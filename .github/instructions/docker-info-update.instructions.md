---
description: "Use when: Docker構成変更に追従してHooksのPHPサービス参照情報を更新する時"
applyTo: "docker-compose.yml,.docs/hooks/docker-info.json,.github/hooks/scripts/pre-tooluse-quality-gate.ps1,.github/prompts/update-docker-info.prompt.md,.github/skills/update-docker-info/**,.github/agents/docker-info-updater.agent.md"
---

# Docker情報更新ルール

## 目的

Dockerサービス名の変更で Hooks 実行が失敗しないよう、参照情報を最新化する。

## 必須手順

1. `docker-compose.yml` の services を確認する
2. 可能なら `docker compose config --services` で実構成を確認する
3. PHPサービス名を `.docs/hooks/docker-info.json` の `phpService` に反映する
4. 更新理由を簡潔に報告する

## 選定ルール

- 優先: `apache-php`
- 次点: `php`, `*-php`, `web`, `app`
- 単一サービスのみの場合はその値を採用

## 禁止事項

- `pre-tooluse-quality-gate.ps1` に固定サービス名を直書きしない
- 根拠なしでサービス名を更新しない
