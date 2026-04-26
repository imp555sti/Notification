# Hooks Error Triage 運用メモ

## 目的

PostToolUseで検知したツールエラーを記録し、再発防止の改善サイクルに接続する。

## 生成ファイル

- `tool-error-history.jsonl`: ツールエラーの時系列ログ

## 運用

1. エラー発生時にHooksスクリプトがログを追記
2. `/review-error-prevention` で候補抽出
3. ユーザー確認（採用/見送り/保留 + コメント）
4. 採用分のみ customization を更新

## 備考

ログには機密情報を含めない。
