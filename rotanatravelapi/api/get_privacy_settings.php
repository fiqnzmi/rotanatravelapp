<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
$userId = isset($input['user_id']) ? (int)$input['user_id'] : (isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0);
if ($userId <= 0) {
  fail('Invalid user id');
}

$pdo = db();
$settings = fetch_privacy_settings($pdo, $userId);
ok($settings);
