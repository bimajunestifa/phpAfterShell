<?php
require_once __DIR__ . '/gadget.php';
session_start();

header('Content-Type: text/plain');
echo "sess=" . session_id() . "\n";
echo "keys=" . implode(',', array_keys($_SESSION)) . "\n";
echo "data=" . json_encode($_SESSION) . "\n";