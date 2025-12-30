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

try {
  $sql = 'SELECT o.id, o.user_id, o.status, o.total, o.created_at, u.name AS customer, u.email AS email
          FROM orders o
          LEFT JOIN users u ON u.id = o.user_id
          ORDER BY o.created_at DESC';
  $stmt = $pdo->query($sql);
  $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);

  $itemStmt = $pdo->query('SELECT oi.order_id, oi.quantity, oi.price, p.title
                            FROM order_items oi
                            LEFT JOIN products p ON p.id = oi.product_id');
  $itemsByOrder = [];
  foreach ($itemStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $orderId = $row['order_id'];
    if (!isset($itemsByOrder[$orderId])) {
      $itemsByOrder[$orderId] = [];
    }
    $itemsByOrder[$orderId][] = $row;
  }

  $result = [];
  foreach ($orders as $order) {
    $id = $order['id'];
    $items = $itemsByOrder[$id] ?? [];
    $count = count($items);
    $names = array_slice(array_map(function($it){ return $it['title'] ?: 'Produk'; }, $items), 0, 3);
    $summaryNames = implode(', ', $names);
    $itemsDescription = $count > 0 ? "$count produk ($summaryNames)" : '-';

    $result[] = [
      'id' => $id,
      'status' => $order['status'] ?? 'pending',
      'total' => (int)$order['total'],
      'created_at' => $order['created_at'],
      'customer' => $order['customer'] ?: 'Pelanggan',
      'contact' => $order['email'] ?: '',
      'items_description' => $itemsDescription,
    ];
  }

  echo json_encode($result);
} catch (PDOException $e) {
  http_response_code(500);
  echo json_encode(['message' => 'Gagal memuat orders', 'error' => $e->getMessage()]);
}
