<?php
require_once __DIR__ . '/gadget.php';
session_start();

header('Content-Type: text/plain');

if (!isset($_FILES['file'])) {
    http_response_code(400);
    echo "no file\n";
    exit;
}

$name = $_POST['PHP_SESSION_UPLOAD_PROGRESS'] ?? 'x';
$_SESSION['upload_progress_' . $name] = json_encode([
    'total' => $_FILES['file']['size'],
    'done'  => $_FILES['file']['size'],
    'name'  => $name,
]);

session_write_close();
echo "ok\n";