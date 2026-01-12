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

$user1_id = $_GET['user1_id'] ?? null;
$user2_id = $_GET['user2_id'] ?? null;

if (!$user1_id || !$user2_id) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required parameters']);
    exit;
}

$db = new Database();
$conn = $db->connect();
$service = new MessageService($conn);

$messages = $service->getMessages($user1_id, $user2_id);

echo json_encode(['messages' => $messages]);
