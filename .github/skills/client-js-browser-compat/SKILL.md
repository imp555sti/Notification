---
name: client-js-browser-compat
description: "クライアントサイドJSのブラウザ互換実装レビュー・修正。PC版Chrome/Edge、Android版Chrome、iOS版Safariを対象にした互換チェック、Notification API差異対応、タッチイベント、ビューポート問題の解消に使う"
argument-hint: "対象JSファイルまたは機能名（例: src/public/assets/js/app.js のNotification実装を確認）"
---

# クライアントサイドJS ブラウザ互換スキル

## 対象ブラウザ

| ブラウザ | バージョン目安 |
|---------|-------------|
| PC Chrome | 最新 -2 |
| PC Edge | 最新 -2 |
| Android Chrome | 最新 -2 |
| iOS Safari | iOS 14+ |

---

## When to Use

- JSコードをPC・Android・iOSで動かしたいとき
- Notification API / Fetch API の実装・レビューをするとき
- タッチ操作・タップ遅延・ビューポート問題を解消するとき
- モバイルでレイアウトが崩れているとき
- 新しいJS機能を追加する前に互換性を確認したいとき

---

## Procedure

### Step 1. 対象コードの読み込み

- 指定されたJSファイル（またはHTML内のscriptブロック）を読み込む
- イベントリスナー・API呼び出し・DOM操作を把握する

### Step 2. ブラウザ互換チェック（全項目を確認）

以下を[チェックリスト](./references/compat-checklist.md)に従って検査する：

1. **ECMAScript バージョン**
   - `var` 使用がないか → `const` / `let` へ
   - `keypress` 使用がないか → `keydown` へ
   - `import` / `export` がバンドラーなしで使われていないか

2. **Notification API**
   - `"Notification" in window` ガード漏れがないか
   - iOS Safari（PWA限定）の代替UIが実装されているか
   - ユーザージェスチャー起点で `requestPermission()` を呼んでいるか

3. **Fetch API**
   - `response.ok` チェックをしているか
   - POST時に `Content-Type` ヘッダーが設定されているか
   - try/catch によるエラーハンドリングがあるか

4. **タッチ・ポインター操作**
   - `onclick` / `touchstart` 直接指定がないか
   - CSS に `touch-action: manipulation` があるか

5. **ビューポート・レイアウト**
   - `100vh` をフル高さに使っていないか（iOS アドレスバー問題）
   - `safe-area-inset-*` が必要な箇所で使われているか

6. **XSS対策**
   - `innerHTML` にユーザー入力を直接渡していないか
   - `escapeHtml()` またはそれ相当の処理をしているか

7. **ポーリング（該当する場合）**
   - 二重起動防止（`clearInterval`）があるか
   - `visibilitychange` で停止・再開しているか

### Step 3. 問題箇所の列挙とレポート

- ブラウザ別の影響度（High/Medium/Low）を明示する
- 問題箇所のコード行を引用する

### Step 4. 修正実装

- Instructionsファイル [client-js.instructions.md](../../instructions/client-js.instructions.md) に従って修正する
- 互換性を壊さないように段階的に変更する
- 変更箇所にコメントで理由を日本語で記載する

### Step 5. 動作確認チェック

修正後、以下を確認するよう案内する：

```
□ PC Chrome DevToolsでコンソールエラーなし
□ Edge で同様の動作
□ DevTools Device Mode（iPhone/Android）でレイアウト確認
□ Notification許可ダイアログがPC Chromeで表示される
□ iOSで通知が使えない場合の代替UI（バッジ等）が動く
□ タップ時の300ms遅延がない
```

---

## 参考リソース

- [互換チェックリスト詳細](./references/compat-checklist.md)
- [Notification API 差異まとめ](./references/notification-api.md)
- [実装テンプレート集](./references/templates.md)
- [Instructions](../../instructions/client-js.instructions.md)
