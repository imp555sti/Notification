$ErrorActionPreference = 'Stop'

function New-HookResponse {
    param(
        [bool]$Continue = $true,
        [string]$SystemMessage = '',
        [string]$PermissionDecision = '',
        [string]$PermissionReason = ''
    )

    $response = @{ continue = $Continue }

    if ($SystemMessage -ne '') {
        $response.systemMessage = $SystemMessage
    }

    if ($PermissionDecision -ne '') {
        $response.hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            permissionDecision = $PermissionDecision
            permissionDecisionReason = $PermissionReason
        }
    }

    return ($response | ConvertTo-Json -Depth 10 -Compress)
}

function Get-PropValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [string[]]$PathCandidates
    )

    foreach ($path in $PathCandidates) {
        $value = $Object
        $exists = $true

        foreach ($segment in $path.Split('.')) {
            if ($null -eq $value) {
                $exists = $false
                break
            }

            $prop = $value.PSObject.Properties[$segment]
            if ($null -eq $prop) {
                $exists = $false
                break
            }

            $value = $prop.Value
        }

        if ($exists -and $null -ne $value) {
            return $value
        }
    }

    return $null
}

function Get-StagedFiles {
    try {
        $staged = git diff --cached --name-only 2>$null
        if ($LASTEXITCODE -eq 0 -and $staged) {
            return $staged | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        }
    } catch {
    }

    return @()
}

function Get-GitAddArgumentSets {
    param(
        [string]$CommandText
    )

    $argumentSets = New-Object System.Collections.Generic.List[object]
    if ([string]::IsNullOrWhiteSpace($CommandText)) {
        return $argumentSets
    }

    $matches = [regex]::Matches($CommandText, '(?is)\bgit\s+add\b(?<args>.*?)(?=(?:\s*(?:&&|\|\||;)|\r?\n|$))')
    foreach ($match in $matches) {
        $argsText = [string]$match.Groups['args'].Value
        if ([string]::IsNullOrWhiteSpace($argsText)) {
            $argumentSets.Add(@()) | Out-Null
            continue
        }

        $tokens = New-Object System.Collections.Generic.List[string]
        $tokenMatches = [regex]::Matches($argsText, '"(?:[^"\\]|\\.)*"|''(?:[^''\\]|\\.)*''|\S+')
        foreach ($tokenMatch in $tokenMatches) {
            $token = [string]$tokenMatch.Value
            if ([string]::IsNullOrWhiteSpace($token)) {
                continue
            }

            if (($token.StartsWith('"') -and $token.EndsWith('"')) -or ($token.StartsWith("'") -and $token.EndsWith("'"))) {
                $token = $token.Substring(1, $token.Length - 2)
            }

            $tokens.Add($token) | Out-Null
        }

        $argumentSets.Add(@($tokens)) | Out-Null
    }

    return $argumentSets
}

