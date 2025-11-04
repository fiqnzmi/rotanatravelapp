<?php
require_once 'db.php'; require_once 'helpers.php';
$pdo = db();

// For demo, return all confirmed bookings; in prod, pass ?user_id= or session auth.
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;

$st = $pdo->prepare("
  SELECT b.id,
         b.package_id,
         p.title,
         b.total_amount,
         b.adults,
         b.children,
         b.status,
         b.created_at,
         b.deposit_paid,
         b.final_paid,
         b.briefing_done,
         b.departure_date
  FROM bookings b
  JOIN packages p ON p.id=b.package_id
  WHERE (:uid = 0 OR b.user_id=:uid)
  ORDER BY b.created_at DESC
");
$st->execute([':uid'=>$userId]);
$rows = $st->fetchAll();
foreach ($rows as &$row) {
  $row['id'] = (int)$row['id'];
  $row['package_id'] = (int)$row['package_id'];
  $row['total_amount'] = isset($row['total_amount']) ? (float)$row['total_amount'] : 0.0;
  $row['price'] = $row['total_amount'];
  $row['adults'] = (int)$row['adults'];
  $row['children'] = (int)$row['children'];
  $row['deposit_paid'] = (int)$row['deposit_paid'];
  $row['final_paid'] = (int)$row['final_paid'];
  $row['briefing_done'] = (int)$row['briefing_done'];
  $row['departure_date'] = $row['departure_date'] ?? null;
}
unset($row);

ok($rows);
