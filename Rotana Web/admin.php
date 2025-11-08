<?php
// admin.php - Admin dashboard
session_start();
if (!isset($_SESSION['user_id']) || (strtolower($_SESSION['role'] ?? '') !== 'admin')) {
  header('Location: index.php'); exit;
}

$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025',[
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
]);

// Simple unread count demo: pending bookings (bookings.status stored uppercase in dump)
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
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Admin Dashboard</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">
  <style>
    body{background:#f7f8fc;}
    /* NAVBAR */
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
    .notif-dropdown{border:1px solid #000;border-radius:.6rem;}

    /* QUICK LINKS BAR now inside red header */
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

    @media (max-width:576px){
      .quicklinks-bar{max-height:none;opacity:1;transform:none;pointer-events:auto;}
      .quicklinks-bar .inner{flex-direction:column;align-items:flex-start;}
      .header-top{flex-direction:column;align-items:flex-start;gap:.75rem;}
      .navbar .container-fluid{padding:0 1rem;}
    }

    /* PAGE */
    .page-wrap{padding:2rem 1.25rem}
    .title{font-weight:800;font-size:2rem;margin-bottom:2rem}

    /* MAIN BUTTON TILES (red) */
    .tiles{max-width:1280px;margin:0 auto}
    .tile{
      background:#e31f25;color:#fff;border:none;border-radius:26px;
      height:230px;display:flex;align-items:center;justify-content:center;
      flex-direction:column;text-align:center;transition:.12s transform ease-in-out;
      box-shadow:0 6px 18px rgba(0,0,0,.06);
    }
    .tile:hover{transform:scale(1.02);cursor:pointer}
    .tile .icon{font-size:90px;margin-bottom:.6rem}
    .tile .label{font-weight:800;letter-spacing:.3px}

    /* Profile customization lab (prototype) */
    .profile-lab{max-width:1280px;margin:3rem auto 0}
    .profile-lab-title{font-weight:800;font-size:1.6rem;margin-bottom:.2rem;}
    .profile-cards{display:grid;gap:1.5rem}
    @media(min-width:768px){
      .profile-cards{grid-template-columns:repeat(2,minmax(0,1fr));}
    }
    .profile-card{
      background:#fff;border:2px solid #e5e5f5;border-radius:24px;
      padding:1.5rem;box-shadow:0 12px 24px rgba(0,0,0,.04);height:100%;
      display:flex;flex-direction:column;gap:1.25rem;
    }
    .profile-card-header{
      font-weight:800;letter-spacing:.05em;text-transform:uppercase;font-size:.9rem;
      color:#6c63ff;
    }
    .profile-card form .form-label{font-weight:700;font-size:.8rem;text-transform:uppercase;color:#555;}
    .profile-card small{text-transform:none;font-weight:400;}

    .profile-preview{
      --accent:#5a29ff;
      border:2px dashed var(--accent);
      border-radius:22px;
      padding:1rem 1.25rem;
      display:flex;
      gap:.9rem;
      align-items:center;
      background:rgba(90,41,255,.05);
      transition:.2s ease;
    }
    .profile-preview-avatar{
      width:72px;height:72px;border-radius:18px;
      background:var(--accent);color:#fff;font-weight:800;font-size:1.5rem;
      display:flex;align-items:center;justify-content:center;
    }
    .profile-preview-name{font-weight:800;font-size:1.2rem;line-height:1.1;}
    .profile-preview-role{font-weight:700;font-size:.85rem;color:#555;text-transform:uppercase;margin-bottom:.2rem;}
    .profile-preview-bio{font-size:.9rem;color:#333;}
    .profile-badges{display:flex;flex-wrap:wrap;gap:.4rem;margin-top:.4rem;}
    .profile-badge{
      background:var(--accent);color:#fff;border-radius:999px;
      padding:.15rem .75rem;font-size:.75rem;font-weight:600;
    }
    .coming-soon-btn{pointer-events:none;opacity:.7;}

    /* Logout */
    .logout-wrap{max-width:1280px;margin:2.25rem auto 0}
    .btn-logout{background:#e31f25;border:0;border-radius:999px;font-weight:800;padding:.7rem 1.4rem}
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
          <li><a class="active" href="admin.php"><i class="bi bi-speedometer2"></i>Dashboard</a></li>
          <li><a href="admin_booking.php"><i class="bi bi-calendar-check"></i>Bookings</a></li>
          <li><a href="admin_package.php"><i class="bi bi-boxes"></i>Packages</a></li>
          <li><a href="admin_records.php"><i class="bi bi-archive"></i>Records</a></li>
          <li><a href="admin_staff.php"><i class="bi bi-people"></i>Staff</a></li>
          <li><a href="admin_transaction.php"><i class="bi bi-currency-dollar"></i>Transactions</a></li>
        </ul>
      </div>
    </div>

  </div>
</nav>

<main class="page-wrap">
  <h1 class="title">DASHBOARD</h1>

  <div class="tiles row g-4">
    <div class="col-12 col-md-6 col-xl-4">
      <a class="text-decoration-none text-white" href="admin_booking.php">
        <div class="tile">
          <i class="bi bi-calendar2-check icon"></i>
          <div class="label">BOOKING</div>
        </div>
      </a>
    </div>

    <div class="col-12 col-md-6 col-xl-4">
      <a class="text-decoration-none text-white" href="admin_package.php">
        <div class="tile">
          <i class="bi bi-box-seam icon"></i>
          <div class="label">PACKAGE</div>
        </div>
      </a>
    </div>

    <div class="col-12 col-md-6 col-xl-4">
      <a class="text-decoration-none text-white" href="admin_records.php">
        <div class="tile">
          <i class="bi bi-folder2-open icon"></i>
          <div class="label">RECORDS</div>
        </div>
      </a>
    </div>

    <div class="col-12 col-md-6 col-xl-4">
      <a class="text-decoration-none text-white" href="admin_staff.php">
        <div class="tile">
          <i class="bi bi-people-fill icon"></i>
          <div class="label">STAFF</div>
        </div>
      </a>
    </div>

    <div class="col-12 col-md-6 col-xl-4">
      <a class="text-decoration-none text-white" href="admin_transaction.php">
        <div class="tile">
          <i class="bi bi-currency-exchange icon"></i>
          <div class="label">TRANSACTION</div>
        </div>
      </a>
    </div>
  </div>

  <section class="profile-lab">
    <div class="d-flex flex-wrap justify-content-between align-items-start gap-3 mb-3">
      <div>
        <h2 class="profile-lab-title">Profile Customization Lab</h2>
        <p class="text-muted mb-0">Sketch out how each admin or staff member could personalize their profile for future releases.</p>
      </div>
      <span class="badge text-dark bg-warning-subtle border border-warning-subtle fw-semibold">Prototype • Visual only</span>
    </div>

    <div class="profile-cards">
      <div class="profile-card">
        <div>
          <div class="profile-card-header">Admin identity</div>
          <p class="small mb-0 text-muted">Tweak colours, avatars, and bios. Saving is disabled until the feature ships.</p>
        </div>
        <form class="profile-form" data-profile-form data-preview-target="adminProfilePreview">
          <div class="mb-3">
            <label class="form-label small mb-1">Display name</label>
            <input type="text" class="form-control form-control-sm" name="display" placeholder="Captain Rotana" value="<?= htmlspecialchars($_SESSION['username'] ?? 'Admin') ?>">
          </div>
          <div class="row g-2">
            <div class="col-6">
              <label class="form-label small mb-1">Accent colour</label>
              <input type="color" class="form-control form-control-color" name="accent" value="#5a29ff" title="Choose accent colour">
            </div>
            <div class="col-6">
              <label class="form-label small mb-1">Avatar shape</label>
              <select class="form-select form-select-sm" name="avatar">
                <option value="rounded">Rounded Square</option>
                <option value="circle">Circle</option>
                <option value="squircle">Squircle</option>
              </select>
            </div>
          </div>
          <div class="mb-3">
            <label class="form-label small mb-1">Tagline / bio</label>
            <textarea class="form-control form-control-sm" name="bio" rows="3" placeholder="e.g. Guardians of premium travel itineraries."></textarea>
          </div>
          <button type="button" class="btn btn-outline-secondary w-100 coming-soon-btn">Save preferences (coming soon)</button>
        </form>

        <div class="profile-preview" id="adminProfilePreview">
          <div class="profile-preview-avatar" data-preview-avatar>AR</div>
          <div>
            <div class="profile-preview-name" data-preview-name><?= htmlspecialchars($_SESSION['username'] ?? 'Admin') ?></div>
            <div class="profile-preview-role">Administrator</div>
            <div class="profile-preview-bio" data-preview-bio>Lead curator of bespoke adventures.</div>
            <div class="profile-badges">
              <span class="profile-badge" data-preview-accent>Ops Hero</span>
              <span class="profile-badge" data-preview-accent>Trusted</span>
            </div>
          </div>
        </div>
      </div>

      <div class="profile-card">
        <div>
          <div class="profile-card-header">Staff spotlight</div>
          <p class="small mb-0 text-muted">Preview how team members might pick department stickers or highlight expertise.</p>
        </div>
        <form class="profile-form" data-profile-form data-preview-target="staffProfilePreview">
          <div class="mb-3">
            <label class="form-label small mb-1">Staff member</label>
            <input type="text" class="form-control form-control-sm" name="display" placeholder="e.g. Afiq Rahman">
          </div>
          <div class="row g-2">
            <div class="col-6">
              <label class="form-label small mb-1">Role label</label>
              <input type="text" class="form-control form-control-sm" name="role" placeholder="Travel Consultant">
            </div>
            <div class="col-6">
              <label class="form-label small mb-1">Theme colour</label>
              <input type="color" class="form-control form-control-color" name="accent" value="#1da1ff">
            </div>
          </div>
          <div class="mb-3">
            <label class="form-label small mb-1">Expertise tags</label>
            <input type="text" class="form-control form-control-sm" name="tags" placeholder="Luxury, Europe, Family Trips">
            <small class="text-muted">Comma separated. Preview chips update instantly.</small>
          </div>
          <button type="button" class="btn btn-outline-secondary w-100 coming-soon-btn">Share spotlight (coming soon)</button>
        </form>

        <div class="profile-preview" id="staffProfilePreview" style="--accent:#1da1ff;">
          <div class="profile-preview-avatar" data-preview-avatar>SR</div>
          <div>
            <div class="profile-preview-name" data-preview-name>Staff Member</div>
            <div class="profile-preview-role" data-preview-role>Travel Specialist</div>
            <div class="profile-preview-bio" data-preview-bio>Passionate about making every itinerary feel handcrafted.</div>
            <div class="profile-badges" data-preview-tags>
              <span class="profile-badge" data-preview-accent>Luxury</span>
              <span class="profile-badge" data-preview-accent>Europe</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>

  <div class="logout-wrap">
    <a href="logout.php" class="btn btn-logout">Log Out</a>
  </div>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="notifications.js"></script>
<script>
  (() => {
    const forms = document.querySelectorAll('[data-profile-form]');
    const getInitials = (value) => {
      if (!value) return 'AA';
      const letters = value.trim().split(/\s+/).map(word => word.charAt(0)).join('');
      return letters.substring(0, 2).toUpperCase();
    };

    forms.forEach(form => {
      const previewId = form.getAttribute('data-preview-target');
      const preview = document.getElementById(previewId);
      if (!preview) return;

      const nameEl = preview.querySelector('[data-preview-name]');
      const avatarEl = preview.querySelector('[data-preview-avatar]');
      const bioEl = preview.querySelector('[data-preview-bio]');
      const roleEl = preview.querySelector('[data-preview-role]');
      const badgesWrap = preview.querySelector('[data-preview-tags]');

      [nameEl, avatarEl, bioEl, roleEl].forEach(el => {
        if (el && !el.dataset.fallback) {
          el.dataset.fallback = el.textContent.trim();
        }
      });

      const apply = () => {
        const display = form.querySelector('[name="display"]')?.value.trim();
        const bio = form.querySelector('[name="bio"]')?.value.trim();
        const role = form.querySelector('[name="role"]')?.value.trim();
        const accent = form.querySelector('[name="accent"]')?.value || preview.style.getPropertyValue('--accent') || '#5a29ff';
        const avatarShape = form.querySelector('[name="avatar"]')?.value;
        const tagsValue = form.querySelector('[name="tags"]')?.value;

        if (nameEl) {
          nameEl.textContent = display || nameEl.dataset.fallback || 'Your Name';
        }

        if (avatarEl) {
          avatarEl.textContent = getInitials(display || nameEl?.dataset.fallback || avatarEl.textContent);
          if (avatarShape === 'circle') {
            avatarEl.style.borderRadius = '999px';
          } else if (avatarShape === 'squircle') {
            avatarEl.style.borderRadius = '32%';
          } else {
            avatarEl.style.borderRadius = '18px';
          }
        }

        if (bioEl) {
          bioEl.textContent = bio || bioEl.dataset.fallback || 'Tell travelers what you care about most.';
        }

        if (roleEl && role !== undefined) {
          roleEl.textContent = role || roleEl.dataset.fallback || 'Team Member';
        }

        preview.style.setProperty('--accent', accent);
        preview.querySelectorAll('[data-preview-accent]').forEach(el => {
          el.style.background = accent;
        });
        if (avatarEl) {
          avatarEl.style.background = accent;
        }

        if (badgesWrap && tagsValue !== undefined) {
          badgesWrap.innerHTML = '';
          const tags = tagsValue
            ? tagsValue.split(',').map(tag => tag.trim()).filter(Boolean)
            : (badgesWrap.dataset.fallback ? badgesWrap.dataset.fallback.split('|') : []);
          if (!badgesWrap.dataset.fallback) {
            const defaults = Array.from(badgesWrap.querySelectorAll('.profile-badge')).map(el => el.textContent.trim());
            badgesWrap.dataset.fallback = defaults.join('|');
          }
          if (tags.length === 0 && badgesWrap.dataset.fallback) {
            tags.push(...badgesWrap.dataset.fallback.split('|').filter(Boolean));
          }
          tags.forEach(tag => {
            const chip = document.createElement('span');
            chip.className = 'profile-badge';
            chip.textContent = tag;
            chip.style.background = accent;
            badgesWrap.appendChild(chip);
          });
        }
      };

      form.addEventListener('input', apply);
      apply();
    });
  })();
</script>
</body>
</html>
