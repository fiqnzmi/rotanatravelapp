<?php
require_once 'db.php';
require_once 'helpers.php';
require_once 'config.php';

if (!isset($_POST['booking_id'], $_POST['user_id'], $_POST['doc_type'])) {
  fail('Missing fields');
}
if (!isset($_FILES['file'])) {
  fail('Missing file');
}

$bookingId = (int)$_POST['booking_id'];
$userId = (int)$_POST['user_id'];
$docType = strtoupper(trim($_POST['doc_type']));
$label = trim($_POST['label'] ?? $docType);

$allowedDocTypes = [
  'PASSPORT',
  'INSURANCE',
  'VISA',
  'PAYMENT_PROOF',
  'IC',
  'TICKET',
  'HOTEL_VOUCHER',
  'OTHER',
];
if (!in_array($docType, $allowedDocTypes, true)) {
  fail('Unsupported document type.');
}

$originalName = $_FILES['file']['name'];
$ext = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
$allowedExt = ['jpg', 'jpeg', 'png', 'pdf'];
if (!in_array($ext, $allowedExt, true)) {
  fail('Invalid file type. Allowed: JPG, PNG, PDF');
}

$size = (int)$_FILES['file']['size'];
$maxSize = 5 * 1024 * 1024; // 5 MB
if ($size > $maxSize) {
  fail('File too large. Maximum size is 5MB.');
}

global $UPLOAD_DIR, $UPLOAD_URL;
$uploadDir = $UPLOAD_DIR ?: __DIR__ . '/../uploads';
if (!is_dir($uploadDir)) {
  if (!@mkdir($uploadDir, 0775, true) && !is_dir($uploadDir)) {
    fail('Failed to prepare upload directory', 500);
  }
}

$filename = 'doc_' . $bookingId . '_' . $userId . '_' . time() . '.' . $ext;
$targetPath = rtrim($uploadDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $filename;

if (!@move_uploaded_file($_FILES['file']['tmp_name'], $targetPath)) {
  fail('Failed to move file', 500);
}

$pdo = db();
$bookingCheck = $pdo->prepare("SELECT id FROM bookings WHERE id=? AND user_id=? LIMIT 1");
$bookingCheck->execute([$bookingId, $userId]);
if (!$bookingCheck->fetchColumn()) {
  fail('Booking not found for this user.', 404);
}
$check = $pdo->prepare("SELECT id FROM documents WHERE booking_id=? AND user_id=? AND doc_type=? LIMIT 1");
$check->execute([$bookingId, $userId, $docType]);
$exists = $check->fetchColumn();

$relativePath = $filename;
$mimeType = isset($_FILES['file']['type']) ? trim((string)$_FILES['file']['type']) : '';
if ($mimeType === '' && function_exists('mime_content_type')) {
  $detected = @mime_content_type($targetPath);
  if (is_string($detected) && $detected !== '') {
    $mimeType = $detected;
  }
}
if ($mimeType === '') {
  $mimeType = 'application/octet-stream';
}
$now = date('Y-m-d H:i:s');

if ($exists) {
  $stmt = $pdo->prepare("
    UPDATE documents
    SET status = 'PENDING',
        file_name = ?,
        file_path = ?,
        mime_type = ?,
        label = ?,
        uploaded_at = ?
    WHERE id = ?
  ");
  $stmt->execute([$originalName, $relativePath, $mimeType, $label, $now, $exists]);
  $documentId = (int)$exists;
} else {
  $stmt = $pdo->prepare("
    INSERT INTO documents (booking_id, user_id, doc_type, label, status, file_name, file_path, mime_type, uploaded_at)
    VALUES (?, ?, ?, ?, 'PENDING', ?, ?, ?, ?)
  ");
  $stmt->execute([$bookingId, $userId, $docType, $label, $originalName, $relativePath, $mimeType, $now]);
  $documentId = (int)$pdo->lastInsertId();
}

$publicUrl = $UPLOAD_URL ? rtrim($UPLOAD_URL, '/') . '/' . ltrim($relativePath, '/')
  : null;

ok([
  'id' => $documentId,
  'doc_type' => $docType,
  'label' => $label,
  'original_name' => $originalName,
  'stored_name' => $relativePath,
  'status' => 'PENDING',
  'file_url' => $publicUrl,
  'size' => $size,
  'mime_type' => $mimeType,
]);
