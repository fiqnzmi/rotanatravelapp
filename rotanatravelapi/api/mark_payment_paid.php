<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body(); require_fields($i, ['payment_id']);
$pdo = db();
$pdo->prepare("UPDATE payments SET status='PAID', transaction_ref=?, paid_at=NOW() WHERE id=?")
    ->execute([$i['transaction_ref'] ?? null, (int)$i['payment_id']]);
ok(['message'=>'Payment marked PAID']);
