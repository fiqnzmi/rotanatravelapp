<?php
require_once __DIR__ . '/_bootstrap.php';

try {
  $data = read_json_body();

  $username = trim($data['username'] ?? '');
  $email    = trim($data['email'] ?? '');
  $password = (string)($data['password'] ?? '');
  $name     = trim($data['name'] ?? $data['full_name'] ?? $username);
  if ($name === '') {
    $name = $username;
  }

  if ($username === '' || $email === '' || $password === '') {
    json_out(['success' => false, 'error' => 'All fields are required'], 422);
  }
  if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    json_out(['success' => false, 'error' => 'Invalid email'], 422);
  }

  $pdo = db();

  // Duplicate check
  $dup = $pdo->prepare('SELECT id FROM users WHERE email = :e OR username = :u LIMIT 1');
  $dup->execute([':e' => $email, ':u' => $username]);
  if ($dup->fetch()) {
    json_out(['success' => false, 'error' => 'User already exists'], 409);
  }

  // Insert
  $hash = password_hash($password, PASSWORD_BCRYPT);
  $ins = $pdo->prepare(
    'INSERT INTO users (username, name, email, password_hash, created_at)
     VALUES (:u, :n, :e, :p, NOW())'
  );
  $ins->execute([':u' => $username, ':n' => $name, ':e' => $email, ':p' => $hash]);

  $userId = (int)$pdo->lastInsertId();

  json_out([
    'success' => true,
    'data' => [
      'user' => [
        'id'       => $userId,
        'username' => $username,
        'name'     => $name,
        'email'    => $email,
        'phone'    => null,
        'gender'   => null,
        'dob'      => null,
        'passport_no' => null,
        'address'  => null,
        'notify_email' => 1,
        'notify_sms' => 0,
        'preferred_language' => null,
        'language' => null,
        'emergency_contact_id' => null,
        'profile_photo' => null,
        'profile_photo_url' => null,
        'photo' => null,
        'photo_url' => null,
      ],
    ],
    'error' => null,
  ]);
} catch (Throwable $e) {
  // Never echo errors; log them
  error_log('register.php: '.$e->getMessage());
  json_out(['success' => false, 'error' => 'Server error'], 500);
}
