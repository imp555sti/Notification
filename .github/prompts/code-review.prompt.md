---
name: code-review
description: PR・コミットの包括的レビュー。プロジェクトルール準拠チェック、ドキュメント影響分析、セキュリティ検証
tools:
  - read
  - search
  - agent
  - web
  - vscode/extensions
  - vscode/getProjectSetupInfo
  - vscode/askQuestions
  - todo
---

# Code Review Prompt

他メンバーのコミット・PRに対する包括的なレビューを行うプロンプトです。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

コミット・PRの以下を網羅的にチェックします：

1. **プロジェクトルール順守**
2. **アーキテクチャ設計原則**
3. **ドキュメント整合性**
4. **テスト品質**
5. **コード品質**

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

#### ケース1: 特定のファイル/差分をレビュー

```
/code-review

以下のコミット・PRをレビューしてください。

git diff の出力:
diff --git a/src/app/Service/ProductService.php b/src/app/Service/ProductService.php
new file mode 100644
index 0000000..abc1234
--- /dev/null
+++ b/src/app/Service/ProductService.php
@@ -0,0 +1,50 @@
+<?php
+
+declare(strict_types=1);
+
+namespace App\Service;
+
+class ProductService
+{
+    // ...
+}
```

#### ケース2: ワークスペース全体のアーキテクチャレビュー

```
/code-review

**🔍 ワークスペース全体を対象に**、
プロジェクト全体のアーキテクチャ準拠性をレビューしてください。

特に以下の点を確認してください：

1. **レイヤー責務の遵守**
   - Entity層: ビジネスロジックなし
   - Repository層: データベースアクセスのみ
   - Service層: ビジネスロジック実装
   - Controller層: HTTP処理のみ

2. **依存方向の正しさ**
   - Controller → Service → Repository → Entity

3. **DI（依存注入）の使用**
   - コンストラクタインジェクション

.github/instructions/architecture.instructions.md を参照してください。
```

---

## Review Checklist（レビュー項目）

### 📋 1. プロジェクトルール順守チェック

#### 1.1 PSR-12コーディング規約

**チェック項目**:
- [ ] `declare(strict_types=1);` が全PHPファイルに存在
- [ ] namespace宣言が正しい（App\Entity, App\Repository, App\Service, App\Controller）
- [ ] クラス名がファイル名と一致
- [ ] インデントが4スペース
- [ ] 行末に不要な空白なし
- [ ] 1行120文字以内（推奨）

**参照**: `.github/instructions/php.instructions.md`

#### 1.2 型宣言必須

**チェック項目**:
- [ ] すべてのメソッド引数に型宣言
- [ ] すべてのメソッド戻り値に型宣言
- [ ] プロパティに型宣言（PHP7.4+）
- [ ] `mixed`, `array` の乱用なし（具体的な型を使用）

**参照**: `.github/instructions/php.instructions.md` - 型宣言セクション

#### 1.3 命名規則

**チェック項目**:
- [ ] クラス名: PascalCase
- [ ] メソッド名: camelCase
- [ ] プロパティ名: camelCase
- [ ] 定数名: UPPER_SNAKE_CASE
- [ ] 名前が意味を表している（略語の乱用なし）

**参照**: `.github/instructions/php.instructions.md` - 命名規則セクション

#### 1.4 セキュリティ対策実装

**チェック項目**:
- [ ] XSS対策: 出力に`SecurityHelper::escape()`使用
- [ ] CSRF対策: POST/PUT/DELETEでトークン検証
- [ ] SQLインジェクション対策: Prepared Statement使用
- [ ] 入力バリデーション: `ValidationHelper`使用
- [ ] パスワード: `password_hash()`使用（`PASSWORD_BCRYPT`以上）

**参照**: `.github/instructions/security.instructions.md`

---

### 🏗️ 2. アーキテクチャ設計原則チェック

#### 2.1 レイヤー責務の遵守

**チェック項目**:

**Entity層**:
- [ ] ビジネスロジックなし（データ保持のみ）
- [ ] 外部依存なし
- [ ] バリデーションは基本的なもののみ

