<#
.SYNOPSIS
    team-devkit の共通資産を案件リポジトリへ同期するスクリプト。

.DESCRIPTION
    .devkit/manifest.json の overrides 設定を尊重しながら、
    DevKit の共通資産を指定した案件リポジトリへコピーします。

    同期対象パス（DevKit → 案件）:
      .github/agents/**               -> .github/agents/**
      .github/hooks/**                -> .github/hooks/**
      .github/instructions/**         -> .github/instructions/**
      .github/prompts/**              -> .github/prompts/**
      .github/skills/**               -> .github/skills/**
      .docs/common/**                 -> .docs/common/**
      AGENT.md                        -> AGENT.md
      .github/copilot-instructions.md -> .github/copilot-instructions.md

.PARAMETER ProjectPath
    同期先の案件リポジトリのルートパス。
    -Apply 指定時は省略可能で、スクリプトの親ディレクトリを自動使用します。

.PARAMETER DevKitPath
    DevKit リポジトリのルートパス。省略時はこのスクリプトの親ディレクトリを使用します。

.PARAMETER Apply
    実際のコピーを実行します。このオプションを指定しない場合は DryRun（差分確認のみ）として動作します。

.PARAMETER Force
    -Apply と併用することで、実行前の確認プロンプトをスキップします。

.PARAMETER Help
    利用方法を表示して終了します。

.EXAMPLE
    # 差分確認のみ（オプションなし = DryRun）
    .\sync-devkit.ps1 -ProjectPath "G:\_dev\_projects\my-project"

.EXAMPLE
    # 実際に同期を実行する
    .\sync-devkit.ps1 -ProjectPath "G:\_dev\_projects\my-project" -Apply

.EXAMPLE
    # 確認スキップして実行（CI 向け）
    .\sync-devkit.ps1 -ProjectPath "G:\_dev\_projects\my-project" -Apply -Force
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false, HelpMessage = '同期先の案件リポジトリのルートパス')]
    [string]$ProjectPath,

    [Parameter(Mandatory = $false, HelpMessage = 'DevKit リポジトリのルートパス（省略時: スクリプトの親ディレクトリ）')]
    [string]$DevKitPath,

    [Parameter(Mandatory = $false, HelpMessage = '実際のコピーを実行する（省略時は DryRun として動作）')]
    [switch]$Apply,

    [Parameter(Mandatory = $false, HelpMessage = '-Apply と併用して確認プロンプトをスキップする')]
    [switch]$Force,

    [Parameter(Mandatory = $false, HelpMessage = '利用方法を表示して終了する')]
    [Alias('h', 'help', '?')]
    [switch]$ShowHelp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────
# 定数定義
# ─────────────────────────────────────────────

# DevKit から案件への同期マッピング（相対パス）
# キー: DevKit 側の相対パス（ファイルまたはディレクトリ）
# 値:   案件側の相対パス
$SYNC_MAP = [ordered]@{
    '.github/agents'               = '.github/agents'
    '.github/hooks'                = '.github/hooks'
    '.github/instructions'         = '.github/instructions'
    '.github/prompts'              = '.github/prompts'
    '.github/skills'               = '.github/skills'
    '.docs/common'                 = '.docs/common'
    'AGENT.md'                     = 'AGENT.md'
    '.github/copilot-instructions.md' = '.github/copilot-instructions.md'
}

# マニフェストのデフォルト値
$DEFAULT_MANIFEST = @{
    devkitRepository = 'team-devkit'
    devkitVersion    = '0.0.0'
    syncProfile      = 'php-hosting-standard'
    overrides        = @()
}

# ─────────────────────────────────────────────
# ユーティリティ関数
# ─────────────────────────────────────────────

function Write-Header {
    param([string]$Text)
    $line = '─' * 60
    Write-Host ''
    Write-Host $line -ForegroundColor DarkGray
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor DarkGray
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [情報] $Text" -ForegroundColor Gray
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [コピー] $Text" -ForegroundColor Green
}

function Write-Skip {
    param([string]$Text, [string]$Reason)
    Write-Host "  [スキップ] $Text  ($Reason)" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Text)
    Write-Host "  [エラー] $Text" -ForegroundColor Red
}

function Show-Usage {
    $scriptName = Split-Path -Leaf $PSCommandPath
@"
使用方法:
  .\$scriptName -ProjectPath <案件ルートパス> [-DevKitPath <DevKitルートパス>] [-Apply] [-Force]
  .\$scriptName -Apply [-DevKitPath <DevKitルートパス>] [-Force]
  .\$scriptName -h | -H | -help | -Help | --help

補足:
  - オプションなしは DryRun（差分確認のみ）
  - -Apply 指定時はスクリプトの親ディレクトリを案件ルートとして自動判定
  - -Apply 指定時は以下の基本構成を前提に確認します:
      .devkit/, .docs/, .github/, src/, tests/, .docker/, docker-compose.yml
"@ | Write-Host
}

function Resolve-ProjectRoot {
    param(
        [string]$InputProjectPath,
        [bool]$ApplyMode
    )

    if ($ApplyMode) {
        $detectedRoot = Split-Path -Parent $PSScriptRoot
        if ($InputProjectPath -and ($InputProjectPath -ne $detectedRoot)) {
            Write-Info "-Apply 指定時のため ProjectPath は無視します: $InputProjectPath"
        }
        return $detectedRoot
    }

    if (-not $InputProjectPath) {
        throw 'DryRun では -ProjectPath の指定が必要です。'
    }

    return $InputProjectPath
}

function Test-ExpectedProjectStructure {
    param([string]$ProjectRoot)

    $requiredDirectories = @(
        '.devkit',
        '.docs',
        '.github',
        'src',
        'tests',
        '.docker'
    )
    $requiredFiles = @(
        'docker-compose.yml'
    )

    $createdDirectories = @()
    foreach ($relativePath in $requiredDirectories) {
        $absolutePath = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            New-Item -ItemType Directory -Path $absolutePath -Force | Out-Null
            $createdDirectories += $relativePath
        }
    }

    $missingFiles = @()
    foreach ($relativePath in $requiredFiles) {
        $absolutePath = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $absolutePath)) {
            $missingFiles += $relativePath
        }
    }

    return @{
        createdDirectories = $createdDirectories
        missingFiles       = $missingFiles
    }
}

<#
.SYNOPSIS
    glob パターン文字列を PowerShell の -like 演算子用パターンに変換します。
    例: ".docs/project/**" -> ".docs/project/*"
        ".github/hooks/docker-info.json" はそのまま返します。
#>
function ConvertTo-LikePattern {
    param([string]$GlobPattern)
    # ** を * に統一（-like は再帰的ワイルドカードを持たないが、
    # 先頭一致で使うため * で代用）
    $pattern = $GlobPattern -replace '\*\*', '*'
    # パス区切りを正規化
    return $pattern.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
}

<#
.SYNOPSIS
    相対パスが overrides パターンに合致するか判定します。
#>
function Test-IsOverride {
    param(
        [string]$RelativePath,
        [string[]]$OverridePatterns
    )
    $normalizedPath = $RelativePath.Replace('/', [System.IO.Path]::DirectorySeparatorChar)

    foreach ($pattern in $OverridePatterns) {
        $likePattern = ConvertTo-LikePattern -GlobPattern $pattern

        # 完全一致 または ワイルドカード一致
        if ($normalizedPath -like $likePattern) {
            return $true
        }

        # ディレクトリプレフィックス一致（例: パターン ".docs/project/*" に対して ".docs/project/foo/bar.md"）
        $prefixPattern = $likePattern.TrimEnd('*').TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        if ($normalizedPath.StartsWith($prefixPattern + [System.IO.Path]::DirectorySeparatorChar)) {
            return $true
        }
    }
    return $false
}

<#
.SYNOPSIS
    .devkit/manifest.json を読み込み、ハッシュテーブルとして返します。
    ファイルが存在しない場合はデフォルト値を返します。
#>
function Get-Manifest {
    param([string]$ProjectRoot)
    $manifestPath = Join-Path $ProjectRoot '.devkit\manifest.json'

    if (-not (Test-Path $manifestPath)) {
        Write-Info '.devkit/manifest.json が見つかりません。デフォルト設定で同期します。'
        return $DEFAULT_MANIFEST
    }

    try {
        $json = Get-Content -Path $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $manifest = @{
            devkitRepository = if ($json.devkitRepository) { $json.devkitRepository } else { $DEFAULT_MANIFEST.devkitRepository }
            devkitVersion    = if ($json.devkitVersion) { $json.devkitVersion } else { $DEFAULT_MANIFEST.devkitVersion }
            syncProfile      = if ($json.syncProfile) { $json.syncProfile } else { $DEFAULT_MANIFEST.syncProfile }
            overrides        = if ($null -ne $json.overrides) { [string[]]$json.overrides } else { @() }
        }
        Write-Info "マニフェスト読み込み完了 (バージョン: $($manifest.devkitVersion)、プロファイル: $($manifest.syncProfile))"
        return $manifest
    }
    catch {
        Write-Warning ".devkit/manifest.json の解析に失敗しました: $_"
        return $DEFAULT_MANIFEST
    }
}

<#
.SYNOPSIS
    2 つのファイルの内容が同一かどうかを判定します。
#>
function Test-FileIdentical {
    param([string]$PathA, [string]$PathB)
    if (-not (Test-Path $PathB)) { return $false }
    $hashA = (Get-FileHash -Path $PathA -Algorithm SHA256).Hash
    $hashB = (Get-FileHash -Path $PathB -Algorithm SHA256).Hash
    return $hashA -eq $hashB
}

# ─────────────────────────────────────────────
# メイン処理
# ─────────────────────────────────────────────

function Invoke-Sync {
    if ($ShowHelp) {
        Show-Usage
        return
    }

    # パス正規化
    $resolvedDevKitPath = if ($DevKitPath) { $DevKitPath } else { Split-Path -Parent $PSScriptRoot }
    $devKitRoot  = (Resolve-Path -LiteralPath $resolvedDevKitPath).Path
    $projectRoot = Resolve-ProjectRoot -InputProjectPath $ProjectPath -ApplyMode $Apply.IsPresent

    # 案件ディレクトリ存在確認
    if (-not (Test-Path $projectRoot -PathType Container)) {
        Write-Error "案件ディレクトリが見つかりません: $projectRoot"
        exit 1
    }
    $projectRoot = (Resolve-Path -LiteralPath $projectRoot).Path

    # 同一ディレクトリへの同期を防ぐ
    if ($Apply -and -not $DevKitPath -and ($devKitRoot -eq $projectRoot)) {
        Write-Error '-Apply では案件ルートをスクリプト親ディレクトリから自動判定します。DevKitPath を明示指定してください。'
        exit 1
    }

    if ($devKitRoot -eq $projectRoot) {
        Write-Error 'DevKit と案件が同じディレクトリを指しています。同期をキャンセルします。'
        exit 1
    }

    Write-Header 'DevKit 同期スクリプト'
    Write-Info "DevKit パス : $devKitRoot"
    Write-Info "案件パス    : $projectRoot"

    if ($Apply) {
        $structureCheck = Test-ExpectedProjectStructure -ProjectRoot $projectRoot
        $createdDirectories = @($structureCheck.createdDirectories)
        $missingFiles = @($structureCheck.missingFiles)

        if ($createdDirectories.Count -gt 0) {
            Write-Info "不足ディレクトリを作成しました: $($createdDirectories -join ', ')"
        }

        if ($missingFiles.Count -gt 0) {
            Write-Error "-Apply で想定する必須ファイルが不足しています: $($missingFiles -join ', ')"
            exit 1
        }
        Write-Info '-Apply 向け基本構成を確認しました。'
    }

    if (-not $Apply) {
        Write-Host ''
        Write-Host '  ★ DryRun モード: ファイルはコピーされません（実行するには -Apply を指定してください）★' -ForegroundColor Magenta
    }

    # マニフェスト読み込み
    Write-Header 'マニフェスト確認'
    $manifest = Get-Manifest -ProjectRoot $projectRoot
    $overrides = $manifest.overrides
    $overrideCount = @($overrides).Count

    if ($overrideCount -gt 0) {
        Write-Info "オーバーライド対象 ($overrideCount 件):"
        foreach ($ov in $overrides) {
            Write-Host "      - $ov" -ForegroundColor DarkYellow
        }
    }
    else {
        Write-Info 'オーバーライド設定なし'
    }

    # 同期確認プロンプト（-Apply 指定時のみ、-Force なければ確認する）
    if ($Apply -and -not $Force) {
        Write-Host ''
        $answer = Read-Host '  同期を実行しますか？ [y/N]'
        if ($answer -notmatch '^[Yy]$') {
            Write-Host '  キャンセルしました。' -ForegroundColor Yellow
            exit 0
        }
    }

    # 同期実行
    Write-Header '同期処理'
    $stats = @{ copied = 0; skipped_override = 0; skipped_unchanged = 0; failed = 0 }

    foreach ($entry in $SYNC_MAP.GetEnumerator()) {
        $srcRelative  = $entry.Key.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $destRelative = $entry.Value.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
        $srcAbsolute  = Join-Path $devKitRoot $srcRelative
        $destAbsolute = Join-Path $projectRoot $destRelative

        # ソース存在確認
        if (-not (Test-Path $srcAbsolute)) {
            Write-Skip $srcRelative 'DevKit に存在しない'
            continue
        }

        $isDirectory = (Get-Item $srcAbsolute).PSIsContainer

        if ($isDirectory) {
            # ─── ディレクトリ同期 ───
            $srcFiles = Get-ChildItem -Path $srcAbsolute -Recurse -File

            foreach ($srcFile in $srcFiles) {
                $fileRelToDevKit = $srcFile.FullName.Substring($devKitRoot.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
                $fileRelToEntry  = $srcFile.FullName.Substring($srcAbsolute.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
                $destFile        = Join-Path $destAbsolute $fileRelToEntry

                # override 判定（案件リポジトリ相対パスで評価）
                $fileRelToProject = Join-Path $destRelative $fileRelToEntry
                $fileRelToProject = $fileRelToProject.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

                if (Test-IsOverride -RelativePath $fileRelToProject -OverridePatterns $overrides) {
                    Write-Skip $fileRelToProject 'override 設定'
                    $stats.skipped_override++
                    continue
                }

                # 内容が同一なら skip
                if (Test-FileIdentical -PathA $srcFile.FullName -PathB $destFile) {
                    Write-Skip $fileRelToProject '変更なし'
                    $stats.skipped_unchanged++
                    continue
                }

                if ($Apply) {
                    try {
                        $destDir = Split-Path $destFile -Parent
                        if (-not (Test-Path $destDir)) {
                            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                        }
                        Copy-Item -LiteralPath $srcFile.FullName -Destination $destFile -Force
                        Write-Success $fileRelToProject
                        $stats.copied++
                    }
                    catch {
                        Write-Fail "${fileRelToProject}: $_"
                        $stats.failed++
                    }
                }
                else {
                    Write-Success "[DryRun] $fileRelToProject"
                    $stats.copied++
                }
            }
        }
        else {
            # ─── 単一ファイル同期 ───
            $fileRelToProject = $destRelative.Replace([System.IO.Path]::DirectorySeparatorChar, '/')

            # override 判定
            if (Test-IsOverride -RelativePath $fileRelToProject -OverridePatterns $overrides) {
                Write-Skip $fileRelToProject 'override 設定'
                $stats.skipped_override++
                continue
            }

            # 内容が同一なら skip
            if (Test-FileIdentical -PathA $srcAbsolute -PathB $destAbsolute) {
                Write-Skip $fileRelToProject '変更なし'
                $stats.skipped_unchanged++
                continue
            }

            if ($Apply) {
                try {
                    $destDir = Split-Path $destAbsolute -Parent
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -LiteralPath $srcAbsolute -Destination $destAbsolute -Force
                    Write-Success $fileRelToProject
                    $stats.copied++
                }
                catch {
                    Write-Fail "${fileRelToProject}: $_"
                    $stats.failed++
                }
            }
            else {
                Write-Success "[DryRun] $fileRelToProject"
                $stats.copied++
            }
        }
    }

    # サマリー表示
    Write-Header '同期結果サマリー'
    if (-not $Apply) {
        Write-Host "  コピー予定      : $($stats.copied) 件" -ForegroundColor Green
        Write-Host '  ※ 実行するには -Apply オプションを指定してください。' -ForegroundColor Magenta
    }
    else {
        Write-Host "  コピー完了      : $($stats.copied) 件" -ForegroundColor Green
    }
    Write-Host "  スキップ（override） : $($stats.skipped_override) 件" -ForegroundColor Yellow
    Write-Host "  スキップ（変更なし） : $($stats.skipped_unchanged) 件" -ForegroundColor Gray
    if ($stats.failed -gt 0) {
        Write-Host "  エラー          : $($stats.failed) 件" -ForegroundColor Red
    }
    Write-Host ''

    if ($stats.failed -gt 0) {
        exit 1
    }
}

Invoke-Sync
