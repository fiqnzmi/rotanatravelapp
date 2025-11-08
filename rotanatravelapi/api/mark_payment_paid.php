<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['payment_id']);

$paymentId = (int)$input['payment_id'];
if ($paymentId <= 0) {
  fail('Invalid payment');
}

$pdo = db();
$stmt = $pdo->prepare("UPDATE payments SET status='PAID', transaction_ref=?, paid_at=NOW() WHERE id=?");
$stmt->execute([$input['transaction_ref'] ?? null, $paymentId]);

$metaStmt = $pdo->prepare("SELECT booking_request_id FROM payments WHERE id=? LIMIT 1");
$metaStmt->execute([$paymentId]);
$requestId = (int)$metaStmt->fetchColumn();
if ($requestId > 0) {
  refresh_booking_request_progress($pdo, $requestId);
}

ok(['message'=>'Payment marked PAID']);
