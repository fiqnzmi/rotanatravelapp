<?php
require_once 'db.php'; require_once 'helpers.php';
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId<=0) {
  // fallback demo user
  $userId = 1;
}
$pdo = db();
$user = $pdo->prepare("SELECT id, username, name, email FROM users WHERE id=?");
$user->execute([$userId]); $u = $user->fetch();

$counts = [
  'completed' => (int)$pdo->query("SELECT COUNT(*) c FROM bookings WHERE user_id=$userId AND status='COMPLETED'")->fetch()['c'],
  'upcoming'  => (int)$pdo->query("SELECT COUNT(*) c FROM bookings WHERE user_id=$userId AND status='CONFIRMED'")->fetch()['c'],
  'family_members' => (int)$pdo->query("SELECT COUNT(*) c FROM family_members WHERE user_id=$userId")->fetch()['c'],
];

$members = $pdo->prepare("SELECT id, full_name, relationship FROM family_members WHERE user_id=? ORDER BY id DESC LIMIT 10");
$members->execute([$userId]); $m = $members->fetchAll();

ok(['user'=>$u, 'counts'=>$counts, 'family_members'=>$m]);
