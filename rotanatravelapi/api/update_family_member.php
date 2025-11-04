<?php
require_once 'db.php';
require_once 'helpers.php';

$input = body();
require_fields($input, ['id', 'user_id', 'full_name', 'relationship']);

$pdo = db();

$id = (int)$input['id'];
$userId = (int)$input['user_id'];
if ($id <= 0 || $userId <= 0) {
  fail('Invalid request');
}

$params = [
  trim((string)$input['full_name']),
  normalize_relationship_value($input['relationship']),
  normalize_gender_value($input['gender'] ?? null),
  isset($input['passport_no']) ? trim((string)$input['passport_no']) : null,
  normalize_date_value($input['dob'] ?? null),
  normalize_date_value($input['passport_issue_date'] ?? null),
  normalize_date_value($input['passport_expiry_date'] ?? null),
  isset($input['nationality']) ? trim((string)$input['nationality']) : null,
  isset($input['phone']) ? trim((string)$input['phone']) : null,
  $id,
  $userId,
];

try {
  $sql = "
    UPDATE family_members
    SET full_name = ?,
        relationship = ?,
        gender = ?,
        passport_no = ?,
        dob = ?,
        passport_issue_date = ?,
        passport_expiry_date = ?,
        nationality = ?,
        phone = ?
    WHERE id = ? AND user_id = ?
  ";
  $stmt = $pdo->prepare($sql);
  $stmt->execute($params);
  if ($stmt->rowCount() === 0) {
    fail('No record updated', 404);
  }
  ok(['updated' => true]);
} catch (PDOException $e) {
  fail('Failed to update family member: '.$e->getMessage(), 500);
}
