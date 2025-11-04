<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body();
require_fields($i, ['identifier','password']);

$pdo = db();
$st = $pdo->prepare("SELECT id, username, name, email, password_hash FROM users WHERE username=? OR email=? LIMIT 1");
$st->execute([$i['identifier'], $i['identifier']]);
$u = $st->fetch();
if (!$u || !password_verify($i['password'], $u['password_hash'])) fail('Invalid credentials', 401);

unset($u['password_hash']);
ok(['user' => $u]);
