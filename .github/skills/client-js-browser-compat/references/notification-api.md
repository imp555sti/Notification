# Notification API ブラウザ差異まとめ

## 対応状況

| 環境 | `"Notification" in window` | 許可ダイアログ | 通知表示 |
|------|---------------------------|--------------|---------|
| PC Chrome | ✅ | ✅ | ✅ |
| PC Edge | ✅ | ✅ | ✅ |
| Android Chrome | ✅ | ✅ | ✅ |
| iOS Safari 16.4+ (PWAのみ) | ✅ | ✅ | ✅ |
| iOS Safari 16.4+ (通常ブラウザ) | ✅ | ❌ | ❌ |
| iOS Safari 16.3以前 | ❌ | - | - |

## 実装パターン

### 基本の安全ガード

```js
function initNotification() {
    // iOS 16.3以前・一部Android対応外ブラウザの保護
    if (!("Notification" in window)) {
        console.info('このブラウザはNotification APIに対応していません');
        return false;
    }
    return true;
}
```

### ユーザージェスチャー起点での許可要求

```js
// ✅ ボタンのクリックハンドラー内など、ユーザー操作起点で呼ぶ
async function requestNotificationPermission() {
    if (!initNotification()) return 'unsupported';

    const permission = await Notification.requestPermission();
    return permission; // 'granted' | 'denied' | 'default'
}
```

### iOS PWA判定補助

```js
// iOS Safari でホーム画面追加済みPWAかどうか
const isIosPwa = window.navigator.standalone === true;

// ユーザーエージェントでiOSを判定（補助用）
const isIos = /iphone|ipad|ipod/i.test(navigator.userAgent);
```

### 通知 + 代替UI の組み合わせパターン

```js
async function notifyUser(title, body) {
    const canNotify = "Notification" in window 
        && Notification.permission === 'granted';

    if (canNotify) {
        new Notification(title, { body });
    } else {
        // 代替: バッジ表示・インジケーター更新など
        showInAppBadge(title);
    }
}
```

## 注意事項

- `Notification.requestPermission()` は **Promise 形式**で使うこと  
  （コールバック形式は非推奨）
- iOS Safari では **Service Workerを使わない** Notificationは動作しない  
  （PWAでも Service Worker 経由の Push Notification は別途対応が必要）
- Android WebView（アプリ内ブラウザ）は通知をブロックすることが多い
