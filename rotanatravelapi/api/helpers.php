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
  $ts = strtotime($text);
  return $ts === false ? null : date('Y-m-d', $ts);
}

function normalize_gender_value($value) {
  if ($value === null) return null;
  $lower = strtolower(trim((string)$value));
  if ($lower === 'male' || $lower === 'female') return $lower;
  return null;
}

function normalize_relationship_value($value) {
  $allowed = ['SPOUSE','CHILD','PARENT','SIBLING','FRIEND','OTHER'];
  $upper = strtoupper(trim((string)$value));
  return in_array($upper, $allowed, true) ? $upper : 'OTHER';
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
