---
name: new-repository
description: 新規Repositoryクラス作成。データベースアクセス、Prepared Statement、Entity マッピング
tools: [vscode/askQuestions, read, agent, edit, search, web, todo]
---

# 新規Repository作成プロンプト

新しいRepositoryクラスを作成する際の標準プロンプトです。

---

## 使用方法

GitHub Copilot Chatで以下のテンプレートを使用してください：

```
このプロンプトを参照して、{クラス名}Repositoryを作成してください。

クラス名: {クラス名}Repository
テーブル名: {テーブル名}
対応Entity: {Entity名}
主要メソッド: {メソッド名のリスト}

.github/instructions/architecture.instructions.md と
.github/instructions/database.instructions.md に従って実装してください。
```

---

## テンプレート

### 基本構造

```php
<?php

declare(strict_types=1);

namespace App\Repository;

use App\Entity\{Entity名};

/**
 * {テーブル名}Repository
 *
 * {機能の説明}
 *
 * @package App\Repository
 */
class {クラス名}Repository extends BaseRepository
{
    /**
     * @var string テーブル名
     */
    protected string $table = '{テーブル名}';
    
    /**
     * IDで検索
     *
     * @param int $id ID
     * @return {Entity名}|null
     */
    public function findById(int $id): ?{Entity名}
    {
        $result = $this->find($id);  // BaseRepositoryのメソッド使用
        
        return $result ? {Entity名}::fromArray($result) : null;
    }
    
    /**
     * すべて取得
     *
     * @param int $limit 取得件数上限
     * @param int $offset オフセット
     * @return array<{Entity名}>
     */
    public function findAll(int $limit = 100, int $offset = 0): array
    {
        $results = parent::findAll($limit, $offset);
        
        return array_map(fn($row) => {Entity名}::fromArray($row), $results);
    }
    
    /**
     * 条件で検索
     *
     * @param array $conditions 検索条件
     * @param int $limit 取得件数上限
     * @param int $offset オフセット
     * @return array<{Entity名}>
     */
    public function findBy(array $conditions, int $limit = 100, int $offset = 0): array
    {
        $results = parent::findBy($conditions, $limit, $offset);
        
        return array_map(fn($row) => {Entity名}::fromArray($row), $results);
    }
    
    /**
     * 新規作成
     *
     * @param {Entity名} $entity Entity
     * @return int 作成されたID
     */
    public function create({Entity名} $entity): int
    {
        $data = [
            'field1' => $entity->getField1(),
            'field2' => $entity->getField2(),
        ];
        
        return $this->insert($data);  // BaseRepositoryのメソッド使用
    }
    
    /**
     * 更新
     *
     * @param {Entity名} $entity Entity
     * @return bool 成功/失敗
     * @throws \InvalidArgumentException When entity ID is null
     */
    public function update{Entity名}({Entity名} $entity): bool
    {
        if ($entity->getId() === null) {
            throw new \InvalidArgumentException('Entity ID is required for update');
        }
        
        $data = $entity->toArray();
        unset($data['id'], $data['created_at']);  // 更新不可フィールド除外
        
        return $this->update($entity->getId(), $data);  // BaseRepositoryのメソッド使用
    }
    
    /**
     * 削除
     *
     * @param int $id ID
     * @return bool 成功/失敗
     */
    public function delete(int $id): bool
    {
        return parent::delete($id);  // BaseRepositoryのメソッド使用
    }
}
```

---

## カスタムクエリメソッド実装例

### パターン1: 単一カラムで検索

```php
/**
 * メールアドレスで検索
 *
 * @param string $email メールアドレス
 * @return {Entity名}|null
 */
public function findByEmail(string $email): ?{Entity名}
{
    $sql = "SELECT * FROM {$this->table} WHERE email = :email LIMIT 1";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute(['email' => $email]);
    $result = $stmt->fetch();
    
    return $result ? {Entity名}::fromArray($result) : null;
}
```

### パターン2: 複数カラムで検索

```php
/**
 * メールアドレスとステータスで検索
 *
 * @param string $email メールアドレス
 * @param string $status ステータス
 * @return array<{Entity名}>
 */
public function findByEmailAndStatus(string $email, string $status): array
{
    $sql = "SELECT * FROM {$this->table} 
            WHERE email = :email AND status = :status 
            ORDER BY created_at DESC";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute([
        'email' => $email,
        'status' => $status,
    ]);
    
    $results = $stmt->fetchAll();
    
    return array_map(fn($row) => {Entity名}::fromArray($row), $results);
}
```

### パターン3: LIKE検索

