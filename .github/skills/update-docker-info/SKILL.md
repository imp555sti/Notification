---
name: update-docker-info
description: "Use when: Dockerサービス名の変動に合わせて、Hooks用のdocker-info.jsonを更新したい時"
---

# Update Docker Info Skill

Docker構成を根拠に、Hooks実行用のPHPサービス名情報を更新するスキル。

## 対象

- `docker-compose.yml`
- `.docs/hooks/docker-info.json`
- `.github/hooks/scripts/pre-tooluse-quality-gate.ps1`

## 手順

1. Docker構成を確認
- `docker-compose.yml` の services を確認
- 必要に応じて `docker compose config --services` を確認

2. PHPサービスを決定
- `apache-php` を優先
- なければ `php`, `*-php`, `web`, `app` の順で選定
- 単一サービスのみならそのサービスを選定

3. 設定ファイルを更新
- `.docs/hooks/docker-info.json` の `phpService` を更新
- 更新日時と根拠を記録

4. 反映確認
- `pre-tooluse-quality-gate.ps1` で参照されることを確認

## ルール

- ハードコード運用へ戻さない
- 根拠（compose構成 or 実コマンド結果）を示す
- 不明時は推測で更新せず、候補を提示して確認する
