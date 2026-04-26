# データベース操作ガイド

PostgreSQL + PDO を使用したデータベース操作の実装ガイドです。

## 📋 目次

1. [基本原則](#基本原則)
2. [Repository実装パターン](#repository実装パターン)
3. [Prepared Statement](#prepared-statement)
4. [トランザクション管理](#トランザクション管理)
5. [Entityマッピング](#entityマッピング)
6. [クエリビルダー](#クエリビルダー)
7. [N+1問題対策](#n1問題対策)
8. [エラーハンドリング](#エラーハンドリング)
9. [パフォーマンス最適化](#パフォーマンス最適化)

---

## 基本原則

### 必須ルール

1. **Prepared Statement必須**: すべてのクエリでPrepared Statementを使用
2. **Repository経由のみ**: 直接のPDOアクセスは`App\Config\Database`クラス以外禁止
3. **トランザクションはService層**: Repositoryはトランザクション管理しない
4. **Entityマッピング**: 配列⇔Entity変換を徹底

### PDO設定

```php
// App\Config\Database クラスで設定済み
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_EMULATE_PREPARES, false);  // 真のPrepared Statement
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
```

---

## Repository実装パターン

### BaseRepository継承

すべてのRepositoryは`BaseRepository`を継承します。

```php
namespace App\Repository;

class UserRepository extends BaseRepository
{
    protected string $table = 'users';  // テーブル名を指定
    
    // 以下BaseRepositoryから継承されるメソッド：
    // - find(int $id): ?array
    // - findAll(int $limit = 100, int $offset = 0): array
    // - findBy(array $conditions, int $limit = 100, int $offset = 0): array
    // - count(array $conditions = []): int
    // - insert(array $data): int
    // - update(int $id, array $data): bool
    // - delete(int $id): bool
    // - beginTransaction(): void
    // - commit(): void
    // - rollback(): void
}
```

### カスタムメソッド実装

```php
namespace App\Repository;

use App\Entity\User;

class UserRepository extends BaseRepository
{
    protected string $table = 'users';
    
    /**
     * メールアドレスでユーザーを検索
     *
     * @param string $email メールアドレス
     * @return User|null
     */
    public function findByEmail(string $email): ?User
    {
        $sql = "SELECT * FROM {$this->table} WHERE email = :email LIMIT 1";
        
        $stmt = $this->db->prepare($sql);
        $stmt->execute(['email' => $email]);
        $result = $stmt->fetch();
        
        return $result ? User::fromArray($result) : null;
    }
    
    /**
     * IDでユーザーを検索
     *
     * @param int $id ユーザーID
     * @return User|null
     */
    public function findById(int $id): ?User
    {
        $result = $this->find($id);  // BaseRepositoryのメソッド使用
        
        return $result ? User::fromArray($result) : null;
    }
    
    /**
     * 新規ユーザー作成
     *
     * @param User $user ユーザーエンティティ
     * @return int 作成されたユーザーID
     */
    public function create(User $user): int
    {
        $data = [
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'password_hash' => $user->getPasswordHash(),
        ];
        
        return $this->insert($data);  // BaseRepositoryのメソッド使用
    }
    
    /**
     * ユーザー更新
     *
     * @param User $user ユーザーエンティティ
     * @return bool 成功/失敗
     */
    public function updateUser(User $user): bool
    {
        if ($user->getId() === null) {
            throw new \InvalidArgumentException('User ID is required for update');
        }
        
        $data = $user->toArray(includePassword: true);
        unset($data['id'], $data['created_at']);  // 更新不可フィールド除外
        
        return $this->update($user->getId(), $data);
    }
}
```

---

## Prepared Statement

### 基本的な使い方

```php
// ✅ 正しい実装（名前付きプレースホルダー）
public function findByEmailAndStatus(string $email, string $status): ?User
{
    $sql = "SELECT * FROM users WHERE email = :email AND status = :status";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute([
        'email' => $email,
        'status' => $status,
    ]);
    
    $result = $stmt->fetch();
    return $result ? User::fromArray($result) : null;
}

// ❌ 間違った実装（文字列連結）
public function findByEmail(string $email): ?User
{
    // NG: SQLインジェクションの危険
    $sql = "SELECT * FROM users WHERE email = '{$email}'";
    $result = $this->db->query($sql)->fetch();
    return $result ? User::fromArray($result) : null;
}
```

### 複数レコード取得

```php
public function findActiveUsers(): array
{
    $sql = "SELECT * FROM users WHERE status = :status ORDER BY created_at DESC";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute(['status' => 'active']);
    
    $results = $stmt->fetchAll();
    
    // 配列→Entity変換
    return array_map(fn($row) => User::fromArray($row), $results);
}
```

### IN句の実装

```php
public function findByIds(array $ids): array
{
    if (empty($ids)) {
        return [];
    }
    
    // プレースホルダー生成: :id0, :id1, :id2, ...
    $placeholders = [];
    $params = [];
    foreach ($ids as $index => $id) {
        $placeholders[] = ":id{$index}";
        $params["id{$index}"] = $id;
    }
    
    $sql = sprintf(
        "SELECT * FROM users WHERE id IN (%s)",
        implode(',', $placeholders)
    );
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute($params);
    
    return array_map(fn($row) => User::fromArray($row), $stmt->fetchAll());
}
```

---

## トランザクション管理

### Service層でのトランザクション制御

```php
namespace App\Service;

class UserService
{
    private UserRepository $userRepository;
    
    public function registerUser(array $data): array
    {
        try {
            // ✅ Service層でトランザクション開始
            $this->userRepository->beginTransaction();
            
            $user = new User();
            $user->setName($data['name']);
            $user->setEmail($data['email']);
            $user->setPasswordHash(SecurityHelper::hashPassword($data['password']));
            
            $userId = $this->userRepository->create($user);
            
            // 関連データも保存（例: プロフィール）
            // $this->profileRepository->create($userId, $data['profile']);
            
            $this->userRepository->commit();
            
            return ['success' => true, 'userId' => $userId];
        } catch (\Exception $e) {
            $this->userRepository->rollback();
            error_log("User registration failed: " . $e->getMessage());
            return ['success' => false, 'errors' => ['system' => ['登録に失敗しました']]];
        }
    }
}
```

### ネストしたトランザクション回避

```php
// ❌ NG: ネストしたトランザクション
public function complexOperation(): void
{
    $this->db->beginTransaction();
    
    // ...処理...
    
    // NG: 既にトランザクション中
    $this->otherMethod();  // この中でもbeginTransaction()している
    
    $this->db->commit();
}

// ✅ OK: トランザクションは最上位のServiceメソッドのみ
public function complexOperation(): void
{
    $this->db->beginTransaction();
    try {
        $this->operationStep1();  // トランザクション制御なし
        $this->operationStep2();  // トランザクション制御なし
        $this->db->commit();
    } catch (\Exception $e) {
        $this->db->rollback();
        throw $e;
    }
}
```

---

## Entityマッピング

### 配列→Entity

```php
public function findById(int $id): ?User
{
    $sql = "SELECT * FROM users WHERE id = :id";
    $stmt = $this->db->prepare($sql);
    $stmt->execute(['id' => $id]);
    $result = $stmt->fetch();
    
    // ✅ fromArray()でEntity化
    return $result ? User::fromArray($result) : null;
}
```

### Entity→配列（INSERT/UPDATE用）

```php
public function create(User $user): int
{
    // ✅ Entityから必要なフィールドのみ抽出
    $data = [
        'name' => $user->getName(),
        'email' => $user->getEmail(),
        'password_hash' => $user->getPasswordHash(),
    ];
    
    return $this->insert($data);
}

// または toArray() を使用
public function updateUser(User $user): bool
{
    $data = $user->toArray(includePassword: true);
    
    // 更新不可フィールド除外
    unset($data['id'], $data['created_at'], $data['updated_at']);
    
    return $this->update($user->getId(), $data);
}
```

---

## クエリビルダー

### 動的WHERE句の安全な構築

```php
public function search(array $filters): array
{
    $sql = "SELECT * FROM users WHERE 1=1";
    $params = [];
    
    // ✅ ホワイトリスト方式で安全に条件追加
    $allowedFilters = ['name', 'email', 'status'];
    
    foreach ($filters as $key => $value) {
        if (!in_array($key, $allowedFilters, true)) {
            continue;  // 許可されていないフィールドはスキップ
        }
        
        $sql .= " AND {$key} = :{$key}";
        $params[$key] = $value;
    }
    
    $sql .= " ORDER BY created_at DESC LIMIT :limit";
    $params['limit'] = $filters['limit'] ?? 100;
    
    $stmt = $this->db->prepare($sql);
    
    // LIMIT句は整数でバインド
    $stmt->bindValue(':limit', $params['limit'], PDO::PARAM_INT);
    unset($params['limit']);
    
    $stmt->execute($params);
    
    return array_map(fn($row) => User::fromArray($row), $stmt->fetchAll());
}
```

### LIKE検索

```php
public function searchByName(string $keyword): array
{
    $sql = "SELECT * FROM users WHERE name LIKE :keyword";
    
    $stmt = $this->db->prepare($sql);
    
    // ✅ ワイルドカードはコード側で追加
    $stmt->execute(['keyword' => "%{$keyword}%"]);
    
    return array_map(fn($row) => User::fromArray($row), $stmt->fetchAll());
}
```

---

## N+1問題対策

### ❌ NG: N+1問題

```php
// NG: ユーザー一覧表示で投稿数を取得
public function getUsersWithPostCount(): array
{
    $users = $this->userRepository->findAll();
    
    foreach ($users as $user) {
        // NG: ループ内でクエリ実行（N+1問題）
        $user['post_count'] = $this->postRepository->countByUserId($user['id']);
    }
    
    return $users;
}
```

### ✅ OK: JOIN使用

```php
// OK: JOINで一度に取得
public function getUsersWithPostCount(): array
{
    $sql = "
        SELECT 
            u.*,
            COUNT(p.id) as post_count
        FROM users u
        LEFT JOIN posts p ON u.id = p.user_id
        GROUP BY u.id
        ORDER BY u.created_at DESC
    ";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute();
    
    return $stmt->fetchAll();
}
```

### ✅ OK: IN句で一括取得

```php
public function getUsersWithPosts(): array
{
    // 1. ユーザー一覧取得
    $users = $this->userRepository->findAll();
    $userIds = array_column($users, 'id');
    
    // 2. 投稿を一括取得
    $posts = $this->postRepository->findByUserIds($userIds);
    
    // 3. メモリ上で紐付け
    $postsByUserId = [];
    foreach ($posts as $post) {
        $postsByUserId[$post->getUserId()][] = $post;
    }
    
    foreach ($users as &$user) {
        $user['posts'] = $postsByUserId[$user['id']] ?? [];
    }
    
    return $users;
}
```

---

## エラーハンドリング

### PDOException処理

```php
public function create(User $user): int
{
    try {
        $data = [
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'password_hash' => $user->getPasswordHash(),
        ];
        
        return $this->insert($data);
    } catch (\PDOException $e) {
        // ✅ 重複エラーの判定（PostgreSQLのエラーコード）
        if ($e->getCode() === '23505') {  // unique_violation
            throw new \RuntimeException('メールアドレスは既に登録されています', 0, $e);
        }
        
        // ✅ その他のDBエラーはログ記録して再スロー
        error_log("Database error: " . $e->getMessage());
        throw new \RuntimeException('データベースエラーが発生しました', 0, $e);
    }
}
```

### エラーコード一覧（PostgreSQL）

| コード | 説明 | 対処 |
|---|---|---|
| 23505 | unique_violation | 重複エラーメッセージ表示 |
| 23503 | foreign_key_violation | 関連データ存在確認 |
| 23502 | not_null_violation | 必須フィールド確認 |
| 23514 | check_violation | 制約違反メッセージ |

---

## パフォーマンス最適化

### インデックス活用

```sql
-- よく検索されるカラムにインデックス作成
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_posts_user_id ON posts(user_id);
```

### ページネーション実装

```php
public function findAllUsers(int $page = 1, int $perPage = 20): array
{
    $offset = ($page - 1) * $perPage;
    
    $sql = "
        SELECT * FROM users
        ORDER BY created_at DESC
        LIMIT :limit OFFSET :offset
    ";
    
    $stmt = $this->db->prepare($sql);
    $stmt->bindValue(':limit', $perPage, PDO::PARAM_INT);
    $stmt->bindValue(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    return array_map(fn($row) => User::fromArray($row), $stmt->fetchAll());
}
```

### SELECT句最適化

```php
// ❌ NG: 不要なカラムも取得
$sql = "SELECT * FROM users";

// ✅ OK: 必要なカラムのみ指定
$sql = "SELECT id, name, email FROM users";
```

---

## データベース操作チェックリスト

新規Repositoryメソッド作成時：

- [ ] Prepared Statement使用
- [ ] 型宣言（引数・戻り値）
- [ ] PHPDoc記述
- [ ] Entityマッピング（配列⇔Entity）
- [ ] エラーハンドリング
- [ ] N+1問題なし
- [ ] インデックス活用確認
- [ ] トランザクション不要確認（Service層で実施）

---

**参照**:  
- [src/app/Config/Database.php](../../src/app/Config/Database.php) - PDO設定  
- [src/app/Repository/BaseRepository.php](../../src/app/Repository/BaseRepository.php) - 基底クラス
