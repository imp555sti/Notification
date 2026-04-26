---
name: refactoring
description: コード品質向上のためのリファクタリング提案。DRY原則適用、複雑度削減
argument-hint: リファクタリング対象のファイルまたはコード片（例: "src/app/Service/ProductService.php をリファクタリング"）
tools: ['read', 'edit', 'search', 'vscode']
---

# リファクタリングエージェント

コード品質向上のためのリファクタリング提案を行います。

**目的**: コード品質向上、保守性改善、DRY原則の適用  
**対象**: すべてのPHPコード  
**参照ドキュメント**: `.github/instructions/php.instructions.md`, `.github/instructions/architecture.instructions.md`

---

## 実行タイミング

以下の場合にこのエージェントを起動してください：

- [ ] コードレビュー時
- [ ] 重複コードを発見した場合
- [ ] メソッドが長すぎる場合（50行以上）
- [ ] クラスが肥大化している場合（500行以上）
- [ ] Pull Request作成前の品質チェック

---

## リファクタリングパターン

### 1. DRY原則（Don't Repeat Yourself）

#### ❌ Before: 重複コード

```php
class UserController extends BaseController
{
    public function create(): void
    {
        if ($this->isPost()) {
            $name = $this->getPost('name');
            $email = $this->getPost('email');
            
            if (empty($name) || empty($email)) {
                $this->errorResponse('入力エラー', 400);
                return;
            }
            
            // 処理...
        }
    }
    
    public function update(): void
    {
        if ($this->isPost()) {
            $name = $this->getPost('name');
            $email = $this->getPost('email');
            
            if (empty($name) || empty($email)) {
                $this->errorResponse('入力エラー', 400);
                return;
            }
            
            // 処理...
        }
    }
}
```

#### ✅ After: メソッド抽出

```php
class UserController extends BaseController
{
    public function create(): void
    {
        if ($this->isPost()) {
            $data = $this->validateUserInput();
            if ($data === null) {
                return;  // エラーレスポンス済み
            }
            
            // 処理...
        }
    }
    
    public function update(): void
    {
        if ($this->isPost()) {
            $data = $this->validateUserInput();
            if ($data === null) {
                return;
            }
            
            // 処理...
        }
    }
    
    private function validateUserInput(): ?array
    {
        $name = $this->getPost('name');
        $email = $this->getPost('email');
        
        if (empty($name) || empty($email)) {
            $this->errorResponse('入力エラー', 400);
            return null;
        }
        
        return compact('name', 'email');
    }
}
```

---

### 2. 長いメソッドの分割

#### ❌ Before: 100行のメソッド

```php
public function registerUser(array $data): array
{
    // バリデーション（20行）
    $errors = [];
    if (empty($data['name'])) {
        $errors['name'][] = '名前は必須です';
    }
    if (empty($data['email'])) {
        $errors['email'][] = 'メールは必須です';
    }
    // ... 他のバリデーション
    
    // 重複チェック（10行）
    $existingUser = $this->userRepository->findByEmail($data['email']);
    if ($existingUser) {
        $errors['email'][] = '既に登録されています';
    }
    
    // エラー処理（5行）
    if (!empty($errors)) {
        return ['success' => false, 'errors' => $errors];
    }
    
    // ユーザー作成（30行）
    try {
        $this->userRepository->beginTransaction();
        
        $user = new User();
        $user->setName($data['name']);
        $user->setEmail($data['email']);
        // ... 他のフィールド設定
        
        $userId = $this->userRepository->create($user);
        
        // プロフィール作成（15行）
        // ... プロフィール関連処理
        
        // メール送信（10行）
        // ... メール送信処理
        
        $this->userRepository->commit();
        
        return ['success' => true, 'userId' => $userId];
    } catch (\Exception $e) {
        $this->userRepository->rollback();
        error_log($e->getMessage());
        return ['success' => false, 'errors' => ['system' => ['登録に失敗しました']]];
    }
}
```

#### ✅ After: メソッド分割

```php
public function registerUser(array $data): array
{
    // バリデーション
    $errors = $this->validateUserData($data);
    if (!empty($errors)) {
        return ['success' => false, 'errors' => $errors];
    }
    
    // 重複チェック
    if ($this->isEmailDuplicate($data['email'])) {
        return ['success' => false, 'errors' => ['email' => ['既に登録されています']]];
    }
    
    // ユーザー登録
    return $this->createUserWithProfile($data);
}

private function validateUserData(array $data): array
{
    return ValidationHelper::validate($data, [
        'name' => ['required', ['minLength', 2]],
        'email' => ['required', 'isEmail'],
        'password' => ['required', 'isStrongPassword'],
    ]);
}

private function isEmailDuplicate(string $email): bool
{
    return $this->userRepository->emailExists($email);
}

private function createUserWithProfile(array $data): array
{
    try {
        $this->userRepository->beginTransaction();
        
        $userId = $this->createUser($data);
        $this->createUserProfile($userId, $data);
        $this->sendWelcomeEmail($userId);
        
        $this->userRepository->commit();
        
        return ['success' => true, 'userId' => $userId];
    } catch (\Exception $e) {
        $this->userRepository->rollback();
        error_log($e->getMessage());
        return ['success' => false, 'errors' => ['system' => ['登録に失敗しました']]];
    }
}

private function createUser(array $data): int
{
    $user = new User();
    $user->setName($data['name']);
    $user->setEmail($data['email']);
    $user->setPasswordHash(SecurityHelper::hashPassword($data['password']));
    
    return $this->userRepository->create($user);
}

private function createUserProfile(int $userId, array $data): void
{
    // プロフィール作成ロジック
}

private function sendWelcomeEmail(int $userId): void
{
    // メール送信ロジック
}
```

