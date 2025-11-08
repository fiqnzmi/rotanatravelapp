<?php
// Always return JSON (never echo HTML)
header('Content-Type: application/json; charset=utf-8');
// (Optional) If calling from emulator/web
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

// Never show PHP warnings/notices in output (they cause "<br/>")
ini_set('display_errors', 0);
ini_set('log_errors', 1);             // log to Apache/PHP error log instead
error_reporting(E_ALL);

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

function json_out(array $payload, int $code = 200): void {
  http_response_code($code);
  echo json_encode($payload, JSON_UNESCAPED_UNICODE);
  exit;
}

// Read JSON body safely
function read_json_body(): array {
  $raw = file_get_contents('php://input') ?: '';
  $data = json_decode($raw, true);
  return is_array($data) ? $data : [];
}
