<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body();
require_fields($i, ['identifier','password']);

$pdo = db();
$st = $pdo->prepare("SELECT id, username, name, email, phone, notify_email, notify_sms, preferred_language, emergency_contact_id, password_hash, profile_photo, profile_photo_url FROM users WHERE username=? OR email=? LIMIT 1");
$st->execute([$i['identifier'], $i['identifier']]);
$u = $st->fetch();
if (!$u || !password_verify($i['password'], $u['password_hash'])) fail('Invalid credentials', 401);

unset($u['password_hash']);
$photoUrl = $u['profile_photo_url'] ?? null;
if (!$photoUrl && !empty($u['profile_photo'])) {
  $photoUrl = $u['profile_photo'];
}
$u['photo'] = $photoUrl;
$u['photo_url'] = $photoUrl;
$u['notify_email'] = isset($u['notify_email']) ? (int)$u['notify_email'] : 1;
$u['notify_sms'] = isset($u['notify_sms']) ? (int)$u['notify_sms'] : 0;
$u['language'] = $u['preferred_language'] ?? null;
ok(['user' => $u]);
