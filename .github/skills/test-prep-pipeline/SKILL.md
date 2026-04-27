---
name: test-prep-pipeline
description: "Use when: src配下を分析してUnit/Integration/E2E向けの調査メモを.docsへ分割し、テスト生成・更新までAI主導で進めたい時"
---

# Test Prep Pipeline Skill

src配下の実装分析から、テスト準備ドキュメント作成、テストコード生成・更新までを段階的に進めるワークフロー。

## 使うタイミング

- 新機能追加前に、テスト観点を先に整理したい
- 既存コードのテスト不足を層別（Unit/Integration/E2E）で可視化したい
- コンテキストウィンドウを意識して調査結果を分割保存したい

## 事前確認

1. .github/instructions/testing.instructions.md
2. .github/instructions/architecture.instructions.md
3. .github/instructions/security.instructions.md
4. .github/instructions/test-preparation.instructions.md

## PHP7.4/RHEL8互換の固定ルール（再発防止）

### 1. PHPUnitバージョン方針

- 本プロジェクトのPHPUnitは `9.5.28` を固定値として扱う
- 互換対象は `PHP 7.4` のため、PHPUnit 10以上へ自動更新しない
- バージョン表記は曖昧にせず、`composer.json` と `src/composer.json` の両方で同一バージョンを維持する

### 2. 依存関係固定の運用

- `phpunit/phpunit` は `require-dev` で厳密固定（例: `9.5.28`）とし、キャレット指定（`^`）を使わない
- テスト基盤を更新した場合は、`composer.lock` も必ず同時更新して差分をコミットする
- 依存更新はコンテナ内で実施し、ホスト環境のPHP/Composer差異を持ち込まない
- 更新後は Unit/Integration の最低実行確認を行い、互換性崩れを早期検知する

### 3. テスト記述ルール（PHP 7.4互換）

- テストコードは PHPUnit 9系の書式を使う（DocBlockアノテーション中心）
- `#[Test]` などのPHP8属性ベース記法は使用しない
- Data Providerは `@dataProvider` を使用する
- PHP8専用構文（union型、match式、constructor property promotionなど）をテストコードへ導入しない
- アサーションは `assertSame` を第一候補とし、型のあいまい比較を避ける

### 4. テスト実行コマンドの統一

- 実行はコンテナ内のPHPUnitバイナリを使用する
- 基本コマンド例:
	- `docker compose run --rm composer`
	- `docker compose run --rm composer "php /opt/app-root/src/vendor/bin/phpunit -c /opt/app-root/phpunit.xml --testsuite Unit"`
	- `docker compose run --rm composer "php /opt/app-root/src/vendor/bin/phpunit -c /opt/app-root/phpunit.xml --testsuite Integration"`
- ホスト側の `phpunit` 直接実行は、バージョン差異混入を招くため原則禁止

### 5. 変更時チェックリスト

- `composer.json` と `src/composer.json` の `require-dev.phpunit/phpunit` が一致している
- `composer.lock` が更新内容と整合している
- 追加したテストがPHP 7.4構文で解釈可能
- Unit/Integration のいずれか最低1スイートがグリーンである

### 6. 直近障害に対する統制ルール

- 生成するテストの namespace で PHP予約語（例: `Public`）を使わない
- `@testdox` は必ず対象メソッド直前に配置し、ずれた DocBlock を残さない
- Integration 実行前に `tests/Integration` の存在を確認する
- 実行前に `src/vendor/bin/phpunit` の存在確認を行う
- `composer install` は完了ログ（`Generating optimized autoload files`）確認までを必須とする
- install 中断が発生した場合は再実行して完了状態に戻してからテスト実行する

## 実行フロー

1. Inventory作成
- src/app と tests の対応関係を source-inventory.tmp.md に記録

2. 層別分析
- Unit: 純粋ロジックの未検証分岐を抽出
- Integration: DB/トランザクション/連携経路の不足を抽出
- E2E: ユーザーフローと主要導線の不足を抽出

3. 一時ファイル更新
- .docs/testiing/tmp/unit-analysis.tmp.md
- .docs/testiing/tmp/integration-analysis.tmp.md
- .docs/testiing/tmp/e2e-analysis.tmp.md

4. 実装フェーズへ移行
- 優先度 高 からテストを生成・更新
- 変更したら .tmp に反映（完了/残課題）

## 出力要件

- 調査結果は必ず .docs/testiing/tmp/*.tmp.md に保存する
- 各観点に「対象」「不足テスト」「追加候補ケース」「優先度」を含める
- 実装に進める粒度で、テスト名またはケース名を明記する
- E2Eには logout と 404 のシナリオを必須で含める

## 参照テンプレート

- templates/source-inventory-template.md
- templates/unit-analysis-template.md
- templates/integration-analysis-template.md
- templates/e2e-analysis-template.md
