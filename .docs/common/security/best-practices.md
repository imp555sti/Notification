# セキュリティベストプラクティス

OWASP Top 10 に基づくセキュリティ対策実装ガイドです。

## 目次

1. [概要](#概要)
2. [OWASP Top 10 対策](#owasp-top-10-対策)
3. [実装チェックリスト](#実装チェックリスト)
4. [セキュリティレビュー手順](#セキュリティレビュー手順)
5. [脆弱性対応フロー](#脆弱性対応フロー)
6. [定期監査](#定期監査)

---

## 概要

### セキュリティ原則

1. **多層防御（Defense in Depth）**: 複数のセキュリティ層で保護
2. **最小権限の原則（Least Privilege）**: 必要最小限の権限のみ付与
3. **セキュアデフォルト（Secure by Default）**: デフォルトで安全な設定
4. **入力は検証、出力はエスケープ**: すべての入出力で対策

---

## OWASP Top 10 対策

### 1. インジェクション攻撃

#### SQLインジェクション対策

**✅ 必須**: Prepared Statement使用

```php
// ✅ Good（Prepared Statement）
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);

// ❌ Bad（文字列連結）
$query = "SELECT * FROM users WHERE email = '$email'";
$pdo->query($query);
```

**設定確認**:
```php
// App\Config\Database クラスで設定済み
$pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);  // 必須
```

---

### 2. 認証の不備

#### パスワード管理

**✅ 必須**: bcryptでハッシュ化

```php
// パスワードハッシュ化
$hash = SecurityHelper::hashPassword($password);

// パスワード検証
if (SecurityHelper::verifyPassword($password, $hash)) {
    // 認証成功
}
```

**禁止事項**:
```php
// ❌ 平文保存
INSERT INTO users (password) VALUES ('password123');

// ❌ MD5/SHA1（脆弱）
$hash = md5($password);
$hash = sha1($password);
```

#### セッション管理

**✅ 必須**: 安全なセッション設定

```php
// src/app/bootstrap.php
session_set_cookie_params([
    'lifetime' => 3600,
    'path' => '/',
    'domain' => '',
    'secure' => true,      // HTTPS必須
    'httponly' => true,    // JavaScript無効化
    'samesite' => 'Strict' // CSRF対策
]);

// ログイン成功時にセッションID再生成
session_regenerate_id(true);
```

---

### 3. 機密データの露出

#### 環境変数管理

**✅ 必須**: `.env` でデータベース認証情報管理

```ini
# .env（.gitignoreで除外）
DB_HOST=db
DB_USER=app_user
DB_PASS=strong_password_here
```

**禁止事項**:
```php
// ❌ ハードコード
$pdo = new PDO('pgsql:host=db;dbname=app_db', 'app_user', 'password123');
```

#### エラーメッセージ

**✅ 必須**: 本番環境でエラー詳細を非表示

```php
// .env
APP_ENV=production
DEBUG=false

// src/src/app/bootstrap.php
if (getenv('APP_ENV') === 'production') {
    ini_set('display_errors', '0');
    error_reporting(0);
}
```

---

### 4. XML外部エンティティ（XXE）

このプロジェクトでは XML を使用していませんが、将来の追加時に注意:

```php
// XML使用時の設定
libxml_disable_entity_loader(true);  // PHP 8.0以降は不要
```

---

### 5. アクセス制御の不備

#### 認可チェック

```php
// ユーザー情報更新時の権限確認
public function updateUser(int $userId, array $data): array
{
    // 自分のデータまたは管理者のみ更新可能
    if ($_SESSION['user_id'] !== $userId && !$this->isAdmin()) {
        return [
            'success' => false,
            'error' => '権限がありません'
        ];
    }

    // ...
}
```

---

### 6. セキュリティ設定のミス

#### HTTPセキュリティヘッダー

**✅ 必須**: `.htaccess` で設定

```apache
# src/.htaccess
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"

# HTTPS強制（本番環境）
# Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
```

---

### 7. クロスサイトスクリプティング（XSS）

#### 出力エスケープ

**✅ 必須**: すべての出力で `SecurityHelper::escape()` 使用

```php
// ✅ Good
<h1><?= SecurityHelper::escape($user->getName()) ?></h1>
<div data-user="<?= SecurityHelper::escape($user->getEmail()) ?>"></div>

// ❌ Bad（エスケープなし）
<h1><?= $user->getName() ?></h1>
```

#### JavaScript内での出力

```php
// ✅ Good（JSON化）
<script>
const user = <?= json_encode($user->toArray(), JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;
</script>

// ❌ Bad
<script>
const userName = "<?= $user->getName() ?>";  // XSS脆弱性
</script>
```

---

### 8. 安全でないデシリアライゼーション

**禁止事項**:
```php
// ❌ unserialize()（信頼できないデータで使用禁止）
$data = unserialize($_POST['data']);

// ✅ JSON使用
$data = json_decode($_POST['data'], true);
```

---

### 9. 既知の脆弱性を持つコンポーネントの使用

#### Composerパッケージ更新

```bash
# 定期的に脆弱性チェック
docker compose exec apache-php composer audit

# 安全な更新
docker compose exec apache-php composer update --with-dependencies
```

---

### 10. 不十分なログとモニタリング

#### ログ記録

**✅ 推奨**: 重要な操作をログに記録

```php
// ログイン成功/失敗
error_log(sprintf(
    '[AUTH] Login %s for user %s from %s',
    $success ? 'SUCCESS' : 'FAILED',
    $email,
    $_SERVER['REMOTE_ADDR']
));

// データ変更
error_log(sprintf(
    '[USER] User %d updated by %d',
    $userId,
    $_SESSION['user_id']
));
```

**禁止事項**:
```php
// ❌ パスワードをログに記録
error_log("Password: $password");  // 絶対NG
```

---

## 実装チェックリスト

### コード提出前の必須確認

#### XSS対策
- [ ] すべての出力で `SecurityHelper::escape()` 使用
- [ ] JavaScript内での出力は `json_encode()` 使用
- [ ] HTMLタグを含む出力は `strip_tags()` または `htmlspecialchars()` 使用

#### CSRF対策
- [ ] すべてのPOST/PUT/DELETEで `requireCsrfToken()` 使用
- [ ] フォームに `csrf_token` を含める
- [ ] GETメソッドでデータ変更しない

#### SQLインジェクション対策
- [ ] Prepared Statement使用
- [ ] `PDO::ATTR_EMULATE_PREPARES = false` 設定
- [ ] 文字列連結でSQLを構築していない

#### 入力バリデーション
- [ ] `ValidationHelper::validate()` 使用
- [ ] 型宣言を使用（`int`, `string` など）
- [ ] 必須項目をチェック

#### パスワード管理
- [ ] `SecurityHelper::hashPassword()` でハッシュ化
- [ ] パスワード強度チェック（8文字以上、大小英数記号）
- [ ] パスワードをログに出力していない

#### セッション管理
- [ ] `httponly=true`, `samesite=Strict` 設定
- [ ] ログイン成功時に `session_regenerate_id(true)` 実行
- [ ] セッションタイムアウト設定

#### ファイルアップロード
- [ ] MIMEタイプチェック（`ValidationHelper::isAllowedMimeType()`）
- [ ] ファイルサイズ制限
- [ ] ファイル名のサニタイズ
- [ ] 実行可能ファイルを拒否

#### エラーハンドリング
- [ ] try-catchで例外を処理
- [ ] 本番環境でエラー詳細を非表示
- [ ] エラーログに詳細を記録

---

## セキュリティレビュー手順

### 自動チェック

```bash
# GitHub Copilot エージェント使用
# .github/agents/security-reviewer.agent.md を参照
```

### 手動レビュー

1. **入力箇所の確認**
   - `$_GET`, `$_POST`, `$_COOKIE`, `$_SERVER` の使用箇所
   - 外部APIからのデータ

2. **出力箇所の確認**
   - `echo`, `print`, PHPの短縮構文 `<?= ?>` の使用箇所
   - JavaScript内での変数埋め込み

3. **データベースクエリの確認**
   - `prepare()` と `execute()` の使用
   - `query()` や文字列連結の使用（禁止）

4. **ファイル操作の確認**
   - ユーザー指定のファイルパス
   - アップロード処理

5. **認証・認可の確認**
   - ログイン処理
   - 権限チェック

---

## 脆弱性対応フロー

### 脆弱性発見時

1. **報告**
   - GitHubで Issue を**非公開**で作成（Security Advisory使用）
   - 深刻度を評価（Critical/High/Medium/Low）

2. **緊急対応**（Critical/High）
   - 即座にパッチ作成
   - 本番環境に緊急デプロイ
   - 影響範囲を調査

3. **通常対応**（Medium/Low）
   - 次回リリースでパッチ適用
   - CHANGELOG.md に記載

---

### セキュリティアドバイザリー

**報告先**:
```
security@your-domain.com
```

**含めるべき情報**:
- 脆弱性の種類（XSS, SQLi, CSRF, etc.）
- 影響するバージョン
- 再現手順
- PoC（実証コード）
- 提案される修正方法

---

## 定期監査

### 月次チェック

- [ ] Composerパッケージ脆弱性チェック（`composer audit`）
- [ ] セキュリティヘッダーチェック（https://securityheaders.com/）
- [ ] SSL/TLS設定チェック（https://www.ssllabs.com/ssltest/）

### 四半期チェック

- [ ] 全コードのセキュリティレビュー
- [ ] ペネトレーションテスト（可能であれば）
- [ ] アクセスログ分析（不正アクセス検出）

### 年次チェック

- [ ] 外部セキュリティ監査
- [ ] OWASP Top 10最新版との対応確認
- [ ] セキュリティポリシー見直し

---

## ツール

### セキュリティスキャナー

```bash
# PHPCSのセキュリティ拡張
composer require --dev squizlabs/php_codesniffer
vendor/bin/phpcs --standard=Security app/

# 静的解析（PHPStan）
composer require --dev phpstan/phpstan
vendor/bin/phpstan analyse app/ --level=8
```

---

### Webアプリケーションスキャナー

- **OWASP ZAP**: https://www.zaproxy.org/
- **Nikto**: https://github.com/sullo/nikto
- **Burp Suite**: https://portswigger.net/burp

---

## 参照ドキュメント

- [OWASP Top 10 2021](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheet Series](https://cheatsheetseries.owasp.org/)
- [.github/instructions/security.instructions.md](../../.github/instructions/security.instructions.md) - セキュリティ実装詳細
- [PHP Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/PHP_Configuration_Cheat_Sheet.html)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
