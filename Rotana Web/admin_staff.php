<?php
// admin_staff.php â€” staff list + inline create (Name / Email-as-Username / Password / RoleID)
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'admin')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025',[
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

/* notifications (optional) */
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

/* CSRF */
if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(16));
$csrf = $_SESSION['csrf'];

function onlyDigits($v){ return ctype_digit((string)$v); }

$errors = [];
$flash  = '';

/* CREATE / DELETE */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  if (!hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')) {
    $errors[] = 'Invalid request. Please try again.';
  } else {
    $action = $_POST['action'] ?? '';
    if ($action === 'create') {
      $name     = trim($_POST['name'] ?? '');
      $email    = trim($_POST['username'] ?? ''); // â€œusernameâ€ field -> Email in DB
      $password = $_POST['password'] ?? '';
      $roleID   = (int)($_POST['role_id'] ?? 2);  // 1=Admin, 2=Staff

      if ($name === '') $errors[] = 'Name is required.';
      if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Valid email is required.';
      if ($password === '' || strlen($password) < 6) $errors[] = 'Password must be at least 6 characters.';
      if (!in_array($roleID, [1,2], true)) $errors[] = 'Invalid role.';

      // unique Email
      $st = $pdo->prepare("SELECT COUNT(*) FROM staff WHERE Email=?");
      $st->execute([$email]);
      if ($st->fetchColumn() > 0) $errors[] = 'That email is already in use.';

      if (!$errors) {
        $hash = password_hash($password, PASSWORD_BCRYPT);
        $sql = "INSERT INTO staff (Name, Email, Password, RoleID, CreatedAt) VALUES (?, ?, ?, ?, NOW())";
        $pdo->prepare($sql)->execute([$name, $email, $hash, $roleID]);
        $_SESSION['flash_ok'] = 'Staff account created.';
        header('Location: admin_staff.php'); exit;
      }
    }

    if ($action === 'delete') {
      $id = $_POST['id'] ?? '';
      if (!onlyDigits($id)) {
        $errors[] = 'Invalid staff ID.';
      } else {
        $st = $pdo->prepare("SELECT RoleID FROM staff WHERE StaffID = ? LIMIT 1");
        $st->execute([(int)$id]);
        $roleRow = $st->fetchColumn();
        if ($roleRow === false) {
          $errors[] = 'Staff account not found.';
        } elseif ((int)$roleRow === 1) {
          $errors[] = 'Admin accounts cannot be removed.';
        }
      }

      if (!$errors) {
        $pdo->prepare("DELETE FROM staff WHERE StaffID=?")->execute([(int)$id]);
        $_SESSION['flash_ok'] = 'Staff account removed.';
        header('Location: admin_staff.php'); exit;
      }
    }
  }
}

