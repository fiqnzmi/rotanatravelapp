<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['user_id', 'package_id', 'adults', 'children', 'travellers']);

$pdo = db();
ensure_booking_request_tables($pdo);

$pkg = $pdo->prepare("SELECT price FROM packages WHERE id=? LIMIT 1");
$pkg->execute([$input['package_id']]);
$base = $pkg->fetch();
if (!$base) {
  fail('Package not found', 404);
}

$userId = (int)$input['user_id'];
if ($userId <= 0) {
  fail('Invalid user id');
}

$adults = max(1, (int)$input['adults']);
$children = max(0, (int)$input['children']);
$rooms = max(1, isset($input['rooms']) ? (int)$input['rooms'] : 1);
$total = $adults * (float)$base['price'];
$departureDate = null;
if (!empty($input['departure_date'])) {
  $ts = strtotime($input['departure_date']);
  if ($ts !== false) {
    $departureDate = date('Y-m-d', $ts);
  }
}

$pdo->beginTransaction();
$stmt = $pdo->prepare("
  INSERT INTO booking_requests (
    user_id,
    package_id,
    adults,
    children,
    rooms,
    status,
    created_at,
    total_amount,
    departure_date,
    documents_ready,
    payment_ready
  ) VALUES (?, ?, ?, ?, ?, 'NOT_CONFIRMED', NOW(), ?, ?, 0, 0)
");
$stmt->execute([
  $userId,
  (int)$input['package_id'],
  $adults,
  $children,
  $rooms,
  $total,
  $departureDate,
]);
$requestId = (int)$pdo->lastInsertId();

// store travellers
$travellers = is_array($input['travellers']) ? $input['travellers'] : [];
$travStmt = $pdo->prepare("
  INSERT INTO booking_request_travellers (
    booking_request_id,
    full_name,
    passport_no,
    dob,
    gender,
    passport_issue_date,
    passport_expiry_date
  ) VALUES (?, ?, ?, ?, ?, ?, ?)
");
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

  $travStmt->execute([
    $requestId,
    $fullName,
    $passport === null ? null : trim((string)$passport),
    normalize_date_value($dobValue),
    normalize_gender_value($genderValue),
    normalize_date_value($issueValue),
    normalize_date_value($expiryValue),
  ]);
}

// Seed default document placeholders so staff can track requirements immediately.
$requiredDocs = booking_required_document_types();
if ($requiredDocs) {
  $docStmt = $pdo->prepare("\n    INSERT INTO documents (booking_id, booking_request_id, user_id, doc_type, label, status, file_path)\n    VALUES (NULL, ?, ?, ?, ?, 'REQUIRED', NULL)\n  ");
  $dupCheck = $pdo->prepare("\n    SELECT 1 FROM documents WHERE booking_request_id = ? AND doc_type = ? LIMIT 1\n  ");
  foreach ($requiredDocs as $docType) {
    $dupCheck->execute([$requestId, $docType]);
    if ($dupCheck->fetchColumn()) {
      continue;
    }
    $label = ucwords(strtolower(str_replace('_', ' ', $docType)));
    $docStmt->execute([$requestId, $userId, $docType, $label]);
  }
}

$pdo->commit();
ok([
  'id' => booking_request_display_id($requestId),
  'status' => 'NOT_CONFIRMED',
]);
