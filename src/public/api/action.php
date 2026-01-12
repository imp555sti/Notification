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

$action = $data['action'] ?? null;
$message_id = $data['message_id'] ?? null;
$user_id = $data['user_id'] ?? null;

if (!$action || !$message_id || !$user_id) {
    http_response_code(400);
    echo json_encode(['error' => 'Missing required fields']);
    exit;
}

$db = new Database();
$conn = $db->connect();
$service = new MessageService($conn);

$success = false;

if ($action === 'edit') {
    $content = $data['content'] ?? '';
    $success = $service->editMessage($message_id, $user_id, $content);
} elseif ($action === 'delete') {
    $success = $service->deleteMessage($message_id, $user_id);
} else {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid action']);
    exit;
}

if ($success) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Action failed']);
}
