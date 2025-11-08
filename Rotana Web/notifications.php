<?php
// notifications.php — lightweight polling endpoint for pending bookings
declare(strict_types=1);

session_start();

header('Content-Type: application/json');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

if (!isset($_SESSION['user_id'])) {
    http_response_code(401);
    echo json_encode(['ok' => false, 'error' => 'unauthorized']);
    exit;
}

try {
    $pdo = new PDO(
        'mysql:host=localhost;dbname=sabrisae_rotanatravel;charset=utf8mb4',
        'sabrisae_rotanatravel',
        'Rotanatravel_2025',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]
    );
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => 'db_connection_failed']);
    exit;
}

$stmt = $pdo->query("
    SELECT
        b.id,
        b.created_at,
        u.name  AS customer_name,
        p.title AS package_name
    FROM bookings b
    LEFT JOIN users u    ON u.id = b.user_id
    LEFT JOIN packages p ON p.id = b.package_id
    WHERE UPPER(b.status) = 'PENDING'
    ORDER BY b.created_at DESC
    LIMIT 10
");
$rows = $stmt->fetchAll();

$items = [];
foreach ($rows as $row) {
    $createdAt = $row['created_at'] ?? null;
    $createdIso = null;
    if ($createdAt) {
        try {
            $createdIso = (new DateTimeImmutable($createdAt))->format(DATE_ATOM);
        } catch (Exception $e) {
            $createdIso = null;
        }
    }

    $items[] = [
        'id'            => isset($row['id']) ? (int)$row['id'] : null,
        'customer_name' => $row['customer_name'] ?? null,
        'package_name'  => $row['package_name'] ?? null,
        'created_at'    => $createdIso,
    ];
}

echo json_encode([
    'ok'           => true,
    'pendingCount' => count($items),
    'items'        => $items,
]);
