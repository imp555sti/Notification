import { defineConfig, devices } from '@playwright/test';

const env = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env ?? {};
const baseURL = env.PLAYWRIGHT_BASE_URL || 'http://localhost:8081/public/index.php';

export default defineConfig({
  testDir: './tests/E2E',
  testMatch: /.*\.spec\.ts/,
  fullyParallel: true,
  forbidOnly: !!env.CI,
  retries: env.CI ? 2 : 0,
  workers: env.CI ? 1 : undefined,
  timeout: 30_000,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'tests/coverage/e2e-report' }],
  ],
  use: {
    baseURL,
    trace: 'on-first-retry',
    screenshot: 'on',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'desktop-chrome',
      use: {
        ...devices['Desktop Chrome'],
        channel: 'chrome',
      },
    },
    {
      name: 'dtab-d51f-portrait',
      use: {
        browserName: 'chromium',
        viewport: { width: 600, height: 960 },
        deviceScaleFactor: 2,
        isMobile: true,
        hasTouch: true,
        userAgent:
          'Mozilla/5.0 (Linux; Android 14; dtab d-51F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
      },
    },
    {
      name: 'dtab-d51f-landscape',
      use: {
        browserName: 'chromium',
        viewport: { width: 960, height: 600 },
        deviceScaleFactor: 2,
        isMobile: true,
        hasTouch: true,
        userAgent:
          'Mozilla/5.0 (Linux; Android 14; dtab d-51F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36',
      },
    },
    {
      name: 'ipad-os26-portrait',
      use: {
        ...devices['iPad Pro 11'],
        browserName: 'webkit',
        viewport: { width: 834, height: 1194 },
        userAgent:
          'Mozilla/5.0 (iPad; CPU OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
      },
    },
    {
      name: 'ipad-os26-landscape',
      use: {
        ...devices['iPad Pro 11 landscape'],
        browserName: 'webkit',
        viewport: { width: 1194, height: 834 },
        userAgent:
          'Mozilla/5.0 (iPad; CPU OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1',
      },
    },
  ],
});
