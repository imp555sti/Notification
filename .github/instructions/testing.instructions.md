# テスト実装ガイド

PHPUnit 9.x を使用したテスト実装の完全ガイドです。

## 📋 目次

1. [テスト戦略](#テスト戦略)
2. [PHPUnit設定](#phpunit設定)
3. [テストディレクトリ構造](#テストディレクトリ構造)
4. [基本的なテストケース](#基本的なテストケース)
5. [モック作成](#モック作成)
6. [カバレッジ戦略](#カバレッジ戦略)
7. [データプロバイダー](#データプロバイダー)
8. [アサーション選択](#アサーション選択)
9. [日本語テスト出力（@testdox）](#日本語テスト出力testdox)
10. [テスト実行](#テスト実行)

---

## テスト戦略

### カバレッジ目標（75%以上）

| レイヤー | カバレッジ目標 | 優先度 | 理由 |
|---|---|---|---|
| Helper | **100%** | 最高 | ロジック密度が高く、全体で使用 |
| Entity | **100%** | 高 | データ構造の整合性確保 |
| Repository | **80%** | 高 | データアクセスの信頼性 |
| Service | **80%** | 高 | ビジネスロジックの正確性 |
| Controller | **60%** | 中 | 薄い層、統合テストで補完 |

### テストの種類

```
┌─────────────────────────────────────────┐
│ 単体テスト（Unit Tests）                │
│ - Helper, Entity, Repository, Service  │
│ - モック使用                            │
│ - 高速（秒単位）                        │
└─────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ 統合テスト（Integration Tests）         │
│ - Service + Repository                  │
│ - テストDB使用                          │
│ - 中速（数秒〜数十秒）                  │
└─────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ E2Eテスト（End-to-End Tests）           │
│ - Controller + Service + Repository     │
│ - ブラウザ自動化（Selenium等）          │
│ - 低速（分単位）                        │
└─────────────────────────────────────────┘
```

---

## PHPUnit設定

### phpunit.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true"
         verbose="true">
    
    <!-- テストスイート定義 -->
    <testsuites>
        <testsuite name="Unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="Service">
            <directory>tests/Service</directory>
        </testsuite>
        <testsuite name="Repository">
            <directory>tests/Repository</directory>
        </testsuite>
        <testsuite name="Controller">
            <directory>tests/Controller</directory>
        </testsuite>
    </testsuites>
    
    <!-- カバレッジ設定 -->
    <coverage>
        <include>
            <directory suffix=".php">app</directory>
        </include>
        <exclude>
            <directory>vendor</directory>
            <file>src/src/app/bootstrap.php</file>
        </exclude>
        <report>
            <html outputDirectory="coverage/html"/>
            <text outputFile="php://stdout" showUncoveredFiles="true"/>
            <clover outputFile="coverage/clover.xml"/>
        </report>
    </coverage>
    
    <!-- 環境変数 -->
    <php>
        <env name="APP_ENV" value="testing"/>
        <env name="APP_DEBUG" value="true"/>
        <env name="DB_HOST" value="localhost"/>
        <env name="DB_NAME" value="test_db"/>
    </php>
</phpunit>
```

---

## テストディレクトリ構造

```
tests/
├── bootstrap.php                   # テスト初期化
├── Unit/                           # 単体テスト
│   ├── Helper/
│   │   ├── SecurityHelperTest.php
│   │   └── ValidationHelperTest.php
│   └── Entity/
│       └── UserTest.php
├── Service/                        # Serviceテスト
│   ├── UserServiceTest.php
│   └── AuthServiceTest.php
├── Repository/                     # Repositoryテスト
│   └── UserRepositoryTest.php
└── Controller/                     # Controllerテスト
    └── UserControllerTest.php
```

---

## 基本的なテストケース

### Helperのテスト

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Helper;

use PHPUnit\Framework\TestCase;
use App\Helper\SecurityHelper;

class SecurityHelperTest extends TestCase
{
    /**
     * HTMLエスケープのテスト
     * 
     * @testdox エスケープ処理が正しく動作する
     */
    public function testEscape(): void
    {
        $input = '<script>alert("XSS")</script>';
        $expected = '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;';
        
        $result = SecurityHelper::escape($input);
        
        $this->assertSame($expected, $result, 'エスケープ処理が正しく動作していない');
    }
    
    /**
     * CSRFトークン生成のテスト
     * 
     * @testdox CSRFトークンが生成される
     */
    public function testGenerateCsrfToken(): void
    {
        session_start();
        
        $token = SecurityHelper::generateCsrfToken();
        
        $this->assertNotEmpty($token, 'CSRFトークンが生成されていない');
        $this->assertSame(64, strlen($token), 'CSRFトークンの長さが不正');
        $this->assertSame($token, $_SESSION['csrf_token'] ?? '', 'セッションにトークンが保存されていない');
    }
    
    /**
     * パスワードハッシュ化のテスト
     * 
     * @testdox パスワードハッシュ化が正しく動作する
     * @dataProvider passwordProvider
     */
    public function testHashPassword(string $password): void
    {
        $hash = SecurityHelper::hashPassword($password);
        
        $this->assertNotEmpty($hash, 'パスワードハッシュが生成されていない');
        $this->assertStringStartsWith('$2y$', $hash, 'bcryptハッシュではない');  // bcrypt
        $this->assertTrue(SecurityHelper::verifyPassword($password, $hash), 'パスワード検証に失敗');
    }
    
    /**
     * パスワードのテストデータ
     */
    public static function passwordProvider(): array
    {
        return [
            'シンプル' => ['password123'],
            '強力' => ['P@ssw0rd!2024'],
            '日本語' => ['パスワード123'],
        ];
    }
}
```

### Entityのテスト

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Entity;

use PHPUnit\Framework\TestCase;
use App\Entity\User;

class UserTest extends TestCase
{
    /**
     * コンストラクタのテスト
     * 
     * @testdox コンストラクタでインスタンス生成できる
     */
    public function testConstructor(): void
    {
        $user = new User();
        
        $this->assertInstanceOf(User::class, $user, 'Userインスタンスが生成されていない');
        $this->assertNull($user->getId(), '初期状態でIDがnullではない');
    }
    
    /**
     * Setter/Getterのテスト
     * 
     * @testdox setterとgetterが正しく動作する
     */
    public function testSetterAndGetter(): void
    {
        $user = new User();
        
        $user->setId(1);
        $user->setName('テストユーザー');
        $user->setEmail('test@example.com');
        
        $this->assertSame(1, $user->getId(), 'IDが正しく設定されていない');
        $this->assertSame('テストユーザー', $user->getName(), '名前が正しく設定されていない');
        $this->assertSame('test@example.com', $user->getEmail(), 'メールアドレスが正しく設定されていない');
    }
    
    /**
     * fromArrayメソッドのテスト
     * 
     * @testdox 配列からEntityを生成できる
     */
    public function testFromArray(): void
    {
        $data = [
            'id' => 1,
            'name' => 'テストユーザー',
            'email' => 'test@example.com',
            'password_hash' => 'hashed_password',
        ];
        
        $user = User::fromArray($data);
        
        $this->assertSame(1, $user->getId(), 'IDが正しく設定されていない');
        $this->assertSame('テストユーザー', $user->getName(), '名前が正しく設定されていない');
        $this->assertSame('test@example.com', $user->getEmail(), 'メールアドレスが正しく設定されていない');
        $this->assertSame('hashed_password', $user->getPasswordHash(), 'パスワードハッシュが正しく設定されていない');
    }
    
    /**
     * toArrayメソッドのテスト
     * 
     * @testdox Entityを配列に変換できる
     */
    public function testToArray(): void
    {
        $user = new User();
        $user->setId(1);
        $user->setName('テストユーザー');
        $user->setEmail('test@example.com');
        
        $result = $user->toArray();
        
        $this->assertIsArray($result, '配列が返されていない');
        $this->assertSame(1, $result['id'], 'IDが配列に含まれていない');
        $this->assertSame('テストユーザー', $result['name'], '名前が配列に含まれていない');
        $this->assertSame('test@example.com', $result['email'], 'メールアドレスが配列に含まれていない');
        $this->assertArrayNotHasKey('password_hash', $result, 'パスワードハッシュがデフォルトで除外されていない');  // デフォルトで除外
    }
    
    /**
     * メソッドチェーンのテスト
     * 
     * @testdox メソッドチェーンが使える
     */
    public function testMethodChaining(): void
    {
        $user = (new User())
            ->setId(1)
            ->setName('テストユーザー')
            ->setEmail('test@example.com');
        
        $this->assertSame(1, $user->getId(), 'IDが正しく設定されていない');
        $this->assertSame('テストユーザー', $user->getName(), '名前が正しく設定されていない');
    }
}
```

---

## モック作成

### Repositoryのモック

```php
<?php

declare(strict_types=1);

namespace Tests\Service;

use PHPUnit\Framework\TestCase;
use App\Service\UserService;
use App\Repository\UserRepository;
use App\Entity\User;

class UserServiceTest extends TestCase
{
    private UserRepository $mockRepository;
    private UserService $userService;
    
    /**
     * 各テストメソッド実行前に呼ばれる
     */
    protected function setUp(): void
    {
        // ✅ モック作成
        $this->mockRepository = $this->createMock(UserRepository::class);
        
        // ✅ DIでモックを注入
        $this->userService = new UserService($this->mockRepository);
    }
    
    /**
     * getUserByIdメソッドのテスト
     * 
     * @testdox ユーザーが取得できる
     */
    public function testGetUserById(): void
    {
        $userId = 1;
        $expectedUser = new User();
        $expectedUser->setId($userId);
        $expectedUser->setName('テストユーザー');
        
        // ✅ モックの振る舞いを定義
        $this->mockRepository
            ->expects($this->once())  // 1回呼ばれることを期待
            ->method('findById')      // メソッド名
            ->with($userId)           // 引数の期待値
            ->willReturn($expectedUser);  // 戻り値
        
        // ✅ テスト実行
        $result = $this->userService->getUserById($userId);
        
        // ✅ アサーション
        $this->assertSame($expectedUser, $result, 'ユーザーが取得できない');
    }
    
    /**
     * registerUserメソッドのテスト（成功パターン）
     * 
     * @testdox 新規登録が成功する
     */
    public function testRegisterUser(): void
    {
        $userData = [
            'name' => 'テストユーザー',
            'email' => 'test@example.com',
            'password' => 'P@ssw0rd123',
        ];
        
        // ✅ 複数メソッドのモック設定
        $this->mockRepository
            ->expects($this->once())
            ->method('emailExists')
            ->with($userData['email'])
            ->willReturn(false);  // 重複なし
        
        $this->mockRepository
            ->expects($this->once())
            ->method('beginTransaction');
        
        $this->mockRepository
            ->expects($this->once())
            ->method('create')
            ->willReturn(1);  // 新規ID
        
        $this->mockRepository
            ->expects($this->once())
            ->method('commit');
        
        // ✅ テスト実行
        $result = $this->userService->registerUser($userData);
        
        // ✅ アサーション
        $this->assertTrue($result['success']);
        $this->assertSame(1, $result['userId']);
    }
    
    /**
     * registerUserメソッドのテスト（エラーパターン）
     * 
     * @testdox メールアドレス重複でエラー
     */
    public function testRegisterUserWithDuplicateEmail(): void
    {
        $userData = [
            'name' => 'テストユーザー',
            'email' => 'existing@example.com',
            'password' => 'P@ssw0rd123',
        ];
        
        // ✅ 重複ありのモック
        $this->mockRepository
            ->expects($this->once())
            ->method('emailExists')
            ->with($userData['email'])
            ->willReturn(true);  // 重複あり
        
        // ✅ createは呼ばれないことを期待
        $this->mockRepository
            ->expects($this->never())
            ->method('create');
        
        $result = $this->userService->registerUser($userData);
        
        $this->assertFalse($result['success'], '成功フラグがfalseではない');
        $this->assertArrayHasKey('errors', $result, 'エラー情報が含まれていない');
    }
}
```

### 複雑なモック（getMockBuilder使用）

```php
/**
 * 複雑なモック設定のテスト
 * 
 * @testdox getMockBuilderを使用した複雑なモック設定ができる
 */
public function testComplexMockSetup(): void
{
    // ✅ getMockBuilder で詳細設定
    $mockRepository = $this->getMockBuilder(UserRepository::class)
        ->disableOriginalConstructor()  // コンストラクタ実行しない
        ->onlyMethods(['findById', 'create'])  // モック対象メソッド指定
        ->getMock();
    
    $mockRepository
        ->method('findById')
        ->willReturnCallback(function ($id) {
            // ✅ 複雑なロジックも実装可能
            if ($id === 1) {
                $user = new User();
                $user->setId(1);
                return $user;
            }
            return null;
        });
    
    $service = new UserService($mockRepository);
    $result = $service->getUserById(1);
    
    $this->assertNotNull($result, 'ユーザーが取得できない');
}
```

---

## カバレッジ戦略

### カバレッジ確認方法

```bash
# HTMLレポート生成
docker exec phpunit-apache-1 composer coverage

# ブラウザで確認
# coverage/html/index.html を開く
```

### カバレッジ向上のコツ

#### 1. 分岐網羅（Branch Coverage）

```php
// テスト対象コード
public function getStatus(User $user): string
{
    if ($user->isActive()) {
        return 'active';
    }
    return 'inactive';
}

// ✅ 両方の分岐をテスト
/**
 * ステータス取得のテスト（アクティブユーザー）
 * 
 * @testdox アクティブユーザーのステータスが正しく取得できる
 */
public function testGetStatusActive(): void
{
    $user = $this->createMock(User::class);
    $user->method('isActive')->willReturn(true);
    
    $result = $this->service->getStatus($user);
    
    $this->assertSame('active', $result, 'アクティブユーザーのステータスが正しくない');
}

/**
 * ステータス取得のテスト（非アクティブユーザー）
 * 
 * @testdox 非アクティブユーザーのステータスが正しく取得できる
 */
public function testGetStatusInactive(): void
{
    $user = $this->createMock(User::class);
    $user->method('isActive')->willReturn(false);
    
    $result = $this->service->getStatus($user);
    
    $this->assertSame('inactive', $result, '非アクティブユーザーのステータスが正しくない');
}
```

#### 2. 例外系テスト

```php
/**
 * getUserByIdメソッドの例外テスト
 * 
 * @testdox 存在しないIDで例外が発生する
 */
public function testGetUserByIdThrowsException(): void
{
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('User not found');
    
    $this->mockRepository
        ->method('findById')
        ->willReturn(null);
    
    $this->userService->getUserById(999);
}
```

#### 3. エッジケーステスト

```php
/**
 * 年齢バリデーションの境界値テスト
 * 
 * @testdox 年齢の境界値が正しく検証される
 * @dataProvider edgeCaseProvider
 */
public function testEdgeCaseValidation(int $input, bool $expected): void
{
    $result = $this->validator->isValidAge($input);
    $this->assertSame($expected, $result, "年齢 {$input} の検証結果が期待値と異なる");
}

public static function edgeCaseProvider(): array
{
    return [
        '最小値-1' => [0, false],
        '最小値' => [1, true],
        '最大値' => [120, true],
        '最大値+1' => [121, false],
    ];
}
```

---

## データプロバイダー

### 基本的な使い方

```php
/**
 * メールアドレスバリデーションのテスト（正常系）
 * 
 * @testdox 正しいメールアドレスが検証される
 * @dataProvider validEmailProvider
 */
public function testIsEmailValid(string $email): void
{
    $result = ValidationHelper::isEmail($email);
    $this->assertTrue($result, "メールアドレス '{$email}' が正しく検証されない");
}

/**
 * 正しいメールアドレスのテストデータ
 */
public static function validEmailProvider(): array
{
    return [
        'シンプル' => ['test@example.com'],
        'サブドメイン' => ['user@mail.example.co.jp'],
        'ドット含む' => ['first.last@example.com'],
        '数字含む' => ['user123@example.com'],
    ];
}

/**
 * メールアドレスバリデーションのテスト（異常系）
 * 
 * @testdox 不正なメールアドレスが検証される
 * @dataProvider invalidEmailProvider
 */
public function testIsEmailInvalid(string $email): void
{
    $result = ValidationHelper::isEmail($email);
    $this->assertFalse($result, "メールアドレス '{$email}' が不正と判定されない");
}

public static function invalidEmailProvider(): array
{
    return [
        '@なし' => ['testexample.com'],
        'ドメインなし' => ['test@'],
        '空文字' => [''],
        'スペース含む' => ['test @example.com'],
    ];
}
```

### 複数パラメータ

```php
/**
 * パスワード強度のテスト
 * 
 * @testdox パスワード強度が正しくチェックされる
 * @dataProvider passwordStrengthProvider
 */
public function testPasswordStrength(string $password, bool $expected): void
{
    $result = ValidationHelper::isStrongPassword($password);
    $this->assertSame($expected, $result, "パスワード '{$password}' の強度判定が期待値と異なる");
}

public static function passwordStrengthProvider(): array
{
    return [
        '弱い（短い）' => ['pass', false],
        '弱い（数字のみ）' => ['12345678', false],
        '普通' => ['Password1', true],
        '強い' => ['P@ssw0rd!123', true],
    ];
}
```

---

## アサーション選択

### 同値比較

```php
// ✅ 厳密な型チェック（推奨）
$this->assertSame(1, $result);  // 型も一致必須（1 !== "1"）

// ⚠️ 緩い比較（型変換あり）
$this->assertEquals(1, $result);  // 型変換あり（1 == "1"）
```

### 型チェック

```php
$this->assertInstanceOf(User::class, $user);
$this->assertIsArray($data);
$this->assertIsString($name);
$this->assertIsInt($id);
$this->assertIsBool($flag);
```

### 存在チェック

```php
$this->assertNull($result);
$this->assertNotNull($result);
$this->assertEmpty($array);
$this->assertNotEmpty($array);
```

### 配列チェック

```php
$this->assertArrayHasKey('email', $errors);
$this->assertArrayNotHasKey('password', $data);
$this->assertCount(3, $users);
$this->assertContains('admin', $roles);
```

### 文字列チェック

```php
$this->assertStringStartsWith('Error:', $message);
$this->assertStringEndsWith('.jpg', $filename);
$this->assertStringContainsString('success', $response);
$this->assertMatchesRegularExpression('/^[0-9]+$/', $code);
```

---

## 日本語テスト出力（@testdox）

### 概要

PHPUnitの `@testdox` アノテーションと `--testdox` オプションを使用して、テスト結果を**日本語の人間が読みやすい形式**で表示します。

### @testdoxアノテーション（ルール）

**✅ 必須ルール**：すべてのテストメソッドに `@testdox` を記述

```php
/**
 * メソッドの説明（PHPDoc）
 * 
 * @testdox 日本語で「テストが何を検証しているか」を簡潔に説明
 */
public function testSomething(): void
{
    // テストコード
}
```

### @testdox記述ガイドライン

| 項目 | ルール | 例 |
|---|---|---|
| **言語** | 必ず日本語で記述 | `@testdox ユーザーが正しく作成される` |
| **形式** | 「〜が〜する」「〜である」の述語形式 | 🆗 `メールアドレスが正しく検証される` <br> ❌ `メールアドレスチェック` |
| **長さ** | 1行で読める（60文字以内推奨） | 🆗 `パスワードハッシュが正しく生成される` <br> ❌ `パスワードをbcryptアルゴリズムでハッシュ化してデータベースに保存する時に適切にハッシュ化される` |
| **検証対象** | **何を検証しているか**を明確に | 🆗 `XSS対策：HTMLエスケープが正しく動作する` <br> ❌ `エスケープ` |
| **正常系・異常系** | 異常系は「〜でエラーになる」と明記 | 🆗 `存在しないIDで例外が発生する` <br> ❌ `存在しないID` |

### 実装例

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Helper;

use PHPUnit\Framework\TestCase;
use App\Helper\SecurityHelper;

class SecurityHelperTest extends TestCase
{
    /**
     * HTMLエスケープのテスト
     * 
     * @testdox XSS対策：HTMLエスケープが正しく動作する
     */
    public function testEscape(): void
    {
        $input = '<script>alert("XSS")</script>';
        $expected = '&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;';
        
        $this->assertSame($expected, SecurityHelper::escape($input), 'XSS対策：HTMLエスケープが正しく動作していない');
    }
    
    /**
     * CSRFトークン生成のテスト
     * 
     * @testdox CSRFトークンが正しく生成される
     */
    public function testGenerateCsrfToken(): void
    {
        $token = SecurityHelper::generateCsrfToken();
        
        $this->assertNotEmpty($token, 'CSRFトークンが生成されていない');
        $this->assertEquals(64, strlen($token), 'CSRFトークンの長さが不正');
    }
    
    /**
     * パスワード検証のテスト
     * 
     * @testdox 正しいパスワードが検証される
     */
    public function testVerifyPassword(): void
    {
        $password = 'SecurePassword123';
        $hash = SecurityHelper::hashPassword($password);
        
        $this->assertTrue(
            SecurityHelper::verifyPassword($password, $hash),
            'パスワード検証：正しいパスワードが検証されていない'
        );
    }
    
    /**
     * パスワード検証：エラーケースのテスト
     * 
     * @testdox 間違ったパスワードが検証されない
     */
    public function testVerifyPasswordWrong(): void
    {
        $hash = SecurityHelper::hashPassword('CorrectPassword');
        
        $this->assertFalse(
            SecurityHelper::verifyPassword('WrongPassword', $hash),
            'パスワード検証：間違ったパスワードが検証されている'
        );
    }
}
```

### アサーションメッセージ（ルール）

**✅ 必須ルール**：すべてのアサーション呼び出しに日本語メッセージを指定

```php
// ✅ 正しい形式：日本語メッセージ付き
$this->assertEquals(
    1, 
    $result['userId'], 
    'ユーザーIDが正しく返されていない'
);

// ❌ 間違った形式：メッセージなし
$this->assertEquals(1, $result['userId']);
```

### メッセージ記述ガイドライン

| パターン | 形式 | 例 |
|---|---|---|
| **検証失敗時** | 「〜が失敗」「〜が正しくない」 | `メールアドレスの検証に失敗` |
| **存在チェック失敗** | 「〜が存在しない」 | `配列にIDキーが存在しない` |
| **型チェック失敗** | 「〜である必要がある」 | `戻り値が配列である必要がある` |
| **値チェック失敗** | 「期待値と異なる」 | `計算結果が期待値と異なる` |
| **範囲チェック失敗** | 「〜範囲内である」 | `値が0-100の範囲内である必要がある` |

### 実装例：メッセージ付きアサーション

```php
/**
 * @testdox ユーザーが正しく作成される
 */
public function testCreateUser(): void
{
    $userData = ['name' => 'テストユーザー', 'email' => 'test@example.com'];
    
    $user = $this->userService->createUser($userData);
    
    // ✅ 各アサーションに日本語メッセージ
    $this->assertNotNull($user, 'ユーザーが作成されていない');
    $this->assertEquals('テストユーザー', $user->getName(), 'ユーザー名が正しく設定されていない');
    $this->assertEquals('test@example.com', $user->getEmail(), 'メールアドレスが正しく設定されていない');
}
```

---

## 日本語テスト出力の環境設定

### PowerShellでのUTF-8設定（Windows）

PowerShellで日本語テスト出力が正しく表示されるよう、**コンソール出力エンコーディングをUTF-8に設定**します。

#### 一時的な設定（現在のセッションのみ）

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

#### 永続的な設定（推奨）

PowerShellプロファイルに以下を追加：

```powershell
# PowerShellプロファイルの場所確認
$PROFILE

# プロファイルに追記
Add-Content -Path $PROFILE -Value "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8"
```

### Bash/Linux/macOS

```bash
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8
```

---

## テスト実行

### 📌 標準的なテスト実行（推奨：--testdox付き）

**日本語テスト名で結果を表示する標準形式**：

```bash
# 全テスト実行（日本語テスト名表示）
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox

# Composerコマンドで実行
docker exec phpunit-apache-1 composer test -- --testdox
```

#### --testdoxオプションの効果

```
✔ ゲッター/セッター機能が正しく動作する [162 ms]
✔ 配列からエンティティが正しく生成される [9 ms]
✔ XSS対策：HTMLエスケープが正しく動作する [8 ms]
✔ CSRFトークンが正しく生成される [10 ms]
```

### 詳細実行（テスト内容確認用）

```bash
# テストの詳細出力
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox --verbose

# テストのタイミング付き詳細出力
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox --verbose --stop-on-failure
```

### 特定のスイート実行

```bash
# Unit テスト（日本語使用を推奨）
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Unit/ --testdox

# Service テスト
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Service/ --testdox

# Repository テスト
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Repository/ --testdox
```

### 特定のテストクラス実行

```bash
# 特定のテストクラスのみ
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Unit/Helper/SecurityHelperTest.php --testdox
```

### 特定のテストメソッド実行

```bash
# 特定のテストメソッド
docker exec phpunit-apache-1 vendor/bin/phpunit --filter testEscape tests/Unit/Helper/SecurityHelperTest.php --testdox
```

### カバレッジ付き実行（推奨）

```bash
# カバレッジレポート生成（HTML + XML）
docker exec phpunit-apache-1 composer coverage

# または直接実行
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox --whitelist src/app
```

### 失敗時は機能的な停止

```bash
# 最初の失敗で停止
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox --stop-on-failure

# N個の失敗で停止
docker exec phpunit-apache-1 vendor/bin/phpunit --testdox --stop-on-failure --max-tries=5
```

---

## テスト実装チェックリスト

新規テスト作成時：

- [ ] `declare(strict_types=1);` 宣言
- [ ] `TestCase` を継承
- [ ] メソッド名は `test` プレフィックスの英語（例：`testGetUserById`）
- [ ] **各テストメソッドに `@testdox` アノテーションで日本語説明を必須記述**
- [ ] **すべてのアサーションに日本語メッセージを指定**
- [ ] PHPDocに詳細な説明を記述
- [ ] `setUp()` でモック準備（必要な場合）
- [ ] データプロバイダー活用（複数ケース検証）
- [ ] 正常系・異常系両方テスト
- [ ] アサーション適切（assertSame推奨、メッセージ必須）
- [ ] カバレッジ75%以上を貢献
- [ ] --testdoxで日本語テスト名が表示されることを確認

---

## PHP7.4 / RHEL8 互換の固定ルール（再発防止）

### PHPUnitバージョン方針

- PHPUnitは **`9.5.28` を固定値**として扱う（`composer.json` と `src/composer.json` で同一バージョンを維持）
- PHP 7.4 互換の上限であり、PHPUnit 10 以上へ自動更新しない
- `require-dev` の指定はキャレット（`^`）を使わず厳密固定とする

```json
// ✅ 正しい（厳密固定）
"require-dev": {
    "phpunit/phpunit": "9.5.28"
}

// ❌ 間違い（自動更新される）
"require-dev": {
    "phpunit/phpunit": "^9.5"
}
```

### 依存関係更新の運用

- 依存更新は**コンテナ内で実施**し、ホスト環境のPHP/Composerバージョン差異を持ち込まない
- 更新後は `composer.lock` も必ずコミットに含める
- 更新後に Unit / Integration の最低どちらか1スイートがグリーンであることを確認する

### テスト記述ルール（PHP 7.4互換の制約）

| 項目 | 使用可 | 禁止 |
|---|---|---|
| テストマーク | `@test` DocBlock アノテーション | `#[Test]` PHP8属性 |
| データプロバイダー | `@dataProvider` アノテーション | `#[DataProvider]` PHP8属性 |
| Data Provider メソッド | `public static function …(): array` | アロー関数・match式 |
| 型宣言 | 単一型 / nullable（`?Type`） | union型（`int\|string`）、intersection型 |
| コンストラクタ | 通常の `__construct` + プロパティ代入 | Constructor Property Promotion |
| その他構文 | PHP 7.4 の範囲内すべて | `match` 式、`throw` 式、`array_is_list()` など |

### テスト実行コマンドの統一（再発防止）

ホスト側の `phpunit` バイナリ直接実行はバージョン差異混入を招くため**原則禁止**。
必ず Docker コンテナ内のバイナリを使用する。

```bash
# ✅ Unit テスト
docker compose exec -T apache-php php /var/www/html/vendor/bin/phpunit \
  -c /var/www/phpunit.xml --testsuite Unit

# ✅ Integration テスト
docker compose exec -T apache-php php /var/www/html/vendor/bin/phpunit \
  -c /var/www/phpunit.xml --testsuite Integration
```

### 変更時チェックリスト

- [ ] `composer.json` と `src/composer.json` の `require-dev.phpunit/phpunit` が同一バージョン
- [ ] `composer.lock` が更新内容と整合している
- [ ] 追加・変更したテストコードが PHP 7.4 構文のみで記述されている
- [ ] Unit / Integration のいずれか最低1スイートがグリーンである

---

**参照**:  
- [phpunit.xml](../../phpunit.xml) - PHPUnit設定  
- [tests/bootstrap.php](../../tests/bootstrap.php) - テスト初期化
