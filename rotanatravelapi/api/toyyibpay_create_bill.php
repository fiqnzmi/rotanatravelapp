<?php
require_once __DIR__ . '/_bootstrap.php';

try {
  global $APP_ENV;

  $input = read_json_body();

  $bookingId = (int)($input['booking_id'] ?? 0);
  if ($bookingId <= 0) {
    json_out(['success' => false, 'error' => 'booking_id is required'], 422);
  }

  $pdo = db();
  $bookingStmt = $pdo->prepare("
    SELECT b.id,
           b.user_id,
           b.total_amount,
           b.departure_date,
           u.name,
           u.username,
           u.email
    FROM bookings b
    JOIN users u ON u.id = b.user_id
    WHERE b.id = ?
    LIMIT 1
  ");
  $bookingStmt->execute([$bookingId]);
  $booking = $bookingStmt->fetch();
  if (!$booking) {
    json_out(['success' => false, 'error' => 'Booking not found'], 404);
  }

  $amount = isset($input['amount']) ? (float)$input['amount'] : (float)$booking['total_amount'];
  if ($amount <= 0) {
    json_out(['success' => false, 'error' => 'Amount must be greater than zero'], 422);
  }

  global $TOYYIBPAY_SECRET_KEY, $TOYYIBPAY_CATEGORY_CODE, $TOYYIBPAY_BASE_URL, $TOYYIBPAY_RETURN_URL, $TOYYIBPAY_CALLBACK_URL, $TOYYIBPAY_DEFAULT_PHONE, $TOYYIBPAY_DEFAULT_EMAIL;
  if ($TOYYIBPAY_SECRET_KEY === '' || $TOYYIBPAY_CATEGORY_CODE === '') {
    json_out(['success' => false, 'error' => 'Toyyibpay credentials are not configured'], 500);
  }

  $billName = trim($input['bill_name'] ?? ('Booking #' . $bookingId));
  $billDescription = trim($input['bill_description'] ?? ('Payment for booking #' . $bookingId));
  $customerName = trim($input['customer_name'] ?? ($booking['name'] ?: $booking['username'] ?: 'Customer'));
  $customerEmail = trim($input['customer_email'] ?? $booking['email'] ?? '');
  if ($customerEmail === '') {
    global $TOYYIBPAY_DEFAULT_EMAIL;
    $customerEmail = $TOYYIBPAY_DEFAULT_EMAIL;
  }
  $customerPhone = trim($input['customer_phone'] ?? '');
  if ($customerPhone === '' && $TOYYIBPAY_DEFAULT_PHONE !== '') {
    $customerPhone = $TOYYIBPAY_DEFAULT_PHONE;
  }
  if ($customerPhone === '') {
    json_out(['success' => false, 'error' => 'customer_phone is required'], 422);
  }
  $dueDays = isset($input['due_in_days']) ? (int)$input['due_in_days'] : null;
  $externalRef = $input['external_ref'] ?? ('BOOK-' . $bookingId . '-' . time());

  $billPayload = [
    'userSecretKey' => $TOYYIBPAY_SECRET_KEY,
    'categoryCode' => $TOYYIBPAY_CATEGORY_CODE,
    'billName' => $billName,
    'billDescription' => $billDescription,
    'billPriceSetting' => 1, // amount is pre-defined
    'billAmount' => (int)round($amount * 100), // Toyyibpay expects cents
    'billTo' => $customerName,
    'billEmail' => $customerEmail,
    'billPhone' => $customerPhone,
    'billPayorInfo' => 1,
    'billPaymentChannel' => 0, // all channels
    'billChargeToCustomer' => 1,
    'billExternalReferenceNo' => $externalRef,
  ];

  if ($TOYYIBPAY_RETURN_URL) {
    $billPayload['billReturnUrl'] = $input['return_url'] ?? $TOYYIBPAY_RETURN_URL;
  } elseif (!empty($input['return_url'])) {
    $billPayload['billReturnUrl'] = $input['return_url'];
  }

  if ($TOYYIBPAY_CALLBACK_URL) {
    $billPayload['billCallbackUrl'] = $input['callback_url'] ?? $TOYYIBPAY_CALLBACK_URL;
  } elseif (!empty($input['callback_url'])) {
    $billPayload['billCallbackUrl'] = $input['callback_url'];
  }

  if ($dueDays !== null && $dueDays > 0) {
    $billPayload['billExpiryDays'] = $dueDays;
  }
  if (!empty($booking['departure_date'])) {
    $billPayload['billExpiryDate'] = date('d-m-Y', strtotime($booking['departure_date']));
  }

  $endpoint = rtrim($TOYYIBPAY_BASE_URL, '/') . '/index.php/api/createBill';

  $ch = curl_init($endpoint);
  $curlOptions = [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => http_build_query($billPayload),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_SSL_VERIFYPEER => true,
  ];

  if ($APP_ENV !== 'production') {
    $curlOptions[CURLOPT_SSL_VERIFYPEER] = false;
    $curlOptions[CURLOPT_SSL_VERIFYHOST] = 0;
  }

  curl_setopt_array($ch, $curlOptions);
  $raw = curl_exec($ch);
  if ($raw === false) {
    $err = curl_error($ch);
    curl_close($ch);
    json_out(['success' => false, 'error' => 'Toyyibpay request failed: ' . $err], 502);
  }
  $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  @file_put_contents(__DIR__ . '/../toyyibpay_last_response.log', json_encode([
    'time' => date('c'),
    'http_code' => $httpCode,
    'body' => $raw,
  ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

  $decoded = json_decode($raw, true);
  if ($httpCode >= 400 || !is_array($decoded)) {
    json_out([
      'success' => false,
      'error' => 'Invalid response from Toyyibpay',
      'debug' => $APP_ENV === 'development' ? ['http_code' => $httpCode, 'body' => $raw] : null,
    ], 502);
  }

  $billInfo = $decoded[0] ?? (isset($decoded['BillCode']) ? $decoded : null);
  $billCode = is_array($billInfo) ? ($billInfo['BillCode'] ?? $billInfo['billCode'] ?? null) : null;
  $billLink = is_array($billInfo)
    ? ($billInfo['BillpaymentLink']
        ?? $billInfo['BillPaymentLink']
        ?? $billInfo['billpaymentLink']
        ?? $billInfo['billPaymentLink']
        ?? null)
    : null;
  if (!$billLink && $billCode) {
    $billLink = rtrim($TOYYIBPAY_BASE_URL, '/') . '/' . ltrim($billCode, '/');
  }

  if (!is_array($billInfo) || !$billCode || !$billLink) {
    $errorMsg = $billInfo['msg'] ?? ($decoded['msg'] ?? 'Unexpected Toyyibpay response');
    json_out([
      'success' => false,
      'error' => $errorMsg,
      'debug' => $APP_ENV === 'development' ? ['http_code' => $httpCode, 'body' => $raw, 'decoded' => $decoded] : null,
    ], 502);
  }

  $gatewayPayload = [
    'bill' => $billInfo,
    'request' => [
      'amount' => $amount,
      'customer_name' => $customerName,
      'customer_email' => $customerEmail,
      'customer_phone' => $customerPhone,
      'external_ref' => $externalRef,
      'return_url' => $billPayload['billReturnUrl'] ?? null,
      'callback_url' => $billPayload['billCallbackUrl'] ?? null,
    ],
  ];

  $pdo->prepare("
      INSERT INTO payments (booking_id, amount, currency, method, status, transaction_ref, gateway_payload, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, NOW())
    ")
    ->execute([
      $bookingId,
      $amount,
      'MYR',
      'FPX',
      'PENDING',
      $billCode,
      json_encode($gatewayPayload, JSON_UNESCAPED_UNICODE)
    ]);
  $paymentId = (int)$pdo->lastInsertId();
  $gatewayPayload['request']['payment_id'] = $paymentId;
  $pdo->prepare("UPDATE payments SET gateway_payload = ? WHERE id = ?")
      ->execute([json_encode($gatewayPayload, JSON_UNESCAPED_UNICODE), $paymentId]);

  json_out([
    'success' => true,
    'data' => [
      'payment_id' => $paymentId,
      'bill_code' => $billCode,
      'payment_url' => $billLink,
      'amount' => $amount,
    ],
    'error' => null,
  ]);
} catch (Throwable $e) {
  @file_put_contents(
    __DIR__ . '/../toyyibpay_error.log',
    sprintf("[%s] %s\n%s\n\n", date('c'), $e->getMessage(), $e->getTraceAsString()),
    FILE_APPEND
  );
  json_out([
    'success' => false,
    'error' => 'Server error',
    'debug' => $APP_ENV === 'development' ? $e->getMessage() : null,
  ], 500);
}