**Repository層**:
- [ ] データベースアクセスのみ
- [ ] ビジネスロジックなし
- [ ] BaseRepositoryを継承
- [ ] Prepared Statement使用

**Service層**:
- [ ] ビジネスロジック実装
- [ ] トランザクション管理
- [ ] 複数Repositoryの協調
- [ ] DIでRepository受け取り

**Controller層**:
- [ ] HTTPリクエスト/レスポンス処理のみ
- [ ] ビジネスロジックはServiceに委譲
- [ ] バリデーションはControllerで実施
- [ ] DIでService受け取り

**参照**: `.github/instructions/architecture.instructions.md`

#### 2.2 依存方向の正しさ

```
Controller → Service → Repository → Entity
                ↓
              Helper
```

**チェック項目**:
- [ ] Entityは他のレイヤーに依存していない
- [ ] Repositoryは他のRepository/Serviceに依存していない
- [ ] Serviceは他のServiceに依存可能（DIで注入）
- [ ] ControllerはRepositoryを直接使用していない

**参照**: `.github/instructions/architecture.instructions.md` - 依存方向セクション

#### 2.3 DIパターンの使用

**チェック項目**:
- [ ] コンストラクタインジェクション使用
- [ ] `new`演算子での直接インスタンス化を避ける
- [ ] 依存関係がコンストラクタで明示されている

**参照**: `.github/instructions/architecture.instructions.md` - DI実装セクション

---

### 📚 3. ドキュメント整合性チェック

#### 3.1 チェック対象ドキュメント

1. **README.md**
   - ディレクトリ構造
   - セットアップ手順
   - 使用技術

2. **SETUP.md**
   - 環境構築手順
   - 環境変数設定

3. **.github/copilot-instructions.md**
   - ディレクトリ構造
   - プロジェクト概要

4. **.github/instructions/*.md**
   - php.instructions.md
   - security.instructions.md
   - architecture.instructions.md
   - database.instructions.md
   - testing.instructions.md
   - setup.instructions.md
   - deployment.instructions.md

5. **.docs/plans/architecture.md**
   - レイヤー構成
   - クラス設計例

6. **.docs/plans/development/*.md**
   - coding-standards.md
   - setup.md
   - testing.md

7. **.docs/plans/security/best-practices.md**
   - セキュリティ実装パターン

8. **.docs/plans/api/endpoints.md**
   - API仕様

#### 3.2 チェック内容

**新規Entity追加の場合**:
- [ ] .docs/plans/architecture.md にEntityの説明追加
- [ ] .docs/plans/api/endpoints.md にデータ構造定義追加（該当する場合）

**新規Repository追加の場合**:
- [ ] .docs/plans/architecture.md にRepositoryの説明追加

**新規Service追加の場合**:
- [ ] .docs/plans/architecture.md にServiceの説明追加

**新規Controller/API追加の場合**:
- [ ] .docs/plans/api/endpoints.md にエンドポイント定義追加
- [ ] .docs/plans/architecture.md にControllerの説明追加

**Config変更の場合**:
- [ ] README.md のディレクトリ構造更新
- [ ] SETUP.md の環境変数設定手順更新
- [ ] .github/instructions/setup.instructions.md 更新

**セキュリティ実装変更の場合**:
- [ ] .docs/plans/security/best-practices.md 更新
- [ ] .github/instructions/security.instructions.md 更新

**参照**: `.github/agents/pre-commit-checker.agent.md` の影響範囲特定ロジック

---

### ✅ 4. テスト品質チェック

#### 4.1 テストカバレッジ

**チェック項目**:
- [ ] 新規クラスに対応するテストクラスが存在
- [ ] カバレッジ75%以上を維持
- [ ] テストファイル配置が正しい（tests/Service/, tests/Repository/等）

**確認コマンド**:
```bash
docker exec phpunit-apache-1 vendor/bin/phpunit --coverage-text
```

**参照**: `.github/instructions/testing.instructions.md`

#### 4.2 @testdoxアノテーション

**チェック項目**:
- [ ] すべてのテストメソッドに`@testdox`アノテーション
- [ ] メソッド名は英語（日本語関数名禁止）
- [ ] @testdoxの説明が日本語で分かりやすい

**例**:
```php
/**
 * @testdox 有効なユーザーデータでユーザーを作成できる
 */