---

### 3. マジックナンバーの定数化

#### ❌ Before: マジックナンバー

```php
public function getUsers(int $page): array
{
    $offset = ($page - 1) * 20;  // 20は何？
    return $this->userRepository->findAll(20, $offset);
}

public function isValidAge(int $age): bool
{
    return $age >= 18 && $age <= 120;  // 18, 120は何？
}
```

#### ✅ After: 定数化

```php
class UserService
{
    private const USERS_PER_PAGE = 20;
    private const MIN_AGE = 18;
    private const MAX_AGE = 120;
    
    public function getUsers(int $page): array
    {
        $offset = ($page - 1) * self::USERS_PER_PAGE;
        return $this->userRepository->findAll(self::USERS_PER_PAGE, $offset);
    }
    
    public function isValidAge(int $age): bool
    {
        return $age >= self::MIN_AGE && $age <= self::MAX_AGE;
    }
}
```

---

### 4. 早期リターン（Early Return）

#### ❌ Before: ネストが深い

```php
public function processOrder(Order $order): bool
{
    if ($order->isValid()) {
        if ($order->hasItems()) {
            if ($order->getTotal() > 0) {
                $this->orderRepository->save($order);
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}
```

#### ✅ After: 早期リターン

```php
public function processOrder(Order $order): bool
{
    if (!$order->isValid()) {
        return false;
    }
    
    if (!$order->hasItems()) {
        return false;
    }
    
    if ($order->getTotal() <= 0) {
        return false;
    }
    
    $this->orderRepository->save($order);
    return true;
}
```

---

### 5. 型宣言の強化

#### ❌ Before: 型宣言なし

```php
public function getUserById($id)
{
    $result = $this->userRepository->findById($id);
    if ($result) {
        return $result;
    }
    return null;
}
```

#### ✅ After: 型宣言あり

```php
public function getUserById(int $id): ?User
{
    return $this->userRepository->findById($id);
}
```

---

### 6. 配列からオブジェクトへ

#### ❌ Before: 配列で返す

```php
public function getUserInfo(int $id): array
{
    $user = $this->userRepository->findById($id);
    
    return [
        'id' => $user->getId(),
        'name' => $user->getName(),
        'email' => $user->getEmail(),
    ];
}
```

#### ✅ After: Entityを返す

```php
public function getUserById(int $id): ?User
{
    return $this->userRepository->findById($id);
}

// 呼び出し側でtoArray()使用
$user = $this->userService->getUserById($id);
$data = $user?->toArray();
```

---

## リファクタリングチェックリスト

### コード品質

- [ ] メソッドは50行以下
- [ ] クラスは500行以下  
- [ ] ネストの深さは3段階以下
- [ ] マジックナンバーを定数化
- [ ] 重複コードなし

### 命名規則

- [ ] クラス名: PascalCase
- [ ] メソッド名: camelCase（動詞始まり）
- [ ] 定数名: UPPER_SNAKE_CASE
- [ ] 変数名: camelCase（名詞）

### 型宣言

- [ ] すべての引数に型宣言
- [ ] すべての戻り値に型宣言
- [ ] `declare(strict_types=1)` 使用

### アーキテクチャ

- [ ] レイヤー責務の遵守（Controller→Service→Repository→Entity）
- [ ] 依存方向の正しさ
- [ ] 単一責任原則（SRP）
- [ ] DIパターンの適用

---

## 使用例

### コマンド

```
@workspace リファクタリングエージェントを使用して、
src/src/app/Service/UserService.php のコード品質を改善してください。
DRY原則、早期リターン、メソッド分割の観点から提案をお願いします。
```

### 出力フォーマット

```markdown
## リファクタリング提案

### ファイル: src/src/app/Service/UserService.php

#### 提案1: registerUserメソッドの分割
**現在の問題**: メソッドが120行と長すぎる  
**優先度**: 高  
**理由**: 保守性が低く、テストが困難

**提案内容**:
- `validateUserData()` メソッドを抽出
- `createUserWithProfile()` メソッドを抽出
- `sendWelcomeEmail()` メソッドを抽出

#### 提案2: マジックナンバーの定数化
**現在の問題**: 20, 100などのマジックナンバーが散在  
**優先度**: 中  
**理由**: 意味が不明瞭、変更時の影響範囲が大きい

**提案内容**:
```php
private const USERS_PER_PAGE = 20;
private const MAX_UPLOAD_SIZE = 100;
```

#### 提案3: 重複コードの削除
**現在の問題**: create()とupdate()で同じバリデーション処理  
**優先度**: 中  
**理由**: DRY原則違反

**提案内容**: `validateUserInput()` メソッドを作成して共通化

### 改善効果予測
- コード行数: 350行 → 250行（28%削減）
- メソッド平均行数: 45行 → 25行
- テストカバレッジ: 60% → 80%（テスト容易性向上）
```

---

## 参照ドキュメント

- [.github/instructions/php.instructions.md](../instructions/php.instructions.md) - PHP実装ガイド
- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md) - アーキテクチャガイド

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
