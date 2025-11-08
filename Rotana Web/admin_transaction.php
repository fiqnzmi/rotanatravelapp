<?php
// admin_transaction.php â€” list of individual payments with Records-style filters
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'admin')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025',[
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

/* ===== Navbar notifications (demo = pending bookings) ===== */
$viewId = isset($_GET['view']) ? (int)($_GET['view'] ?? 0) : 0;
$self = htmlspecialchars(basename($_SERVER['PHP_SELF']));

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

/* ===== Query params ===== */
$q        = trim($_GET['q'] ?? '');         // search by package name
$sortPkg  = ($_GET['sort'] ?? '') === 'package';
$useYear  = ($_GET['year_on'] ?? '') === '1';
$useMonth = ($_GET['month_on'] ?? '') === '1';  // only used if year is on
$year     = $_GET['year'] ?? '';
$month    = $_GET['month'] ?? '';

/* ===== Build WHERE ===== */
$where = [];
$params = [];

if ($q !== '') { $where[] = "p.title LIKE ?"; $params[] = "%$q%"; }
if ($useYear && $year !== '' && ctype_digit($year)) {
  $where[] = "YEAR(pay.created_at) = ?";
  $params[] = (int)$year;
  if ($useMonth && $month !== '' && ctype_digit($month) && (int)$month >= 1 && (int)$month <= 12) {
    $where[] = "MONTH(pay.created_at) = ?";
    $params[] = (int)$month;
  }
}

$whereSql = $where ? "WHERE ".implode(" AND ", $where) : "";

/* ===== Main list (payments) =====
   payment -> booking -> package
*/
$sql = "
  SELECT
    pay.id        AS PaymentID,
    pay.amount    AS Amount,
    pay.method    AS Method,
    pay.status    AS Status,
    pay.currency  AS Currency,
    pay.created_at AS PaymentDate,
    p.id          AS PackageID,
    p.title       AS PackageName
  FROM payments pay
  INNER JOIN bookings b ON b.id = pay.booking_id
  INNER JOIN packages p ON p.id = b.package_id
  $whereSql
  ".($sortPkg
      ? "ORDER BY p.title ASC, pay.created_at DESC"
      : "ORDER BY pay.created_at DESC, p.title ASC")."
";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll();