public function testCreateUserWithValidData(): void
{
    // ...
}
```

**参照**: `.github/instructions/testing.instructions.md` - @testdoxセクション

#### 4.3 モック使用の適切性

**チェック項目**:
- [ ] 外部依存（Repository, Service）はモック化
- [ ] `createMock()` または `createStub()` 使用
- [ ] モックの振る舞い設定が適切

**参照**: `.github/instructions/testing.instructions.md` - モック作成セクション

---

### 🔍 5. コード品質チェック

#### 5.1 重複コード

**チェック項目**:
- [ ] 同じロジックが複数箇所に存在しない
- [ ] 共通処理はHelperまたはBaseクラスに抽出
- [ ] コピペコードなし

#### 5.2 複雑度

**チェック項目**:
- [ ] 1メソッドが50行以内（推奨）
- [ ] ネストが3段階以内（推奨）
- [ ] 早期リターンの活用

**悪い例**:
```php
public function process($data)
{
    if ($data !== null) {
        if (isset($data['id'])) {
            if ($data['id'] > 0) {
                // 処理
            }
        }
    }
}
```

**良い例**:
```php
public function process(?array $data): void
{
    if ($data === null) {
        return;
    }
    
    if (!isset($data['id'])) {
        return;
    }
    
    if ($data['id'] <= 0) {
        return;
    }
    
    // 処理
}
```

#### 5.3 エラーハンドリング

**チェック項目**:
- [ ] 例外処理が適切
- [ ] カスタム例外クラスの使用（必要に応じて）
- [ ] エラーメッセージが分かりやすい
- [ ] ログ出力が適切

**参照**: `.github/instructions/php.instructions.md` - エラーハンドリングセクション

---

## Output（出力形式）

以下の形式でレビューレポートを出力してください。

```markdown
# 🔍 コードレビューレポート

## 📊 変更サマリー

**PR/コミット情報**:
- タイトル: 製品管理機能の追加
- 作成者: @developer-name
- 変更ファイル数: 7
- 追加行数: +350
- 削除行数: -10

**変更内容**:
- src/app/Entity/Product.php (追加)
- src/app/Repository/ProductRepository.php (追加)
- src/app/Service/ProductService.php (追加)
- src/app/Controller/ProductController.php (追加)
- tests/Service/ProductServiceTest.php (追加)
- .docs/plans/api/endpoints.md (修正)
- README.md (修正)

---

## ✅ 問題なし（Good Points）

1. **PSR-12準拠**
   - ✅ すべてのファイルに`declare(strict_types=1);`あり
   - ✅ 命名規則が正しい（PascalCase/camelCase）
   - ✅ インデント・スペースが統一

2. **型宣言**
   - ✅ すべてのメソッドに引数・戻り値の型宣言あり
   - ✅ プロパティにも型宣言あり

3. **セキュリティ対策**
   - ✅ ProductRepository でPrepared Statement使用
   - ✅ ProductController で入力バリデーション実装

4. **テスト**
   - ✅ ProductServiceTest.php が追加されている
   - ✅ @testdoxアノテーション使用

5. **ドキュメント**
   - ✅ .docs/plans/api/endpoints.md に製品管理API追加
   - ✅ README.md のディレクトリ構造更新

---

## ⚠️ 改善推奨（Minor Issues）

### 1. ProductService.php - DI未使用

