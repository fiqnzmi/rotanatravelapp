<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['user_id', 'full_name', 'relationship']);

$pdo = db();

$userId = (int)$input['user_id'];
if ($userId <= 0) {
  fail('Invalid user id');
}

$params = [
  $userId,
  trim((string)$input['full_name']),
  normalize_relationship_value($input['relationship']),
  normalize_gender_value($input['gender'] ?? null),
  isset($input['passport_no']) ? trim((string)$input['passport_no']) : null,
  normalize_date_value($input['dob'] ?? null),
  normalize_date_value($input['passport_issue_date'] ?? null),
  normalize_date_value($input['passport_expiry_date'] ?? null),
  isset($input['nationality']) ? trim((string)$input['nationality']) : null,
  isset($input['phone']) ? trim((string)$input['phone']) : null,
];

try {
  $stmt = $pdo->prepare("
    INSERT INTO family_members (
      user_id,
      full_name,
      relationship,
      gender,
      passport_no,
      dob,
      passport_issue_date,
      passport_expiry_date,
      nationality,
      phone,
      created_at
    ) VALUES (?,?,?,?,?,?,?,?,?,?,NOW())
  ");
  $stmt->execute($params);
  ok(['id' => (int)$pdo->lastInsertId()]);
} catch (PDOException $e) {
  fail('Failed to save family member: '.$e->getMessage(), 500);
}
