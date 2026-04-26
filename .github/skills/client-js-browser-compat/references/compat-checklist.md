# ブラウザ互換チェックリスト

コードレビュー・実装時に使うチェックリストです。  
Stepごとに ✅ / ❌ / ⚠️ で記録してください。

---

## A. ECMAScript 互換性

| # | チェック項目 | iOS14+ | Android | PC |
|---|------------|--------|---------|-----|
| A1 | `var` を使っていない | ✅ | ✅ | ✅ |
| A2 | `keypress` を使っていない（`keydown` を使う） | ✅ | ✅ | ✅ |
| A3 | Optional Chaining `?.` を使う場合はiOS14+前提 | ✅ | ✅ | ✅ |
| A4 | `Array.at()` を使う場合はiOS15.4+前提（必要なら代替）| ⚠️ | ✅ | ✅ |
| A5 | `import/export` をバンドラーなしで使っていない | ✅ | ✅ | ✅ |

---

## B. Notification API

| # | チェック項目 | iOS | Android | PC |
|---|------------|-----|---------|-----|
| B1 | `"Notification" in window` のガードがある | ✅ | ✅ | ✅ |
| B2 | `requestPermission()` はユーザージェスチャー起点 | 必須 | 推奨 | 推奨 |
| B3 | 通知が使えない環境向け代替UIがある | 必須 | - | - |
| B4 | `Notification.permission === 'granted'` を確認してから送信 | ✅ | ✅ | ✅ |

---

## C. Fetch API

| # | チェック項目 |
|---|------------|
| C1 | `response.ok` で HTTPステータスを確認している |
| C2 | `try/catch` でネットワークエラーを捕捉している |
| C3 | POST時に `Content-Type: application/json` を設定している |
| C4 | レスポンスが `json()` でパースできない場合を考慮している |

---

## D. タッチ・ポインター操作

| # | チェック項目 | iOS | Android |
|---|------------|-----|---------|
| D1 | `addEventListener` でイベント登録（インラインonclick最小化）| ✅ | ✅ |
| D2 | CSS に `touch-action: manipulation` がある（タップ遅延防止）| 必須 | 推奨 |
| D3 | `hover` のみに依存したUIがない | 必須 | 必須 |
| D4 | `pointer events` を `touch events` より優先している | ✅ | ✅ |

---

## E. ビューポート・レイアウト

| # | チェック項目 | iOS |
|---|------------|-----|
| E1 | フル高さに `100vh` を使っていない（`100dvh` または代替）| 必須 |
| E2 | ノッチ・ホームバー領域に `safe-area-inset-*` を使っている | 推奨 |
| E3 | `position: fixed` 要素が `transform` の子孫になっていない | 確認 |

---

## F. セキュリティ（XSS）

| # | チェック項目 |
|---|------------|
| F1 | `innerHTML` にユーザー入力を直接渡していない |
| F2 | `escapeHtml()` 相当の関数を使っている |
| F3 | `eval()` / `document.write()` を使っていない |
| F4 | `innerHTML` に動的コンテンツを入れる場合は `DOMPurify` 等を検討 |

---

## G. ポーリング（該当する場合）

| # | チェック項目 |
|---|------------|
| G1 | `clearInterval` で二重起動を防止している |
| G2 | `visibilitychange` でタブ非表示時に停止している |
| G3 | エラー時もポーリングが継続するよう try/catch がある |
| G4 | ページ離脱時（`beforeunload`）にポーリングを停止している |
