これは [Antigravity](https://github.com/antigravity-dev/antigravity) による開発を試みた際の実際の出力結果です。


# 1:1 チャットアプリケーション

RHEL10 + Apache 2.4 + PHP 8.3 + PostgreSQL 16 環境で動作する 1:1 テキストチャット Web アプリケーションです。

## 技術スタック
- **サーバー**: Apache 2.4
- **言語**: PHP 8.3
- **データベース**: PostgreSQL 16
- **フロントエンド**: HTML, CSS, Vanilla JS
- **環境構築**: Docker, Docker Compose

## 機能一覧
1. **ユーザーログイン (簡易)**:
   - UserA, UserB, UserC の3ユーザーから選択してログインします。
2. **1:1 チャット**:
   - ユーザーを選択して、1対1でリアルタイム(Ajaxポーリング)にチャットが可能です。
3. **未読管理**:
   - 未読メッセージがあるユーザーにはバッジが表示されます。
4. **通知機能**:
   - ブラウザの Notification API を使用し、新着メッセージを通知します。
5. **メッセージ編集・削除**:
   - 自分の直近のメッセージを編集または削除できます。
   - 削除されたメッセージは「削除されました」と表示されます。
   - 編集されたメッセージには「(編集済み)」と表示されます。

## 環境構築と実行方法

### 必要要件
- Docker および Docker Compose

### 構築手順
1. プロジェクトのルートディレクトリではなく、`.docker` ディレクトリに移動、または `-f` オプションを使用して起動します。
   ```bash
   cd .docker
   docker-compose up -d
   ```
   またはルートから:
   ```bash
   docker-compose -f .docker/docker-compose.yml up -d
   ```
2. 初回起動時にデータベースの初期化が行われます。データは Docker Volume (`pgdata`) に永続化されます。

### アプリケーションへのアクセス
ブラウザで以下のURLにアクセスしてください。
`http://localhost:8081/public/index.php`

**注意**: ポート `8081` を使用しています (他プロジェクトとの競合回避のため)。

## ディレクトリ構成
```
/
├── .docker/           # Docker 関連ファイル (docker-compose.yml, Dockerfile, init.sql)
├── src/
│   ├── public/        # 公開用ディレクトリ
│   │   ├── api/       # API エンドポイント (Ajax用)
│   │   ├── assets/    # 静的ファイル (CSS, JS)
│   │   └── index.php  # メイン画面
│   └── lib/           # バックエンドロジック (DB接続, Service)
├── docs/              # ドキュメント (実装計画書, Taskリスト)
└── README.md
```

## コーディング規約
- **PHP**: PSR-12 ベース
- **言語**: 日本語 (コメント, PHPDoc, コミットメッセージ)


## その他

- **Implemantation_plan**: `docs/antigravity/brain/walkthrough.md` に実装計画書があります。
- **Taks**: `docs/antigravity/brain/tasks.md` にタスクリストがあります。
- **Walkthrough**: `docs/antigravity/brain/walkthrough.md` に実装の詳細な手順と検証結果があります。

- **Chat**: `docs/chat.md` にチャットの履歴があります。

- **Verification_report**: `docs\antigravity\browser_recordings\` に検証時のスクリーンショットがあります。


- **注意事項**: 本アプリケーションは学習目的で作成されており、本番環境での使用には適していません。セキュリティやスケーラビリティの強化が必要です。
