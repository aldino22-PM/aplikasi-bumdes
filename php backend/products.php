<?php
header('Content-Type: application/json');
require 'db.php';
$sql = 'SELECT id,title,price,image,category,rating,distance,delivery_time FROM products WHERE is_active=1';
echo json_encode($pdo->query($sql)->fetchAll(PDO::FETCH_ASSOC));