/* Fetch list (join role for name) */
$list = $pdo->query("
  SELECT s.StaffID, s.Name, s.Email, s.CreatedAt, r.RoleName, s.RoleID
  FROM staff s
  LEFT JOIN role r ON r.RoleID = s.RoleID
  ORDER BY s.CreatedAt ASC, s.StaffID ASC
")->fetchAll();

if (isset($_SESSION['flash_ok'])) { $flash = $_SESSION['flash_ok']; unset($_SESSION['flash_ok']); }
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin - Staff</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
  <style>
    body{background:#f7f8fc;}
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
    .wrap{padding:1.75rem 1.25rem}
    .page-title{font-weight:800;font-size:2.4rem;margin:0 0 1.25rem}
    .staff-table thead th{border:2px solid #000 !important; text-align:center; vertical-align:middle; font-weight:700;}
    .staff-table td{border:2px solid #000 !important; vertical-align:middle;}
    .btn-remove{background:#e31f25; color:#fff; font-weight:800; border:0; border-radius:12px; padding:.5rem 1rem}
    .btn-new{position:fixed; right:28px; bottom:28px; background:#1da1ff; border:0; color:#fff; font-weight:800; border-radius:12px; padding:.55rem 1rem; box-shadow:0 6px 16px rgba(0,0,0,.12);}
    .btn-back{display:inline-block; background:#1da1ff; color:#fff; border:0; font-weight:800; border-radius:999px; padding:.9rem 2.2rem;}
    .form-card{max-width: 620px; margin: 0 auto; background:#fff; border:2px solid #000; border-radius:22px; padding: 2rem 2rem; box-shadow:0 8px 24px rgba(0,0,0,.06);}
    .form-label{font-weight:700}
    .pill.form-control{border-radius:999px; padding:.8rem 1.1rem}
    .role-chip{border-radius:16px; font-weight:800; padding:.35rem .85rem; background:#17a2ff; color:#fff; cursor:pointer; user-select:none}
    .role-chip.inactive{opacity:.5; filter:grayscale(40%);}
    .btn-add{background:#6bd12f;border:0;border-radius:999px;font-weight:800;padding:.8rem 1.6rem}
    .btn-cancel{background:#1da1ff;border:0;border-radius:999px;font-weight:800;padding:.75rem 1.6rem}
    .muted{opacity:.7}

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
          <li><a class="active" href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="wrap container-fluid">
  <h1 class="page-title">STAFF</h1>

  <?php if ($flash): ?><div class="alert alert-success"><?= htmlspecialchars($flash) ?></div><?php endif; ?>
  <?php if ($errors): ?><div class="alert alert-danger"><ul class="mb-0"><?php foreach ($errors as $e): ?><li><?= htmlspecialchars($e) ?></li><?php endforeach; ?></ul></div><?php endif; ?>

  <!-- LIST -->
  <section id="listWrap" class="<?= ($_POST['action'] ?? '')==='create' && $errors ? 'd-none' : '' ?>">
    <div class="table-responsive">
      <table class="table staff-table bg-white">
        <thead>
          <tr>
            <th style="width:90px">No.</th>
            <th>Name</th>
            <th style="width:220px">Registered From</th>
            <th style="width:260px">Action</th>
          </tr>
        </thead>
        <tbody>
          <?php if (!$list): ?>
            <tr><td colspan="4" class="text-center text-muted py-4">No staff yet.</td></tr>
          <?php else: $i=1; foreach ($list as $u): ?>
            <tr>
              <td class="text-center"><?= $i++ ?></td>
              <td>
                <?= htmlspecialchars($u['Name']) ?>
                <span class="muted small">(<?= strtoupper($u['RoleName'] ?? ($u['RoleID']==1?'ADMIN':'STAFF')) ?> Â· <?= htmlspecialchars($u['Email']) ?>)</span>
              </td>
              <td class="text-center"><?= htmlspecialchars(substr($u['CreatedAt'],0,10)) ?></td>
              <td class="text-center">
                <?php if ((int)$u['RoleID'] === 1): ?>
                  <span class="text-muted fw-bold">Protected</span>
                <?php else: ?>
                  <form method="post" action="admin_staff.php" class="d-inline" onsubmit="return confirm('Remove this account?');">
                    <input type="hidden" name="csrf" value="<?= $csrf ?>">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="<?= (int)$u['StaffID'] ?>">
                    <button class="btn btn-remove">REMOVE</button>
                  </form>
                <?php endif; ?>
              </td>
            </tr>
          <?php endforeach; endif; ?>
        </tbody>
      </table>
    </div>

    <button type="button" class="btn btn-new" id="btnNew">NEW STAFF</button>

    <div class="text-center my-5">
      <a href="admin.php" class="btn-back">Back</a>
    </div>
  </section>

  <!-- NEW STAFF FORM -->
  <section id="newFormWrap" class="<?= ($_POST['action'] ?? '')==='create' && $errors ? '' : 'd-none' ?>">
    <div class="form-card">
      <form method="post" action="admin_staff.php" novalidate>
        <input type="hidden" name="csrf" value="<?= $csrf ?>">
        <input type="hidden" name="action" value="create">
        <input type="hidden" name="role_id" id="roleField" value="<?= htmlspecialchars($_POST['role_id'] ?? '2') ?>">

        <div class="mb-3 row align-items-center">
          <label class="col-sm-4 col-form-label form-label">Name</label>
          <div class="col-sm-8">
            <input type="text" name="name" class="form-control pill" placeholder="Full name" value="<?= htmlspecialchars($_POST['name'] ?? '') ?>" required>
          </div>
        </div>

        <div class="mb-3 row align-items-center">
          <label class="col-sm-4 col-form-label form-label">Username (Email)</label>
          <div class="col-sm-8">
            <input type="email" name="username" class="form-control pill" placeholder="name@example.com" value="<?= htmlspecialchars($_POST['username'] ?? '') ?>" required>
          </div>
        </div>

        <div class="mb-4 row align-items-center">
          <label class="col-sm-4 col-form-label form-label">Password</label>
          <div class="col-sm-8">
            <input type="password" name="password" class="form-control pill" placeholder="min 6 characters" required>
          </div>
        </div>


        <div class="text-center">
          <button class="btn btn-add" type="submit">Add</button>
        </div>
      </form>
    </div>

    <div class="text-center mt-4">
      <button class="btn btn-cancel" type="button" id="btnCancel">Back</button>
    </div>
  </section>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
<script>
  // Toggle list/new
  const listWrap  = document.getElementById('listWrap');
  const formWrap  = document.getElementById('newFormWrap');
  const btnNew    = document.getElementById('btnNew');
  const btnCancel = document.getElementById('btnCancel');

  btnNew?.addEventListener('click', () => {
    listWrap.classList.add('d-none');
    formWrap.classList.remove('d-none');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  btnCancel?.addEventListener('click', () => {
    formWrap.classList.add('d-none');
    listWrap.classList.remove('d-none');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  // Role chips (map to RoleID: 2=Staff, 1=Admin)
  const roleField = document.getElementById('roleField');
  document.querySelectorAll('.role-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('.role-chip').forEach(c => c.classList.add('inactive'));
      chip.classList.remove('inactive');
      roleField.value = chip.dataset.role;
    });
  });
</script>
</body>
</html>