function Get-StagedFilesWithChainedGitAdd {
    param(
        [string[]]$CurrentStagedFiles,
        [string]$CommandText
    )

    $result = [ordered]@{
        files = @($CurrentStagedFiles)
        simulationUsed = $false
        simulationError = ''
    }

    $argumentSets = Get-GitAddArgumentSets -CommandText $CommandText
    if ($argumentSets.Count -eq 0) {
        return $result
    }

    $gitDir = git rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitDir)) {
        $result.simulationError = 'git リポジトリ情報を取得できず、git add 疑似反映をスキップしました'
        return $result
    }

    $tempIndexPath = [System.IO.Path]::GetTempFileName()
    $indexPath = Join-Path -Path ([string]$gitDir).Trim() -ChildPath 'index'
    $previousIndexFile = $env:GIT_INDEX_FILE

    try {
        if (Test-Path -LiteralPath $indexPath) {
            Copy-Item -LiteralPath $indexPath -Destination $tempIndexPath -Force
        }

        $env:GIT_INDEX_FILE = $tempIndexPath

        foreach ($argSet in $argumentSets) {
            & git add @argSet 2>$null
            if ($LASTEXITCODE -ne 0) {
                $result.simulationError = 'git add 疑似反映に失敗したため、既存ステージ情報のみで判定します'
                return $result
            }
        }

        $simulatedStaged = git diff --cached --name-only 2>$null
        if ($LASTEXITCODE -eq 0 -and $simulatedStaged) {
            $simulatedFiles = @($simulatedStaged | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            $result.files = @($simulatedFiles | Select-Object -Unique)
            $result.simulationUsed = $true
        }

        return $result
    } catch {
        $result.simulationError = "git add 疑似反映で例外が発生: $($_.Exception.Message)"
        return $result
    } finally {
        if ($null -eq $previousIndexFile) {
            Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
        } else {
            $env:GIT_INDEX_FILE = $previousIndexFile
        }

        if (Test-Path -LiteralPath $tempIndexPath) {
            Remove-Item -LiteralPath $tempIndexPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-PushCandidateFiles {
    $result = [ordered]@{
        files = @()
        source = ''
        error = ''
        range = ''
    }

    $upstreamRef = ''

    try {
        $upstreamRaw = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($upstreamRaw)) {
            $upstreamRef = [string]($upstreamRaw | Select-Object -First 1)
        }
    } catch {
    }

    try {
        $changed = @()

        if (-not [string]::IsNullOrWhiteSpace($upstreamRef)) {
            $range = "$upstreamRef...HEAD"
            $changedRaw = git diff --name-only $range 2>$null
            if ($LASTEXITCODE -eq 0 -and $changedRaw) {
                $changed = @($changedRaw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            $result.source = 'git diff --name-only <upstream>...HEAD'
            $result.range = $range
        } else {
            $changedRaw = git log --name-only --pretty=format: HEAD --not --remotes 2>$null
            if ($LASTEXITCODE -eq 0 -and $changedRaw) {
                $changed = @($changedRaw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }
            $result.source = 'git log --name-only HEAD --not --remotes'
        }

        if ($changed.Count -gt 0) {
            $result.files = @($changed | Select-Object -Unique)
        }

        return $result
    } catch {
        $result.error = "push 対象差分の取得に失敗: $($_.Exception.Message)"
        return $result
    }
}

function Resolve-DockerPhpService {
    $result = [ordered]@{
        serviceName = ''
        source = ''
        error = ''
    }

    $configPath = '.docs/hooks/docker-info.json'
    if (Test-Path -LiteralPath $configPath) {
        try {
            $configRaw = Get-Content -LiteralPath $configPath -Raw
            if (-not [string]::IsNullOrWhiteSpace($configRaw)) {
                $config = $configRaw | ConvertFrom-Json -Depth 20
                $serviceFromConfig = ''

                if ($null -ne $config.PSObject.Properties['phpService']) {
                    $serviceFromConfig = [string]$config.phpService
                } elseif ($null -ne $config.PSObject.Properties['php_service']) {
                    $serviceFromConfig = [string]$config.php_service
                } elseif ($null -ne $config.PSObject.Properties['serviceName']) {
                    $serviceFromConfig = [string]$config.serviceName
                }

                if (-not [string]::IsNullOrWhiteSpace($serviceFromConfig)) {
                    $result.serviceName = $serviceFromConfig.Trim()
                    $result.source = $configPath
                    return $result
                }
            }
        } catch {
            $result.error = "docker-info.json の解析に失敗: $($_.Exception.Message)"
            return $result
        }
    }

    try {
        $servicesRaw = docker compose config --services 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $servicesRaw) {
            $result.error = 'docker compose config --services の取得に失敗'
            return $result
        }

        $services = @($servicesRaw | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
        if ($services.Count -eq 0) {
            $result.error = 'docker compose からサービス一覧を取得できませんでした'
            return $result
        }

        $preferredPatterns = @('apache-php', '^php$', '^php-', '-php$', 'web', 'app')
        foreach ($pattern in $preferredPatterns) {
            $match = $services | Where-Object { $_ -match $pattern } | Select-Object -First 1
            if (-not [string]::IsNullOrWhiteSpace($match)) {
                $result.serviceName = $match
                $result.source = 'docker compose config --services'
                return $result
            }
        }

        if ($services.Count -eq 1) {
            $result.serviceName = $services[0]
            $result.source = 'docker compose config --services (single-service fallback)'
            return $result
        }

        $result.error = "PHP実行サービスを自動判定できませんでした: $($services -join ', ')"
        return $result
    } catch {
        $result.error = $_.Exception.Message
        return $result
    }
}

function Run-Linter {
    param(
        [string[]]$TargetFiles
    )

    $result = [ordered]@{
        status = 'SKIP'
        command = ''
        output = ''
    }

    if ($TargetFiles.Count -eq 0) {
        $result.output = 'PHP差分ファイルがないためスキップ'
        return $result
    }

    try {
        $docker = Get-Command docker -ErrorAction SilentlyContinue
        if ($null -eq $docker) {
            $result.status = 'FAIL'
            $result.command = 'docker compose exec -T <php-service> composer phpcs'
            $result.output = 'docker コマンドが見つからないため、Docker環境内Linter実行に失敗'
            return $result
        }

        $serviceInfo = Resolve-DockerPhpService
        if ([string]::IsNullOrWhiteSpace([string]$serviceInfo.serviceName)) {
            $result.status = 'FAIL'
            $result.command = 'docker compose exec -T <php-service> composer phpcs'
            $result.output = if ([string]::IsNullOrWhiteSpace([string]$serviceInfo.error)) {
                'PHPサービス名を解決できないため、Docker環境内Linter実行に失敗'
            } else {
                [string]$serviceInfo.error
            }
            return $result
        }

        $phpService = [string]$serviceInfo.serviceName
        $result.command = "docker compose exec -T $phpService composer phpcs"
        $output = docker compose exec -T $phpService composer phpcs 2>&1
        $result.output = ($output | Out-String).Trim()
        $result.status = if ($LASTEXITCODE -eq 0) { 'PASS' } else { 'FAIL' }
        return $result
    } catch {
        $result.status = 'FAIL'
        $result.output = $_.Exception.Message
        return $result
    }
}

function Add-Finding {
    param(
        [System.Collections.Generic.List[object]]$Findings,
        [string]$Severity,
        [string]$Title,
        [string]$Detail,
        [string]$Suggestion
    )

    $Findings.Add([ordered]@{
        severity = $Severity
        title = $Title
        detail = $Detail
        suggestion = $Suggestion
    }) | Out-Null
}

function Analyze-PhpFiles {
    param(
        [string[]]$PhpFiles
    )

    $findings = New-Object 'System.Collections.Generic.List[object]'

    foreach ($file in $PhpFiles) {
        if (-not (Test-Path -LiteralPath $file)) {
            continue
        }

        $content = Get-Content -LiteralPath $file -Raw

        if ($content -notmatch 'declare\s*\(\s*strict_types\s*=\s*1\s*\)') {
            Add-Finding -Findings $findings -Severity 'MEDIUM' -Title 'strict_types不足' -Detail "$file に declare(strict_types=1); がありません" -Suggestion 'PHPファイル先頭へ strict_types 宣言を追加'
        }

        if ($content -match '\$_(GET|POST|REQUEST|COOKIE)') {
            Add-Finding -Findings $findings -Severity 'HIGH' -Title '生入力の直接参照' -Detail "$file でスーパーグローバル直接参照を検知" -Suggestion 'Controllerの入力取得ヘルパーと ValidationHelper を利用'
        }

        if ($content -match 'SELECT.+\$|INSERT.+\$|UPDATE.+\$|DELETE.+\$') {
            Add-Finding -Findings $findings -Severity 'HIGH' -Title 'SQL組み立ての疑い' -Detail "$file に変数連結の可能性があるSQLを検知" -Suggestion 'Prepared Statement を使用して値をバインド'
        }

        if ($content -match 'echo\s+\$' -and $content -notmatch 'SecurityHelper::escape') {
            Add-Finding -Findings $findings -Severity 'MEDIUM' -Title 'エスケープ不足の疑い' -Detail "$file に escape なし出力の疑い" -Suggestion '出力時に SecurityHelper::escape を適用'
        }
    }

    return $findings
}

try {
    $rawInput = [Console]::In.ReadToEnd()

    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Output (New-HookResponse)
        exit 0
    }

    $payload = $rawInput | ConvertFrom-Json -Depth 100

    $toolName = [string](Get-PropValue -Object $payload -PathCandidates @(
        'toolName',
        'tool_name',
        'tool.name',
        'toolCall.name'
    ))

    $commandText = [string](Get-PropValue -Object $payload -PathCandidates @(
        'toolInput.command',
        'toolCall.input.command',
        'input.command',
        'command'
    ))

    $isTerminalTool = $toolName -match 'run_in_terminal|send_to_terminal|terminal'
    if (-not $isTerminalTool) {
        Write-Output (New-HookResponse)
        exit 0
    }

    $isGateTarget = $commandText -match '(?i)\bgit\s+commit\b|\bgit\s+push\b|\bgh\s+pr\s+(create|merge)\b|\bgit\s+merge\b'
    if (-not $isGateTarget) {
        Write-Output (New-HookResponse)
        exit 0
    }

    $hasPush = $commandText -match '(?i)\bgit\s+push\b'
    $hasGitAdd = $commandText -match '(?i)\bgit\s+add\b'
    $hasGateAction = $commandText -match '(?i)\bgit\s+commit\b|\bgit\s+push\b|\bgh\s+pr\s+(create|merge)\b|\bgit\s+merge\b'
    $hasCommandJoiner = $commandText -match '(?s)(;|&&|\|\||\r?\n|`n)'

    $stagedFiles = Get-StagedFiles
    $pushCandidate = [ordered]@{
        files = @()
        source = ''
        error = ''
        range = ''
    }
    $simulation = [ordered]@{
        simulationUsed = $false
        simulationError = ''
    }

    if ($hasGitAdd -and $hasGateAction -and $hasCommandJoiner) {
        $simulated = Get-StagedFilesWithChainedGitAdd -CurrentStagedFiles $stagedFiles -CommandText $commandText
        $stagedFiles = @($simulated.files | Select-Object -Unique)
        $simulation.simulationUsed = [bool]$simulated.simulationUsed
        $simulation.simulationError = [string]$simulated.simulationError
    }

    if ($hasPush) {
        $pushCandidate = Get-PushCandidateFiles
    }

    $reviewTargetFiles = @($stagedFiles + $pushCandidate.files | Select-Object -Unique)
    $phpFiles = @($reviewTargetFiles | Where-Object { $_ -match '\.php$' })

    $lint = Run-Linter -TargetFiles $phpFiles
    $findings = Analyze-PhpFiles -PhpFiles $phpFiles

    $highCount = @($findings | Where-Object { $_.severity -eq 'HIGH' }).Count
    $mediumCount = @($findings | Where-Object { $_.severity -eq 'MEDIUM' }).Count
    $mustFix = ($lint.status -eq 'FAIL') -or ($highCount -gt 0)

    $reviewResult = if ($mustFix) { '❌ 要改善' } elseif ($mediumCount -gt 0) { '⚠️ 条件付き承認（Approve with Changes）' } else { '✅ 承認（Approve）' }
    $mergeDecision = if ($mustFix) { '❌ 修正後に実行推奨' } elseif ($mediumCount -gt 0) { '⚠️ 条件付きで実行可能' } else { '✅ 実行可能' }

    $mustFixItems = New-Object System.Collections.Generic.List[string]
    if ($lint.status -eq 'FAIL') {
        $mustFixItems.Add('🔴 Linterでエラー検知: ルール違反を修正') | Out-Null
    }
    foreach ($item in ($findings | Where-Object { $_.severity -eq 'HIGH' })) {
        $mustFixItems.Add("🔴 $($item.title): $($item.suggestion)") | Out-Null
    }

    $recommendedItems = New-Object System.Collections.Generic.List[string]
    foreach ($item in ($findings | Where-Object { $_.severity -eq 'MEDIUM' })) {
        $recommendedItems.Add("🟡 $($item.title): $($item.suggestion)") | Out-Null
    }

    if ($mustFixItems.Count -eq 0) {
        $mustFixItems.Add('なし') | Out-Null
    }
    if ($recommendedItems.Count -eq 0) {
        $recommendedItems.Add('なし') | Out-Null
    }

    $metricsLinter = if ($lint.status -eq 'PASS') { '✅ OK' } elseif ($lint.status -eq 'FAIL') { '❌ 要修正' } else { '⚪ スキップ' }
    $metricsReview = if ($highCount -gt 0) { '❌ 要修正' } elseif ($mediumCount -gt 0) { '⚠️ 要改善' } else { '✅ OK' }

    $goodPoints = New-Object System.Collections.Generic.List[string]
    if ($lint.status -eq 'PASS') {
        $goodPoints.Add('Linter チェックを通過') | Out-Null
    }
    if ($highCount -eq 0) {
        $goodPoints.Add('Critical Issues 該当なし') | Out-Null
    }
    if ($mediumCount -eq 0) {
        $goodPoints.Add('Minor Issues 該当なし') | Out-Null
    }
    if ($goodPoints.Count -eq 0) {
        $goodPoints.Add('なし') | Out-Null
    }

    $minorIssueSections = New-Object System.Collections.Generic.List[string]
    $minorIndex = 1
    foreach ($item in ($findings | Where-Object { $_.severity -eq 'MEDIUM' })) {
        $minorIssueSections.Add(@"
### $minorIndex. $($item.title)

**重大度**: 🟡 Medium（品質リスク）
**内容**: $($item.detail)
**推奨修正**: $($item.suggestion)
"@.Trim()) | Out-Null
        $minorIndex++
    }

    if ($minorIssueSections.Count -eq 0) {
        $minorIssueSections.Add('指摘なし') | Out-Null
    }

    $criticalIssueSections = New-Object System.Collections.Generic.List[string]
    $criticalIndex = 1

    if ($lint.status -eq 'FAIL') {
        $criticalIssueSections.Add(@"
### $criticalIndex. Linter エラー

**重大度**: 🔴 High（品質リスク）
**内容**: Linter で失敗が検出されました
**推奨修正**: ルール違反を修正して再実行
"@.Trim()) | Out-Null
        $criticalIndex++
    }

    foreach ($item in ($findings | Where-Object { $_.severity -eq 'HIGH' })) {
        $criticalIssueSections.Add(@"
### $criticalIndex. $($item.title)

**重大度**: 🔴 High（セキュリティ/品質リスク）
**内容**: $($item.detail)
**推奨修正**: $($item.suggestion)
"@.Trim()) | Out-Null
        $criticalIndex++
    }

    if ($criticalIssueSections.Count -eq 0) {
        $criticalIssueSections.Add('指摘なし') | Out-Null
    }

    $changedPhpSummary = if ($phpFiles.Count -gt 0) { ($phpFiles -join ', ') } else { 'なし' }
    $pushTargetSummary = if ($pushCandidate.files.Count -gt 0) { ($pushCandidate.files -join ', ') } else { 'なし' }
    $reviewReasons = New-Object System.Collections.Generic.List[string]
    if ($lint.status -eq 'FAIL') {
        $reviewReasons.Add('Linter 失敗により要修正') | Out-Null
    } elseif ($lint.status -eq 'PASS') {
        $reviewReasons.Add('Linter は通過') | Out-Null
    } else {
        $reviewReasons.Add('Linter は実行スキップ') | Out-Null
    }
    if ($highCount -gt 0) {
        $reviewReasons.Add('Critical Issues が存在') | Out-Null
    }
    if ($mediumCount -gt 0) {
        $reviewReasons.Add('Minor Issues が存在') | Out-Null
    }
    if ($reviewReasons.Count -eq 0) {
        $reviewReasons.Add('主要な問題は検出されず') | Out-Null
    }
    if ($simulation.simulationUsed) {
        $reviewReasons.Add('連結コマンドの git add を疑似反映して対象ファイルを算出') | Out-Null
    } elseif (-not [string]::IsNullOrWhiteSpace($simulation.simulationError)) {
        $reviewReasons.Add($simulation.simulationError) | Out-Null
    }
    if ($hasPush) {
        if ($pushCandidate.files.Count -gt 0) {
            if (-not [string]::IsNullOrWhiteSpace($pushCandidate.range)) {
                $reviewReasons.Add("push 直前チェックとして未反映コミット差分を対象化（$($pushCandidate.range)）") | Out-Null
            } else {
                $reviewReasons.Add('push 直前チェックとして未反映コミット差分を対象化') | Out-Null
            }
        } elseif (-not [string]::IsNullOrWhiteSpace($pushCandidate.error)) {
            $reviewReasons.Add($pushCandidate.error) | Out-Null
        }
    }

    $pushDiffStatus = '対象外'
    if ($hasPush) {
        if (-not [string]::IsNullOrWhiteSpace($pushCandidate.error)) {
            $pushDiffStatus = "失敗（$($pushCandidate.error)）"
        } elseif (-not [string]::IsNullOrWhiteSpace($pushCandidate.source)) {
            if (-not [string]::IsNullOrWhiteSpace($pushCandidate.range)) {
                $pushDiffStatus = "成功（$($pushCandidate.source): $($pushCandidate.range)）"
            } else {
                $pushDiffStatus = "成功（$($pushCandidate.source)）"
            }
        } else {
            $pushDiffStatus = '対象なし'
        }
    }

    $report = @"
## 📊 変更サマリー

- 対象コマンド: $commandText
- ステージ済みファイル数: $($stagedFiles.Count)
- push差分ファイル数: $($pushCandidate.files.Count)
- push差分ファイル: $pushTargetSummary
- PHP差分ファイル: $changedPhpSummary
- Linter実行コマンド: $($lint.command)
- 連結 git add 疑似反映: $(if ($simulation.simulationUsed) { '実施' } elseif (-not [string]::IsNullOrWhiteSpace($simulation.simulationError)) { "未実施（$($simulation.simulationError)）" } else { '対象外' })
- push差分取得: $pushDiffStatus

## ✅ 問題なし（Good Points）

$((($goodPoints | ForEach-Object { "- $_" }) -join "`n"))

## ⚠️ 改善推奨（Minor Issues）

$($minorIssueSections -join "`n`n")

## ❌ 修正必須（Critical Issues）

$($criticalIssueSections -join "`n`n")

## 📈 コード品質メトリクス

| 項目 | 現在値 | 目標値 | 状態 |
|-----|-------|-------|------|
| Linter | $($lint.status) | PASS | $metricsLinter |
| High指摘件数 | $highCount | 0 | $(if ($highCount -eq 0) { '✅ OK' } else { '❌ 要修正' }) |
| Medium指摘件数 | $mediumCount | 0 | $metricsReview |

## 🎯 総合評価

### レビュー結果: $reviewResult

**理由**:
$((($reviewReasons | ForEach-Object { "- $_" }) -join "`n"))

### マージ可否: $mergeDecision

**必須修正項目**:
$((($mustFixItems | ForEach-Object { "- $_" }) -join "`n"))

**推奨修正項目**:
$((($recommendedItems | ForEach-Object { "- $_" }) -join "`n"))

## 📋 Next Steps

### 開発者へのアクションアイテム

1. **優先度: 高（実行前に必須）**
$((($mustFixItems | ForEach-Object { "- $_" }) -join "`n"))

2. **優先度: 中（できれば修正）**
$((($recommendedItems | ForEach-Object { "- $_" }) -join "`n"))

3. **ユーザー確認**
- 判定: 要改善（中断して改善） / 今回は進める
- 追加コメント: 任意

要改善にする場合は、この操作を中断してから改善を実施します。
"@

    $reportPath = '.docs/hooks/pretool-review-last-report.md'
    $reportDir = Split-Path -Path $reportPath -Parent
    if (-not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    Set-Content -LiteralPath $reportPath -Value $report -Encoding UTF8

    $lintTail = if ([string]::IsNullOrWhiteSpace($lint.output)) { '(出力なし)' } else { ($lint.output -split "`r?`n" | Select-Object -First 20) -join "`n" }

    if ($mustFix -or $mediumCount -gt 0) {
        $systemMessage = @"
[PreToolUse Quality Gate]
コミット/PR/push 操作の前チェック結果です。以下レポート書式で確認してください。

$report

Linter実行コマンド: $($lint.command)
Linter抜粋:
$lintTail

対応ルール:
1) ユーザーへ上記レポートを提示し、要改善か否かを確認
2) 要改善なら現在操作を中断して改善を実施
3) 追加コメントを受け取り、改善方針へ反映
推奨: /pre-commit-pr-review-gate を利用
"@

        Write-Output (New-HookResponse -Continue $true -SystemMessage $systemMessage -PermissionDecision 'ask' -PermissionReason 'コミット/PR/push 前のレビューで改善候補が検出されました')
        exit 0
    }

    $statusSummary = if ($lint.status -eq 'SKIP' -and $phpFiles.Count -eq 0) {
        '対象なし（PHP差分がないためチェック対象外）'
    } else {
        'チェックOK（阻害要因なし）'
    }

    $passSystemMessage = @"
[PreToolUse Quality Gate]
判定: $statusSummary

- 対象コマンド: $commandText
- ステージ済みファイル数: $($stagedFiles.Count)
- push差分ファイル数: $($pushCandidate.files.Count)
- PHP差分ファイル数: $($phpFiles.Count)
- Linter: $($lint.status)
- High指摘件数: $highCount
- Medium指摘件数: $mediumCount

詳細レポート: .docs/hooks/pretool-review-last-report.md
"@

    Write-Output (New-HookResponse -Continue $true -SystemMessage $passSystemMessage)
    exit 0
} catch {
    Write-Output (New-HookResponse -Continue $true)
    exit 0
}
