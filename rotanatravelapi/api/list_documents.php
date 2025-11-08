<?php
require_once 'db.php';
require_once 'helpers.php';
require_once 'config.php';

$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
$userId    = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($bookingId === 0) {
  fail('Missing booking_id');
}

$pdo = db();
$context = fetch_booking_context($pdo, $bookingId, $userId);
if (!$context['found']) {
  fail('Booking not found', 404);
}

$column = $context['kind'] === 'request' ? 'booking_request_id' : 'booking_id';
$linkId = $context['kind'] === 'request' ? $context['request_id'] : $context['booking_id'];

$docs = $pdo->prepare("SELECT id, doc_type, label, status, file_name, remarks, file_path, mime_type
                       FROM documents WHERE $column = ? AND user_id = ? ORDER BY id");
$docs->execute([$linkId, $userId]);
$rows = $docs->fetchAll();

if (!$rows) {
  $required = [
    ['PASSPORT','Passport'],
    ['INSURANCE','Travel Insurance'],
    ['VISA','Visa'],
    ['PAYMENT_PROOF','Payment Proof'],
    ['OTHER','Additional Document'],
  ];
  $insert = $pdo->prepare("INSERT INTO documents (booking_id, booking_request_id, user_id, doc_type, label, status, file_path)
                            VALUES (?, ?, ?, ?, ?, 'REQUIRED', NULL)");
  foreach ($required as $r) {
    $insert->execute([
      $context['kind'] === 'request' ? null : $linkId,
      $context['kind'] === 'request' ? $linkId : null,
      $userId,
      $r[0],
      $r[1],
    ]);
  }
  $docs->execute([$linkId, $userId]);
  $rows = $docs->fetchAll();
}
$baseUrl = $UPLOAD_URL ? rtrim($UPLOAD_URL, '/') : null;
foreach ($rows as &$row) {
  $path = $row['file_path'] ?? '';
  if ($baseUrl && $path) {
    $row['file_url'] = $baseUrl . '/' . ltrim($path, '/');
  } else {
    $row['file_url'] = null;
  }
}
unset($row);

ok($rows);
