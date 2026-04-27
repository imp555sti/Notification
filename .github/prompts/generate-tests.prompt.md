---
name: generate-tests
description: PHPUnit 9.x準拠の単体テストを生成。@testdoxアノテーション、カバレッジ75%目標
tools: [vscode/getProjectSetupInfo, read, edit/createDirectory, edit/createFile, edit/editFiles, search, todo]
---

# Generate Tests Prompt

指定されたクラスに対する PHPUnit 9.x 準拠テストを生成します。

## Purpose（目的）

以下を満たすテストコードを作成する。

1. PHPUnit 9.x 互換
2. `@testdox` アノテーション必須（日本語説明）
3. カバレッジ 75% 以上を目標
4. モックで外部依存を分離
5. PSR-12 準拠

## 入力テンプレート

`/generate-tests` 実行時は、次の情報を受け取って進める。

```text
対象クラス: src/.../TargetClass.php
目的: 新規作成 / 既存拡張 / カバレッジ改善
追加要件: 任意（例: 例外系を厚く、特定メソッド優先）
```

## 実行指示

1. `.github/instructions/testing.instructions.md` を必ず参照する
2. 詳細ワークフローは `.github/skills/generate-tests-workflow/SKILL.md` に従う
3. 出力は「変更ファイル」「追加ケース」「実行結果要約」を含める

## 参照

- `.github/instructions/testing.instructions.md`
- `.github/skills/generate-tests-workflow/SKILL.md`