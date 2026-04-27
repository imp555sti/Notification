import { expect, test } from '@playwright/test';

const COOLDOWN_KEY = 'notification_confirm_next_show_at';

type NotificationMode = {
    permission?: 'default' | 'granted' | 'denied';
    unsupported?: boolean;
    userAgent?: string;
    standalone?: boolean;
};

async function mockApi(page: import('@playwright/test').Page): Promise<void> {
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
}

async function installNotificationStub(
    page: import('@playwright/test').Page,
    mode: NotificationMode,
): Promise<void> {
    await page.addInitScript((params: NotificationMode) => {
        if (params.userAgent) {
            Object.defineProperty(window.navigator, 'userAgent', {
                value: params.userAgent,
                configurable: true,
            });
        }

        if (typeof params.standalone !== 'undefined') {
            Object.defineProperty(window.navigator, 'standalone', {
                value: params.standalone,
                configurable: true,
            });
        }

        if (params.unsupported) {
            try {
                delete (window as { Notification?: unknown }).Notification;
            } catch (e) {
                Object.defineProperty(window, 'Notification', {
                    value: undefined,
                    configurable: true,
                });
            }
            return;
        }

        let permissionState: 'default' | 'granted' | 'denied' = params.permission || 'default';

        class FakeNotification {
            public static get permission(): 'default' | 'granted' | 'denied' {
                return permissionState;
            }

            public static requestPermission(): Promise<'default' | 'granted' | 'denied'> {
                permissionState = 'granted';
                return Promise.resolve(permissionState);
            }

            public constructor(_title: string, _options?: unknown) {}
        }

        Object.defineProperty(window, 'Notification', {
            value: FakeNotification,
            configurable: true,
            writable: true,
        });
    }, mode);
}

test.describe('Notification Permission Modal', () => {
    test.beforeEach(async ({ page }) => {
        await mockApi(page);
    });

    test('default時に通知許可モーダルが表示される', async ({ page }) => {
        test.skip(test.info().project.name.includes('ipad'), 'iPad非PWAはモーダルを出さない仕様');

        await installNotificationStub(page, { permission: 'default' });
        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#notification-permission-modal')).toBeVisible();
        await expect(page.getByRole('button', { name: '受け取る' })).toBeVisible();
        await expect(page.getByRole('button', { name: '後で' })).toBeVisible();
    });

    test('後で選択時はモーダルを閉じ、再表示クールダウンを保存する', async ({ page }) => {
        test.skip(test.info().project.name.includes('ipad'), 'iPad非PWAはモーダルを出さない仕様');

        await installNotificationStub(page, { permission: 'default' });
        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await page.getByRole('button', { name: '後で' }).click();
        await expect(page.locator('#notification-permission-modal')).toBeHidden();

        const cooldown = await page.evaluate((key) => Number(localStorage.getItem(key) || '0'), COOLDOWN_KEY);
        expect(cooldown).toBeGreaterThan(Date.now());
    });

    test('受け取る選択時は通知状態が有効になる', async ({ page }) => {
        test.skip(test.info().project.name.includes('ipad'), 'iPad非PWAはモーダルを出さない仕様');

        await installNotificationStub(page, { permission: 'default' });
        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await page.getByRole('button', { name: '受け取る' }).click();

        await expect(page.locator('#notification-permission-modal')).toBeHidden();
        await expect(page.locator('#notification-status')).toHaveText('通知: 有効');
        await expect(page.locator('#notification-enable-btn')).toHaveText('通知は有効です');
        await expect(page.locator('#notification-enable-btn')).toBeDisabled();
    });

    test('iPad非PWAではdefaultでもモーダルを表示しない', async ({ page }) => {
        test.skip(!test.info().project.name.includes('ipad'), 'iPad専用シナリオ');

        await installNotificationStub(page, {
            permission: 'default',
            userAgent:
                'Mozilla/5.0 (iPad; CPU OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
            standalone: false,
        });
        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#notification-permission-modal')).toBeHidden();
        await expect(page.locator('#notification-status')).toContainText('iOSはホーム画面に追加したPWAでのみ対応');
    });
});
