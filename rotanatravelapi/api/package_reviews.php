<?php
require_once 'db.php';
require_once 'helpers.php';

$packageId = isset($_GET['package_id']) ? (int)$_GET['package_id'] : 0;
if ($packageId <= 0) {
  fail('Missing package_id');
}

$limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 20;
if ($limit <= 0) {
  $limit = 20;
}
$limit = min($limit, 50);
$offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
if ($offset < 0) {
  $offset = 0;
}
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

$pdo = db();
ensure_package_reviews_table($pdo);

$totalStmt = $pdo->prepare("SELECT COUNT(*) FROM package_reviews WHERE package_id = ?");
$totalStmt->execute([$packageId]);
$total = (int)$totalStmt->fetchColumn();

$sql = "
  SELECT r.id, r.package_id, r.user_id, r.rating, r.comment, r.created_at, r.updated_at,
         u.name AS user_name,
         u.username AS user_username,
         u.email AS user_email,
         u.profile_photo,
         u.profile_photo_url
  FROM package_reviews r
  LEFT JOIN users u ON u.id = r.user_id
  WHERE r.package_id = :package_id
  ORDER BY r.created_at DESC, r.id DESC
  LIMIT $limit OFFSET $offset
";
$stmt = $pdo->prepare($sql);
$stmt->execute([':package_id' => $packageId]);

$items = [];
$myReview = null;
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
  $formatted = format_package_review_row($row, $userId);
  $items[] = $formatted;
  if ($myReview === null && $formatted['is_mine']) {
    $myReview = $formatted;
  }
}

$summary = package_rating_summary($pdo, $packageId);
$eligibility = [
  'is_logged_in' => $userId > 0,
  'has_booking' => $userId > 0 ? user_can_review_package($pdo, $userId, $packageId) : false,
];

ok([
  'items' => $items,
  'total' => $total,
  'has_more' => ($offset + $limit) < $total,
  'summary' => $summary,
  'my_review' => $myReview,
  'eligibility' => $eligibility,
]);
