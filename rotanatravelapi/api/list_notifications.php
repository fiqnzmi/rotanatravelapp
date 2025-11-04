<?php
require_once 'db.php'; require_once 'helpers.php';
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
$pdo = db();
$rows = $pdo->prepare("SELECT id, type, title, body, created_at FROM notifications
                       WHERE (:uid=0 OR user_id=:uid) ORDER BY created_at DESC LIMIT 30");
$rows->execute([':uid'=>$userId]);
ok($rows->fetchAll());
