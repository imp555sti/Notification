import { expect, test } from '@playwright/test';

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
        const nextShowAt = Date.now() + 24 * 60 * 60 * 1000;
        localStorage.setItem('notification_confirm_next_show_at', String(nextShowAt));

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

test.describe('Notification UI', () => {
    test('default時は通知未設定の導線を表示する', async ({ page }) => {
        const isIpadProject = test.info().project.name.includes('ipad');
        await installNotificationStub(page, { permission: 'default' });
        await mockApi(page);

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        if (isIpadProject) {
            await expect(page.locator('#notification-status')).toContainText('iOSはホーム画面に追加したPWAでのみ対応');
            await expect(page.locator('#notification-enable-btn')).toHaveText('PWA利用手順を表示');
            await expect(page.locator('#notification-help')).toContainText('ホーム画面に追加したPWA');
            return;
        }

        await expect(page.locator('#notification-status')).toHaveText('通知: 未設定');
        await expect(page.locator('#notification-enable-btn')).toHaveText('通知を有効化');
        await expect(page.locator('#notification-help')).toContainText('ボタンを押して許可');
    });

    test('denied時は設定解除導線を表示する', async ({ page }) => {
        await installNotificationStub(page, { permission: 'denied' });
        await mockApi(page);

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#notification-status')).toContainText('ブロック中');
        await expect(page.locator('#notification-enable-btn')).toHaveText('設定手順を表示');
        await expect(page.locator('#notification-help')).toContainText('解除が必要');
    });

    test('未対応ブラウザでは未対応表示になる', async ({ page }) => {
        await installNotificationStub(page, { unsupported: true });
        await mockApi(page);

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#notification-status')).toContainText('このブラウザは未対応');
        await expect(page.locator('#notification-enable-btn')).toHaveText('通知は未対応です');
        await expect(page.locator('#notification-enable-btn')).toBeDisabled();
    });

    test('iOS非PWAではPWA案内を表示する', async ({ page }) => {
        await installNotificationStub(page, {
            permission: 'default',
            userAgent:
                'Mozilla/5.0 (iPad; CPU OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
            standalone: false,
        });
        await mockApi(page);

        await page.goto('/public/index.php');
        await page.getByRole('button', { name: 'UserA' }).click();

        await expect(page.locator('#notification-status')).toContainText('iOSはホーム画面に追加したPWAでのみ対応');
        await expect(page.locator('#notification-enable-btn')).toHaveText('PWA利用手順を表示');
        await expect(page.locator('#notification-help')).toContainText('ホーム画面に追加したPWA');
    });
});
