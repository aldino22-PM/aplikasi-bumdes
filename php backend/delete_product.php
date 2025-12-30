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
$id = isset($raw['id']) ? (int)$raw['id'] : 0;
if ($id <= 0) {
  http_response_code(400);
  echo json_encode(['message' => 'id wajib diisi']);
  exit;
}

try {
  $stmt = $pdo->prepare('DELETE FROM products WHERE id = ?');
  $stmt->execute([$id]);
  echo json_encode(['message' => 'Produk dihapus', 'id' => $id]);
} catch (PDOException $e) {
  http_response_code(500);
  echo json_encode(['message' => 'Gagal menghapus produk', 'error' => $e->getMessage()]);
}
