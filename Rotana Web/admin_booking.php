<?php
// admin_booking.php â€” Admin view of bookings (list + in-page detail)
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'admin')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO(
  'mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4',
  'sabrisae_rotanatravel','Rotanatravel_2025',
  [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
  ]
);

/* ====== Navbar notifications (pending bookings) ====== */
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

/* ====== Routing ====== */
$viewId = isset($_GET['view']) ? (int)$_GET['view'] : 0;
$self   = htmlspecialchars(basename($_SERVER['PHP_SELF']));

/* ====== Flash message (green success box) ====== */
$flash = $_SESSION['flash_success'] ?? '';
unset($_SESSION['flash_success']);

/* ====== If LIST view, prep query/filters ====== */
$reportData = null;
$rows = [];
if ($viewId === 0) {
  $q       = trim($_GET['q'] ?? '');         // search customer
  $sort    = $_GET['sort'] ?? '';            // '' or 'package'
  $useDate = ($_GET['date'] ?? '') === '1';  // toggle date inputs
  $from    = $_GET['from'] ?? '';
  $to      = $_GET['to'] ?? '';
  $orderPref = strtolower($_GET['order'] ?? 'newest');
  $orderPref = in_array($orderPref, ['oldest','newest'], true) ? $orderPref : 'newest';

  $where = [];
  $params = [];
  if ($q !== '') { $where[] = "u.name LIKE ?"; $params[] = "%$q%"; }
  if ($useDate && $from !== '') { $where[] = "DATE(b.created_at) >= ?"; $params[] = $from; }
  if ($useDate && $to   !== '') { $where[] = "DATE(b.created_at) <= ?"; $params[] = $to; }

  $whereSql = $where ? "WHERE ".implode(" AND ", $where) : "";

  $direction = ($orderPref === 'oldest') ? 'ASC' : 'DESC';
  $directionSecondary = ($orderPref === 'oldest') ? 'ASC' : 'DESC';
  $orderSql = "ORDER BY b.created_at $direction, b.id $directionSecondary";
  if ($sort === 'package') {
    $orderSql = "ORDER BY p.title ASC, b.created_at $direction";
  }

  $sql = "
    SELECT b.id AS BookingID,
           b.created_at AS CreatedAt,
           b.status AS Status,
           u.name AS CustomerName,
           p.title AS PackageName
    FROM bookings b
    JOIN users    u ON u.id = b.user_id
    JOIN packages p ON p.id = b.package_id
    $whereSql
    $orderSql
    LIMIT 200
  ";
  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  $rows = $stmt->fetchAll();

  $reportData = [
    'totalBookings' => count($rows),
    'statusCounts'  => [],
    'packageCounts' => [],
    'topPackages'   => [],
    'latestEntries' => [],
  ];

  foreach ($rows as $row) {
    $statusKey = strtoupper($row['Status'] ?? 'UNKNOWN');
    $reportData['statusCounts'][$statusKey] = ($reportData['statusCounts'][$statusKey] ?? 0) + 1;

    $pkgKey = trim($row['PackageName'] ?? 'Unknown Package');
    $reportData['packageCounts'][$pkgKey] = ($reportData['packageCounts'][$pkgKey] ?? 0) + 1;
  }

  arsort($reportData['packageCounts']);
  $reportData['topPackages'] = array_slice($reportData['packageCounts'], 0, 5, true);
  $reportData['latestEntries'] = array_slice($rows, 0, 5);
}

