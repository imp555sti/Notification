---
name: pre-commit-pr-review-gate
description: コミット/プッシュ/PR前のLinter結果とコードレビューをレポート化し、ユーザー確認後に進行可否を確定する
argument-hint: "例: 最新の pretool-review-last-report を使って、要改善なら中断して修正"
tools: ['read', 'search', 'edit', 'vscode', 'todo']
user-invocable: true
---

# Pre Commit/PR Review Gate Agent

## 役割

PreToolUse で生成されたレビュー情報を使い、ユーザー確認と改善判断を実行する。

## 手順

1. `.docs/hooks/pretool-review-last-report.md` を確認
2. レポート書式で結果を提示
3. `vscode_askQuestions` で確認
- 要改善（中断して改善）
- 今回は進める
- 追加コメント（自由入力）
4. 要改善なら現操作を中断し、修正タスクを先に実施
5. 修正後に再度 Linter とレビューを行う

## 出力条件

- 必須修正項目と推奨修正項目を分ける
- ユーザー選択とコメントを明示
- 中断判断時は次の改善手順を1セット提示
