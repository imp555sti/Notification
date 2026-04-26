# PHP実装ガイド

このドキュメントは、プロジェクトでのPHP実装における詳細なガイドラインです。

## 📋 目次

1. [コーディング規約](#コーディング規約)
2. [型宣言](#型宣言)
3. [エラーハンドリング](#エラーハンドリング)
4. [命名規則](#命名規則)
5. [コメント規約](#コメント規約)
6. [禁止事項](#禁止事項)
7. [PHP7.4互換性](#php74互換性)

---

## コーディング規約

### PSR-12準拠

すべてのPHPコードは**PSR-12**に準拠します。

#### インデント・スペース
```php
// ✅ 正しい
class UserService
{
    public function getUser(int $id): ?User
    {
        if ($id > 0) {
            return $this->repository->find($id);
        }
        
        return null;
    }
}

// ❌ 間違い（タブ使用、スペース不足）
class UserService{
	public function getUser(int $id):?User{
		if($id>0){
			return $this->repository->find($id);
		}
		return null;
	}
}
```

#### 1行の長さ
- **推奨**: 120文字以内
- **絶対最大**: 200文字

```php
// ✅ 正しい（長い行は複数行に分割）
$result = $this->userService->registerUser([
    'name' => $name,
    'email' => $email,
    'password' => $password,
]);

// ❌ 間違い（1行が長すぎる）
$result = $this->userService->registerUser(['name' => $name, 'email' => $email, 'password' => $password, 'role' => $role, 'status' => $status]);
```

#### クラス・メソッド構造
```php
<?php

declare(strict_types=1);  // ✅ 必須

namespace App\Service;  // ✅ 名前空間

use App\Repository\UserRepository;  // ✅ use文はアルファベット順
use App\Entity\User;
use App\Helper\SecurityHelper;

/**
 * ユーザーサービスクラス
 * 
 * @package App\Service
 */
class UserService  // ✅ クラス宣言の前に1行空行
{
    private UserRepository $repository;  // ✅ プロパティ
    
    public function __construct(UserRepository $repository)  // ✅ コンストラクタ
    {
        $this->repository = $repository;
    }
    
    public function getUser(int $id): ?User  // ✅ publicメソッド
    {
        return $this->repository->find($id);
    }
    
    private function validateUser(array $data): array  // ✅ privateメソッド
    {
        // 実装
    }
}
```

---

## 型宣言

### 必須ルール

すべての**引数**と**戻り値**に型宣言を付けます。

#### 関数・メソッド

```php
// ✅ 正しい
public function getUser(int $id): ?User
{
    return $this->repository->find($id);
}

public function getUsers(int $page = 1, int $perPage = 20): array
{
    return $this->repository->findAll($perPage, ($page - 1) * $perPage);
}

public function deleteUser(int $id): bool
{
    return $this->repository->delete($id);
}

public function logMessage(string $message): void
{
    error_log($message);
}

// ❌ 間違い（型宣言なし）
public function getUser($id)
{
    return $this->repository->find($id);
}
```

#### プロパティ（PHP7.4対応）

```php
// ✅ 正しい（PHP7.4でも動作）
class UserService
{
    /** @var UserRepository */
    private UserRepository $repository;
    
    /** @var int */
    private int $maxRetries = 3;
    
    /** @var string|null */
    private ?string $cacheKey = null;
}
```

#### サポートする型

| 型 | 使用例 |
|---|---|
| `int` | `function count(): int` |
| `float` | `function getPrice(): float` |
| `string` | `function getName(): string` |
| `bool` | `function isValid(): bool` |
| `array` | `function getList(): array` |
| `object` | `function getObject(): object` |
| `callable` | `function setCallback(callable $fn): void` |
| `iterable` | `function process(iterable $items): void` |
| `void` | `function log(string $msg): void` |
| `?Type` | `function find(int $id): ?User` (nullable) |
| `ClassName` | `function getUser(): User` |

#### 配列の型ヒント（PHPDocで補足）

```php
/**
 * ユーザー一覧を取得
 * 
 * @param int $page
 * @param int $perPage
 * @return array<int, User>  ✅ PHPDocで詳細な型情報
 */
public function getUsers(int $page, int $perPage): array
{
    return $this->repository->findAll();
}

/**
 * ユーザーデータを検証
 * 
 * @param array<string, mixed> $data
 * @return array<string, array<string>>  ✅ エラー配列の型
 */
private function validate(array $data): array
{
    // 実装
}
```

---

## エラーハンドリング

### try-catch の使用

外部リソース（DB、ファイル、API）へのアクセスは必ず`try-catch`で囲みます。

```php
// ✅ 正しい
public function createUser(array $data): array
{
    try {
        $this->repository->beginTransaction();
        
        $user = new User();
        $user->setName($data['name']);
        $user->setEmail($data['email']);
        
        $userId = $this->repository->create($user);
        
        $this->repository->commit();
        
        return ['success' => true, 'userId' => $userId];
    } catch (PDOException $e) {
        $this->repository->rollback();
        error_log('ユーザー作成エラー: ' . $e->getMessage());
        
        return ['success' => false, 'error' => 'データベースエラーが発生しました'];
    } catch (\Exception $e) {
        $this->repository->rollback();
        error_log('予期しないエラー: ' . $e->getMessage());
        
        return ['success' => false, 'error' => 'システムエラーが発生しました'];
    }
}
```

### カスタム例外

プロジェクト固有の例外クラスを作成可能：

```php
// app/Exception/ValidationException.php
namespace App\Exception;

class ValidationException extends \Exception
{
    private array $errors;
    
    public function __construct(array $errors, string $message = '入力値が不正です')
    {
        parent::__construct($message);
        $this->errors = $errors;
    }
    
    public function getErrors(): array
    {
        return $this->errors;
    }
}

// 使用例
if (!empty($errors)) {
    throw new ValidationException($errors);
}
```

### エラーログ

```php
// ✅ 正しい（詳細なログ）
error_log(sprintf(
    'ユーザー登録エラー: %s (Email: %s)',
    $e->getMessage(),
    $email
));

// ⚠️ 機密情報は記録しない
error_log('パスワード: ' . $password);  // ❌NG
```

---

## 命名規則

### クラス名

**PascalCase**（各単語の先頭が大文字）

```php
class UserService {}
class ProductRepository {}
class SecurityHelper {}
```

### メソッド名・関数名

**camelCase**（最初の単語は小文字、以降は大文字）

```php
public function getUserById(int $id): ?User {}
public function createNewProduct(array $data): int {}
private function validateInput(array $data): bool {}
```

### 変数名・プロパティ名

**camelCase**

```php
$userId = 1;
$productList = [];
private string $emailAddress;
```

### 定数

**UPPER_CASE**（アンダースコア区切り）

```php
const MAX_LOGIN_ATTEMPTS = 5;
const DEFAULT_TIMEOUT = 30;
define('APP_VERSION', '1.0.0');
```

### 真偽値系の命名

`is`, `has`, `can` で始める：

```php
public function isValid(): bool {}
public function hasPermission(): bool {}
public function canDelete(): bool {}

private bool $isActive;
private bool $hasError;
```

---

## コメント規約

### PHPDoc必須

すべてのクラスとpublicメソッドに**PHPDoc**を記述します。

```php
/**
 * ユーザーサービスクラス
 * 
 * ユーザー関連のビジネスロジックを提供します。
 * 
 * @package App\Service
 */
class UserService
{
    /**
     * IDでユーザーを取得
     * 
     * @param int $id ユーザーID
     * @return User|null ユーザーエンティティ（見つからない場合はnull）
     */
    public function getUserById(int $id): ?User
    {
        return $this->repository->find($id);
    }
}
```

### インラインコメント

複雑なロジックには日本語でコメント：

```php
// ✅ 正しい
public function calculateDiscount(int $price, string $couponCode): int
{
    // 基本割引率を取得
    $baseDiscount = $this->getBaseDiscount();
    
    // クーポンコードが有効かチェック
    if ($this->isValidCoupon($couponCode)) {
        // クーポン割引を追加適用
        $baseDiscount += $this->getCouponDiscount($couponCode);
    }
    
    // 最大割引率を超えないように制限
    $discount = min($baseDiscount, self::MAX_DISCOUNT_RATE);
    
    return (int)($price * (1 - $discount / 100));
}
```

### TODO/FIXMEコメント

```php
// TODO: PHP8移行時にUnion Types（int|string）に変更
// FIXME: N+1問題が発生する可能性あり - JOIN句に修正必要
// NOTE: この処理はパフォーマンス最適化済み
```

---

## 禁止事項

### 絶対に使用禁止

```php
// ❌ eval() - 任意コード実行の危険
eval($code);

// ❌ extract() - 変数汚染の危険
extract($_POST);

// ❌ グローバル変数の多用
global $user;

// ❌ register_globals的な使い方
$$variableName = 'value';

// ❌ エラー抑制演算子の安易な使用
@file_get_contents($file);  // 例外的に許可される場合のみ

// ❌ 直接のexit()呼び出し - ApplicationHelper::appExit()を使用
exit();  // ❌ テスト時に問題が発生
die();   // ❌ 同様に禁止

// ✅ 正しい終了処理
ApplicationHelper::appExit();  // テスト対応済み
```

### exit()使用ルール（重要）

**プログラム終了時は必ず`ApplicationHelper::appExit()`を使用してください。**

#### 理由
- PHPUnitテスト時に`exit()`を呼ぶとテストが中断される
- `appExit()`はテストモード時のみexit()をスキップする
- 本番環境では通常通りexit()が実行される

#### 実装例

```php
// ❌ 間違い
protected function jsonResponse(array $data, int $statusCode = 200): void
{
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();  // ❌ 直接呼び出しは禁止
}

// ✅ 正しい
protected function jsonResponse(array $data, int $statusCode = 200): void
{
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    ApplicationHelper::appExit();  // ✅ ラッパー関数を使用
}
```

#### ApplicationHelper::appExit()の実装

```php
/**
 * アプリケーション終了処理
 * 
 * テスト時はexit()をスキップし、本番環境では正常にexit()を呼び出す。
 * プログラム内で直接exit()を呼ばず、必ずこのメソッドを使用すること。
 * 
 * @param int $status 終了ステータスコード（デフォルト: 0）
 * @return void
 */
public static function appExit(int $status = 0): void
{
    // PHPUnitテスト時はexit()をスキップ
    if (!defined('PHPUNIT_TEST_MODE')) {
        exit($status);
    }
}
```

#### メリット

1. **テスト可能性**: ユニットテストでControllerの出力を検証可能
2. **一元管理**: テストモード判定が1箇所に集約
3. **保守性**: 将来的な終了処理の変更が容易
4. **一貫性**: プロジェクト全体で統一されたexit処理


### 非推奨（使用を避ける）

```php
// ⚠️ 短いタグ（<?= 以外）
<? echo $value; ?>  // ❌ 使用禁止
<?= $value ?>  // ✅ これはOK

// ⚠️ mysql_* 関数（PHP7で削除済み）
mysql_connect();  // ❌ PDOを使用

// ⚠️ ereg系関数（preg_を使用）
ereg();  // ❌
preg_match();  // ✅
```

---

## PHP7.4互換性

### PHP7.4で使用可能な機能

```php
// ✅ Typed Properties
class User
{
    private int $id;
    private string $name;
    private ?string $email = null;
}

// ✅ Arrow Functions
$numbers = array_map(fn($n) => $n * 2, [1, 2, 3]);

// ✅ Null Coalescing Assignment
$data['key'] ??= 'default';

// ✅ Spread Operator in Arrays
$array1 = [1, 2, 3];
$array2 = [...$array1, 4, 5];
```

### PHP8で追加される機能（将来の移行準備）

```php
// ❌ PHP7.4では使用不可（PHP8+）
// Union Types
function process(int|string $value) {}  // ❌ PHP7.4ではエラー

// Named Arguments
getValue(name: 'test', id: 1);  // ❌ PHP7.4ではエラー

// Match Expression
$result = match($value) {  // ❌ PHP7.4ではエラー
    1 => 'one',
    2 => 'two',
};

// ✅ PHP7.4での代替実装
function process($value): void {
    if (!is_int($value) && !is_string($value)) {
        throw new InvalidArgumentException();
    }
}
```

### コメントで将来の移行を記録

```php
/**
 * 値を処理
 * 
 * @param int|string $value  // TODO: PHP8移行時に Union Types (int|string) に変更
 * @return void
 */
public function process($value): void
{
    // 実装
}
```

---

## チェックリスト

新規PHP実装時の確認項目：

- [ ] `declare(strict_types=1);` を記述
- [ ] 名前空間を正しく設定
- [ ] すべての引数・戻り値に型宣言
- [ ] PHPDocを記述（クラス・publicメソッド）
- [ ] PSR-12に準拠
- [ ] エラーハンドリング実装（try-catch）
- [ ] セキュリティチェック（XSS/CSRF/SQLi対策）
- [ ] 禁止関数を使用していないか確認
- [ ] PHP7.4互換性を確認

---

**参照**: [PSR-12公式仕様](https://www.php-fig.org/psr/psr-12/)
