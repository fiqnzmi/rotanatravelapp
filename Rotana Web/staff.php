<?php
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'staff')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025', [
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// Pull latest pending bookings for notifications (customize as needed)
$pending = $pdo->query("
  SELECT b.id, u.name AS CustomerName, p.title AS PackageName, b.created_at
  FROM bookings b
  JOIN users u     ON u.id = b.user_id
  JOIN packages p  ON p.id = b.package_id
  WHERE UPPER(b.status) = 'PENDING'
  ORDER BY b.created_at DESC
  LIMIT 10
")->fetchAll();
$pendingCount = count($pending);
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Staff Dashboard</title>
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

  .page-wrap{padding:2rem 1.25rem}
  .title{font-weight:800;font-size:2rem;margin:0 auto 1.5rem;max-width:1280px}
  .tiles{max-width:1280px;margin:0 auto}
  .tile{background:#86c3f3;border:none;border-radius:24px;height:230px;display:flex;align-items:center;justify-content:center;flex-direction:column;text-align:center;transition:.15s transform ease-in-out;}
  .tile:hover{transform:scale(1.02);cursor:pointer}
  .tile .icon{font-size:90px;margin-bottom:.5rem;color:#0b0b0b}
  .tile .label{font-weight:800;color:#fff;letter-spacing:.3px}
  .logout-wrap{max-width:1280px;margin:2rem auto 0}
  .btn-logout{background:#dc3545;border:0;border-radius:999px;font-weight:800;padding:.65rem 1.25rem}
</style>
</head>
<body>

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
                    $customer = trim($row['CustomerName'] ?? '');
                    $package  = trim($row['PackageName'] ?? '');
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
          <li><a class="active" href="staff.php"><i class="bi bi-speedometer2"></i>Dashboard</a></li>
          <li><a href="staff_booking.php"><i class="bi bi-calendar-check"></i>Bookings</a></li>
          <li><a href="staff_tasks.php"><i class="bi bi-list-task"></i>Tasks</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap">
  <h1 class="title">DASHBOARD</h1>

  <div class="tiles row g-4">
    <div class="col-12 col-lg-6">
      <a class="text-decoration-none" href="staff_booking.php">
        <div class="tile">
          <i class="bi bi-calendar3 icon"></i>
          <div class="label">BOOKING</div>
        </div>
      </a>
    </div>
    <div class="col-12 col-lg-6">
      <a class="text-decoration-none" href="staff_tasks.php">
        <div class="tile">
          <i class="bi bi-plus-circle icon"></i>
          <div class="label">TASKS</div>
        </div>
      </a>
    </div>
  </div>

  <div class="logout-wrap">
    <a href="logout.php" class="btn btn-logout">Log Out</a>
  </div>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
</body>
</html>
