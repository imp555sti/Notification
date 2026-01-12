<?php
require_once __DIR__ . '/../../lib/Database.php';
require_once __DIR__ . '/../../lib/MessageService.php';

use Lib\Database;
use Lib\MessageService;

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit;
}

$receiver_id = $_GET['receiver_id'] ?? null;
$sender_id = $_GET['sender_id'] ?? null;
$last_check_time = $_GET['last_check_time'] ?? null;

if (!$receiver_id || !$sender_id) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required parameters']);
    exit;
}

$db = new Database();
$conn = $db->connect();
$service = new MessageService($conn);

// 既読処理のリクエストがあれば先に処理
if (isset($_GET['mark_read']) && $_GET['mark_read'] === 'true') {
    $service->markAsRead($sender_id, $receiver_id);
}

$result = $service->checkUpdates($receiver_id, $sender_id, $last_check_time);

echo json_encode($result);
