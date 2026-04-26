# セキュリティ実装ガイド

プロジェクトでのセキュリティ対策実装の詳細ガイドです。すべての実装で必須確認してください。

## 📋 目次

1. [XSS対策](#xss対策)
2. [CSRF対策](#csrf対策)
3. [SQLインジェクション対策](#sqlインジェクション対策)
4. [セッション管理](#セッション管理)
5. [パスワード管理](#パスワード管理)
6. [入力検証](#入力検証)
7. [ファイルアップロード](#ファイルアップロード)
8. [HTTPヘッダー](#httpヘッダー)
9. [セキュリティチェックリスト](#セキュリティチェックリスト)

---

## XSS対策

### 基本原則

**すべての出力をエスケープする**

### SecurityHelper::escape() 必須使用

```php
use App\Helper\SecurityHelper;

// ✅ 正しい
echo SecurityHelper::escape($userInput);
echo SecurityHelper::escape($user->getName());

// ❌ 間違い（エスケープなし）
echo $userInput;  // XSS脆弱性
echo $user->getName();  // XSS脆弱性
```

### HTMLテンプレート内での使用

```php
<?php use App\Helper\SecurityHelper; ?>
<!DOCTYPE html>
<html>
<head>
    <title><?= SecurityHelper::escape($pageTitle) ?></title>
</head>
<body>
    <h1><?= SecurityHelper::escape($userName) ?></h1>
    <p><?= SecurityHelper::escape($userComment) ?></p>
    
    <!-- ❌ 間違い -->
    <p><?= $userComment ?></p>
</body>
</html>
```

### JavaScript内での出力

```php
<script>
// ✅ 正しい（JSON encodingも安全）
const userName = <?= json_encode($userName, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT) ?>;

// ❌ 間違い
const userName = "<?= $userName ?>";  // XSS脆弱性
</script>
```

### 例外：信頼できるHTMLの出力

```php
// ⚠️ 例外的にエスケープしない場合（管理者のみが編集できるコンテンツなど）
// 必ずHTMLPurifierなどでサニタイズ

use HTMLPurifier;

$purifier = new HTMLPurifier();
$cleanHtml = $purifier->purify($untrustedHtml);
echo $cleanHtml;  // サニタイズ済みなのでOK
```

---

## CSRF対策

### トークン生成と検証

#### フォームでのトークン埋め込み

```php
use App\Helper\SecurityHelper;

// トークン生成
$csrfToken = SecurityHelper::generateCsrfToken();
?>

<form method="POST" action="/user/create">
    <!-- ✅ hidden fieldでトークン送信 -->
    <input type="hidden" name="csrf_token" value="<?= SecurityHelper::escape($csrfToken) ?>">
    
    <input type="text" name="name" required>
    <input type="email" name="email" required>
    <button type="submit">登録</button>
</form>
```

#### Controller でのトークン検証

```php
namespace App\Controller;

use App\Controller\BaseController;

class UserController extends BaseController
{
    public function create(): void
    {
        // ✅ POST/PUT/DELETEは必ずCSRF検証
        if ($this->isPost()) {
            $this->requireCsrfToken();  // 検証失敗時は403エラー
            
            // 処理続行
            $name = $this->getPost('name');
            // ...
        }
    }
}
```

#### 手動検証

```php
use App\Helper\SecurityHelper;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $token = $_POST['csrf_token'] ?? null;
    
    // ✅ トークン検証
    if (!SecurityHelper::verifyCsrfToken($token)) {
        http_response_code(403);
        die('不正なリクエストです');
    }
    
    // 処理続行
}
```

#### AJAX リクエストでのCSRF対策

```javascript
// ページ読み込み時にトークンを取得
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

// AJAX リクエスト
fetch('/api/user', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify(data)
});
```

```php
<!-- HTML head内 -->
<meta name="csrf-token" content="<?= SecurityHelper::escape(SecurityHelper::generateCsrfToken()) ?>">
```

### GETリクエストでの重要操作禁止

```php
// ❌ 間違い（GETで削除処理）
public function delete(): void
{
    if ($this->isGet()) {
        $id = $this->getQuery('id');
        $this->userService->deleteUser($id);  // CSRF攻撃の危険
    }
}

// ✅ 正しい（POSTで削除 + CSRF検証）
public function delete(): void
{
    if ($this->isPost()) {
        $this->requireCsrfToken();  // CSRF検証必須
        $id = $this->getPost('id');
        $this->userService->deleteUser($id);
    }
}
```

---

## SQLインジェクション対策

### Prepared Statement 必須

**すべてのDBクエリでPrepared Statementを使用**

#### 正しい実装

```php
// ✅ 正しい（Prepared Statement）
public function findByEmail(string $email): ?User
{
    $stmt = $this->db->prepare("SELECT * FROM users WHERE email = :email");
    $stmt->execute(['email' => $email]);
    return $stmt->fetch();
}

// ✅ 正しい（複数パラメータ）
public function search(string $name, int $age): array
{
    $stmt = $this->db->prepare(
        "SELECT * FROM users WHERE name LIKE :name AND age >= :age"
    );
    $stmt->execute([
        'name' => '%' . $name . '%',
        'age' => $age
    ]);
    return $stmt->fetchAll();
}
```

#### 間違った実装（脆弱性あり）

```php
// ❌ 間違い（文字列連結 - SQLインジェクション脆弱性）
public function findByEmail(string $email): ?User
{
    $query = "SELECT * FROM users WHERE email = '" . $email . "'";
    return $this->db->query($query)->fetch();
}

// ❌ 間違い（変数展開）
$stmt = $this->db->query("SELECT * FROM users WHERE id = $id");
```

### 動的クエリ構築時の注意

```php
// ✅ 正しい（WHERE句を動的構築）
public function findBy(array $conditions): array
{
    $where = [];
    $params = [];
    
    foreach ($conditions as $column => $value) {
        // カラム名はホワイトリストで検証
        if (!in_array($column, ['name', 'email', 'status'], true)) {
            throw new InvalidArgumentException('Invalid column');
        }
        
        $where[] = "{$column} = :{$column}";
        $params[$column] = $value;
    }
    
    $sql = "SELECT * FROM users WHERE " . implode(' AND ', $where);
    $stmt = $this->db->prepare($sql);
    $stmt->execute($params);
    
    return $stmt->fetchAll();
}
```

### ORDER BY / LIMIT での注意

```php
// カラム名やORDER方向はホワイトリストで検証
public function getUsers(string $orderBy = 'id', string $direction = 'ASC'): array
{
    // ✅ ホワイトリスト検証
    $allowedColumns = ['id', 'name', 'email', 'created_at'];
    $allowedDirections = ['ASC', 'DESC'];
    
    if (!in_array($orderBy, $allowedColumns, true)) {
        $orderBy = 'id';
    }
    
    if (!in_array(strtoupper($direction), $allowedDirections, true)) {
        $direction = 'ASC';
    }
    
    // カラム名・方向は検証済みなので直接埋め込み可能
    $sql = "SELECT * FROM users ORDER BY {$orderBy} {$direction}";
    return $this->db->query($sql)->fetchAll();
}
```

---

## セッション管理

### セキュアなセッション設定

`src/src/app/bootstrap.php`で実装済み：

```php
session_set_cookie_params([
    'lifetime' => 1800,        // 30分
    'path' => '/',
    'domain' => '',
    'secure' => true,          // HTTPS環境でのみtrue
    'httponly' => true,        // ✅ JavaScript からアクセス不可
    'samesite' => 'Strict'     // ✅ CSRF対策
]);

session_start();
```

### セッション固定化攻撃対策

```php
// ✅ ログイン成功時にセッションIDを再生成
public function login(string $email, string $password): array
{
    $user = $this->userRepository->findByEmail($email);
    
    if ($user && SecurityHelper::verifyPassword($password, $user->getPasswordHash())) {
        // ✅ セッションID再生成（固定化攻撃対策）
        session_regenerate_id(true);
        
        $_SESSION['user_id'] = $user->getId();
        
        return ['success' => true];
    }
    
    return ['success' => false];
}
```

### セッションハイジャック対策

```php
// ユーザーエージェント・IPアドレスの確認（オプション）
if (!isset($_SESSION['user_agent'])) {
    $_SESSION['user_agent'] = $_SERVER['HTTP_USER_AGENT'] ?? '';
}

if ($_SESSION['user_agent'] !== ($_SERVER['HTTP_USER_AGENT'] ?? '')) {
    // セッションを破棄
    session_destroy();
    die('不正なアクセスです');
}
```

---

## パスワード管理

### ハッシュ化必須

```php
use App\Helper\SecurityHelper;

// ✅ パスワードハッシュ化
$passwordHash = SecurityHelper::hashPassword($password);

// DB保存
$user->setPasswordHash($passwordHash);
$this->repository->create($user);
```

### パスワード検証

```php
// ✅ パスワード検証
if (SecurityHelper::verifyPassword($inputPassword, $user->getPasswordHash())) {
    // 認証成功
}
```

### パスワード強度チェック

```php
use App\Helper\ValidationHelper;

// ✅ 強度チェック
if (!ValidationHelper::isStrongPassword($password, 8)) {
    return [
        'success' => false,
        'error' => 'パスワードは8文字以上で、英大文字、英小文字、数字を含む必要があります'
    ];
}
```

### 平文パスワードの禁止

```php
// ❌ 絶対禁止
$user->setPassword($password);  // 平文保存は絶対NG

// ❌ 禁止（弱いハッシュ）
$hash = md5($password);  // MD5は脆弱
$hash = sha1($password);  // SHA1も脆弱

// ✅ 正しい
$hash = SecurityHelper::hashPassword($password);  // bcrypt使用
```

---

## 入力検証

### ValidationHelper使用

```php
use App\Helper\ValidationHelper;

// ✅ 個別検証
if (!ValidationHelper::isEmail($email)) {
    return ['error' => '有効なメールアドレスを入力してください'];
}

if (!ValidationHelper::minLength($password, 8)) {
    return ['error' => 'パスワードは8文字以上必要です'];
}

// ✅ 一括検証
$errors = ValidationHelper::validate($data, [
    'name' => ['required', 'minLength:2', 'maxLength:100'],
    'email' => ['required', 'email'],
    'age' => ['required', 'min:18', 'max:120']
]);

if (!empty($errors)) {
    return ['success' => false, 'errors' => $errors];
}
```

### ホワイトリスト方式

```php
// ✅ 正しい（許可する値を明示）
$allowedRoles = ['admin', 'user', 'guest'];

if (!in_array($role, $allowedRoles, true)) {
    throw new InvalidArgumentException('不正なロールです');
}

// ❌ ブラックリスト方式（推奨しない）
$deniedRoles = ['superadmin'];
if (in_array($role, $deniedRoles, true)) {
    throw new InvalidArgumentException();
}
```

---

## ファイルアップロード

### アップロードファイルの検証

```php
use App\Helper\ValidationHelper;
use App\Helper\SecurityHelper;

public function uploadFile(array $file): array
{
    // ✅ ファイルアップロードエラーチェック
    if ($file['error'] !== UPLOAD_ERR_OK) {
        return ['success' => false, 'error' => 'アップロードエラー'];
    }
    
    // ✅ ファイルサイズチェック
    if ($file['size'] > UPLOAD_MAX_SIZE) {
        return ['success' => false, 'error' => 'ファイルサイズが大きすぎます'];
    }
    
    // ✅ 拡張子チェック
    if (!ValidationHelper::hasAllowedExtension($file['name'], UPLOAD_ALLOWED_EXTENSIONS)) {
        return ['success' => false, 'error' => '許可されていないファイル形式です'];
    }
    
    // ✅ MIMEタイプチェック
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    $allowedMimes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!in_array($mimeType, $allowedMimes, true)) {
        return ['success' => false, 'error' => '不正なファイル形式です'];
    }
    
    // ✅ ファイル名をサニタイズ
    $filename = SecurityHelper::sanitizeFilename($file['name']);
    
    // ✅ ユニークなファイル名を生成
    $uniqueFilename = uniqid() . '_' . $filename;
    $destination = UPLOAD_PATH . '/' . $uniqueFilename;
    
    // ✅ ファイル移動
    if (move_uploaded_file($file['tmp_name'], $destination)) {
        return ['success' => true, 'filename' => $uniqueFilename];
    }
    
    return ['success' => false, 'error' => 'ファイル保存に失敗しました'];
}
```

---

## HTTPヘッダー

### セキュリティヘッダー設定

`.htaccess` または `httpd.conf` で設定済み：

```apache
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self';"
Header always set Permissions-Policy "geolocation=(), camera=(), microphone=()"
```

### PHPでのヘッダー設定

```php
// 追加のセキュリティヘッダー
header('X-Frame-Options: SAMEORIGIN');
header('X-Content-Type-Options: nosniff');
header('Content-Security-Policy: default-src \'self\'');
```

---

## セキュリティチェックリスト

### 実装時の必須確認

すべての機能実装で以下を確認：

#### 入力処理
- [ ] すべての入力値をバリデーション
- [ ] ホワイトリスト方式で検証
- [ ] `ValidationHelper` を使用

#### 出力処理
- [ ] すべての出力を `SecurityHelper::escape()` でエスケープ
- [ ] JavaScriptへの出力は `json_encode()` 使用
- [ ] 信頼できないHTMLは絶対に出力しない

#### データベース
- [ ] Prepared Statement を使用
- [ ] 文字列連結でクエリ構築しない
- [ ] カラム名・ORDER BY はホワイトリスト検証

#### CSRF
- [ ] POST/PUT/DELETEで`requireCsrfToken()`を実行
- [ ] フォームに`csrf_token`フィールド埋め込み
- [ ] GETで重要な操作を行わない

#### 認証・セッション
- [ ] ログイン時に `session_regenerate_id(true)` 実行
- [ ] パスワードは `SecurityHelper::hashPassword()` でハッシュ化
- [ ] セッションCookieは `httponly`, `samesite=Strict` 設定

#### ファイルアップロード
- [ ] 拡張子チェック
- [ ] MIMEタイプチェック
- [ ] ファイルサイズチェック
- [ ] ファイル名をサニタイズ

---

**重要**: セキュリティは常に最優先事項です。不明点があれば必ず確認してください。
