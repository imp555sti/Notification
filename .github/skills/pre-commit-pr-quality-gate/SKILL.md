---
name: pre-commit-pr-quality-gate
description: "Use when: コミット/PR/push前にLinterとコードレビューを実施し、要改善なら中断して修正したい時"
---

# Pre Commit/PR Quality Gate Skill

PreToolUseを起点に、コミット/PR/push 実行前の品質チェックとユーザー確認を標準化する。

## 対象

- `.github/hooks/hooks.json`
- `.github/hooks/scripts/pre-tooluse-quality-gate.ps1`
- `.docs/hooks/pretool-review-last-report.md`
- `.github/prompts/pre-commit-pr-review-gate.prompt.md`
- `.github/agents/pre-commit-pr-review-gate.agent.md`

## 手順

1. commit/PR/push 操作の検知
2. Linter実行
3. 差分ベースのコードレビュー
4. レポート書式で提示
5. ユーザー確認
- 要改善（中断して改善）
- 今回は進める
6. 要改善時は中断し、修正後に再実行

## レポート要素

- コード品質メトリクス
- 総合評価
- レビュー結果
- マージ可否
- 必須修正項目
- 推奨修正項目
- ユーザー確認

## 品質ルール

- High指摘またはLinter失敗は要改善候補
- 要改善が選択されたら commit/PR を止める
- 追加コメントを改善方針に反映する
