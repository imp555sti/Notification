# Unit 分析

## 対象
- src/lib/MessageService.php
- src/lib/Database.php

## 現状
- MessageService はビジネスロジックと永続化呼び出しの境界にあり、分岐の大半がこのクラスに集中する。
- Database は環境変数から DSN を組み立てて PDO を返す薄いクラスだが、接続失敗時の戻り値が null になる重要な責務がある。
- 既存 Unit テストは存在しない。

## 不足テスト
1. sendMessage: execute が true の場合に true を返すこと。
2. sendMessage: execute が false の場合に false を返すこと。
3. getMessages: user1 と user2 を双方向条件で bind し、fetchAll の結果をそのまま返すこと。
4. checkUpdates: last_check_time 未指定時に updates を空配列で返し、unread_count と timestamp を含むこと。
5. checkUpdates: last_check_time 指定時に更新一覧取得クエリを追加実行し、updates を返すこと。
6. markAsRead: sender_id、receiver_id、is_read=false 条件で execute すること。
7. editMessage: 自分のメッセージのみ更新する条件で content と user_id を bind すること。
8. deleteMessage: status を deleted にする更新を実行すること。
9. Database::__construct: 環境変数未設定時に既定値を使用すること。
10. Database::connect: PDOException 発生時に null を返すこと。

## 追加候補ケース
- testSendMessageReturnsTrueWhenStatementExecutes
- testSendMessageReturnsFalseWhenStatementFails
- testGetMessagesReturnsFetchedRowsInAscendingOrder
- testCheckUpdatesWithoutLastCheckTimeSkipsUpdateQuery
- testCheckUpdatesWithLastCheckTimeReturnsUnreadCountAndUpdates
- testMarkAsReadExecutesUnreadUpdateForPair
- testEditMessageUpdatesOnlyOwnedMessage
- testDeleteMessageMarksMessageAsDeleted
- testConnectUsesEnvironmentVariablesWhenProvided
- testConnectReturnsNullWhenPdoCreationFails

## 実装優先度
- 高: MessageService の全 public メソッド 8 ケース
- 中: Database の既定値と接続失敗
- 低: SQL 文字列の完全一致まで固定するテスト

## すぐ実装できる粒度
- tests/Unit/Lib/MessageServiceTest.php を作成し、PDO と PDOStatement のモックで public メソッド単位に分割する。
- tests/Unit/Lib/DatabaseTest.php を作成し、環境変数の切替と接続失敗時の null 戻りを検証する。
- MessageService では dataProvider よりも 1 メソッド 1 振る舞いで分け、失敗箇所を即判別できる名前にする。

## 優先度 高 の実装タスク
1. MessageService の sendMessage、getMessages、checkUpdates、markAsRead を先にテストする。
2. checkUpdates の last_check_time 有無で分岐する2ケースを必須にする。
3. editMessage と deleteMessage を追加し、更新系 API の下支えを固める。

## 参照ファイル
- src/lib/MessageService.php
- src/lib/Database.php
- tests/bootstrap.php
- composer.json