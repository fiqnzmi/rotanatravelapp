<?php
require_once 'db.php';
require_once 'helpers.php';
require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  fail('Only POST requests are allowed', 405);
}

if (!isset($_POST['user_id']) || (int)$_POST['user_id'] <= 0) {
  fail('Missing or invalid user_id');
}

if (!isset($_FILES['photo'])) {
  fail('Missing photo');
}

$userId = (int)$_POST['user_id'];
$photo = $_FILES['photo'];

$errorCode = $photo['error'] ?? UPLOAD_ERR_NO_FILE;
if ($errorCode !== UPLOAD_ERR_OK) {
  $messages = [
    UPLOAD_ERR_INI_SIZE   => 'The uploaded file exceeds the server size limit.',
    UPLOAD_ERR_FORM_SIZE  => 'The uploaded file exceeds the allowed size.',
    UPLOAD_ERR_PARTIAL    => 'The uploaded file was only partially received.',
    UPLOAD_ERR_NO_FILE    => 'No file was uploaded.',
    UPLOAD_ERR_NO_TMP_DIR => 'Server is missing a temporary folder.',
    UPLOAD_ERR_CANT_WRITE => 'Server failed to write the uploaded file.',
    UPLOAD_ERR_EXTENSION  => 'File upload stopped by a PHP extension.',
  ];
  $message = $messages[$errorCode] ?? 'Unknown upload error.';
  fail($message);
}

$originalName = (string)($photo['name'] ?? '');
$extension = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
$allowed = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
if ($extension === '' || !in_array($extension, $allowed, true)) {
  fail('Unsupported file type. Allowed: jpg, jpeg, png, webp, heic');
}

try {
  $pdo = db();
  $stmt = $pdo->prepare('SELECT profile_photo FROM users WHERE id = ? LIMIT 1');
  $stmt->execute([$userId]);
  $current = $stmt->fetch();
  if (!$current) {
    fail('User not found', 404);
  }

  global $UPLOAD_DIR, $UPLOAD_URL, $BASE_URL;

  $uploadDir = $UPLOAD_DIR;
  if (!$uploadDir || !is_dir($uploadDir)) {
    $uploadDir = __DIR__ . '/../uploads';
    if (!is_dir($uploadDir) && !@mkdir($uploadDir, 0775, true)) {
      fail('Upload directory is not available', 500);
    }
  }
  $uploadDir = realpath($uploadDir) ?: $uploadDir;

  $filename = 'profile_' . $userId . '_' . time() . '_' . bin2hex(random_bytes(4)) . '.' . $extension;
  $targetPath = rtrim($uploadDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $filename;

  if (!@move_uploaded_file($photo['tmp_name'], $targetPath)) {
    fail('Failed to store uploaded file', 500);
  }

  $relativePath = 'uploads/' . $filename;

  $uploadUrlBase = $UPLOAD_URL;
  if (!$uploadUrlBase) {
    $scriptDir = dirname($_SERVER['SCRIPT_NAME'] ?? '', 2);
    if ($scriptDir === '\\' || $scriptDir === '.') {
      $scriptDir = '';
    }
    $scriptDir = trim((string)$scriptDir, '/');
    $uploadUrlBase = rtrim($BASE_URL, '/');
    if ($scriptDir !== '') {
      $uploadUrlBase .= '/' . $scriptDir;
    }
    $uploadUrlBase .= '/uploads';
  }
  $photoUrl = rtrim($uploadUrlBase, '/') . '/' . $filename;

  $update = $pdo->prepare(
    'UPDATE users SET profile_photo = ?, profile_photo_url = ? WHERE id = ?'
  );
  $update->execute([$relativePath, $photoUrl, $userId]);
  if ($update->rowCount() === 0) {
    @unlink($targetPath);
    fail('Failed to update user record', 500);
  }

  $previousPath = (string)($current['profile_photo'] ?? '');
  if ($previousPath !== '' && stripos($previousPath, 'http') !== 0) {
    $previousName = basename($previousPath);
    $previousFullPath = rtrim($uploadDir, DIRECTORY_SEPARATOR) . DIRECTORY_SEPARATOR . $previousName;
    if (is_file($previousFullPath) && $previousFullPath !== $targetPath) {
      @unlink($previousFullPath);
    }
  }

  ok([
    'photo' => $photoUrl,
    'photo_url' => $photoUrl,
    'profile_photo' => $relativePath,
    'profile_photo_url' => $photoUrl,
    'filename' => $filename,
  ]);
} catch (Throwable $e) {
  error_log('upload_profile_photo.php: ' . $e->getMessage());
  fail('Server error', 500);
}
