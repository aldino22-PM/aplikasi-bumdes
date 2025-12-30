<?php
$host = "localhost";
$user = "db_user";
$pass = "db_pass";
$db   = "db_bumdes";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) { http_response_code(500); echo json_encode(["error"=>"DB error"]); exit; }

header("Content-Type: application/json; charset=UTF-8");
?>
