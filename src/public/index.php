<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chat App</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <div class="container">
        <!-- Login/User Selection Screen -->
        <div id="login-screen" class="screen">
            <h1>ユーザー選択</h1>
            <div class="user-list">
                <button class="user-btn" data-id="1">UserA</button>
                <button class="user-btn" data-id="2">UserB</button>
                <button class="user-btn" data-id="3">UserC</button>
            </div>
        </div>

        <!-- Chat Screen -->
        <div id="chat-screen" class="screen hidden">
            <div class="sidebar">
                <h2>Users</h2>
                <div id="chat-user-list">
                    <!-- User list will be populated here -->
                </div>
                <button id="logout-btn">ログアウト</button>
            </div>
            <div class="main-chat">
                <div class="chat-header">
                    <h2 id="chat-with-name">Select a user to chat</h2>
                </div>
                <div id="message-area" class="message-area">
                    <!-- Messages will be displayed here -->
                </div>
                <div class="input-area">
                    <textarea id="message-input" placeholder="メッセージを入力..."></textarea>
                    <button id="send-btn">送信</button>
                </div>
            </div>
        </div>
    </div>

    <!-- Edit Modal -->
    <div id="edit-modal" class="modal hidden">
        <div class="modal-content">
            <h3>メッセージ編集</h3>
            <textarea id="edit-input"></textarea>
            <div class="modal-actions">
                <button id="save-edit-btn">保存</button>
                <button id="cancel-edit-btn">キャンセル</button>
            </div>
        </div>
    </div>

    <script src="assets/js/app.js"></script>
</body>
</html>
