---
name: implement-tests-from-context
description: "Use when: .docs/testiing/tmpの分析メモを根拠に、段階的にテストを実装したい時"
tools: [read, search, edit, agent, execute, todo]
---

# Implement Tests From Context Prompt

.docs/testiing/tmp の分析結果を入力として、テストコードを段階的に生成・更新する。

## 入力テンプレート

```text
対象メモ: .docs/testiing/tmp/*.tmp.md
優先度: 高 / 中 / 低
範囲: Unit / Integration / E2E（複数可）
完了条件: 任意（例: 3ケース追加してグリーン）
```

## 実行指示

1. `.github/instructions/testing.instructions.md` を必ず参照する
2. 詳細ワークフローは `.github/skills/test-prep-pipeline/SKILL.md` に従う
3. 1回の更新は1領域（最大3テストケース）を上限に進める
4. 実装後は `.docs/testiing/tmp/*.tmp.md` に完了・残課題を追記する

## 更新ルール

- 1回の更新は1領域（最大3テストケース）
- 特定テストケース指定がある場合は、指定対象を最優先で更新
- 変更理由をテスト名で明確化
- 既存ケースと重複する場合は統合を優先
- リファクタリングより、まず不足ケース充足を優先

## 実行例

```text
/implement-tests-from-context

対象メモ: .docs/testiing/tmp/unit-analysis.tmp.md
優先度: 高
範囲: Unit
完了条件: 境界値ケースを3件追加し、tmpへ反映
```
