---
name: team-orchestrator
description: チーム エージェント オーケストレーター。要求を分析し、コード生成・テスト・レビューを動的に実行・調整
tools: [vscode/getProjectSetupInfo, vscode/askQuestions, read, agent, edit, search, web, todo]
---

# Team Orchestrator Prompt

複数のエージェント（生成・テスト・レビュー）を調整し、チームで開発するような包括的なワークフローをオーケストレーションするプロンプトです。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Purpose（目的）

開発タスクの要求を受け取り、以下をオーケストレートします：

1. **要求分析**: 必要なタスクを特定
2. **ダイナミックディスパッチ**: 適切なプロンプトに振り分け
3. **反復改善**: レビュー指摘を修正して繰り返す（最大N回）
4. **品質保証**: テストカバレッジ・セキュリティ・アーキテクチャを検証
5. **最終成果物**: ファイル自動作成または提案表示

---

## 📚 参考ドキュメント

詳細な実行手順とエージェント連携については、以下を参照してください：

- **[Orchestration Workflow Guide](../workflows/orchestration-workflow.md)** - フェーズ別の実行手順、チェックリスト、トラブルシューティング
- **[Agent Orchestration Map](../docs/agent-orchestration-map.md)** - 各プロンプトの連携ルール、入出力仕様、実行シーケンス図

---

## Usage（使用方法）

### GitHub Copilot Chat での実行

```
/team-orchestrator

以下の要求に対して、包括的な開発タスクをオーケストレーションしてください:

## 要求

Product（製品）管理機能を実装してください。

### 要件

1. **Entity層**: Product.php
   - ID、名前、価格、説明を持つ
   
2. **Repository層**: ProductRepository.php
   - CRUD操作（作成・取得・更新・削除）
   - Prepared Statement使用
   
3. **Service層**: ProductService.php
   - ビジネスロジック実装
   - バリデーション
   - トランザクション管理
   
4. **Controller層**: ProductController.php
   - HTTPリクエスト処理
   - レスポンス生成
   - CSRF対策
   
5. **テスト**: ProductServiceTest.php, ProductRepositoryTest.php
   - ユニットテスト
   - モック使用
   - カバレッジ75%以上
   
6. **ドキュメント**:
   - PHPDocコメント
   - .docs/plans/api/endpoints.md に API仕様を追加

### 制約

- PSR-12準拠
- アーキテクチャ: MVC + Service + Repository + Entity
- PHP7.4互換
- セキュリティ対策必須（XSS/CSRF/SQLインジェクション）
- 型宣言必須

### 優先度

1. Entity → Repository → Service → Controller（順序厳守）
2. 各ステップでレビューを実施
3. テストは実装完了後
```

---

## オーケストレーション処理フロー

```
┌─────────────────────────────────────────┐
│     1. 要求受信・分析フェーズ             │
│  - 要求内容を理解                         │
│  - 必要なタスクを列挙（Entity/Repo等）    │
│  - 実装順序を決定                         │
│  - 最大反復回数を決定（デフォルト3回）    │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  2. コード生成・レビューサイクル（反復） │
│  ┌─────────────────────────────────────┐│
│  │ 2-A. 次のタスクを実行                ││
│  │  1) コード生成: /refactor-code      ││
│  │  2) コード品質レビュー: /code-review││
│  │  3) 指摘があれば修正・繰り返し        ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ 2-B. テスト生成（実装完了後）        ││
│  │  1) テスト生成: /generate-tests     ││
│  │  2) テスト実行成功確認                ││
│  │  3) カバレッジ確認                    ││
│  └─────────────────────────────────────┘│
│  ┌─────────────────────────────────────┐│
│  │ 2-C. セキュリティ・アーキ検証        ││
│  │  1) セキュリティレビュー              ││
│  │  2) アーキテクチャ検証                ││
│  │  3) 全体レビュー                      ││
│  └─────────────────────────────────────┘│
└──────────────┬──────────────────────────┘
               ↓
────反復回数チェック────
    │               │
    ↓（続行）      ↓（終了）
  2-Aへ         3へ
               
┌─────────────────────────────────────────┐
│     3. 最終品質チェック・成果物作成      │
│  - テストカバレッジ確認（75%以上）      │
│  - セキュリティ脆弱性確認                 │
│  - ドキュメント整合性確認                 │
│  - ファイル自動作成または提案             │
└─────────────────────────────────────────┘
```

