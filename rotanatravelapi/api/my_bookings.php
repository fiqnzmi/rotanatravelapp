<?php
require_once 'db.php';
require_once 'helpers.php';

$pdo = db();
ensure_booking_request_tables($pdo);

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

$bookingsStmt = $pdo->prepare("
  SELECT b.id,
         b.package_id,
         p.title,
         b.total_amount,
         b.adults,
         b.children,
         b.rooms,
         b.status,
         b.created_at,
         b.deposit_paid,
         b.final_paid,
         b.briefing_done,
         b.departure_date
  FROM bookings b
  JOIN packages p ON p.id = b.package_id
  WHERE (:uid = 0 OR b.user_id = :uid)
");
$bookingsStmt->execute([':uid' => $userId]);
$items = [];
while ($row = $bookingsStmt->fetch(PDO::FETCH_ASSOC)) {
  $row['id'] = (int)$row['id'];
  $row['package_id'] = (int)$row['package_id'];
  $row['total_amount'] = isset($row['total_amount']) ? (float)$row['total_amount'] : 0.0;
  $row['price'] = $row['total_amount'];
  $row['adults'] = (int)$row['adults'];
  $row['children'] = (int)$row['children'];
  $row['rooms'] = isset($row['rooms']) ? (int)$row['rooms'] : 1;
  $row['deposit_paid'] = (int)$row['deposit_paid'];
  $row['final_paid'] = (int)$row['final_paid'];
  $row['briefing_done'] = (int)$row['briefing_done'];
  $row['departure_date'] = $row['departure_date'] ?? null;
  $row['is_request'] = 0;
  $row['documents_ready'] = 1;
  $row['payment_ready'] = 1;
  $row['created_at'] = $row['created_at'] ?? null;
  $items[] = $row;
}

$requestStmt = $pdo->prepare("
  SELECT r.id,
         r.package_id,
         p.title,
         r.total_amount,
         r.adults,
         r.children,
         r.rooms,
         r.status,
         r.created_at,
         r.departure_date,
         r.documents_ready,
         r.payment_ready
  FROM booking_requests r
  JOIN packages p ON p.id = r.package_id
  WHERE (:uid = 0 OR r.user_id = :uid)
");
$requestStmt->execute([':uid' => $userId]);
while ($row = $requestStmt->fetch(PDO::FETCH_ASSOC)) {
  $row['id'] = booking_request_display_id((int)$row['id']);
  $row['package_id'] = (int)$row['package_id'];
  $row['total_amount'] = isset($row['total_amount']) ? (float)$row['total_amount'] : 0.0;
  $row['price'] = $row['total_amount'];
  $row['adults'] = (int)$row['adults'];
  $row['children'] = (int)$row['children'];
  $row['rooms'] = isset($row['rooms']) ? (int)$row['rooms'] : 1;
  $row['deposit_paid'] = 0;
  $row['final_paid'] = 0;
  $row['briefing_done'] = 0;
  $row['documents_ready'] = (int)$row['documents_ready'];
  $row['payment_ready'] = (int)$row['payment_ready'];
  $row['departure_date'] = $row['departure_date'] ?? null;
  $row['is_request'] = 1;
  $items[] = $row;
}

usort($items, static function ($a, $b) {
  $aTime = strtotime($a['created_at'] ?? '1970-01-01');
  $bTime = strtotime($b['created_at'] ?? '1970-01-01');
  return $bTime <=> $aTime;
});

ok($items);
