# リポジトリ共通化戦略

複数案件で共通のホスティング環境構成を前提とし、AI開発資産と案件実装を分離して管理するための戦略書です。

## 目次

1. [目的](#目的)
2. [推奨リポジトリ構成](#推奨リポジトリ構成)
3. [管理対象の分離方針](#管理対象の分離方針)
4. [同期ルール](#同期ルール)
5. [運用フロー](#運用フロー)
6. [現ワークスペースの切り出し対象](#現ワークスペースの切り出し対象)
7. [移行手順](#移行手順)
8. [採用しない方式と理由](#採用しない方式と理由)
9. [結論](#結論)

---

## 目的

- チーム共通のAI開発資産を一元管理する
- 案件固有の実装と共通ルールの責務を分離する
- 新規案件の立ち上げを高速化する
- 共通資産の改善を各案件へ安全に横展開する
- ホスティング環境前提の制約を崩さずに再利用性を高める

---

## 推奨リポジトリ構成

### 1. 共有DevKitリポジトリ

AI開発関連資産の正本を管理するリポジトリです。

役割:
- エージェント運用ルールの標準化
- Hooks / Instructions / Prompts / Skills の標準化
- チーム共通の開発ガイド整備
- 案件リポジトリへの同期元

管理対象:
- `.docs/`
- `.github/agents/`
- `.github/hooks/`
- `.github/instructions/`
- `.github/prompts/`
- `.github/skills/`
- `AGENT.md`
- `.github/copilot-instructions.md`

### 2. 案件テンプレートリポジトリ

ホスティング環境向けPHP案件の初期骨格を管理するテンプレートです。

役割:
- 新規案件作成時の雛形提供
- 共通アーキテクチャの初期配置
- Docker開発環境とテスト骨格の配布

管理対象:
- `src/`
- `tests/`
- `.docker/`
- `docker-compose.yml`
- `composer.json`
- `phpunit.xml`
- `playwright.config.ts`
- 案件初期READMEのひな形

### 3. 実案件リポジトリ

顧客案件ごとの実装を管理するリポジトリです。

役割:
- アプリケーション本体の継続開発
- 案件固有の環境変数・Docker差分管理
- 案件固有要件に応じたテスト運用
- 共有DevKitの同期受け入れ

構成原則:
- 初回作成は案件テンプレートから生成する
- AI開発資産は共有DevKitから同期する
- 案件差分は案件リポジトリ内に閉じ込める

### 推奨全体像

```text
team-devkit/
├── .docs/
├── .github/
│   ├── agents/
│   ├── hooks/
│   ├── instructions/
│   ├── prompts/
│   └── skills/
├── AGENT.md
└── .github/copilot-instructions.md

php-hosting-project-template/
├── .docker/
├── src/
├── tests/
├── docker-compose.yml
├── composer.json
├── phpunit.xml
└── README.md

project-foo/
├── .devkit/
│   └── manifest.json
├── .docs/
├── .github/
├── .docker/
├── src/
├── tests/
├── docker-compose.yml
└── README.md
```

---

## 管理対象の分離方針

### DevKitへ寄せるもの

変更がチーム横断で効くものを集約します。

| 対象 | 理由 |
|---|---|
| `.github/instructions/` | 実装判断ルールを統一するため |
| `.github/skills/` | 再利用ワークフローを共通化するため |
| `.github/agents/` | サブエージェント運用を統一するため |
| `.github/prompts/` | 定型タスクの入口を共有するため |
| `.github/hooks/` | 品質ゲート・自動補助を標準化するため |
| `.docs/` の共通運用文書 | 開発手順・レビュー観点を共通化するため |
| `AGENT.md` | 作業ルールの補助文書として共通化しやすいため |
| `.github/copilot-instructions.md` | 常時適用ルールの中心となるため |

### 案件リポジトリへ残すもの

案件固有の変更頻度が高いものを保持します。

| 対象 | 理由 |
|---|---|
| `src/` | 顧客要件ごとの実装差分が大きいため |
| `tests/` | 案件仕様に追従する必要があるため |
| `.docker/` | ローカル検証条件や周辺サービス差分が出るため |
| `docker-compose.yml` | サービス名やポートが案件差分になりやすいため |
| `composer.json` | 依存差分が出るため |
| `phpunit.xml` | テスト構成差分が出るため |
| `playwright.config.ts` | E2E条件差分が出るため |
| `README.md` | 案件固有のセットアップや運用注意点を含むため |
| `.env.example` 相当 | 接続先や変数名の差分が出やすいため |

### 例外的に二層管理するもの

以下は完全共通化ではなく、共通ベース + 案件追記の二層管理を推奨します。

| 対象 | 推奨方式 |
|---|---|
| `README.md` | 共通章はDevKit、案件章は案件リポジトリ |
| `.docs/` | 共通運用文書はDevKit、案件設計書は案件リポジトリ |
| `.github/hooks/docker-info.json` | ベースはDevKit、値は案件リポジトリで再生成 |

---

## 同期ルール

### 基本方針

- 共通資産は「コピー配布 + PR反映」で同期する
- 実案件リポジトリに共通資産を実ファイルとして配置する
- 共通資産の更新は直接手編集せず、DevKit側を正本にする
- 案件差分はオーバーライド領域へ逃がす

### 推奨同期単位

```text
DevKit -> Project
.github/agents/**         -> .github/agents/**
.github/hooks/**          -> .github/hooks/**
.github/instructions/**   -> .github/instructions/**
.github/prompts/**        -> .github/prompts/**
.github/skills/**         -> .github/skills/**
.docs/common/**           -> .docs/common/**
AGENT.md                  -> AGENT.md
.github/copilot-instructions.md -> .github/copilot-instructions.md
```

### 案件側で保持するメタ情報

案件リポジトリに以下のようなメタファイルを置きます。

```json
{
  "devkitRepository": "team-devkit",
  "devkitVersion": "1.4.0",
  "syncProfile": "php-hosting-standard",
  "overrides": [
    "README.md",
    ".docs/project/**",
    ".github/hooks/docker-info.json"
  ]
}
```

推奨パスは `.devkit/manifest.json` です。

### オーバーライド規約

- 共通ファイルを案件側で直接改変しない
- 改変が必要な場合は `overrides` に登録する
- 置換値で済むものはテンプレート変数を使う
- 案件固有説明は `.docs/project/` に集約する

### 同期方法

推奨順は以下です。

1. PowerShell または Node.js の同期スクリプトでコピーと差分生成を行う
2. GitHub Actions で定期または手動トリガーの同期PRを作る
3. 各案件はPRレビュー後に取り込む

### 同期の安全策

- 同期対象外パスを manifest で明示する
- 破壊的更新時は DevKit 側で major version を上げる
- 案件側CIで Hooks / Instructions / Markdownリンク整合性を確認する
- 同期PRには更新理由と影響範囲を自動添付する

---

## 運用フロー

### 新規案件立ち上げ

1. 案件テンプレートリポジトリから新規案件を生成する
2. `.devkit/manifest.json` を追加する
3. 共有DevKitの初回同期を実行する
4. `README.md` と `.docs/project/` に案件固有情報を追記する
5. Dockerサービス名差分があれば hooks 用設定を再生成する

### 共通資産更新

1. DevKitリポジトリで変更する
2. バージョンタグを付与する
3. 同期PRを各案件へ自動作成する
4. 案件側で差分と競合を確認する
5. テスト・Lint通過後に取り込む

### 案件固有差分更新

1. 実案件リポジトリで `src/` `tests/` `.docker/` を更新する
2. 共通資産へ戻すべき改善があればDevKitへ逆提案する
3. 案件限定差分は共通側へ戻さない

---

## 現ワークスペースの切り出し対象

このワークスペースを基準に、以下のように再編するのが妥当です。

### 共有DevKitへ移管する対象

| 現在のパス | 移管先 | 備考 |
|---|---|---|
| `.github/agents/` | `team-devkit/.github/agents/` | そのまま移管 |
| `.github/hooks/` | `team-devkit/.github/hooks/` | docker情報だけ案件再生成を想定 |
| `.github/instructions/` | `team-devkit/.github/instructions/` | そのまま移管 |
| `.github/prompts/` | `team-devkit/.github/prompts/` | そのまま移管 |
| `.github/skills/` | `team-devkit/.github/skills/` | そのまま移管 |
| `AGENT.md` | `team-devkit/AGENT.md` | 標準運用ガイドとして管理 |
| `.github/copilot-instructions.md` | `team-devkit/.github/copilot-instructions.md` | 常時ルールの正本 |
| `.docs/hooks/README.md` | `team-devkit/.docs/common/hooks/README.md` | 共通文書へ整理 |
| `.docs/plans/development/` | `team-devkit/.docs/common/development/` | 共通ガイドとして移管 |
| `.docs/plans/security/` | `team-devkit/.docs/common/security/` | 共通ガイドとして移管 |

### 案件リポジトリへ残す対象

| 現在のパス | 継続配置先 | 備考 |
|---|---|---|
| `src/` | 実案件リポジトリ | 顧客要件の本体 |
| `tests/` | 実案件リポジトリ | 案件仕様に追従 |
| `.docker/` | 実案件リポジトリ | 開発環境差分を許容 |
| `docker-compose.yml` | 実案件リポジトリ | サービス名差分あり |
| `composer.json` | 実案件リポジトリ | 依存差分が出る |
| `phpunit.xml` | 実案件リポジトリ | テスト構成差分が出る |
| `playwright.config.ts` | 実案件リポジトリ | E2E条件差分が出る |
| `test-results/` | 実案件リポジトリまたはGit管理外 | 生成物扱いを推奨 |

### 二層管理を推奨する対象

| 現在のパス | 方針 | 備考 |
|---|---|---|
| `README.md` | 共通章 + 案件章 | 完全共通化しない |
| `.docs/plans/architecture.md` | ベースはDevKit、案件版は `.docs/project/architecture.md` | 顧客仕様との差分を分離 |
| `.docs/hooks/docker-info.json` | 案件リポジトリで再生成 | composeサービス名差分に追従 |
| `.docs/hooks/pretool-review-last-report.md` | 案件ローカル生成物 | 共通管理しない |
| `.docs/hooks/tool-error-history.jsonl` | 案件ローカル履歴 | 共通管理しない |

---

## 移行手順

### フェーズ1: 共通資産の抽出

1. `team-devkit` リポジトリを作成する
2. `.github/` 配下と `AGENT.md` を移管する
3. `.docs/` を `common` と `project` に再編する
4. `README.md` の共通章を抽出してベース文書化する

### フェーズ2: 同期基盤の導入

1. `.devkit/manifest.json` の仕様を決める
2. `scripts/sync-devkit.ps1` などの同期スクリプトを作る
3. GitHub Actions で同期PR作成を自動化する
4. 案件側CIに整合性チェックを追加する

### フェーズ3: 既存案件への展開

1. 各案件へ manifest を追加する
2. 初回同期を実行する
3. 競合箇所を `overrides` へ退避する
4. README と `.docs/project/` の案件情報を補完する

---

## 採用しない方式と理由

### Template Repository 単独運用

初回作成は容易ですが、共通資産の継続更新を横展開できません。

### Git Submodule 中心運用

更新漏れ、初期化漏れ、参照先ずれが発生しやすく、チーム全体の運用コストが高くなります。

### Composer パッケージ化でAI資産を配布

PHPコード共有には有効ですが、Hooks / Instructions / Prompts / Skills のようなリポジトリ実体が重要な資産とは相性がよくありません。

---

## 結論

このチーム構成では、以下の3層戦略が最適です。

1. 共有DevKitリポジトリでAI開発資産を一元管理する
2. 案件テンプレートリポジトリでPHPホスティング案件の骨格を配布する
3. 実案件リポジトリで `src/` `tests/` `.docker/` `docker-compose.yml` を継続管理し、DevKitを同期する

この形であれば、共通部分の統制と案件固有差分の柔軟性を両立できます。

---

**Version**: 1.0.0
**Last Updated**: 2026-02-11
