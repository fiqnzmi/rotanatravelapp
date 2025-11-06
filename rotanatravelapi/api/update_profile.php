<?php
require_once 'db.php';
require_once 'helpers.php';

$data = body();
if (empty($data)) {
  $data = $_POST;
}

$userId = isset($data['user_id']) ? (int)$data['user_id'] : 0;
if ($userId <= 0) {
  fail('Missing or invalid user_id');
}

$pdo = db();

$hasGender = db_column_exists($pdo, 'users', 'gender');
$hasDob = db_column_exists($pdo, 'users', 'dob');
$hasPassport = db_column_exists($pdo, 'users', 'passport_no');
$hasAddress = db_column_exists($pdo, 'users', 'address');
$hasProfilePhotoUrl = db_column_exists($pdo, 'users', 'profile_photo_url');

$selectColumns = [
  'id',
  'username',
  'name',
  'email',
  'phone',
  'notify_email',
  'notify_sms',
  'preferred_language',
  'emergency_contact_id',
  'profile_photo',
];

if ($hasGender) $selectColumns[] = 'gender';
if ($hasDob) $selectColumns[] = 'dob';
if ($hasPassport) $selectColumns[] = 'passport_no';
if ($hasAddress) $selectColumns[] = 'address';
if ($hasProfilePhotoUrl) $selectColumns[] = 'profile_photo_url';

$stmt = $pdo->prepare('SELECT ' . implode(', ', $selectColumns) . ' FROM users WHERE id = ? LIMIT 1');
$stmt->execute([$userId]);
$existing = $stmt->fetch();
if (!$existing) {
  fail('User not found', 404);
}

function bool_to_flag($value, $default) {
  if ($value === null) {
    return $default ? 1 : 0;
  }
  if (is_bool($value)) {
    return $value ? 1 : 0;
  }
  if (is_numeric($value)) {
    return ((int)$value) !== 0 ? 1 : 0;
  }
  $str = strtolower(trim((string)$value));
  if ($str === '') {
    return $default ? 1 : 0;
  }
  $truthy = ['1','true','yes','y','on'];
  $falsy = ['0','false','no','n','off'];
  if (in_array($str, $truthy, true)) return 1;
  if (in_array($str, $falsy, true)) return 0;
  return $default ? 1 : 0;
}

$updates = [];
$params = [':id' => $userId];
$emergencyContact = null;

if (array_key_exists('name', $data)) {
  $name = trim((string)$data['name']);
  if ($name === '') {
    fail('Name is required');
  }
  $updates[] = 'name = :name';
  $params[':name'] = $name;
}

if (array_key_exists('username', $data)) {
  $username = trim((string)$data['username']);
  if ($username === '') {
    fail('Username cannot be empty');
  }
  $dup = $pdo->prepare('SELECT id FROM users WHERE username = ? AND id <> ? LIMIT 1');
  $dup->execute([$username, $userId]);
  if ($dup->fetch()) {
    fail('Username already taken', 409);
  }
  $updates[] = 'username = :username';
  $params[':username'] = $username;
}

if (array_key_exists('email', $data)) {
  $email = trim((string)$data['email']);
  if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fail('Invalid email address');
  }
  $dup = $pdo->prepare('SELECT id FROM users WHERE email = ? AND id <> ? LIMIT 1');
  $dup->execute([$email, $userId]);
  if ($dup->fetch()) {
    fail('Email already in use', 409);
  }
  $updates[] = 'email = :email';
  $params[':email'] = $email;
}

if (array_key_exists('phone', $data)) {
  $phoneRaw = trim((string)$data['phone']);
  $updates[] = 'phone = :phone';
  $params[':phone'] = $phoneRaw === '' ? null : $phoneRaw;
}

if ($hasGender && array_key_exists('gender', $data)) {
  $genderValue = $data['gender'];
  $gender = normalize_gender_value($genderValue);
  if ($gender === null) {
    $text = trim((string)$genderValue);
    if ($text !== '') {
      fail('Invalid gender value');
    }
  }
  $updates[] = 'gender = :gender';
  $params[':gender'] = $gender;
}

$dobInput = null;
if ($hasDob && array_key_exists('dob', $data)) {
  $dobInput = $data['dob'];
} elseif ($hasDob && array_key_exists('date_of_birth', $data)) {
  $dobInput = $data['date_of_birth'];
}
if ($dobInput !== null) {
  $dobNormalized = normalize_date_value($dobInput);
  if ($dobNormalized === null) {
    $text = trim((string)$dobInput);
    if ($text !== '') {
      fail('Invalid date of birth');
    }
  }
  $updates[] = 'dob = :dob';
  $params[':dob'] = $dobNormalized;
}

