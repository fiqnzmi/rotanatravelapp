<?php
require_once 'db.php'; require_once 'helpers.php';
$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
if ($bookingId<=0) fail('Missing booking_id');

$pdo = db();
$totalRow = $pdo->query("SELECT total_amount FROM bookings WHERE id=$bookingId")->fetch();
$total = isset($totalRow['total_amount']) ? (float)$totalRow['total_amount'] : 0.0;
$items = $pdo->query("SELECT id, amount, method, status, currency, transaction_ref, paid_at, created_at FROM payments WHERE booking_id=$bookingId ORDER BY created_at DESC")->fetchAll();
$paid  = 0.0;
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

ok(['total'=>$total, 'paid'=>$paid, 'balance'=>max(0,$total-$paid), 'items'=>$items]);
