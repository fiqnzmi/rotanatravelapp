<?php
session_start();

/* Laragon DB (uses your sabrisae_rotanatravel schema) */
$dsn  = 'mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4';
$user = 'sabrisae_rotanatravel';
$pass = 'Rotanatravel_2025';
$pdo = new PDO($dsn, $user, $pass, [
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
  PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
]);

$error = $_SESSION['flash_error'] ?? '';
unset($_SESSION['flash_error']);

/* Handle login POST */
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $email = trim($_POST['username'] ?? '');      // weâ€™ll treat â€œusernameâ€ as Email in your schema
  $password = $_POST['password'] ?? '';

  if ($email === '' || $password === '') {
    $_SESSION['flash_error'] = 'Email and password are required.';
    header('Location: index.php'); exit;
  }

  // staff + role join (schema: staff.Email, staff.Password, staff.RoleID -> role.RoleName)
  $stmt = $pdo->prepare("
    SELECT s.StaffID, s.Name, s.Email, s.Password, r.RoleName
    FROM staff s
    LEFT JOIN role r ON r.RoleID = s.RoleID
    WHERE s.Email = ?
    LIMIT 1
  ");
  $stmt->execute([$email]);
  $user = $stmt->fetch();

  if ($user && password_verify($password, $user['Password'])) {
    $_SESSION['user_id']  = $user['StaffID'];
    $_SESSION['username'] = $user['Name'];
    $_SESSION['email']    = $user['Email'];
    $_SESSION['role']     = $user['RoleName'] ?: 'Staff';

    if (strcasecmp($_SESSION['role'], 'Admin') === 0) {
      header('Location: admin.php'); exit;
    } else {
      header('Location: staff.php'); exit;
    }
  } else {
    $_SESSION['flash_error'] = 'Invalid credentials.';
    header('Location: index.php'); exit;
  }
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Login Rotana</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet" />
  <style>
    body { min-height: 100vh; background:#f7f8fc; display:grid; place-items:center; }
    .login-card { max-width:640px; width:92%; border:2px solid #000; border-radius:22px;
                  background:#fff; box-shadow:0 8px 24px rgba(0,0,0,.06); padding:1.5rem 2rem; }
    .brand { width:300px; height:auto; margin-bottom:.75rem; }
    .pill-input.form-control { border-radius:999px; background:#a6a6a6; color:#111; border:none; padding:.9rem 1.25rem; }
    .pill-input::placeholder { color:#2b2b2b; opacity:.6; }
    .btn-login { border-radius:999px; padding:.6rem 1.25rem; font-weight:700; background:#6bd12f; border:0; }
    .btn-login:focus { box-shadow:0 0 0 .25rem rgba(78,196,23,.35); }
  </style>
</head>
<body>
  <main class="login-card">
    <div class="text-center">
      <a id="logoLink"><img id="brandLogo" class="brand" src="img/logo.png" alt="Company Logo" /></a>
    </div>

    <?php if (!empty($error)): ?>
      <div class="alert alert-danger small py-2 mb-3" role="alert"><?= htmlspecialchars($error) ?></div>
    <?php endif; ?>

    <!-- NOTE: â€œusernameâ€ is actually Email per your schema -->
    <form class="needs-validation" method="post" action="index.php" novalidate>
      <div class="mb-3">
        <label for="username" class="form-label fw-semibold">Email</label>
        <input type="email" name="username" id="username" class="form-control form-control-lg pill-input"
               placeholder="Enter email" required />
        <div class="invalid-feedback">Please enter your email.</div>
      </div>

      <div class="mb-4">
        <label for="password" class="form-label fw-semibold">Password</label>
        <div class="input-group">
          <input type="password" name="password" id="password" class="form-control form-control-lg pill-input"
                 placeholder="Enter password" required minlength="6" />
          <button type="button" class="btn btn-outline-secondary rounded-pill ms-2" id="togglePassword">Show</button>
        </div>
        <div class="invalid-feedback">Please enter your password (min 6 characters).</div>
      </div>

      <div class="d-flex justify-content-end">
        <button type="submit" class="btn btn-login">LOG IN</button>
      </div>
    </form>
  </main>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
  <script>
    (function(){
      const pwd = document.getElementById('password');
      const toggle = document.getElementById('togglePassword');
      toggle?.addEventListener('click', () => {
        const reveal = pwd.type === 'password';
        pwd.type = reveal ? 'text' : 'password';
        toggle.textContent = reveal ? 'Hide' : 'Show';
      });
    })();
  </script>
</body>
</html>
