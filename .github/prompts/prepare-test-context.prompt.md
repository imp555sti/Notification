---
name: prepare-test-context
description: "Use when: src配下を分析し、Unit/Integration/E2Eのテスト準備メモを作成したい時"
tools: [read, search, edit, agent, todo]
---

# Prepare Test Context Prompt

src配下のコードを起点に、テスト実装前の分析コンテキストを作成する。

## 入力テンプレート

```text
対象: src/...（ファイルまたはディレクトリ）
深さ: quick / medium / thorough
追加要件: 任意（例: Service層優先、境界値重視）
```

## 実行指示

1. `.github/instructions/test-preparation.instructions.md` を必ず参照する
2. 詳細ワークフローは `.github/skills/test-prep-pipeline/SKILL.md` に従う
3. 出力は `.docs/testiing/tmp/*.tmp.md` へ分割保存する
4. 各セクションに「対象・不足テスト・追加候補ケース・優先度」を含める

## 参照ルール

- .github/instructions/test-preparation.instructions.md
- .github/instructions/testing.instructions.md
- .github/instructions/architecture.instructions.md
- .github/instructions/security.instructions.md

## 期待成果物

- .docs/testiing/tmp/source-inventory.tmp.md
- .docs/testiing/tmp/unit-analysis.tmp.md
- .docs/testiing/tmp/integration-analysis.tmp.md
- .docs/testiing/tmp/e2e-analysis.tmp.md

## 実行例

```text
/prepare-test-context

対象: src/app/Service/UserService.php と src/app/Service/AuthService.php
深さ: medium
追加要件: Unit/Integration/E2E それぞれ不足ケースを5件以上抽出
```
