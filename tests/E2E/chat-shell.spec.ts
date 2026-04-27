import { expect, test } from '@playwright/test';

test.describe('Chat Shell', () => {
    test.beforeEach(async ({ page }) => {
        await page.addInitScript(() => {
            localStorage.setItem('notification_confirm_next_show_at', String(Date.now() + 24 * 60 * 60 * 1000));
        });

        await page.route('**/api/check.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ unread_count: 0, updates: [], timestamp: new Date().toISOString() }),
            });
        });

        await page.route('**/api/fetch.php**', async (route) => {
            await route.fulfill({
                status: 200,
                contentType: 'application/json',
                body: JSON.stringify({ messages: [] }),
            });
        });
    });

    test('初期表示でログイン画面が見え、チャット画面は非表示', async ({ page }) => {
        await page.goto('/public/index.php');

        await expect(page.locator('#login-screen')).toBeVisible();
        await expect(page.locator('#chat-screen')).toBeHidden();
    });

    test('ログイン後にチャット画面へ遷移し、自分以外のユーザーが表示される', async ({ page }) => {
        await page.goto('/public/index.php');

        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#chat-screen')).toBeVisible();
        await expect(page.locator('#login-screen')).toBeHidden();
        await expect(page.locator('#chat-user-list')).toContainText('UserB');
        await expect(page.locator('#chat-user-list')).toContainText('UserC');
        await expect(page.locator('#chat-user-list')).not.toContainText('UserA');
    });

    test('ログアウトでログイン画面に戻る', async ({ page }) => {
        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await page.getByRole('button', { name: 'ログアウト' }).click();

        await expect(page.locator('#login-screen')).toBeVisible();
        await expect(page.locator('#chat-screen')).toBeHidden();
    });

    test('存在しないページで404を検知できる', async ({ page }) => {
        const response = await page.goto('/public/not-found-e2e-check');
        expect(response?.status()).toBe(404);
    });
});