**場所**: [src/app/Service/ProductService.php](../../src/app/Service/ProductService.php#L15-L20)

**問題**:
```php
public function __construct()
{
    $database = new Database();
    $this->productRepository = new ProductRepository($database);
}
```

**理由**: DIパターン未使用、`new`での直接インスタンス化

**推奨修正**:
```php
public function __construct(ProductRepository $productRepository)
{
    $this->productRepository = $productRepository;
}
```

**参照**: `.github/instructions/architecture.instructions.md` - DI実装パターン

---

### 2. ProductController.php - エラーハンドリング不足

**場所**: [src/app/Controller/ProductController.php](../../src/app/Controller/ProductController.php#L45-L50)

**問題**:
```php
public function create(): void
{
    $data = $_POST;
    $this->productService->createProduct($data);
    echo json_encode(['success' => true]);
}
```

**理由**: 例外処理なし、失敗時の処理が未定義

**推奨修正**:
```php
public function create(): void
{
    try {
        $data = $_POST;
        $product = $this->productService->createProduct($data);
        http_response_code(201);
        echo json_encode(['success' => true, 'data' => $product]);
    } catch (ValidationException $e) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Internal Server Error']);
    }
}
```

**参照**: `.github/instructions/php.instructions.md` - エラーハンドリング

---

### 3. ProductServiceTest.php - モックの振る舞い設定不足

**場所**: [tests/Service/ProductServiceTest.php](../../tests/Service/ProductServiceTest.php#L30-L35)

**問題**:
```php
$mockRepository = $this->createMock(ProductRepository::class);
$service = new ProductService($mockRepository);
$result = $service->getProduct(1);
```

**理由**: モックの戻り値が未設定、テストが不安定

**推奨修正**:
```php
$mockRepository = $this->createMock(ProductRepository::class);
$mockRepository->expects($this->once())
    ->method('findById')
    ->with(1)
    ->willReturn(new Product(1, 'Test Product', 1000));

$service = new ProductService($mockRepository);
$result = $service->getProduct(1);

$this->assertInstanceOf(Product::class, $result);
$this->assertSame(1, $result->getId());
```

**参照**: `.github/instructions/testing.instructions.md` - モック作成

---

### 4. ドキュメント更新漏れ

**場所**: `.docs/plans/architecture.md`

**問題**: ProductService の実装例が未追加

**推奨修正**: 
```markdown
## Service層の実装例

### UserService

...

### ProductService

製品管理のビジネスロジックを実装。

\`\`\`php
class ProductService
{
    private ProductRepository $productRepository;
    
    public function __construct(ProductRepository $productRepository)
    {
        $this->productRepository = $productRepository;
    }
    
    public function createProduct(array $data): Product
    {
        // バリデーション
        // 製品作成
        // 保存
    }
}
\`\`\`
```

**参照**: `.github/agents/pre-commit-checker.agent.md` - ドキュメント整合性チェック

---

## ❌ 修正必須（Critical Issues）

### 1. CSRF対策未実装

**場所**: [src/app/Controller/ProductController.php](../../src/app/Controller/ProductController.php#L45)

**問題**: POST/PUT/DELETEでCSRFトークン検証なし

**重大度**: 🔴 High（セキュリティリスク）

**推奨修正**:
```php
public function create(): void
{
    // CSRFトークン検証
    if (!SecurityHelper::verifyCsrfToken($_POST['csrf_token'] ?? '')) {
        http_response_code(403);
        echo json_encode(['success' => false, 'error' => 'CSRF token validation failed']);
        return;
    }
    
    // 以下、処理続行
}
```

**参照**: `.github/instructions/security.instructions.md` - CSRF対策セクション

---

### 2. XSS対策未実装

**場所**: [src/app/Controller/ProductController.php](../../src/app/Controller/ProductController.php#L60-L65)

**問題**:
```php
public function show(int $id): void
{
    $product = $this->productService->getProduct($id);
    echo "<h1>{$product->getName()}</h1>";  // XSS脆弱性
}
```

**重大度**: 🔴 High（セキュリティリスク）

**推奨修正**:
```php
public function show(int $id): void
{
    $product = $this->productService->getProduct($id);
    echo "<h1>" . SecurityHelper::escape($product->getName()) . "</h1>";
}
```

**参照**: `.github/instructions/security.instructions.md` - XSS対策セクション

---

### 3. テストカバレッジ不足

**場所**: `tests/Service/ProductServiceTest.php`

**問題**: 
- ProductService::updateProduct() のテストなし
- ProductService::deleteProduct() のテストなし

**重大度**: 🟡 Medium（品質リスク）

**推奨**: 以下のテストを追加
```php
/**
 * @testdox 有効なデータで製品を更新できる
 */
public function testUpdateProductWithValidData(): void
{
    // ...
}

/**
 * @testdox 存在する製品を削除できる
 */
public function testDeleteExistingProduct(): void
{
    // ...
}
```

**参照**: `.github/instructions/testing.instructions.md`

---

## 📈 コード品質メトリクス

| 項目 | 現在値 | 目標値 | 状態 |
|-----|-------|-------|------|
| テストカバレッジ | 68% | 75%以上 | ⚠️ 不足 |
| PSR-12準拠 | 100% | 100% | ✅ OK |
| 型宣言率 | 95% | 100% | ⚠️ 要改善 |
| セキュリティ対策 | 60% | 100% | ❌ 要修正 |

---

## 🎯 総合評価

### レビュー結果: ⚠️ 条件付き承認（Approve with Changes）

**理由**:
- ✅ アーキテクチャ設計は適切
- ✅ コーディング規約準拠
- ❌ セキュリティ対策が不十分（CSRF, XSS）
- ⚠️ テストカバレッジ不足
- ⚠️ DI未使用箇所あり

### マージ可否: ❌ 修正後にマージ推奨

**必須修正項目**:
1. 🔴 CSRF対策実装（ProductController）
2. 🔴 XSS対策実装（ProductController）
3. 🟡 テストカバレッジ向上（updateProduct, deleteProduct）

**推奨修正項目**:
1. ProductService のDI対応
2. エラーハンドリング追加
3. ドキュメント更新

---

## 📋 Next Steps

### 開発者へのアクションアイテム

1. **優先度: 高（マージ前に必須）**
   - [ ] ProductController にCSRF対策追加
   - [ ] ProductController にXSS対策追加
   - [ ] ProductServiceTest にテストケース追加

2. **優先度: 中（できれば修正）**
   - [ ] ProductService のDI対応
   - [ ] エラーハンドリング改善
   - [ ] .docs/plans/architecture.md 更新

3. **フォローアップレビュー**
   - 上記修正後、再度以下を実行:
   ```
   @workspace 
   
   .github/prompts/code-review.prompt.md で再レビューしてください。
   ```

---

## 📚 参考資料

- セキュリティ対策: `.github/instructions/security.instructions.md`
- アーキテクチャ設計: `.github/instructions/architecture.instructions.md`
- テスト実装: `.github/instructions/testing.instructions.md`
- PHP規約: `.github/instructions/php.instructions.md`

---

**レビュー実施日**: 2026-02-14  
**レビュアー**: GitHub Copilot Agent  
**レビュー時間**: 約5分

```

---

## Review Guidelines（レビュー実施ガイドライン）

### エージェントへの指示

1. **段階的にチェック**
   - まず重大度の高い問題（セキュリティ、アーキテクチャ違反）をチェック
   - 次にコード品質、テスト、ドキュメントをチェック

2. **具体的な指摘**
   - ファイル名と行番号を明示
   - 問題のコードを引用
   - 修正例を必ず提示

3. **重大度の判定**
   - 🔴 High: セキュリティリスク、アーキテクチャ違反、データ破損リスク
   - 🟡 Medium: テストカバレッジ不足、エラーハンドリング不足
   - 🟢 Low: コーディングスタイル、命名

4. **建設的なフィードバック**
   - 問題点だけでなく、良い点も指摘
   - 参照ドキュメントへのリンクを提供
   - 修正後の再レビュー方法を明示

5. **総合評価**
   - ✅ Approve: 問題なし、そのままマージ可能
   - ⚠️ Approve with Changes: 軽微な修正後にマージ可能
   - ❌ Request Changes: 重大な問題あり、修正必須

---

## Example（実行例）

### 入力例

```
@workspace 

.github/prompts/code-review.prompt.md に基づいて、
以下のコミットをレビューしてください。

git diff main..feature-product-management
```

### 出力例

上記の「Output（出力形式）」セクションを参照。

---

## Notes（注意事項）

- このプロンプトは**ガイダンス**であり、最終判断はレビュアーが行ってください
- 自動レビューツール（PHPStan, PHP_CodeSniffer等）と併用推奨
- 定期的にチェックリストを更新し、プロジェクトの進化に対応してください

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-14
