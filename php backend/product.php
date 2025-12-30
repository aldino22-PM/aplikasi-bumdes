<?php
require "config.php";
$id = intval($_GET["id"] ?? 0);

$stmt = $conn->prepare("SELECT id, nama, harga, stok, gambar_url, deskripsi FROM products WHERE id=?");
$stmt->bind_param("i", $id);
$stmt->execute();
$res = $stmt->get_result();

if ($row = $res->fetch_assoc()) {
  echo json_encode($row);
} else {
  http_response_code(404);
  echo json_encode(["error" => "Not found"]);
}
?>
