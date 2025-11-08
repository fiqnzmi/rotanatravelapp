<?php
// admin_package.php â€” manage packages stored in rotanadb.packages
session_start();
if (!isset($_SESSION['user_id']) || strcasecmp($_SESSION['role'] ?? '', 'admin') !== 0) {
  header('Location: index.php');
  exit;
}

$pdo = new PDO(
  'mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4',
  'sabrisae_rotanatravel',
  'Rotanatravel_2025',
  [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]
);

$pending = $pdo->query("
  SELECT
    b.id,
    b.created_at,
    u.name  AS customer_name,
    p.title AS package_name
  FROM bookings b
  LEFT JOIN users u    ON u.id = b.user_id
  LEFT JOIN packages p ON p.id = b.package_id
  WHERE UPPER(b.status) = 'PENDING'
  ORDER BY b.created_at DESC
  LIMIT 10
")->fetchAll();
$pendingCount = count($pending);

$toyyibpayConfig = [
  'endpoint'         => 'https://toyyibpay.com/index.php/api/createBill',
  'userSecretKey'    => '6snobie9-a2hm-vdpp-9xa3-wv69aioimh6d',
  'categoryCode'     => '1pqcbh5e',
  'returnUrl'        => null, // override with absolute URL if desired
  'callbackUrl'      => null,
  'defaultBillTo'    => 'Rotana Travel Customer',
  'defaultBillEmail' => 'billing@rotana.local',
  'defaultBillPhone' => '0000000000',
];

// basic CSRF token
if (empty($_SESSION['csrf'])) {
  $_SESSION['csrf'] = bin2hex(random_bytes(16));
}
$csrf = $_SESSION['csrf'];

function ensureCsrf(): bool {
  return isset($_POST['csrf'], $_SESSION['csrf']) && hash_equals($_SESSION['csrf'], $_POST['csrf']);
}

function firstImage(string $json = null): ?string {
  if (!$json) return null;
  $decoded = json_decode($json, true);
  if (is_string($decoded)) return $decoded;
  if (is_array($decoded) && $decoded) {
    foreach ($decoded as $item) {
      if (is_string($item) && $item !== '') return $item;
    }
  }
  return null;
}

function imageJson(?string $value): ?string {
  $trimmed = trim((string)$value);
  if ($trimmed === '') return null;
  return json_encode([$trimmed], JSON_UNESCAPED_SLASHES);
}

function storePackageImage(?array $file, ?string $existingRelative = null): array {
  $result = [
    'ok'          => true,
    'path'        => $existingRelative,
    'uploadedNew' => false,
    'error'       => null,
  ];

  if (!$file || !isset($file['error']) || $file['error'] === UPLOAD_ERR_NO_FILE) {
    return $result;
  }

  if ($file['error'] !== UPLOAD_ERR_OK) {
    $result['ok'] = false;
    $result['error'] = 'Image upload failed (error code '.$file['error'].').';
    return $result;
  }

  $extension = strtolower(pathinfo($file['name'] ?? '', PATHINFO_EXTENSION));
  if ($extension === 'jpeg') {
    $extension = 'jpg';
  }
  $allowed = ['jpg', 'png', 'gif', 'webp'];
  if (!in_array($extension, $allowed, true)) {
    $result['ok'] = false;
    $result['error'] = 'Image must be JPG, PNG, GIF, or WEBP.';
    return $result;
  }

  $relativeDir = 'uploads/packages';
  $absoluteDir = __DIR__.DIRECTORY_SEPARATOR.str_replace('/', DIRECTORY_SEPARATOR, $relativeDir);
  if (!is_dir($absoluteDir) && !mkdir($absoluteDir, 0775, true) && !is_dir($absoluteDir)) {
    $result['ok'] = false;
    $result['error'] = 'Unable to create directory for package images.';
    return $result;
  }

  try {
    $filename = 'pkg_'.bin2hex(random_bytes(6)).'.'.$extension;
  } catch (Exception $e) {
    $result['ok'] = false;
    $result['error'] = 'Unable to generate filename for uploaded image.';
    return $result;
  }

  $destination = $absoluteDir.DIRECTORY_SEPARATOR.$filename;
  if (!move_uploaded_file($file['tmp_name'], $destination)) {
    $result['ok'] = false;
    $result['error'] = 'Failed to save the uploaded image.';
    return $result;
  }

  $result['path'] = $relativeDir.'/'.$filename;
  $result['uploadedNew'] = true;

  return $result;
}

function appBaseUrl(): string {
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
  $scriptDir = dirname($_SERVER['SCRIPT_NAME'] ?? '/') ?: '';
  return rtrim($scheme.'://'.$host.$scriptDir, '/');
}

function createToyyibBill(array $config, array $package): array {
  $result = ['ok' => false, 'billCode' => null, 'billUrl' => null, 'error' => null, 'raw' => null];

  if (empty($config['userSecretKey']) || empty($config['categoryCode'])) {
    $result['error'] = 'Toyyibpay credentials are not configured.';
    return $result;
  }
  if (!function_exists('curl_init')) {
    $result['error'] = 'PHP cURL extension is not enabled.';
    return $result;
  }

  $amount = (float)($package['price'] ?? 0);
  if ($amount <= 0) {
    $result['error'] = 'Toyyibpay skipped: amount must be greater than 0.';
    return $result;
  }

  $endpoint = $config['endpoint'] ?? 'https://toyyibpay.com/index.php/api/createBill';
  $packageName = (string)($package['name'] ?? 'Package');
  $description = $package['description'] ?? ("Payment for {$packageName} travel package");
  $reference = $package['reference'] ?? ('PKG-'.strtoupper(bin2hex(random_bytes(4))));
  $baseUrl = $package['baseUrl'] ?? appBaseUrl();

  $departure = null;
  if (!empty($package['departure_date'])) {
    try {
      $departure = new DateTimeImmutable($package['departure_date']);
    } catch (Exception $e) {
      $result['error'] = 'Invalid departure date provided.';
      return $result;
    }
  }
  $billExpiryDays = 0;
  if ($departure) {
    $today = new DateTimeImmutable('today');
    $diffDays = (int)$today->diff($departure)->format('%r%a');
    if ($diffDays < 0) {
      $result['error'] = 'Departure date already passed.';
      return $result;
    }
    $billExpiryDays = $diffDays;
  }

  $payload = [
    'userSecretKey'           => $config['userSecretKey'],
    'categoryCode'            => $config['categoryCode'],
    'billName'                => mb_substr($packageName, 0, 100),
    'billDescription'         => mb_substr($description, 0, 200),
    'billPriceSetting'        => 1, // fixed price
    'billPayorInfo'           => 1, // require customer details
    'billAmount'              => (int)round($amount * 100), // amount in cents
    'billReturnUrl'           => $config['returnUrl'] ?? ($baseUrl ? $baseUrl.'/toyyibpay-return.php' : ''),
    'billCallbackUrl'         => $config['callbackUrl'] ?? ($baseUrl ? $baseUrl.'/toyyibpay-callback.php' : ''),
    'billExternalReferenceNo' => $reference,
    'billTo'                  => $config['defaultBillTo'] ?? null,
    'billEmail'               => $config['defaultBillEmail'] ?? null,
    'billPhone'               => $config['defaultBillPhone'] ?? null,
    'billContentEmail'        => "Payment link for {$packageName}",
    'billChargeToCustomer'    => 0,
    'billExpiryDays'          => $billExpiryDays,
    'billPaymentChannel'      => 2, // FPX + Credit Card
  ];

  // Remove null/empty optional values
  $payload = array_filter($payload, static fn($v) => $v !== null && $v !== '');

  $ch = curl_init($endpoint);
  curl_setopt_array($ch, [
    CURLOPT_POST           => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 30,
    CURLOPT_POSTFIELDS     => http_build_query($payload),
  ]);

  $response = curl_exec($ch);
  if ($response === false) {
    $result['error'] = curl_error($ch) ?: 'Toyyibpay request failed.';
    curl_close($ch);
    return $result;
  }

  $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
  curl_close($ch);

  if ($httpCode < 200 || $httpCode >= 300) {
    $result['error'] = "Toyyibpay responded with HTTP {$httpCode}.";
    $result['raw'] = $response;
    return $result;
  }

  $decoded = json_decode($response, true);
  if (!is_array($decoded)) {
    $result['error'] = 'Toyyibpay returned an unreadable response.';
    $result['raw'] = $response;
    return $result;
  }

  $result['raw'] = $decoded;

  // Handle associative responses like {"status":"error","msg":"..."}
  if (isset($decoded['status']) || isset($decoded['msg']) || isset($decoded['message'])) {
    $status  = $decoded['status'] ?? null;
    $message = $decoded['msg'] ?? ($decoded['message'] ?? json_encode($decoded));
    if ($status && strcasecmp($status, 'success') === 0) {
      $billCode = $decoded['BillCode'] ?? ($decoded['billCode'] ?? null);
      $billUrl  = $decoded['BillUrl'] ?? ($decoded['billUrl'] ?? null);
    } else {
      $result['error'] = 'Toyyibpay error: '.$message;
      return $result;
    }
  } else {
    $first = $decoded[0] ?? null;
    if (!is_array($first)) {
      $result['error'] = 'Toyyibpay response did not contain a bill. Raw: '.json_encode($decoded);
      return $result;
    }

    if (!empty($first['code']) && strcasecmp($first['code'], '00') !== 0) {
      $result['error'] = $first['msg'] ?? ($first['message'] ?? 'Toyyibpay reported an error.');
      return $result;
    }

    $billCode = $first['BillCode'] ?? ($first['billCode'] ?? null);
    $billUrl  = $first['BillUrl'] ?? ($first['billUrl'] ?? null);
  }

  if (!$billUrl && $billCode) {
    $billUrl = 'https://toyyibpay.com/'.$billCode;
  }

  if (!$billCode && !$billUrl) {
    $result['error'] = 'Toyyibpay response did not include a bill code. Raw: '.json_encode($decoded);
    return $result;
  }

  $result['ok'] = true;
  $result['billCode'] = $billCode;
  $result['billUrl']  = $billUrl;
  return $result;
}

function validateToyyibUrl(string $url): bool {
  if (!filter_var($url, FILTER_VALIDATE_URL)) return false;
  return (bool)preg_match('#^https?://(www\.)?toyyibpay\.com/[A-Za-z0-9]+$#', $url);
}

$errors = [];
$flash  = '';

// handle create / update / delete
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if (!ensureCsrf()) {
    $errors[] = 'Invalid form token, please try again.';
  } else {
    $action = $_POST['action'] ?? '';
    // common fields
    $title       = trim($_POST['title'] ?? '');
    $description = trim($_POST['description'] ?? '');
    $price       = $_POST['price'] ?? '';
    $duration    = $_POST['duration'] ?? '';
    $departure   = $_POST['departure_date'] ?? '';
    $cities      = trim($_POST['cities'] ?? '');
    $billUrl     = trim($_POST['bill_url'] ?? '');
    $now         = (new DateTimeImmutable())->format('Y-m-d H:i:s');
    $imageFile   = $_FILES['image'] ?? null;
    $imagePath   = null;
    $newImagePath = null;
    $existingImagePath = null;

    if ($action === 'create' || $action === 'update') {
      if ($title === '') $errors[] = 'Package title is required.';
      if ($price === '' || !is_numeric($price) || $price < 0) $errors[] = 'Price must be zero or positive.';
      if ($duration !== '' && (!ctype_digit((string)$duration) || (int)$duration < 0)) {
        $errors[] = 'Duration must be a positive number of days.';
      }
      if ($departure !== '' && !DateTimeImmutable::createFromFormat('Y-m-d\TH:i', $departure)) {
        $errors[] = 'Departure must be a valid date/time.';
      }
      if ($billUrl !== '' && !validateToyyibUrl($billUrl)) {
        $errors[] = 'Toyyibpay bill URL must be a valid toyyibpay.com link.';
      }
    }

    if (!$errors) {
      if ($action === 'create') {
        $uploadResult = storePackageImage($imageFile, null);
        if (!$uploadResult['ok']) {
          $errors[] = $uploadResult['error'];
        } else {
          $imagePath = $uploadResult['path'];
          if (!empty($uploadResult['uploadedNew'])) {
            $newImagePath = $uploadResult['path'];
          }
        }

        if ($billUrl === '' && !$errors) {
          $billResult = createToyyibBill($toyyibpayConfig, [
            'name'        => $title,
            'description' => $description,
            'price'       => (float)$price,
            'reference'   => 'PKG-'.strtoupper(bin2hex(random_bytes(3))),
            'baseUrl'     => appBaseUrl(),
            'departure_date' => $departure,
          ]);
          if ($billResult['ok']) {
            $billUrl = $billResult['billUrl'];
          } else {
            $errors[] = 'Toyyibpay bill not created: '.$billResult['error'];
          }
        }
        if (!$errors) {
          $stmt = $pdo->prepare('
            INSERT INTO packages
              (title, description, price, duration_days, cities, images_json, bill_url, created_at)
            VALUES
              (?, ?, ?, ?, ?, ?, ?, ?)
          ');
          $stmt->execute([
            $title,
            $description !== '' ? $description : null,
            (float)$price,
            $duration === '' ? null : (int)$duration,
            $cities !== '' ? $cities : null,
            imageJson($imagePath),
            $billUrl,
            $now,
          ]);
          $_SESSION['flash_ok'] = 'Package created.';
          header('Location: admin_package.php');
          exit;
        }
        if ($errors && $newImagePath) {
          $absoluteCleanup = __DIR__.DIRECTORY_SEPARATOR.str_replace(['/', '\\'], DIRECTORY_SEPARATOR, ltrim($newImagePath, '/\\'));
          if (is_file($absoluteCleanup)) {
            @unlink($absoluteCleanup);
          }
        }
      }

      if ($action === 'update' && !$errors) {
        $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
        if ($id <= 0) {
          $errors[] = 'Invalid package id.';
        } else {
          $stmt = $pdo->prepare('SELECT images_json FROM packages WHERE id = ?');
          $stmt->execute([$id]);
          $row = $stmt->fetch();
          if (!$row) {
            $errors[] = 'Package not found.';
          } else {
            $existingImagePath = firstImage($row['images_json']);
            $uploadResult = storePackageImage($imageFile, $existingImagePath);
            if (!$uploadResult['ok']) {
              $errors[] = $uploadResult['error'];
            } else {
              $imagePath = $uploadResult['path'];
              if (!empty($uploadResult['uploadedNew'])) {
                $newImagePath = $uploadResult['path'];
              }
            }
          }
        }

        if (!$errors && $billUrl === '') {
          $billResult = createToyyibBill($toyyibpayConfig, [
            'name'           => $title,
            'description'    => $description,
            'price'          => (float)$price,
            'reference'      => 'PKG-'.strtoupper(bin2hex(random_bytes(3))),
            'baseUrl'        => appBaseUrl(),
            'departure_date' => $departure,
          ]);
          if ($billResult['ok']) {
            $billUrl = $billResult['billUrl'];
          } else {
            $errors[] = 'Toyyibpay bill not created: '.$billResult['error'];
          }
        }
        if (!$errors) {
          $stmt = $pdo->prepare('
            UPDATE packages
               SET title = ?, description = ?, price = ?, duration_days = ?, cities = ?, images_json = ?, bill_url = ?
             WHERE id = ?
          ');
          $stmt->execute([
            $title,
            $description !== '' ? $description : null,
            (float)$price,
            $duration === '' ? null : (int)$duration,
            $cities !== '' ? $cities : null,
            imageJson($imagePath),
            $billUrl,
            $id,
          ]);
          if ($newImagePath && $existingImagePath && $newImagePath !== $existingImagePath) {
            $oldAbsolute = __DIR__.DIRECTORY_SEPARATOR.str_replace(['/', '\\'], DIRECTORY_SEPARATOR, ltrim($existingImagePath, '/\\'));
            if (is_file($oldAbsolute)) {
              @unlink($oldAbsolute);
            }
          }
          $_SESSION['flash_ok'] = 'Package updated.';
          header('Location: admin_package.php');
          exit;
        } elseif ($errors && $newImagePath) {
          $absoluteCleanup = __DIR__.DIRECTORY_SEPARATOR.str_replace(['/', '\\'], DIRECTORY_SEPARATOR, ltrim($newImagePath, '/\\'));
          if (is_file($absoluteCleanup)) {
            @unlink($absoluteCleanup);
          }
        }
      }

      if ($action === 'delete') {
        $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
        if ($id <= 0) {
          $errors[] = 'Invalid package id.';
        } else {
          $pdo->prepare('DELETE FROM packages WHERE id = ?')->execute([$id]);
          $_SESSION['flash_ok'] = 'Package removed.';
          header('Location: admin_package.php');
          exit;
        }
      }
    }
  }
}

if (isset($_SESSION['flash_ok'])) {
  $flash = $_SESSION['flash_ok'];
  unset($_SESSION['flash_ok']);
}

$createDefaults = [
  'title'       => '',
  'price'       => '',
  'duration'    => '',
  'cities'      => '',
  'bill_url'    => '',
  'description' => '',
  'departure'   => '',
];

if (($action ?? '') === 'create' && $errors) {
  $createDefaults = [
    'title'       => $_POST['title'] ?? '',
    'price'       => $_POST['price'] ?? '',
    'duration'    => $_POST['duration'] ?? '',
    'cities'      => $_POST['cities'] ?? '',
    'bill_url'    => $_POST['bill_url'] ?? '',
    'description' => $_POST['description'] ?? '',
    'departure'   => $_POST['departure_date'] ?? '',
  ];
}

$packages = $pdo->query('
  SELECT id, title, price, duration_days, cities, images_json, bill_url, created_at
  FROM packages
  ORDER BY created_at DESC, id DESC
')->fetchAll();

$editId = isset($_GET['edit']) ? (int)$_GET['edit'] : 0;
$editRow = null;
$editImageValue = null;
if ($editId > 0) {
  $stmt = $pdo->prepare('SELECT * FROM packages WHERE id = ?');
  $stmt->execute([$editId]);
  $editRow = $stmt->fetch();
  if (!$editRow) {
    $errors[] = 'Package not found for editing.';
  } else {
    $editImageValue = firstImage($editRow['images_json']);
    if (!empty($editRow['departure_date'])) {
      $dt = new DateTimeImmutable($editRow['departure_date']);
      $editRow['departureDate'] = $dt->format('Y-m-d\TH:i');
    }
    if (($action ?? '') === 'update' && $errors) {
      $editRow['title']       = $_POST['title'] ?? $editRow['title'];
      $editRow['price']       = $_POST['price'] ?? $editRow['price'];
      $editRow['duration_days'] = $_POST['duration'] ?? $editRow['duration_days'];
      $editRow['cities']      = $_POST['cities'] ?? $editRow['cities'];
      $editRow['bill_url']    = $_POST['bill_url'] ?? $editRow['bill_url'];
      $editRow['description'] = $_POST['description'] ?? $editRow['description'];
      $editRow['departureDate'] = $_POST['departure_date'] ?? ($editRow['departureDate'] ?? '');
    }
  }
}

$isEditing = (bool)$editRow;
$showCreateForm = !$isEditing && (isset($_GET['create']) || (($action ?? '') === 'create' && $errors));

?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin Â· Packages</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
  <style>
    body { background:#f7f8fc; }
    .navbar{
      background:#e31f25;
      border-bottom:1px solid rgba(0,0,0,.08);
      box-shadow:0 6px 16px rgba(0,0,0,.14);
    }
    .navbar-brand img { height:36px; }
    .brand-text { font-weight:800; color:#fff; letter-spacing:.3px; }
    .navbar .container-fluid{display:flex;flex-direction:column;align-items:stretch;padding:0 1.5rem;}
    .header-top{display:flex;align-items:center;width:100%;margin-bottom:.15rem;}
    .role-badge { color:#fff; font-weight:800; margin-right:.75rem; }
    .notif-btn{position:relative;}
    .notif-badge{position:absolute;top:-6px;right:-6px;background:#000;color:#fff;border-radius:999px;font-size:.75rem;padding:2px 7px;line-height:1;border:2px solid #fff;}
    .notif-btn.notif-pulse{animation:notifPulse .8s ease-in-out 3;}
    @keyframes notifPulse{
      0%,100%{transform:scale(1);}
      50%{transform:scale(1.08);}
    }
    .profile-btn{width:40px;height:40px;border:0;padding:0;background:#fff;color:#e31f25;font-weight:700;display:flex;align-items:center;justify-content:center;}
    .profile-initial{font-size:1rem;}
    .nav-icon-btn{width:40px;height:40px;display:flex;align-items:center;justify-content:center;border:0;background:#fff;color:#e31f25;font-size:1.1rem;}
    .nav-icon-btn:hover{color:#e31f25;background:#fff;}
    .notif-dropdown{width:360px;max-width:85vw;border:1px solid #000;border-radius:.6rem;padding:.5rem .75rem;}
    .notif-dropdown h6{font-weight:800;text-decoration:underline;margin:.25rem 0 .5rem;}

    .quicklinks-bar{
      background:transparent;box-shadow:none;width:100%;
      max-height:0;overflow:hidden;opacity:0;transform:translateY(-8px);
      transition:max-height .28s ease, opacity .22s ease, transform .24s ease;
      pointer-events:none;margin-top:.05rem;
    }
    .navbar:hover .quicklinks-bar,
    .navbar:focus-within .quicklinks-bar{
      max-height:220px;opacity:1;transform:translateY(0);pointer-events:auto;
    }
    .quicklinks-bar .inner{
      display:flex;align-items:center;gap:1rem;flex-wrap:wrap;
      padding:.35rem 0 .4rem;border-top:1px solid rgba(255,255,255,.25);
    }
    .quicklinks-bar .menu-title{
      font-weight:700;letter-spacing:.16em;text-transform:uppercase;
      font-size:.8rem;color:#ffeaea;opacity:.9;
    }
    .quicklinks-bar .menu-links{display:flex;align-items:center;gap:.45rem;margin:0;padding:0;list-style:none;flex-wrap:wrap;}
    .quicklinks-bar .menu-links a{
      display:flex;align-items:center;padding:.45rem 1.1rem;border-radius:999px;
      text-decoration:none;font-weight:600;font-size:.9rem;
      background:rgba(255,255,255,.08);color:#fff;transition:.18s ease;
    }
    .quicklinks-bar .menu-links a .bi{font-size:1rem;margin-right:.2rem;}
    .quicklinks-bar .menu-links a:hover,
    .quicklinks-bar .menu-links a:focus-visible{
      background:#fff;color:#e31f25;box-shadow:0 6px 16px rgba(0,0,0,.18);transform:translateY(-1px);
    }
    .quicklinks-bar .menu-links .active{
      background:#fff;color:#e31f25;box-shadow:0 6px 16px rgba(0,0,0,.18);
    }

    .wrap { padding:1.75rem 1.25rem; }
    .page-title { font-weight:800; font-size:2.2rem; margin-bottom:1.5rem; }
    .table-frame { border:3px solid #000; border-radius:6px; background:#fff; }
    .table-frame thead th { text-align:center; vertical-align:middle; border-bottom:2px solid #000 !important; font-weight:700; }
    .table-frame td { vertical-align:middle; }
    .btn-add, .btn-cancel { border-radius:999px; font-weight:800; }
    .btn-add { background:#6bd12f; border:0; padding:.8rem 1.6rem; }
    .btn-cancel { background:#1da1ff; border:0; padding:.75rem 1.6rem; }
    .btn-back { display:inline-block; background:#1da1ff; color:#fff; border:0; font-weight:800; border-radius:999px; padding:.9rem 2.2rem; }
    .btn-edit { background:#6bd12f; border:0; font-weight:700; border-radius:12px; padding:.45rem 1rem; }
    .btn-del { background:#ff5252; border:0; font-weight:700; border-radius:12px; padding:.45rem 1rem; color:#fff; }
    .form-card { max-width:720px; margin:0 auto; background:#fff; border:2px solid #000; border-radius:22px; padding:2rem; box-shadow:0 8px 24px rgba(0,0,0,.06); }
    .form-label { font-weight:700; }
    .pill.form-control { border-radius:999px; padding:.75rem 1rem; }
    .btn-fab { position:fixed; right:1.75rem; bottom:1.75rem; background:#1da1ff; color:#fff; font-weight:800; padding:1rem 2.2rem; border-radius:999px; box-shadow:0 14px 28px rgba(29,161,255,.25); border:0; text-decoration:none; }
    .btn-fab:hover { color:#fff; background:#0f7acc; }
    .package-thumb { max-width:180px; border:2px solid #000; border-radius:16px; box-shadow:0 6px 16px rgba(0,0,0,.12); }

    @media (max-width:576px){
      .quicklinks-bar{max-height:none;opacity:1;transform:none;pointer-events:auto;}
      .quicklinks-bar .inner{flex-direction:column;align-items:flex-start;}
      .header-top{flex-direction:column;align-items:flex-start;gap:.75rem;}
      .navbar .container-fluid{padding:0 1rem;}
    }
  </style>
</head>
<body>

<nav class="navbar navbar-expand-lg">
  <div class="container-fluid">

    <div class="header-top">
      <a class="navbar-brand d-flex align-items-center" href="admin.php">
        <img src="img/logo_white.png" class="me-2" alt="Logo">
        <span class="brand-text">ROTANA TRAVEL &amp; TOURS</span>
      </a>

      <div class="ms-auto d-flex align-items-center gap-3">
        <span class="role-badge">ADMIN</span>
        <a class="btn btn-light rounded-circle nav-icon-btn" href="admin.php" aria-label="Back to dashboard">
          <i class="bi bi-arrow-left-circle"></i>
        </a>

        <!-- Notifications -->
        <div class="dropdown">
          <button class="btn btn-light rounded-circle notif-btn" type="button" data-bs-toggle="dropdown" data-notifications="true" data-initial-count="<?= $pendingCount ?>" aria-expanded="false" aria-label="Notifications">
            <i class="bi bi-bell"></i>
            <span class="notif-badge <?= $pendingCount>0 ? '' : 'd-none' ?>" id="notificationBadge"><?= $pendingCount ?></span>
          </button>
          <div class="dropdown-menu dropdown-menu-end shadow-sm p-3 small notif-dropdown" id="notificationDropdown">
            <h6>NOTIFICATIONS</h6>
            <div id="notificationContent">
              <?php if ($pendingCount===0): ?>
                <div class="text-muted small px-1 py-1">No new notifications.</div>
              <?php else: ?>
                <ol class="mb-0 ps-3">
                  <?php foreach ($pending as $row):
                    $customer = trim($row['customer_name'] ?? '');
                    $package  = trim($row['package_name'] ?? '');
                    $messageParts = [];
                    if ($customer !== '') { $messageParts[] = $customer; }
                    if ($package !== '') { $messageParts[] = $package; }
                    $message = $messageParts ? implode(' — ', $messageParts) : 'Incoming Customer Booking (Pending)';
                  ?>
                    <li><?= htmlspecialchars($message) ?></li>
                  <?php endforeach; ?>
                </ol>
              <?php endif; ?>
            </div>
          </div>
        </div>

        <!-- Profile -->
        <div class="dropdown">
          <button class="btn btn-light rounded-circle profile-btn" type="button" data-bs-toggle="dropdown" aria-expanded="false" aria-label="Profile menu">
            <span class="profile-initial"><?= htmlspecialchars(strtoupper(substr($_SESSION['username'] ?? 'Admin', 0, 1))) ?></span>
          </button>
          <ul class="dropdown-menu dropdown-menu-end shadow-sm">
            <li class="dropdown-item-text small text-muted">
              Signed in as<br>
              <strong><?= htmlspecialchars($_SESSION['username'] ?? 'Admin') ?></strong>
            </li>
            <li><hr class="dropdown-divider"></li>
            <li><a class="dropdown-item" href="logout.php">Log Out</a></li>
          </ul>
        </div>
      </div>
    </div>

    <div class="quicklinks-bar">
      <div class="inner">
        <span class="menu-title">Quick Links</span>
        <ul class="menu-links">
          <li><a href="admin.php"><i class="bi bi-speedometer2"></i>Dashboard</a></li>
          <li><a href="admin_booking.php"><i class="bi bi-calendar-check"></i>Bookings</a></li>
          <li><a class="active" href="admin_package.php"><i class="bi bi-boxes"></i>Packages</a></li>
          <li><a href="admin_records.php"><i class="bi bi-archive"></i>Records</a></li>
          <li><a href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="wrap container-fluid">
  <h1 class="page-title"><?= $editRow ? 'Edit Package' : 'Packages' ?></h1>

  <?php if ($flash): ?>
    <div class="alert alert-success"><?= htmlspecialchars($flash) ?></div>
  <?php endif; ?>

  <?php if ($errors): ?>
    <div class="alert alert-danger">
      <ul class="mb-0">
        <?php foreach ($errors as $err): ?>
          <li><?= htmlspecialchars($err) ?></li>
        <?php endforeach; ?>
      </ul>
    </div>
  <?php endif; ?>

  <?php if (!$isEditing): ?>
    <section class="table-frame mb-4">
      <div class="table-responsive">
        <table class="table align-middle text-center mb-0">
          <thead>
            <tr>
              <th style="width:120px;">Image</th>
              <th>Package</th>
              <th style="width:140px;">Price</th>
              <th style="width:140px;">Duration</th>
              <th>Cities</th>
              <th style="width:220px;">ToyyibPay URL</th>
              <th style="width:180px;">Created</th>
              <th style="width:200px;">Action</th>
            </tr>
          </thead>
          <tbody>
            <?php if (!$packages): ?>
              <tr><td colspan="8" class="text-muted py-4">No packages found.</td></tr>
            <?php else: ?>
              <?php foreach ($packages as $pkg): ?>
                <?php
                  $imagePath = firstImage($pkg['images_json']);
                  $priceFmt  = 'RM '.number_format((float)$pkg['price'], 2, '.', ',');
                  $duration  = is_null($pkg['duration_days']) ? 'â€”' : $pkg['duration_days'].' days';
                  $cities    = $pkg['cities'] ?: 'â€”';
                  $created   = substr($pkg['created_at'], 0, 10);
                ?>
                <tr>
                  <td>
                    <?php if ($imagePath): ?>
                      <img src="<?= htmlspecialchars($imagePath) ?>" alt="Package image" style="max-width:100px;max-height:80px;border:1px solid #ddd;border-radius:10px;">
                    <?php else: ?>
                      <span class="text-muted">No image</span>
                    <?php endif; ?>
                  </td>
                  <td class="text-start">
                    <strong><?= htmlspecialchars($pkg['title']) ?></strong>
                    <?php if (!empty($pkg['description'])): ?>
                      <div class="text-muted small"><?= htmlspecialchars(mb_strimwidth($pkg['description'], 0, 80, 'â€¦')) ?></div>
                    <?php endif; ?>
                  </td>
                  <td><?= $priceFmt ?></td>
                  <td><?= htmlspecialchars($duration) ?></td>
                  <td><?= htmlspecialchars($cities) ?></td>
                  <td class="text-break" style="max-width:220px;">
                    <?php if (!empty($pkg['bill_url'])): ?>
                      <a href="<?= htmlspecialchars($pkg['bill_url']) ?>" target="_blank" rel="noopener"><?= htmlspecialchars($pkg['bill_url']) ?></a>
                    <?php else: ?>
                      <span class="text-muted">-</span>
                    <?php endif; ?>
                  </td>
                  <td><?= htmlspecialchars($created) ?></td>
                  <td>
                    <a class="btn btn-edit me-1" href="admin_package.php?edit=<?= (int)$pkg['id'] ?>">EDIT</a>
                    <form class="d-inline" method="post" onsubmit="return confirm('Delete this package?');">
                      <input type="hidden" name="csrf" value="<?= $csrf ?>">
                      <input type="hidden" name="action" value="delete">
                      <input type="hidden" name="id" value="<?= (int)$pkg['id'] ?>">
                      <button class="btn btn-del">DELETE</button>
                    </form>
                  </td>
                </tr>
              <?php endforeach; ?>
            <?php endif; ?>
          </tbody>
        </table>
      </div>
    </section>

    <?php if ($showCreateForm): ?>
    <section class="form-card">
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="csrf" value="<?= $csrf ?>">
        <input type="hidden" name="action" value="create">
        <div class="mb-3">
          <label class="form-label">Package Title</label>
          <input type="text" name="title" class="form-control pill" required value="<?= htmlspecialchars($createDefaults['title']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Price (RM)</label>
          <input type="number" step="0.01" min="0" name="price" class="form-control pill" required value="<?= htmlspecialchars($createDefaults['price']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Duration (days)</label>
          <input type="number" min="0" name="duration" class="form-control pill" placeholder="e.g. 7" value="<?= htmlspecialchars($createDefaults['duration']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Cities</label>
          <input type="text" name="cities" class="form-control pill" placeholder="Kuala Lumpur, Mecca, Madinah" value="<?= htmlspecialchars($createDefaults['cities']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Hero Image</label>
          <input type="file" name="image" class="form-control" accept=".jpg,.jpeg,.png,.gif,.webp">
          <div class="form-text">Upload a JPG, PNG, GIF, or WEBP file. Leave empty to skip for now.</div>
        </div>
        <div class="mb-3">
          <label class="form-label">ToyyibPay Bill URL</label>
          <input type="text" name="bill_url" class="form-control pill" placeholder="Leave blank to auto generate" value="<?= htmlspecialchars($createDefaults['bill_url']) ?>">
          <div class="form-text">Leave empty to automatically create a Toyyibpay bill.</div>
        </div>
        <div class="mb-3">
          <label class="form-label">Departure Date & Time</label>
          <input type="datetime-local" name="departure_date" class="form-control pill" value="<?= htmlspecialchars($createDefaults['departure']) ?>">
          <div class="form-text">Used to set the Toyyibpay bill expiry.</div>
        </div>
        <div class="mb-3">
          <label class="form-label">Description</label>
          <textarea name="description" class="form-control" rows="4" placeholder="Describe the package..."><?= htmlspecialchars($createDefaults['description']) ?></textarea>
        </div>
        <div class="text-center d-flex justify-content-center gap-2">
          <button class="btn btn-add" type="submit">Create Package</button>
          <a class="btn btn-cancel" href="admin_package.php">Cancel</a>
        </div>
      </form>
    </section>
    <?php endif; ?>

  <?php else: ?>

    <section class="form-card">
      <form method="post" enctype="multipart/form-data">
        <input type="hidden" name="csrf" value="<?= $csrf ?>">
        <input type="hidden" name="action" value="update">
        <input type="hidden" name="id" value="<?= (int)$editRow['id'] ?>">
        <div class="mb-3">
          <label class="form-label">Package Title</label>
          <input type="text" name="title" class="form-control pill" required value="<?= htmlspecialchars($editRow['title']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Price (RM)</label>
          <input type="number" step="0.01" min="0" name="price" class="form-control pill" required value="<?= htmlspecialchars($editRow['price']) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Duration (days)</label>
          <input type="number" min="0" name="duration" class="form-control pill" value="<?= htmlspecialchars($editRow['duration_days'] ?? '') ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Cities</label>
          <input type="text" name="cities" class="form-control pill" value="<?= htmlspecialchars($editRow['cities'] ?? '') ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Hero Image</label>
          <?php if ($editImageValue): ?>
            <div class="mb-2">
              <img src="<?= htmlspecialchars($editImageValue) ?>" alt="Current package image" class="package-thumb">
            </div>
          <?php else: ?>
            <div class="mb-2 text-muted">No image currently uploaded.</div>
          <?php endif; ?>
          <input type="file" name="image" class="form-control" accept=".jpg,.jpeg,.png,.gif,.webp">
          <div class="form-text">Upload a new image to replace the current one.</div>
        </div>
        <div class="mb-3">
          <label class="form-label">ToyyibPay Bill URL</label>
          <input type="text" name="bill_url" class="form-control pill" value="<?= htmlspecialchars($editRow['bill_url'] ?? '') ?>" placeholder="Leave blank to auto generate">
        </div>
        <div class="mb-3">
          <label class="form-label">Departure Date & Time</label>
          <input type="datetime-local" name="departure_date" class="form-control pill" value="<?= htmlspecialchars($editRow['departureDate'] ?? ($editRow['departure_date'] ?? '')) ?>">
        </div>
        <div class="mb-3">
          <label class="form-label">Description</label>
          <textarea name="description" class="form-control" rows="4"><?= htmlspecialchars($editRow['description'] ?? '') ?></textarea>
        </div>
        <div class="text-center d-flex justify-content-center gap-2">
          <button class="btn btn-add" type="submit">Save Changes</button>
          <a class="btn btn-cancel" href="admin_package.php">Cancel</a>
        </div>
      </form>
    </section>

  <?php endif; ?>

  <?php if (!$isEditing && !$showCreateForm): ?>
    <a class="btn-fab" href="admin_package.php?create=1">NEW PLAN</a>
  <?php endif; ?>

  <div class="text-center my-5">
    <a class="btn-back" href="admin.php">Back</a>
  </div>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
</body>
</html>