$paymentDetail = null;
$gatewayMeta = [];
if ($viewId > 0) {
  $detailStmt = $pdo->prepare("
    SELECT
      pay.id             AS PaymentID,
      pay.amount         AS Amount,
      pay.currency       AS Currency,
      pay.method         AS Method,
      pay.status         AS Status,
      pay.transaction_ref AS TransactionRef,
      pay.paid_at        AS PaidAt,
      pay.created_at     AS CreatedAt,
      pay.gateway_payload AS GatewayPayload,
      b.id               AS BookingID,
      b.status           AS BookingStatus,
      b.created_at       AS BookingCreatedAt,
      p.title            AS PackageName,
      u.name             AS CustomerName,
      u.email            AS CustomerEmail,
      u.phone            AS CustomerPhone
    FROM payments pay
    INNER JOIN bookings b ON b.id = pay.booking_id
    INNER JOIN users    u ON u.id = b.user_id
    INNER JOIN packages p ON p.id = b.package_id
    WHERE pay.id = ?
    LIMIT 1
  ");
  $detailStmt->execute([$viewId]);
  $paymentDetail = $detailStmt->fetch();

  if ($paymentDetail && !empty($paymentDetail['GatewayPayload'])) {
    $decoded = json_decode((string)$paymentDetail['GatewayPayload'], true);
    if (is_array($decoded)) {
      $gatewayMeta = [
        'Bill Code'     => $decoded['bill']['BillCode'] ?? null,
        'External Ref'  => $decoded['request']['external_ref'] ?? null,
      ];
    }
  }
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin - Transaction</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
  <style>
    body{background:#f7f8fc;}
    /* NAVBAR (admin red) */
    .navbar{
      background:#e31f25;
      border-bottom:1px solid rgba(0,0,0,.08);
      box-shadow:0 6px 16px rgba(0,0,0,.14);
    }
    .navbar-brand img{height:36px}
    .brand-text{font-weight:800;color:#fff;letter-spacing:.3px}
    .navbar .container-fluid{display:flex;flex-direction:column;align-items:stretch;padding:0 1.5rem;}
    .header-top{display:flex;align-items:center;width:100%;margin-bottom:.15rem;}
    .role-badge{color:#fff;font-weight:800;margin-right:.75rem}
    .notif-btn{position:relative}
    .notif-badge{position:absolute;top:-6px;right:-6px;background:#000;color:#fff;border-radius:999px;font-size:.75rem;padding:2px 7px;line-height:1;border:2px solid #fff;}
    .profile-btn{width:40px;height:40px;border:0;padding:0;background:#fff;color:#e31f25;font-weight:700;display:flex;align-items:center;justify-content:center;}
    .profile-initial{font-size:1rem;}
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

    .page-wrap{padding:1.75rem 1.25rem}
    .title{font-weight:800;font-size:2.4rem;margin:0}

    /* Filter panel */
    .dropdown-menu.filter-panel{width:420px;max-width:85vw;border:1px solid #000;border-radius:.5rem;padding:.75rem .85rem;}
    .filter-panel h6{font-weight:800;text-decoration:underline;margin:.2rem 0 .6rem}
    .chip{display:inline-block;background:#222;color:#fff;border-radius:16px;padding:.35rem .8rem;font-weight:700;margin-right:.4rem;cursor:pointer;user-select:none}
    .chip.secondary{background:#5b5bf0}
    .chip.inactive{opacity:.45}

    .search-wrap{max-width:520px}
    .search-input{border-radius:999px;padding:.8rem 1.1rem}

    /* Table framed look */
    .frame{border:4px solid #5a29ff; border-radius:2px; background:#fff}
    .tr-table{margin:0; border-collapse:separate; border-spacing:0}
    .tr-table thead th{border:2px solid #000 !important; text-align:center; vertical-align:middle; font-weight:700;}
    .tr-table td{border:2px solid #000 !important; vertical-align:middle;}

    .btn-view{background:#6bd12f; border:0; font-weight:800; border-radius:12px; padding:.5rem 1rem}
    .btn-back{display:inline-block; background:#1da1ff; color:#fff; border:0; font-weight:800; border-radius:999px; padding:.9rem 2.2rem;}

    /* Detail view */
    .detail-wrapper{max-width:960px;margin:0 auto;}
    .detail-card{border:3px solid #5a29ff;border-radius:24px;background:#fff;padding:1.5rem 1.75rem;}
    .detail-label{font-size:.85rem;font-weight:700;text-transform:uppercase;color:#666;margin-bottom:.25rem;}
    .detail-value{font-size:1.1rem;font-weight:700;}
    .detail-email{overflow-wrap:anywhere;}
    .detail-section-title{font-weight:800;text-transform:uppercase;font-size:1rem;margin-bottom:.8rem;}
    .detail-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:1rem 1.5rem;}
    .detail-actions{display:flex;flex-wrap:wrap;gap:.75rem;align-items:center;}
    .detail-actions .btn-view{background:#28a745;}

    @media (max-width:576px){
      .quicklinks-bar{max-height:none;opacity:1;transform:none;pointer-events:auto;}
      .quicklinks-bar .inner{flex-direction:column;align-items:flex-start;}
      .header-top{flex-direction:column;align-items:flex-start;gap:.75rem;}
      .navbar .container-fluid{padding:0 1rem;}
    }
  </style>
</head>
<body>

<!-- Header + Quick Links -->
<nav class="navbar navbar-expand-lg">
  <div class="container-fluid">

    <div class="header-top">
      <a class="navbar-brand d-flex align-items-center" href="admin.php">
        <img src="img/logo_white.png" class="me-2" alt="Logo">
        <span class="brand-text">ROTANA TRAVEL &amp; TOURS</span>
      </a>

      <div class="ms-auto d-flex align-items-center gap-3">
        <span class="role-badge">ADMIN</span>

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
          <li><a href="admin_package.php"><i class="bi bi-boxes"></i>Packages</a></li>
          <li><a href="admin_records.php"><i class="bi bi-archive"></i>Records</a></li>
          <li><a href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a class="active" href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap container-fluid">
  <?php if ($viewId === 0): ?>
    <div class="d-flex justify-content-between align-items-center mb-3">
      <h1 class="title">TRANSACTION</h1>

      <div class="dropdown">
        <button class="btn btn-dark rounded-pill" data-bs-toggle="dropdown" aria-expanded="false">
          <i class="bi bi-sliders me-1"></i> Filter
        </button>
        <div class="dropdown-menu dropdown-menu-end filter-panel shadow-sm">
          <h6>Filter by</h6>
          <?php $isPkg=$sortPkg; $isYear=$useYear; $isMonth=($useYear && $useMonth); ?>
          <div class="mb-2">
            <a class="chip <?= $isPkg?'':'inactive' ?>"
               href="<?= $self ?>?<?= http_build_query(['q'=>$q,'sort'=>($isPkg?'':"package"),'year_on'=>$isYear?1:0,'month_on'=>$isMonth?1:0,'year'=>$year,'month'=>$month]) ?>">Package</a>
            <span class="chip secondary <?= $isYear?'':'inactive' ?>" id="chipYear">Year</span>
            <span class="chip secondary <?= $isMonth?'':'inactive' ?>" id="chipMonth">Month</span>
          </div>

          <form class="row g-2 align-items-end" method="get" action="<?= $self ?>" id="filterForm">
            <input type="hidden" name="q" value="<?= htmlspecialchars($q) ?>">
            <input type="hidden" name="sort" value="<?= $sortPkg ? 'package' : '' ?>">
            <input type="hidden" name="year_on"  id="yearFlag"  value="<?= $useYear?1:0 ?>">
            <input type="hidden" name="month_on" id="monthFlag" value="<?= $useMonth?1:0 ?>">

            <div id="yearRow" class="col-12 <?= $useYear?'':'d-none' ?>">
              <label class="form-label small mb-1">Year</label>
              <input type="number" name="year" class="form-control form-control-sm" min="2000" max="2100" value="<?= htmlspecialchars($year) ?>" placeholder="YYYY">
            </div>

            <div id="monthRow" class="col-12 <?= ($useYear && $useMonth)?'':'d-none' ?>">
              <label class="form-label small mb-1">Month (1–12)</label>
              <input type="number" name="month" class="form-control form-control-sm" min="1" max="12" value="<?= htmlspecialchars($month) ?>" placeholder="MM">
            </div>

            <div class="col-12">
              <button class="btn btn-danger w-100"><i class="bi bi-sliders me-1"></i>Filter</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <form class="search-wrap mb-3" method="get" action="<?= $self ?>">
      <input type="hidden" name="sort" value="<?= $sortPkg ? 'package' : '' ?>">
      <input type="hidden" name="year_on" value="<?= $useYear?1:0 ?>">
      <input type="hidden" name="month_on" value="<?= $useMonth?1:0 ?>">
      <input type="hidden" name="year" value="<?= htmlspecialchars($year) ?>">
      <input type="hidden" name="month" value="<?= htmlspecialchars($month) ?>">

      <div class="input-group" style="max-width:520px">
        <input type="text" name="q" value="<?= htmlspecialchars($q) ?>" class="form-control search-input" placeholder='Search package...'>
        <button class="btn btn-outline-secondary rounded-end-pill"><i class="bi bi-search"></i></button>
      </div>
    </form>

    <?php if ($useYear && ctype_digit($year)): ?>
      <h2 class="fw-bold ms-1 mb-3"><?= (int)$year ?></h2>
    <?php endif; ?>

    <div class="frame">
      <table class="table tr-table">
        <thead>
          <tr>
            <th style="width:100px">No.</th>
            <th>Amount</th>
            <th style="width:240px">Date</th>
            <th style="width:180px">Action</th>
          </tr>
        </thead>
        <tbody>
          <?php if (!$rows): ?>
            <tr><td colspan="4" class="text-center text-muted py-4">No results found.</td></tr>
          <?php else: $i=1; foreach ($rows as $r): ?>
            <tr>
              <td class="text-center"><?= $i++ ?></td>
              <td><?= htmlspecialchars($r['Currency']) ?> <?= number_format((float)$r['Amount'], 2) ?></td>
              <td class="text-center"><?= htmlspecialchars(substr($r['PaymentDate'],0,10)) ?></td>
              <td class="text-center">
                <a class="btn btn-view" href="<?= $self ?>?view=<?= (int)$r['PaymentID'] ?>">VIEW</a>
              </td>
            </tr>
          <?php endforeach; endif; ?>
        </tbody>
      </table>
    </div>

    <div class="text-center my-5">
      <a href="admin.php" class="btn btn-back">Back</a>
    </div>
  <?php else: ?>
    <div class="detail-wrapper">
      <div class="d-flex justify-content-between flex-wrap align-items-center mb-3">
        <h1 class="title mb-0">TRANSACTION DETAIL</h1>
        <div class="detail-actions">
          <button class="btn btn-view" id="printPaymentBtn">Print Receipt</button>
          <a href="<?= $self ?>" class="btn btn-back">Back to list</a>
        </div>
      </div>

      <?php if (!$paymentDetail): ?>
        <div class="alert alert-danger">We couldn't find that payment record. It may have been removed.</div>
      <?php else: ?>
      <div class="detail-card" id="paymentDetailCard">
        <div class="detail-section-title">Payment Summary</div>
        <div class="detail-grid mb-4">
          <div>
            <div class="detail-label">Payment ID</div>
            <div class="detail-value">#<?= (int)$paymentDetail['PaymentID'] ?></div>
          </div>
          <div>
            <div class="detail-label">Amount</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['Currency']) ?> <?= number_format((float)$paymentDetail['Amount'], 2) ?></div>
          </div>
          <div>
            <div class="detail-label">Method</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['Method']) ?></div>
          </div>
          <div>
            <div class="detail-label">Status</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['Status']) ?></div>
          </div>
          <div>
            <div class="detail-label">Transaction Ref</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['TransactionRef'] ?? '—') ?></div>
          </div>
          <div>
            <div class="detail-label">Paid at</div>
            <div class="detail-value"><?= $paymentDetail['PaidAt'] ? htmlspecialchars($paymentDetail['PaidAt']) : '—' ?></div>
          </div>
          <div>
            <div class="detail-label">Created</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['CreatedAt']) ?></div>
          </div>
        </div>

        <div class="detail-section-title">Booking & Customer</div>
        <div class="detail-grid mb-4">
          <div>
            <div class="detail-label">Booking</div>
            <div class="detail-value">#<?= (int)$paymentDetail['BookingID'] ?> · <?= htmlspecialchars($paymentDetail['PackageName']) ?></div>
          </div>
          <div>
            <div class="detail-label">Booking status</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['BookingStatus']) ?></div>
          </div>
          <div>
            <div class="detail-label">Customer</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['CustomerName']) ?></div>
          </div>
          <div>
            <div class="detail-label">Email</div>
            <div class="detail-value detail-email"><?= htmlspecialchars($paymentDetail['CustomerEmail']) ?></div>
          </div>
          <div>
            <div class="detail-label">Phone</div>
            <div class="detail-value"><?= htmlspecialchars($paymentDetail['CustomerPhone'] ?? '—') ?></div>
          </div>
        </div>

        <?php if ($gatewayMeta): ?>
          <div class="detail-section-title">Gateway Payload</div>
          <div class="detail-grid">
            <?php foreach ($gatewayMeta as $label => $value): ?>
              <?php if ($value): ?>
                <div>
                  <div class="detail-label"><?= htmlspecialchars($label) ?></div>
                  <div class="detail-value"><?= htmlspecialchars($value) ?></div>
                </div>
              <?php endif; ?>
            <?php endforeach; ?>
          </div>
        <?php endif; ?>
      </div>
      <?php endif; ?>
    </div>
    <?php endif; ?>
  </main>


<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
<script>
  // Filter chip toggles
  const chipYear  = document.getElementById('chipYear');
  const chipMonth = document.getElementById('chipMonth');
  const yearRow   = document.getElementById('yearRow');
  const monthRow  = document.getElementById('monthRow');
  const yearFlag  = document.getElementById('yearFlag');
  const monthFlag = document.getElementById('monthFlag');

  chipYear?.addEventListener('click', () => {
    const on = !yearRow.classList.contains('d-none');
    if (on) {
      yearRow.classList.add('d-none');
      monthRow.classList.add('d-none');
      yearFlag.value = '0';
      monthFlag.value = '0';
      chipYear.classList.add('inactive');
      chipMonth.classList.add('inactive');
    } else {
      yearRow.classList.remove('d-none');
      yearFlag.value = '1';
      chipYear.classList.remove('inactive');
    }
  });

  chipMonth?.addEventListener('click', () => {
    const yearOn = yearFlag.value === '1';
    if (!yearOn) return;
    const on = !monthRow.classList.contains('d-none');
    if (on) {
      monthRow.classList.add('d-none');
      monthFlag.value = '0';
      chipMonth.classList.add('inactive');
    } else {
      monthRow.classList.remove('d-none');
      monthFlag.value = '1';
      chipMonth.classList.remove('inactive');
    }
  });

  // Printable receipt
  const printBtn = document.getElementById('printPaymentBtn');
  const detailCard = document.getElementById('paymentDetailCard');
  printBtn?.addEventListener('click', () => {
    if (!detailCard) return;
    const w = window.open('', '', 'width=900,height=700');
    if (!w) return;
    w.document.write(`<!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Payment Receipt</title>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
          <style>
            body{font-family:'Segoe UI',sans-serif;padding:1.5rem;background:#fff;}
            .detail-card{border:2px solid #5a29ff;border-radius:24px;padding:1.5rem;}
            .detail-label{font-size:.85rem;font-weight:700;text-transform:uppercase;color:#666;margin-bottom:.25rem;}
            .detail-value{font-size:1.1rem;font-weight:700;}
            .detail-section-title{font-weight:800;text-transform:uppercase;font-size:1rem;margin-bottom:.8rem;}
            .detail-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:1rem;}
          </style>
        </head>
        <body>
          ${detailCard.outerHTML}
        </body>
      </html>`);
    w.document.close();
    w.focus();
    w.print();
  });
</script>
</body>
</html>
