---
applyTo: "src/**/*.js,src/**/*.html"
description: "クライアントサイドJS実装ガイド。PC版Chrome/Edge・Android版ブラウザ・iOS版Safariの互換性を守りたい時に参照"
---

# クライアントサイドJS 実装ガイド

対象ブラウザ：**PC版 Chrome / Edge、Android版 Chrome、iOS版 Safari**

---

## 1. ECMAScript バージョン方針

| 機能 | 使用可否 | 備考 |
|------|----------|------|
| `async/await` | ✅ | ES2017。全対象ブラウザ対応済み |
| `const` / `let` | ✅ | `var` 禁止 |
| アロー関数 | ✅ | |
| Optional Chaining `?.` | ✅ | Chrome85+/Edge85+/iOS14+ |
| Nullish Coalescing `??` | ✅ | Chrome80+/Edge80+/iOS14+ |
| `Array.at()` | ⚠️ | iOS15.4+。iOS14以下対応が必要なら `arr[arr.length-1]` を使う |
| トップレベル `await` | ❌ | ES Modules必須。現環境非対応 |
| `import` / `export` | ❌ | バンドラーなし環境では使用不可 |

```js
// ✅ 正しい
const items = data?.items ?? [];

// ❌ 避ける
var items = data && data.items ? data.items : [];
```

---

## 2. DOM操作

### イベント登録

```js
// ✅ 正しい — addEventListener を使う
element.addEventListener('click', handler);

// ❌ 禁止 — インライン属性イベントと onclick プロパティ代入
element.onclick = handler;
```

> **注意**: `onclick` 属性（`<span onclick="...">`）はやむを得ない場合のみ許容。  
> その場合は必ず `window.xxx` でグローバル関数を明示的に公開する。

### キーボードイベント

```js
// ✅ 正しい — keydown を使う（keypress は非推奨）
element.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
    }
});

// ❌ 非推奨
element.addEventListener('keypress', handler);
```

---

## 3. タッチ・ポインター操作（モバイル対応）

```js
// ✅ iOS/Android 両対応 — pointer events を優先
element.addEventListener('pointerdown', handler);

// モバイルのタップ遅延を防ぐ（CSS でも対応可）
// CSS: touch-action: manipulation;
```

- **300ms タップ遅延**: `touch-action: manipulation` をCSS側で設定すること
- `touchstart` / `touchend` は直接使わず `pointer events` を使う
- `hover` に依存したUI要素はモバイルで機能しない。`focus` / `active` で代替

---

## 4. Notification API — ブラウザ差異

| ブラウザ | 対応状況 | 条件 |
|---------|---------|------|
| PC Chrome / Edge | ✅ 完全対応 | ユーザー許可が必要 |
| Android Chrome | ✅ 対応 | ユーザー許可が必要 |
| iOS Safari 16.4+ | ⚠️ 限定対応 | **PWAとしてホーム画面追加後のみ**動作 |
| iOS Safari 16.3以前 | ❌ 非対応 | `"Notification" in window` が `false` |

```js
// ✅ 必須チェック — iOS未対応を考慮
if ("Notification" in window) {
    Notification.requestPermission().then((permission) => {
        if (permission === 'granted') {
            // 通知送信
        }
    });
}

// ✅ iOS PWA環境の検出（補助判定）
const isIosPwa = window.navigator.standalone === true;
```

- `Notification.requestPermission()` は **ユーザージェスチャー起点**で呼ぶこと  
  （iOS Safariはジェスチャーなしの自動呼び出しを拒否する）
- 通知が使えない環境向けに **UI上のバッジ表示など代替手段を必ず実装**する

---

## 5. Fetch API

```js
// ✅ 正しいパターン — エラーハンドリング込み
async function fetchData(url) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTPエラー: ${response.status}`);
        }
        return await response.json();
    } catch (error) {
        console.error('フェッチエラー:', error);
        throw error;
    }
}
```

- `fetch` はネットワークエラーのみ `reject` する。`4xx` / `5xx` は `response.ok` で判定すること
- POST送信時は必ず `Content-Type: application/json` ヘッダーを設定する

```js
// ✅ POST の正しいパターン
const response = await fetch('api/send.php', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ key: value }),
});
```

---

## 6. ビューポート・レイアウト（モバイル対応）

```css
/* ✅ iOS Safariのアドレスバー考慮 — 100vh は使わない */
.full-height {
    height: 100dvh; /* dvh = Dynamic Viewport Height (iOS15.4+) */
}

/* iOS15.3以前のフォールバック */
@supports not (height: 100dvh) {
    .full-height {
        height: calc(100vh - env(safe-area-inset-bottom));
    }
}
```

- `position: fixed` 要素はiOSでスクロール時に動くことがある。`transform` の親要素に注意
- `safe-area-inset-*` でiPhoneのノッチ・ホームバー領域を考慮する

---

## 7. XSS対策（必須）

```js
// ✅ 必須 — ユーザー入力をDOMに挿入する際は必ずエスケープ
function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
}

// ❌ 禁止 — innerHTML に生の文字列を渡す
element.innerHTML = userInput;

// ✅ 安全
element.textContent = userInput;
// または
element.innerHTML = `<span>${escapeHtml(userInput)}</span>`;
```

---

## 8. ポーリング実装

```js
// ✅ 正しいポーリングパターン
let pollingInterval = null;

function startPolling(intervalMs = 3000) {
    stopPolling(); // 二重起動防止
    pollingInterval = setInterval(async () => {
        try {
            await pollAction();
        } catch (e) {
            console.error('ポーリングエラー:', e);
        }
    }, intervalMs);
}

function stopPolling() {
    if (pollingInterval !== null) {
        clearInterval(pollingInterval);
        pollingInterval = null;
    }
}

// ✅ Page Visibility API でタブ非表示時に停止（バッテリー・通信節約）
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        stopPolling();
    } else {
        startPolling();
    }
});
```

---

## 9. 禁止事項

| 禁止 | 代替 |
|------|------|
| `document.write()` | `element.textContent` / `insertAdjacentHTML` |
| `eval()` | JSON.parse / Function コンストラクター禁止 |
| `var` | `const` / `let` |
| `keypress` イベント | `keydown` |
| `innerHTML` に非エスケープ文字列 | `textContent` / `escapeHtml()` |
| グローバル変数の乱用 | モジュールスコープ / クロージャ |

---

## 10. デバッグ・動作確認チェックリスト

- [ ] PC Chrome DevTools でコンソールエラーなし
- [ ] PC Edge で同様に動作確認
- [ ] Chrome DevTools の Device Mode（Android想定）でレイアウト崩れなし
- [ ] Chrome DevTools の Device Mode（iPhone想定）でレイアウト崩れなし
- [ ] Notification API: PC Chromeで許可ダイアログが表示される
- [ ] Notification API: 非対応環境でも代替UI（バッジ等）が機能する
- [ ] タップ操作で300msの遅延を感じない（`touch-action: manipulation` 設定済み）
- [ ] `visibilitychange` でポーリングが適切に停止・再開する
