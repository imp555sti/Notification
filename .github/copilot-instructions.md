# PHP開発環境テンプレート - GitHub Copilot Instructions

このプロジェクトは**RHEL8 + Apache2.4 + PHP7.4 + PostgreSQL12.12**を使用した、MVC + Service + Repository + Entityアーキテクチャの PHP開発環境テンプレートです。

## 📚 プロジェクト概要

- **技術スタック**: RHEL8, Apache2.4, PHP7.4, PostgreSQL12.12
- **アーキテクチャ**: MVC + Service + Repository + Entity
- **テストフレームワーク**: PHPUnit 9.x（カバレッジ目標75%以上）
- **セキュリティ**: CSRF/XSS/SQLインジェクション対策実装済み
- **言語**: 全ドキュメント・コメント日本語

## 🎯 基本方針

- ✅ **全コメント・ドキュメントは日本語**で記述
- ✅ **PSR-12準拠**のコーディング規約
- ✅ **型宣言必須**（引数・戻り値）
- ✅ **テストカバレッジ75%以上**を維持
- ✅ **セキュリティチェック必須**（すべての実装で）
- ✅ **レイヤー責務の厳守**（依存方向の遵守）

## 📖 状況別 Instructions参照ガイド

### 🔧 実装時の参照先

#### PHP実装全般
**参照**: `.github/instructions/php.instructions.md`

以下の場合に参照：
- PHP コードを新規作成・編集するとき
- コーディング規約を確認したいとき
- エラーハンドリングの実装方法
- 型宣言・命名規則の確認
- PHP7.4互換性の確認

**含まれる内容**:
- PSR-12 コーディング規約詳細
- 型宣言ルール
- エラーハンドリングパターン
- 命名規則
- 禁止事項

---

#### セキュリティ対策
**参照**: `.github/instructions/security.instructions.md`

以下の場合に参照：
- ユーザー入力を扱う実装
- フォーム・API実装
- 認証・認可機能の実装
- ファイルアップロード機能
- セキュリティレビュー時

**含まれる内容**:
- XSS対策（出力エスケープ）
- CSRF対策（トークン検証）
- SQLインジェクション対策
- セッション管理
- パスワード管理
- ファイルアップロードセキュリティ

---

#### アーキテクチャ設計
**参照**: `.github/instructions/architecture.instructions.md`

以下の場合に参照：
- 新しいEntity/Repository/Service/Controllerを作成するとき
- レイヤー間の依存関係を確認したいとき
- クラス設計の方針を確認したいとき
- DI（依存注入）の実装方法

**含まれる内容**:
- 各レイヤーの責務定義
- 依存方向のルール
- Entity/Repository/Service/Controllerの実装パターン
- DIの実装方法
- 命名規則

---

#### データベース操作
**参照**: `.github/instructions/database.instructions.md`

以下の場合に参照：
- Repositoryクラスを実装するとき
- データベースクエリを書くとき
- トランザクション処理を実装するとき
- Entityマッピングを行うとき

**含まれる内容**:
- Repository実装パターン
- Prepared Statement使用方法
- トランザクション管理
- Entityマッピング
- N+1問題対策
- エラーハンドリング

---

#### テスト実装
**参照**: `.github/instructions/testing.instructions.md`

以下の場合に参照：
- PHPUnitテストを書くとき
- カバレッジを向上させたいとき
- モックを使用したいとき
- テスト戦略を確認したいとき

**含まれる内容**:
- PHPUnitバージョン9.x設定
- テストディレクトリ構造
- モック作成方法
- カバレッジ75%達成戦略
- テストパターン集
- アサーション選択ガイド

---

### 🛠️ 環境・運用の参照先

#### 環境構築
**参照**: `.github/instructions/setup.instructions.md`

以下の場合に参照：
- 初回環境セットアップ
- Docker環境の構築・トラブルシューティング
- Composerパッケージ管理
- データベース初期化

---

#### デプロイ
**参照**: `.github/instructions/deployment.instructions.md`

以下の場合に参照：
- 本番環境へのデプロイ手順
- ホスティング環境での注意事項
- vendor/フォルダのデプロイ方法