if ($hasPassport && (array_key_exists('passport_no', $data) || array_key_exists('passport', $data))) {
  $passportRaw = $data['passport_no'] ?? $data['passport'];
  $passport = trim((string)$passportRaw);
  $updates[] = 'passport_no = :passport_no';
  $params[':passport_no'] = $passport === '' ? null : $passport;
}

if ($hasAddress && array_key_exists('address', $data)) {
  $address = trim((string)$data['address']);
  $updates[] = 'address = :address';
  $params[':address'] = $address === '' ? null : $address;
}

if (array_key_exists('notify_email', $data)) {
  $flag = bool_to_flag($data['notify_email'], (int)$existing['notify_email'] === 1);
  $updates[] = 'notify_email = :notify_email';
  $params[':notify_email'] = $flag;
}

if (array_key_exists('notify_sms', $data)) {
  $flag = bool_to_flag($data['notify_sms'], (int)$existing['notify_sms'] === 1);
  $updates[] = 'notify_sms = :notify_sms';
  $params[':notify_sms'] = $flag;
}

$languageValue = null;
if (array_key_exists('language', $data)) {
  $languageValue = $data['language'];
} elseif (array_key_exists('preferred_language', $data)) {
  $languageValue = $data['preferred_language'];
}
if ($languageValue !== null) {
  $lang = strtolower(trim((string)$languageValue));
  if ($lang === '') {
    $lang = null;
  } else {
    $lang = substr($lang, 0, 10);
  }
  $updates[] = 'preferred_language = :preferred_language';
  $params[':preferred_language'] = $lang;
}

if (array_key_exists('emergency_contact_id', $data)) {
  $contactId = (int)$data['emergency_contact_id'];
  if ($contactId > 0) {
    $check = $pdo->prepare('SELECT id, full_name, relationship, phone FROM family_members WHERE id = ? AND user_id = ? LIMIT 1');
    $check->execute([$contactId, $userId]);
    $contact = $check->fetch();
    if (!$contact) {
      fail('Invalid emergency contact');
    }
    $emergencyContact = $contact;
    $updates[] = 'emergency_contact_id = :emergency_contact_id';
    $params[':emergency_contact_id'] = $contactId;
  } else {
    $emergencyContact = null;
    $updates[] = 'emergency_contact_id = :emergency_contact_id';
    $params[':emergency_contact_id'] = null;
  }
}

if ($updates) {
  $sql = 'UPDATE users SET ' . implode(', ', $updates) . ' WHERE id = :id';
  $updateStmt = $pdo->prepare($sql);
  foreach ($params as $key => $value) {
    if ($value === null) {
      $updateStmt->bindValue($key, null, PDO::PARAM_NULL);
    } elseif (is_int($value)) {
      $updateStmt->bindValue($key, $value, PDO::PARAM_INT);
    } elseif (is_bool($value)) {
      $updateStmt->bindValue($key, $value ? 1 : 0, PDO::PARAM_INT);
    } else {
      $updateStmt->bindValue($key, (string)$value, PDO::PARAM_STR);
    }
  }
  $updateStmt->execute();
}

$stmt->execute([$userId]);
$updated = $stmt->fetch();
if (!$updated) {
  fail('User not found after update', 500);
}

$photoUrl = $updated['profile_photo_url'] ?? null;
if (!$photoUrl && !empty($updated['profile_photo'])) {
  $photoUrl = $updated['profile_photo'];
}
$updated['photo'] = $photoUrl;
$updated['photo_url'] = $photoUrl;
$updated['notify_email'] = isset($updated['notify_email']) ? (int)$updated['notify_email'] : 1;
$updated['notify_sms'] = isset($updated['notify_sms']) ? (int)$updated['notify_sms'] : 0;
$updated['language'] = $updated['preferred_language'] ?? null;
$updated['gender'] = $updated['gender'] ?? null;
$updated['passport_no'] = $updated['passport_no'] ?? null;
$updated['address'] = $updated['address'] ?? null;
if (!empty($updated['dob'])) {
  $updated['dob'] = date('Y-m-d', strtotime($updated['dob']));
} else {
  $updated['dob'] = null;
}

if ($emergencyContact === null && !empty($updated['emergency_contact_id'])) {
  $check = $pdo->prepare('SELECT id, full_name, relationship, phone FROM family_members WHERE id = ? AND user_id = ? LIMIT 1');
  $check->execute([(int)$updated['emergency_contact_id'], $userId]);
  $emergencyContact = $check->fetch() ?: null;
}

ok([
  'user' => $updated,
  'emergency_contact' => $emergencyContact,
]);
