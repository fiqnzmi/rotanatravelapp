<?php
// admin_records.php â€” aggregated totals per package with filters
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'admin')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025',[
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

/* ===== Navbar notifications (demo = pending bookings) ===== */
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
$useMonth = ($_GET['month_on'] ?? '') === '1';  // only used if a year is also on
$year     = $_GET['year'] ?? '';
$month    = $_GET['month'] ?? '';

/* ===== Build WHERE ===== */
$where = [];
$params = [];

if ($q !== '') { $where[] = "p.title LIKE ?"; $params[] = "%$q%"; }
if ($useYear && $year !== '' && ctype_digit($year)) {
  $where[] = "YEAR(b.created_at) = ?";
  $params[] = (int)$year;
  if ($useMonth && $month !== '' && ctype_digit($month) && (int)$month >= 1 && (int)$month <= 12) {
    $where[] = "MONTH(b.created_at) = ?";
    $params[] = (int)$month;
  }
}

$whereSql = $where ? "WHERE ".implode(" AND ", $where) : "";

/* ===== Main aggregation =====
   Count bookings per package, left join to show packages with zero bookings.
*/
$sql = "
  SELECT
    p.id AS PackageID,
    p.title AS PackageName,
    COALESCE(COUNT(b.id), 0) AS Total
  FROM packages p
  LEFT JOIN bookings b ON b.package_id = p.id
  $whereSql
  GROUP BY p.id, p.title
  ".($sortPkg ? "ORDER BY p.title ASC" : "ORDER BY Total DESC, p.title ASC")."
";
$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll();

/* Build self URL helper */
$self = htmlspecialchars(basename($_SERVER['PHP_SELF']));
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin Records</title>
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

    /* Filter panel (dropdown like your Booking page) */
    .dropdown-menu.filter-panel{width:420px;max-width:85vw;border:1px solid #000;border-radius:.5rem;padding:.75rem .85rem;}
    .filter-panel h6{font-weight:800;text-decoration:underline;margin:.2rem 0 .6rem}
    .chip{display:inline-block;background:#222;color:#fff;border-radius:16px;padding:.35rem .8rem;font-weight:700;margin-right:.4rem;cursor:pointer;user-select:none}
    .chip.secondary{background:#5b5bf0}
    .chip.inactive{opacity:.45}

    .search-wrap{max-width:520px}
    .search-input{border-radius:999px;padding:.8rem 1.1rem}

    /* Table framed look */
    .frame{border:4px solid #5a29ff; border-radius:2px; background:#fff}
    .rec-table{margin:0; border-collapse:separate; border-spacing:0}
    .rec-table thead th{border:2px solid #000 !important; text-align:center; vertical-align:middle; font-weight:700;}
    .rec-table td{border:2px solid #000 !important; vertical-align:middle;}

    .btn-back{display:inline-block; background:#1da1ff; color:#fff; border:0; font-weight:800; border-radius:999px; padding:.9rem 2.2rem;}

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
          <li><a class="active" href="admin_records.php"><i class="bi bi-archive"></i>Records</a></li>
          <li><a href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap container-fluid">
  <!-- Header row: title + filter dropdown -->
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h1 class="title">RECORDS</h1>

    <div class="dropdown">
      <button class="btn btn-dark rounded-pill" data-bs-toggle="dropdown" aria-expanded="false">
        <i class="bi bi-sliders me-1"></i> Filter
      </button>
      <div class="dropdown-menu dropdown-menu-end filter-panel shadow-sm">
        <h6>Filter by</h6>
        <?php $isPkg=$sortPkg; $isYear=$useYear; $isMonth=($useYear && $useMonth); ?>
        <div class="mb-2">
          <!-- Package chip toggles alphabetical sort -->
          <a class="chip <?= $isPkg?'':'inactive' ?>"
             href="<?= $self ?>?<?= http_build_query(['q'=>$q,'sort'=>($isPkg?'':"package"),'year_on'=>$isYear?1:0,'month_on'=>$isMonth?1:0,'year'=>$year,'month'=>$month]) ?>">Package</a>
          <!-- Year chip toggles year inputs -->
          <span class="chip secondary <?= $isYear?'':'inactive' ?>" id="chipYear">Year</span>
          <!-- Month chip toggles month input; ignored if year is off -->
          <span class="chip secondary <?= $isMonth?'':'inactive' ?>" id="chipMonth">Month</span>
        </div>

        <form class="row g-2 align-items-end" method="get" action="<?= $self ?>" id="filterForm">
          <!-- preserve search + sort -->
          <input type="hidden" name="q" value="<?= htmlspecialchars($q) ?>">
          <input type="hidden" name="sort" value="<?= $sortPkg ? 'package' : '' ?>">
          <input type="hidden" name="year_on"  id="yearFlag"  value="<?= $useYear?1:0 ?>">
          <input type="hidden" name="month_on" id="monthFlag" value="<?= $useMonth?1:0 ?>">

          <div id="yearRow" class="col-12 <?= $useYear?'':'d-none' ?>">
            <label class="form-label small mb-1">Year</label>
            <input type="number" name="year" class="form-control form-control-sm" min="2000" max="2100" value="<?= htmlspecialchars($year) ?>" placeholder="YYYY">
          </div>

          <div id="monthRow" class="col-12 <?= ($useYear && $useMonth)?'':'d-none' ?>">
            <label class="form-label small mb-1">Month (1â€“12)</label>
            <input type="number" name="month" class="form-control form-control-sm" min="1" max="12" value="<?= htmlspecialchars($month) ?>" placeholder="MM">
          </div>

          <div class="col-12">
            <button class="btn btn-danger w-100"><i class="bi bi-sliders me-1"></i>Filter</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- Search -->
  <form class="search-wrap mb-3" method="get" action="<?= $self ?>">
    <!-- Keep filter state -->
    <input type="hidden" name="sort" value="<?= $sortPkg ? 'package' : '' ?>">
    <input type="hidden" name="year_on" value="<?= $useYear?1:0 ?>">
    <input type="hidden" name="month_on" value="<?= $useMonth?1:0 ?>">
    <input type="hidden" name="year" value="<?= htmlspecialchars($year) ?>">
    <input type="hidden" name="month" value="<?= htmlspecialchars($month) ?>">

    <div class="input-group" style="max-width:520px">
      <input type="text" name="q" value="<?= htmlspecialchars($q) ?>" class="form-control search-input" placeholder="Search package...">
      <button class="btn btn-outline-secondary rounded-end-pill"><i class="bi bi-search"></i></button>
    </div>
  </form>

  <!-- Table -->
  <div class="frame">
    <table class="table rec-table">
      <thead>
        <tr>
          <th>Package</th>
          <th style="width:220px">Total</th>
        </tr>
      </thead>
      <tbody>
        <?php if (!$rows): ?>
          <tr><td colspan="2" class="text-center text-muted py-4">No results found.</td></tr>
        <?php else: ?>
          <?php foreach ($rows as $r): ?>
            <tr>
              <td><?= htmlspecialchars($r['PackageName']) ?></td>
              <td class="text-center"><?= (int)$r['Total'] ?></td>
            </tr>
          <?php endforeach; ?>
        <?php endif; ?>
      </tbody>
    </table>
  </div>

  <div class="text-center my-5">
    <a href="admin.php" class="btn btn-back">Back</a>
  </div>
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
    // Month only makes sense if Year is on
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
</script>
</body>
</html>