---

## 🤖 GitHub Copilot Chat 使用例

### 新規Controller作成時
```
新しいProductControllerを作成してください。
.github/instructions/architecture.instructions.md と
.github/instructions/php.instructions.md を参照して、
適切な実装をお願いします。
```

### セキュリティレビュー時
```
このコードのセキュリティレビューをしてください。
.github/instructions/security.instructions.md の
チェックリストに基づいて確認をお願いします。
```

### テストコード生成時
```
@workspace /generate-tests

UserServiceのテストコードを生成してください。

テスト対象クラス: src/app/Service/UserService.php

要件:
1. カバレッジ75%以上
2. PHPUnit 9.xの最新パターン
3. モックを使用した依存性の分離
4. 正常系・異常系・エッジケースをカバー
```

---

## 🚨 重要な制約事項

### ホスティング環境制約
- **ドキュメントルート**: `src/` のみ公開
- **vendor/**: Git管理対象（デプロイ時に含める）
- **PHP7.4厳守**: ホスティング環境の制約（将来的にPHP8.x移行予定）

### セキュリティ要件
すべての実装で以下を必須確認：
- [ ] XSS対策（`SecurityHelper::escape()` 使用）
- [ ] CSRF対策（POST/PUT/DELETEでトークン検証）
- [ ] SQLインジェクション対策（Prepared Statement使用）
- [ ] 入力バリデーション（`ValidationHelper` 使用）

### テスト要件
- カバレッジ**75%以上**を維持
- 新機能追加時は必ずテストも追加
- CIでの自動テスト実行

---

## 📁 ディレクトリ構造（簡易版）

```
workspace/
├── .github/
│   ├── copilot-instructions.md     # 👈 このファイル
│   ├── instructions/               # 👈 分野別詳細ガイド
│   │   ├── php.instructions.md
│   │   ├── security.instructions.md
│   │   ├── architecture.instructions.md
│   │   ├── database.instructions.md
│   │   ├── testing.instructions.md
│   │   ├── setup.instructions.md
│   │   └── deployment.instructions.md
│   ├── agents/                     # AIエージェント定義
│   ├── prompts/                    # 再利用可能プロンプト
│   └── ISSUE_TEMPLATE/             # Issue/PRテンプレート
├── src/                            # ドキュメントルート（公開）
│   ├── .env                        # 環境変数（.htaccessで保護）
│   ├── .htaccess                   # アクセス制御
│   ├── composer.json               # Composer設定（.htaccessで保護）
│   ├── composer.lock               # 依存関係（.htaccessで保護）
│   ├── vendor/                     # Composerパッケージ（.htaccessで保護）
│   ├── app/                        # アプリケーションコード
│   │   ├── Config/                 # 設定クラス（App, Database）
│   │   ├── Controller/             # コントローラー層
│   │   ├── Service/                # サービス層
│   │   ├── Repository/             # リポジトリ層
│   │   ├── Entity/                 # エンティティ層
│   │   ├── Helper/                 # ヘルパー関数
│   │   └── bootstrap.php           # 初期化（直接アクセス不可）
│   ├── error/                      # エラーページ（公開）
│   ├── index.php                   # エントリーポイント
│   └── uploads/                    # アップロードファイル（予定）
├── tests/                          # テストコード（開発環境のみ）
├── .docs/                          # ドキュメント（開発環境のみ）
└── vendor/                         # 開発環境用（src/vendor へのリンク元）
```

**ホスティング環境の制約対応**:
- ✅ すべてのファイルを `src/` 配下に配置
- ✅ `.htaccess` で `.env`, `vendor/`, `composer.*`, `app/` を保護
- ✅ デプロイ時は `src/` の中身のみアップロード

---

## 🔗 関連リソース

- [README.md](../README.md) - プロジェクト概要・セットアップ手順
- [.docs/plans/architecture.md](../.docs/plans/architecture.md) - アーキテクチャ詳細
- [.docs/plans/security/best-practices.md](../.docs/plans/security/best-practices.md) - セキュリティガイド

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-11
