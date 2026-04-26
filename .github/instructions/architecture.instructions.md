# アーキテクチャ設計ガイド

MVC + Service + Repository + Entity アーキテクチャの実装ガイドです。

## 📋 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [レイヤー責務](#レイヤー責務)
3. [依存方向のルール](#依存方向のルール)
4. [Entity層](#entity層)
5. [Repository層](#repository層)
6. [Service層](#service層)
7. [Controller層](#controller層)
8. [Helper層](#helper層)
9. [命名規則](#命名規則)
10. [DI実装](#di実装)

---

## アーキテクチャ概要

### レイヤー構成

```
┌──────────────┐
│  Controller  │  ← HTTPリクエスト処理、レスポンス生成
└──────┬───────┘
       ↓
┌──────────────┐
│   Service    │  ← ビジネスロジック、トランザクション制御
└──────┬───────┘
       ↓
┌──────────────┐
│  Repository  │  ← データアクセス、CRUD操作
└──────┬───────┘
       ↓
┌──────────────┐
│    Entity    │  ← データ構造、ドメインモデル
└──────────────┘
```

### データフロー  

**リクエスト→レスポンス**:  
`HTTPリクエスト → Controller → Service → Repository → Entity → DB`  
`HTTPレスポンス ← Controller ← Service ← Repository ← Entity ← DB`

---

## レイヤー責務

### Entity層：データ構造のみ

**責務**:
- データ構造の定義
- ゲッター/セッター
- データ変換（`toArray()`, `fromArray()`）
- 簡単なドメインロジック（値オブジェクト的な振る舞い）

**禁止事項**:
- ❌ データベースアクセス
- ❌ 外部APIアクセス
- ❌ 複雑なビジネスロジック
- ❌ 他のEntityへの依存（関連は許可）

```php
// ✅ 正しいEntity実装
namespace App\Entity;

class User
{
    private ?int $id = null;
    private string $name = '';
    private string $email = '';
    
    // ゲッター/セッター
    public function getId(): ?int { return $this->id; }
    public function setId(?int $id): self { $this->id = $id; return $this; }
    
    // 変換メソッド
    public static function fromArray(array $data): self { /* ... */ }
    public function toArray(bool $includePassword = false): array { /* ... */ }
    
    // ✅ 簡単なドメインロジックはOK
    public function isActive(): bool
    {
        return $this->status === 'active';
    }
}
```

### Repository層：データアクセスのみ

**責務**:
- CRUD操作
- データベースクエリ構築
- Entityマッピング（配列 ⇔ Entity変換）
- トランザクション管理

**禁止事項**:
- ❌ ビジネスロジック
- ❌ バリデーション（DBレベルの制約違反チェックは除く）
- ❌ 複数Repositoryの調整
- ❌ HTTPレスポンス生成

```php
// ✅ 正しいRepository実装
namespace App\Repository;

class UserRepository extends BaseRepository
{
    protected string $table = 'users';
    
    // ✅ データアクセスのみ
    public function findByEmail(string $email): ?User
    {
        $stmt = $this->db->prepare("SELECT * FROM {$this->table} WHERE email = :email");
        $stmt->execute(['email' => $email]);
        $result = $stmt->fetch();
        
        return $result ? User::fromArray($result) : null;
    }
    
    // ✅ Entityマッピング
    public function create(User $user): int
    {
        $data = [
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'password_hash' => $user->getPasswordHash(),
        ];
        
        return $this->insert($data);
    }
    
    // ❌ ビジネスロジックは禁止（Serviceで実装）
    // public function registerUser(array $data): int { /* NG */ }
}
```

### Service層：ビジネスロジック

**責務**:
- ビジネスロジックの実装
- 複数Repositoryの調整
- トランザクション制御
- バリデーション
- エラーハンドリング

**禁止事項**:
- ❌ 直接のDBアクセス（Repositoryを経由）
- ❌ HTTPリクエスト/レスポンス処理
- ❌ セッション直接操作（AuthServiceは例外）

```php
// ✅ 正しいService実装
namespace App\Service;

class UserService
{
    private UserRepository $userRepository;
    
    public function __construct(UserRepository $userRepository)
    {
        $this->userRepository = $userRepository;
    }
    
    // ✅ ビジネスロジック + トランザクション
    public function registerUser(array $data): array
    {
        // バリデーション
        $errors = $this->validateUserData($data);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }
        
        // 重複チェック（ビジネスルール）
        if ($this->userRepository->emailExists($data['email'])) {
            return ['success' => false, 'errors' => ['email' => ['既に登録されています']]];
        }
        
        try {
            // トランザクション開始
            $this->userRepository->beginTransaction();
            
            $user = new User();
            $user->setName($data['name']);
            $user->setEmail($data['email']);
            $user->setPasswordHash(SecurityHelper::hashPassword($data['password']));
            
            $userId = $this->userRepository->create($user);
            
            // 他のビジネスロジック（例: ウェルカムメール送信）
            // $this->emailService->sendWelcomeEmail($user);
            
            $this->userRepository->commit();
            
            return ['success' => true, 'userId' => $userId];
        } catch (\Exception $e) {
            $this->userRepository->rollback();
            error_log($e->getMessage());
            return ['success' => false, 'errors' => ['system' => ['登録に失敗しました']]];
        }
    }
}
```

### Controller層：リクエスト処理

**責務**:
- HTTPリクエスト受信
- 入力値取得
- CSRF検証
- Serviceメソッド呼び出し
- HTTPレスポンス生成

**禁止事項**:
- ❌ ビジネスロジック（Serviceに委譲）
- ❌ 直接のDBアクセス
- ❌ 複雑な処理（薄く保つ）

```php
// ✅ 正しいController実装
namespace App\Controller;

class UserController extends BaseController
{
    private UserService $userService;
    
    public function __construct()
    {
        $this->userService = new UserService();
    }
    
    public function create(): void
    {
        if ($this->isPost()) {
            // CSRF検証
            $this->requireCsrfToken();
            
            // 入力取得
            $data = [
                'name' => $this->getPost('name'),
                'email' => $this->getPost('email'),
                'password' => $this->getPost('password'),
            ];
            
            // ✅ Serviceに処理を委譲
            $result = $this->userService->registerUser($data);
            
            // レスポンス生成
            if ($result['success']) {
                $this->successResponse(['userId' => $result['userId']], 201);
            } else {
                $this->errorResponse('登録に失敗しました', 400);
            }
        }
    }
    
    // ❌ ビジネスロジックは禁止
    // public function create(): void
    // {
    //     // NG: Controllerでバリデーション・DB操作
    // }
}
```

### Helper層：横断的ユーティリティ

**責務**:
- セキュリティ機能（SecurityHelper）
- バリデーション機能（ValidationHelper）
- 日付操作（DateHelper）
- 文字列操作（StringHelper）

**特徴**:
- すべてstaticメソッド
- 状態を持たない（ステートレス）
- どのレイヤーからでも使用可能

```php
// ✅ 正しいHelper実装
namespace App\Helper;

class SecurityHelper
{
    // ✅ staticメソッド、ステートレス
    public static function escape(string $string): string
    {
        return htmlspecialchars($string, ENT_QUOTES, 'UTF-8');
    }
    
    public static function generateCsrfToken(): string
    {
        // 実装
    }
}
```

---

## 依存方向のルール

### 依存の流れ

```
Controller → Service → Repository → Entity
    ↓           ↓          ↓
  Helper ← ← ← ← ← ← ← ← ← ← ←
```

### 許可される依存

- ✅ Controller → Service
- ✅ Controller → Helper
- ✅ Service → Repository
- ✅ Service → Entity
- ✅ Service → Helper
- ✅ Repository → Entity
- ✅ Repository → Helper

### 禁止される依存

- ❌ Service → Controller
- ❌ Repository → Service
- ❌ Repository → Controller
- ❌ Entity → Repository
- ❌ Entity → Service
- ❌ Entity → Controller

### 検証方法

```bash
# Serviceクラス内でControllerを使用していないか確認
grep -r "use App\\\\Controller" src/src/app/Service/

# Repositoryクラス内でServiceを使用していないか確認
grep -r "use App\\\\Service" src/src/app/Repository/
```

---

## Entity層

### 実装パターン

```php
namespace App\Entity;

use DateTime;

class User
{
    // ✅ 型付きプロパティ
    private ?int $id = null;
    private string $name = '';
    private string $email = '';
    private string $passwordHash = '';
    private ?DateTime $createdAt = null;
    private ?DateTime $updatedAt = null;
    
    // ✅ ゲッター（読み取り専用プロパティ）
    public function getId(): ?int
    {
        return $this->id;
    }
    
    // ✅ セッター（fluent interface）
    public function setId(?int $id): self
    {
        $this->id = $id;
        return $this;
    }
    
    // ✅ fromArray（配列→Entity）
    public static function fromArray(array $data): self
    {
        $user = new self();
        $user->setId($data['id'] ?? null);
        $user->setName($data['name'] ?? '');
        // ...
        return $user;
    }
    
    // ✅ toArray（Entity→配列）
    public function toArray(bool $includePassword = false): array
    {
        $data = [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
        ];
        
        if ($includePassword) {
            $data['password_hash'] = $this->passwordHash;
        }
        
        return $data;
    }
}
```

---

## Repository層

### BaseRepository継承

```php
namespace App\Repository;

class UserRepository extends BaseRepository
{
    protected string $table = 'users';  // テーブル名指定
    
    // カスタムクエリメソッド
    public function findByEmail(string $email): ?User { /* ... */ }
    public function findActiveUsers(): array { /* ... */ }
}
```

---

## Service層

### DI（依存注入）

```php
namespace App\Service;

class UserService
{
    private UserRepository $userRepository;
    private AuthService $authService;  // 他のServiceも注入可能
    
    // ✅ コンストラクタインジェクション
    public function __construct(
        ?UserRepository $userRepository = null,
        ?AuthService $authService = null
    ) {
        $this->userRepository = $userRepository ?? new UserRepository();
        $this->authService = $authService ?? new AuthService();
    }
}
```

---

## Controller層

### 基本構造

```php
namespace App\Controller;

class UserController extends BaseController
{
    private UserService $userService;
    
    public function __construct()
    {
        $this->userService = new UserService();
    }
    
    public function index(): void
    {
        // GETリクエスト処理
    }
    
    public function create(): void
    {
        if ($this->isPost()) {
            $this->requireCsrfToken();  // CSRF検証
            // POST処理
        }
    }
}
```

---

## 命名規則

### クラス名

| レイヤー | 命名パターン | 例 |
|---|---|---|
| Entity | `{名詞}` | `User`, `Product`, `Order` |
| Repository | `{Entity名}Repository` | `UserRepository`, `ProductRepository` |
| Service | `{名詞}Service` | `UserService`, `OrderService` |
| Controller | `{名詞}Controller` | `UserController`, `ApiController` |
| Helper | `{機能}Helper` | `SecurityHelper`, `ValidationHelper` |

### メソッド名

| レイヤー | 命名パターン | 例 |
|---|---|---|
| Repository | `find*`, `create`, `update`, `delete` | `findById()`, `findByEmail()`, `create()` |
| Service | `{動詞}{名詞}` | `getUser()`, `registerUser()`, `updateProfile()` |
| Controller | アクション名 | `index()`, `create()`, `update()`, `delete()` |

---

## DI実装

### シンプルな依存注入

```php
// ✅ コンストラクタインジェクション（テスト時にモック注入可能）
class UserService
{
    public function __construct(?UserRepository $repository = null)
    {
        $this->repository = $repository ?? new UserRepository();
    }
}

// テスト時
$mockRepo = $this->createMock(UserRepository::class);
$service = new UserService($mockRepo);
```

---

## アーキテクチャチェックリスト

新規クラス作成時の確認：

- [ ] 適切なレイヤーに配置
- [ ] 命名規則に従っている
- [ ] 依存方向が正しい（逆方向依存なし）
- [ ] 責務が単一（1クラス1責務）
- [ ] DI可能な設計（テスタビリティ）
- [ ] 型宣言を使用
- [ ] PHPDoc記述

---

**参照**: [.docs/plans/architecture.md](../../.docs/plans/architecture.md)
