---
name: new-controller
description: 新規Controllerクラス作成。HTTPリクエスト処理、バリデーション、レスポンス生成
tools: [vscode/askQuestions, read, agent, edit, search, web, todo]
---

# 新規Controller作成プロンプト

新しいControllerクラスを作成する際の標準プロンプトです。

---

## 使用方法

GitHub Copilot Chatで以下のテンプレートを使用してください：

```
このプロンプトを参照して、{クラス名}Controllerを作成してください。

クラス名: {クラス名}Controller
機能概要: {機能の説明}
必要なアクション: {index/create/update/delete等}

.github/instructions/architecture.instructions.md と
.github/instructions/php.instructions.md に従って実装してください。
```

---

## テンプレート

### 基本構造

```php
<?php

declare(strict_types=1);

namespace App\Controller;

use App\Service\{Service名};
use App\Helper\SecurityHelper;
use App\Helper\ValidationHelper;

/**
 * {機能名}Controller
 *
 * {機能の説明}
 *
 * @package App\Controller
 */
class {クラス名}Controller extends BaseController
{
    private {Service名} ${service変数名};
    
    /**
     * コンストラクタ
     */
    public function __construct()
    {
        $this->{service変数名} = new {Service名}();
    }
    
    /**
     * 一覧表示
     *
     * @return void
     */
    public function index(): void
    {
        $page = (int)($this->getQuery('page') ?? 1);
        
        $result = $this->{service変数名}->getAll($page);
        
        $this->htmlResponse('
            <!DOCTYPE html>
            <html lang="ja">
            <head>
                <meta charset="UTF-8">
                <title>{機能名}一覧</title>
            </head>
            <body>
                <h1>{機能名}一覧</h1>
                <!-- データ表示 -->
            </body>
            </html>
        ');
    }
    
    /**
     * 新規作成
     *
     * @return void
     */
    public function create(): void
    {
        if ($this->isPost()) {
            // CSRF検証
            $this->requireCsrfToken();
            
            // 入力取得
            $data = [
                'field1' => $this->getPost('field1'),
                'field2' => $this->getPost('field2'),
            ];
            
            // Service呼び出し
            $result = $this->{service変数名}->create($data);
            
            // レスポンス
            if ($result['success']) {
                $this->successResponse(['id' => $result['id']], 201);
            } else {
                $this->errorResponse('作成に失敗しました', 400);
            }
        } else {
            // フォーム表示
            $this->showCreateForm();
        }
    }
    
    /**
     * 更新
     *
     * @return void
     */
    public function update(): void
    {
        if ($this->isPost()) {
            $this->requireCsrfToken();
            
            $id = (int)$this->getPost('id');
            $data = [
                'field1' => $this->getPost('field1'),
                'field2' => $this->getPost('field2'),
            ];
            
            $result = $this->{service変数名}->update($id, $data);
            
            if ($result['success']) {
                $this->successResponse(['message' => '更新しました']);
            } else {
                $this->errorResponse('更新に失敗しました', 400);
            }
        }
    }
    
    /**
     * 削除
     *
     * @return void
     */
    public function delete(): void
    {
        if ($this->isPost()) {
            $this->requireCsrfToken();
            
            $id = (int)$this->getPost('id');
            
            $result = $this->{service変数名}->delete($id);
            
            if ($result['success']) {
                $this->successResponse(['message' => '削除しました']);
            } else {
                $this->errorResponse('削除に失敗しました', 400);
            }
        }
    }
    
    /**
     * 作成フォーム表示
     *
     * @return void
     */
    private function showCreateForm(): void
    {
        $csrfToken = SecurityHelper::generateCsrfToken();
        
        $this->htmlResponse('
            <!DOCTYPE html>
            <html lang="ja">
            <head>
                <meta charset="UTF-8">
                <title>{機能名}作成</title>
            </head>
            <body>
                <h1>{機能名}作成</h1>
                <form method="POST">
                    <input type="hidden" name="csrf_token" value="' . $csrfToken . '">
                    
                    <label>フィールド1:
                        <input type="text" name="field1" required>
                    </label>
                    
                    <label>フィールド2:
                        <input type="text" name="field2" required>
                    </label>
                    
                    <button type="submit">作成</button>
                </form>
            </body>
            </html>
        ');
    }
}
```

---

## チェックリスト

作成後、以下を確認：

### アーキテクチャ

- [ ] `BaseController` を継承
- [ ] namespace が `App\Controller`
- [ ] ファイルが `src/src/app/Controller/` に配置
- [ ] クラス名が `{名詞}Controller` の形式

### セキュリティ

- [ ] POST/PUT/DELETEで `$this->requireCsrfToken()` 呼び出し
- [ ] 出力時に `SecurityHelper::escape()` 使用
- [ ] フォームにCSRFトークン埋め込み

### 実装規約

- [ ] `declare(strict_types=1);` 宣言
- [ ] すべてのメソッドに型宣言（引数・戻り値）
- [ ] PHPDocコメント記述（日本語）
- [ ] メソッドは `public` または `private` のみ
- [ ] ビジネスロジックなし（Serviceに委譲）

### テスト

- [ ] テストファイル作成（`tests/Controller/{クラス名}ControllerTest.php`）
- [ ] 主要アクションのテスト実装

---

## 使用例

### 例1: ProductController作成

```
このプロンプトを参照して、ProductControllerを作成してください。

クラス名: ProductController
機能概要: 商品管理機能
必要なアクション: index（一覧）、create（新規作成）、update（更新）、delete（削除）

ProductServiceとの連携を想定。
```

### 例2: ApiController作成

```
このプロンプトを参照して、ApiControllerを作成してください。

クラス名: ApiController  
機能概要: REST API エンドポイント
必要なアクション: getUsers, createUser, updateUser, deleteUser

すべてJSON形式でレスポンスを返す。
```

---

## 参照ドキュメント

- [.github/instructions/architecture.instructions.md](../instructions/architecture.instructions.md)
- [.github/instructions/php.instructions.md](../instructions/php.instructions.md)
- [.github/instructions/security.instructions.md](../instructions/security.instructions.md)
- [src/app/Controller/BaseController.php](../../src/app/Controller/BaseController.php)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
