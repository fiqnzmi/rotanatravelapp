<?php
require_once 'db.php';
require_once 'helpers.php';

$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
$userId    = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($bookingId <= 0) {
  fail('Missing booking_id');
}

$pdo = db();
$sql = "
  SELECT b.id,
         b.user_id,
         b.deposit_paid,
         b.briefing_done,
         b.final_paid,
         b.departure_date,
         b.status,
         (
           SELECT COUNT(*)
           FROM documents d
           WHERE d.booking_id = b.id
             AND (d.status IS NULL OR d.status = 'ACTIVE')
         ) AS docs_count
  FROM bookings b
  WHERE b.id = ?
";

$params = [$bookingId];
if ($userId > 0) {
  $sql .= " AND b.user_id = ?";
  $params[] = $userId;
}

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$booking = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$booking) {
  fail('Booking not found', 404);
}

$depositDone = (int)$booking['deposit_paid'] === 1;
$finalPayDone = (int)$booking['final_paid'] === 1;
$briefingDone = (int)$booking['briefing_done'] === 1;
$docsDone = (int)$booking['docs_count'] > 0;
$travelDone = false;

if (!empty($booking['departure_date'])) {
  $depTs = strtotime($booking['departure_date']);
  if ($depTs !== false && $depTs <= strtotime('today')) {
    $travelDone = true;
  }
}

$steps = [
  ['key' => 'deposit', 'label' => 'Deposit', 'done' => $depositDone],
  ['key' => 'docs', 'label' => 'Docs', 'done' => $docsDone],
  ['key' => 'brief', 'label' => 'Briefing', 'done' => $briefingDone],
  ['key' => 'final', 'label' => 'Final Pay', 'done' => $finalPayDone],
  ['key' => 'travel', 'label' => 'Travel', 'done' => $travelDone],
];

ok([
  'steps' => $steps,
  'booking_id' => $bookingId,
  'user_id' => (int)$booking['user_id'],
  'status' => $booking['status'],
  'departure_date' => $booking['departure_date'],
  'docs_count' => (int)$booking['docs_count'],
  'deposit_paid' => $depositDone,
  'final_paid' => $finalPayDone,
  'briefing_done' => $briefingDone,
]);
