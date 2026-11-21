<?php
header('Content-Type: text/plain');
$f = $_GET['f'] ?? '';
if ($f !== '' && is_file($f)) {
    readfile($f);
} else {
    http_response_code(404);
    echo "no\n";
}