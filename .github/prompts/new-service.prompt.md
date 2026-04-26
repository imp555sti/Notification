---
name: new-service
description: 新規Serviceクラス作成。ビジネスロジック実装、DI対応、トランザクション管理
tools: [vscode/askQuestions, read, agent, edit, search, web, todo]
---

# 新規Service作成プロンプト

新しいServiceクラスを作成する際の標準プロンプトです。

---

## 使用方法

GitHub Copilot Chatで以下のテンプレートを使用してください：

```
このプロンプトを参照して、{クラス名}Serviceを作成してください。

クラス名: {クラス名}Service
機能概要: {機能の説明}
主要メソッド: {メソッド名のリスト}
依存Repository: {Repository名}

.github/instructions/architecture.instructions.md と
.github/instructions/php.instructions.md に従って実装してください。
```

---

## テンプレート

### 基本構造

```php
<?php

declare(strict_types=1);

namespace App\Service;

use App\Repository\{Repository名};
use App\Entity\{Entity名};
use App\Helper\SecurityHelper;
use App\Helper\ValidationHelper;

/**
 * {機能名}Service
 *
 * {機能の説明}
 *
 * @package App\Service
 */
class {クラス名}Service
{
    private {Repository名} ${repository変数名};
    
    /**
     * コンストラクタ
     *
     * @param {Repository名}|null ${repository変数名} リポジトリ（DI）
     */
    public function __construct(?{Repository名} ${repository変数名} = null)
    {
        $this->{repository変数名} = ${repository変数名} ?? new {Repository名}();
    }
    
    /**
     * IDで取得
     *
     * @param int $id ID
     * @return {Entity名}|null
     */
    public function getById(int $id): ?{Entity名}
    {
        return $this->{repository変数名}->findById($id);
    }
    
    /**
     * 一覧取得（ページネーション）
     *
     * @param int $page ページ番号
     * @param int $perPage 1ページあたりの件数
     * @return array{items: array, total: int, page: int, perPage: int}
     */
    public function getAll(int $page = 1, int $perPage = 20): array
    {
        $offset = ($page - 1) * $perPage;
        $items = $this->{repository変数名}->findAll($perPage, $offset);
        $total = $this->{repository変数名}->count();
        
        return [
            'items' => $items,
            'total' => $total,
            'page' => $page,
            'perPage' => $perPage,
        ];
    }
    
    /**
     * 新規作成
     *
     * @param array $data 入力データ
     * @return array{success: bool, id?: int, errors?: array}
     */
    public function create(array $data): array
    {
        // バリデーション
        $errors = $this->validateData($data);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }
        
        try {
            // トランザクション開始
            $this->{repository変数名}->beginTransaction();
            
            // Entity作成
            $entity = new {Entity名}();
            $entity->setField1($data['field1']);
            $entity->setField2($data['field2']);
            
            // DB保存
            $id = $this->{repository変数名}->create($entity);
            
            // コミット
            $this->{repository変数名}->commit();
            
            return ['success' => true, 'id' => $id];
        } catch (\Exception $e) {
            // ロールバック
            $this->{repository変数名}->rollback();
            error_log("Create failed: " . $e->getMessage());
            return ['success' => false, 'errors' => ['system' => ['作成に失敗しました']]];
        }
    }
    
    /**
     * 更新
     *
     * @param int $id ID
     * @param array $data 更新データ
     * @return array{success: bool, errors?: array}
     */
    public function update(int $id, array $data): array
    {
        // 存在確認
        $entity = $this->{repository変数名}->findById($id);
        if ($entity === null) {
            return ['success' => false, 'errors' => ['id' => ['データが見つかりません']]];
        }
        
        // バリデーション
        $errors = $this->validateData($data);
        if (!empty($errors)) {
            return ['success' => false, 'errors' => $errors];
        }
        
        try {
            $this->{repository変数名}->beginTransaction();
            
            // 更新
            $entity->setField1($data['field1']);
            $entity->setField2($data['field2']);
            
            $this->{repository変数名}->update{Entity名}($entity);
            
            $this->{repository変数名}->commit();
            
            return ['success' => true];
        } catch (\Exception $e) {
            $this->{repository変数名}->rollback();
            error_log("Update failed: " . $e->getMessage());
            return ['success' => false, 'errors' => ['system' => ['更新に失敗しました']]];
        }
    }
    
    /**
     * 削除
     *
     * @param int $id ID
     * @return array{success: bool, errors?: array}
     */
    public function delete(int $id): array
    {
        // 存在確認
        $entity = $this->{repository変数名}->findById($id);
        if ($entity === null) {
            return ['success' => false, 'errors' => ['id' => ['データが見つかりません']]];
        }
        
        try {
            $this->{repository変数名}->beginTransaction();
            
            $this->{repository変数名}->delete($id);
            
            $this->{repository変数名}->commit();
            
            return ['success' => true];
        } catch (\Exception $e) {
            $this->{repository変数名}->rollback();
            error_log("Delete failed: " . $e->getMessage());
            return ['success' => false, 'errors' => ['system' => ['削除に失敗しました']]];
        }
    }
    
    /**
     * データバリデーション
     *
     * @param array $data 検証データ
     * @return array エラー配列
     */
    private function validateData(array $data): array
    {
        return ValidationHelper::validate($data, [
            'field1' => ['required', ['minLength', 2]],
            'field2' => ['required', ['maxLength', 100]],
        ]);
    }
}
```

