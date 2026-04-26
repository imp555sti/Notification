# 環境セットアップガイド

Docker を使用した開発環境の構築手順です。

## 📋 目次

1. [前提条件](#前提条件)
2. [初回セットアップ手順](#初回セットアップ手順)
3. [Docker環境の起動](#docker環境の起動)
4. [環境確認](#環境確認)
5. [トラブルシューティング](#トラブルシューティング)
6. [よくある質問](#よくある質問)

---

## 前提条件

### 必須ソフトウェア

| ソフトウェア | バージョン | 用途 |
|---|---|---|
| **Docker Desktop** | 最新版 | コンテナ実行環境 |
| **Git** | 2.x以上 | ソースコード管理 |
| **VSCode** | 最新版 | エディタ（推奨） |

### Windows環境の追加要件

- **WSL2**（Windows Subsystem for Linux 2）が有効
- Docker Desktop の設定で「Use WSL 2 based engine」を有効化

### macOS/Linux環境

- 追加要件なし（Docker Desktopインストールのみ）

---

## 初回セットアップ手順

### 1. リポジトリのクローン

```bash
# プロジェクトをクローン
git clone <repository-url>
cd PHPUnit

# ディレクトリ構造確認
ls -la
```

### 2. 環境変数ファイルの作成

```bash
# .env.example をコピー
cp .env.example .env

# .env ファイルを編集（必要に応じて）
# Windowsの場合: notepad .env
# macOS/Linuxの場合: nano .env
```

#### .env の主要設定項目

```env
# アプリケーション設定
APP_ENV=development           # 開発環境
APP_DEBUG=true                # デバッグモード有効
APP_NAME=PHPUnit Template     # アプリケーション名

# データベース設定
DB_HOST=postgres              # Docker コンテナ名
DB_PORT=5432                  # PostgreSQL ポート
DB_NAME=app_db                # データベース名
DB_USER=app_user              # ユーザー名
DB_PASSWORD=app_password      # パスワード（本番環境では必ず変更）

# セッション設定
SESSION_COOKIE_SECURE=false   # 開発環境ではfalse（本番はtrue）
SESSION_COOKIE_SAMESITE=Strict

# セキュリティ
CSRF_TOKEN_NAME=csrf_token
```

### 3. Dockerイメージのビルド

```bash
# イメージをビルド（初回のみ、5〜10分程度）
docker-compose build

# ビルド完了確認
docker images | grep phpunit
```

**出力例**:
```
phpunit-apache-php   latest   abc123def456   2 minutes ago   1.2GB
```

### 4. コンテナの起動

```bash
# バックグラウンドで起動
docker-compose up -d

# 起動確認
docker-compose ps
```

**正常な出力例**:
```
NAME                  STATE      PORTS
phpunit-apache-1      running    0.0.0.0:8080->80/tcp
phpunit-postgres-1    running    0.0.0.0:5432->5432/tcp
```

### 5. Composer パッケージのインストール

```bash
# Composer install（初回のみ）
docker exec phpunit-apache-1 composer install

# インストール成功確認
docker exec phpunit-apache-1 composer show
```

**重要**: `vendor/`フォルダは Git管理対象です（ホスティング環境制約のため）

### 6. データベース初期化の確認

データベースは自動的に初期化されます（`.docker/postgres/init.sql`が実行される）

```bash
# PostgreSQL コンテナに接続して確認
docker exec -it phpunit-postgres-1 psql -U app_user -d app_db

# テーブル一覧表示
\dt

# サンプルデータ確認
SELECT * FROM users;

# 終了
\q
```

**期待される出力**:
```
           List of relations
 Schema |   Name     | Type  |  Owner
--------+------------+-------+----------
 public | users      | table | app_user
 public | categories | table | app_user
```

---

## Docker環境の起動

### 起動

```bash
# コンテナ起動（バックグラウンド）
docker-compose up -d

# ログ確認（リアルタイム）
docker-compose logs -f

# 特定のサービスのログのみ
docker-compose logs -f apache-php
```

### 停止

```bash
# コンテナ停止（データは保持）
docker-compose stop

# コンテナ停止＋削除（データは保持）
docker-compose down

# コンテナ停止＋削除＋ボリューム削除（データも削除）
docker-compose down -v
```

### 再起動

```bash
# 全コンテナ再起動
docker-compose restart

# 特定のコンテナのみ再起動
docker-compose restart apache-php
```

---

## 環境確認

### 1. Webサーバーにアクセス

ブラウザで以下のURLを開く：

```
http://localhost:8080
```

**期待される表示**:
- プロジェクトダッシュボード
- 技術スタック情報
- APIサンプルリンク

### 2. PHPバージョン確認

```bash
docker exec phpunit-apache-1 php -v
```

**期待される出力**:
```
PHP 7.4.x (cli) (built: ...)
```

### 3. Apache設定確認

```bash
docker exec phpunit-apache-1 httpd -v
```

**期待される出力**:
```
Server version: Apache/2.4.x (Red Hat Enterprise Linux)
```

### 4. PostgreSQL接続確認

```bash
docker exec phpunit-postgres-1 psql -U app_user -d app_db -c "SELECT version();"
```

**期待される出力**:
```
PostgreSQL 12.12 on x86_64-pc-linux-musl, compiled by gcc ...
```

### 5. PHPUnit動作確認

```bash
# テスト実行
docker exec phpunit-apache-1 composer test
```

**期待される出力**:
```
PHPUnit 9.x.x by Sebastian Bergmann and contributors.

...                                                                 3 / 3 (100%)

Time: 00:00.123, Memory: 10.00 MB

OK (3 tests, 10 assertions)
```

### 6. カバレッジレポート生成確認

```bash
# カバレッジレポート生成
docker exec phpunit-apache-1 composer coverage

# HTMLレポート確認
# ブラウザで coverage/html/index.html を開く
```

---

## トラブルシューティング

### ポート衝突エラー

**症状**:
```
ERROR: for apache-php  Cannot start service apache-php: 
Ports are not available: listen tcp 0.0.0.0:8080: bind: address already in use
```

**原因**: ポート8080が既に使用されている

**解決方法1**: 使用中のプロセスを停止
```bash
# Windowsの場合
netstat -ano | findstr :8080
taskkill /PID <PID番号> /F

# macOS/Linuxの場合
lsof -i :8080
kill -9 <PID番号>
```

**解決方法2**: docker-compose.yml のポート番号変更
```yaml
services:
  apache-php:
    ports:
      - "8081:80"  # 8080 → 8081 に変更
```

### Composer installエラー

**症状**:
```
Fatal error: Allowed memory size of ... bytes exhausted
```

**解決方法**:
```bash
# メモリ制限を一時的に解除して実行
docker exec phpunit-apache-1 php -d memory_limit=-1 /usr/local/bin/composer install
```

### PostgreSQL接続エラー

**症状**:
```
SQLSTATE[08006] [7] could not connect to server: Connection refused
```

**原因**: PostgreSQLコンテナが起動していない、またはホスト名が間違っている

**解決方法**:
```bash
# PostgreSQLコンテナの状態確認
docker-compose ps postgres

# 起動していない場合
docker-compose up -d postgres

# .env のDB_HOST確認（"postgres"である必要がある）
cat .env | grep DB_HOST
```

### ファイル権限エラー（Linux環境）

**症状**:
```
Warning: file_put_contents(...): failed to open stream: Permission denied
```

**解決方法**:
```bash
# ログディレクトリに書き込み権限付与
sudo chmod -R 777 logs/
sudo chmod -R 777 coverage/

# または所有者変更
sudo chown -R $USER:$USER logs/ coverage/
```

### XDebugカバレッジエラー

**症状**:
```
No code coverage driver available
```

**解決方法**:
```bash
# XDebugインストール確認
docker exec phpunit-apache-1 php -m | grep xdebug

# 出力がない場合、Dockerイメージ再ビルド
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Windowsでの改行コードエラー

**症状**:
```
bash: ./script.sh: /bin/bash^M: bad interpreter
```

**解決方法**:
```bash
# Gitの改行コード設定確認
git config core.autocrlf

# true の場合、.gitattributes が正しく動作していない
# リポジトリを再クローン、または以下で修正：
git config core.autocrlf input
git rm --cached -r .
git reset --hard
```

---

## よくある質問

### Q1: vendor/ フォルダをGitにコミットする理由は？

**A**: プロダクション環境がホスティングサイトのため、Composerを実行できません。そのため、`vendor/`フォルダごとデプロイする必要があります。

### Q2: 開発中にコンテナを停止すべき？

**A**: 停止不要です。`docker-compose stop`で停止すると次回起動が遅くなります。メモリ節約が必要な場合のみ停止してください。

### Q3: データベースをリセットするには？

**A**: 以下のコマンドでボリュームを削除して再作成：
```bash
docker-compose down -v
docker-compose up -d
```

### Q4: PHPのエラーログはどこ？

**A**: コンテナのログで確認：
```bash
docker-compose logs apache-php
```

または、ブラウザに直接表示されます（`APP_DEBUG=true`の場合）

### Q5: VSCodeからDockerコンテナに接続できる？

**A**: はい。以下の拡張機能をインストール：
- **Remote - Containers** (ms-vscode-remote.remote-containers)

コンテナにアタッチ：
1. VSCodeのコマンドパレット（Ctrl+Shift+P）
2. 「Remote-Containers: Attach to Running Container...」
3. `phpunit-apache-1` を選択

### Q6: テストが遅い場合の対処法は？

**A**: 以下を確認：
1. WSL2を使用（Windowsの場合）
2. `docker-compose.yml`のボリュームマウントを`:cached`に設定
```yaml
volumes:
  - .:/var/www/html:cached  # :cached 追加
```
3. テストデータベースにSQLite in-memoryを使用（将来の最適化）

---

## セットアップチェックリスト

初回セットアップ完了確認：

- [ ] Docker Desktop インストール済み
- [ ] WSL2有効（Windowsの場合）
- [ ] リポジトリクローン完了
- [ ] `.env`ファイル作成完了
- [ ] `docker-compose build` 成功
- [ ] `docker-compose up -d` 成功
- [ ] `composer install` 成功
- [ ] http://localhost:8081 でアクセス可能
- [ ] PostgreSQL接続確認
- [ ] PHPUnitテスト実行成功
- [ ] カバレッジレポート生成成功

---

**次のステップ**:  
- [.docs/plans/development/coding-standards.md](../../.docs/plans/development/coding-standards.md) - コーディング規約  
- [.github/instructions/php.instructions.md](./php.instructions.md) - PHP実装ガイド  
- [.github/instructions/testing.instructions.md](./testing.instructions.md) - テスト実装ガイド
