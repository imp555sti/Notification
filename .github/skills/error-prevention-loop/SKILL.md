---
name: error-prevention-loop
description: "Use when: PostToolUseエラーを起点に、更新候補の提示・ユーザー選択・採用分のみ反映を行いたい時"
---

# Error Prevention Loop Skill

PostToolUseのエラー履歴を使い、再発防止のための customizations 更新を段階的に実施するスキル。

## 対象

- `.github/instructions/*.instructions.md`
- `.github/skills/*/SKILL.md`
- `.github/agents/*.agent.md`
- `.github/prompts/*.prompt.md`
- `.docs/hooks/tool-error-history.jsonl`

## 実行フロー

1. 最新エラー確認
- `.docs/hooks/tool-error-history.jsonl` から最新を読む
- 同種エラーが続いているか確認する

2. 候補抽出（最大3件）
- Instructions/Skills/Agents/Prompts のどこを変えるべきか判定
- 候補ごとに4点を整理
  - 起きた事象
  - アップデート内容
  - 理由
  - 期待される効果

3. ユーザー確認
- `vscode_askQuestions` で候補別に選択式確認
- 選択肢は `採用 / 見送り / 保留`
- 自由入力コメントを必須で受け付ける

4. 反映
- `採用` の候補のみ更新
- 反映後に変更点と期待効果を要約

## 品質ルール

- 根拠ログなしの変更を行わない
- 既存記述と矛盾する場合は小さく修正
- 不要な重複ファイルを作らない
