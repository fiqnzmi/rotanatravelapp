<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
$userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
if ($userId <= 0) {
  fail('Invalid user id');
}

$pdo = db();
ensure_booking_request_tables($pdo);
$stmt = $pdo->prepare("SELECT id, username, name, email, phone, created_at FROM users WHERE id=? LIMIT 1");
$stmt->execute([$userId]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
  fail('User not found', 404);
}

// bookings
$bookingStmt = $pdo->prepare("SELECT * FROM bookings WHERE user_id=? ORDER BY created_at DESC");
$bookingStmt->execute([$userId]);
$bookings = $bookingStmt->fetchAll(PDO::FETCH_ASSOC);

$bookingIds = array_map(function ($row) {
  return (int)$row['id'];
}, $bookings);

$travellers = [];
if (!empty($bookingIds)) {
  $placeholders = implode(',', array_fill(0, count($bookingIds), '?'));
  $travStmt = $pdo->prepare("SELECT * FROM booking_travellers WHERE booking_id IN ($placeholders) ORDER BY id ASC");
  $travStmt->execute($bookingIds);
  $travellers = $travStmt->fetchAll(PDO::FETCH_ASSOC);
}

$requestStmt = $pdo->prepare("SELECT * FROM booking_requests WHERE user_id=? ORDER BY created_at DESC");
$requestStmt->execute([$userId]);
$bookingRequests = $requestStmt->fetchAll(PDO::FETCH_ASSOC);

$requestIds = array_map(static function ($row) {
  return (int)$row['id'];
}, $bookingRequests);

$requestTravellers = [];
if (!empty($requestIds)) {
  $rqPlaceholders = implode(',', array_fill(0, count($requestIds), '?'));
  $rqTravStmt = $pdo->prepare("SELECT * FROM booking_request_travellers WHERE booking_request_id IN ($rqPlaceholders) ORDER BY id ASC");
  $rqTravStmt->execute($requestIds);
  $requestTravellers = $rqTravStmt->fetchAll(PDO::FETCH_ASSOC);
}

$familyStmt = $pdo->prepare("SELECT id, full_name, relationship, gender, passport_no, dob, nationality, phone, created_at FROM family_members WHERE user_id=? ORDER BY id ASC");
$familyStmt->execute([$userId]);
$family = $familyStmt->fetchAll(PDO::FETCH_ASSOC);

$documentsStmt = $pdo->prepare("SELECT * FROM documents WHERE user_id=? ORDER BY uploaded_at DESC");
$documentsStmt->execute([$userId]);
$documents = $documentsStmt->fetchAll(PDO::FETCH_ASSOC);

$payments = [];
if (!empty($bookingIds)) {
  $placeholders = implode(',', array_fill(0, count($bookingIds), '?'));
  $payStmt = $pdo->prepare("SELECT * FROM payments WHERE booking_id IN ($placeholders) ORDER BY created_at DESC");
  $payStmt->execute($bookingIds);
  $payments = $payStmt->fetchAll(PDO::FETCH_ASSOC);
}

if (!empty($requestIds)) {
  $rqPlaceholders = implode(',', array_fill(0, count($requestIds), '?'));
  $rqPayStmt = $pdo->prepare("SELECT * FROM payments WHERE booking_request_id IN ($rqPlaceholders) ORDER BY created_at DESC");
  $rqPayStmt->execute($requestIds);
  $payments = array_merge($payments, $rqPayStmt->fetchAll(PDO::FETCH_ASSOC));
}

ok([
  'generated_at' => date('c'),
  'user' => $user,
  'privacy_settings' => fetch_privacy_settings($pdo, $userId),
  'bookings' => $bookings,
  'booking_requests' => $bookingRequests,
  'booking_travellers' => $travellers,
  'booking_request_travellers' => $requestTravellers,
  'family_members' => $family,
  'documents' => $documents,
  'payments' => $payments,
]);
