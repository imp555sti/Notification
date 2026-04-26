---
name: security-review
description: OWASP Top 10準拠のセキュリティレビュー。XSS/CSRF/SQLi等の脆弱性を検出
tools: [vscode/askQuestions, read, agent,  search, web, todo]
---

# Security Review Prompt

コード変更のセキュリティレビューを実施する再利用可能なプロンプトです。

**Version**: 1.0.0  
**Author**: Development Team  
**Created**: 2026-02-14  
**Reference**: OWASP Top 10, `.github/instructions/security.instructions.md`

---

## Prompt

```
以下のコード変更についてセキュリティレビューを実施してください。

## 変更内容

[ここに変更ファイルリストまたはコードを記載]

---

## セキュリティチェック項目

以下のOWASP Top 10に基づくチェックリストを確認してください：

### 1. インジェクション攻撃対策

#### SQLインジェクション
- [ ] Prepared Statement を使用しているか
- [ ] 文字列連結でSQLクエリを構築していないか
- [ ] PDO::ATTR_EMULATE_PREPARES が false に設定されているか
- [ ] ユーザー入力を直接クエリに含めていないか

**チェック方法**:
```php
// ❌ Bad
$query = "SELECT * FROM users WHERE email = '$email'";

// ✅ Good
$stmt = $pdo->prepare('SELECT * FROM users WHERE email = :email');
$stmt->execute(['email' => $email]);
```

#### XSS（クロスサイトスクリプティング）
- [ ] 出力時に `SecurityHelper::escape()` を使用しているか
- [ ] HTML内でユーザー入力を直接出力していないか
- [ ] JavaScriptコード内でユーザー入力を使用していないか
- [ ] URLパラメータを直接出力していないか

**チェック方法**:
```php
// ❌ Bad
echo "<div>$username</div>";

// ✅ Good
echo "<div>" . SecurityHelper::escape($username) . "</div>";
```

---

### 2. 認証・認可の不備

#### パスワード管理
- [ ] `SecurityHelper::hashPassword()` でハッシュ化しているか
- [ ] bcrypt（Blowfish）を使用しているか
- [ ] パスワードを平文で保存・ログ出力していないか
- [ ] MD5/SHA1を使用していないか

#### セッション管理
- [ ] ログイン成功時に `session_regenerate_id(true)` を呼び出しているか
- [ ] セッション設定が安全か（secure, httponly, samesite）
- [ ] セッションタイムアウトが適切か
- [ ] ログアウト時にセッションを破棄しているか

**チェック方法**:
```php
// セッション設定確認
session_set_cookie_params([
    'secure' => true,      // ✅ HTTPS必須
    'httponly' => true,    // ✅ JavaScript無効化
    'samesite' => 'Strict' // ✅ CSRF対策
]);
```

---

### 3. 機密データの露出

#### 環境変数・認証情報
- [ ] パスワード・APIキーをハードコードしていないか
- [ ] .env ファイルを使用しているか
- [ ] .env が .gitignore に含まれているか
- [ ] ログに機密情報を出力していないか

#### エラーメッセージ
- [ ] 本番環境でスタックトレースを表示していないか
- [ ] エラーメッセージから内部構造が推測できないか
- [ ] データベースエラーをそのまま表示していないか

---

### 4. CSRF（クロスサイトリクエストフォージェリ）対策

#### トークン検証
- [ ] POST/PUT/DELETEリクエストでCSRFトークンを検証しているか
- [ ] `SecurityHelper::verifyCsrfToken()` を使用しているか
- [ ] Controller で `requireCsrfToken()` を呼び出しているか
- [ ] GETリクエストで状態変更していないか

**チェック方法**:
```php
// ✅ Controller
public function create(): void
{
    $this->requireCsrfToken(); // CSRF検証
    
    $data = $this->getPost();
    // ...
}
```

---

### 5. アクセス制御の不備

#### 認証・認可チェック
- [ ] 保護されたリソースへのアクセス前に認証確認しているか
- [ ] ユーザーの権限を確認しているか
- [ ] 他ユーザーのデータに不正アクセスできないか
- [ ] IDベースのアクセス制御が適切か（IDOR対策）

**チェック方法**:
```php
// ✅ 認証チェック
if (!$this->authService->isAuthenticated()) {
    $this->redirect('/login');
    return;
}

// ✅ 権限チェック
$userId = $_SESSION['user_id'];
if ($resource->getUserId() !== $userId) {
    $this->errorResponse('Forbidden', 403);
    return;
}
```

---

### 6. 入力バリデーション

#### バリデーション実装
- [ ] すべてのユーザー入力をバリデーションしているか
- [ ] `ValidationHelper` を使用しているか
- [ ] ホワイトリスト方式を採用しているか
- [ ] ファイルアップロード時に拡張子・MIMEタイプを検証しているか

**チェック方法**:
```php
// ✅ バリデーション
$errors = [];

if (!ValidationHelper::required($email)) {
    $errors['email'][] = 'メールアドレスは必須です';
}

