<?php
require_once 'db.php';
require_once 'helpers.php';

$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
$userId    = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($bookingId === 0) {
  fail('Missing booking_id');
}

$pdo = db();
$context = fetch_booking_context($pdo, $bookingId, $userId);
if (!$context['found']) {
  fail('Booking not found', 404);
}

if ($context['kind'] === 'request') {
  $request = $context['row'];
  $progress = refresh_booking_request_progress($pdo, $context['request_id']);
  $docsReady = (int)($progress['documents_ready'] ?? $request['documents_ready'] ?? 0) === 1;
  $paymentReady = (int)($progress['payment_ready'] ?? $request['payment_ready'] ?? 0) === 1;
  $status = $progress['status'] ?? ($request['status'] ?? 'NOT_CONFIRMED');
  $steps = [
    ['key' => 'docs', 'label' => 'Documents', 'done' => $docsReady],
    ['key' => 'payment', 'label' => 'Payment', 'done' => $paymentReady],
    ['key' => 'review', 'label' => 'Review', 'done' => $status === 'READY_FOR_REVIEW' || $status === 'APPROVED'],
  ];
  ok([
    'steps' => $steps,
    'booking_id' => $bookingId,
    'user_id' => (int)$request['user_id'],
    'status' => $status,
    'departure_date' => $request['departure_date'] ?? null,
    'docs_count' => $docsReady ? count(booking_required_document_types()) : 0,
    'deposit_paid' => false,
    'final_paid' => false,
    'briefing_done' => false,
    'documents_ready' => $docsReady,
    'payment_ready' => $paymentReady,
  ]);
}

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

$params = [$context['booking_id']];
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
  'booking_id' => $context['booking_id'],
  'user_id' => (int)$booking['user_id'],
  'status' => $booking['status'],
  'departure_date' => $booking['departure_date'],
  'docs_count' => (int)$booking['docs_count'],
  'deposit_paid' => $depositDone,
  'final_paid' => $finalPayDone,
  'briefing_done' => $briefingDone,
]);
