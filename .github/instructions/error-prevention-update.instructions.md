---
description: "Use when: ツールエラーの再発防止として、Instructions/Skills/Agents/Prompts の更新候補を抽出し、ユーザー確認後に反映する時"
applyTo: ".github/hooks/**,.github/instructions/**,.github/skills/**,.github/agents/**,.github/prompts/**,.docs/hooks/**"
---

# ツールエラー再発防止 更新ルール

## 目的

PostToolUse で検知したエラーを根拠に、Instructions / Skills / Agents / Prompts の改善を実施し、同種の失敗再発を防ぐ。

## 必須フロー

1. `.docs/hooks/tool-error-history.jsonl` の最新イベントを確認する
2. 更新候補を抽出する（最大3件）
3. 候補ごとに以下4点を明示する
- 起きた事象
- アップデート内容
- 理由
- 期待される効果
4. ユーザー確認を選択式で実施する
- 採用
- 見送り
- 保留
5. 追加コメント入力欄を必ず用意する
6. ユーザーが採用した項目のみ更新する

## 更新対象の判断基準

- Instructions: 常時効くガイドライン不足の場合
- Skills: 手順化された再発防止ワークフロー不足の場合
- Agents: 専門ロールでの分析・更新分離が必要な場合
- Prompts: 単発で再利用したい確認手順が不足している場合

## 禁止事項

- ユーザー確認なしで customization ファイルを更新しない
- エラー根拠が不明なまま抽象的なルールを増やさない
- 1回で広範囲を更新しない（小さく分ける）

## 推奨問い合わせ文面

- 起きた事象: （簡潔な再現状況）
- アップデート内容: （変更対象と変更要点）
- 理由: （根拠ログと失敗原因）
- 期待される効果: （再発防止と作業効率）
- 採用可否: 採用 / 見送り / 保留
- 追加コメント: 任意入力
