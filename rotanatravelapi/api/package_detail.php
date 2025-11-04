<?php
require_once 'db.php';
require_once 'helpers.php';
$id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
if ($id <= 0) fail('Missing id');

$pdo = db();
$p = $pdo->prepare("SELECT id, title, description, price, duration_days, cities, hotel_stars,
                           rating_avg, rating_count,
                           images_json, departures_json, inclusions_json,
                           itinerary_json, faqs_json, required_docs_json
                    FROM packages WHERE id=? LIMIT 1");
$p->execute([$id]);
$pkg = $p->fetch(); if (!$pkg) fail('Package not found', 404);

$decode = static function ($json) {
  if (!$json) return [];
  $decoded = json_decode($json, true);
  return is_array($decoded) ? $decoded : [];
};

$pkg['images'] = $decode($pkg['images_json'] ?? null);
$pkg['cover_image'] = $pkg['images'][0] ?? null;
$pkg['departures'] = $decode($pkg['departures_json'] ?? null);
$pkg['inclusions'] = $decode($pkg['inclusions_json'] ?? null);
$pkg['itinerary'] = $decode($pkg['itinerary_json'] ?? null);
$pkg['faqs'] = $decode($pkg['faqs_json'] ?? null);
$pkg['required_docs'] = $decode($pkg['required_docs_json'] ?? null);

$pkg['price'] = isset($pkg['price']) ? (float)$pkg['price'] : 0.0;
if ($pkg['duration_days'] !== null) {
  $pkg['duration_days'] = (int)$pkg['duration_days'];
}
if ($pkg['hotel_stars'] !== null) {
  $pkg['hotel_stars'] = (int)$pkg['hotel_stars'];
}
if ($pkg['rating_avg'] !== null) {
  $pkg['rating_avg'] = (float)$pkg['rating_avg'];
}
if ($pkg['rating_count'] !== null) {
  $pkg['rating_count'] = (int)$pkg['rating_count'];
}

unset(
  $pkg['images_json'],
  $pkg['departures_json'],
  $pkg['inclusions_json'],
  $pkg['itinerary_json'],
  $pkg['faqs_json'],
  $pkg['required_docs_json']
);

ok($pkg);
