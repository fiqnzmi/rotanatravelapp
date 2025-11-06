<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
$userId = isset($input['user_id']) ? (int)$input['user_id'] : 0;
if ($userId <= 0) {
  fail('Invalid user id');
}

$fields = ['two_factor', 'biometric_login', 'trusted_devices', 'personalized_recommendations'];
$updates = [];
foreach ($fields as $field) {
  if (array_key_exists($field, $input)) {
    $normalized = normalize_bool_value($input[$field], null);
    if (!is_bool($normalized)) {
      fail("Invalid value for $field");
    }
    $updates[$field] = $normalized;
  }
}

if (empty($updates)) {
  fail('No valid settings provided.');
}

$pdo = db();
$current = fetch_privacy_settings($pdo, $userId);
$merged = array_merge($current, $updates);
save_privacy_settings($pdo, $userId, $merged);

ok($merged);
