<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); // hanya untuk dev
require 'db.php';
error_reporting(E_ALL);
ini_set('display_errors', 0); // matikan display di prod

$raw = json_decode(file_get_contents('php://input'), true) ?? [];
$name = trim($raw['name'] ?? ($_POST['name'] ?? ''));
$email = trim($raw['email'] ?? ($_POST['email'] ?? ''));
$pass = $raw['password'] ?? ($_POST['password'] ?? '');

if (!$name || !$email || !$pass) {
  http_response_code(400);
  echo json_encode(['message' => 'Nama, email, dan password wajib diisi']);
  exit;
}

$hash = password_hash($pass, PASSWORD_BCRYPT);

try {
  $stmt = $pdo->prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)');
  $stmt->execute([$name, $email, $hash, 'user']);
  echo json_encode(['message' => 'Registrasi berhasil']);
} catch (PDOException $e) {
  // 1062 = duplicate entry
  if ($e->errorInfo[1] == 1062) {
    http_response_code(400);
    echo json_encode(['message' => 'Email sudah terdaftar']);
  } else {
    http_response_code(500);
    echo json_encode(['message' => 'Gagal daftar']);
  }
}
