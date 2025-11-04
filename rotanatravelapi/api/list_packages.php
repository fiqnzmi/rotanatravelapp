<?php
require_once 'db.php';
require_once 'helpers.php';

$pdo = db();
$rows = $pdo->query("
  SELECT id, title, description, price,
         duration_days, cities, hotel_stars,
         rating_avg, rating_count,
         images_json
  FROM packages
  ORDER BY created_at DESC, id DESC
")->fetchAll();

foreach ($rows as &$r) {
  $images = [];
  if (!empty($r['images_json'])) {
    $decoded = json_decode($r['images_json'], true);
    if (is_array($decoded)) {
      $images = $decoded;
    }
  }
  $r['price'] = isset($r['price']) ? (float)$r['price'] : 0.0;
  if ($r['duration_days'] !== null) {
    $r['duration_days'] = (int)$r['duration_days'];
  }
  if ($r['hotel_stars'] !== null) {
    $r['hotel_stars'] = (int)$r['hotel_stars'];
  }
  if ($r['rating_avg'] !== null) {
    $r['rating_avg'] = (float)$r['rating_avg'];
  }
  if ($r['rating_count'] !== null) {
    $r['rating_count'] = (int)$r['rating_count'];
  }
  $r['images'] = $images;
  $r['cover_image'] = $images[0] ?? null;
  unset($r['images_json']);
}
unset($r);

ok($rows);
