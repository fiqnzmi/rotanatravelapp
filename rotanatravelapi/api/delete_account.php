<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['user_id', 'password']);

$userId = (int)$input['user_id'];
if ($userId <= 0) {
  fail('Invalid user id');
}
$password = (string)$input['password'];

$pdo = db();
ensure_booking_request_tables($pdo);
$stmt = $pdo->prepare("SELECT password_hash FROM users WHERE id=? LIMIT 1");
$stmt->execute([$userId]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);
if (!$user) {
  fail('User not found', 404);
}

if (!password_verify($password, $user['password_hash'])) {
  fail('Invalid password.', 403);
}

try {
  $pdo->beginTransaction();

  // Gather related bookings
  $bookingStmt = $pdo->prepare("SELECT id FROM bookings WHERE user_id=?");
  $bookingStmt->execute([$userId]);
  $bookingIds = $bookingStmt->fetchAll(PDO::FETCH_COLUMN, 0);

  if (!empty($bookingIds)) {
    $placeholders = implode(',', array_fill(0, count($bookingIds), '?'));
    $pdo->prepare("DELETE bt FROM booking_travellers bt INNER JOIN bookings b ON bt.booking_id = b.id WHERE b.user_id = ?")
        ->execute([$userId]);
    $pdo->prepare("DELETE FROM payments WHERE booking_id IN ($placeholders)")
        ->execute(array_values($bookingIds));
    $pdo->prepare("DELETE FROM documents WHERE booking_id IN ($placeholders)")
        ->execute(array_values($bookingIds));
    $pdo->prepare("DELETE FROM bookings WHERE id IN ($placeholders)")
        ->execute(array_values($bookingIds));
  }

  $requestStmt = $pdo->prepare("SELECT id FROM booking_requests WHERE user_id=?");
  $requestStmt->execute([$userId]);
  $requestIds = $requestStmt->fetchAll(PDO::FETCH_COLUMN, 0);
  if (!empty($requestIds)) {
    $rqPlaceholders = implode(',', array_fill(0, count($requestIds), '?'));
    $pdo->prepare("DELETE FROM booking_request_travellers WHERE booking_request_id IN ($rqPlaceholders)")
        ->execute($requestIds);
    $pdo->prepare("DELETE FROM payments WHERE booking_request_id IN ($rqPlaceholders)")
        ->execute($requestIds);
    $pdo->prepare("DELETE FROM documents WHERE booking_request_id IN ($rqPlaceholders)")
        ->execute($requestIds);
    $pdo->prepare("DELETE FROM booking_requests WHERE id IN ($rqPlaceholders)")
        ->execute($requestIds);
  }

  $pdo->prepare("DELETE FROM documents WHERE user_id=?")->execute([$userId]);
  $pdo->prepare("DELETE FROM family_members WHERE user_id=?")->execute([$userId]);
  $pdo->prepare("DELETE FROM notifications WHERE user_id=?")->execute([$userId]);
  $pdo->prepare("DELETE FROM user_settings WHERE user_id=?")->execute([$userId]);
  $pdo->prepare("DELETE FROM password_resets WHERE user_id=?")->execute([$userId]);
  $pdo->prepare("DELETE FROM users WHERE id=?")->execute([$userId]);

  $pdo->commit();
  ok(['message' => 'Account deleted successfully.']);
} catch (Throwable $e) {
  $pdo->rollBack();
  fail('Failed to delete account: '.$e->getMessage(), 500);
}
