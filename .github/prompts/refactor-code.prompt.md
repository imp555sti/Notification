---
name: refactor-code
description: コードのリファクタリング。DI対応、複雑度削減、PSR-12準拠化
tools:
  - read
  - edit
  - search
  - vscode/getProjectSetupInfo
---

# Refactor Code Prompt

既存コードをプロジェクトルールに準拠するようリファクタリングします。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

以下のリファクタリングを実行します：

1. **DI対応**（コンストラクタインジェクション）
2. **複雑度削減**（ネスト・メソッド長）
3. **PSR-12準拠化**（コーディング規約）
4. **型宣言追加**（引数・戻り値）

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

#### ケース1: 特定ファイルのリファクタリング

```
/refactor-code

以下のファイルをリファクタリングしてください。

ファイル: src/app/Service/UserService.php

重点項目:
1. DI未使用の `new` をコンストラクタインジェクションに変更
2. 複雑度が高いメソッドを分割
3. PSR-12準拠化
4. 型宣言の追加

.github/instructions/php.instructions.md と
.github/instructions/architecture.instructions.md を参照してください。
```

#### ケース2: ワークスペース全体のリファクタリング

```
/refactor-code

**🔨 ワークスペース全体を対象に**、
レガシーコードをリファクタリングしてください。

優先度順：

1. **DI対応（高優先度）**
   - `new` で直接インスタンス化しているコード
   - グローバル変数の使用
   - 静的メソッド呼び出し（テスト困難）

2. **複雑度削減（中優先度）**
   - ネストが3段階以上
   - 1メソッド 50行以上
   - 条件分岐が多い（10以上）

3. **型宣言追加（中優先度）**
   - 引数の型なし
   - 戻り値の型なし

4. **PSR-12準拠（低優先度）**
   - インデント・空白
   - 命名規則

.github/instructions/php.instructions.md を参照してください。
```

---

## リファクタリングガイドライン

### 1. DI対応

**Before（DI未使用）**:

```php
class UserService
{
    private UserRepository $userRepository;

    public function __construct()
    {
        $database = new Database();
        $this->userRepository = new UserRepository($database);
    }
}
```

**After（DI使用）**:

```php
class UserService
{
    private UserRepository $userRepository;

    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
}
```

### 2. 複雑度削減

**Before（ネスト深い）**:

```php
public function processOrder(Order $order): void
{
    if ($order->isValid()) {
        if ($order->getTotalAmount() > 0) {
            if ($this->hasInventory($order)) {
                if ($this->isCustomerActive($order->getCustomerId())) {
                    $this->repository->save($order);
                }
            }
        }
    }
}
```

**After（ガード句で早期リターン）**:

```php
public function processOrder(Order $order): void
{
    if (!$order->isValid()) {
        return;
    }

    if ($order->getTotalAmount() <= 0) {
        return;
    }

    if (!$this->hasInventory($order)) {
        return;
    }

    if (!$this->isCustomerActive($order->getCustomerId())) {
        return;
    }

    $this->repository->save($order);
}
```

### 3. メソッド分割

**Before（50行超え）**:

```php
public function createUserWithProfile(array $data): User
{
    // バリデーション 10行
    // Entityの生成 5行
    // プロフィール作成 10行
    // 画像アップロード 10行
    // メール送信 10行
}
```

**After（メソッド分割）**:

```php
public function createUserWithProfile(array $data): User
{
    $this->validateData($data);
    
    $user = $this->createUser($data);
    $this->createProfile($user, $data);
    $this->uploadProfileImage($user, $data);
    $this->sendWelcomeEmail($user);
    
    return $user;
}

private function validateData(array $data): void
{
    // バリデーション
}

private function createUser(array $data): User
{
    // ユーザー作成
}

private function createProfile(User $user, array $data): void
{
    // プロフィール作成
}

private function uploadProfileImage(User $user, array $data): void
{
    // 画像アップロード
}

private function sendWelcomeEmail(User $user): void
{
    // メール送信
}
```

### 4. 型宣言追加

**Before**:

```php
public function calculateTotal($items, $taxRate)
{
    $total = 0;
    foreach ($items as $item) {
        $total += $item['price'] * $item['quantity'];
    }
    return $total * (1 + $taxRate);
}
```

**After**:

```php
public function calculateTotal(array $items, float $taxRate): float
{
    $total = 0;
    foreach ($items as $item) {
        $total += $item['price'] * $item['quantity'];
    }
    return $total * (1 + $taxRate);
}
```

**参照**: `.github/instructions/php.instructions.md`