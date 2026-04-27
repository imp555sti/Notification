import { expect, test } from '@playwright/test';

type Message = {
    id: number;
    sender_id: number;
    receiver_id: number;
    content: string;
    status: 'active' | 'edited' | 'deleted';
    created_at: string;
    updated_at: string;
};

test.describe('Chat Flow', () => {
    test('相手選択後に送信・編集・削除ができる', async ({ page }) => {
        const now = '2026-04-27T10:00:00.000Z';
        let nextId = 100;
        const messages: Message[] = [
            {
                id: 1,
                sender_id: 2,
                receiver_id: 1,
                content: 'こんにちは',
                status: 'active',
                created_at: now,
                updated_at: now,
            },
        ];

        await page.addInitScript(() => {
            localStorage.setItem('notification_confirm_next_show_at', String(Date.now() + 24 * 60 * 60 * 1000));
        });

        await page.route('**/api/fetch.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ messages }),
            });
        });

        await page.route('**/api/check.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ unread_count: 0, updates: [], timestamp: new Date().toISOString() }),
            });
        });

        await page.route('**/api/send.php', async (route) => {
            const payload = JSON.parse(route.request().postData() || '{}') as {
                sender_id: number;
                receiver_id: number;
                content: string;
            };

            const created: Message = {
                id: nextId++,
                sender_id: payload.sender_id,
                receiver_id: payload.receiver_id,
                content: payload.content,
                status: 'active',
                created_at: now,
                updated_at: now,
            };
            messages.push(created);

            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ success: true }),
            });
        });

        await page.route('**/api/action.php', async (route) => {
            const payload = JSON.parse(route.request().postData() || '{}') as {
                action: 'edit' | 'delete';
                message_id: number;
                content?: string;
            };
            const target = messages.find((msg) => msg.id === payload.message_id);

            if (!target) {
                await route.fulfill({
                    status: 404,
                    contentType: 'application/json',
                    body: JSON.stringify({ success: false }),
                });
                return;
            }

            if (payload.action === 'edit') {
                target.content = payload.content || target.content;
                target.status = 'edited';
                target.updated_at = now;
            }

            if (payload.action === 'delete') {
                target.status = 'deleted';
                target.updated_at = now;
            }

            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ success: true }),
            });
        });

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();
        await page.locator('#chat-user-list .user-item[data-id="2"]').click();

        await expect(page.locator('#chat-with-name')).toHaveText('UserB とチャット中');

        await page.locator('#message-input').fill('E2E送信メッセージ');
        await page.getByRole('button', { name: '送信' }).click();

        await expect(page.locator('#message-input')).toHaveValue('');
        await expect(page.locator('#message-area .message-content').last()).toHaveText('E2E送信メッセージ');

        await page.locator('#message-area .message.sent .action-link[data-action="edit"]').last().click();
        await page.locator('#edit-input').fill('E2E編集後メッセージ');
        await page.getByRole('button', { name: '保存' }).click();

        await expect(page.locator('#message-area .message-content').last()).toHaveText('E2E編集後メッセージ');
        await expect(page.locator('#message-area')).toContainText('(編集済み)');

        page.once('dialog', async (dialog) => {
            await dialog.accept();
        });
        await page.locator('#message-area .message.sent .action-link[data-action="delete"]').last().click();

        await expect(page.locator('#message-area')).toContainText('メッセージは削除されました');
    });
});
