<?php
// JSON & CORS
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

function respond($ok, $data = null, $error = null) {
  echo json_encode(['success' => $ok, 'data' => $data, 'error' => $error], JSON_UNESCAPED_UNICODE);
  exit;
}

function body() {
  $raw = file_get_contents('php://input');
  if (!$raw) return [];
  $json = json_decode($raw, true);
  return is_array($json) ? $json : [];
}

function require_fields($arr, $fields) {
  foreach ($fields as $f) { if (!isset($arr[$f]) || $arr[$f]==='') respond(false, null, "Missing field: $f"); }
}

function ok($data = []) { respond(true, $data, null); }
function fail($msg, $code=400) { http_response_code($code); respond(false, null, $msg); }

function mask_email($email) {
  if (strpos($email,'@')===false) return $email;
  list($u,$d) = explode('@',$email,2);
  $m = substr($u,0,1) . str_repeat('*', max(1, strlen($u)-2)) . substr($u,-1);
  return $m.'@'.$d;
}

function normalize_date_value($value) {
  if ($value === null) return null;
  if ($value instanceof DateTimeInterface) return $value->format('Y-m-d');
  $text = trim((string)$value);
  if ($text === '') return null;

  // Try common date formats explicitly before falling back to strtotime.
  $formats = ['Y-m-d', 'd/m/Y', 'd-m-Y', 'm/d/Y', 'm-d-Y', 'Y/m/d'];
  foreach ($formats as $format) {
    $dt = DateTime::createFromFormat($format, $text);
    if ($dt instanceof DateTime) {
      $errors = DateTime::getLastErrors();
      $warningCount = is_array($errors) ? ($errors['warning_count'] ?? 0) : 0;
      $errorCount = is_array($errors) ? ($errors['error_count'] ?? 0) : 0;
      if ($warningCount === 0 && $errorCount === 0) {
        return $dt->format('Y-m-d');
      }
    }
  }

  $ts = strtotime($text);
  return $ts === false ? null : date('Y-m-d', $ts);
}

function normalize_gender_value($value) {
  if ($value === null) return null;
  $lower = strtolower(trim((string)$value));
  if ($lower === '') return null;
  if (in_array($lower, ['m', 'male'], true)) return 'male';
  if (in_array($lower, ['f', 'female'], true)) return 'female';
  if (in_array($lower, ['other', 'o'], true)) return 'other';
  return null;
}

function normalize_relationship_value($value) {
  $allowed = ['SPOUSE','CHILD','PARENT','SIBLING','FRIEND','OTHER'];
  $upper = strtoupper(trim((string)$value));
  return in_array($upper, $allowed, true) ? $upper : 'OTHER';
}

function normalize_bool_value($value, $default = null) {
  if (is_bool($value)) return $value;
  if (is_int($value)) {
    if ($value === 1) return true;
    if ($value === 0) return false;
  }
  if (is_string($value)) {
    $lower = strtolower(trim($value));
    if (in_array($lower, ['1','true','yes','y','on'], true)) return true;
    if (in_array($lower, ['0','false','no','n','off'], true)) return false;
  }
  return $default;
}

