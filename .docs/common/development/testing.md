# テスト実行ガイド

PHPUnit 9.x によるテスト実行とカバレッジレポート生成のガイドです。

## 目次

1. [概要](#概要)
2. [テスト実行方法](#テスト実行方法)
3. [カバレッジレポート](#カバレッジレポート)
4. [テスト作成ガイド](#テスト作成ガイド)
5. [CI/CD統合](#cicd統合)
6. [トラブルシューティング](#トラブルシューティング)

---

## 概要

### テストフレームワーク

- **PHPUnit**: 9.5系（PHP 7.4互換）
- **XDebug**: 3.x（カバレッジモード）
- **目標カバレッジ**: 75%以上

### テスト構成

```
tests/
├── bootstrap.php              # テスト初期化
├── Unit/                      # 単体テスト
│   ├── Helper/
│   │   ├── SecurityHelperTest.php
│   │   └── ValidationHelperTest.php
│   └── Entity/
│       └── UserTest.php
├── Service/                   # Serviceテスト
├── Repository/                # Repositoryテスト
└── Controller/                # Controllerテスト
```

---

## テスト実行方法

### 基本コマンド

```bash
# すべてのテストを実行
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml

# 特定のテストスイートを実行
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --testsuite=Unit
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --testsuite=Service
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --testsuite=Repository
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --testsuite=Controller

# 特定のファイルのみ実行
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Unit/Helper/SecurityHelperTest.php

# 特定のテストメソッドのみ実行
docker exec phpunit-apache-1 vendor/bin/phpunit --filter testEscapeHtml
```

---

### 出力オプション

```bash
# 詳細出力
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --verbose

# カラー出力
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --colors=always

# テストケース名を表示
docker exec phpunit-apache-1 vendor/bin/phpunit --configuration=/var/www/phpunit.xml --testdox
```

**出力例**:
```
PHPUnit 9.5.28 by Sebastian Bergmann and contributors.

SecurityHelper
 ✔ Escape html
 ✔ Escape javascript
 ✔ Generate csrf token
 ✔ Verify csrf token valid
 ✔ Verify csrf token invalid
 ✔ Hash password
 ✔ Verify password correct
 ✔ Verify password wrong
 ✔ Sanitize string
 ✔ Sanitize email

Time: 00:00.125, Memory: 8.00 MB

OK (10 tests, 15 assertions)
```

---

## カバレッジレポート

### HTML形式（推奨）

```bash
# HTMLレポート生成
docker compose exec apache-php vendor/bin/phpunit --coverage-html coverage

# レポートを開く（Windows）
start coverage/index.html

# レポートを開く（macOS）
open coverage/index.html

# レポートを開く（Linux）
xdg-open coverage/index.html
```

**レポート内容**:
- ディレクトリごとのカバレッジ
- ファイルごとのカバレッジ
- 行ごとのカバレッジ（緑=実行済み、赤=未実行）

---

### テキスト形式（CLI）

```bash
# テキスト形式でカバレッジ表示
docker compose exec apache-php vendor/bin/phpunit --coverage-text
```

**出力例**:
```
Code Coverage Report:
  2026-02-11 10:00:00

 Summary:
  Classes: 80.00% (8/10)
  Methods: 75.50% (62/82)
  Lines:   78.30% (450/575)

App\Helper\SecurityHelper
  Methods: 100.00% (10/10)
  Lines:   100.00% (45/45)

App\Entity\User
  Methods: 100.00% (12/12)
  Lines:   100.00% (30/30)

App\Repository\UserRepository
  Methods:  80.00% (8/10)
  Lines:    82.50% (66/80)
```

---

### Clover形式（CI用）

```bash
# Clover XML生成
docker compose exec apache-php vendor/bin/phpunit --coverage-clover coverage.xml
```

---

## テスト作成ガイド

### 基本テンプレート

```php
<?php
/**
 * UserService テストケース
 */
declare(strict_types=1);

namespace Tests\Service;

use PHPUnit\Framework\TestCase;
use App\Service\UserService;
use App\Repository\UserRepository;
use App\Entity\User;

class UserServiceTest extends TestCase
{
    /**
     * UserServiceインスタンス
     *
     * @var UserService
     */
    private UserService $userService;

    /**
     * UserRepositoryモック
     *
     * @var UserRepository|\PHPUnit\Framework\MockObject\MockObject
     */
    private $userRepositoryMock;

    /**
     * 各テスト前に実行
     *
     * @return void
     */
    protected function setUp(): void
    {
        parent::setUp();

        // Repositoryモック作成
        $this->userRepositoryMock = $this->createMock(UserRepository::class);

        // Serviceインスタンス作成
        $this->userService = new UserService($this->userRepositoryMock);
    }

    /**
     * ユーザー取得テスト
     *
     * @return void
     */
    public function testGetUserById(): void
    {
        // Arrange（準備）
        $userId = 1;
        $expectedUser = new User();
        $expectedUser->fromArray([
            'id' => $userId,
            'name' => '山田太郎',
            'email' => 'yamada@example.com'
        ]);

        $this->userRepositoryMock
            ->expects($this->once())
            ->method('find')
            ->with($userId)
            ->willReturn($expectedUser);

        // Act（実行）
        $result = $this->userService->getUserById($userId);

        // Assert（検証）
        $this->assertInstanceOf(User::class, $result);
        $this->assertEquals($userId, $result->getId());
        $this->assertEquals('山田太郎', $result->getName());
    }
}
```

---

### モック作成

#### 基本的なモック

```php
// モック作成
$mock = $this->createMock(UserRepository::class);

// メソッドの戻り値を設定
$mock->method('find')->willReturn($user);

// 特定の引数で呼ばれることを期待
$mock->expects($this->once())
    ->method('find')
    ->with(1)
    ->willReturn($user);
```

#### 複数回呼ばれるモック

```php
$mock->expects($this->exactly(3))
    ->method('findAll')
    ->willReturn([$user1, $user2, $user3]);
```

#### 例外をスローするモック

```php
$mock->method('find')
    ->willThrowException(new \PDOException('Database error'));
```

---

### データプロバイダー

複数の入力パターンをテストする場合:

```php
/**
 * メールアドレスバリデーションテスト
 *
 * @dataProvider emailProvider
 * @param string $email
 * @param bool $expected
 * @return void
 */
public function testIsEmail(string $email, bool $expected): void
{
    $result = ValidationHelper::isEmail($email);
    $this->assertEquals($expected, $result);
}

/**
 * メールアドレステストデータ
 *
 * @return array
 */
public function emailProvider(): array
{
    return [
        // [email, expected]
        ['test@example.com', true],
        ['invalid', false],
        ['test@', false],
        ['@example.com', false],
        ['test@example', true],  // トップレベルドメインなしもOK
    ];
}
```

---

### アサーション一覧

| アサーション | 用途 | 例 |
|---|---|---|
| `assertEquals($expected, $actual)` | 値が等しい | `$this->assertEquals(1, $user->getId())` |
| `assertSame($expected, $actual)` | 型と値が等しい | `$this->assertSame(1, $user->getId())` |
| `assertTrue($condition)` | 真であること | `$this->assertTrue($result)` |
| `assertFalse($condition)` | 偽であること | `$this->assertFalse($result)` |
| `assertNull($variable)` | nullであること | `$this->assertNull($user)` |
| `assertNotNull($variable)` | nullでないこと | `$this->assertNotNull($user)` |
| `assertInstanceOf($class, $object)` | インスタンスであること | `$this->assertInstanceOf(User::class, $user)` |
| `assertArrayHasKey($key, $array)` | 配列にキーが存在 | `$this->assertArrayHasKey('success', $result)` |
| `assertCount($count, $array)` | 配列の要素数 | `$this->assertCount(3, $users)` |
| `assertStringContainsString($needle, $haystack)` | 文字列を含む | `$this->assertStringContainsString('Error', $message)` |

---

## CI/CD統合

### GitHub Actions

**.github/workflows/phpunit.yml**:

```yaml
name: PHPUnit Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:12-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test_user
          POSTGRES_PASSWORD: test_password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Setup PHP 7.4
        uses: shivammathur/setup-php@v2
        with:
          php-version: '7.4'
          extensions: mbstring, pdo, pdo_pgsql, xdebug
          coverage: xdebug

      - name: Install Dependencies
        run: composer install --no-interaction --prefer-dist

      - name: Run PHPUnit
        run: vendor/bin/phpunit --coverage-clover coverage.xml

      - name: Check Coverage
        run: |
          coverage=$(php -r "echo round(simplexml_load_file('coverage.xml')->project->metrics['statements'] / simplexml_load_file('coverage.xml')->project->metrics['elements'] * 100, 2);")
          echo "Coverage: ${coverage}%"
          if (( $(echo "$coverage < 75" | bc -l) )); then
            echo "Coverage ${coverage}% is below 75% threshold"
            exit 1
          fi
```

---

### カバレッジバッジ

README.mdに追加:

```markdown
[![PHPUnit](https://github.com/your-org/your-repo/actions/workflows/phpunit.yml/badge.svg)](https://github.com/your-org/your-repo/actions/workflows/phpunit.yml)
[![Coverage](https://img.shields.io/codecov/c/github/your-org/your-repo)](https://codecov.io/gh/your-org/your-repo)
```

---

## トラブルシューティング

### エラー: No code coverage driver available

**原因**: XDebugがインストールされていない

**解決方法**:
```bash
# XDebugインストール確認
docker compose exec apache-php php -m | grep xdebug

# php.iniでXDebug有効化（.docker/apache/php.ini）
[xdebug]
zend_extension=xdebug.so
xdebug.mode=coverage
```

---

### エラー: Class not found

**原因**: Composer autoloadが読み込まれていない

**解決方法**:
```bash
# Composer autoload再生成
docker compose exec apache-php composer dump-autoload
```

---

### テストが遅い

**原因**: データベースアクセスが多い

**解決策**:

1. **SQLite in-memoryを使用**:
```php
// tests/bootstrap.php
$_ENV['DB_HOST'] = ':memory:';
$_ENV['DB_DRIVER'] = 'sqlite';
```

2. **モックを使用**:
```php
// Repositoryをモック化してデータベースアクセスを回避
$mock = $this->createMock(UserRepository::class);
```

---

## 参照ドキュメント

- [PHPUnit 9.5 ドキュメント](https://phpunit.readthedocs.io/ja/9.5/)
- [.github/instructions/testing.instructions.md](../../.github/instructions/testing.instructions.md) - テスト戦略詳細
- [XDebug 3 ドキュメント](https://xdebug.org/docs/)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
