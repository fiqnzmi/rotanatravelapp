<?php
require_once 'db.php';
require_once 'helpers.php';

$data = body();
require_fields($data, ['package_id', 'user_id', 'rating']);

$packageId = (int)$data['package_id'];
$userId = (int)$data['user_id'];
$rating = (int)$data['rating'];
$comment = isset($data['comment']) ? trim((string)$data['comment']) : '';

if ($packageId <= 0) {
  fail('Invalid package_id');
}
if ($userId <= 0) {
  fail('Invalid user_id');
}
if ($rating < 1 || $rating > 5) {
  fail('Rating must be between 1 and 5');
}

$pdo = db();
ensure_package_reviews_table($pdo);

$pkgStmt = $pdo->prepare("SELECT id FROM packages WHERE id = ? LIMIT 1");
$pkgStmt->execute([$packageId]);
if (!$pkgStmt->fetchColumn()) {
  fail('Package not found', 404);
}

$userStmt = $pdo->prepare("SELECT id FROM users WHERE id = ? LIMIT 1");
$userStmt->execute([$userId]);
if (!$userStmt->fetchColumn()) {
  fail('User not found', 404);
}

$hasBooking = user_can_review_package($pdo, $userId, $packageId);

$pdo->beginTransaction();
try {
  $stmt = $pdo->prepare("
    INSERT INTO package_reviews (package_id, user_id, rating, comment)
    VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE rating = VALUES(rating), comment = VALUES(comment), updated_at = CURRENT_TIMESTAMP
  ");
  $stmt->execute([$packageId, $userId, $rating, $comment !== '' ? $comment : null]);

  $summary = recalc_package_rating($pdo, $packageId);

  $reviewStmt = $pdo->prepare("
    SELECT r.id, r.package_id, r.user_id, r.rating, r.comment, r.created_at, r.updated_at,
           u.name AS user_name,
           u.username AS user_username,
           u.email AS user_email,
           u.profile_photo,
           u.profile_photo_url
    FROM package_reviews r
    LEFT JOIN users u ON u.id = r.user_id
    WHERE r.package_id = ? AND r.user_id = ?
    LIMIT 1
  ");
  $reviewStmt->execute([$packageId, $userId]);
  $reviewRow = $reviewStmt->fetch(PDO::FETCH_ASSOC);

  $pdo->commit();
} catch (Throwable $e) {
  $pdo->rollBack();
  fail('Failed to save review: ' . $e->getMessage());
}

$review = $reviewRow ? format_package_review_row($reviewRow, $userId) : null;

ok([
  'review' => $review,
  'summary' => $summary,
  'eligibility' => [
    'is_logged_in' => true,
    'has_booking' => $hasBooking,
  ],
]);
