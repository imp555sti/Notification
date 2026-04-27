# ソース棚卸し

## 対象
- src/lib
- src/public
- tests

## 現状
- 実装の主軸は src/app ではなく src/lib と src/public にある。
- PHP の業務ロジックは Lib\MessageService と Lib\Database に集中している。
- HTTP 入口は src/public/index.php と src/public/api/*.php の4本で構成される。
- フロントエンドの主要導線は src/public/assets/js/app.js に集約されている。
- tests 配下には bootstrap.php のみがあり、Unit、Integration、E2E の実テストは未作成。
- phpunit.xml は tests/Unit、tests/Integration、tests/E2E を参照するが、対応ディレクトリが未整備。
- Playwright は tests/E2E を前提に設定済みで、Chrome、Android系Chromium、iPad WebKit の実行設定がある。

## src と tests の対応表
| 実装 | 役割 | 既存テスト | あるべき配置 | 状態 |
| --- | --- | --- | --- | --- |
| src/lib/Database.php | PostgreSQL 接続生成 | なし | tests/Unit/Lib/DatabaseTest.php | 未作成 |
| src/lib/MessageService.php | メッセージ送信・取得・更新・既読 | なし | tests/Unit/Lib/MessageServiceTest.php | 未作成 |
| src/public/api/send.php | 送信 API | なし | tests/Integration/Public/Api/SendEndpointTest.php | 未作成 |
| src/public/api/fetch.php | 履歴取得 API | なし | tests/Integration/Public/Api/FetchEndpointTest.php | 未作成 |
| src/public/api/check.php | 更新確認・既読 API | なし | tests/Integration/Public/Api/CheckEndpointTest.php | 未作成 |
| src/public/api/action.php | 編集・削除 API | なし | tests/Integration/Public/Api/ActionEndpointTest.php | 未作成 |
| src/public/index.php | 画面骨格 | なし | tests/E2E/chat-shell.spec.ts | 未作成 |
| src/public/assets/js/app.js | ログイン、チャット、通知、編集削除 UI | なし | tests/E2E/chat-flow.spec.ts | 未作成 |

## 不足テスト
- オートロード設定の妥当性を確認する最低限のブートストラップ検証がない。
- MessageService の分岐と SQL 実行結果の扱いを担保するテストがない。
- API のメソッド制約、必須パラメータ不足、失敗時ステータスコードの検証がない。
- 主要ユーザーフローであるログイン、送信、編集、削除、ログアウトの E2E がない。
- 通知 UI と 404 導線の E2E がない。

## 追加候補ケース
- tests/Unit/Lib/MessageServiceTest.php を最優先で追加する。
- tests/Unit/Lib/DatabaseTest.php で環境変数優先と接続失敗時の null 戻りを確認する。
- tests/Integration/Public/Api 配下で各エンドポイントを HTTP 単位で検証する。
- tests/E2E 配下でログインから送受信までの基本導線を追加する。
- tests/E2E 配下でログアウトと 404 を必須シナリオとして固定する。

## 実装優先度
- 高: MessageService 単体テスト、send/fetch/check/action の統合テスト、ログアウトと 404 を含む E2E 基本導線
- 中: Database 単体テスト、通知 UI 状態遷移の E2E
- 低: 時刻表示や細かな文言差分の回帰テスト

## 参照ファイル
- src/lib/Database.php
- src/lib/MessageService.php
- src/public/index.php
- src/public/api/send.php
- src/public/api/fetch.php
- src/public/api/check.php
- src/public/api/action.php
- src/public/assets/js/app.js
- tests/bootstrap.php
- phpunit.xml
- playwright.config.ts