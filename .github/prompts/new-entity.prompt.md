---
name: new-entity
description: 新規Entityクラス作成。データモデル定義、型宣言、getters/setters生成
tools: [vscode/askQuestions, read, agent, edit, search, web, todo]
---

# 新規Entity作成プロンプト

新しいEntityクラスを作成する際の標準プロンプトです。

---

## 使用方法

GitHub Copilot Chatで以下のテンプレートを使用してください：

```
このプロンプトを参照して、{クラス名}Entityを作成してください。

クラス名: {クラス名}
テーブル名: {テーブル名}
フィールド: 
  - {フィールド名}: {型} ({説明})
  - ...

.github/instructions/architecture.instructions.md と
.github/instructions/php.instructions.md に従って実装してください。
```

---

## テンプレート

### 基本構造

```php
<?php

declare(strict_types=1);

namespace App\Entity;

use DateTime;

/**
 * {クラス名}Entity
 *
 * {説明}
 *
 * @package App\Entity
 */
class {クラス名}
{
    /**
     * @var int|null ID
     */
    private ?int $id = null;
    
    /**
     * @var string フィールド1
     */
    private string $field1 = '';
    
    /**
     * @var string フィールド2
     */
    private string $field2 = '';
    
    /**
     * @var DateTime|null 作成日時
     */
    private ?DateTime $createdAt = null;
    
    /**
     * @var DateTime|null 更新日時
     */
    private ?DateTime $updatedAt = null;
    
    // ===== ゲッター =====
    
    /**
     * IDを取得
     *
     * @return int|null
     */
    public function getId(): ?int
    {
        return $this->id;
    }
    
    /**
     * フィールド1を取得
     *
     * @return string
     */
    public function getField1(): string
    {
        return $this->field1;
    }
    
    /**
     * フィールド2を取得
     *
     * @return string
     */
    public function getField2(): string
    {
        return $this->field2;
    }
    
    /**
     * 作成日時を取得
     *
     * @return DateTime|null
     */
    public function getCreatedAt(): ?DateTime
    {
        return $this->createdAt;
    }
    
    /**
     * 更新日時を取得
     *
     * @return DateTime|null
     */
    public function getUpdatedAt(): ?DateTime
    {
        return $this->updatedAt;
    }
    
    // ===== セッター =====
    
    /**
     * IDを設定
     *
     * @param int|null $id ID
     * @return self
     */
    public function setId(?int $id): self
    {
        $this->id = $id;
        return $this;
    }
    
    /**
     * フィールド1を設定
     *
     * @param string $field1 フィールド1
     * @return self
     */
    public function setField1(string $field1): self
    {
        $this->field1 = $field1;
        return $this;
    }
    
    /**
     * フィールド2を設定
     *
     * @param string $field2 フィールド2
     * @return self
     */
    public function setField2(string $field2): self
    {
        $this->field2 = $field2;
        return $this;
    }
    
    /**
     * 作成日時を設定
     *
     * @param DateTime|string|null $createdAt 作成日時
     * @return self
     */
    public function setCreatedAt(DateTime|string|null $createdAt): self
    {
        if (is_string($createdAt)) {
            $this->createdAt = new DateTime($createdAt);
        } else {
            $this->createdAt = $createdAt;
        }
        return $this;
    }
    
    /**
     * 更新日時を設定
     *
     * @param DateTime|string|null $updatedAt 更新日時
     * @return self
     */
    public function setUpdatedAt(DateTime|string|null $updatedAt): self
    {
        if (is_string($updatedAt)) {
            $this->updatedAt = new DateTime($updatedAt);
        } else {
            $this->updatedAt = $updatedAt;
        }
        return $this;
    }
    
    // ===== データ変換 =====
    
    /**
     * 配列からEntityを生成
     *
     * @param array $data データ配列
     * @return self
     */
    public static function fromArray(array $data): self
    {
        $entity = new self();
        
        $entity->setId($data['id'] ?? null);
        $entity->setField1($data['field1'] ?? '');
        $entity->setField2($data['field2'] ?? '');
        $entity->setCreatedAt($data['created_at'] ?? null);
        $entity->setUpdatedAt($data['updated_at'] ?? null);
        
        return $entity;
    }
    
    /**
     * Entityを配列に変換
     *
     * @return array
     */
    public function toArray(): array
    {
        return [
            'id' => $this->id,
            'field1' => $this->field1,
            'field2' => $this->field2,
            'created_at' => $this->createdAt?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updatedAt?->format('Y-m-d H:i:s'),
        ];
    }
}
```

---

## フィールド型別パターン

### 文字列フィールド

```php
/**
 * @var string 名前
 */
private string $name = '';

public function getName(): string
{
    return $this->name;
}

public function setName(string $name): self
{
    $this->name = $name;
    return $this;
}
```

### 整数フィールド

```php
/**
 * @var int 年齢
 */
private int $age = 0;

public function getAge(): int
{
    return $this->age;
}

public function setAge(int $age): self
{
    $this->age = $age;
    return $this;
}
```

### NULL許容整数フィールド

```php
/**
 * @var int|null カテゴリID
 */
private ?int $categoryId = null;

public function getCategoryId(): ?int
{
    return $this->categoryId;
}

public function setCategoryId(?int $categoryId): self
{
    $this->categoryId = $categoryId;
    return $this;
}
```

### 真偽値フィールド

```php
/**
 * @var bool アクティブフラグ
 */
private bool $isActive = false;

public function isActive(): bool
{
    return $this->isActive;
}

public function setIsActive(bool $isActive): self
{
    $this->isActive = $isActive;
    return $this;
}
```

### 浮動小数点フィールド

