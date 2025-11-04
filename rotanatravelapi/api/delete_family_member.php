<?php
require_once 'db.php'; require_once 'helpers.php';
$i = body(); require_fields($i, ['id','user_id']);
$pdo = db();
$pdo->prepare("DELETE FROM family_members WHERE id=? AND user_id=?")->execute([(int)$i['id'], (int)$i['user_id']]);
ok(['deleted'=>true]);
