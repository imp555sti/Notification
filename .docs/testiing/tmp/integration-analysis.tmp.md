# Integration 分析

## 対象
- src/public/api/send.php
- src/public/api/fetch.php
- src/public/api/check.php
- src/public/api/action.php
- src/lib/Database.php
- src/lib/MessageService.php

## 現状
- 各 API は superglobal と php://input を直接読み、Database と MessageService をその場で new している。
- エンドポイントは薄いが、HTTP メソッド判定、入力不足判定、サービス失敗時のステータス返却が分散している。
- DB 統合テストと HTTP 入口テストは未作成。

## 不足テスト
1. send.php: POST 以外で 405 と error JSON を返すこと。
2. send.php: 必須項目不足で 400 を返すこと。
3. send.php: service 成功時に success=true を返すこと。
4. fetch.php: user1_id または user2_id 不足で 400 を返すこと。
5. fetch.php: 正常時に messages 配列を返すこと。
6. check.php: mark_read=true 指定時に既読化を先行実行し、その後の結果を返すこと。
7. check.php: last_check_time ありで updates を返すこと。
8. action.php: action 不正時に 400 を返すこと。
9. action.php: edit 成功時に success=true を返すこと。
10. action.php: delete 失敗時に 500 を返すこと。

## 追加候補ケース
- End-to-end に近い HTTP レベルの統合として、各スクリプトを include 実行し output buffering でレスポンスを検証する。
- PostgreSQL を使える環境ではテスト用 messages と users を投入し、fetch/check/action の永続化整合性を確認する。
- service 失敗分岐は MessageService を差し替えにくいため、暫定的には DB 接続失敗または既知の無効入力で 500 経路を確認する。
- check.php の mark_read は副作用を持つため、既読前後で unread_count が変わることを確認する。
- action.php は edit と delete を別テストクラスに分けず、action パラメータごとの分岐としてまとめる。

## 実装優先度
- 高: send、fetch、check、action の HTTP ステータスと JSON 契約
- 中: 実 DB を使った既読・編集・削除の整合性
- 低: エラーメッセージ文言の完全一致

## すぐ実装できる粒度
- tests/Integration/Public/Api/SendEndpointTest.php
- tests/Integration/Public/Api/FetchEndpointTest.php
- tests/Integration/Public/Api/CheckEndpointTest.php
- tests/Integration/Public/Api/ActionEndpointTest.php
- いずれも $_SERVER、$_GET、php://input 相当の前処理を helper で統一する。

## 優先度 高 の実装タスク
1. send.php の 405、400、200 を先に固める。
2. fetch.php の 405、400、200 を追加し、履歴取得契約を固定する。
3. check.php の mark_read=true と last_check_time ありの2経路を検証する。
4. action.php の edit、delete、invalid action を分岐ごとに固定する。

## 参照ファイル
- src/public/api/send.php
- src/public/api/fetch.php
- src/public/api/check.php
- src/public/api/action.php
- src/lib/Database.php
- src/lib/MessageService.php
- phpunit.xml