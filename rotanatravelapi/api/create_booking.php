<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body(); require_fields($i, ['user_id','package_id','adults','children','travellers']);

$pdo = db();
$pkg = $pdo->prepare("SELECT price FROM packages WHERE id=?"); $pkg->execute([$i['package_id']]);
$base = $pkg->fetch(); if (!$base) fail('Package not found', 404);

$user_id = (int)$i['user_id'];
if ($user_id <= 0) fail('Invalid user id');

$adults = max(1, (int)$i['adults']);
$children = max(0, (int)$i['children']);
$total = $adults * (float)$base['price']; // simple
$departureDate = null;
if (!empty($i['departure_date'])) {
  $ts = strtotime($i['departure_date']);
  if ($ts !== false) {
    $departureDate = date('Y-m-d', $ts);
  }
}

$pdo->beginTransaction();
$pdo->prepare("INSERT INTO bookings (
                 user_id,
                 package_id,
                 adults,
                 children,
                 status,
                 created_at,
                 total_amount,
                 departure_date,
                 deposit_paid,
                 final_paid,
                 briefing_done
               )
               VALUES (?, ?, ?, ?, 'CONFIRMED', NOW(), ?, ?, 0, 0, 0)")
    ->execute([
      $user_id,
      $i['package_id'],
      $adults,
      $children,
      $total,
      $departureDate
    ]);
$bid = (int)$pdo->lastInsertId();

// store travellers JSON (or rows)
$travellers = is_array($i['travellers']) ? $i['travellers'] : [];
foreach ($travellers as $t) {
  if ($t instanceof stdClass) {
    $t = (array)$t;
  }
  if (!is_array($t)) continue;

  $normalized = build_normalized_key_map($t);
  $fullName = trim((string)(array_pick_value($t, $normalized, ['full_name', 'fullName', 'name']) ?? ''));
  if ($fullName === '') continue;

  $passport = array_pick_value($t, $normalized, ['passport', 'passport_no', 'passportNo'], true);
  $dobValue = array_pick_value($t, $normalized, ['dob', 'date_of_birth', 'birth_date', 'dateOfBirth'], false);
  $issueValue = array_pick_value(
    $t,
    $normalized,
    ['passport_issue_date', 'issue_date', 'passportIssueDate', 'issueDate'],
    false
  );
  $expiryValue = array_pick_value(
    $t,
    $normalized,
    ['passport_expiry_date', 'expiry_date', 'passportExpiryDate', 'expiryDate'],
    false
  );
  $genderValue = array_pick_value($t, $normalized, ['gender'], true);

  $pdo->prepare("
    INSERT INTO booking_travellers (booking_id, full_name, passport_no, dob, gender, passport_issue_date, passport_expiry_date)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ")->execute([
    $bid,
    $fullName,
    $passport === null ? null : trim((string)$passport),
    normalize_date_value($dobValue),
    normalize_gender_value($genderValue),
    normalize_date_value($issueValue),
    normalize_date_value($expiryValue),
  ]);
}

$pdo->commit();
ok(['id'=>$bid]);
