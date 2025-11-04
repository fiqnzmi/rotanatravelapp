<?php
require_once 'db.php'; require_once 'helpers.php'; require_once 'config.php';
$i = body(); require_fields($i, ['identifier']);
$pdo = db();

$st = $pdo->prepare("SELECT id, email FROM users WHERE username=? OR email=? LIMIT 1");
$st->execute([$i['identifier'], $i['identifier']]);
$u = $st->fetch(); if (!$u) fail('Account not found', 404);

$token = bin2hex(random_bytes(16));
$code  = random_int(100000, 999999);
$pdo->prepare("INSERT INTO password_resets (user_id, token, code, created_at, used_at) VALUES (?,?,?,NOW(),NULL)")
    ->execute([$u['id'], $token, $code]);

$data = ['token'=>$token, 'contact_mask'=>mask_email($u['email'])];
global $APP_ENV;
if ($APP_ENV !== 'production') $data['debug_code'] = $code; // for development

$subject = 'Rotana Travel password reset code';
$body = "Hi,\n\nWe received a request to reset your Rotana Travel password.\n\n"
      . "Your verification code is: $code\n\n"
      . "This code expires in 30 minutes. If you did not request this, you can safely ignore this email.\n\n"
      . "Regards,\nRotana Travel";
if (!send_email($u['email'], $subject, $body)) {
  fail('Unable to send verification email. Please try again later.', 500);
}

ok($data);
