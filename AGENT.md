# AGENT.md

このファイルは、本リポジトリで動作する GitHub Copilot 系エージェント向けの運用ガイドです。
既存の `.github/copilot-instructions.md` と分野別 instruction を補完し、実作業時の判断を統一します。

## 1. 目的

- 目的: 実装品質、セキュリティ、テスト品質を保ちながら、変更を最小かつ安全に進める
- 対象: `src/`・`tests/`・`.docs/` の更新、レビュー、テスト整備
- 前提: RHEL8 / Apache2.4 / PHP7.4 / PostgreSQL12.12 / PHPUnit 9.x

## 2. 優先順位（競合時）

1. システム・プラットフォームの制約
2. `.github/copilot-instructions.md`
3. `.github/instructions/*.instructions.md`
4. この `AGENT.md`
5. ユーザーの都度指示

競合がある場合は、上位ルールを優先します。

## 3. 基本ポリシー

- PSR-12 準拠
- 型宣言を必須化（引数・戻り値）
- 変更は最小単位で実施し、無関係な整形やリネームを避ける
- 既存アーキテクチャ（MVC + Service + Repository + Entity）の責務を崩さない
- コメント、ドキュメント、テスト説明は日本語を優先

## 4. セキュリティ必須チェック

実装・レビュー時は、以下を毎回確認します。

- XSS: 出力時に `SecurityHelper::escape()` を使用
- CSRF: POST/PUT/DELETE でトークン検証
- SQLi: Prepared Statement を必須化（文字列連結禁止）
- 入力検証: `ValidationHelper` を利用
- セッション/認証: セキュア設定を維持

## 5. レイヤー責務ルール

- Controller: HTTP 入出力、CSRF 検証、Service 呼び出し
- Service: ビジネスロジック、トランザクション制御、複数 Repository 調整
- Repository: DB アクセス、クエリ、Entity マッピング
- Entity: データ構造と軽量なドメイン振る舞い

禁止事項:

- Controller でビジネスロジックを持たない
- Service で直接 SQL を発行しない
- Repository で HTTP レスポンス生成を行わない

## 6. テスト運用ルール

- 変更時は関連テストを追加・更新する
- カバレッジ 75% 以上維持を目標とする
- 優先度: Helper/Entity -> Service/Repository -> Controller
- E2E 観点には `logout` と `404` を必須で含める

推奨コマンド:

```bash
docker exec phpunit-apache-1 composer test
```

## 7. テスト準備ワークフロー（必要時）

段階的にテスト準備を進める場合は以下を実施します。

1. `src/app` と `tests` の棚卸し
2. Unit/Integration/E2E の不足観点抽出
3. `.docs/testiing/tmp/*.tmp.md` へ分割保存
4. 優先度高からテスト実装
5. 反映結果を `.tmp.md` に追記

## 8. 変更時の実務ガイド

- 変更前に関連 instruction を確認する
- 既存の未コミット変更は勝手に巻き戻さない
- 影響範囲が広い場合は先に実施方針を短く共有する
- 変更後は可能な範囲でテスト・静的チェックを実行する
- 実行不可の場合は、未実施理由と推奨確認手順を明記する

## 9. 出力スタイル

- まず結論、その後に根拠と変更点
- ファイル参照はパスを明示
- レビュー依頼時は「重大度順の指摘」を先に列挙
- 実施できなかった検証は明確に宣言

## 10. デプロイ/構成上の注意

- 公開ルートは `src/` 配下のみ
- `vendor/` はデプロイ対象として扱う
- `src/.htaccess` による保護前提を崩さない
- PHP 7.4 互換性を維持する（新機能の利用に注意）

## 11. 参照先

- `.github/copilot-instructions.md`
- `.github/instructions/php.instructions.md`
- `.github/instructions/security.instructions.md`
- `.github/instructions/architecture.instructions.md`
- `.github/instructions/database.instructions.md`
- `.github/instructions/testing.instructions.md`
- `.github/instructions/test-preparation.instructions.md`

---

この `AGENT.md` は、プロジェクトの運用実態に合わせて継続更新します。