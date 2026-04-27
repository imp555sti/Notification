---
name: generate-tests-workflow
description: "Use when: /generate-tests 実行時に、PHPUnit 9.x準拠でテスト生成・カバレッジ改善を段階実行したい時"
---

# Generate Tests Workflow Skill

`/generate-tests` の詳細手順を提供するワークフローSkillです。

## 目的

- PHPUnit 9.x 互換のテストを生成する
- `@testdox`（日本語説明）を付与する
- テストの可読性と再現性を担保する
- カバレッジ 75% 以上の改善サイクルを回す

## 管理境界（責務分担）

- 全体ルール（必須/禁止/互換制約）は `.github/instructions/testing.instructions.md` を正本とする
- 本Skillは `/generate-tests` の詳細実行手順のみを管理する
- 事前調査や `.docs/testiing/tmp` 起点の段階実装は `.github/skills/test-prep-pipeline/SKILL.md` を使用する

## 事前参照

1. `.github/instructions/testing.instructions.md`
2. `.github/instructions/php.instructions.md`
3. `.github/instructions/architecture.instructions.md`
4. `.github/instructions/security.instructions.md`

## 入力テンプレート

```text
対象: src/.../TargetClass.php
目的: 新規テスト作成 / 既存テスト拡張 / カバレッジ改善
制約: PHPUnit 9.x, @testdox必須（日本語）, メソッド名は英語
```

## 実行フロー

1. 対象クラスの公開メソッドを棚卸しする
2. 正常系・異常系・境界値の不足ケースを抽出する
3. 既存テストがあれば重複を避けて拡張する
4. 必要なモックを定義し、外部依存を分離する
5. `@testdox` を全ケースへ付与する
6. テスト実行し、失敗要因を修正する
7. カバレッジ確認し、75%未満なら不足ケースを追加する

## 失敗パターン再発防止ルール

1. 名前空間の予約語禁止
- `Public` などPHP予約語を namespace セグメントに使わない
- Integration は `Tests\\Integration\\Http\\...` のように予約語を避ける

2. `@testdox` の位置固定
- すべてのテストメソッドで、対応する `@testdox` を「メソッド直前」に置く
- 1つ下のメソッドへずれた DocBlock を残さない

3. Integration スイート作成前チェック
- `tests/Integration` が存在しない状態で Integration 実行しない
- 新規作成時は `tests/Integration/.../*Test.php` を最低1件追加してから実行する

4. PHPUnit バイナリの参照先固定
- 本リポジトリでは `src/vendor/bin/phpunit` を使用する
- 実行前に `src/vendor/bin/phpunit` と `src/vendor/autoload.php` の存在を確認する

5. 依存解決完了の確認
- `composer install` 実行後に `Generating optimized autoload files` まで出ることを確認する
- 依存解決中にコマンドを中断しない（中断時は install を再実行する）

## カバレッジ改善モード

ワークスペース全体を対象にする場合は次を反復する。

1. カバレッジ計測
2. 不足クラス特定
3. 優先度（Service/Repository/Helper）順に追加
4. 再実行して改善幅を確認

## 配置ルール

```text
tests/
├── Unit/
│   └── Lib/
├── Service/
├── Repository/
├── Entity/
├── Controller/
└── Helper/
```

## テスト作成ルール

- メソッド名は英語、`@testdox` は日本語で記述
- アサーションは `assertSame` を優先する
- 例外系は `expectException` を明示する
- Data Provider が有効な箇所は `@dataProvider` を使う
- PHP 7.4 非互換構文（属性、union型など）を使わない

## コマンド例

```bash
# 依存導入（ワンショット）
docker compose run --rm composer

# Unit 実行
docker compose run --rm composer "php /opt/app-root/src/vendor/bin/phpunit -c /opt/app-root/phpunit.xml --testsuite Unit"

# Integration 実行
docker compose run --rm composer "php /opt/app-root/src/vendor/bin/phpunit -c /opt/app-root/phpunit.xml --testsuite Integration"

# カバレッジ確認
docker compose run --rm composer "php /opt/app-root/src/vendor/bin/phpunit -c /opt/app-root/phpunit.xml --coverage-text"
```

## 出力要件

- 変更したテストファイル一覧
- 追加したテストケース一覧（testdox文言付き）
- 実行結果の要約（成功/失敗、主な原因）
- 次に追加すべき高優先テスト候補
