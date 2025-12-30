<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// jawab preflight tanpa lanjut ke logika / DB
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

require 'db.php';

$title    = $_POST['title'] ?? '';
$price    = (int)($_POST['price'] ?? 0);
$imageUrl = $_POST['image'] ?? '';
$category = $_POST['category'] ?? '';
$rating   = (float)($_POST['rating'] ?? 4.8);
$distance = $_POST['distance'] ?? '1 km';
$delivery = $_POST['delivery_time'] ?? '10-15 mnt';
$weight   = $_POST['weight'] ?? '250 gr';
$origin   = $_POST['origin'] ?? 'Kebun Mitra Baru';

if (!$title || !$price || !$category) {
  http_response_code(400);
  echo json_encode(['message' => 'Field wajib: title, price, category']);
  exit;
}

// handle upload file jika ada
$finalImage = $imageUrl;
if (!empty($_FILES['image_file']['tmp_name'])) {
  // simpan di C:\xampp\htdocs\flutter_api\upload
  $uploadDir = __DIR__ . '/upload/';
  if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0775, true);
  }
  $safeName = time() . '-' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $_FILES['image_file']['name']);
  $targetPath = $uploadDir . $safeName;
  if (move_uploaded_file($_FILES['image_file']['tmp_name'], $targetPath)) {
    // path relatif untuk disimpan
    $finalImage = 'upload/' . $safeName;
  } else {
    http_response_code(500);
    echo json_encode(['message' => 'Gagal mengunggah gambar']);
    exit;
  }
}

// jika tidak ada file dan tidak ada URL
if (!$finalImage) {
  http_response_code(400);
  echo json_encode(['message' => 'Harus menyertakan URL gambar atau upload file']);
  exit;
}

try {
  $stmt = $pdo->prepare(
    'INSERT INTO products (title, price, image, category, rating, distance, delivery_time, weight, origin, stock, is_active)
     VALUES (?,?,?,?,?,?,?,?,?,0,1)'
  );
  $stmt->execute([$title, $price, $finalImage, $category, $rating, $distance, $delivery, $weight, $origin]);

  echo json_encode(['message' => 'Produk ditambahkan', 'id' => $pdo->lastInsertId()]);
} catch (PDOException $e) {
  http_response_code(500);
  echo json_encode(['message' => 'Gagal menyimpan', 'error' => $e->getMessage()]);
}
