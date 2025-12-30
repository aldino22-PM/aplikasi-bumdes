<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

require 'db.php';

$raw = json_decode(file_get_contents('php://input'), true) ?? [];
$items = $raw['items'] ?? [];
$userId = isset($raw['user_id']) ? (int)$raw['user_id'] : 0;
$deliveryFee = (int)($raw['delivery_fee'] ?? 0);
$paymentMethod = $raw['payment_method'] ?? 'cash';
$status = $raw['status'] ?? 'pending';

if (empty($items)) {
  http_response_code(400);
  echo json_encode(['message' => 'Items kosong']);
  exit;
}

if ($userId <= 0) {
  // fallback: ambil user role user pertama, jika tidak ada, ambil user pertama apa saja
  $userStmt = $pdo->query("SELECT id FROM users WHERE role='user' ORDER BY id ASC LIMIT 1");
  $fallback = $userStmt->fetch(PDO::FETCH_ASSOC);
  if (!$fallback) {
    $userStmt = $pdo->query('SELECT id FROM users ORDER BY id ASC LIMIT 1');
    $fallback = $userStmt->fetch(PDO::FETCH_ASSOC);
  }
  if ($fallback && isset($fallback['id'])) {
    $userId = (int)$fallback['id'];
  } else {
    http_response_code(400);
    echo json_encode(['message' => 'user_id wajib dikirim dan tidak ditemukan fallback user']);
    exit;
  }
}

$subtotal = 0;
foreach ($items as $item) {
  $qty = (int)($item['quantity'] ?? 0);
  $price = (int)($item['price'] ?? 0);
  $subtotal += $qty * $price;
}
$total = $subtotal + $deliveryFee;

try {
  $pdo->beginTransaction();

  $stmt = $pdo->prepare(
    'INSERT INTO orders (`user_id`, `status`, `subtotal`, `delivery_fee`, `total`, `payment_method`, `created_at`)
     VALUES (?,?,?,?,?,?,NOW())'
  );
  $stmt->execute([$userId, $status, $subtotal, $deliveryFee, $total, $paymentMethod]);
  $orderId = $pdo->lastInsertId();

  $insertItem = $pdo->prepare(
    'INSERT INTO order_items (order_id, product_id, quantity, price, total) VALUES (?,?,?,?,?)'
  );

  foreach ($items as $item) {
    $productId = $item['product_id'] ?? null;
    $qty = (int)($item['quantity'] ?? 0);
    $price = (int)($item['price'] ?? 0);
    $rowTotal = $qty * $price;

    if (!$productId || $qty <= 0) {
      continue;
    }
    $insertItem->execute([$orderId, $productId, $qty, $price, $rowTotal]);
  }

  $pdo->commit();
  echo json_encode(['message' => 'Order disimpan', 'order_id' => $orderId, 'user_id' => $userId]);
} catch (PDOException $e) {
  $pdo->rollBack();
  http_response_code(500);
  echo json_encode(['message' => 'Gagal membuat order', 'error' => $e->getMessage()]);
}
