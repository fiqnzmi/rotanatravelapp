<?php
require_once 'db.php';
require_once 'helpers.php';

$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
if ($bookingId === 0) {
  fail('Missing booking_id');
}

$pdo = db();
$context = fetch_booking_context($pdo, $bookingId, null);
if (!$context['found']) {
  fail('Booking not found', 404);
}

if ($context['kind'] === 'request') {
  $totalStmt = $pdo->prepare("SELECT total_amount FROM booking_requests WHERE id=? LIMIT 1");
  $totalStmt->execute([$context['request_id']]);
  $totalRow = $totalStmt->fetch();
  $itemsStmt = $pdo->prepare("SELECT id, amount, method, status, currency, transaction_ref, paid_at, created_at
                               FROM payments WHERE booking_request_id=? ORDER BY created_at DESC");
  $itemsStmt->execute([$context['request_id']]);
} else {
  $totalStmt = $pdo->prepare("SELECT total_amount FROM bookings WHERE id=? LIMIT 1");
  $totalStmt->execute([$context['booking_id']]);
  $totalRow = $totalStmt->fetch();
  $itemsStmt = $pdo->prepare("SELECT id, amount, method, status, currency, transaction_ref, paid_at, created_at
                               FROM payments WHERE booking_id=? ORDER BY created_at DESC");
  $itemsStmt->execute([$context['booking_id']]);
}

$total = isset($totalRow['total_amount']) ? (float)$totalRow['total_amount'] : 0.0;
$items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
$paid = 0.0;
foreach ($items as &$p) {
  $p['id'] = (int)$p['id'];
  $p['amount'] = (float)$p['amount'];
  $p['currency'] = $p['currency'] ?? 'MYR';
  $p['transaction_ref'] = $p['transaction_ref'] ?? '';
  $p['paid_at'] = $p['paid_at'] ?? null;
  if ($p['status'] === 'PAID') {
    $paid += $p['amount'];
  }
}
unset($p);

ok([
  'total' => $total,
  'paid' => $paid,
  'balance' => max(0, $total - $paid),
  'items' => $items,
]);