```php
/**
 * @var float 価格
 */
private float $price = 0.0;

public function getPrice(): float
{
    return $this->price;
}

public function setPrice(float $price): self
{
    $this->price = $price;
    return $this;
}
```

### 配列フィールド

```php
/**
 * @var array<string> タグ
 */
private array $tags = [];

/**
 * @return array<string>
 */
public function getTags(): array
{
    return $this->tags;
}

/**
 * @param array<string> $tags タグ
 * @return self
 */
public function setTags(array $tags): self
{
    $this->tags = $tags;
    return $this;
}
```

### JSON フィールド（メタデータ等）

```php
/**
 * @var array<string, mixed> メタデータ
 */
private array $metadata = [];

/**
 * @return array<string, mixed>
 */
public function getMetadata(): array
{
    return $this->metadata;
}

/**
 * @param array<string, mixed> $metadata メタデータ
 * @return self
 */
public function setMetadata(array $metadata): self
{
    $this->metadata = $metadata;
    return $this;
}

// fromArray() でのJSONデコード
public static function fromArray(array $data): self
{
    $entity = new self();
    
    if (isset($data['metadata'])) {
        if (is_string($data['metadata'])) {
            $entity->setMetadata(json_decode($data['metadata'], true) ?? []);
        } else {
            $entity->setMetadata($data['metadata']);
        }
    }
    
    return $entity;
}

// toArray() でのJSONエンコード
public function toArray(): array
{
    return [
        // ...
        'metadata' => json_encode($this->metadata),
    ];
}
```

---

## 追加機能パターン

### パターン1: バリデーションメソッド

```php
/**
 * Entityが有効か検証
 *
 * @return bool
 */
public function isValid(): bool
{
    return !empty($this->name) && !empty($this->email);
}

/**
 * 大人かどうか判定
 *
 * @return bool
 */
public function isAdult(): bool
{
    return $this->age >= 18;
}
```

### パターン2: 計算メソッド

```php
/**
 * 合計金額を計算
 *
 * @return float
 */
public function getTotalAmount(): float
{
    return $this->price * $this->quantity;
}

/**
 * フルネームを取得
 *
 * @return string
 */
public function getFullName(): string
{
    return $this->firstName . ' ' . $this->lastName;
}
```

### パターン3: ステータス判定

```php
/**
 * アクティブかどうか
 *
 * @return bool
 */
public function isActive(): bool
{
    return $this->status === 'active';
}

/**
 * 公開済みかどうか
 *
 * @return bool
 */
public function isPublished(): bool
{
    return $this->publishedAt !== null 
        && $this->publishedAt <= new DateTime();
}
```

---

## チェックリスト

作成後、以下を確認：

### アーキテクチャ

- [ ] namespace が `App\Entity`
- [ ] ファイルが `src/src/app/Entity/` に配置
- [ ] クラス名がPascalCase（名詞）
- [ ] Baseクラスは継承しない（Entityは純粋なデータ構造）

### プロパティ

- [ ] すべてのプロパティが `private`
- [ ] 型宣言を使用
- [ ] デフォルト値を設定（NULL許容の場合は `null`）
- [ ] PHPDocコメント記述（日本語）

### メソッド

- [ ] すべてのプロパティにゲッター/セッター実装
- [ ] セッターは `return $this;`（fluent interface）
- [ ] 型宣言（引数・戻り値）
- [ ] PHPDocコメント記述（日本語）

### データ変換

- [ ] `fromArray()` 実装（`static`メソッド）
- [ ] `toArray()` 実装
- [ ] DateTime 型は文字列⇔DateTimeオブジェクト変換
- [ ] JSON 型は適切にエンコード/デコード

### 禁止事項

- [ ] データベースアクセスなし
- [ ] 外部APIアクセスなし
- [ ] 他のEntityへの依存なし（関連は許可）
- [ ] 複雑なビジネスロジックなし

### テスト

- [ ] テストファイル作成（`tests/Unit/Entity/{クラス名}Test.php`）
- [ ] ゲッター/セッターテスト
- [ ] `fromArray()` / `toArray()` テスト
- [ ] メソッドチェーンテスト

---

## 使用例

### 例1: Product Entity作成

```
このプロンプトを参照して、ProductEntityを作成してください。

クラス名: Product
テーブル名: products
フィールド:
  - id: ?int (主キー)
  - name: string (商品名)
  - description: string (商品説明)
  - price: float (価格)
  - stock: int (在庫数)
  - category_id: ?int (カテゴリID)
  - is_active: bool (アクティブフラグ)
  - created_at: ?DateTime (作成日時)
  - updated_at: ?DateTime (更新日時)

追加メソッド:
  - isInStock(): bool (在庫があるか判定)
  - getTaxIncludedPrice(): float (税込価格を計算)
```

### 例2: Order Entity作成

```
このプロンプトを参照して、OrderEntityを作成してください。

クラス名: Order
テーブル名: orders
フィールド:
  - id: ?int (主キー)
  - user_id: int (ユーザーID)
  - total_amount: float (合計金額)
  - status: string (ステータス: pending/paid/shipped/completed)
  - items: array (注文アイテム)
  - created_at: ?DateTime (作成日時)
  - updated_at: ?DateTime (更新日時)

追加メソッド:
  - isPaid(): bool (支払い済みか)
  - isCompleted(): bool (完了したか)
  - getItemCount(): int (アイテム数取得)
```

---

## 参照ドキュメント

- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md)
- [.github/instructions/php.instructions.md](../instructions/php.instructions.md)
- [src/app/Entity/User.php](../../src/app/Entity/User.php) - 既存の実装例

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
