---
name: review-error-prevention
description: PostToolUseで検知したツールエラーの再発防止候補を提示し、選択式確認と追加コメント収集後に採用分だけ更新する
tools: [read, search, edit, vscode, todo]
---

# Review Error Prevention Prompt

PostToolUseで記録されたエラー履歴を使って、再発防止の更新を安全に進めるためのプロンプトです。

## 実行手順

1. `.docs/hooks/tool-error-history.jsonl` の最新イベントを確認する
2. 再発防止候補を最大3件抽出する
3. 候補ごとに次を作る
- 起きた事象
- アップデート内容
- 理由
- 期待される効果
4. ユーザー確認を取る（選択式 + 追加コメント）
- 選択肢: 採用 / 見送り / 保留
- 追加コメント: 任意
5. 採用候補のみ、対象 customization を更新する

## 質問テンプレート（vscode_askQuestions）

- header: `candidate-1-decision`
- question: `候補1を採用しますか？`
- options:
  - `採用`
  - `見送り`
  - `保留`
- allowFreeformInput: true
- message: `追加コメントがあれば記入してください。`

同様に候補2、候補3を必要に応じて提示する。

## 制約

- 根拠がない候補は出さない
- ユーザー承認前に編集しない
- 1回の更新は最小差分に限定する
