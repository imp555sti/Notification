# 環境セットアップガイド

RHEL8相当(UBI8) + Apache2.4(prefork MPM) + PHP7.4(mod_php) + PostgreSQL12.12 開発環境の詳細セットアップ手順です。

## 目次

1. [前提条件](#前提条件)
2. [インストール手順](#インストール手順)
3. [環境変数設定](#環境変数設定)
4. [Docker環境の起動](#docker環境の起動)
5. [初回セットアップ](#初回セットアップ)
6. [トラブルシューティング](#トラブルシューティング)
7. [VSCode連携](#vscode連携)

---

## 前提条件

### 必須ソフトウェア

| ソフトウェア | 推奨バージョン | ダウンロード |
|---|---|---|
| **Docker Desktop** | 4.0以降 | https://www.docker.com/products/docker-desktop/ |
| **Git** | 2.30以降 | https://git-scm.com/downloads |
| **VSCode** (推奨) | 1.80以降 | https://code.visualstudio.com/ |

### システム要件

- **OS**: Windows 10/11, macOS 10.15以降, Linux（Ubuntu 20.04以降推奨）
- **メモリ**: 8GB以上（推奨16GB）
- **ディスク空き容量**: 10GB以上

---

## インストール手順

### 1. Docker Desktopのインストール

#### Windows

1. [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) をダウンロード
2. インストーラーを実行
3. WSL 2を有効化（推奨設定）
4. 再起動

**WSL 2設定確認**:
```powershell
wsl --list --verbose
```

出力例:
```
  NAME                   STATE           VERSION
* docker-desktop         Running         2
  docker-desktop-data    Running         2
```


---

### 2. プロジェクトのクローン

```bash
# プロジェクトをクローン
git clone <repository_url>
cd PHPUnit

# または既存ディレクトリで初期化
git init
```

---

### 3. Composerパッケージのインストール

Docker環境でComposerを実行します。

```bash
# Docker環境でComposerインストール
docker exec phpunit-apache-1 composer install --working-dir=/var/www/html
```

**開発環境の場合** (`--dev` オプションでPHPUnitもインストール):
```bash
docker compose run --rm apache-php composer install
```

---

## 環境変数設定

### .envファイルの作成

```bash
# テンプレートをコピー
cp .env.example .env
```

### .envファイルの編集

```bash
# Windows
notepad .env

# macOS/Linux
nano .env
```

**設定例**:
```ini
# アプリケーション設定
APP_NAME="PHPUnit Sample"
APP_ENV=development  # 本番環境では production
DEBUG=true           # 本番環境では false

# データベース接続（Docker Composeのサービス名を使用）
DB_HOST=db
DB_PORT=5432
DB_NAME=app_db
DB_USER=app_user
DB_PASS=app_password

# セッション設定
SESSION_LIFETIME=3600
```

**重要**: `.env` ファイルは `.gitignore` で管理対象外です。絶対にGitにコミットしないでください。

---

## Docker環境の起動

### 初回起動

```bash
# Dockerイメージをビルドしてコンテナを起動
docker compose up -d --build
```

**出力例**:
```
[+] Building 120.3s (15/15) FINISHED
[+] Running 3/3
 ✔ Network phpunit_default       Created
 ✔ Container phpunit-db-1        Started
 ✔ Container phpunit-apache-php-1  Started
```

### 起動確認

```bash
# コンテナの状態確認
docker compose ps
```

**正常時の出力**:
```
NAME                    IMAGE               STATUS
phpunit-apache-php-1    phpunit-apache-php  Up 10 seconds
phpunit-db-1            postgres:12-alpine  Up 10 seconds
```

### ログ確認

```bash
# すべてのコンテナのログをリアルタイム表示
docker compose logs -f

# 特定のコンテナのログのみ
docker compose logs -f apache-php
docker compose logs -f db
```

---

## 初回セットアップ

### 1. ブラウザでアクセス

```
http://localhost:8080/
```

「PHP開発環境テンプレート」ページが表示されれば成功です。

---

### 2. データベース初期化確認

PostgreSQLコンテナが起動時に `init.sql` を自動実行します。

**手動で確認する場合**:
```bash
# PostgreSQLコンテナに接続
docker compose exec db psql -U app_user -d app_db

# テーブル一覧表示
\dt

# サンプルデータ確認
SELECT * FROM users;

# 終了
\q
```

---

### 3. PHPUnitテストの実行

```bash
# テストを実行
docker compose exec apache-php vendor/bin/phpunit

# カバレッジレポート生成（HTML形式）
docker compose exec apache-php vendor/bin/phpunit --coverage-html coverage

# カバレッジレポートを開く（Windows）
start coverage/index.html

# カバレッジレポートを開く（macOS）
open coverage/index.html

# カバレッジレポートを開く（Linux）
xdg-open coverage/index.html
```

---

## トラブルシューティング

### ポート8080が既に使用中

**症状**:
```
Error response from daemon: Ports are not available: exposing port TCP 0.0.0.0:8080 -> 0.0.0.0:0: listen tcp 0.0.0.0:8080: bind: address already in use
```

**解決方法1**: ポート番号を変更

```yaml
# docker-compose.yml の ports セクション
services:
  apache-php:
    ports:
      - "8081:8080"  # UBI8/PHP-74 S2Iイメージは8080番ポートで起動
```

**解決方法2**: 既存プロセスを停止

```bash
# Windows
netstat -ano | findstr :8080
taskkill /PID <プロセスID> /F

# macOS/Linux
lsof -i :8080
kill -9 <プロセスID>
```

---

### データベース接続エラー

**症状**:
```
SQLSTATE[08006] [7] could not translate host name "db" to address: Name or service not known
```

**原因と解決策**:

1. **データベースコンテナが起動していない**
```bash
# コンテナ起動確認
docker compose ps

# 起動していない場合
docker compose up -d db
```

2. **.envの設定ミス**
```ini
# DB_HOSTはコンテナ名を指定
DB_HOST=db  # ← localhost ではない
```

3. **接続待機が必要**

データベースが完全に起動するまで数秒かかることがあります。
```bash
# 待機してから確認
sleep 5
docker compose exec apache-php php -r "echo 'DB Connected';"
```

---

### Composerインストールエラー

**症状**:
```
Your requirements could not be resolved to an installable set of packages.
```

**解決方法**:

```bash
# キャッシュをクリア
docker compose run --rm apache-php composer clear-cache

# 再インストール
docker compose run --rm apache-php composer install
```

---

### ファイル権限エラー（Linux）

**症状**:
```
Warning: file_put_contents(/var/www/html/logs/app.log): failed to open stream: Permission denied
```

**解決方法**:

```bash
# ログディレクトリの権限変更
docker compose exec apache-php chown -R apache:apache /var/www/html/logs
docker compose exec apache-php chmod -R 775 /var/www/html/logs
```

---

### XDebugカバレッジが生成されない

**症状**:
```
Error: No code coverage driver available
```

**解決方法**:

```bash
# XDebugがインストールされているか確認
docker compose exec apache-php php -m | grep xdebug

# php.iniでXDebugが有効化されているか確認
docker compose exec apache-php php -i | grep xdebug.mode

# XDebugモードを設定（docker-compose.ymlに追記）
environment:
  - XDEBUG_MODE=coverage
```

---

### WSL2でのパフォーマンス問題（Windows）

**症状**: ファイル変更の反映が遅い

**解決方法**: プロジェクトをWSL2内に配置

```bash
# WSL2に入る
wsl

# WSL内のホームディレクトリでクローン
cd ~
git clone <repository_url>
cd PHPUnit
docker compose up -d
```

---

## VSCode連携

### 推奨拡張機能

以下の拡張機能をインストールしてください:

1. **Dev Containers** (`ms-vscode-remote.remote-containers`)
   - Dockerコンテナ内で開発

2. **PHP Intelephense** (`bmewburn.vscode-intelephense-client`)
   - PHP補完・定義ジャンプ

3. **PHPUnit Test Explorer** (`recca0120.vscode-phpunit`)
   - テスト実行UI

4. **PHP Debug** (`xdebug.php-debug`)
   - XDebugデバッグ

---

### Dev Container設定

**.devcontainer/devcontainer.json** を作成:

```json
{
  "name": "PHP 7.4 Development",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "apache-php",
  "workspaceFolder": "/var/www/html",
  "customizations": {
    "vscode": {
      "extensions": [
        "bmewburn.vscode-intelephense-client",
        "recca0120.vscode-phpunit",
        "xdebug.php-debug"
      ]
    }
  },
  "forwardPorts": [8080, 5432]
}
```

**使用方法**:
1. VSCodeでプロジェクトを開く
2. `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. コンテナ内で開発が可能

---

### XDebugデバッグ設定

**.vscode/launch.json** を作成:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Listen for XDebug",
      "type": "php",
      "request": "launch",
      "port": 9003,
      "pathMappings": {
        "/var/www/html": "${workspaceFolder}"
      }
    }
  ]
}
```

**使用方法**:
1. VSCodeでブレークポイントを設定
2. F5キーでデバッグ開始
3. ブラウザで http://localhost:8080/ にアクセス

---

## 次のステップ

環境構築が完了したら、以下のドキュメントを参照してください:

- [コーディング規約](coding-standards.md)
- [テスト実行ガイド](testing.md)
- [APIエンドポイント](../api/endpoints.md)
- [セキュリティガイド](../security/best-practices.md)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
