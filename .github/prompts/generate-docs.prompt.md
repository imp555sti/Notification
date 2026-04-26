---
name: generate-docs
description: クラス・API・アーキテクチャのドキュメントを生成。日本語必須
tools: [vscode/getProjectSetupInfo, read, edit, search, todo]
---

# Generate Documentation Prompt

コード・API・アーキテクチャのドキュメントを日本語で生成します。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

以下のドキュメントを生成します：

1. **クラスドキュメント（PHPDocコメント）**
2. **APIドキュメント（endpoints）**
3. **アーキテクチャドキュメント**

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

#### ケース1: 特定クラスのドキュメント生成

```
/generate-docs

以下のクラスのドキュメントを生成してください。

クラス: src/app/Service/ProductService.php

以下を含めてください：
- PHPDocコメント（クラス・メソッド）
- README.md への追加
- メソッドの説明・パラメータ・戻り値

.github/instructions/architecture.instructions.md を参照してください。
```

#### ケース2: ワークスペース全体のドキュメント整備

```
/generate-docs

**📚 ワークスペース全体を対象に**、
ドキュメントを整備してください。

以下の手順で実施してください：

1. **.docs/plans/architecture.md の更新**
   - 各Entity/Repository/Service/Controllerの説明を追加
   - アーキテクチャ図の更新

2. **.docs/plans/api/endpoints.md の更新**
   - すべてのAPIエンドポイントを記載
   - リクエスト/レスポンス例を追加

3. **PHPDocコメントの追加**
   - すべてのクラス・メソッドの説明

4. **README.md の更新**
   - ディレクトリ構造の説明
   - セットアップ手順

.github/instructions/architecture.instructions.md を参照してください。
```

---

## ドキュメント生成ガイドライン

### 1. PHPDocコメント例

```php
<?php

declare(strict_types=1);

namespace App\Service;

use App\Repository\ProductRepository;
use App\Entity\Product;
use InvalidArgumentException;

/**
 * 製品管理サービス
 * 
 * 製品のCRUD操作とビジネスロジックを提供します。
 * Repositoryをコンストラクタインジェクションで受け取り、
 * データベースアクセスを委譲します。
 * 
 * @package App\Service
 * @version 1.0.0
 */
class ProductService
{
    private ProductRepository $productRepository;

    /**
     * コンストラクタ
     * 
     * @param ProductRepository $productRepository 製品リポジトリ
     */
    public function __construct(ProductRepository $productRepository)
    {
        $this->productRepository = $productRepository;
    }

    /**
     * 新しい製品を作成
     * 
     * 入力データのバリデーション後、データベースに保存します。
     * 
     * @param array $data 製品データ
     *   - 'name' (string): 製品名（必須、1～255文字）
     *   - 'price' (int): 価格（必須、1以上）
     *   - 'description' (string): 説明（オプション）
     * 
     * @return Product 作成された製品エンティティ
     * 
     * @throws InvalidArgumentException バリデーションエラー時
     */
    public function createProduct(array $data): Product
    {
        // ...
    }

    /**
     * 製品を取得
     * 
     * @param int $productId 製品ID
     * 
     * @return Product 製品エンティティ
     * 
     * @throws \RuntimeException 製品が見つからない場合
     */
    public function getProduct(int $productId): Product
    {
        // ...
    }
}
```

### 2. APIドキュメント例（.docs/plans/api/endpoints.md）

```markdown
# API Endpoints

## 製品管理API

### POST /api/products

新しい製品を作成します。

**認証**: 不要

**リクエスト**:

```json
{
  "name": "新製品",
  "price": 1500,
  "description": "製品の説明",
  "csrf_token": "abc123def456..."
}
```

**レスポンス（成功: 201 Created）**:

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "新製品",
    "price": 1500,
    "description": "製品の説明",
    "created_at": "2026-02-14T10:30:00Z"
  }
}
```

**レスポンス（バリデーションエラー: 400 Bad Request）**:

```json
{
  "success": false,
  "errors": {
    "name": "製品名は1文字以上255文字以下で入力してください",
    "price": "価格は1以上の整数で入力してください"
  }
}
```

**エラーコード**:
- `400`: バリデーションエラー
- `401`: 認証エラー
- `403`: CSRF トークンエラー
- `500`: サーバーエラー
```

### 3. アーキテクチャドキュメント例（.docs/plans/architecture.md）

```markdown
# アーキテクチャ

## 概要

このプロジェクトは**MVC + Service + Repository + Entity**パターンを採用しています。

```
┌──────────────────────────────────────────────┐
│         ユーザーブラウザ                        │
└──────────────────────────────────────────────┘
                      ↓ HTTP
┌──────────────────────────────────────────────┐
│        Controller層（HTTP処理）               │
│  - リクエスト処理                               │
│  - レスポンス生成                               │
│  - バリデーション                               │
└──────────────────────────────────────────────┘
                      ↓ DIで注入
┌──────────────────────────────────────────────┐
│      Service層（ビジネスロジック）             │
│  - 製品管理ロジック                             │
│  - トランザクション管理                         │
│  - 複数Repositoryの協調                       │
└──────────────────────────────────────────────┘
                      ↓ DIで注入
┌──────────────────────────────────────────────┐
│     Repository層（データベースアクセス）       │
│  - CRUD操作                                   │
│  - Prepared Statement                        │
│  - N+1対策                                    │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│         Entity層（データ保持）                 │
│  - ビジネスロジックなし                         │
│  - データ保持のみ                               │
└──────────────────────────────────────────────┘
                      ↓
┌──────────────────────────────────────────────┐
│        PostgreSQL 12.12                      │
└──────────────────────────────────────────────┘
```

## 各層の責務

### Entity層

**責務**: データの保持のみ

```php
class Product
{
    private int $id;
    private string $name;
    private int $price;

    // Getterのみ（Setterはコンストラクタで初期化）
}
```

### Repository層

**責務**: データベースアクセス

```php
class ProductRepository extends BaseRepository
{
    public function find(int $id): Product
    {
        $sql = "SELECT * FROM products WHERE id = ?";
        $stmt = $this->connection->prepare($sql);
        $stmt->execute([$id]);
        // ...
    }
}
```

### Service層

**責務**: ビジネスロジック

```php
class ProductService
{
    public function createProduct(array $data): Product
    {
        // バリデーション
        // Entityの生成
        // Repositoryへの保存依頼
        // トランザクション管理
    }
}
```

### Controller層

**責務**: HTTP処理

```php
class ProductController
{
    public function create(): void
    {
        // リクエスト解析
        // Serviceへのビジネスロジック依頼
        // レスポンス生成
    }
}
```

## 依存方向

```
Controller → Service → Repository → Entity
```

**重要**: 逆方向の依存は禁止（下位層が上位層に依存しない）
```

**参照**: `.github/instructions/architecture.instructions.md`