---

## チェックリスト

作成後、以下を確認：

### アーキテクチャ

- [ ] namespace が `App\Service`
- [ ] ファイルが `src/src/app/Service/` に配置
- [ ] クラス名が `{名詞}Service` の形式
- [ ] Repositoryへの依存のみ（Controllerへの依存なし）

### 実装規約

- [ ] `declare(strict_types=1);` 宣言
- [ ] すべてのメソッドに型宣言（引数・戻り値）
- [ ] PHPDocコメント記述（日本語）
- [ ] DI可能なコンストラクタ（`?Repository = null`）

### トランザクション管理

- [ ] 作成・更新・削除で `beginTransaction()`
- [ ] 成功時に `commit()`
- [ ] 例外時に `rollback()`
- [ ] try-catch でエラーハンドリング

### バリデーション

- [ ] 入力データは必ずバリデーション
- [ ] `ValidationHelper::validate()` 使用
- [ ] エラーは配列形式で返却

### レスポンス形式

- [ ] 成功: `['success' => true, 'id' => $id]`
- [ ] 失敗: `['success' => false, 'errors' => [...]]`

### テスト

- [ ] テストファイル作成（`tests/Service/{クラス名}ServiceTest.php`）
- [ ] Repositoryのモック使用
- [ ] 正常系・異常系テスト実装

---

## 使用例

### 例1: ProductService作成

```
このプロンプトを参照して、ProductServiceを作成してください。

クラス名: ProductService
機能概要: 商品管理のビジネスロジック
主要メソッド: getById, getAll, create, update, delete
依存Repository: ProductRepository

追加要件:
- createメソッドで在庫チェック実施
- deleteメソッドで注文履歴チェック実施
```

### 例2: EmailService作成

```
このプロンプトを参照して、EmailServiceを作成してください。

クラス名: EmailService
機能概要: メール送信機能
主要メソッド: sendWelcomeEmail, sendPasswordResetEmail, sendNotification
依存Repository: なし（外部API使用）

追加要件:
- テンプレートエンジン使用
- 送信ログ保存
```

---

## パターン別テンプレート

### パターン1: 外部API連携Service

```php
class ExternalApiService
{
    private string $apiUrl;
    private string $apiKey;
    
    public function __construct()
    {
        $this->apiUrl = $_ENV['API_URL'] ?? '';
        $this->apiKey = $_ENV['API_KEY'] ?? '';
    }
    
    public function fetchData(array $params): array
    {
        try {
            $response = $this->callApi('GET', '/endpoint', $params);
            return ['success' => true, 'data' => $response];
        } catch (\Exception $e) {
            error_log("API call failed: " . $e->getMessage());
            return ['success' => false, 'errors' => ['api' => ['API呼び出しに失敗']]];
        }
    }
    
    private function callApi(string $method, string $endpoint, array $params): array
    {
        // cURL実装
    }
}
```

### パターン2: 複数Repository使用Service

```php
class OrderService
{
    private OrderRepository $orderRepository;
    private ProductRepository $productRepository;
    private UserRepository $userRepository;
    
    public function __construct(
        ?OrderRepository $orderRepository = null,
        ?ProductRepository $productRepository = null,
        ?UserRepository $userRepository = null
    ) {
        $this->orderRepository = $orderRepository ?? new OrderRepository();
        $this->productRepository = $productRepository ?? new ProductRepository();
        $this->userRepository = $userRepository ?? new UserRepository();
    }
    
    public function createOrder(int $userId, array $items): array
    {
        // 複数Repositoryを調整
        $this->orderRepository->beginTransaction();
        try {
            // ユーザー存在確認
            $user = $this->userRepository->findById($userId);
            
            // 商品在庫確認
            foreach ($items as $item) {
                $product = $this->productRepository->findById($item['product_id']);
                // ...
            }
            
            // 注文作成
            $orderId = $this->orderRepository->create(/* ... */);
            
            $this->orderRepository->commit();
            return ['success' => true, 'orderId' => $orderId];
        } catch (\Exception $e) {
            $this->orderRepository->rollback();
            return ['success' => false, 'errors' => ['system' => ['注文作成失敗']]];
        }
    }
}
```

---

## 参照ドキュメント

- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md)
- [.github/instructions/php.instructions.md](../instructions/php.instructions.md)
- [.github/instructions/database.instructions.md](../instructions/database.instructions.md)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
