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
  $fullName = trim($t['full_name'] ?? '');
  if ($fullName === '') continue;
  $passport = trim($t['passport'] ?? $t['passport_no'] ?? '');
  $dob = $t['dob'] ?? $t['date_of_birth'] ?? null;
  $issue = $t['issue_date'] ?? null;
  $expiry = $t['expiry_date'] ?? null;

  $pdo->prepare("
    INSERT INTO booking_travellers (booking_id, full_name, passport_no, dob, gender, passport_issue_date, passport_expiry_date)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  ")->execute([
    $bid,
    $fullName,
    $passport,
    $dob ? date('Y-m-d', strtotime($dob)) : null,
    $t['gender'] ?? null,
    $issue ? date('Y-m-d', strtotime($issue)) : null,
    $expiry ? date('Y-m-d', strtotime($expiry)) : null,
  ]);
}

$pdo->commit();
ok(['id'=>$bid]);
