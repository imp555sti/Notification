# デプロイ手順ガイド

ホスティング環境へのデプロイ手順と設定ガイドです。

## 📋 目次

1. [デプロイ前提条件](#デプロイ前提条件)
2. [デプロイ準備](#デプロイ準備)
3. [ファイル構成](#ファイル構成)
4. [WebGUIアップロード手順](#webguiアップロード手順)
5. [本番環境設定](#本番環境設定)
6. [デプロイ後の確認](#デプロイ後の確認)
7. [ロールバック手順](#ロールバック手順)
8. [トラブルシューティング](#トラブルシューティング)

---

## デプロイ前提条件

### ホスティング環境の制約

| 項目 | 制約内容 | 対応 |
|---|---|---|
| **アクセス可能フォルダ** | `src/` のみ | src/に全てを配置 |
| **シェルアクセス** | なし（WebGUIのみ） | vendor/をGit管理 |
| **Composer実行** | 不可 | vendor/含めてアップロード |
| **PHP実行** | 可能 | init.sql相当をPHPで実行 |

### 新しいファイル構成（ホスティング環境対応）

**重要**: すべてのファイルを `src/` 配下に配置し、`.htaccess` で保護します。

```
src/                          # ← ドキュメントルート（すべてここに配置）
├── .env                      # 環境変数（.htaccessで保護）
├── .htaccess                 # アクセス制御
├── composer.json             # Composer設定（.htaccessで保護）
├── composer.lock             # 依存関係ロック（.htaccessで保護）
├── vendor/                   # Composerパッケージ（.htaccessで保護）
├── app/                      # アプリケーションコード（.htaccessで保護）
│   ├── Config/
│   ├── Controller/
│   ├── Service/
│   ├── Repository/
│   ├── Entity/
│   ├── Helper/
│   └── bootstrap.php
├── error/                    # エラーページ（公開）
│   ├── 404.php
│   └── 500.php
└── index.php                 # エントリーポイント（公開）
```

### 必須アカウント情報

- ✅ FTP/SFTP接続情報（ホスト、ユーザー名、パスワード）
- ✅ データベース接続情報（ホスト、DB名、ユーザー、パスワード）
- ✅ ホスティング管理画面のログイン情報

---

## デプロイ準備

### 1. 本番ビルドの作成

```bash
# 最新のmainブランチを取得
git checkout main
git pull origin main

# Composerパッケージを最適化
docker exec phpunit-apache-1 composer install --no-dev --optimize-autoloader

# テスト実行（デプロイ前の最終確認）
docker exec phpunit-apache-1 composer test
```

### 2. 本番用.envファイルの準備

**重要**: `.env` は `src/.env` に配置します。

```bash
# src/.env.production を作成
cp src/.env src/.env.production

# または、ルートの .env.example から作成
cp .env.example src/.env.production
```

**.env.production の編集**:

```env
# 本番環境設定
APP_ENV=production            # ✅ production に変更
APP_DEBUG=false               # ✅ false に変更（エラー表示オフ）
APP_NAME=Your App Name        # ✅ アプリ名

# データベース設定（ホスティング提供の情報）
DB_HOST=your-db-host.com      # ✅ ホスティング提供のDBホスト
DB_PORT=5432
DB_NAME=your_production_db    # ✅ 本番DB名
DB_USER=your_db_user          # ✅ 本番DBユーザー
DB_PASSWORD=your_secure_pass  # ✅ 本番DBパスワード（強力なもの）

# セッション設定（本番環境）
SESSION_COOKIE_SECURE=true    # ✅ HTTPS必須
SESSION_COOKIE_SAMESITE=Strict
SESSION_COOKIE_HTTPONLY=true

# セキュリティ
CSRF_TOKEN_NAME=csrf_token
SECRET_KEY=<ランダム64文字>    # ✅ openssl rand -hex 32 で生成
```

**SECRET_KEY生成方法**:
```bash
# ランダムな秘密鍵生成
openssl rand -hex 32
```

### 3. 不要ファイルの除外リスト作成

デプロイ**しない**ファイル/フォルダ（開発環境のみ）:

```
.docker/
.vscode/
.idea/
tests/
.git/
.gitignore
docker-compose.yml
phpunit.xml
README.md
.docs/
.env.example          # 本番では不要（.envのみ）
```

**デプロイするもの**: `src/` ディレクトリ全体

---

## ファイル構成

### アップロード対象のディレクトリ構造

**アップロードするのは `src/` ディレクトリのみ**です。
node_modules/
.git/
.env
.env.example
docker-compose.yml
phpunit.xml
README.md
.gitignore
.gitattributes
composer.lock（オプション）
```

---

## ファイル構成

### アップロード対象のディレクトリ構造

```
production-upload/
├── src/                      # ✅ ドキュメントルート（必須）
│   ├── index.php
│   ├── .htaccess
│   ├── error/
│   │   ├── 404.php
│   │   └── 500.php
│   └── app/                  # ✅ アプリケーションコード
│       ├── Config/           # 設定クラス（App, Database）
│       ├── Controller/
│       ├── Service/
│       ├── Repository/
│       ├── Entity/
│       ├── Helper/
│       └── bootstrap.php
├── vendor/                   # ✅ Composerパッケージ（必須）
│   ├── autoload.php
│   ├── composer/
│   └── ... (全パッケージ)
└── .env                      # ✅ 本番環境変数（.env.productionをリネーム）
                              #    ※ ドキュメントルート外なのでWebから見えない（安全）
```

### ZIPアーカイブの作成

```bash
# 本番用.envを準備
cp src/.env.production src/.env

# src/ ディレクトリ全体をZIP化
# Windowsの場合:
# エクスプローラーで src/ を右クリック → 送る → 圧縮(zip形式)フォルダー

# macOS/Linuxの場合:
cd src/
zip -r ../deploy.zip . -x "*.git*" -x ".env.production"
cd ..

# ファイルサイズ確認
ls -lh deploy.zip
```

**重要**: 
- `src/.env.production` を `src/.env` にコピーしてからZIP化
- vendor/ ディレクトリが実ファイルとして含まれていることを確認（シンボリックリンクではなく）

---

## WebGUIアップロード手順

### ステップ1: ファイルマネージャーにアクセス

1. ホスティング管理画面にログイン
2. 「ファイルマネージャー」または「FTP」セクションを開く
3. アップロード先ディレクトリに移動（例: `/home/username/public_html/`）

### ステップ2: 既存ファイルのバックアップ

```
重要: 初回デプロイでない場合、必ずバックアップを取得
```

1. 既存のフォルダを選択
2. 「圧縮」または「アーカイブ」をクリック
3. `backup-YYYYMMDD-HHMMSS.zip` という名前で保存
4. バックアップをダウンロードして保管

### ステップ3: アップロード

**方法A: ZIP一括アップロード（推奨）**

1. 「アップロード」ボタンをクリック
2. `deploy.zip` を選択してアップロード（進捗表示を確認）
3. アップロード完了後、ZIPファイルを右クリック
4. 「展開」または「解凍」を選択
5. 展開先を確認して実行

**方法B: FTPクライアント使用**

FileZilla等のFTPクライアントを使用：

1. FTPクライアント設定
   - ホスト: `ftp.your-host.com`
   - ユーザー名: `your-username`
   - パスワード: `your-password`
   - ポート: 21（FTP）または 22（SFTP）

2. ローカル側: `src/` フォルダの**中身**を選択
3. リモート側: `/public_html/`（またはドキュメントルート）
4. ドラッグ&ドロップでアップロード

### ステップ4: ディレクトリ構成の確認

アップロード後のサーバー構成（`src/` の中身を `public_html/` に展開）:

```
/home/username/public_html/      # ← ドキュメントルート
├── .env                         # ← .htaccessで保護
├── .htaccess                    # ← アクセス制御
├── composer.json                # ← .htaccessで保護
├── composer.lock                # ← .htaccessで保護
├── vendor/                      # ← .htaccessで保護
├── app/                         # ← .htaccessで保護
│   ├── Config/
│   ├── Controller/
│   └── ...
├── error/                       # ← 公開OK（エラーページ）
│   ├── 404.php
│   └── 500.php
└── index.php                    # ← エントリーポイント（公開）
```

**確認ポイント**:
- ✅ `.htaccess` が存在する
- ✅ `.env` が存在する
- ✅ `vendor/` ディレクトリが存在する
- ✅ `app/` ディレクトリが存在する

---

## 本番環境設定

### 1. ドキュメントルートの設定

**重要**: ドキュメントルートは `/public_html/` のまま（変更不要）

すべてのファイルが `/public_html/` 直下に配置されるため、サーバー設定の変更は不要です。

### 2. PHPバージョンの設定

```
PHP 7.4 を選択（利用可能な場合）
```

**cPanel の場合**:
1. 「ソフトウェア」→「Select PHP Version」
2. PHP 7.4.x を選択
3. 「保存」

### 3. .htaccess の確認（重要）

`.htaccess` が正しくアップロードされ、以下の保護ルールが含まれていることを確認：

```apache
# ====================
# セキュリティ保護: 重要ファイル・ディレクトリへのアクセス拒否
# ====================

# .env ファイルへのアクセス拒否（最重要）
<FilesMatch "^\.env">
    Require all denied
</FilesMatch>

# composer関連ファイルへのアクセス拒否
<FilesMatch "^composer\.(json|lock)$">
    Require all denied
</FilesMatch>

# vendor ディレクトリへのアクセス拒否
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^vendor/ - [F,L]
</IfModule>

# app ディレクトリへの直接アクセス拒否（PHPファイルのみ）
<IfModule mod_rewrite.c>
    RewriteRule ^app/.*\.php$ - [F,L]
</IfModule>

# 隠しファイル全般へのアクセス拒否
<FilesMatch "^\.">
    Require all denied
</FilesMatch>

# エラーページ
ErrorDocument 404 /error/404.php
ErrorDocument 500 /error/500.php

# セキュリティヘッダー
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
</IfModule>
```

### 4. セキュリティテスト（必須）

ブラウザで以下のURLにアクセスし、すべて**403 Forbidden**または**404 Not Found**が表示されることを確認：

```
https://yourdomain.com/.env                → ❌ アクセス拒否
https://yourdomain.com/composer.json       → ❌ アクセス拒否
https://yourdomain.com/vendor/autoload.php → ❌ アクセス拒否
https://yourdomain.com/app/bootstrap.php   → ❌ アクセス拒否
https://yourdomain.com/                    → ✅ 正常表示
```
<FilesMatch "^\.">
    Require all denied
</FilesMatch>
```

### 4. データベース初期化

**init.sql相当の処理をPHPスクリプトで実行**:

`setup-db.php` を作成（一時的に `src/` にアップロード）:

```php
<?php
require_once __DIR__ . '/../vendor/autoload.php';

// .env読み込み
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

try {
    $db = new PDO(
        "pgsql:host={$_ENV['DB_HOST']};port={$_ENV['DB_PORT']};dbname={$_ENV['DB_NAME']}",
        $_ENV['DB_USER'],
        $_ENV['DB_PASSWORD']
    );
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // usersテーブル作成
    $db->exec("
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100) NOT NULL,
            email VARCHAR(255) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            status VARCHAR(20) DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    ");
    
    // updated_atトリガー作成
    $db->exec("
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $$ language 'plpgsql';
        
        DROP TRIGGER IF EXISTS update_users_updated_at ON users;
        CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    ");
    
    echo "データベース初期化完了";
} catch (PDOException $e) {
    echo "エラー: " . $e->getMessage();
}
```

**実行方法**:
```
1. ブラウザで https://your-domain.com/setup-db.php にアクセス
2. "データベース初期化完了" と表示されることを確認
3. 完了後、setup-db.php を必ず削除（セキュリティリスク）
```

### 5. ファイル権限の設定

以下のフォルダに書き込み権限が必要:

```bash
logs/          # 644 または 755
uploads/       # 755 (ファイルアップロード機能がある場合)
```

**cPanel ファイルマネージャーの場合**:
1. フォルダを右クリック→「パーミッション」
2. `755` (rwxr-xr-x) に設定
3. 保存

---

## デプロイ後の確認

### 1. トップページアクセス

```
https://your-domain.com/
```

**期待される表示**: ダッシュボード画面

### 2. エラーログ確認

ホスティング管理画面で以下を確認:

```
エラーログの場所（例）:
/home/username/logs/error_log
/var/log/httpd/error_log
```

**エラーがないこと**を確認。

### 3. データベース接続確認

PHPでDB接続テスト（一時ファイル作成）:

```php
<?php
// db-test.php (一時的に src/ に配置)
require_once __DIR__ . '/vendor/autoload.php';

use App\Config\Database;

try {
    $db = Database::getConnection();
    $version = $db->query('SELECT version()')->fetchColumn();
    echo "DB接続成功: {$version}";
} catch (PDOException $e) {
    echo "DB接続失敗: " . $e->getMessage();
}
```

ブラウザでアクセス: `https://your-domain.com/db-test.php`

**確認後、db-test.php を必ず削除**

### 4. 機能テスト

- [ ] トップページ表示
- [ ] APIエンドポイント動作(`?action=api&endpoint=users`)
- [ ] システム情報表示(`?action=info`)
- [ ] 404エラーページ表示（存在しないURLアクセス）
- [ ] CSRF トークン生成確認（フォーム表示時）

---

## ロールバック手順

デプロイ後に問題が発生した場合の復旧手順:

### 方法1: バックアップからの復元

1. ホスティング管理画面のファイルマネージャーにアクセス
2. バックアップZIP（`backup-YYYYMMDD-HHMMSS.zip`）をアップロード
3. ZIPを展開
4. 既存ファイルを上書き
5. ブラウザでアクセス確認

### 方法2: Gitタグからの再デプロイ

```bash
# 前回のリリースタグに戻る
git checkout v1.0.0

# 再度デプロイ用ZIPを作成
# ... (デプロイ準備の手順と同じ)
```

### 緊急時: メンテナンスモード

`src/index.php` の先頭に以下を追加:

```php
<?php
// メンテナンスモード
die('現在メンテナンス中です。しばらくお待ちください。');
```

---

## トラブルシューティング

### 500 Internal Server Error

**原因1**: .htaccess の構文エラー

**解決**: .htaccess を一時的にリネームして確認
```bash
.htaccess → .htaccess.bak
```

**原因2**: PHPバージョン不一致

**解決**: ホスティング管理画面でPHP 7.4を選択

**原因3**: ファイル権限エラー

**解決**: logs/ フォルダを755に設定

---

### データベース接続エラー

**症状**:
```
SQLSTATE[08006] [7] could not connect to server
```

**確認項目**:
- [ ] .env の DB_HOST が正しい
- [ ] .env の DB_NAME が正しい
- [ ] .env の DB_USER が正しい
- [ ] .env の DB_PASSWORD が正しい
- [ ] DB_PORT が正しい（PostgreSQL: 5432）

**デバッグ方法**:
```php
<?php
// debug-db.php
echo '<pre>';
echo 'DB_HOST: ' . ($_ENV['DB_HOST'] ?? 'NOT SET') . "\n";
echo 'DB_NAME: ' . ($_ENV['DB_NAME'] ?? 'NOT SET') . "\n";
echo 'DB_USER: ' . ($_ENV['DB_USER'] ?? 'NOT SET') . "\n";
echo '</pre>';
```

---

### vendor/ フォルダが見つからない

**症状**:
```
Warning: require(vendor/autoload.php): failed to open stream
```

**原因**: ZIPアップロード時に vendor/ が除外された

**解決**: 
1. ローカルで vendor/ フォルダの存在を確認
2. ZIP圧縮時に vendor/ が含まれているか確認
3. 再度ZIPを作成してアップロード

---

### CSRF Token Mismatch

**症状**:
```
403 Forbidden - CSRF token mismatch
```

**原因**: セッションが動作していない、またはCookieが保存されない

**解決**:
1. `.env` の `SESSION_COOKIE_SECURE` を確認:
   - HTTPS環境: `true`
   - HTTP環境: `false` (開発環境のみ)

2. ブラウザのCookie設定を確認（サードパーティCookieブロック無効化）

---

## デプロイチェックリスト

### デプロイ前

- [ ] テスト全件成功（`composer test`）
- [ ] カバレッジ75%以上達成
- [ ] .env.production作成（APP_DEBUG=false）
- [ ] SECRET_KEY生成
- [ ] バックアップ取得（既存環境）
- [ ] デプロイ用ZIP作成
- [ ] vendor/フォルダ含まれる確認

### デプロイ中

- [ ] ZIPアップロード完了
- [ ] ZIP展開完了
- [ ] ドキュメントルート設定（`src/`）
- [ ] PHPバージョン設定（7.4）
- [ ] データベース初期化実行
- [ ] ファイル権限設定（logs: 755）

### デプロイ後

- [ ] トップページ表示確認
- [ ] エラーログ確認（エラーなし）
- [ ] データベース接続確認
- [ ] API動作確認
- [ ] セキュリティヘッダー確認
- [ ] 一時ファイル削除（setup-db.php, db-test.php等）

---

**参照**:  
- [.github/instructions/setup.instructions.md](./setup.instructions.md) - 環境セットアップ  
- [.github/instructions/security.instructions.md](./security.instructions.md) - セキュリティ設定
