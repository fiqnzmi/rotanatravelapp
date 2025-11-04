<?php
require_once __DIR__ . '/_bootstrap.php';

try {
  // Toyyibpay posts form-encoded data; fall back to JSON if provided.
  $payload = $_POST;
  if (empty($payload)) {
    $raw = file_get_contents('php://input') ?: '';
    if ($raw !== '') {
      $decodedJson = json_decode($raw, true);
      if (is_array($decodedJson)) {
        $payload = $decodedJson;
      } else {
        parse_str($raw, $payload);
      }
    }
  }

  $billCode = trim((string)($payload['billcode'] ?? $payload['BillCode'] ?? $payload['bill_code'] ?? ''));
  $statusId = trim((string)($payload['status_id'] ?? $payload['status'] ?? ''));
  $transactionId = trim((string)($payload['transaction_id'] ?? $payload['transactionId'] ?? ''));

  if ($billCode === '') {
    json_out(['success' => false, 'error' => 'Missing billcode'], 400);
  }

  $pdo = db();
  $stmt = $pdo->prepare("SELECT id, status, gateway_payload FROM payments WHERE transaction_ref = ? ORDER BY id DESC LIMIT 1");
  $stmt->execute([$billCode]);
  $payment = $stmt->fetch(PDO::FETCH_ASSOC);

  if (!$payment && $transactionId !== '') {
    $stmt = $pdo->prepare("SELECT id, status, gateway_payload FROM payments WHERE transaction_ref = ? ORDER BY id DESC LIMIT 1");
    $stmt->execute([$transactionId]);
    $payment = $stmt->fetch(PDO::FETCH_ASSOC);
  }

  if (!$payment) {
    json_out(['success' => false, 'error' => 'Payment not found for billcode'], 404);
  }

  $paymentId = (int)$payment['id'];
  $status = strtoupper((string)$payment['status']);

  $newStatus = $status; // default keep existing
  $paidAtClause = '';

  switch ($statusId) {
    case '1':
      $newStatus = 'PAID';
      $paidAtClause = ", paid_at = IFNULL(paid_at, NOW())";
      break;
    case '2':
      if ($status !== 'PAID') {
        $newStatus = 'PENDING';
        $paidAtClause = ", paid_at = NULL";
      }
      break;
    case '3':
      if ($status !== 'PAID') {
        $newStatus = 'FAILED';
        $paidAtClause = ", paid_at = NULL";
      }
      break;
    default:
      // Leave status unchanged for unknown codes
      break;
  }

  $txRef = $transactionId !== '' ? $transactionId : $billCode;

  $updateSql = "UPDATE payments SET transaction_ref = ?, status = ?" . $paidAtClause . " WHERE id = ?";
  $pdo->prepare($updateSql)->execute([$txRef, $newStatus, $paymentId]);

  // Store callback payload for auditing
  $callbackLog = [
    'received_at' => date('c'),
    'payload' => $payload,
  ];
  if (!empty($payment['gateway_payload'])) {
    $existing = json_decode($payment['gateway_payload'], true);
    if (!is_array($existing)) {
      $existing = [];
    }
  } else {
    $existing = [];
  }
  $existing['callback'] = $callbackLog;

  $pdo->prepare("UPDATE payments SET gateway_payload = ? WHERE id = ?")
      ->execute([json_encode($existing, JSON_UNESCAPED_UNICODE), $paymentId]);

  json_out(['success' => true, 'data' => ['payment_id' => $paymentId, 'status' => $newStatus]], 200);
} catch (Throwable $e) {
  json_out([
    'success' => false,
    'error' => 'Server error',
    'debug' => $e->getMessage(),
  ], 500);
}
