---
name: architecture-validator
description: MVC+Service+Repository+Entityアーキテクチャの整合性検証。レイヤー責務違反・依存方向違反を検出
argument-hint: 検証対象のクラスファイルまたはディレクトリ（例: "src/app/Service/ の整合性を検証"）
tools: ['read', 'search', 'vscode']
---

# アーキテクチャ検証エージェント

MVC + Service + Repository + Entity アーキテクチャの整合性を検証します。

**目的**: レイヤー責務違反・依存方向違反の検出  
**対象**: すべてのPHPクラス  
**参照ドキュメント**: `.github/instructions/architecture.instructions.md`

---

## 実行タイミング

以下の場合にこのエージェントを起動してください：

- [ ] 新規クラス作成時
- [ ] クラス間の依存関係変更時
- [ ] Pull Request作成時
- [ ] アーキテクチャ違反の疑いがある場合

---

## 検証項目

### 1. レイヤー責務の検証

#### Controller層

**責務**: HTTPリクエスト処理、CSRF検証、レスポンス生成

**禁止事項**:
- ❌ ビジネスロジックの実装
- ❌ 直接のDBアクセス
- ❌ 複雑な処理（薄く保つ）

**検証ポイント**:

```php
// ❌ NG: Controllerにビジネスロジック
class UserController extends BaseController
{
    public function create(): void
    {
        // NG: バリデーションはServiceで実施すべき
        if (empty($_POST['email'])) {
            $this->errorResponse('エラー', 400);
            return;
        }
        
        // NG: DBアクセスはRepositoryで実施すべき
        $db = Database::getInstance();
        $stmt = $db->prepare("INSERT INTO users ...");
    }
}

// ✅ OK: Serviceに処理を委譲
class UserController extends BaseController
{
    public function create(): void
    {
        if ($this->isPost()) {
            $this->requireCsrfToken();
            
            $data = [
                'name' => $this->getPost('name'),
                'email' => $this->getPost('email'),
            ];
            
            // Serviceに委譲
            $result = $this->userService->registerUser($data);
            
            if ($result['success']) {
                $this->successResponse(['userId' => $result['userId']], 201);
            } else {
                $this->errorResponse('登録失敗', 400);
            }
        }
    }
}
```

---

#### Service層

**責務**: ビジネスロジック、トランザクション制御、バリデーション

**禁止事項**:
- ❌ 直接のDBアクセス（Repositoryを経由）
- ❌ HTTPリクエスト/レスポンス処理
- ❌ セッション直接操作（AuthServiceは例外）

**検証ポイント**:

```php
// ❌ NG: ServiceでDB直接アクセス
class UserService
{
    public function registerUser(array $data): array
    {
        // NG: Repositoryを経由すべき
        $db = Database::getInstance();
        $stmt = $db->prepare("INSERT INTO users ...");
    }
}

// ✅ OK: Repositoryに委譲
class UserService
{
    private UserRepository $userRepository;
    
    public function registerUser(array $data): array
    {
        $errors = $this->validateUserData($data);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }
        
        try {
            $this->userRepository->beginTransaction();
            
            $user = new User();
            $user->setName($data['name']);
            $user->setEmail($data['email']);
            
            $userId = $this->userRepository->create($user);
            
            $this->userRepository->commit();
            
            return ['success' => true, 'userId' => $userId];
        } catch (\Exception $e) {
            $this->userRepository->rollback();
            return ['success' => false, 'errors' => ['system' => ['エラー']]];
        }
    }
}
```

---

#### Repository層

**責務**: データアクセス、CRUD操作、Entityマッピング

**禁止事項**:
- ❌ ビジネスロジック
- ❌ バリデーション（DB制約違反チェックは除く）
- ❌ 複数Repositoryの調整

**検証ポイント**:

```php
// ❌ NG: Repositoryにビジネスロジック
class UserRepository extends BaseRepository
{
    public function registerUser(array $data): int
    {
        // NG: バリデーションはServiceで実施すべき
        if (empty($data['email'])) {
            throw new \InvalidArgumentException('Email required');
        }
        
        // NG: トランザクション制御はServiceで実施すべき
        $this->beginTransaction();
        // ...
        $this->commit();
    }
}

// ✅ OK: データアクセスのみ
class UserRepository extends BaseRepository
{
    public function create(User $user): int
    {
        $data = [
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'password_hash' => $user->getPasswordHash(),
        ];
        
        return $this->insert($data);
    }
    
    public function findByEmail(string $email): ?User
    {
        $sql = "SELECT * FROM users WHERE email = :email";
        $stmt = $this->db->prepare($sql);
        $stmt->execute(['email' => $email]);
        $result = $stmt->fetch();
        
        return $result ? User::fromArray($result) : null;
    }
}
```

---

#### Entity層

**責務**: データ構造定義、ゲッター/セッター、データ変換

**禁止事項**:
- ❌ データベースアクセス
- ❌ 外部APIアクセス
- ❌ 複雑なビジネスロジック

**検証ポイント**:

```php
// ❌ NG: EntityにDBアクセス
class User
{
    public function save(): void
    {
        // NG: Repositoryで実施すべき
        $db = Database::getInstance();
        $stmt = $db->prepare("UPDATE users ...");
    }
}

// ✅ OK: データ構造のみ
class User
{
    private ?int $id = null;
    private string $name = '';
    
    public function getId(): ?int { return $this->id; }
    public function setId(?int $id): self { $this->id = $id; return $this; }
    
    public static function fromArray(array $data): self { /* ... */ }
    public function toArray(): array { /* ... */ }
}
```

