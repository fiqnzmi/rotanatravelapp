<?php
require_once 'db.php'; require_once 'helpers.php';
$bookingId = isset($_GET['booking_id']) ? (int)$_GET['booking_id'] : 0;
$userId    = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($bookingId<=0) fail('Missing booking_id');

$pdo = db();
$docs = $pdo->prepare("SELECT id, doc_type, label, status, file_name, remarks, file_path
                       FROM documents WHERE booking_id=? AND user_id=? ORDER BY id");
$docs->execute([$bookingId,$userId]);
$rows = $docs->fetchAll();

if (!$rows) {
  // seed required docs for demo
  $required = [
    ['PASSPORT','Passport'],
    ['INSURANCE','Travel Insurance'],
    ['VISA','Visa'],
    ['PAYMENT_PROOF','Payment Proof'],
    ['OTHER','Additional Document'],
  ];
  foreach ($required as $r) {
    $pdo->prepare("INSERT INTO documents (booking_id,user_id,doc_type,label,status,file_path) VALUES (?,?,?,?,?,?)")
        ->execute([$bookingId,$userId,$r[0],$r[1],'ACTIVE','']);
  }
  $docs->execute([$bookingId,$userId]);
  $rows = $docs->fetchAll();
}
ok($rows);