function ensure_user_settings_table(PDO $pdo): void {
  static $created = false;
  if ($created) {
    return;
  }
  $pdo->exec("
    CREATE TABLE IF NOT EXISTS user_settings (
      user_id INT NOT NULL PRIMARY KEY,
      settings_json JSON NOT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT fk_user_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ");
  $created = true;
}

function fetch_privacy_settings(PDO $pdo, int $userId): array {
  ensure_user_settings_table($pdo);
  $defaults = [
    'two_factor' => false,
    'biometric_login' => false,
    'trusted_devices' => true,
    'personalized_recommendations' => true,
  ];
  $stmt = $pdo->prepare("SELECT settings_json FROM user_settings WHERE user_id = ? LIMIT 1");
  $stmt->execute([$userId]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC);
  if ($row && !empty($row['settings_json'])) {
    $json = json_decode($row['settings_json'], true);
    if (is_array($json)) {
      foreach ($defaults as $key => $default) {
        if (array_key_exists($key, $json)) {
          $defaults[$key] = (bool)$json[$key];
        }
      }
    }
  }
  return $defaults;
}

function save_privacy_settings(PDO $pdo, int $userId, array $settings): void {
  ensure_user_settings_table($pdo);
  $stmt = $pdo->prepare("
    INSERT INTO user_settings (user_id, settings_json)
    VALUES (?, ?)
    ON DUPLICATE KEY UPDATE settings_json = VALUES(settings_json), updated_at = CURRENT_TIMESTAMP
  ");
  $stmt->execute([
    $userId,
    json_encode($settings, JSON_UNESCAPED_UNICODE),
  ]);
}

function ensure_booking_request_tables(PDO $pdo): void {
  static $ensured = false;
  if ($ensured) {
    return;
  }

  $pdo->exec("
    CREATE TABLE IF NOT EXISTS booking_requests (
      id INT NOT NULL AUTO_INCREMENT,
      user_id INT NOT NULL,
      package_id INT NOT NULL,
      adults INT NOT NULL DEFAULT 1,
      children INT NOT NULL DEFAULT 0,
      rooms INT NOT NULL DEFAULT 1,
      status ENUM('NOT_CONFIRMED','AWAITING_REQUIREMENTS','READY_FOR_REVIEW','APPROVED','REJECTED') NOT NULL DEFAULT 'NOT_CONFIRMED',
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      departure_date DATE DEFAULT NULL,
      total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
      documents_ready TINYINT(1) NOT NULL DEFAULT 0,
      payment_ready TINYINT(1) NOT NULL DEFAULT 0,
      notes TEXT NULL,
      approved_booking_id INT DEFAULT NULL,
      approved_at DATETIME DEFAULT NULL,
      approved_by INT DEFAULT NULL,
      PRIMARY KEY (id),
      KEY idx_booking_requests_user (user_id),
      KEY idx_booking_requests_status (status),
      KEY idx_booking_requests_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ");

  $pdo->exec("
    CREATE TABLE IF NOT EXISTS booking_request_travellers (
      id INT NOT NULL AUTO_INCREMENT,
      booking_request_id INT NOT NULL,
      full_name VARCHAR(200) NOT NULL,
      passport_no VARCHAR(100) DEFAULT NULL,
      dob DATE DEFAULT NULL,
      gender VARCHAR(20) DEFAULT NULL,
      passport_issue_date DATE DEFAULT NULL,
      passport_expiry_date DATE DEFAULT NULL,
      PRIMARY KEY (id),
      KEY idx_request_travellers_booking (booking_request_id),
      CONSTRAINT fk_request_travellers_request FOREIGN KEY (booking_request_id)
        REFERENCES booking_requests (id)
        ON DELETE CASCADE ON UPDATE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ");

  if (!db_column_exists($pdo, 'documents', 'booking_request_id')) {
    $pdo->exec("ALTER TABLE documents ADD COLUMN booking_request_id INT DEFAULT NULL AFTER booking_id");
    $pdo->exec("ALTER TABLE documents ADD KEY idx_documents_booking_request (booking_request_id)");
    try {
      $pdo->exec("ALTER TABLE documents ADD CONSTRAINT fk_documents_booking_request FOREIGN KEY (booking_request_id) REFERENCES booking_requests (id) ON DELETE CASCADE ON UPDATE CASCADE");
    } catch (Throwable $e) {
      // Constraint might already exist or fail in shared hosting; ignore.
    }
  }

  if (!db_column_exists($pdo, 'payments', 'booking_request_id')) {
    try {
      $pdo->exec("ALTER TABLE payments MODIFY booking_id INT DEFAULT NULL");
    } catch (Throwable $e) {
      // ignore if already nullable
    }
    $pdo->exec("ALTER TABLE payments ADD COLUMN booking_request_id INT DEFAULT NULL AFTER booking_id");
    $pdo->exec("ALTER TABLE payments ADD KEY idx_payments_booking_request (booking_request_id)");
    try {
      $pdo->exec("ALTER TABLE payments ADD CONSTRAINT fk_payments_booking_request FOREIGN KEY (booking_request_id) REFERENCES booking_requests (id) ON DELETE CASCADE ON UPDATE CASCADE");
    } catch (Throwable $e) {
      // ignore
    }
  }

  if (!db_column_exists($pdo, 'booking_requests', 'rooms')) {
    $pdo->exec("ALTER TABLE booking_requests ADD COLUMN rooms INT NOT NULL DEFAULT 1 AFTER children");
  }
  if (!db_column_exists($pdo, 'bookings', 'rooms')) {
    $pdo->exec("ALTER TABLE bookings ADD COLUMN rooms INT NOT NULL DEFAULT 1 AFTER children");
  }

  $ensured = true;
}

function booking_required_document_types(): array {
  return ['PASSPORT','INSURANCE','VISA','PAYMENT_PROOF'];
}

function ensure_package_reviews_table(PDO $pdo): void {
  static $done = false;
  if ($done) {
    return;
  }
  $pdo->exec("
    CREATE TABLE IF NOT EXISTS package_reviews (
      id INT NOT NULL AUTO_INCREMENT,
      package_id INT NOT NULL,
      user_id INT NOT NULL,
      rating TINYINT NOT NULL,
      comment TEXT NULL,
      created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      PRIMARY KEY (id),
      UNIQUE KEY uniq_package_user (package_id, user_id),
      KEY idx_package_reviews_package (package_id),
      KEY idx_package_reviews_user (user_id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  ");
  $done = true;
}

function format_package_review_row(array $row, int $currentUserId = 0): array {
  $name = trim((string)($row['user_name'] ?? $row['user_username'] ?? ''));
  if ($name === '') {
    $name = 'Traveler';
  }
  $initials = reviewer_initials($name);
  $photo = $row['profile_photo_url'] ?? $row['profile_photo'] ?? null;
  return [
    'id' => (int)($row['id'] ?? 0),
    'package_id' => (int)($row['package_id'] ?? 0),
    'user_id' => (int)($row['user_id'] ?? 0),
    'rating' => (int)($row['rating'] ?? 0),
    'comment' => $row['comment'] ?? null,
    'created_at' => $row['created_at'] ?? null,
    'updated_at' => $row['updated_at'] ?? null,
    'reviewer_name' => $name,
    'reviewer_initials' => $initials,
    'reviewer_photo' => $photo,
    'is_mine' => $currentUserId > 0 && (int)($row['user_id'] ?? 0) === $currentUserId,
  ];
}

function reviewer_initials(string $name): string {
  $substr = function (string $text, int $start, int $length = 1): string {
    if (function_exists('mb_substr')) {
      return mb_substr($text, $start, $length);
    }
    return substr($text, $start, $length);
  };
  $strlen = function (string $text): int {
    if (function_exists('mb_strlen')) {
      return mb_strlen($text);
    }
    return strlen($text);
  };
  $trimmed = trim($name);
  if ($trimmed === '') {
    return 'T';
  }
  $parts = preg_split('/\s+/', $trimmed) ?: [];
  $first = $substr($parts[0], 0, 1);
  $second = '';
  if (count($parts) > 1) {
    $second = $substr($parts[count($parts) - 1], 0, 1);
  } elseif ($strlen($trimmed) > 1) {
    $second = $substr($trimmed, 1, 1);
  }
  $initials = $first . $second;
  return function_exists('mb_strtoupper') ? mb_strtoupper($initials) : strtoupper($initials);
}

function package_rating_summary(PDO $pdo, int $packageId): array {
  ensure_package_reviews_table($pdo);
  $stmt = $pdo->prepare("SELECT COUNT(*) AS total, AVG(rating) AS avg_rating FROM package_reviews WHERE package_id = ?");
  $stmt->execute([$packageId]);
  $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['total' => 0, 'avg_rating' => null];
  $count = (int)($row['total'] ?? 0);
  $avg = $row['avg_rating'] !== null ? round((float)$row['avg_rating'], 2) : null;
  return [
    'rating_count' => $count,
    'rating_avg' => $avg,
  ];
}

function recalc_package_rating(PDO $pdo, int $packageId): array {
  ensure_package_reviews_table($pdo);
  $summary = package_rating_summary($pdo, $packageId);
  $stmt = $pdo->prepare("UPDATE packages SET rating_avg = ?, rating_count = ? WHERE id = ?");
  $stmt->execute([$summary['rating_avg'], $summary['rating_count'], $packageId]);
  return $summary;
}

function user_can_review_package(PDO $pdo, int $userId, int $packageId): bool {
  $stmt = $pdo->prepare("SELECT 1 FROM bookings WHERE user_id = ? AND package_id = ? LIMIT 1");
  $stmt->execute([$userId, $packageId]);
  if ($stmt->fetchColumn()) {
    return true;
  }
  $stmt = $pdo->prepare("
    SELECT 1
    FROM booking_requests
    WHERE user_id = ? AND package_id = ? AND status IN ('READY_FOR_REVIEW','APPROVED')
    LIMIT 1
  ");
  $stmt->execute([$userId, $packageId]);
  return (bool)$stmt->fetchColumn();
}

function booking_request_display_id(int $requestId): int {
  return -abs($requestId);
}

function booking_request_id_from_display(int $bookingId): int {
  return abs($bookingId);
}

function is_booking_request_identifier(int $bookingId): bool {
  return $bookingId < 0;
}

function fetch_booking_context(PDO $pdo, int $identifier, ?int $userId = null): array {
  ensure_booking_request_tables($pdo);
  if (is_booking_request_identifier($identifier)) {
    $requestId = booking_request_id_from_display($identifier);
    $sql = "SELECT * FROM booking_requests WHERE id=?";
    $params = [$requestId];
    if ($userId !== null && $userId > 0) {
      $sql .= " AND user_id=?";
      $params[] = $userId;
    }
    $stmt = $pdo->prepare($sql . " LIMIT 1");
    $stmt->execute($params);
    $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
    return [
      'found' => $row !== null,
      'kind' => 'request',
      'display_id' => $identifier,
      'request_id' => $requestId,
      'booking_id' => null,
      'row' => $row,
    ];
  }

  $sql = "SELECT * FROM bookings WHERE id=?";
  $params = [$identifier];
  if ($userId !== null && $userId > 0) {
    $sql .= " AND user_id=?";
    $params[] = $userId;
  }
  $stmt = $pdo->prepare($sql . " LIMIT 1");
  $stmt->execute($params);
  $row = $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
  return [
    'found' => $row !== null,
    'kind' => 'booking',
    'display_id' => $identifier,
    'request_id' => null,
    'booking_id' => $row ? $identifier : null,
    'row' => $row,
  ];
}

function refresh_booking_request_progress(PDO $pdo, int $requestId): array {
  ensure_booking_request_tables($pdo);
  $stmt = $pdo->prepare("SELECT id, status, total_amount FROM booking_requests WHERE id=? LIMIT 1");
  $stmt->execute([$requestId]);
  $request = $stmt->fetch(PDO::FETCH_ASSOC);
  if (!$request) {
    return ['exists' => false];
  }

  $requiredDocs = booking_required_document_types();
  $docPlaceholders = implode(',', array_fill(0, count($requiredDocs), '?'));
  $docStmt = $pdo->prepare("
    SELECT doc_type,
           MAX(CASE WHEN file_path IS NOT NULL AND file_path <> '' THEN 1 ELSE 0 END) AS has_file
    FROM documents
    WHERE booking_request_id = ? AND doc_type IN ($docPlaceholders)
    GROUP BY doc_type
  ");
  $docStmt->execute(array_merge([$requestId], $requiredDocs));
  $docStatus = array_fill_keys($requiredDocs, 0);
  while ($row = $docStmt->fetch(PDO::FETCH_ASSOC)) {
    $docType = strtoupper((string)($row['doc_type'] ?? ''));
    if ($docType !== '' && array_key_exists($docType, $docStatus)) {
      $docStatus[$docType] = (int)$row['has_file'] === 1 ? 1 : 0;
    }
  }
  $docsReady = !in_array(0, $docStatus, true) && count($docStatus) === count($requiredDocs);

  $payStmt = $pdo->prepare("SELECT COALESCE(SUM(amount),0) AS paid FROM payments WHERE booking_request_id = ? AND status = 'PAID'");
  $payStmt->execute([$requestId]);
  $paidAmount = (float)$payStmt->fetchColumn();
  $totalAmount = isset($request['total_amount']) ? (float)$request['total_amount'] : 0.0;
  $paymentReady = $totalAmount <= 0 ? true : ($paidAmount + 0.01) >= $totalAmount;

  $currentStatus = $request['status'] ?? 'NOT_CONFIRMED';
  $newStatus = $currentStatus;
  if (!in_array($currentStatus, ['APPROVED','REJECTED'], true)) {
    if ($docsReady && $paymentReady) {
      $newStatus = 'READY_FOR_REVIEW';
    } elseif ($docsReady || $paymentReady) {
      $newStatus = 'AWAITING_REQUIREMENTS';
    } else {
      $newStatus = 'NOT_CONFIRMED';
    }
  }

  $updateStmt = $pdo->prepare("
    UPDATE booking_requests
    SET documents_ready = ?,
        payment_ready = ?,
        status = ?
    WHERE id = ?
  ");
  $updateStmt->execute([
    $docsReady ? 1 : 0,
    $paymentReady ? 1 : 0,
    $newStatus,
    $requestId,
  ]);

  return [
    'exists' => true,
    'documents_ready' => $docsReady,
    'payment_ready' => $paymentReady,
    'status' => $newStatus,
    'total_amount' => $totalAmount,
    'paid_amount' => $paidAmount,
  ];
}

function normalize_key_identifier(string $key): string {
  return preg_replace('/[^a-z0-9]/', '', strtolower($key));
}

function build_normalized_key_map(array $row): array {
  $map = [];
  foreach ($row as $key => $value) {
    if (!is_string($key)) continue;
    $map[normalize_key_identifier($key)] = $value;
  }
  return $map;
}

function array_pick_value(array $row, array $normalizedMap, array $candidates, bool $trim = true) {
  foreach ($candidates as $candidate) {
    $value = null;
    if (is_string($candidate) && array_key_exists($candidate, $row)) {
      $value = $row[$candidate];
    } else {
      $normalizedKey = normalize_key_identifier((string)$candidate);
      if (array_key_exists($normalizedKey, $normalizedMap)) {
        $value = $normalizedMap[$normalizedKey];
      }
    }
    if ($value === null) continue;
    if ($trim && is_string($value)) {
      $value = trim($value);
      if ($value === '') continue;
    }
    return $value;
  }
  return null;
}

function db_column_exists(PDO $pdo, string $table, string $column) {
  static $cache = [];
  $key = $table . ':' . $column;
  if (array_key_exists($key, $cache)) {
    return $cache[$key];
  }
  $stmt = $pdo->prepare("
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?
  ");
  $stmt->execute([$table, $column]);
  $cache[$key] = $stmt->fetchColumn() > 0;
  return $cache[$key];
}

function send_email(string $toEmail, string $subject, string $body): bool {
  global $MAIL_HOST, $MAIL_PORT, $MAIL_USERNAME, $MAIL_PASSWORD, $MAIL_SECURE, $MAIL_FROM, $MAIL_FROM_NAME, $MAIL_REPLY_TO;

  if (!filter_var($toEmail, FILTER_VALIDATE_EMAIL)) {
    return false;
  }

  $host = $MAIL_HOST ?: '';
  $port = (int)($MAIL_PORT ?? 0);
  $username = $MAIL_USERNAME ?? '';
  $password = $MAIL_PASSWORD ?? '';
  $secure = in_array(strtolower((string)$MAIL_SECURE), ['ssl', 'tls'], true) ? strtolower((string)$MAIL_SECURE) : 'tls';
  if ($port <= 0) {
    $port = ($secure === 'ssl') ? 465 : 587;
  }

  $fromEmail = $MAIL_FROM ?: ($username ?: 'no-reply@localhost');
  $fromName = $MAIL_FROM_NAME ?: $fromEmail;
  $replyTo = $MAIL_REPLY_TO ?: $fromEmail;

  try {
    smtp_send_email([
      'host' => $host,
      'port' => $port,
      'secure' => $secure,
      'username' => $username,
      'password' => $password,
      'from_email' => $fromEmail,
      'from_name' => $fromName,
      'reply_to' => $replyTo,
      'to_email' => $toEmail,
      'subject' => $subject,
      'body' => $body,
    ]);
    return true;
  } catch (Throwable $e) {
    error_log('SMTP send failed: ' . $e->getMessage());
    return false;
  }
}

function smtp_send_email(array $config): void {
  $host = $config['host'] ?? '';
  if ($host === '') {
    throw new RuntimeException('SMTP host not configured');
  }
  $port = (int)($config['port'] ?? 587);
  $secure = $config['secure'] ?? 'tls';
  $username = $config['username'] ?? '';
  $password = $config['password'] ?? '';
  $fromEmail = $config['from_email'];
  $fromName = $config['from_name'] ?? $fromEmail;
  $replyTo = $config['reply_to'] ?? $fromEmail;
  $toEmail = $config['to_email'];
  $subject = $config['subject'];
  $body = $config['body'];

  $transportHost = $host;
  $remote = $host . ':' . $port;
  $contextOptions = [];

  if ($secure === 'ssl') {
    $transportHost = 'ssl://' . $host;
  } elseif ($secure === 'tls') {
    $contextOptions['ssl'] = [
      'verify_peer' => true,
      'verify_peer_name' => true,
      'allow_self_signed' => false,
    ];
  }

  $context = stream_context_create($contextOptions);
  $socket = @stream_socket_client($transportHost . ':' . $port, $errno, $errstr, 30, STREAM_CLIENT_CONNECT, $context);
  if (!$socket) {
    throw new RuntimeException("Unable to connect to SMTP server: $errstr ($errno)");
  }

  try {
    smtp_expect($socket, [220]);
    smtp_send($socket, 'EHLO ' . ($host ?: 'localhost'), [250]);

    if ($secure === 'tls') {
      smtp_send($socket, 'STARTTLS', [220]);
      $cryptoMethods = smtp_crypto_method();
      $enabled = $cryptoMethods === 0
        ? stream_socket_enable_crypto($socket, true)
        : stream_socket_enable_crypto($socket, true, $cryptoMethods);
      if (!$enabled) {
        throw new RuntimeException('Failed to initiate TLS encryption');
      }
      smtp_send($socket, 'EHLO ' . ($host ?: 'localhost'), [250]);
    }

    if ($username !== '' && $password !== '') {
      smtp_send($socket, 'AUTH LOGIN', [334]);
      smtp_send($socket, base64_encode($username), [334]);
      smtp_send($socket, base64_encode($password), [235]);
    }

    smtp_send($socket, 'MAIL FROM:<' . $fromEmail . '>', [250]);
    smtp_send($socket, 'RCPT TO:<' . $toEmail . '>', [250, 251]);
    smtp_send($socket, 'DATA', [354]);

    $headers = [];
    $headers[] = 'Date: ' . gmdate('D, d M Y H:i:s O');
    $headers[] = 'From: ' . format_email_header($fromName, $fromEmail);
    if ($replyTo) {
      $headers[] = 'Reply-To: ' . $replyTo;
    }
    $headers[] = 'To: ' . $toEmail;
    $headers[] = 'MIME-Version: 1.0';
    $headers[] = 'Content-Type: text/plain; charset=UTF-8';
    $headers[] = 'Content-Transfer-Encoding: 8bit';
    $headers[] = 'Subject: ' . encode_header($subject);

    $bodyNormalized = normalize_newlines($body);
    $bodySafe = str_replace(["\r\n.", "\n.", "\r."], ["\r\n..", "\n..", "\r.."], $bodyNormalized);
    $data = implode("\r\n", $headers) . "\r\n\r\n" . $bodySafe . "\r\n.";
    smtp_send_raw($socket, $data . "\r\n");
    smtp_expect($socket, [250]);
    smtp_send($socket, 'QUIT', [221]);
  } finally {
    fclose($socket);
  }
}

function smtp_send($socket, string $command, array $expectedCodes): void {
  smtp_send_raw($socket, $command . "\r\n");
  smtp_expect($socket, $expectedCodes);
}

function smtp_send_raw($socket, string $data): void {
  $written = fwrite($socket, $data);
  if ($written === false || $written === 0) {
    throw new RuntimeException('Failed to write to SMTP socket');
  }
}

function smtp_expect($socket, array $expectedCodes): void {
  $response = smtp_read_response($socket);
  if ($response === '') {
    throw new RuntimeException('Empty response from SMTP server');
  }
  $code = (int)substr($response, 0, 3);
  if (!in_array($code, $expectedCodes, true)) {
    throw new RuntimeException('Unexpected SMTP response: ' . trim($response));
  }
}

function smtp_read_response($socket): string {
  $data = '';
  while (($line = fgets($socket, 515)) !== false) {
    $data .= $line;
    if (isset($line[3]) && $line[3] === ' ') {
      break;
    }
  }
  return $data;
}

function smtp_crypto_method(): int {
  $methods = 0;
  $candidates = [
    'STREAM_CRYPTO_METHOD_TLS_CLIENT',
    'STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT',
    'STREAM_CRYPTO_METHOD_TLSv1_1_CLIENT',
    'STREAM_CRYPTO_METHOD_TLSv1_0_CLIENT',
    'STREAM_CRYPTO_METHOD_SSLv23_CLIENT',
  ];
  foreach ($candidates as $name) {
    if (defined($name)) {
      $methods |= constant($name);
    }
  }
  return $methods ?: 0;
}

function encode_header(string $value): string {
  if (function_exists('mb_encode_mimeheader')) {
    return mb_encode_mimeheader($value, 'UTF-8');
  }
  return '=?UTF-8?B?' . base64_encode($value) . '?=';
}

function format_email_header(string $name, string $email): string {
  if ($name === '' || $name === $email) {
    return $email;
  }
  return encode_header($name) . ' <' . $email . '>';
}

function normalize_newlines(string $text): string {
  $text = str_replace(["\r\n", "\r"], "\n", $text);
  return implode("\r\n", explode("\n", $text));
}
