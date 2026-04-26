<#
.SYNOPSIS
    SessionStart 時に DevKit の差分を確認し、適用可否をエージェント経由でユーザーへ提示するフックスクリプト。

.DESCRIPTION
    以下の順序で動作します。
      1. stdin から SessionStart ペイロードを受け取る
      2. <project_root>/.devkit/devkit-local.json を探す（なければ何もしない）
      3. <project_root>/.devkit/.last-sync-check のタイムスタンプを確認し、
         前回確認から 24 時間未満であれば何もしない
      4. sync-devkit.ps1 を DryRun で実行し、コピー予定ファイルを取得する
      5. 差分があれば systemMessage に差分情報と操作指示を含めて返す
         → エージェントがユーザーへ対話形式で確認する
      6. タイムスタンプを更新する

.NOTES
    設定ファイル : .devkit/devkit-local.json
      {
        "devkitLocalPath": "G:\\_dev\\_test\\team-devkit"
      }
    タイムスタンプ: .devkit/.last-sync-check
#>

$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────
# レスポンスヘルパー
# ─────────────────────────────────────────────

function New-SessionResponse {
    param(
        [bool]$Continue = $true,
        [string]$SystemMessage = ''
    )
    $response = @{ continue = $Continue }
    if ($SystemMessage -ne '') {
        $response.systemMessage = $SystemMessage
    }
    return ($response | ConvertTo-Json -Depth 5 -Compress)
}

# ─────────────────────────────────────────────
# メイン処理
# ─────────────────────────────────────────────

try {
    # stdin を読み捨て（SessionStart ペイロードは使用しない）
    $null = [Console]::In.ReadToEnd()

    # ── プロジェクトルート特定 ──
    # フックは workspace ルートをカレントディレクトリとして実行される想定
    $projectRoot = (Get-Location).Path

    # ── 設定ファイル確認 ──
    $configPath = Join-Path $projectRoot '.devkit\devkit-local.json'
    if (-not (Test-Path $configPath)) {
        # 設定がなければ何もしない
        Write-Output (New-SessionResponse)
        exit 0
    }

    $config = Get-Content -Path $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $devkitLocalPath = $config.devkitLocalPath

    if ([string]::IsNullOrWhiteSpace($devkitLocalPath)) {
        Write-Output (New-SessionResponse)
        exit 0
    }

    if (-not (Test-Path $devkitLocalPath -PathType Container)) {
        # DevKit ディレクトリが存在しない（別マシン設定など）
        Write-Output (New-SessionResponse)
        exit 0
    }

    # ── 1日1回制限 ──
    $timestampPath = Join-Path $projectRoot '.devkit\.last-sync-check'
    $now = Get-Date

    if (Test-Path $timestampPath) {
        $rawTs = Get-Content -Path $timestampPath -Raw -Encoding UTF8
        $lastCheck = $null
        if ([datetime]::TryParse($rawTs.Trim(), [ref]$lastCheck)) {
            $elapsed = $now - $lastCheck
            if ($elapsed.TotalHours -lt 24) {
                # 24 時間未満なので何もしない
                Write-Output (New-SessionResponse)
                exit 0
            }
        }
    }

    # タイムスタンプを今すぐ更新（スクリプト途中で終了しても翌日まで再実行しない）
    $now.ToString('o') | Set-Content -Path $timestampPath -Encoding UTF8

    # ── DryRun 実行 ──
    $syncScript = Join-Path $devkitLocalPath 'scripts\sync-devkit.ps1'
    if (-not (Test-Path $syncScript)) {
        Write-Output (New-SessionResponse)
        exit 0
    }

    $dryRunOutput = & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass `
        -File $syncScript `
        -ProjectPath $projectRoot `
        -DevKitPath $devkitLocalPath `
        2>&1

    $dryRunText = $dryRunOutput -join "`n"

    # ── 差分ファイルを抽出 ──
    $changedFiles = @(
        $dryRunOutput | Where-Object { $_ -match '^\s*\[DryRun\]' } |
        ForEach-Object { ($_ -replace '^\s*\[DryRun\]\s*', '').Trim() }
    )

    if ($changedFiles.Count -eq 0) {
        # 差分なし：何もしない
        Write-Output (New-SessionResponse)
        exit 0
    }

    # ── systemMessage 組み立て ──
    $fileList = $changedFiles | ForEach-Object { "- $_" }
    $fileListText = $fileList -join "`n"

    $applyCommand = ".\scripts\sync-devkit.ps1 -ProjectPath `"$projectRoot`" -DevKitPath `"$devkitLocalPath`" -Apply -Force"

    $message = @"
## DevKit 同期確認

DevKit に更新があります。以下のファイルが同期対象です（$($changedFiles.Count) 件）。

$fileListText

**ユーザーへ以下を確認してください。**

> 上記ファイルを DevKit から同期しますか？
> - 「はい」の場合は次のコマンドを実行してください:
>   ``$applyCommand``
> - 「いいえ」の場合は何もしません。

確認をお願いします。
"@

    Write-Output (New-SessionResponse -SystemMessage $message)
    exit 0
}
catch {
    # フックでのエラーは握りつぶしてセッションを継続させる
    Write-Output (New-SessionResponse)
    exit 0
}
