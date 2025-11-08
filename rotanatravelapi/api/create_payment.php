<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['booking_id','amount']);

$bookingId = (int)$input['booking_id'];
if ($bookingId === 0) {
  fail('Invalid booking');
}

$amount = (float)$input['amount'];
if ($amount <= 0) {
  fail('Amount must be greater than zero.');
}

$pdo = db();
$context = fetch_booking_context($pdo, $bookingId, null);
if (!$context['found']) {
  fail('Booking not found', 404);
}

$payload = isset($input['metadata']) && is_array($input['metadata'])
  ? json_encode($input['metadata'], JSON_UNESCAPED_UNICODE)
  : null;

$stmt = $pdo->prepare("INSERT INTO payments (booking_id, booking_request_id, amount, currency, method, status, transaction_ref, gateway_payload, created_at)
                        VALUES (?, ?, ?, ?, ?, 'PENDING', ?, ?, NOW())");
$stmt->execute([
  $context['kind'] === 'request' ? null : $context['booking_id'],
  $context['kind'] === 'request' ? $context['request_id'] : null,
  $amount,
  $input['currency'] ?? 'MYR',
  $input['method'] ?? 'TRANSFER',
  $input['transaction_ref'] ?? null,
  $payload,
]);
$paymentId = (int)$pdo->lastInsertId();

if ($context['kind'] === 'request') {
  refresh_booking_request_progress($pdo, $context['request_id']);
}

ok(['id'=>$paymentId]);
