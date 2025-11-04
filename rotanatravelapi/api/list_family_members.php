<?php
require_once 'db.php';
require_once 'helpers.php';

$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
if ($userId <= 0) {
  fail('Missing user_id');
}

$pdo = db();
$stmt = $pdo->prepare("
  SELECT
    id,
    full_name,
    relationship,
    gender,
    passport_no,
    dob,
    passport_issue_date,
    passport_expiry_date,
    nationality,
    phone
  FROM family_members
  WHERE user_id = ?
  ORDER BY id DESC
");
$stmt->execute([$userId]);
$data = $stmt->fetchAll(PDO::FETCH_ASSOC);

foreach ($data as &$row) {
  $row['full_name'] = $row['full_name'] ?? '';
  $row['relationship'] = $row['relationship'] ?? 'OTHER';
  $row['gender'] = normalize_gender_value($row['gender'] ?? null);
  $row['passport_no'] = $row['passport_no'] ?? '';
  $row['dob'] = normalize_date_value($row['dob'] ?? null);
  $row['passport_issue_date'] = normalize_date_value($row['passport_issue_date'] ?? null);
  $row['passport_expiry_date'] = normalize_date_value($row['passport_expiry_date'] ?? null);
  $row['nationality'] = $row['nationality'] ?? '';
  $row['phone'] = $row['phone'] ?? '';
}
unset($row);

ok($data);
