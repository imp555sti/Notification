---
name: generate-tests
description: PHPUnit 9.x準拠の単体テストを生成。@testdoxアノテーション、カバレッジ75%目標
tools: [vscode/getProjectSetupInfo, read, edit/createDirectory, edit/createFile, edit/editFiles, search, todo]
---

# Generate Tests Prompt

指定されたクラスに対するPHPUnit 9.x準拠のテストを生成します。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

以下を満たすテストコードを生成します：

1. **PHPUnit 9.x互換**
2. **@testdoxアノテーション必須（日本語説明）**
3. **カバレッジ75%以上**を実現
4. **モック使用**（外部依存のテスト化）
5. **PSR-12準拠**

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

#### ケース1: 特定クラスのテスト生成

```
/generate-tests

以下のクラスのテストを生成してください。

クラス: src/app/Service/ProductService.php

.github/instructions/testing.instructions.md を参照して、
モックを使用した適切なテストケースを作成してください。

要件:
- PHPUnit 9.x
- @testdox アノテーション必須（日本語説明）
- メソッド名は英語
- カバレッジ75%以上を目指す
```

#### ケース2: ワークスペース全体のテストカバレッジ向上

```
/generate-tests

**📊 ワークスペース全体を対象に**、
テストカバレッジを75%以上に引き上げてください。

以下の手順で実施してください：

1. 現在のカバレッジを確認
   docker exec phpunit-apache-1 vendor/bin/phpunit --coverage-text

2. カバレッジが不足しているクラスを特定

3. 各クラスの不足しているテストケースを生成

4. テストを実行して確認
   docker exec phpunit-apache-1 vendor/bin/phpunit

.github/instructions/testing.instructions.md を参照してください。
```

---

## テスト生成ガイドライン

### テストファイルの配置

```
tests/
├── Service/          # サービス層テスト
├── Repository/       # リポジトリ層テスト
├── Entity/          # エンティティ層テスト
├── Controller/      # コントローラー層テスト
└── Helper/          # ヘルパー関数テスト
```

### テストクラス作成例

```php
<?php

declare(strict_types=1);

namespace Tests\Service;

use PHPUnit\Framework\TestCase;
use App\Service\ProductService;
use App\Repository\ProductRepository;
use App\Entity\Product;

/**
 * ProductServiceのテスト
 */
class ProductServiceTest extends TestCase
{
    private ProductService $service;
    private ProductRepository $mockRepository;

    protected function setUp(): void
    {
        $this->mockRepository = $this->createMock(ProductRepository::class);
        $this->service = new ProductService($this->mockRepository);
    }

    /**
     * @testdox 有効なデータで製品を作成できる
     */
    public function testCreateProductWithValidData(): void
    {
        // Arrange
        $data = ['name' => 'Test Product', 'price' => 1000];
        $expected = new Product(1, 'Test Product', 1000);
        
        $this->mockRepository->expects($this->once())
            ->method('save')
            ->with($this->anything())
            ->willReturn($expected);

        // Act
        $result = $this->service->createProduct($data);

        // Assert
        $this->assertInstanceOf(Product::class, $result);
        $this->assertSame('Test Product', $result->getName());
        $this->assertSame(1000, $result->getPrice());
    }

    /**
     * @testdox 無効なデータで例外がスロー される
     */
    public function testCreateProductWithInvalidData(): void
    {
        // Arrange
        $this->expectException(\InvalidArgumentException::class);
        $data = ['name' => '', 'price' => -100];

        // Act
        $this->service->createProduct($data);
    }
}
```

### テスト実行・カバレッジ確認

```bash
# テスト実行
docker exec phpunit-apache-1 vendor/bin/phpunit

# カバレッジ確認
docker exec phpunit-apache-1 vendor/bin/phpunit --coverage-text

# 特定ディレクトリのみテスト
docker exec phpunit-apache-1 vendor/bin/phpunit tests/Service/
```

**参照**: `.github/instructions/testing.instructions.md`