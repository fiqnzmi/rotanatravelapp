<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['user_id', 'current_password', 'new_password']);

$userId = (int)$input['user_id'];
if ($userId <= 0) {
  fail('Invalid user id');
}

$current = trim((string)$input['current_password']);
$new = trim((string)$input['new_password']);
if (strlen($new) < 8) {
  fail('New password must be at least 8 characters.');
}
if ($current === $new) {
  fail('New password must be different from the current password.');
}

$pdo = db();
$stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id=? LIMIT 1");
$stmt->execute([$userId]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
  fail('User not found', 404);
}

if (!password_verify($current, $user['password_hash'])) {
  fail('Current password is incorrect.', 403);
}

$hash = password_hash($new, PASSWORD_DEFAULT);
$update = $pdo->prepare("UPDATE users SET password_hash=? WHERE id=?");
$update->execute([$hash, $userId]);

ok(['message' => 'Password updated successfully.']);
