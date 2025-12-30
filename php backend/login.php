<?php
header('Content-Type: application/json');
require 'db.php';

$raw = json_decode(file_get_contents('php://input'), true) ?? [];
$email = trim($raw['email'] ?? ($_POST['email'] ?? ''));
$pass  = $raw['password'] ?? ($_POST['password'] ?? '');

$stmt = $pdo->prepare('SELECT id,name,email,password,role FROM users WHERE email=? LIMIT 1');
$stmt->execute([$email]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user || !password_verify($pass, $user['password'])) {
  http_response_code(401);
  echo json_encode(['message' => 'Email atau password salah']); exit;
}

$role = isset($user['role']) && $user['role'] !== '' ? $user['role'] : 'user';
$token = bin2hex(random_bytes(16));

echo json_encode([
  'token' => $token,
  'role' => $role,
  'user' => [
    'id'=>$user['id'],
    'name'=>$user['name'],
    'email'=>$user['email'],
    'role'=>$role,
  ]
]);
