---
description: "Use when: PreToolUseでコミット/PR/push前にLinterとコードレビュー結果を提示し、要改善なら操作中断して改善する時"
applyTo: ".github/hooks/**,.github/instructions/**,.github/agents/**,.github/prompts/**,.github/skills/**,.docs/hooks/**"
---

# PreToolUse コミット/PR 品質ゲート

## 目的

コミットやPR、push実行前に Linter とコードレビューを行い、ユーザー確認後に進行可否を決める。

## 必須フロー

1. PreToolUse で commit/PR/push 系コマンドを検知する
2. Linter を実行し、結果を取得する
3. コードレビュー所見をまとめる
4. レポート書式でユーザーへ提示する
5. ユーザーへ選択式確認を行う
- 要改善（中断して改善）
- 今回は進める
6. 追加コメントを必ず受け付ける
7. 要改善が選ばれた場合は操作を中断し、改善を実施する

## レポート書式

- コード品質メトリクス
- 総合評価
- レビュー結果
- マージ可否
- 必須修正項目
- 推奨修正項目
- ユーザー確認（選択式 + 追加コメント）

## 禁止事項

- レポート提示なしで commit/PR/push を続行しない
- 要改善選択後に操作を継続しない
- 根拠のない指摘を必須修正にしない
