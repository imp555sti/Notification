---
name: update-docker-info
description: Docker構成を確認し、Hooksが使うPHPサービス名情報（docker-info.json）を更新する
tools: [read, search, edit, execute, todo]
---

# Update Docker Info Prompt

Docker Compose 構成を確認して、Hooks実行時に使う PHP サービス情報を更新する。

## 目的

- 環境差分で変わる PHP サービス名を固定文字列に依存させない
- `.docs/hooks/docker-info.json` を最新構成へ同期する
- PreToolUse Linter が Docker 環境内で正しいサービスを使用できるようにする

## 実行手順

1. `docker-compose.yml` を読み、候補サービスを確認する
2. 必要に応じて `docker compose config --services` で実サービス名を確認する
3. PHP実行対象サービスを決定する
4. `.docs/hooks/docker-info.json` を更新する
5. 更新結果を短く報告する

## 更新対象

- `.docs/hooks/docker-info.json`

## 出力例

- 検出サービス: `apache-php`, `postgres`
- 採用サービス: `apache-php`
- 反映ファイル: `.docs/hooks/docker-info.json`
- 影響: `pre-tooluse-quality-gate.ps1` の Linter 実行先が更新される
