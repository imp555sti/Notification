import { expect, test } from '@playwright/test';

type MessagePayload = {
    id: number;
    sender_id: number;
    receiver_id: number;
    content: string;
    status: 'active' | 'edited' | 'deleted';
    created_at: string;
    updated_at: string;
};

async function setupNotificationProbe(page: import('@playwright/test').Page): Promise<void> {
    await page.addInitScript(() => {
        const calls: Array<{ title: string; body: string }> = [];
        (window as { __notificationCalls?: Array<{ title: string; body: string }> }).__notificationCalls = calls;

        // 初回ログイン時の通知モーダルを抑止
        localStorage.setItem('notification_confirm_next_show_at', String(Date.now() + 24 * 60 * 60 * 1000));

        class FakeNotification {
            public static permission = 'granted';

            public static requestPermission(): Promise<'granted'> {
                return Promise.resolve('granted');
            }

            public constructor(title: string, options?: { body?: string }) {
                calls.push({ title, body: options?.body || '' });
            }
        }

        Object.defineProperty(window, 'Notification', {
            value: FakeNotification,
            configurable: true,
            writable: true,
        });
    });
}

test.describe('Notification Delivery', () => {
    test('表示中の相手チャット更新では通知を発火しない', async ({ page }) => {
        const now = '2026-04-27T10:00:00.000Z';
        let sender2PollCount = 0;

        await setupNotificationProbe(page);

        await page.route('**/api/fetch.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ messages: [] }),
            });
        });

        await page.route('**/api/check.php**', async (route) => {
            const url = new URL(route.request().url());
            const senderId = Number(url.searchParams.get('sender_id') || '0');
            const markRead = url.searchParams.get('mark_read') === 'true';

            if (markRead) {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({ unread_count: 0, updates: [], timestamp: now }),
                });
                return;
            }

            if (senderId === 2) {
                sender2PollCount += 1;
                const updates: MessagePayload[] = [
                    {
                        id: 201,
                        sender_id: 2,
                        receiver_id: 1,
                        content: 'UserB からの更新',
                        status: 'active',
                        created_at: now,
                        updated_at: now,
                    },
                ];
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({ unread_count: 1, updates, timestamp: now }),
                });
                return;
            }

            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ unread_count: 0, updates: [], timestamp: now }),
            });
        });

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();
        await page.locator('#chat-user-list .user-item[data-id="2"]').click();

        await expect.poll(() => sender2PollCount, { timeout: 12000 }).toBeGreaterThan(0);

        const calls = await page.evaluate(
            () =>
                (
                    window as { __notificationCalls?: Array<{ title: string; body: string }> }
                ).__notificationCalls || [],
        );
        expect(calls.length).toBe(0);
    });

    test('非アクティブ相手の更新では通知を発火する', async ({ page }) => {
        const now = '2026-04-27T10:00:00.000Z';

        await setupNotificationProbe(page);

        await page.route('**/api/fetch.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ messages: [] }),
            });
        });

        await page.route('**/api/check.php**', async (route) => {
            const url = new URL(route.request().url());
            const senderId = Number(url.searchParams.get('sender_id') || '0');
            const markRead = url.searchParams.get('mark_read') === 'true';

            if (markRead) {
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({ unread_count: 0, updates: [], timestamp: now }),
                });
                return;
            }

            if (senderId === 3) {
                const updates: MessagePayload[] = [
                    {
                        id: 301,
                        sender_id: 3,
                        receiver_id: 1,
                        content: 'UserC からの新着',
                        status: 'active',
                        created_at: now,
                        updated_at: now,
                    },
                ];
                await route.fulfill({
                    status: 200,
                    contentType: 'application/json',
                    body: JSON.stringify({ unread_count: 1, updates, timestamp: now }),
                });
                return;
            }

            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ unread_count: 0, updates: [], timestamp: now }),
            });
        });

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        // UserB のチャットを開いた状態で UserC 更新を受ける
        await page.locator('#chat-user-list .user-item[data-id="2"]').click();

        await expect.poll(
            async () => {
                const calls = await page.evaluate(
                    () =>
                        (
                            window as { __notificationCalls?: Array<{ title: string; body: string }> }
                        ).__notificationCalls || [],
                );
                return calls.length;
            },
            { timeout: 12000 },
        ).toBeGreaterThan(0);

        const calls = await page.evaluate(
            () =>
                (
                    window as { __notificationCalls?: Array<{ title: string; body: string }> }
                ).__notificationCalls || [],
        );

        expect(calls[0].title).toContain('UserC');
        expect(calls[0].body).toContain('新着');
    });
});
