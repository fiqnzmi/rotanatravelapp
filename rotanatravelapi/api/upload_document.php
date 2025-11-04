<?php
require_once 'db.php'; require_once 'helpers.php'; require_once 'config.php';

if (!isset($_POST['booking_id'], $_POST['user_id'], $_POST['doc_type'])) fail('Missing fields');
if (!isset($_FILES['file'])) fail('Missing file');

$bookingId=(int)$_POST['booking_id']; $userId=(int)$_POST['user_id']; $docType=$_POST['doc_type'];
$label = $_POST['label'] ?? $docType;

$ext = strtolower(pathinfo($_FILES['file']['name'], PATHINFO_EXTENSION));
$allowed = ['jpg','jpeg','png','pdf'];
if (!in_array($ext,$allowed)) fail('Invalid file type');

$fname = 'doc_' . $bookingId . '_' . $userId . '_' . time() . '.' . $ext;
global $UPLOAD_DIR, $UPLOAD_URL;
$target = $UPLOAD_DIR . DIRECTORY_SEPARATOR . $fname;
if (!@move_uploaded_file($_FILES['file']['tmp_name'], $target)) fail('Failed to move file', 500);

$pdo = db();
$st = $pdo->prepare("UPDATE documents SET status='PENDING', file_name=?, file_url=?, label=? 
                     WHERE booking_id=? AND user_id=? AND doc_type=?");
$st->execute([$fname, $UPLOAD_URL . '/' . $fname, $label, $bookingId, $userId, $docType]);

ok(['file'=>$fname, 'url'=>$UPLOAD_URL.'/'.$fname, 'status'=>'PENDING']);
