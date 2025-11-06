<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body();
require_fields($i, ['identifier','password']);

$pdo = db();
$st = $pdo->prepare("SELECT id, username, name, email, phone, gender, dob, passport_no, address, notify_email, notify_sms, preferred_language, emergency_contact_id, password_hash, profile_photo, profile_photo_url FROM users WHERE username=? OR email=? LIMIT 1");
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
$u['gender'] = $u['gender'] ?? null;
$u['passport_no'] = $u['passport_no'] ?? null;
$u['address'] = $u['address'] ?? null;
if (!empty($u['dob'])) {
  $u['dob'] = date('Y-m-d', strtotime($u['dob']));
} else {
  $u['dob'] = null;
}
ok(['user' => $u]);
