# E2E 分析

## 対象
- src/public/index.php
- src/public/assets/js/app.js
- src/public/api/*.php
- playwright.config.ts

## 現状
- 画面はログイン画面とチャット画面の2面構成で、ユーザー選択後にチャット UI が表示される。
- 主要操作はユーザー選択、相手選択、履歴表示、送信、編集、削除、ログアウト、通知設定である。
- Playwright 設定は整っているが tests/E2E 配下に spec が存在しない。
- ブラウザ互換で重視されているのは Desktop Chrome、Android 系 Chromium、iPad Safari 系 WebKit である。

## 不足テスト
1. 初期表示でログイン画面が見え、チャット画面が hidden であること。
2. ユーザー選択後にチャット画面へ遷移し、現在ユーザー以外がサイドバーに表示されること。
3. 相手選択後に履歴取得 API が呼ばれ、チャットヘッダーが更新されること。
4. メッセージ送信後に入力欄がクリアされ、新しいメッセージが画面に表示されること。
5. 編集操作でモーダルが開き、保存後に編集済み表示が出ること。
6. 削除操作で confirm 後に削除済み表示へ変わること。
7. ログアウトでログイン画面へ戻り、ポーリング副作用が止まること。
8. 通知権限が default のとき、許可モーダルまたは設定導線が出ること。
9. Notification 未対応ブラウザで通知状態が未対応表示になること。
10. 404 ページへ遷移したときに適切に失敗を検知できること。

## 追加候補ケース
- chat-shell.spec.ts: 初期表示、ログイン、ログアウト、404 をまとめる。
- chat-flow.spec.ts: 相手選択、送信、編集、削除をまとめる。
- notification-ui.spec.ts: 通知未設定、拒否済み、未対応、iOS 非 PWA を状態差し替えで検証する。
- API は route.fulfill と route.fetch を使い分け、UI 契約に集中する。
- confirm と Notification は page.on と addInitScript でスタブし、環境差を吸収する。

## 実装優先度
- 高: ログイン、相手選択、送信、編集、削除、ログアウト、404
- 中: 通知権限 default と denied の表示差分
- 低: 時刻表示フォーマットやスクロール位置の細部

## すぐ実装できる粒度
- tests/E2E/chat-shell.spec.ts で初期表示、ログイン、ログアウト、404 を実装する。
- tests/E2E/chat-flow.spec.ts で fetch/send/action/check をモックし、送信から編集削除までを固定する。
- tests/E2E/notification-ui.spec.ts で Notification オブジェクトを差し替え、UI 文言とボタン状態を検証する。

## 優先度 高 の実装タスク
1. 初期表示とログイン遷移を最初に追加する。
2. ログアウトを必須シナリオとして固定する。
3. 404 を必須シナリオとして固定する。
4. 送信、編集、削除の一連のメッセージ操作を Chrome で先行実装する。
5. 安定後に Android 系 Chromium と iPad WebKit へプロジェクト横展開する。

## 参照ファイル
- src/public/index.php
- src/public/assets/js/app.js
- src/public/api/send.php
- src/public/api/fetch.php
- src/public/api/check.php
- src/public/api/action.php
- playwright.config.ts

## 実装ログ（2026-04-27）

### 追加したE2Eテスト
- tests/E2E/chat-shell.spec.ts
	- 初期表示（ログイン表示 / チャット非表示）
	- ログイン遷移（自分以外のユーザー表示）
	- ログアウトでログイン画面へ復帰
	- 404ページの検知
- tests/E2E/chat-flow.spec.ts
	- 相手選択後の送信
	- 編集モーダル経由の更新（編集済み表示）
	- confirm後の削除（削除済み表示）

### 実行結果
- コマンド: `npm run e2e:test:chrome -- tests/E2E`
- 結果: 5 passed

### 追加実装（通知UI）
- tests/E2E/notification-ui.spec.ts
	- default（通知未設定導線）
	- denied（設定解除導線）
	- unsupported（未対応表示）
	- iOS非PWA（PWA利用案内）
- tests/E2E/notification-permission-modal.spec.ts
	- default時の通知許可モーダル表示
	- 「後で」選択時のクールダウン保存
	- 「受け取る」選択時の通知有効化反映
	- iPad非PWAではモーダルを表示しないこと

 - tests/E2E/notification-delivery.spec.ts
	- 表示中チャット相手の更新では `new Notification(...)` が発火しない
	- 非アクティブ相手（未選択チャット）の更新では `new Notification(...)` が発火する

### デバイス横展開結果
- `npm run e2e:test:chrome -- tests/E2E/notification-ui.spec.ts` : 4 passed
- `npm run e2e:test:dtab -- tests/E2E/notification-ui.spec.ts` : 8 passed
- `npm run e2e:test:ipad -- tests/E2E/notification-ui.spec.ts` : 8 passed
- `npm run e2e:test:chrome -- tests/E2E/notification-permission-modal.spec.ts` : 3 passed / 1 skipped
- `npm run e2e:test:dtab -- tests/E2E/notification-permission-modal.spec.ts` : 6 passed / 2 skipped
- `npm run e2e:test:ipad -- tests/E2E/notification-permission-modal.spec.ts` : 2 passed / 6 skipped
- `npm run e2e:test:chrome -- tests/E2E/notification-delivery.spec.ts` : 2 passed

### 未対応（次フェーズ）
- Android系Chromium / iPad WebKit への横展開
- `document.hidden=true` 条件での通知発火検証（Playwrightで可視状態制御を含む）