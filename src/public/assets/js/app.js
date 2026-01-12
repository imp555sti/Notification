document.addEventListener('DOMContentLoaded', () => {
    // Current User State
    let currentUser = null;
    let currentChatPartner = null;
    const users = [
        { id: 1, name: 'UserA' },
        { id: 2, name: 'UserB' },
        { id: 3, name: 'UserC' }
    ];

    // Polling interval
    let pollingInterval = null;
    let lastCheckTime = null;

    // DOM Elements
    const loginScreen = document.getElementById('login-screen');
    const chatScreen = document.getElementById('chat-screen');
    const userListContainer = document.querySelector('.user-list');
    const chatUserList = document.getElementById('chat-user-list');
    const chatWithName = document.getElementById('chat-with-name');
    const messageArea = document.getElementById('message-area');
    const messageInput = document.getElementById('message-input');
    const sendBtn = document.getElementById('send-btn');
    const logoutBtn = document.getElementById('logout-btn');
    const editModal = document.getElementById('edit-modal');
    const editInput = document.getElementById('edit-input');
    const saveEditBtn = document.getElementById('save-edit-btn');
    const cancelEditBtn = document.getElementById('cancel-edit-btn');

    let editingMessageId = null;

    // Initialize Notification API
    if ("Notification" in window) {
        Notification.requestPermission();
    }

    // --- Event Listeners ---

    // Login (User Selection)
    document.querySelectorAll('.user-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const userId = parseInt(btn.dataset.id);
            login(userId);
        });
    });

    // Logout
    logoutBtn.addEventListener('click', () => {
        logout();
    });

    // Send Message
    sendBtn.addEventListener('click', sendMessage);
    messageInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Edit Modal Actions
    saveEditBtn.addEventListener('click', saveEdit);
    cancelEditBtn.addEventListener('click', closeEditModal);

    // --- Functions ---

    function login(userId) {
        currentUser = users.find(u => u.id === userId);
        if (!currentUser) return;

        loginScreen.classList.add('hidden');
        chatScreen.classList.remove('hidden');

        renderChatUserList();
        
        // Start Polling
        startPolling();
    }

    function logout() {
        currentUser = null;
        currentChatPartner = null;
        stopPolling();
        chatScreen.classList.add('hidden');
        loginScreen.classList.remove('hidden');
    }

    function renderChatUserList() {
        chatUserList.innerHTML = '';
        users.forEach(user => {
            if (user.id === currentUser.id) return;

            const div = document.createElement('div');
            div.className = 'user-item';
            div.dataset.id = user.id;
            div.innerHTML = `
                <span>${user.name}</span>
                <span class="unread-badge" id="unread-${user.id}">0</span>
            `;
            div.addEventListener('click', () => {
                openChat(user);
            });
            chatUserList.appendChild(div);
        });
    }

    function openChat(user) {
        currentChatPartner = user;
        chatWithName.textContent = `${user.name} とチャット中`;
        
        // Highlight active user
        document.querySelectorAll('.user-item').forEach(el => el.classList.remove('active'));
        const activeItem = document.querySelector(`.user-item[data-id="${user.id}"]`);
        if(activeItem) activeItem.classList.add('active');

        // Clear messages and fetch history
        messageArea.innerHTML = '';
        fetchMessages();
    }

    async function fetchMessages() {
        if (!currentUser || !currentChatPartner) return;

        try {
            const response = await fetch(`api/fetch.php?user1_id=${currentUser.id}&user2_id=${currentChatPartner.id}`);
            const data = await response.json();
            
            messageArea.innerHTML = '';
            data.messages.forEach(msg => appendMessage(msg));
            scrollToBottom();
            
            // Mark as read immediately when opening/fetching
            markAsRead(currentChatPartner.id);

            // Update last check time to now (approx)
            lastCheckTime = new Date().toISOString(); 

        } catch (error) {
            console.error('Error fetching messages:', error);
        }
    }

    function appendMessage(msg) {
        const isMe = parseInt(msg.sender_id) === currentUser.id;
        const div = document.createElement('div');
        div.className = `message ${isMe ? 'sent' : 'received'}`;
        div.id = `msg-${msg.id}`;

        let contentHtml = '';
        if (msg.status === 'deleted') {
             contentHtml = '<div class="deleted-msg">メッセージは削除されました</div>';
        } else {
             contentHtml = `<div class="message-content">${escapeHtml(msg.content)}</div>`;
             if (msg.status === 'edited') {
                 contentHtml += '<div class="message-meta"><small>(編集済み)</small></div>';
             }
        }

        let metaHtml = `<div class="message-meta">${formatTime(msg.created_at)}</div>`;
        
        let actionsHtml = '';
        if (isMe && msg.status !== 'deleted') {
            actionsHtml = `
                <div class="message-actions">
                    <span class="action-link" onclick="window.editMessage(${msg.id}, '${escapeHtml(msg.content)}')">編集</span>
                    <span class="action-link" onclick="window.deleteMessage(${msg.id})">削除</span>
                </div>
            `;
        }

        div.innerHTML = contentHtml + metaHtml + actionsHtml;
        messageArea.appendChild(div);
    }

    function updateMessageDOM(msg) {
        const msgDiv = document.getElementById(`msg-${msg.id}`);
        if (!msgDiv) return; // Might not be loaded in current view, that's fine

        // Re-render the message content depending on status
        const isMe = parseInt(msg.sender_id) === currentUser.id;
        
        let contentHtml = '';
        if (msg.status === 'deleted') {
             contentHtml = '<div class="deleted-msg">メッセージは削除されました</div>';
             // Remove actions if deleted
             const actionsDiv = msgDiv.querySelector('.message-actions');
             if (actionsDiv) actionsDiv.remove();
        } else {
             contentHtml = `<div class="message-content">${escapeHtml(msg.content)}</div>`;
             if (msg.status === 'edited') {
                 contentHtml += '<div class="message-meta"><small>(編集済み)</small></div>';
             }
        }
        
        // Update content part only, easier to just replace content + meta + actions
        // But to keep it simple, check structure. 
        // Let's rebuild innerHTML for simplicity
        let metaHtml = `<div class="message-meta">${formatTime(msg.created_at)}</div>`;
        let actionsHtml = '';
        if (isMe && msg.status !== 'deleted') {
             actionsHtml = `
                <div class="message-actions">
                    <span class="action-link" onclick="window.editMessage(${msg.id}, '${escapeHtml(msg.content)}')">編集</span>
                    <span class="action-link" onclick="window.deleteMessage(${msg.id})">削除</span>
                </div>
            `;
        }
        msgDiv.innerHTML = contentHtml + metaHtml + actionsHtml;
    }

    async function sendMessage() {
        const content = messageInput.value.trim();
        if (!content || !currentChatPartner) return;

        try {
            const response = await fetch('api/send.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    sender_id: currentUser.id,
                    receiver_id: currentChatPartner.id,
                    content: content
                })
            });
            const result = await response.json();
            if (result.success) {
                messageInput.value = '';
                // Immediately fetch to show own message (or optimistically append)
                fetchMessages(); 
            }
        } catch (error) {
            console.error('Error sending message:', error);
        }
    }

    // Polling System
    function startPolling() {
        if (pollingInterval) clearInterval(pollingInterval);
        lastCheckTime = new Date(Date.now() - 5000).toISOString(); // Go back a bit to be safe
        pollingInterval = setInterval(checkUpdates, 3000);
    }

    function stopPolling() {
        if (pollingInterval) clearInterval(pollingInterval);
    }

    async function checkUpdates() {
        if (!currentUser) return;

        // Check for updates for ALL potential partners (or at least the active one + notifications for others)
        // Since the backend API is designed for pair (one receiver, one sender), 
        // we might need to change logic if we want global notifications.
        // BUT, requirements say "1:1 bidirectional", "New message from partner".
        // Let's iterate over other users to check for unread counts (inefficient but simple for 3 users).
        
        users.forEach(async (user) => {
            if (user.id === currentUser.id) return;

            // Prepare params
            let url = `api/check.php?receiver_id=${currentUser.id}&sender_id=${user.id}`;
            
            // If this is the currently open chat, we ask for updates since last time
            if (currentChatPartner && currentChatPartner.id === user.id) {
                if (lastCheckTime) {
                    url += `&last_check_time=${lastCheckTime}`;
                }
                // If window is focused/active, we can mark as read? 
                // For now, let's just fetch updates.
            }

            try {
                const response = await fetch(url);
                const data = await response.json();

                // Update Unread Count UI
                const badge = document.getElementById(`unread-${user.id}`);
                if (badge) {
                     if (data.unread_count > 0) {
                         badge.textContent = data.unread_count;
                         badge.style.display = 'inline-block';
                         
                         // If we are NOT chatting with this user, OR window is hidden, notify?
                         // "New message from partner" notification
                         // To avoid spamming, strict logic needed. Simplified here:
                         // Ideally check if unread count increased.
                         // For this MVP, let's check `updates` array for new messages.
                     } else {
                         badge.style.display = 'none';
                     }
                }

                // If updates found
                if (data.updates && data.updates.length > 0) {
                    // Update timestamp
                    // Only update global timestamp if we are processing the active chat?
                    // Actually check.php returns timestamp.
                    
                    data.updates.forEach(msg => {
                        // Notify if it's a new message (not edit/delete) and not from me
                        const isNew = new Date(msg.created_at) > new Date(msg.updated_at); // Rough check
                        // Actually 'status' helps.
                        
                        // If I am chatting with this user, append/update message
                        if (currentChatPartner && currentChatPartner.id === user.id) {
                            // Check if message already exists in DOM
                            const exists = document.getElementById(`msg-${msg.id}`);
                            if (exists) {
                                // It's an update (edit/delete)
                                updateMessageDOM(msg);
                            } else {
                                // It's new
                                appendMessage(msg);
                                scrollToBottom();
                                // Mark read if active
                                markAsRead(user.id);
                            }
                            lastCheckTime = data.timestamp; // synced with server time
                        }

                        // Notification 
                        // Show notification if:
                        // 1. Message is active (not deleted)
                        // 2. I am NOT the sender
                        // 3. (Optional) Page is hidden OR not chatting with this user
                        if (parseInt(msg.sender_id) !== currentUser.id && msg.status === 'active') {
                             // Simple check: if msg.created_at is very recent?
                             // Since we use polling, just notify for every 'new' item in updates
                             // that we haven't seen.
                             // Logic: If it's in 'updates', it's new since last check.
                             if (!isChattingWith(user.id) || document.hidden) {
                                 showNotification(user.name, msg.content);
                             }
                        }
                    });
                }

            } catch (e) {
                console.error(e);
            }
        });
    }

    function isChattingWith(userId) {
        return currentChatPartner && currentChatPartner.id === userId;
    }

    async function markAsRead(targetUserId) {
         try {
             await fetch(`api/check.php?receiver_id=${currentUser.id}&sender_id=${targetUserId}&mark_read=true`);
             // Clear badge locally
             const badge = document.getElementById(`unread-${targetUserId}`);
             if(badge) badge.style.display = 'none';
         } catch(e) {}
    }

    function showNotification(senderName, content) {
        if (Notification.permission === "granted") {
            new Notification(`New message from ${senderName}`, {
                body: content,
                icon: 'assets/icon.png' // Optional
            });
        }
    }

    function scrollToBottom() {
        messageArea.scrollTop = messageArea.scrollHeight;
    }

    function formatTime(timestamp) {
        if(!timestamp) return '';
        const date = new Date(timestamp);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    function escapeHtml(text) {
        if (!text) return '';
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    // --- Global Actions (exposed for inline onclick) ---
    window.editMessage = (id, currentContent) => {
        editingMessageId = id;
        editInput.value = currentContent;
        editModal.classList.remove('hidden');
    };

    window.deleteMessage = async (id) => {
        if(!confirm('本当に削除しますか？')) return;
        
        try {
            const response = await fetch('api/action.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    action: 'delete',
                    message_id: id,
                    user_id: currentUser.id
                })
            });
            const res = await response.json();
            if(res.success) {
                fetchMessages(); // Refresh
            }
        } catch(e) {
            console.error(e);
        }
    };

    async function saveEdit() {
        const newContent = editInput.value.trim();
        if(!newContent) return;

        try {
            const response = await fetch('api/action.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    action: 'edit',
                    message_id: editingMessageId,
                    user_id: currentUser.id,
                    content: newContent
                })
            });
            const res = await response.json();
            if(res.success) {
                closeEditModal();
                fetchMessages();
            }
        } catch(e) {
            console.error(e);
        }
    }

    function closeEditModal() {
        editModal.classList.add('hidden');
        editingMessageId = null;
        editInput.value = '';
    }
});
