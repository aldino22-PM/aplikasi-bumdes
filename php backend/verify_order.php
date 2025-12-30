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

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['message' => 'Gunakan POST']);
  exit;
}

$raw = json_decode(file_get_contents('php://input'), true) ?? [];
$orderId = isset($raw['order_id']) ? (int)$raw['order_id'] : 0;
$newStatus = $raw['status'] ?? 'accepted';

if ($orderId <= 0) {
  http_response_code(400);
  echo json_encode(['message' => 'order_id wajib diisi']);
  exit;
}

try {
  $stmt = $pdo->prepare('UPDATE orders SET status = ? WHERE id = ?');
  $stmt->execute([$newStatus, $orderId]);

  echo json_encode(['message' => 'Order diperbarui', 'order_id' => $orderId, 'status' => $newStatus]);
} catch (PDOException $e) {
  http_response_code(500);
  echo json_encode(['message' => 'Gagal memperbarui order', 'error' => $e->getMessage()]);
}
