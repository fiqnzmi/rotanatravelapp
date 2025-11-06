<?php
require_once 'db.php'; require_once 'helpers.php';
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId<=0) {
  // fallback demo user
  $userId = 1;
}
$pdo = db();
$user = $pdo->prepare("SELECT id, username, name, email, phone, gender, dob, passport_no, address, notify_email, notify_sms, preferred_language, emergency_contact_id, profile_photo, profile_photo_url FROM users WHERE id=?");
$user->execute([$userId]); $u = $user->fetch();

if ($u) {
  $photoUrl = $u['profile_photo_url'] ?? null;
  if (!$photoUrl && !empty($u['profile_photo'])) {
    $photoUrl = $u['profile_photo'];
  }
  $u['photo'] = $photoUrl;
  $u['photo_url'] = $photoUrl;
  $u['notify_email'] = isset($u['notify_email']) ? (int)$u['notify_email'] : 1;
  $u['notify_sms'] = isset($u['notify_sms']) ? (int)$u['notify_sms'] : 0;
  $u['language'] = $u['preferred_language'] ?: null;
  if (!isset($u['phone'])) {
    $u['phone'] = null;
  }
  $u['gender'] = $u['gender'] ?? null;
  $u['passport_no'] = $u['passport_no'] ?? null;
  $u['address'] = $u['address'] ?? null;
  if (!empty($u['dob'])) {
    $u['dob'] = date('Y-m-d', strtotime($u['dob']));
  } else {
    $u['dob'] = null;
  }
}

$counts = [
  'completed' => (int)$pdo->query("SELECT COUNT(*) c FROM bookings WHERE user_id=$userId AND status='COMPLETED'")->fetch()['c'],
  'upcoming'  => (int)$pdo->query("SELECT COUNT(*) c FROM bookings WHERE user_id=$userId AND status='CONFIRMED'")->fetch()['c'],
  'family_members' => (int)$pdo->query("SELECT COUNT(*) c FROM family_members WHERE user_id=$userId")->fetch()['c'],
];

$members = $pdo->prepare("SELECT id, full_name, relationship FROM family_members WHERE user_id=? ORDER BY id DESC LIMIT 10");
$members->execute([$userId]); $m = $members->fetchAll();

$emergency = null;
if ($u && !empty($u['emergency_contact_id'])) {
  $em = $pdo->prepare("SELECT id, full_name, relationship, phone FROM family_members WHERE id=? AND user_id=? LIMIT 1");
  $em->execute([(int)$u['emergency_contact_id'], $userId]);
  $emergency = $em->fetch() ?: null;
}

$privacy = fetch_privacy_settings($pdo, $userId);

ok([
  'user'=>$u,
  'counts'=>$counts,
  'family_members'=>$m,
  'emergency_contact'=>$emergency,
  'privacy_settings' => $privacy,
]);