---

## 推奨実行ステップ（段階的）

### ステップ1: 要求定義

以下の情報を明確に記述してください：

```
/team-orchestrator

## 要求

[実装したい機能の説明]

## 実装対象

- [ ] Entity層
- [ ] Repository層
- [ ] Service層
- [ ] Controller層
- [ ] テスト
- [ ] ドキュメント

## 具体的な要件

[Entity、Repository、Service、Controller各層の具体的な要件]

## 制約・ガイドライン

- PSR-12準拠
- PHP7.4互換
- セキュリティ対策（XSS/CSRF/SQLインジェクション）
- アーキテクチャ: Entity → Repository → Service → Controller
- テストカバレッジ: 75%以上
- 型宣言必須
```

---

### ステップ2: Orchestrator が以下を自動実行

1. **要求分析**
   - 必要なレイヤーを特定
   - 実装順序を決定
   - 品質基準を設定

2. **コード生成・品質サイクル（反復）**
   - `/refactor-code` でコード生成
   - `/code-review` でレビュー
   - 品質改善まで繰り返し

3. **セキュリティ・アーキテクチャ検証**
   - `/security-review` 実行
   - `/verify-architecture` 実行
   - 違反があれば修正

4. **テスト生成・実行**
   - `/generate-tests` でテスト生成
   - テスト実行・カバレッジ確認
   - 不足分を生成

5. **ドキュメント整備**
   - `/generate-docs` で生成
   - `/check-documentation-consistency` で確認

---

## 出力フォーマット

Orchestrator は以下の形式でレポートを提示します：

```markdown
# 🤖 Team Orchestrator 実行結果

## 📋 要求分析

- **要求内容**: [要求の要約]
- **必要タスク**: [Entity, Repository, Service, Controller, Tests, Docs]
- **実装順序**: Entity → Repository → Service → Controller → Tests → Docs
- **最大反復回数**: 3回
- **推定工数**: XXX時間

---

## ✅ 実装完了

### ✨ 生成ファイル一覧

1. **Entity層**
   - ✅ src/app/Entity/Product.php
   - 品質: ⭐⭐⭐⭐⭐ (5/5)

2. **Repository層**
   - ✅ src/app/Repository/ProductRepository.php
   - 品質: ⭐⭐⭐⭐⭐ (5/5)

3. **Service層**
   - ✅ src/app/Service/ProductService.php
   - 品質: ⭐⭐⭐⭐☆ (4/5)
   - 指摘: メソッド複雑度が高い → 反復1で修正済み

4. **Controller層**
   - ✅ src/app/Controller/ProductController.php
   - 品質: ⭐⭐⭐⭐⭐ (5/5)

5. **テスト**
   - ✅ tests/Service/ProductServiceTest.php
   - ✅ tests/Repository/ProductRepositoryTest.php
   - カバレッジ: 78% （目標75%達成✅）

6. **ドキュメント**
   - ✅ .docs/plans/api/endpoints.md 更新
   - ✅ PHPDocコメント追加

---

## 📊 品質指標

| 項目 | 閾値 | 実績 | 判定 |
|------|------|------|------|
| テストカバレッジ | 75% | 78% | ✅ |
| セキュリティ脆弱性 | 0件 | 0件 | ✅ |
| アーキテクチャ違反 | 0件 | 0件 | ✅ |
| コード品質 | A以上 | A | ✅ |

---

## 🔄 実行履歴

### 反復1: Entity層実装
- ✅ コード生成
- ✅ レビュー実施
- ✅ 修正完了

### 反復2: Repository → Service実装
- ✅ コード生成
- ⚠️ レビュー: メソッド複雑度が高い
- ✅ 修正完了

### 反復3: Controller → Tests実装
- ✅ コード生成
- ✅ レビュー実施
- ✅ テスト実行成功（カバレッジ78%）

---

## 🎯 推奨アクション

1. 生成されたファイルを確認
   ```bash
   git status
   ```

2. テスト実行確認
   ```bash
   docker exec phpunit-apache-1 vendor/bin/phpunit tests/
   ```

3. マージ前ドキュメント確認
   ```
   /check-documentation-consistency
   ```

---

**実行時刻**: 2026-02-14 10:30:00  
**所要時間**: 約5分  
**Orchestrator**: v1.0.0
```

---

## カスタマイズ設定

### Skip 設定（特定タスクをスキップ）