```php
/**
 * 名前で部分一致検索
 *
 * @param string $keyword 検索キーワード
 * @return array<{Entity名}>
 */
public function searchByName(string $keyword): array
{
    $sql = "SELECT * FROM {$this->table} 
            WHERE name LIKE :keyword 
            ORDER BY name ASC";
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute(['keyword' => "%{$keyword}%"]);
    
    $results = $stmt->fetchAll();
    
    return array_map(fn($row) => {Entity名}::fromArray($row), $results);
}
```

### パターン4: 存在確認

```php
/**
 * メールアドレスの存在確認
 *
 * @param string $email メールアドレス
 * @param int|null $excludeId 除外するID（更新時の重複チェックで使用）
 * @return bool
 */
public function emailExists(string $email, ?int $excludeId = null): bool
{
    $sql = "SELECT COUNT(*) FROM {$this->table} WHERE email = :email";
    $params = ['email' => $email];
    
    if ($excludeId !== null) {
        $sql .= " AND id != :exclude_id";
        $params['exclude_id'] = $excludeId;
    }
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute($params);
    
    return (int)$stmt->fetchColumn() > 0;
}
```

### パターン5: JOIN クエリ

```php
/**
 * ユーザーと投稿数を取得
 *
 * @return array<array>
 */
public function findUsersWithPostCount(): array
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

### パターン6: IN句の実装

```php
/**
 * 複数IDで検索
 *
 * @param array<int> $ids ID配列
 * @return array<{Entity名}>
 */
public function findByIds(array $ids): array
{
    if (empty($ids)) {
        return [];
    }
    
    // プレースホルダー生成
    $placeholders = [];
    $params = [];
    foreach ($ids as $index => $id) {
        $placeholders[] = ":id{$index}";
        $params["id{$index}"] = $id;
    }
    
    $sql = sprintf(
        "SELECT * FROM {$this->table} WHERE id IN (%s)",
        implode(',', $placeholders)
    );
    
    $stmt = $this->db->prepare($sql);
    $stmt->execute($params);
    
    $results = $stmt->fetchAll();
    
    return array_map(fn($row) => {Entity名}::fromArray($row), $results);
}
```

---

## チェックリスト

作成後、以下を確認：

### アーキテクチャ

- [ ] `BaseRepository` を継承
- [ ] namespace が `App\Repository`
- [ ] ファイルが `src/src/app/Repository/` に配置
- [ ] クラス名が `{Entity名}Repository` の形式
- [ ] `protected string $table` でテーブル名定義

### データベース操作

- [ ] すべてのクエリでPrepared Statement使用
- [ ] `$this->db->query()` の直接使用なし
- [ ] プレースホルダーは名前付き（`:name` 形式）
- [ ] 動的WHERE句はホワイトリスト検証

### Entityマッピング

- [ ] 検索結果は `Entity::fromArray()` で変換
- [ ] 複数レコードは `array_map()` で変換
- [ ] 作成・更新時は `$entity->toArray()` またはゲッター使用

### エラーハンドリング

- [ ] PDOExceptionはキャッチしない（Service層で処理）
- [ ] `null` を返す場合の条件明確化
- [ ] 不正な引数は `InvalidArgumentException` スロー

### 型宣言

- [ ] `declare(strict_types=1);` 宣言
- [ ] すべてのメソッドに型宣言（引数・戻り値）
- [ ] PHPDocコメント記述（日本語）
- [ ] 戻り値の配列は `array<Entity>` 記述

### テスト

- [ ] テストファイル作成（`tests/Repository/{クラス名}RepositoryTest.php`）
- [ ] カスタムメソッドのテスト実装

---

## 使用例

### 例1: ProductRepository作成

```
このプロンプトを参照して、ProductRepositoryを作成してください。

クラス名: ProductRepository
テーブル名: products
対応Entity: Product
主要メソッド: 
  - findById
  - findByCategory (category_id で検索)
  - findInStock (在庫ありの商品のみ)
  - searchByName (名前で部分一致検索)
```

### 例2: OrderRepository作成

```
このプロンプトを参照して、OrderRepositoryを作成してください。

クラス名: OrderRepository
テーブル名: orders
対応Entity: Order
主要メソッド:
  - findById
  - findByUserId (ユーザーIDで検索)
  - findByStatus (ステータスで検索)
  - findRecentOrders (最近の注文取得)
  - getTotalAmount (合計金額取得)
```

---

## 参照ドキュメント

- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md)
- [.github/instructions/database.instructions.md](../instructions/database.instructions.md)
- [src/app/Repository/BaseRepository.php](../../src/app/Repository/BaseRepository.php)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
