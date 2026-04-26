---
name: prepare-test-context
description: src配下を分析し、Unit/Integration/E2Eのテスト準備メモを.docs/testiing/tmpへ分割生成する
tools: [read, search, edit, agent, todo]
---

# Prepare Test Context Prompt

src配下のコードを起点に、テスト実装前の分析コンテキストを作成する。

## 実施内容

1. src/app と tests を対応付けて棚卸しする
2. Unit/Integration/E2E の不足観点を抽出する
3. .docs/testiing/tmp/*.tmp.md に分割保存する
4. 優先度 高 の項目を、すぐ実装できる粒度へ落とす

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

/prepare-test-context

対象: src/app/Service/UserService.php と src/app/Service/AuthService.php を中心に調査
要件: Unit/Integration/E2E それぞれ不足ケースを5件以上抽出
制約: 各.tmpは1セクション200行以下で分割
