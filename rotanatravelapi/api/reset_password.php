<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body(); require_fields($i,['token','code','new_password']);

$pdo = db();
$st = $pdo->prepare("SELECT pr.id, pr.user_id FROM password_resets pr
                     WHERE pr.token=? AND pr.code=? AND pr.used_at IS NULL
                       AND pr.created_at >= (NOW() - INTERVAL 30 MINUTE) LIMIT 1");
$st->execute([$i['token'], $i['code']]);
$r = $st->fetch(); if (!$r) fail('Invalid or expired code/token', 400);

$hash = password_hash($i['new_password'], PASSWORD_BCRYPT);
$pdo->prepare("UPDATE users SET password_hash=? WHERE id=?")->execute([$hash, $r['user_id']]);
$pdo->prepare("UPDATE password_resets SET used_at=NOW() WHERE id=?")->execute([$r['id']]);
ok(['message'=>'Password updated']);
