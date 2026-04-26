---
name: implement-tests-from-context
description: .docs/testiing/tmpの分析メモを根拠に、Unit/Integration/E2Eテストを生成または更新する
tools: [read, search, edit, agent, execute, todo]
---

# Implement Tests From Context Prompt

.docs/testiing/tmp の分析結果を入力として、テストコードを段階的に生成・更新する。

## 実施内容

1. .docs/testiing/tmp/*.tmp.md を読み、優先度 高 の項目を抽出
2. Unit → Integration → E2E の順で更新する
3. 変更後にテスト実行し、失敗を修正
4. .docs/testiing/tmp/*.tmp.md に実装結果を追記

## 更新ルール

- 1回の更新は1領域（最大3テストケース）
- 特定テストケース指定がある場合は、指定対象を最優先で更新
- 変更理由をテスト名で明確化
- 既存ケースと重複する場合は統合を優先
- リファクタリングより、まず不足ケース充足を優先

## 実行例

/implement-tests-from-context

対象: .docs/testiing/tmp/unit-analysis.tmp.md の優先度 高
方針: ValidationHelper, SecurityHelper の境界値ケースを追加
完了条件: 追加ケースが実行成功し、tmpへ反映されること