/* ====== If DETAIL view, fetch booking + customer + travellers ====== */
$detail = null;
$people = [];
if ($viewId > 0) {
  $st = $pdo->prepare("
    SELECT 
      b.id            AS BookingID,
      b.created_at    AS BookingCreatedAt,
      b.status        AS Status,
      p.title         AS PackageName,
      u.id            AS CustomerID,
      u.name          AS LeadName,
      u.email         AS Email,
      NULL            AS Phone,
      NULL            AS IC,
      NULL            AS Gender,
      NULL            AS DateOfBirth,
      NULL            AS Address
    FROM bookings b
    JOIN users    u ON u.id = b.user_id
    JOIN packages p ON p.id = b.package_id
    WHERE b.id = ?
    LIMIT 1
  ");
  $st->execute([$viewId]);
  $detail = $st->fetch();

  // Travellers (requires booking_traveller table)
  $pe = $pdo->prepare("
    SELECT id            AS TravellerID,
           full_name     AS FullName,
           gender        AS Gender,
           dob           AS DateOfBirth,
           passport_no   AS PassportNo,
           passport_issue_date  AS PassportIssue,
           passport_expiry_date AS PassportExpiry,
           NULL          AS Relationship
    FROM booking_travellers
    WHERE booking_id = ?
    ORDER BY id
  ");
  $pe->execute([$viewId]);
  $people = $pe->fetchAll();
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin - Booking</title>
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
    .notif-btn.notif-pulse{animation:notifPulse .8s ease-in-out 3;}
    @keyframes notifPulse{
      0%,100%{transform:scale(1);}
      50%{transform:scale(1.08);}
    }
    .profile-btn{width:40px;height:40px;border:0;padding:0;background:#fff;color:#e31f25;font-weight:700;display:flex;align-items:center;justify-content:center;}
    .profile-initial{font-size:1rem;}
    .notif-dropdown,.dropdown-menu.filter-panel{width:360px;max-width:85vw;border:1px solid #000;border-radius:.6rem;padding:.5rem .75rem;}
    .notif-dropdown h6,.filter-panel h6{font-weight:800;text-decoration:underline;margin:.25rem 0 .5rem}

    /* QUICK LINKS BAR (hover reveal) */
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
    .title{font-weight:800;font-size:2rem;margin:0}

    /* Chips inside filter panel */
    .chip{display:inline-block;background:#222;color:#fff;border-radius:16px;padding:.35rem .8rem;font-weight:700;margin-right:.4rem;cursor:pointer;user-select:none}
    .chip.secondary{background:#5b5bf0}
    .chip.inactive{opacity:.45}

    /* Search box */
    .search-wrap{max-width:520px}
    .search-input{border-radius:999px;padding:.8rem 1.1rem}

    /* Table */
    .table thead th{border-bottom:2px solid #000}
    .table td,.table th{vertical-align:middle}
    .btn-view{background:#6bd12f;border:0;font-weight:800;border-radius:12px}
    .btn-back{background:#e31f25;border:0;font-weight:800;border-radius:999px;padding:.7rem 1.4rem}

    /* Detail panels to mimic your mockup */
    .rounded-panel{border:2px solid #222;border-radius:28px;padding:1.5rem 1.25rem;background:#fff;}
    .lbl{font-weight:800;margin-bottom:.25rem}
    .chip-readonly{display:inline-block;background:#f1f3f5;border:2px solid #222;border-radius:12px;padding:.35rem .75rem;min-width:120px;}

    /* Report */
    .report-actions{display:flex;flex-wrap:wrap;gap:.75rem;margin-bottom:1rem;}
    .btn-report{border-radius:999px;font-weight:700;padding:.6rem 1.4rem;border:0;}
    .btn-report.primary{background:#e31f25;color:#fff;}
    .btn-report.secondary{background:#fff;color:#e31f25;border:2px solid #e31f25;}
    .btn-report:disabled{opacity:.5;pointer-events:none;}
    .report-card{border:2px solid #222;border-radius:28px;padding:1.5rem;background:#fff;margin-bottom:1.5rem;}
    .report-section-title{font-size:1rem;font-weight:800;text-transform:uppercase;margin-bottom:.6rem;}
    .report-stat{background:#f8f9fb;border:2px solid #222;border-radius:20px;padding:1rem 1.2rem;height:100%;}
    .report-stat .label{font-size:.85rem;font-weight:700;color:#555;text-transform:uppercase;}
    .report-stat .value{font-size:2rem;font-weight:800;color:#111;}
    .report-list{list-style:none;padding-left:0;margin-bottom:0;}
    .report-list li{padding:.35rem 0;border-bottom:1px solid #eee;font-weight:600;}
    .report-list li:last-child{border-bottom:0;}

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
          <li><a class="active" href="admin_booking.php"><i class="bi bi-calendar-check"></i>Bookings</a></li>
          <li><a href="admin_package.php"><i class="bi bi-boxes"></i>Packages</a></li>
          <li><a href="admin_records.php"><i class="bi bi-archive"></i>Records</a></li>
          <li><a href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap container-fluid">

  <?php if ($flash): ?>
    <div class="alert alert-success text-center" role="alert">
      <?= htmlspecialchars($flash) ?>
    </div>
  <?php endif; ?>

<?php if ($viewId === 0): ?>
  <!-- ======================= LIST VIEW ======================= -->

  <!-- Header row with Title (left) + Filter dropdown (right) -->
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="title">BOOKING</h1>

    <?php
      $qEsc    = htmlspecialchars($_GET['q'] ?? '');
      $sort    = $_GET['sort'] ?? '';
      $useDate = (($_GET['date'] ?? '') === '1');
      $from    = htmlspecialchars($_GET['from'] ?? '');
      $to      = htmlspecialchars($_GET['to'] ?? '');
      $isPkg   = ($sort==='package'); $isDate=$useDate;
    ?>

    <div class="dropdown">
      <button class="btn btn-dark rounded-pill" data-bs-toggle="dropdown" aria-expanded="false">
        <i class="bi bi-sliders me-1"></i> Filter
      </button>
      <div class="dropdown-menu dropdown-menu-end filter-panel shadow-sm">
        <h6>FILTER BY</h6>
        <div class="mb-2">
          <a class="chip <?= $isPkg?'':'inactive' ?>"
             href="<?= $self ?>?<?= http_build_query(['q'=>$qEsc,'sort'=>($isPkg?'':'package'),'date'=>$isDate?1:0,'from'=>$from,'to'=>$to,'order'=>$orderPref]) ?>">Package</a>
          <span class="chip secondary <?= $isDate?'':'inactive' ?>" id="chipDate">Date</span>
        </div>

        <form class="row g-2 align-items-end" method="get" action="<?= $self ?>" id="dateForm">
          <input type="hidden" name="q" value="<?= $qEsc ?>">
          <input type="hidden" name="sort" value="<?= htmlspecialchars($sort) ?>">
          <input type="hidden" name="date" value="<?= $isDate?1:0 ?>" id="dateFlag">
          <div class="<?= $isDate?'':'d-none' ?>" id="dateInputs">
            <div class="col-6">
              <label class="form-label small mb-1">From</label>
              <input type="date" name="from" value="<?= $from ?>" class="form-control form-control-sm">
            </div>
            <div class="col-6">
              <label class="form-label small mb-1">To</label>
              <input type="date" name="to" value="<?= $to ?>" class="form-control form-control-sm">
            </div>
            <div class="col-12 mt-2">
              <button class="btn btn-danger w-100"><i class="bi bi-sliders me-1"></i>Apply</button>
            </div>
          </div>
          <div class="<?= $isDate?'d-none':'' ?> text-muted small" id="dateHint">Toggle <strong>Date</strong> to filter by range.</div>
        </form>

        <div class="mt-3">
          <label class="form-label small mb-1 text-uppercase fw-bold">Preference</label>
          <select class="form-select form-select-sm" name="order" form="dateForm" onchange="document.getElementById('dateForm').submit()">
            <option value="newest" <?= $orderPref==='newest'?'selected':'' ?>>Newest first</option>
            <option value="oldest" <?= $orderPref==='oldest'?'selected':'' ?>>Oldest first</option>
          </select>
        </div>
      </div>
    </div>
  </div>

  <!-- Search -->
  <form class="search-wrap mb-3" method="get" action="<?= $self ?>">
    <input type="hidden" name="sort" value="<?= htmlspecialchars($sort) ?>">
    <input type="hidden" name="date" value="<?= $useDate?1:0 ?>">
    <input type="hidden" name="order" value="<?= $orderPref ?>">
    <input type="hidden" name="from" value="<?= $from ?>">
    <input type="hidden" name="to"   value="<?= $to ?>">

    <div class="input-group" style="max-width:520px">
      <input type="text" name="q" value="<?= $qEsc ?>" class="form-control search-input" placeholder="Search customer...">
      <button class="btn btn-outline-secondary rounded-end-pill"><i class="bi bi-search"></i></button>
    </div>
  </form>

  <?php if ($reportData !== null): ?>
    <div class="report-actions">
      <button type="button" class="btn-report primary" id="toggleReportBtn" data-expanded="false">
        View Report
      </button>
      <button type="button" class="btn-report secondary" id="printReportBtn" <?= $reportData['totalBookings']>0 ? '' : 'disabled' ?>>
        Print Report
      </button>
    </div>

    <section id="bookingReport" class="report-card d-none">
      <div class="row g-4">
        <div class="col-12 col-lg-4">
          <div class="report-stat">
            <div class="label">Total bookings</div>
            <div class="value"><?= (int)$reportData['totalBookings'] ?></div>
          </div>
        </div>
        <div class="col-12 col-lg-4">
          <div>
            <div class="report-section-title">Status breakdown</div>
            <?php if (empty($reportData['statusCounts'])): ?>
              <div class="text-muted small">No records in view.</div>
            <?php else: ?>
              <ul class="report-list">
                <?php foreach ($reportData['statusCounts'] as $status => $count): ?>
                  <li><?= htmlspecialchars(ucwords(strtolower($status))) ?> <span class="float-end"><?= (int)$count ?></span></li>
                <?php endforeach; ?>
              </ul>
            <?php endif; ?>
          </div>
        </div>
        <div class="col-12 col-lg-4">
          <div>
            <div class="report-section-title">Top packages</div>
            <?php if (empty($reportData['topPackages'])): ?>
              <div class="text-muted small">No package data.</div>
            <?php else: ?>
              <ul class="report-list">
                <?php foreach ($reportData['topPackages'] as $pkg => $count): ?>
                  <li><?= htmlspecialchars($pkg) ?> <span class="float-end"><?= (int)$count ?></span></li>
                <?php endforeach; ?>
              </ul>
            <?php endif; ?>
          </div>
        </div>
      </div>

      <div class="mt-4">
        <div class="report-section-title">Latest bookings in view</div>
        <?php if (empty($reportData['latestEntries'])): ?>
          <div class="text-muted small">No booking entries available.</div>
        <?php else: ?>
          <div class="table-responsive">
            <table class="table table-bordered mb-0">
              <thead class="table-light">
                <tr>
                  <th>#</th>
                  <th>Customer</th>
                  <th>Package</th>
                  <th>Status</th>
                  <th>Registered</th>
                </tr>
              </thead>
              <tbody>
                <?php foreach ($reportData['latestEntries'] as $idx => $entry): ?>
                  <tr>
                    <td><?= $idx+1 ?></td>
                    <td><?= htmlspecialchars($entry['CustomerName']) ?></td>
                    <td><?= htmlspecialchars($entry['PackageName']) ?></td>
                    <td><?= htmlspecialchars(ucwords(strtolower($entry['Status']))) ?></td>
                    <td><?= htmlspecialchars(substr($entry['CreatedAt'],0,10)) ?></td>
                  </tr>
                <?php endforeach; ?>
              </tbody>
            </table>
          </div>
        <?php endif; ?>
      </div>
    </section>
  <?php endif; ?>

  <!-- Table -->
  <div class="table-responsive">
    <table class="table table-bordered bg-white">
      <thead class="align-middle text-center">
        <tr>
          <th style="width:80px">No.</th>
          <th>Customer</th>
          <th>Package</th>
          <th style="width:180px">Registered on</th>
          <th style="width:140px">Action</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$rows): ?>
          <tr><td colspan="5" class="text-center text-muted py-4">No results found.</td></tr>
        <?php else: ?>
          <?php $i=1; foreach ($rows as $r): ?>
            <tr>
              <td class="text-center"><?= $i++ ?></td>
              <td><?= htmlspecialchars($r['CustomerName']) ?></td>
              <td><?= htmlspecialchars($r['PackageName']) ?></td>
              <td class="text-center"><?= htmlspecialchars(substr($r['CreatedAt'],0,10)) ?></td>
              <td class="text-center">
                <!-- SAME FILE VIEW -->
                <a class="btn btn-view" href="<?= $self ?>?view=<?= (int)$r['BookingID'] ?>">VIEW</a>
              </td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>

  <div class="mt-4">
    <a href="admin.php" class="btn btn-back">Back</a>
  </div>

<?php else: ?>
  <!-- ======================= DETAIL VIEW ======================= -->
  <?php if (!$detail): ?>
    <div class="alert alert-danger" role="alert">We couldnâ€™t find that booking. It may have been removed.</div>
    <a class="btn btn-back" href="<?= $self ?>">Back</a>
  <?php else: ?>
    <div class="d-flex align-items-center justify-content-between mb-4">
      <h2 class="title mb-0">CUSTOMER REGISTRATION</h2>
      <div class="text-muted small">
        Booking #<?= (int)$detail['BookingID'] ?> &nbsp;-&nbsp;
        <?= htmlspecialchars($detail['PackageName']) ?> &nbsp;-&nbsp;
        Registered on <?= htmlspecialchars(substr($detail['BookingCreatedAt'],0,10)) ?>
      </div>
    </div>

    <?php if (!$people): ?>
      <div class="alert alert-warning">No travellers recorded for this booking.</div>
    <?php else: ?>
      <div class="row g-4">
        <?php foreach ($people as $i => $p): ?>
          <div class="col-12 col-lg-6">
            <div class="rounded-panel h-100">
              <h5 class="mb-4"># Person <?= $i+1 ?><?= $p['Relationship'] ? " - ".htmlspecialchars($p['Relationship']) : "" ?></h5>

              <div class="mb-3">
                <div class="lbl">Name</div>
                <div class="chip-readonly"><?= htmlspecialchars($p['FullName']) ?></div>
              </div>

              <div class="row">
                <div class="col-md-6 mb-3">
                  <div class="lbl">Gender</div>
                  <div class="chip-readonly"><?= htmlspecialchars($p['Gender'] ?? 'â€”') ?></div>
                </div>
                <div class="col-md-6 mb-3">
                  <div class="lbl">Date of Birth</div>
                  <div class="chip-readonly"><?= htmlspecialchars($p['DateOfBirth'] ?? 'â€”') ?></div>
                </div>
              </div>

              <div class="row">
                <div class="col-md-6 mb-3">
                  <div class="lbl">Passport number</div>
                  <div class="chip-readonly"><?= htmlspecialchars($p['PassportNo'] ?? 'â€”') ?></div>
                </div>
                <div class="col-md-6 mb-3">
                  <div class="lbl">Issue date</div>
                  <div class="chip-readonly"><?= htmlspecialchars($p['PassportIssue'] ?? 'â€”') ?></div>
                </div>
                <div class="col-md-6 mb-3">
                  <div class="lbl">Expiry date</div>
                  <div class="chip-readonly"><?= htmlspecialchars($p['PassportExpiry'] ?? 'â€”') ?></div>
                </div>
              </div>
            </div>
          </div>
        <?php endforeach; ?>
      </div>
    <?php endif; ?>

    <div class="mt-4">
      <a class="btn btn-back" href="<?= $self ?>">Back</a>
    </div>
  <?php endif; ?>
<?php endif; ?>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
<script>
  // Toggle DATE chip to show/hide date inputs in panel without navigating (list view only)
  const chipDate   = document.getElementById('chipDate');
  const dateInputs = document.getElementById('dateInputs');
  const dateHint   = document.getElementById('dateHint');
  const dateFlag   = document.getElementById('dateFlag');

  chipDate?.addEventListener('click', () => {
    const isOn = !dateInputs.classList.contains('d-none');
    if (isOn) {
      dateInputs.classList.add('d-none');
      dateHint.classList.remove('d-none');
      chipDate.classList.add('inactive');
      if (dateFlag) dateFlag.value = '0';
    } else {
      dateInputs.classList.remove('d-none');
      dateHint.classList.add('d-none');
      chipDate.classList.remove('inactive');
      if (dateFlag) dateFlag.value = '1';
    }
  });

  // Report toggle + print helpers
  const reportCard = document.getElementById('bookingReport');
  const toggleReportBtn = document.getElementById('toggleReportBtn');
  const printReportBtn = document.getElementById('printReportBtn');

  toggleReportBtn?.addEventListener('click', () => {
    if (!reportCard) return;
    const isHidden = reportCard.classList.toggle('d-none');
    toggleReportBtn.textContent = isHidden ? 'View Report' : 'Hide Report';
    toggleReportBtn.dataset.expanded = isHidden ? 'false' : 'true';
  });

  printReportBtn?.addEventListener('click', () => {
    if (!reportCard) return;
    const printWindow = window.open('', '', 'width=960,height=700');
    if (!printWindow) return;
    const doc = printWindow.document;
    doc.write(`<!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Booking Report</title>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
          <style>
            body{font-family:'Segoe UI',sans-serif;padding:1.5rem;background:#fff;}
            .report-card{border:2px solid #222;border-radius:28px;padding:1.5rem;background:#fff;margin-bottom:1.5rem;}
            .report-section-title{font-size:1rem;font-weight:800;text-transform:uppercase;margin-bottom:.6rem;}
            .report-list{list-style:none;padding-left:0;}
            .report-list li{padding:.35rem 0;border-bottom:1px solid #eee;font-weight:600;}
            .report-list li:last-child{border-bottom:0;}
            .report-stat{background:#f8f9fb;border:2px solid #222;border-radius:20px;padding:1rem 1.2rem;margin-bottom:1rem;}
            .report-stat .label{font-size:.85rem;font-weight:700;color:#555;text-transform:uppercase;}
            .report-stat .value{font-size:2rem;font-weight:800;color:#111;}
          </style>
        </head>
        <body>
          ${reportCard.outerHTML}
        </body>
      </html>`);
    doc.close();
    printWindow.focus();
    printWindow.print();
  });
</script>
</body>
</html>
