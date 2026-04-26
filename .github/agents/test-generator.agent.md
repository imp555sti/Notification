---
name: test-generator
description: PHPUnit 9.xテストコード自動生成。カバレッジ75%達成を支援
argument-hint: テスト対象のクラスファイルパス（例: "src/app/Service/UserService.php のテストを生成"）
tools: ['read', 'edit', 'search', 'vscode']
---

# テスト生成エージェント

既存のPHPクラスからPHPUnit 9.xテストコードを自動生成します。

**目的**: カバレッジ75%達成のためのテストコード自動生成  
**対象**: Helper, Entity, Service, Repository, Controllerクラス  
**参照ドキュメント**: `.github/instructions/testing.instructions.md`

---

## 実行タイミング

以下の場合にこのエージェントを起動してください：

- [ ] 新規クラス作成後、テストが未実装の場合
- [ ] カバレッジが75%未満の場合
- [ ] 既存クラスにメソッド追加した場合

---

## 生成ルール

### レイヤー別カバレッジ目標

| レイヤー | カバレッジ目標 | テスト密度 |
|---|---|---|
| Helper | **100%** | すべてのメソッド |
| Entity | **100%** | ゲッター/セッター, fromArray, toArray |
| Repository | **80%** | findBy系, create, update, delete |
| Service | **80%** | ビジネスロジック, トランザクション |
| Controller | **60%** | 主要なアクションメソッド |

---

## テンプレート

### 1. Helperクラステスト

**対象**: `src/src/app/Helper/SecurityHelper.php`

**生成されるテスト**: `tests/Unit/Helper/SecurityHelperTest.php`

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
     * 様々な入力でのエスケープテスト
     * 
     * @testdox 様々な入力でエスケープが動作する
     * @dataProvider escapeProvider
     */
    public function testEscapeVariousInputs(string $input, string $expected): void
    {
        $result = SecurityHelper::escape($input);
        $this->assertSame($expected, $result, "入力 '{$input}' のエスケープが正しくない");
    }
    
    public static function escapeProvider(): array
    {
        return [
            'スクリプトタグ' => ['<script>alert(1)</script>', '&lt;script&gt;alert(1)&lt;/script&gt;'],
            'シングルクォート' => ["It's a test", 'It&#039;s a test'],
            'ダブルクォート' => ['Say "Hello"', 'Say &quot;Hello&quot;'],
            '空文字' => ['', ''],
        ];
    }
}
```

---

### 2. Entityクラステスト

**対象**: `src/src/app/Entity/User.php`

**生成されるテスト**: `tests/Unit/Entity/UserTest.php`

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Entity;

use PHPUnit\Framework\TestCase;
use App\Entity\User;

class UserTest extends TestCase
{
    private User $user;
    
    protected function setUp(): void
    {
        $this->user = new User();
    }
    
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
        $this->user->setId(1);
        $this->user->setName('テストユーザー');
        $this->user->setEmail('test@example.com');
        
        $this->assertSame(1, $this->user->getId(), 'IDが正しく設定されていない');
        $this->assertSame('テストユーザー', $this->user->getName(), '名前が正しく設定されていない');
        $this->assertSame('test@example.com', $this->user->getEmail(), 'メールアドレスが正しく設定されていない');
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
        ];
        
        $user = User::fromArray($data);
        
        $this->assertSame(1, $user->getId(), 'IDが正しく設定されていない');
        $this->assertSame('テストユーザー', $user->getName(), '名前が正しく設定されていない');
        $this->assertSame('test@example.com', $user->getEmail(), 'メールアドレスが正しく設定されていない');
    }
    
    /**
     * toArrayメソッドのテスト
     * 
     * @testdox Entityを配列に変換できる
     */
    public function testToArray(): void
    {
        $this->user->setId(1);
        $this->user->setName('テストユーザー');
        $this->user->setEmail('test@example.com');
        
        $result = $this->user->toArray();
        
        $this->assertIsArray($result, '配列が返されていない');
        $this->assertSame(1, $result['id'], 'IDが配列に含まれていない');
        $this->assertSame('テストユーザー', $result['name'], '名前が配列に含まれていない');
        $this->assertSame('test@example.com', $result['email'], 'メールアドレスが配列に含まれていない');
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

### 3. Serviceクラステスト（モック使用）

**対象**: `src/src/app/Service/UserService.php`

**生成されるテスト**: `tests/Service/UserServiceTest.php`

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
    
    protected function setUp(): void
    {
        $this->mockRepository = $this->createMock(UserRepository::class);
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
        
        $this->mockRepository
            ->expects($this->once())
            ->method('findById')
            ->with($userId)
            ->willReturn($expectedUser);
        
        $result = $this->userService->getUserById($userId);
        
        $this->assertSame($expectedUser, $result, 'ユーザーが取得できない');
    }
    
    /**
     * getUserByIdメソッドのテスト（存在しないID）
     * 
     * @testdox 存在しないIDでnullが返される
     */
    public function testGetUserByIdNotFound(): void
    {
        $userId = 999;
        
        $this->mockRepository
            ->expects($this->once())
            ->method('findById')
            ->with($userId)
            ->willReturn(null);
        
        $result = $this->userService->getUserById($userId);
        
        $this->assertNull($result, '存在しないIDでnullが返されていない');
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
        
        $this->mockRepository
            ->expects($this->once())
            ->method('emailExists')
            ->with($userData['email'])
            ->willReturn(false);
        
        $this->mockRepository
            ->expects($this->once())
            ->method('beginTransaction');
        
        $this->mockRepository
            ->expects($this->once())
            ->method('create')
            ->willReturn(1);
        
        $this->mockRepository
            ->expects($this->once())
            ->method('commit');
        
        $result = $this->userService->registerUser($userData);
        
        $this->assertTrue($result['success']);
        $this->assertSame(1, $result['userId']);
    }
    
    /**
     * registerUserメソッドのテスト（バリデーションエラー）
     * 
     * @testdox バリデーションエラーで失敗する
     */
    public function testRegisterUserValidationError(): void
    {
        $userData = [
            'name' => '',  // 必須エラー
            'email' => 'invalid-email',  // 形式エラー
            'password' => '123',  // 弱いパスワード
        ];
        
        $result = $this->userService->registerUser($userData);
        
        $this->assertFalse($result['success'], '成功フラグがfalseではない');
        $this->assertArrayHasKey('errors', $result, 'エラー情報が含まれていない');
    }
}
```

