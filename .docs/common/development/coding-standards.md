# コーディング規約

PSR-12準拠のPHP 7.4コーディング規約です。

## 目次

1. [基本原則](#基本原則)
2. [ファイル構成](#ファイル構成)
3. [命名規則](#命名規則)
4. [型宣言](#型宣言)
5. [コードフォーマット](#コードフォーマット)
6. [PHPDoc](#phpdoc)
7. [禁止事項](#禁止事項)
8. [ツール](#ツール)

---

## 基本原則

### PSR-12準拠

このプロジェクトは [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/) に準拠します。

### Strict Types

すべてのPHPファイルで `declare(strict_types=1)` を使用します。

```php
<?php
declare(strict_types=1);

namespace App\Controller;
```

---

## ファイル構成

### ファイルテンプレート

```php
<?php
/**
 * クラスの簡潔な説明
 *
 * @package App\Controller
 * @author Your Name
 */
declare(strict_types=1);

namespace App\Controller;

use App\Service\UserService;
use App\Helper\SecurityHelper;

/**
 * ユーザーコントローラー
 */
class UserController extends BaseController
{
    /**
     * ユーザーサービス
     *
     * @var UserService
     */
    private UserService $userService;

    /**
     * コンストラクタ
     *
     * @param UserService $userService
     */
    public function __construct(UserService $userService)
    {
        $this->userService = $userService;
    }

    // メソッド...
}
```

### インポート順序

1. PHP標準ライブラリ
2. サードパーティライブラリ
3. プロジェクト内クラス

```php
use PDO;                          // PHP標準
use PDOException;                 // PHP標準

use Vendor\Package\ClassName;     // サードパーティ

use App\Service\UserService;      // プロジェクト内
use App\Repository\UserRepository;
```

---

## 命名規則

### クラス名

**PascalCase**（単語の先頭を大文字）

```php
// ✅ Good
class UserController { }
class SecurityHelper { }
class BaseRepository { }

// ❌ Bad
class userController { }
class security_helper { }
```

### メソッド名

**camelCase**（最初の単語は小文字、以降は大文字）

```php
// ✅ Good
public function getUserById(int $id): ?User { }
public function createUser(array $data): array { }

// ❌ Bad
public function get_user_by_id(int $id): ?User { }
public function CreateUser(array $data): array { }
```

### プロパティ名

**camelCase**

```php
// ✅ Good
private UserService $userService;
private string $userName;

// ❌ Bad
private UserService $user_service;
private string $UserName;
```

### 定数

**UPPER_SNAKE_CASE**（すべて大文字、アンダースコア区切り）

```php
// ✅ Good
const MAX_LOGIN_ATTEMPTS = 5;
const SESSION_TIMEOUT = 3600;

// ❌ Bad
const maxLoginAttempts = 5;
const sessionTimeout = 3600;
```

### テーブル名・カラム名

**snake_case**（すべて小文字、アンダースコア区切り）

```sql
-- ✅ Good
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    email_address VARCHAR(255),
    created_at TIMESTAMP
);

-- ❌ Bad
CREATE TABLE Users (
    userId SERIAL PRIMARY KEY,
    emailAddress VARCHAR(255),
    createdAt TIMESTAMP
);
```

---

## 型宣言

### 必須ルール

すべてのメソッド引数と戻り値に型を宣言します。

```php
// ✅ Good
public function findById(int $id): ?User
{
    // ...
}

public function createUser(string $name, string $email): array
{
    // ...
}

// ❌ Bad（型宣言なし）
public function findById($id)
{
    // ...
}
```

### Nullable型

`null` を許容する場合は `?` を使用します。

```php
// ✅ Good
public function findByEmail(string $email): ?User
{
    // 見つからない場合はnullを返す
    return $user ?? null;
}

// ❌ Bad（@return でしか示していない）
/**
 * @return User|null
 */
public function findByEmail(string $email)
{
    return $user ?? null;
}
```

### Union型（PHP 8以降）

PHP 7.4では Union型は使用できません。`@param` と `@return` で示します。

```php
// PHP 7.4 の場合
/**
 * @param int|string $id
 * @return User|false
 */
public function find($id)
{
    // ...
}

// PHP 8 に移行後
public function find(int|string $id): User|false
{
    // ...
}
```

---

## コードフォーマット

### インデント

- **4スペース**（タブ不可）
- VSCodeの設定で自動変換

**.vscode/settings.json**:
```json
{
  "editor.insertSpaces": true,
  "editor.tabSize": 4
}
```

### 波括弧の配置

```php
// ✅ Good（PSR-12）
class ClassName
{
    public function methodName(): void
    {
        if ($condition) {
            // ...
        } else {
            // ...
        }
    }
}

// ❌ Bad
class ClassName {
    public function methodName(): void {
        if ($condition)
        {
            // ...
        }
        else
        {
            // ...
        }
    }
}
```

### 1行の長さ

- **推奨**: 80文字以内
- **最大**: 120文字

長い場合は改行します:

```php
// ✅ Good（改行して読みやすく）
$result = $this->userService->createUser(
    $name,
    $email,
    $password,
    $role
);

// ❌ Bad（長すぎる）
$result = $this->userService->createUser($name, $email, $password, $role);
```

---

## PHPDoc

### すべてのクラス・メソッドにPHPDocを記述

```php
/**
 * ユーザーを作成する
 *
 * @param string $name ユーザー名
 * @param string $email メールアドレス
 * @param string $password パスワード（平文）
 * @return array ['success' => bool, 'data' => array|null, 'errors' => array]
 * @throws \PDOException データベースエラー時
 */
public function createUser(string $name, string $email, string $password): array
{
    // ...
}
```

### PHPDocタグ

| タグ | 用途 | 例 |
|---|---|---|
| `@param` | 引数の説明 | `@param string $name ユーザー名` |
| `@return` | 戻り値の説明 | `@return User|null` |
| `@throws` | 例外の説明 | `@throws \PDOException` |
| `@var` | プロパティの型 | `@var UserService` |
| `@see` | 関連項目 | `@see SecurityHelper::escape()` |
| `@todo` | TODO項目 | `@todo PHP8移行時に Union型に変更` |

---

## 禁止事項

### 絶対に使用禁止

```php
// ❌ eval()
eval($code);

// ❌ extract()
extract($_POST);

// ❌ グローバル変数
global $db;

// ❌ mysql_* 関数（非推奨）
mysql_query("SELECT * FROM users");

// ❌ エラー制御演算子 @
$result = @file_get_contents($path);
```

### 使用非推奨

```php
// ⚠️ var_dump()（デバッグ時のみ、本番コードに残さない）
var_dump($data);

// ⚠️ die() / exit()（早期リターンを推奨）
die('Error');

// ⚠️ magic number（定数化推奨）
if ($attempts > 5) {  // ← 5 は何の数値?
    // 定数化する
    if ($attempts > self::MAX_LOGIN_ATTEMPTS) {
```

---

## ツール

### PHP_CodeSniffer（phpcs）

**インストール**:
```bash
composer require --dev squizlabs/php_codesniffer
```

**実行**:
```bash
# PSR-12チェック
vendor/bin/phpcs --standard=PSR12 app/

# 自動修正
vendor/bin/phpcbf --standard=PSR12 app/

# 特定ファイルのみ
vendor/bin/phpcs --standard=PSR12 src/src/app/Controller/UserController.php
```

**VSCode連携**: `.vscode/settings.json`
```json
{
  "phpcs.enable": true,
  "phpcs.standard": "PSR12",
  "editor.formatOnSave": true
}
```

---

### PHP CS Fixer

より厳密なフォーマット（将来導入予定）

```bash
composer require --dev friendsofphp/php-cs-fixer
```

**.php-cs-fixer.php**:
```php
<?php
$finder = PhpCsFixer\Finder::create()
    ->in(__DIR__ . '/app')
    ->name('*.php');

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
        'strict_param' => true,
        'array_syntax' => ['syntax' => 'short'],
    ])
    ->setFinder($finder);
```

---

### PHPStan（静的解析）

型安全性を向上（将来導入予定）

```bash
composer require --dev phpstan/phpstan

# レベル6でチェック
vendor/bin/phpstan analyse app/ --level=6
```

---

## コードレビューチェックリスト

### 提出前の確認事項

- [ ] `declare(strict_types=1)` がある
- [ ] すべてのメソッドに型宣言がある
- [ ] PHPDocが記述されている
- [ ] PSR-12準拠（`phpcs` でエラーなし）
- [ ] 禁止事項を使用していない
- [ ] マジックナンバーがない（定数化済み）
- [ ] テストが追加されている
- [ ] セキュリティチェックを実施（[security.instructions.md](../../.github/instructions/security.instructions.md) 参照）

---

### 自動チェックコマンド

```bash
# PSR-12チェック
vendor/bin/phpcs --standard=PSR12 app/

# テスト実行
vendor/bin/phpunit

# カバレッジ確認
vendor/bin/phpunit --coverage-text
```

---

## 参照ドキュメント

- [PSR-12: 拡張コーディングスタイルガイド](https://www.php-fig.org/psr/psr-12/)
- [.github/instructions/php.instructions.md](../../.github/instructions/php.instructions.md) - PHP実装詳細ガイド
- [PHP公式ドキュメント](https://www.php.net/manual/ja/)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
