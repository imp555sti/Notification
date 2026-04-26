---
name: pre-commit-pr-review-gate
description: コミット/PR前のレビュー報告を提示し、要改善なら操作を中断して改善へ切り替える
tools: [read, search, edit, vscode, todo]
---

# Pre Commit/PR Review Gate Prompt

コミットまたはPR直前に、Linterとコードレビュー結果を確認して進行可否を決める。

## 実行フロー

1. `.docs/hooks/pretool-review-last-report.md` を読み取る
2. レポート書式に沿ってユーザーへ提示する
3. 次を質問する
- 判定: 要改善（中断して改善） / 今回は進める
- 追加コメント: 任意入力
4. 判定が要改善の場合
- 現在操作を中断
- 必須修正項目を優先して改善
- 改善後に再レビュー

## vscode_askQuestions テンプレート

- header: `pre-commit-pr-decision`
- question: `レビュー結果を踏まえて、要改善にしますか？`
- options:
  - `要改善（中断して改善）`
  - `今回は進める`
- allowFreeformInput: true
- message: `追加コメントがあれば入力してください。`
