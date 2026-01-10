# 1:1 チャットアプリ実装計画

RHEL10 + Apache 2.4 + PHP 8.3 + PostgreSQL 16 を使用した、1:1 双方向テキストメッセージング Web アプリケーションの実装計画です。

## 技術スタック
- **OS**: RHEL10 (Docker コンテナでエミュレート、ベースは一般的に AlmaLinux や RockyLinux が使われますが、ここでは公式の PHP イメージ等をベースにします)
- **Web Server**: Apache 2.4
- **Language**: PHP 8.3 (PSR-12, 日本語 PHPDoc/コメント)
- **Database**: PostgreSQL 16
- **Frontend**: HTML5, CSS3, Vanilla JS (Ajax, Notification API)

## ユーザー確認事項
> [!IMPORTANT]
> - **認証について**: 今回の要件には「ログイン」機能の詳細が含まれていませんが、1:1 チャットを実現するためには「誰」が「誰」に送るかを識別する必要があります。簡易的なユーザー選択画面または固定のユーザーIDを使用する仕組みを実装します。
> - **ブラウザ通知**: ブラウザの通知許可が必要です。サイトにアクセスした際に許可を求めます。
> - **RHEL10対応**: Docker環境では完全にRHEL10と一致させることはライセンス等の関係で難しいため、機能的に同等な構成（PHP 8.3 + Apache + PostgreSQL 16）を目指します。

## 変更内容の提案

### ディレクトリ構成
```
/
├── .docker/
│   ├── php/
│   │   └── Dockerfile
│   └── db/
│       └── init.sql
├── src/
│   ├── public/         # ドキュメントルート
│   │   ├── index.php   # メイン画面
│   │   ├── api/        # API エンドポイント
│   │   │   ├── send.php
│   │   │   ├── fetch.php
│   │   │   ├── check.php
│   │   │   └── action.php (edit/delete)
│   │   ├── assets/
│   │   │   ├── css/
│   │   │   │   └── style.css
│   │   │   └── js/
│   │   │       └── app.js
│   └── lib/
│       ├── Database.php
│       └── MessageService.php
├── docker-compose.yml
└── README.md
```

### データベース設計 (PostgreSQL 16)
**users テーブル**
- `id`: SERIAL, PRIMARY KEY
- `name`: VARCHAR(50)

**messages テーブル**
- `id`: SERIAL, PRIMARY KEY
- `sender_id`: INTEGER (FK users.id)
- `receiver_id`: INTEGER (FK users.id)
- `content`: TEXT
- `is_read`: BOOLEAN (既読フラグ)
- `status`: VARCHAR(20) (active, edited, deleted)
- `created_at`: TIMESTAMP
- `updated_at`: TIMESTAMP

### バックエンド (PHP 8.3)
- **Database.php**: PDO を使用した DB 接続管理。
- **MessageService.php**: メッセージの保存、取得、更新、削除等のビジネスロジック。
- **API**: JSON 形式でデータを返すシンプルな API。

### フロントエンド
- **画面**: 左側にユーザーリスト（今回は簡易的に相手を選ぶ）、右側にチャットエリア。
- **Ajax**: `setInterval` で定期的に `api/check.php` を叩き、未読件数や新着メッセージ、ステータス変更（編集/削除）を確認。
- **通知**: 新規メッセージがある場合に `Notification API` を発火。
- **編集/削除**: 自分の直近のメッセージに対して操作可能。

## 検証計画

### 自動テスト
現状、単体テストフレームワークの導入は明記されていないため、重要なロジック確認用のシンプルなスクリプトを用意するか、手動確認を主とします。

### 手動検証
1. **Docker起動**: `docker-compose up` で環境が立ち上がるか。
2. **メッセージ送信**: ユーザーAからユーザーBへ送信し、DBに保存されるか。
3. **ポーリング受信**: ユーザーBの画面で自動的にメッセージが表示されるか。
4. **通知**: バックグラウンド（または別タブ）にいるときにデスクトップ通知が来るか。
5. **編集・削除**: 送信済みメッセージを編集・削除し、相手側の表示が更新されるか。
6. **未読管理**: 未読件数が正しく表示され、閲覧後に既読になるか。
