<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body(); require_fields($i, ['booking_id','amount']);

$pdo = db();
$payload = isset($i['metadata']) && is_array($i['metadata']) ? json_encode($i['metadata'], JSON_UNESCAPED_UNICODE) : null;
$pdo->prepare("INSERT INTO payments (booking_id, amount, currency, method, status, transaction_ref, gateway_payload, created_at)
               VALUES (?, ?, ?, ?, 'PENDING', ?, ?, NOW())")
    ->execute([
      (int)$i['booking_id'],
      (float)$i['amount'],
      $i['currency'] ?? 'MYR',
      $i['method'] ?? 'TRANSFER',
      $i['transaction_ref'] ?? null,
      $payload
    ]);
ok(['id'=>(int)$pdo->lastInsertId()]);
