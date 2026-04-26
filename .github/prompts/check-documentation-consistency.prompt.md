---
name: check-documentation-consistency
description: ドキュメントとコードの整合性確認。変更がドキュメントに与える影響を分析
tools:
  - read
  - search
  - vscode/getProjectSetupInfo
  - todo
---

# Check Documentation Consistency Prompt

ドキュメントとコードの整合性を確認する再利用可能なプロンプトです。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14

---

## Prompt

```

**ワークスペース全体のMarkdownファイルを対象に**
以下の変更がプロジェクトドキュメントに与える影響を分析してください。

## 変更内容

[ここに変更ファイルリストを記載]

例:
- src/app/Service/ProductService.php (追加)
- src/app/Repository/ProductRepository.php (追加)
- src/app/Entity/Product.php (追加)
- config/app.php (削除)
- src/app/Config/App.php (追加)

---

## チェック対象ドキュメント

以下のドキュメントについて、変更による影響を確認してください：

### プロジェクトルートドキュメント
1. README.md
2. SETUP.md

### GitHub Copilot関連
3. .github/copilot-instructions.md
4. .github/instructions/php.instructions.md
5. .github/instructions/security.instructions.md
6. .github/instructions/architecture.instructions.md
7. .github/instructions/database.instructions.md
8. .github/instructions/testing.instructions.md
9. .github/instructions/setup.instructions.md
10. .github/instructions/deployment.instructions.md

### プロジェクトドキュメント
11. .docs/plans/architecture.md
12. .docs/plans/development/setup.md
13. .docs/plans/development/testing.md
14. .docs/plans/development/coding-standards.md
15. .docs/plans/security/best-practices.md
16. .docs/plans/api/endpoints.md

---

## 分析観点

各ドキュメントについて、以下の観点でチェックしてください：

### 1. ディレクトリ構造・ファイルパス
- [ ] ディレクトリ構造の図が最新か
- [ ] ファイルパスの記述が正しいか
- [ ] 削除されたファイルへの言及が残っていないか

### 2. コード例・実装例
- [ ] コード例が動作するか
- [ ] import/use文が正しいか
- [ ] クラス名・メソッド名が一致するか

### 3. セットアップ手順
- [ ] 環境構築手順が実行可能か
- [ ] 環境変数の設定方法が正しいか
- [ ] Dockerコマンドが最新か

### 4. API仕様
- [ ] 新しいエンドポイントが追加されているか
- [ ] レスポンス形式が更新されているか
- [ ] 削除されたエンドポイントの説明が削除されているか

### 5. セキュリティ
- [ ] セキュリティ対策の実装例が正しいか
- [ ] 新しいセキュリティ要件が追加されているか

### 6. テスト
- [ ] テスト実行コマンドが正しいか
- [ ] テストディレクトリ構造が最新か

---

## 出力形式

以下の形式で結果を報告してください：

```markdown
# ドキュメント整合性チェック結果

## サマリー

- ✅ 問題なし: X件
- ⚠️ 修正推奨: Y件
- ❌ 修正必須: Z件

---

## 詳細レポート

### ✅ 問題なし

1. **ファイル名**
   - 確認項目: ...
   - 理由: ...

### ⚠️ 修正推奨

1. **ファイル名**
   - 行番号: XXX
   - 現在の記述: "..."
   - 推奨修正: "..."
   - 理由: ...
   - 優先度: 高/中/低

### ❌ 修正必須

1. **ファイル名**
   - 行番号: XXX
   - 現在の記述: "..."
   - 必要な修正: "..."
   - 理由: ...
   - 影響: セットアップ不可/API仕様不一致/セキュリティ懸念 等

---

## 推奨アクション

1. [具体的な修正手順]
2. [具体的な修正手順]
3. ...

---

## GitHub Copilot Chatでの修正プロンプト例

`````
ファイル名 を以下のように修正してください：

行XXX:
```diff
- 旧: ...
+ 新: ...
```

理由: ...
`````
```

---

## 使用例

### ケース1: 新機能追加時

```
/check-documentation-consistency

以下の変更がドキュメントに与える影響を確認してください:

変更内容:
- src/app/Service/ProductService.php (追加)
- src/app/Repository/ProductRepository.php (追加)
- src/app/Entity/Product.php (追加)
- tests/Service/ProductServiceTest.php (追加)
```

### ケース2: リファクタリング時

```
/check-documentation-consistency

以下の変更がドキュメントに与える影響を確認してください:

変更内容:
- config/app.php (削除)
- config/database.php (削除)
- src/app/Config/App.php (追加)
- src/app/Config/Database.php (追加)
- src/app/bootstrap.php (修正)
- tests/bootstrap.php (修正)
```

### ケース3: Docker環境変更時

```
/check-documentation-consistency

以下の変更がドキュメントに与える影響を確認してください:

変更内容:
- docker-compose.yml (修正: mountポイント変更)
- phpunit.xml (修正: パス変更)
- .docker/apache/httpd.conf (修正)
```

---

## チェックリスト（プロンプト実行前）

使用前に以下を確認してください：

- [ ] git status で変更ファイルを確認済み
- [ ] 変更内容を正確に把握している
- [ ] テストが全てパスしている
- [ ] コーディング規約チェック済み

---

## 関連リソース

- **より詳細なチェック**: `.github/agents/pre-commit-checker.agent.md` を使用
- **セキュリティ重点チェック**: `.github/prompts/security-review.prompt.md` を使用
- **開発ワークフロー**: `.github/DEVELOPMENT_WORKFLOW.md` 参照

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-14