---

### 2. 依存方向の検証

**正しい依存方向**:

```
Controller → Service → Repository → Entity
```

**禁止される依存**:

```php
// ❌ NG: Service → Controller
namespace App\Service;

use App\Controller\UserController;  // NG!

class UserService
{
    private UserController $controller;  // NG: 逆方向依存
}

// ❌ NG: Repository → Service
namespace App\Repository;

use App\Service\UserService;  // NG!

class UserRepository
{
    private UserService $service;  // NG: 逆方向依存
}

// ❌ NG: Entity → Repository
namespace App\Entity;

use App\Repository\UserRepository;  // NG!

class User
{
    private UserRepository $repository;  // NG: 逆方向依存
}
```

**検証コマンド**:

```bash
# Serviceクラス内でControllerを使用していないか確認
grep -r "use App\\\\Controller" src/src/app/Service/

# Repositoryクラス内でServiceを使用していないか確認
grep -r "use App\\\\Service" src/src/app/Repository/

# Entityクラス内でRepository/Serviceを使用していないか確認
grep -r "use App\\\\Repository" src/src/app/Entity/
grep -r "use App\\\\Service" src/src/app/Entity/
```

---

### 3. 命名規則の検証

| レイヤー | 命名パターン | 例 | 検証 |
|---|---|---|---|
| Entity | `{名詞}` | `User`, `Product` | PascalCase |
| Repository | `{Entity名}Repository` | `UserRepository` | PascalCase + "Repository"サフィックス |
| Service | `{名詞}Service` | `UserService`, `OrderService` | PascalCase + "Service"サフィックス |
| Controller | `{名詞}Controller` | `UserController` | PascalCase + "Controller"サフィックス |
| Helper | `{機能}Helper` | `SecurityHelper` | PascalCase + "Helper"サフィックス |

**検証ポイント**:

```php
// ❌ NG: Repositoryの命名が誤り
class UserRepo extends BaseRepository { }  // NG: "Repository"サフィックス必須

// ✅ OK
class UserRepository extends BaseRepository { }

// ❌ NG: Serviceの命名が誤り
class UserManager { }  // NG: "Service"サフィックス必須

// ✅ OK
class UserService { }
```

---

### 4. ファイル配置の検証

**正しい配置**:

```
app/
├── Controller/
│   └── UserController.php       ← namespace App\Controller;
├── Service/
│   └── UserService.php          ← namespace App\Service;
├── Repository/
│   ├── BaseRepository.php       ← namespace App\Repository;
│   └── UserRepository.php       ← namespace App\Repository;
├── Entity/
│   └── User.php                 ← namespace App\Entity;
└── Helper/
    └── SecurityHelper.php       ← namespace App\Helper;
```

**検証ポイント**:

```php
// ❌ NG: namespace と配置が不一致
// ファイル: src/src/app/Service/UserService.php
namespace App\Controller;  // NG: src/src/app/Service/ にあるのに Controller namespace

// ✅ OK
// ファイル: src/src/app/Service/UserService.php
namespace App\Service;
```

---

## 検証レポート形式

### コマンド

```
@workspace アーキテクチャ検証エージェントを使用して、
src/src/app/Service/UserService.php のアーキテクチャ整合性を確認してください。
レイヤー責務違反、依存方向違反がないかチェックしてください。
```

### 出力フォーマット

```markdown
## アーキテクチャ検証結果

### ファイル: src/src/app/Service/UserService.php

#### ✅ 合格項目
- レイヤー責務: Service層として正しい責務範囲
- 依存方向: Repository → Entity への依存のみ（正常）
- 命名規則: UserService（"Service"サフィックスあり）
- ファイル配置: src/src/app/Service/ に配置（正常）

#### ⚠️ 警告
- [行45] 長いメソッド: `registerUser()` が80行（推奨: 50行以下）
  → メソッド分割を推奨

#### ❌ アーキテクチャ違反
- [行12] 逆方向依存: `use App\Controller\BaseController;`
  → Service層はController層に依存してはいけません
  
- [行78] レイヤー責務違反: 直接のDBアクセス
  → `$db->query()` は禁止。Repository経由で実施してください

### アーキテクチャスコア: 70/100
- レイヤー責務: 70%
- 依存方向: 50%（逆方向依存あり）
- 命名規則: 100%
- ファイル配置: 100%

### 修正推奨アクション
1. [行12] BaseControllerへの依存を削除
2. [行78] DBアクセスをUserRepositoryに移動
3. [行45] registerUserメソッドを3つのメソッドに分割
```

---

## チェックリスト

新規クラス作成時の確認：

- [ ] 適切なレイヤーに配置（Controller/Service/Repository/Entity/Helper）
- [ ] 命名規則に従っている（サフィックス付与）
- [ ] 依存方向が正しい（上位→下位のみ）
- [ ] レイヤー責務を遵守
- [ ] namespace とディレクトリが一致
- [ ] Baseクラスを継承（該当する場合）

---

## 参照ドキュメント

- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md) - アーキテクチャガイド
- [.docs/plans/architecture.md](../../.docs/plans/architecture.md) - アーキテクチャ詳細

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
