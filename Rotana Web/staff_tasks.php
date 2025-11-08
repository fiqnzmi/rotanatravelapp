<?php
// staff_tasks.php — manage pending booking requests before confirming them
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'staff')) {
  header('Location: index.php'); exit;
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

/* -------------------- navbar notifications (Pending booking requests) -------------------- */
$pending = $pdo->query("
  SELECT
    r.id,
    r.created_at,
    u.name  AS customer_name,
    p.title AS package_name
  FROM booking_requests r
  LEFT JOIN users u    ON u.id = r.user_id
  LEFT JOIN packages p ON p.id = r.package_id
  WHERE r.status IN ('NOT_CONFIRMED','AWAITING_REQUIREMENTS','READY_FOR_REVIEW')
  ORDER BY r.created_at DESC
  LIMIT 10
")->fetchAll();
$pendingCount = count($pending);

/* -------------------- simple CSRF token -------------------- */
if (empty($_SESSION['csrf'])) {
  $_SESSION['csrf'] = bin2hex(random_bytes(16));
}
$csrf = $_SESSION['csrf'];

$flashSuccess = $_SESSION['flash_success'] ?? '';
$flashError   = $_SESSION['flash_error'] ?? '';
unset($_SESSION['flash_success'], $_SESSION['flash_error']);

/* -------------------- handle POST: process pending booking -------------------- */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $postedCsrf = $_POST['csrf'] ?? '';
  if (!hash_equals($csrf, $postedCsrf)) {
    $_SESSION['flash_error'] = 'Security token mismatch. Please try again.';
    header('Location: staff_tasks.php');
    exit;
  }

  $requestId = isset($_POST['booking_id']) ? (int)$_POST['booking_id'] : 0;
  $action    = $_POST['action'] ?? '';
  $notes     = trim($_POST['notes'] ?? '');

  if ($requestId <= 0 || !in_array($action, ['confirm', 'cancel'], true)) {
    $_SESSION['flash_error'] = 'Invalid request.';
    header('Location: staff_tasks.php');
    exit;
  }

  try {
    $pdo->beginTransaction();
    $stmt = $pdo->prepare("SELECT * FROM booking_requests WHERE id=? FOR UPDATE");
    $stmt->execute([$requestId]);
    $request = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$request) {
      $pdo->rollBack();
      $_SESSION['flash_error'] = 'This request no longer exists.';
      header('Location: staff_tasks.php');
      exit;
    }

    if (in_array($request['status'], ['APPROVED', 'REJECTED'], true)) {
      $pdo->rollBack();
      $_SESSION['flash_error'] = 'This request was already processed.';
      header('Location: staff_tasks.php');
      exit;
    }

    if ($action === 'confirm') {
      if ((int)$request['documents_ready'] === 0 || (int)$request['payment_ready'] === 0) {
        $pdo->rollBack();
        $_SESSION['flash_error'] = 'Documents and payment must be complete before approval.';
        header('Location: staff_tasks.php');
        exit;
      }

      $insert = $pdo->prepare("
        INSERT INTO bookings (
          user_id, package_id, adults, children, rooms, status, created_at, departure_date, room_tier, deposit_paid, briefing_done, final_paid, total_amount
        ) VALUES (?, ?, ?, ?, ?, 'CONFIRMED', NOW(), ?, NULL, 0, 0, 0, ?)
      ");
      $insert->execute([
        $request['user_id'],
        $request['package_id'],
        $request['adults'],
        $request['children'],
        $request['rooms'] ?? 1,
        $request['departure_date'],
        $request['total_amount'],
      ]);
      $newBookingId = (int)$pdo->lastInsertId();

      $travRows = $pdo->prepare("SELECT full_name, passport_no, dob, gender, passport_issue_date, passport_expiry_date FROM booking_request_travellers WHERE booking_request_id=?");
      $travRows->execute([$requestId]);
      $travInsert = $pdo->prepare("INSERT INTO booking_travellers (booking_id, full_name, passport_no, dob, gender, passport_issue_date, passport_expiry_date) VALUES (?, ?, ?, ?, ?, ?, ?)");
      while ($trav = $travRows->fetch(PDO::FETCH_ASSOC)) {
        $travInsert->execute([
          $newBookingId,
          $trav['full_name'],
          $trav['passport_no'],
          $trav['dob'],
          $trav['gender'],
          $trav['passport_issue_date'],
          $trav['passport_expiry_date'],
        ]);
      }

      $pdo->prepare("UPDATE documents SET booking_id = ?, booking_request_id = NULL WHERE booking_request_id = ?")
          ->execute([$newBookingId, $requestId]);
      $pdo->prepare("UPDATE payments SET booking_id = ?, booking_request_id = NULL WHERE booking_request_id = ?")
          ->execute([$newBookingId, $requestId]);

      $update = $pdo->prepare("UPDATE booking_requests SET status='APPROVED', approved_booking_id=?, approved_at=NOW(), approved_by=?, notes = NULLIF(?, '') WHERE id=?");
      $update->execute([$newBookingId, $_SESSION['user_id'], $notes, $requestId]);

      $pdo->commit();
      $_SESSION['flash_success'] = 'Request approved and moved into active bookings (ID #'.$newBookingId.').';
    } else {
      $update = $pdo->prepare("UPDATE booking_requests SET status='REJECTED', notes = NULLIF(?, ''), approved_by=?, approved_at=NOW() WHERE id=?");
      $update->execute([$notes, $_SESSION['user_id'], $requestId]);
      $pdo->commit();
      $_SESSION['flash_success'] = 'Request marked as rejected.';
    }
  } catch (Throwable $e) {
    if ($pdo->inTransaction()) {
      $pdo->rollBack();
    }
    $_SESSION['flash_error'] = 'Failed to process request: '.$e->getMessage();
  }

  header('Location: staff_tasks.php');
  exit;
}

/* -------------------- fetch pending booking requests -------------------- */
$tasksStmt = $pdo->query("
  SELECT
    r.id,
    r.created_at,
    r.adults,
    r.children,
    r.rooms,
    r.total_amount,
    r.departure_date,
    r.status,
    r.documents_ready,
    r.payment_ready,
    u.name AS customer_name,
    u.email AS customer_email,
    NULLIF(u.phone, '') AS customer_phone,
    p.title AS package_name
  FROM booking_requests r
  JOIN users u    ON u.id = r.user_id
  JOIN packages p ON p.id = r.package_id
  WHERE r.status IN ('NOT_CONFIRMED','AWAITING_REQUIREMENTS','READY_FOR_REVIEW')
  ORDER BY r.created_at ASC
");
$tasks = $tasksStmt->fetchAll();

$travellersByRequest = [];
$documentsByRequest = [];
$paymentsSummaryByRequest = [];
$paymentsDetailByRequest = [];
if ($tasks) {
  $requestIds = array_column($tasks, 'id');
  $placeholders = implode(',', array_fill(0, count($requestIds), '?'));
  $travStmt = $pdo->prepare("
    SELECT booking_request_id, full_name, gender, dob, passport_no
    FROM booking_request_travellers
    WHERE booking_request_id IN ($placeholders)
    ORDER BY id
  ");
  $travStmt->execute($requestIds);
  while ($row = $travStmt->fetch()) {
    $rid = (int)$row['booking_request_id'];
    if (!isset($travellersByRequest[$rid])) {
      $travellersByRequest[$rid] = [];
    }
    $travellersByRequest[$rid][] = $row;
  }

  $docStmt = $pdo->prepare("
    SELECT booking_request_id, doc_type, label, status, file_name, file_path, uploaded_at, mime_type
    FROM documents
    WHERE booking_request_id IN ($placeholders)
    ORDER BY FIELD(doc_type,'PASSPORT','INSURANCE','VISA','PAYMENT_PROOF'), id
  ");
  $docStmt->execute($requestIds);
  while ($row = $docStmt->fetch(PDO::FETCH_ASSOC)) {
    $rid = (int)$row['booking_request_id'];
    if (!isset($documentsByRequest[$rid])) {
      $documentsByRequest[$rid] = [];
    }
    $row['file_url'] = buildDocumentUrl($row['file_path'] ?? null);
    $documentsByRequest[$rid][] = $row;
  }

  $payStmt = $pdo->prepare("
    SELECT booking_request_id, id, amount, currency, method, status, transaction_ref, created_at, paid_at
    FROM payments
    WHERE booking_request_id IN ($placeholders)
    ORDER BY created_at DESC
  ");
  $payStmt->execute($requestIds);
  while ($row = $payStmt->fetch(PDO::FETCH_ASSOC)) {
    $rid = (int)$row['booking_request_id'];
    if (!isset($paymentsDetailByRequest[$rid])) {
      $paymentsDetailByRequest[$rid] = [];
      $paymentsSummaryByRequest[$rid] = ['paid' => 0.0, 'total' => 0.0];
    }
    $amount = isset($row['amount']) ? (float)$row['amount'] : 0.0;
    $paymentsDetailByRequest[$rid][] = $row;
    $paymentsSummaryByRequest[$rid]['total'] += $amount;
    if (($row['status'] ?? '') === 'PAID') {
      $paymentsSummaryByRequest[$rid]['paid'] += $amount;
    }
  }

}

function buildDocumentUrl(?string $path): ?string {
  if (!$path) {
    return null;
  }
  $normalized = ltrim($path, '/');
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
  $host = $_SERVER['HTTP_HOST'] ?? '';
  $basePath = rtrim(dirname($_SERVER['SCRIPT_NAME'] ?? ''), '/'); // e.g. /rotanatravel
  return sprintf('%s://%s%s/rotanatravelapi/uploads/%s', $scheme, $host, $basePath, $normalized);
}

function formatTaskDate(?string $value): string {
  if (!$value) {
    return '-';
  }
  try {
    return (new DateTimeImmutable($value))->format('d M Y, h:i A');
  } catch (Throwable $e) {
    return $value;
  }
}

function formatDisplayDate(?string $value): ?string {
  if (!$value) {
    return null;
  }
  try {
    return (new DateTimeImmutable($value))->format('d M Y');
  } catch (Throwable $e) {
    return $value;
  }
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Tasks - Pending Booking Requests</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
  <style>
    body{background:#f7f8fc;}
    /* NAVBAR */
    .navbar{
      background:#3ea8ff;
      border-bottom:1px solid rgba(0,0,0,.08);
      box-shadow:0 6px 16px rgba(0,0,0,.1);
    }
    .navbar-brand img{height:36px}
    .brand-text{font-weight:800;color:#fff;letter-spacing:.3px}
    .navbar .container-fluid{display:flex;flex-direction:column;align-items:stretch;padding:0 1.5rem;}
    .header-top{display:flex;align-items:center;width:100%;margin-bottom:.15rem;}
    .role-badge{color:#fff;font-weight:800;margin-right:.75rem}
    .notif-btn{position:relative}
    .notif-badge{
      position:absolute;top:-6px;right:-6px;background:#072b4f;color:#fff;border-radius:999px;
      font-size:.75rem;padding:2px 7px;line-height:1;border:2px solid #fff;
    }
    .notif-btn.notif-pulse{animation:notifPulse .8s ease-in-out 3;}
    @keyframes notifPulse{
      0%,100%{transform:scale(1);}
      50%{transform:scale(1.08);}
    }
    .profile-btn{width:40px;height:40px;border:0;padding:0;background:#fff;color:#1381ca;font-weight:700;display:flex;align-items:center;justify-content:center;}
    .profile-initial{font-size:1rem;}
    .notif-dropdown{border:1px solid #072b4f;border-radius:.6rem;}

    /* QUICK LINKS BAR */
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
      padding:.35rem 0 .4rem;border-top:1px solid rgba(255,255,255,.3);
    }
    .quicklinks-bar .menu-title{
      font-weight:700;letter-spacing:.16em;text-transform:uppercase;
      font-size:.8rem;color:#e8f6ff;opacity:.9;
    }
    .quicklinks-bar .menu-links{display:flex;align-items:center;gap:.45rem;margin:0;padding:0;list-style:none;flex-wrap:wrap;}
    .quicklinks-bar .menu-links a{
      display:flex;align-items:center;padding:.45rem 1.1rem;border-radius:999px;
      text-decoration:none;font-weight:600;font-size:.9rem;
      background:rgba(255,255,255,.15);color:#fff;transition:.18s ease;
    }
    .quicklinks-bar .menu-links a .bi{font-size:1rem;margin-right:.2rem;}
    .quicklinks-bar .menu-links a:hover,
    .quicklinks-bar .menu-links a:focus-visible{
      background:#fff;color:#1f7fbb;box-shadow:0 6px 16px rgba(0,0,0,.18);transform:translateY(-1px);
    }
    .quicklinks-bar .menu-links .active{
      background:#fff;color:#1f7fbb;box-shadow:0 6px 16px rgba(0,0,0,.18);
    }
    @media (max-width:576px){
      .quicklinks-bar{max-height:none;opacity:1;transform:none;pointer-events:auto;}
      .quicklinks-bar .inner{flex-direction:column;align-items:flex-start;}
      .header-top{flex-direction:column;align-items:flex-start;gap:.75rem;}
      .navbar .container-fluid{padding:0 1rem;}
    }

    .page-wrap{padding:1.75rem 1.25rem}
    .title{font-weight:800;font-size:2rem;margin-bottom:.5rem}
    .subtitle{color:#5d6a7a;margin-bottom:1.5rem}

    .table thead th{border-bottom:2px solid #000; font-size:.95rem;}
    .table td,.table th{vertical-align:top}
    .customer-meta .label{display:block;font-size:.85rem;color:#6b7280}
    .traveller-list{list-style:none;margin:0;padding:0;}
    .traveller-list li{margin-bottom:.35rem;border-bottom:1px dashed rgba(0,0,0,.08);padding-bottom:.35rem;}
    .traveller-list li:last-child{border-bottom:0;margin-bottom:0;padding-bottom:0;}
    .actions form{display:inline-block;margin:0 4px;}
    .btn-approve{background:#22c55e;border:0;font-weight:700;border-radius:999px;padding:.45rem 1.2rem;color:#fff;}
    .btn-cancel{background:#ef4444;border:0;font-weight:700;border-radius:999px;padding:.45rem 1.2rem;color:#fff;}
    .btn-back{background:#3ea8ff;border:0;font-weight:800;border-radius:999px;padding:.7rem 1.4rem;color:#fff;}
    .empty-state{border:2px dashed #cbd5f5;padding:2.5rem;border-radius:20px;background:#fff;}
  </style>
</head>
<body>

<!-- Navbar -->
<nav class="navbar navbar-expand-lg">
  <div class="container-fluid">

    <div class="header-top">
      <a class="navbar-brand d-flex align-items-center" href="staff.php">
        <img src="img/logo_white.png" class="me-2" alt="Logo">
        <span class="brand-text">ROTANA TRAVEL &amp; TOURS</span>
      </a>

      <div class="ms-auto d-flex align-items-center gap-3">
        <span class="role-badge">STAFF</span>

        <!-- Notifications -->
        <div class="dropdown">
          <button
            class="btn btn-light rounded-circle notif-btn"
            type="button"
            data-bs-toggle="dropdown"
            data-notifications="true"
            data-initial-count="<?= $pendingCount ?>"
            aria-expanded="false"
            aria-label="Notifications"
          >
            <i class="bi bi-bell"></i>
            <span class="notif-badge <?= $pendingCount>0 ? '' : 'd-none' ?>" id="notificationBadge"><?= $pendingCount ?></span>
          </button>
          <div class="dropdown-menu dropdown-menu-end shadow-sm p-3 small notif-dropdown" id="notificationDropdown" style="width:360px;max-width:85vw;">
            <h6 class="fw-bold text-decoration-underline mb-2">NOTIFICATIONS</h6>
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
                    $message = $messageParts ? implode(' - ', $messageParts) : 'Incoming Customer Booking (Pending)';
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
            <span class="profile-initial"><?= htmlspecialchars(strtoupper(substr($_SESSION['username'] ?? 'Staff', 0, 1))) ?></span>
          </button>
          <ul class="dropdown-menu dropdown-menu-end shadow-sm">
            <li class="dropdown-item-text small text-muted">
              Signed in as<br>
              <strong><?= htmlspecialchars($_SESSION['username'] ?? 'Staff') ?></strong>
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
          <li><a href="staff.php"><i class="bi bi-speedometer2"></i>Dashboard</a></li>
          <li><a href="staff_booking.php"><i class="bi bi-calendar-check"></i>Bookings</a></li>
          <li><a class="active" href="staff_tasks.php"><i class="bi bi-list-task"></i>Tasks</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap container-fluid">
  <h1 class="title">Pending Booking Requests</h1>
  <p class="subtitle">Every customer submission from the app lands here first. Review the traveller list, confirm the details, then move it into the official booking list.</p>

  <?php if ($flashSuccess): ?>
    <div class="alert alert-success"><?= htmlspecialchars($flashSuccess) ?></div>
  <?php endif; ?>
  <?php if ($flashError): ?>
    <div class="alert alert-danger"><?= htmlspecialchars($flashError) ?></div>
  <?php endif; ?>

  <?php if (!$tasks): ?>
    <div class="empty-state text-center text-muted">
      <i class="bi bi-clipboard-check display-5 d-block mb-3"></i>
      <p class="mb-1 fw-bold">No tasks waiting</p>
      <p class="mb-0">New customer bookings will appear here for review.</p>
    </div>
  <?php else: ?>
    <div class="table-responsive">
      <table class="table table-bordered bg-white">
        <thead class="align-middle text-center">
          <tr>
            <th style="width:60px">#</th>
            <th style="width:230px">Requested</th>
            <th>Customer</th>
            <th>Package</th>
            <th style="width:320px">Travellers</th>
            <th style="width:220px">Action</th>
          </tr>
        </thead>
        <tbody>
          <?php foreach ($tasks as $index => $task): ?>
            <?php
              $bookingId = (int)$task['id'];
              $travellers = $travellersByRequest[$bookingId] ?? [];
              $docItems = $documentsByRequest[$bookingId] ?? [];
              $paymentsSummary = $paymentsSummaryByRequest[$bookingId] ?? ['paid' => 0.0, 'total' => 0.0];
              $paymentsDetail = $paymentsDetailByRequest[$bookingId] ?? [];
              $docJson = htmlspecialchars(json_encode($docItems, JSON_UNESCAPED_UNICODE), ENT_QUOTES);
              $payJson = htmlspecialchars(json_encode($paymentsDetail, JSON_UNESCAPED_UNICODE), ENT_QUOTES);
              $customerSafe = htmlspecialchars($task['customer_name'] ?? 'Customer', ENT_QUOTES);
              $docReady = (int)$task['documents_ready'] === 1;
              $paymentReady = (int)$task['payment_ready'] === 1;
            ?>
            <tr>
              <td class="text-center fw-bold"><?= $index + 1 ?></td>
              <td>
                <div class="fw-semibold"><?= formatTaskDate($task['created_at'] ?? null) ?></div>
                <?php if (!empty($task['departure_date'])): ?>
                  <div class="small text-muted">Departure: <?= htmlspecialchars(formatDisplayDate($task['departure_date'])) ?></div>
                <?php endif; ?>
              </td>
              <td>
                <div class="fw-semibold"><?= htmlspecialchars($task['customer_name'] ?? 'Unnamed') ?></div>
                <?php if (!empty($task['customer_email'])): ?>
                  <div class="customer-meta"><span class="label">Email</span><?= htmlspecialchars($task['customer_email']) ?></div>
                <?php endif; ?>
                <?php if (!empty($task['customer_phone'])): ?>
                  <div class="customer-meta mt-1"><span class="label">Phone</span><?= htmlspecialchars($task['customer_phone']) ?></div>
                <?php endif; ?>
              </td>
              <td>
                <div class="fw-semibold"><?= htmlspecialchars($task['package_name'] ?? 'Package') ?></div>
                <div class="small text-muted">
                  <?= (int)$task['adults'] ?> Adult(s)
                  <?php if ((int)$task['children'] > 0): ?>
                    · <?= (int)$task['children'] ?> Child(ren)
                  <?php endif; ?>
                </div>
                <div class="small text-muted">
                  Rooms: <?= (int)($task['rooms'] ?? 1) ?>
                </div>
                <div class="small text-muted">
                  Total: RM <?= number_format((float)$task['total_amount'], 2) ?>
                </div>
                <div class="mt-2 d-flex flex-column gap-1">
                  <span class="badge rounded-pill <?= $docReady ? 'bg-success' : 'bg-warning text-dark' ?>">Docs: <?= $docReady ? 'Complete' : 'Pending' ?></span>
                  <span class="badge rounded-pill <?= $paymentReady ? 'bg-success' : 'bg-warning text-dark' ?>">Payment: <?= $paymentReady ? 'Complete' : 'Pending' ?></span>
                </div>
              </td>
              <td>
                <?php if (!$travellers): ?>
                  <em class="text-muted small">Traveller list not provided.</em>
                <?php else: ?>
                  <ul class="traveller-list">
                    <?php foreach ($travellers as $trav): ?>
                      <li>
                        <strong><?= htmlspecialchars($trav['full_name'] ?? 'Traveller') ?></strong>
                        <div class="small text-muted">
                          <?php if (!empty($trav['gender'])): ?>
                            <?= htmlspecialchars(ucfirst($trav['gender'])) ?> ·
                          <?php endif; ?>
                          <?php if (!empty($trav['dob'])): ?>
                            DOB: <?= htmlspecialchars(formatDisplayDate($trav['dob'])) ?>
                          <?php endif; ?>
                          <?php if (!empty($trav['passport_no'])): ?>
                            · Passport: <?= htmlspecialchars($trav['passport_no']) ?>
                          <?php endif; ?>
                        </div>
                      </li>
                    <?php endforeach; ?>
                  </ul>
                <?php endif; ?>
              </td>
              <td class="text-center actions">
                <div class="d-grid gap-2 mb-3">
                  <button
                    type="button"
                    class="btn btn-outline-secondary"
                    data-bs-toggle="modal"
                    data-bs-target="#documentsModal"
                    data-request="<?= $bookingId ?>"
                    data-customer="<?= $customerSafe ?>"
                    data-docs='<?= $docJson ?>'
                    data-doc-ready="<?= $docReady ? '1' : '0' ?>"
                  >
                    <i class="bi bi-folder-check me-1"></i> Review Documents
                  </button>
                  <button
                    type="button"
                    class="btn btn-outline-primary"
                    data-bs-toggle="modal"
                    data-bs-target="#paymentsModal"
                    data-request="<?= $bookingId ?>"
                    data-customer="<?= $customerSafe ?>"
                    data-payments='<?= $payJson ?>'
                    data-total="<?= (float)$task['total_amount'] ?>"
                    data-paid="<?= $paymentsSummary['paid'] ?>"
                  >
                    <i class="bi bi-credit-card-2-front me-1"></i> Review Payments
                  </button>
                </div>
                <form method="post" class="mb-2 d-grid">
                  <input type="hidden" name="csrf" value="<?= $csrf ?>">
                  <input type="hidden" name="booking_id" value="<?= $bookingId ?>">
                  <input type="hidden" name="action" value="confirm">
                  <button class="btn btn-approve w-100" type="submit">
                    <i class="bi bi-check-circle me-1"></i> Confirm &amp; move to bookings
                  </button>
                </form>
                <form method="post" class="d-grid">
                  <input type="hidden" name="csrf" value="<?= $csrf ?>">
                  <input type="hidden" name="booking_id" value="<?= $bookingId ?>">
                  <input type="hidden" name="action" value="cancel">
                  <button class="btn btn-cancel w-100" type="submit" onclick="return confirm('Mark this request as cancelled?');">
                    <i class="bi bi-x-circle me-1"></i> Cancel request
                  </button>
                </form>
              </td>
            </tr>
          <?php endforeach; ?>
        </tbody>
      </table>
    </div>
  <?php endif; ?>

  <div class="mt-4">
    <a href="staff.php" class="btn btn-back">Back</a>
  </div>
</main>

<!-- Documents Modal -->
<div class="modal fade" id="documentsModal" tabindex="-1" aria-labelledby="documentsModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="documentsModalLabel">Documents</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="docs-summary text-muted mb-3"></div>
        <div class="table-responsive">
          <table class="table table-sm align-middle">
            <thead>
              <tr>
                <th>Type</th>
                <th>Status</th>
                <th>File</th>
                <th>Uploaded</th>
              </tr>
            </thead>
            <tbody class="docs-list"></tbody>
          </table>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Document Preview Modal -->
<div class="modal fade" id="docPreviewModal" tabindex="-1" aria-labelledby="docPreviewModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-xl modal-dialog-centered modal-fullscreen-sm-down">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="docPreviewModalLabel">Preview</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="doc-preview-container d-flex justify-content-center align-items-center" style="min-height:60vh;"></div>
      </div>
      <div class="modal-footer">
        <div class="me-auto doc-preview-fallback text-muted small"></div>
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<!-- Payments Modal -->
<div class="modal fade" id="paymentsModal" tabindex="-1" aria-labelledby="paymentsModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="paymentsModalLabel">Payments</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <div class="payments-summary text-muted mb-3"></div>
        <div class="table-responsive">
          <table class="table table-sm align-middle">
            <thead>
              <tr>
                <th>#</th>
                <th>Method</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Reference</th>
                <th>Created</th>
              </tr>
            </thead>
            <tbody class="payments-list"></tbody>
          </table>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
<script>
(function(){
  const docsModal = document.getElementById('documentsModal');
  const docPreviewModalEl = document.getElementById('docPreviewModal');
  let docPreviewModalInstance = null;
  if (docsModal) {
    docsModal.addEventListener('show.bs.modal', event => {
      const button = event.relatedTarget;
      const docs = safeJson(button?.getAttribute('data-docs'));
      const customer = button?.getAttribute('data-customer') || 'Customer';
      const ready = button?.getAttribute('data-doc-ready') === '1';
      docsModal.querySelector('#documentsModalLabel').textContent = `Documents – ${customer}`;
      const summary = ready ? 'All required documents are uploaded.' : 'Pending documents still require attention.';
      docsModal.querySelector('.docs-summary').textContent = summary;
      const list = docsModal.querySelector('.docs-list');
      list.innerHTML = docs.length ? docs.map(buildDocRow).join('') : '<tr><td colspan="4" class="text-center text-muted">No documents were uploaded for this request.</td></tr>';
    });

    docsModal.addEventListener('click', event => {
      const target = event.target.closest('[data-preview-doc]');
      if (!target) return;
      event.preventDefault();
      const file = target.getAttribute('data-file');
      if (!file) return;
      const name = target.getAttribute('data-name') || 'Document';
      const mime = target.getAttribute('data-mime') || '';
      openPreview(name, file, mime);
    });
  }

  function buildDocRow(doc) {
    const label = escapeHtml(doc.label || doc.doc_type || 'Document');
    const status = escapeHtml(doc.status || 'REQUIRED');
    const uploaded = doc.uploaded_at ? escapeHtml(doc.uploaded_at) : '-';
    let link = '-';
    if (doc.file_url) {
      const name = escapeHtml(doc.file_name || 'Preview');
      const safeUrl = escapeAttr(doc.file_url);
      const safeMime = escapeAttr(doc.mime_type || '');
      const safeName = escapeAttr(doc.file_name || label);
      link = `<button type="button" class="btn btn-link p-0 doc-preview" data-preview-doc="1" data-file="${safeUrl}" data-mime="${safeMime}" data-name="${safeName}">${name}</button>`;
    }
    const badgeClass = status === 'APPROVED' || status === 'ACTIVE' ? 'bg-success' : (status === 'PENDING' ? 'bg-warning text-dark' : 'bg-secondary');
    return `<tr><td>${label}</td><td><span class="badge ${badgeClass}">${status}</span></td><td>${link}</td><td>${uploaded}</td></tr>`;
  }

  const paymentsModal = document.getElementById('paymentsModal');
  if (paymentsModal) {
    paymentsModal.addEventListener('show.bs.modal', event => {
      const button = event.relatedTarget;
      const payments = safeJson(button?.getAttribute('data-payments'));
      const customer = button?.getAttribute('data-customer') || 'Customer';
      const total = parseFloat(button?.getAttribute('data-total') || '0');
      const paid = parseFloat(button?.getAttribute('data-paid') || '0');
      paymentsModal.querySelector('#paymentsModalLabel').textContent = `Payments – ${customer}`;
      paymentsModal.querySelector('.payments-summary').textContent = `Paid RM ${paid.toFixed(2)} of RM ${total.toFixed(2)} (Balance RM ${(Math.max(0,total-paid)).toFixed(2)})`;
      const list = paymentsModal.querySelector('.payments-list');
      if (!payments.length) {
        list.innerHTML = '<tr><td colspan="6" class="text-center text-muted">No manual payments logged yet.</td></tr>';
        return;
      }
      list.innerHTML = payments.map((p, idx) => buildPaymentRow(p, idx)).join('');
    });
  }

  function buildPaymentRow(p, idx) {
    const amount = typeof p.amount === 'undefined' ? 0 : parseFloat(p.amount);
    const currency = escapeHtml(p.currency || 'MYR');
    const method = escapeHtml(p.method || '-');
    const status = escapeHtml(p.status || 'PENDING');
    const ref = escapeHtml(p.transaction_ref || '-');
    const created = escapeHtml(p.created_at || '-');
    const badgeClass = status === 'PAID' ? 'bg-success' : status === 'PENDING' ? 'bg-warning text-dark' : 'bg-secondary';
    return `<tr><td>${idx + 1}</td><td>${method}</td><td>${currency} ${amount.toFixed(2)}</td><td><span class="badge ${badgeClass}">${status}</span></td><td>${ref}</td><td>${created}</td></tr>`;
  }

  function safeJson(value) {
    if (!value) return [];
    try {
      return JSON.parse(value);
    } catch (e) {
      return [];
    }
  }

  function escapeHtml(str) {
    return String(str ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
  }

  function escapeAttr(str) {
    return String(str ?? '').replace(/"/g, '&quot;');
  }

  function openPreview(name, url, mime) {
    if (!docPreviewModalEl) {
      window.open(url, '_blank');
      return;
    }
    if (!docPreviewModalInstance) {
      docPreviewModalInstance = new bootstrap.Modal(docPreviewModalEl);
    }
    docPreviewModalEl.querySelector('#docPreviewModalLabel').textContent = name;
    const container = docPreviewModalEl.querySelector('.doc-preview-container');
    const fallback = docPreviewModalEl.querySelector('.doc-preview-fallback');
    const normalizedMime = (mime || '').toLowerCase();
    const urlLower = url.toLowerCase();
    const isImage = normalizedMime.startsWith('image/') || /\.(png|jpe?g|gif|bmp|webp|heic)$/i.test(urlLower);
    const isPdf = normalizedMime.includes('pdf') || urlLower.endsWith('.pdf');
    let inner;
    const openLink = `<a href="${escapeAttr(url)}" target="_blank" rel="noopener">Open original file</a>`;
    if (isImage) {
      inner = `<img src="${escapeAttr(url)}" alt="${escapeAttr(name)}" class="img-fluid" style="max-height:80vh;object-fit:contain;">`;
      fallback.innerHTML = openLink;
    } else if (isPdf) {
      inner = `<iframe src="${escapeAttr(url)}" style="width:100%;height:75vh;border:0;" title="${escapeAttr(name)}"></iframe>`;
      fallback.innerHTML = openLink;
    } else {
      inner = `<p class="text-center text-muted">Preview not available for this file type.</p>`;
      fallback.innerHTML = openLink;
    }
    container.innerHTML = inner;
    docPreviewModalInstance.show();
  }
})();
</script>
</body>
</html>
