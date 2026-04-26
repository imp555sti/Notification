# 実装テンプレート集

クライアントサイドJS でよく使うパターンのテンプレートです。

---

## 1. 安全な escapeHtml

```js
/**
 * XSS対策: HTMLエスケープ
 * @param {string} str
 * @returns {string}
 */
function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(String(str)));
    return div.innerHTML;
}
```

---

## 2. Fetch ラッパー（GET）

```js
/**
 * JSON取得ラッパー
 * @param {string} url
 * @returns {Promise<any>}
 */
async function fetchJson(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`HTTPエラー: ${response.status}`);
    }
    return response.json();
}
```

---

## 3. Fetch ラッパー（POST）

```js
/**
 * JSON送信ラッパー
 * @param {string} url
 * @param {object} data
 * @returns {Promise<any>}
 */
async function postJson(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    });
    if (!response.ok) {
        throw new Error(`HTTPエラー: ${response.status}`);
    }
    return response.json();
}
```

---

## 4. ポーリング管理

```js
let pollingTimer = null;

function startPolling(fn, intervalMs = 3000) {
    stopPolling();
    pollingTimer = setInterval(async () => {
        try {
            await fn();
        } catch (e) {
            console.error('ポーリングエラー:', e);
        }
    }, intervalMs);
}

function stopPolling() {
    if (pollingTimer !== null) {
        clearInterval(pollingTimer);
        pollingTimer = null;
    }
}

// Page Visibility API でタブ非表示時は停止
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        stopPolling();
    } else {
        startPolling(yourPollFunction);
    }
});
```

---

## 5. Notification API 初期化

```js
/**
 * 通知許可を要求する（ユーザージェスチャー起点で呼ぶ）
 * @returns {Promise<'granted'|'denied'|'default'|'unsupported'>}
 */
async function requestNotificationPermission() {
    if (!("Notification" in window)) {
        return 'unsupported';
    }
    return await Notification.requestPermission();
}

/**
 * 通知を送る（代替UIフォールバック付き）
 * @param {string} title
 * @param {string} body
 */
function sendNotification(title, body) {
    if ("Notification" in window && Notification.permission === 'granted') {
        new Notification(title, { body });
    } else {
        // 代替: アプリ内バッジ・インジケーター等
        updateInAppIndicator(title, body);
    }
}
```

---

## 6. キーボードイベント（Enter送信）

```js
// keydown を使う（keypress は非推奨）
inputElement.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
    }
});
```

---

## 7. iOS 100vh 問題の CSS 対策

```css
/* フル高さのコンテナ */
.full-screen {
    height: 100dvh; /* iOS15.4+ */
}

/* iOS14以下のフォールバック */
@supports not (height: 100dvh) {
    .full-screen {
        height: calc(100vh - env(safe-area-inset-bottom, 0px));
    }
}
```
