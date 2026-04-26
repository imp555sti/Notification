---
name: verify-architecture
description: MVC+Service+Repository+Entityアーキテクチャの準拠性チェック。依存方向・レイヤー責務の検証
tools:
  - read
  - search
  - agent
  - vscode/getProjectSetupInfo
---

# Verify Architecture Prompt

プロジェクトのアーキテクチャ準拠性を検証します。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

アーキテクチャルール準拠性を包括的に検証します：

1. **レイヤー責務の遵守**
2. **依存方向の正しさ**
3. **DI（依存注入）使用**
4. **命名規則準拠**

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

#### ケース1: 特定モジュールのアーキテクチャ検証

```
/verify-architecture

以下のモジュールのアーキテクチャを検証してください。

モジュール: Product（製品管理）
ファイル:
  - src/app/Entity/Product.php
  - src/app/Repository/ProductRepository.php
  - src/app/Service/ProductService.php
  - src/app/Controller/ProductController.php

検証項目:
1. 各レイヤーの責務が正しいか
2. 依存方向が正しいか（Controller → Service → Repository → Entity）
3. DI（コンストラクタインジェクション）が使用されているか

.github/instructions/architecture.instructions.md を参照してください。
```

#### ケース2: ワークスペース全体のアーキテクチャ監査

```
/verify-architecture

**🏗️ ワークスペース全体を対象に**、
アーキテクチャ準拠性を包括的に監査してください。

検証項目:

1. **レイヤー責務**
   - Entity層: ビジネスロジックなし（データ保持のみ）
   - Repository層: データベースアクセスのみ
   - Service層: ビジネスロジック実装
   - Controller層: HTTP処理のみ

2. **依存方向**
   ```
   Controller → Service → Repository → Entity
   ```
   逆方向の依存がないか

3. **DI使用**
   - すべてのクラスがコンストラクタインジェクション使用
   - `new` での直接インスタンス化がないか
   - グローバル変数がないか

4. **命名規則**
   - クラス名がレイヤーを表している
   - Service: xxxService
   - Repository: xxxRepository
   - Entity: xxx
   - Controller: xxxController

5. **ファイル配置**
   - Entity: src/app/Entity/
   - Repository: src/app/Repository/
   - Service: src/app/Service/
   - Controller: src/app/Controller/

違反している箇所を特定し、修正案を提示してください。

.github/instructions/architecture.instructions.md を参照してください。
```

---

## 検証チェックリスト

### ✅ レイヤー責務

```markdown
## Entity層

- [ ] ビジネスロジックなし
- [ ] Getter/Setter のみ
- [ ] バリデーションなし
- [ ] 他のレイヤーに依存していない

## Repository層

- [ ] データベースアクセスのみ
- [ ] ビジネスロジックなし
- [ ] Prepared Statement使用
- [ ] BaseRepositoryを継承
- [ ] 他のRepository/Serviceに依存していない

## Service層

- [ ] ビジネスロジック実装
- [ ] トランザクション管理
- [ ] 複数Repositoryの協調
- [ ] Repository をコンストラクタインジェクション
- [ ] バリデーション実施

## Controller層

- [ ] HTTP処理のみ
- [ ] ビジネスロジックなし
- [ ] Service をコンストラクタインジェクション
- [ ] バリデーション実施
- [ ] Repository を直接使用していない
```

### ✅ 依存方向

```markdown
## 許可される依存

- [ ] Controller → Service
- [ ] Service → Repository
- [ ] Service → Service（DIで注入）
- [ ] Repository → Entity
- [ ] すべて → Helper

## 禁止される依存

- [ ] Entity → 他のレイヤー
- [ ] Repository → Service
- [ ] Repository → Controller
- [ ] Service → Controller
```

### 出力形式

```markdown
# 🏗️ アーキテクチャ検証レポート

## ✅ 準拠している項目

1. Entity層の責務が正しい（ビジネスロジックなし）
2. Repository層がPrepared Statement使用
3. すべてのServiceがRepositoryをDIで受け取り

---

## ❌ 違反項目

### 1. UserService が直接 UserRepository をnewしている

**ファイル**: src/app/Service/UserService.php#15

**問題**: DI未使用

**種類**: DI違反

**修正**:
```php
// Before
class UserService
{
    public function __construct()
    {
        $this->repository = new UserRepository();
    }
}

// After
class UserService
{
    public function __construct(UserRepository $repository)
    {
        $this->repository = $repository;
    }
}
```

---

### 2. ProductController が ProductService を経由せず ProductRepository を直接使用

**ファイル**: src/app/Controller/ProductController.php#45

**問題**: レイヤー責務違反

**種類**: 依存方向違反

**修正**: ProductService を経由して処理を実施

---

## 修正優先度

1. **高**: DI未使用（テスト困難）
2. **中**: レイヤー責務違反
3. **低**: 命名規則

---

## 次アクション

`/refactor-code` を実行して、検出された違反を修正してください。
```

**参照**: `.github/instructions/architecture.instructions.md`