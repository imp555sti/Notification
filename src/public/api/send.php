<?php
require_once __DIR__ . '/../../lib/Database.php';
require_once __DIR__ . '/../../lib/MessageService.php';

use Lib\Database;
use Lib\MessageService;

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method Not Allowed']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['sender_id']) || !isset($data['receiver_id']) || !isset($data['content'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$db = new Database();
$conn = $db->connect();
$service = new MessageService($conn);

if ($service->sendMessage($data['sender_id'], $data['receiver_id'], $data['content'])) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to send message']);
}