---

## 使用例

### コマンド

```
@workspace テスト生成エージェントを使用して、
src/src/app/Service/OrderService.php のテストコードを生成してください。
.github/instructions/testing.instructions.md のパターンに従って、
カバレッジ80%以上を目指したテストケースを作成してください。
```

### 出力

エージェントは以下を生成します：

1. **テストファイル**: `tests/Service/OrderServiceTest.php`
2. **テストケース**: 正常系・異常系・境界値テスト
3. **モック設定**: 依存クラスのモック実装
4. **データプロバイダー**: パラメータ化テスト用データ

---

## 生成戦略

### カバレッジ向上のポイント

#### 1. 分岐網羅

すべてのif/else/switch文の分岐をテストします。

```php
// テスト対象
public function getStatus(User $user): string
{
    if ($user->isActive()) {
        return 'active';
    }
    return 'inactive';
}

// 生成されるテスト
/**
 * @testdox アクティブユーザーのステータスが正しく取得できる
 */
public function testGetStatusActive(): void { /* ... */ }

/**
 * @testdox 非アクティブユーザーのステータスが正しく取得できる
 */
public function testGetStatusInactive(): void { /* ... */ }
```

#### 2. 例外系テスト

例外をスローする可能性のある処理をテストします。

```php
/**
 * getUserByIdメソッドの例外テスト
 * 
 * @testdox 存在しないIDで例外が発生する
 */
public function testGetUserByIdThrowsException(): void
{
    $this->expectException(\InvalidArgumentException::class);
    $this->userService->getUserById(999);
}
```

#### 3. エッジケーステスト

境界値・特殊値のテストケースを生成します。

```php
public static function edgeCaseProvider(): array
{
    return [
        '最小値-1' => [0, false],
        '最小値' => [1, true],
        '最大値' => [100, true],
        '最大値+1' => [101, false],
        '空文字' => ['', false],
        'NULL' => [null, false],
    ];
}
```

---

## チェックリスト

生成されたテストコードの確認：

- [ ] `declare(strict_types=1);` が記述されている
- [ ] `TestCase` を継承している
- [ ] メソッド名は `test` プレフィックスの英語（例：`testGetUserById`）
- [ ] **すべてのテストメソッドに `@testdox` アノテーションが記述されている**
- [ ] PHPDocに詳細な説明が記述されている
- [ ] **すべてのアサーションに日本語メッセージが指定されている**
- [ ] `setUp()` でモック準備（必要な場合）
- [ ] データプロバイダー活用（複数パターン）
- [ ] 正常系・異常系両方カバー
- [ ] `assertSame` 使用（厳密な型チェック）

---

## 参照ドキュメント

- [.github/instructions/testing.instructions.md](../instructions/testing.instructions.md) - テスト実装ガイド
- [phpunit.xml](../../phpunit.xml) - PHPUnit設定

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