```
/team-orchestrator

要求: [要求内容]

設定:
- skip: [controller, tests]  # Controller・TestsをスキップしてEntity～Serviceのみ
```

### 反復回数カスタマイズ

```
/team-orchestrator

要求: [要求内容]

設定:
- max_iterations: 5  # デフォルト 3回 → 5回に変更
```

### 優先度設定

```
/team-orchestrator

要求: [要求内容]

設定:
- focus_on: security  # セキュリティを最優先
```

---

## 使用例

### 例1: Product 機能を実装

```
/team-orchestrator

## 要求

Product（製品）管理エンティティのCRUD実装

## 実装対象

- [x] Entity層
- [x] Repository層
- [x] Service層
- [x] Controller層
- [x] テスト
- [x] ドキュメント

## 具体的な要件

### Entity層 (Product.php)
- プロパティ: id (int), name (string, 1-255), price (int, 1以上), description (string)
- Getter実装
- PHPDocコメント

### Repository層 (ProductRepository.php)
- BaseRepository継承
- CRUD メソッド: find, findAll, save, update, delete
- Prepared Statement 使用
- エラーハンドリング

### Service層 (ProductService.php)
- ProductRepository DI
- createProduct(array): Product
- getProduct(int): Product
- updateProduct(int, array): Product
- deleteProduct(int): void
- バリデーション実装

### Controller層 (ProductController.php)
- BaseController継承
- ProductService DI
- POST /api/products → createProduct()
- GET /api/products/{id} → getProduct()
- PUT /api/products/{id} → updateProduct()
- DELETE /api/products/{id} → deleteProduct()
- CSRF トークン検証

### テスト
- ProductServiceTest.php: @testdox日本語説明
- ProductRepositoryTest.php: CRUD テスト
- モック使用、カバレッジ75%以上

### ドキュメント
- PHPDocコメント
- .docs/plans/api/endpoints.md にAPI仕様

## 制約・ガイドライン

- PSR-12準拠
- PHP7.4互換
- 型宣言必須
- セキュリティ対策: XSS/CSRF/SQLインジェクション
- アーキテクチャ: Entity → Repository → Service → Controller
```

---

### 例2: 既存機能の改善

```
/team-orchestrator

## 要求

既存の User 管理機能のセキュリティ・品質改善

## 実装対象

- [ ] Entity層 (修正)
- [x] Repository層 (修正)
- [x] Service層 (修正)
- [x] Controller層 (修正)
- [x] テスト (追加)
- [ ] ドキュメント (チェック)

## 具体的な要件

### Security修正
- パスワード管理: password_hash() をBCRYPT使用に変更
- XSS対策: すべての出力を SecurityHelper::escape() で保護
- バリデーション: ValidationHelper で入力検証

### テスト改善
- カバレッジ 65% → 80%に向上
- エッジケース追加: 重複メール登録、無効パスワード等

## 設定

- max_iterations: 5  # セキュリティ重視のため反復回数増
- focus_on: security
```

---

## 関連プロンプト

Team Orchestrator が以下のプロンプトを自動的に呼び出します：

| プロンプト | 役割 | 呼び出しタイミング |
|----------|------|-----------------|
| `/refactor-code` | コード生成・修正 | コード実装フェーズ |
| `/code-review` | コード品質レビュー | 各レイヤー実装後 |
| `/generate-tests` | テスト生成 | 実装完了後 |
| `/security-review` | セキュリティレビュー | 全実装完了後 |
| `/verify-architecture` | アーキテクチャ検証 | 全実装完了後 |
| `/generate-docs` | ドキュメント生成 | テスト完了後 |
| `/check-documentation-consistency` | ドキュメント整合性確認 | 最終チェック |

---

## 関連ドキュメント（詳細）

- [Orchestration Workflow Guide](../workflows/orchestration-workflow.md) - 実行ガイドとチェックリスト
- [Agent Orchestration Map](../docs/agent-orchestration-map.md) - エージェント連携マップ
- [Code Review Prompt](./code-review.prompt.md)
- [Generate Tests Prompt](./generate-tests.prompt.md)
- [Security Review Prompt](./security-review.prompt.md)
- [Verify Architecture Prompt](./verify-architecture.prompt.md)
- [Architecture Instructions](../instructions/architecture.instructions.md)
- [Testing Instructions](../instructions/testing.instructions.md)

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-14