if (!ValidationHelper::email($email)) {
    $errors['email'][] = 'メールアドレスの形式が不正です';
}
```

---

### 7. ファイルアップロードセキュリティ

- [ ] 許可する拡張子をホワイトリストで制限しているか
- [ ] ファイルサイズを制限しているか
- [ ] アップロードファイルを公開ディレクトリ外に保存しているか
- [ ] ファイル名をサニタイズしているか
- [ ] MIMEタイプを検証しているか

---

### 8. HTTPヘッダーセキュリティ

- [ ] `X-Frame-Options` ヘッダーを設定しているか
- [ ] `X-Content-Type-Options` ヘッダーを設定しているか
- [ ] `Strict-Transport-Security` ヘッダーを設定しているか（HTTPS時）
- [ ] CSP（Content-Security-Policy）を検討しているか

---

## 出力形式

以下の形式でレビュー結果を報告してください：

```markdown
# セキュリティレビューレポート

## サマリー

- ✅ 問題なし: X件
- ⚠️ 要確認: Y件
- ❌ 脆弱性: Z件

**総合評価**: 安全 / 要改善 / 危険

---

## 詳細レポート

### ✅ 適切に実装されている項目

1. **SQLインジェクション対策**
   - ファイル: src/app/Repository/UserRepository.php
   - 行: 45-50
   - 内容: Prepared Statement を正しく使用

2. **CSRF対策**
   - ファイル: src/app/Controller/UserController.php
   - 行: 30
   - 内容: requireCsrfToken() を適切に呼び出し

---

### ⚠️ 要確認項目

1. **エラーハンドリング**
   - ファイル: src/app/Service/UserService.php
   - 行: 78
   - 内容: catch ブロックで例外メッセージをログ出力
   - 懸念: 機密情報が含まれていないか確認が必要
   - 推奨: 機密情報を除外したログ出力

2. **セッションタイムアウト**
   - ファイル: src/app/bootstrap.php
   - 行: 25
   - 内容: セッション有効期限が3600秒（1時間）
   - 懸念: 用途によっては長すぎる可能性
   - 推奨: セキュリティ要件に応じて調整を検討

---

### ❌ 脆弱性（修正必須）

1. **XSS脆弱性**
   - ファイル: src/app/Controller/ProductController.php
   - 行: 102
   - 重大度: 高
   - 現在のコード:
     ```php
     echo "<h1>$productName</h1>";
     ```
   - 問題: ユーザー入力を直接HTML出力
   - 修正:
     ```php
     echo "<h1>" . SecurityHelper::escape($productName) . "</h1>";
     ```
   - 影響: XSS攻撃によるセッション乗っ取りの可能性

2. **SQLインジェクション脆弱性**
   - ファイル: src/app/Repository/ProductRepository.php
   - 行: 55
   - 重大度: 高
   - 現在のコード:
     ```php
     $query = "SELECT * FROM products WHERE category = '$category'";
     $stmt = $pdo->query($query);
     ```
   - 問題: 文字列連結でSQLクエリを構築
   - 修正:
     ```php
     $stmt = $pdo->prepare('SELECT * FROM products WHERE category = :category');
     $stmt->execute(['category' => $category]);
     ```
   - 影響: データベース不正アクセス・データ漏洩の可能性

---

## 推奨アクション（優先度順）

### 優先度: 緊急（即座に修正）

1. **ProductController.php のXSS脆弱性修正**
   - SecurityHelper::escape() を使用

2. **ProductRepository.php のSQLインジェクション脆弱性修正**
   - Prepared Statement に変更

### 優先度: 高（コミット前に修正）

3. **エラーログの機密情報除外**
4. **セッションタイムアウトの見直し**

### 優先度: 中（次回スプリントで対応）

5. **CSPヘッダーの追加検討**

---

## セキュリティチェックリスト

- [x] SQLインジェクション対策
- [x] XSS対策
- [x] CSRF対策
- [x] パスワードハッシュ化
- [x] セッション管理
- [ ] ファイルアップロードセキュリティ（該当なし）
- [x] 入力バリデーション
- [ ] HTTPヘッダーセキュリティ（要改善）

---

## 参考資料

- `.github/instructions/security.instructions.md`
- `.docs/plans/security/best-practices.md`
- OWASP Top 10: https://owasp.org/www-project-top-ten/

---

## 次回レビュー時の確認事項

1. 今回指摘した脆弱性が修正されているか
2. 新しいコードで同様の問題が発生していないか
3. セキュリティテストが追加されているか
```

---

## 使用例

### ケース1: 新機能のセキュリティレビュー

```
@workspace 

.github/prompts/security-review.prompt.md を使用して、
以下のファイルのセキュリティレビューを実施してください：

対象ファイル:
- src/app/Service/ProductService.php
- src/app/Repository/ProductRepository.php
- src/app/Controller/ProductController.php
```

### ケース2: 特定のコードのレビュー

```
@workspace 

.github/prompts/security-review.prompt.md を使用して、
以下のコードのセキュリティレビューを実施してください：

コード:
[貼り付け]
```

### ケース3: コミット前の最終確認

```
@workspace 

.github/prompts/security-review.prompt.md を使用して、
git diff の内容をレビューしてください。

特に以下の観点で確認:
- SQLインジェクション
- XSS
- CSRF
```

---

## チェックリスト（プロンプト実行前）

- [ ] レビュー対象のファイル・コードを特定済み
- [ ] 変更内容を理解している
- [ ] セキュリティ要件を把握している
- [ ] `.github/instructions/security.instructions.md` を確認済み

---

## 関連リソース

- **セキュリティベストプラクティス**: `.docs/plans/security/best-practices.md`
- **セキュリティ実装ガイド**: `.github/instructions/security.instructions.md`
- **開発ワークフロー**: `.github/DEVELOPMENT_WORKFLOW.md`

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-14
