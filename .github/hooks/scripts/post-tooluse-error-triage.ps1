$ErrorActionPreference = 'Stop'

function New-ContinueResponse {
    param(
        [string]$SystemMessage = ''
    )

    $response = @{
        continue = $true
    }

    if ($SystemMessage -ne '') {
        $response.systemMessage = $SystemMessage
    }

    return ($response | ConvertTo-Json -Depth 8 -Compress)
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

try {
    $rawInput = [Console]::In.ReadToEnd()

    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Output (New-ContinueResponse)
        exit 0
    }

    $payload = $rawInput | ConvertFrom-Json -Depth 100

    $toolName = Get-PropValue -Object $payload -PathCandidates @(
        'toolName',
        'tool_name',
        'tool.name',
        'toolCall.name'
    )

    if ($null -eq $toolName -or [string]::IsNullOrWhiteSpace([string]$toolName)) {
        $toolName = 'unknown-tool'
    }

    $isError = $false
    $isErrorCandidate = Get-PropValue -Object $payload -PathCandidates @(
        'isError',
        'toolResult.isError',
        'result.isError',
        'toolCall.result.isError'
    )

    if ($isErrorCandidate -is [bool]) {
        $isError = $isErrorCandidate
    }

    $exitCode = Get-PropValue -Object $payload -PathCandidates @(
        'exitCode',
        'toolResult.exitCode',
        'result.exitCode',
        'toolCall.result.exitCode'
    )

    if ($exitCode -ne $null) {
        try {
            if ([int]$exitCode -ne 0) {
                $isError = $true
            }
        } catch {
        }
    }

    $errorText = Get-PropValue -Object $payload -PathCandidates @(
        'error',
        'toolResult.error',
        'result.error',
        'toolCall.result.error',
        'stderr',
        'toolResult.stderr',
        'result.stderr'
    )

    $stdoutText = Get-PropValue -Object $payload -PathCandidates @(
        'stdout',
        'toolResult.stdout',
        'result.stdout'
    )

    if ($null -ne $errorText -and -not [string]::IsNullOrWhiteSpace([string]$errorText)) {
        $isError = $true
    }

    if (-not $isError) {
        Write-Output (New-ContinueResponse)
        exit 0
    }

    $workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $logDir = Join-Path $workspaceRoot '.docs\hooks'
    $logFile = Join-Path $logDir 'tool-error-history.jsonl'

    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $event = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        hookEvent = 'PostToolUse'
        toolName = [string]$toolName
        exitCode = $exitCode
        error = if ($null -eq $errorText) { '' } else { [string]$errorText }
        stdout = if ($null -eq $stdoutText) { '' } else { [string]$stdoutText }
        source = 'hooks/post-tooluse-error-triage'
    }

    ($event | ConvertTo-Json -Depth 8 -Compress) | Add-Content -LiteralPath $logFile -Encoding UTF8

    $systemMessage = @"
[PostToolUse Error Triage]
ツールエラーを検知しました。再発防止のため、以下の順で対応してください。
1) .docs/hooks/tool-error-history.jsonl の最新イベントを確認する
2) Instructions / Skills / Agents / Prompts への更新候補を抽出する
3) 次の4点を必ず提示して、ユーザー確認を取る
   - 起きた事象
   - アップデート内容
   - 理由
   - 期待される効果
4) 採用可否は選択式で確認する（採用 / 見送り / 保留）
5) 追加コメント入力を受け付ける
6) ユーザー承認後のみ更新する
推奨: /review-error-prevention を利用して確認フローを実行する。
"@

    Write-Output (New-ContinueResponse -SystemMessage $systemMessage)
    exit 0
} catch {
    Write-Output (New-ContinueResponse)
    exit 0
}
