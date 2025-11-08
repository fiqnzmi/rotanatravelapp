<?php
$pdo = new PDO('mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4','sabrisae_rotanatravel','Rotanatravel_2025', [
  PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
]);

// Ensure roles exist
$roles = ['Admin','Staff'];
foreach ($roles as $role) {
  $pdo->prepare("INSERT IGNORE INTO role (RoleID, RoleName)
                 SELECT COALESCE((SELECT RoleID FROM role WHERE RoleName=?), NULL), ? 
                 WHERE NOT EXISTS (SELECT 1 FROM role WHERE RoleName=?)")
      ->execute([$role, $role, $role]);
}

// Get role IDs
$roleMap = [];
$stmt = $pdo->query("SELECT RoleID, RoleName FROM role");
foreach ($stmt as $r) $roleMap[$r['RoleName']] = $r['RoleID'];

// Upsert staff (email = login)
function upsertStaff($pdo, $name, $email, $plainPw, $roleId) {
  $hash = password_hash($plainPw, PASSWORD_DEFAULT);
  $exists = $pdo->prepare("SELECT StaffID FROM staff WHERE Email=?");
  $exists->execute([$email]);
  if ($exists->fetch()) {
    $u = $pdo->prepare("UPDATE staff SET Name=?, Password=?, RoleID=? WHERE Email=?");
    $u->execute([$name, $hash, $roleId, $email]);
    echo "Updated $email\n";
  } else {
    $i = $pdo->prepare("INSERT INTO staff (Name, Email, Password, RoleID) VALUES (?,?,?,?)");
    $i->execute([$name, $email, $hash, $roleId]);
    echo "Inserted $email\n";
  }
}

upsertStaff($pdo, 'Rotana Admin', 'admin@rotana.test', '123456', $roleMap['Admin']);
upsertStaff($pdo, 'Rotana Staff', 'staff@rotana.test', '123456', $roleMap['Staff']);

echo "Done.\n";
