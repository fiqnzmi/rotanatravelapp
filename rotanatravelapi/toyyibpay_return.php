<?php
$status = $_GET['status_id'] ?? $_GET['status'] ?? '';
$message = 'Processing your payment...';
if ($status === '1') {
  $message = 'Payment completed successfully. You may return to the app.';
} elseif ($status === '3') {
  $message = 'Payment failed or cancelled. You may return to the app.';
} elseif ($status === '2') {
  $message = 'Payment pending confirmation. You may return to the app.';
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Payment Status</title>
  <style>
    body { font-family: system-ui, sans-serif; text-align: center; padding: 32px; background: #f5f6fa; color: #222; }
    .card { max-width: 420px; margin: 0 auto; background: #fff; border-radius: 16px; padding: 28px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
    h1 { font-size: 1.4rem; margin-bottom: 12px; }
    p { margin: 0; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="card">
    <h1>Payment Status</h1>
    <p><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></p>
  </div>
</body>
</html>
