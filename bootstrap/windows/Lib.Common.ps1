# ============================================================================
# Lib.Common.ps1 — OpenClaw Bootstrap 公共函数库 (Windows)
# ============================================================================
# 提供统一的输出、日志、工具函数，供所有模块引用。
# ============================================================================

# 防止重复加载
if ($Script:LibCommonLoaded) { return }
$Script:LibCommonLoaded = $true

# ========================================
# 严格模式
# ========================================
Set-StrictMode -Version Latest

# ========================================
# 全局配置
# ========================================
$Script:BootstrapVersion = "0.1.0"
$Script:BootstrapDir = $PSScriptRoot
$Script:ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

# 日志目录
$Script:LogDir = Join-Path $env:LOCALAPPDATA "openclaw-bootstrap\logs"
$Script:LogFile = ""

# 配置目录
$Script:ConfigDir = Join-Path $env:APPDATA "openclaw"

# 工作目录
$Script:WorkDir = Join-Path $env:USERPROFILE "openclaw"

# 策略文件
$Script:VersionPolicyFile = Join-Path $Script:ProjectRoot "checks\version-policy.json"
$Script:SourceAllowlistFile = Join-Path $Script:ProjectRoot "checks\source-allowlist.json"

# 运行模式
$Script:NonInteractive = $false
$Script:VerboseMode = $false

# 预检结果
$Script:PreflightResults = @()
$Script:PreflightHasFail = $false

# ========================================
# 统一输出函数
# ========================================

function Write-Info {
    param([string]$Message)
    Write-Host "[信息] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
    Write-LogEntry "INFO" $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[成功] " -ForegroundColor Green -NoNewline
    Write-Host $Message
    Write-LogEntry "SUCCESS" $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[警告] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
    Write-LogEntry "WARN" $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "[错误] " -ForegroundColor Red -NoNewline
    Write-Host $Message
    Write-LogEntry "ERROR" $Message
}

function Write-Step {
    param([string]$Message)
    Write-Host "[步骤] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
    Write-LogEntry "STEP" $Message
}

function Write-Dbg {
    param([string]$Message)
    if ($Script:VerboseMode) {
        Write-Host "[调试] " -ForegroundColor Gray -NoNewline
        Write-Host $Message
    }
    Write-LogEntry "DEBUG" $Message
}

# ========================================
# 结构化错误输出
# ========================================

function Write-ErrorDetail {
    param(
        [string]$Title,
        [string]$Reason,
        [string]$Impact,
        [string]$FixSteps,
        [string]$FixCommands = "",
        [string]$LogLocation = ""
    )

    if ([string]::IsNullOrEmpty($LogLocation)) {
        $LogLocation = $Script:LogFile
    }

    Write-Host ""
    Write-Host "[错误] $Title" -ForegroundColor Red
    Write-Host ""
    Write-Host "原因："
    Write-Host "  $Reason"
    Write-Host ""
    Write-Host "影响："
    Write-Host "  $Impact"
    Write-Host ""
    Write-Host "修复步骤："
    $FixSteps -split "`n" | ForEach-Object { Write-Host "  $_" }

    if (-not [string]::IsNullOrEmpty($FixCommands)) {
        Write-Host ""
        Write-Host "建议命令 / 操作："
        $FixCommands -split "`n" | ForEach-Object { Write-Host "  $_" }
    }

    if (-not [string]::IsNullOrEmpty($LogLocation)) {
        Write-Host ""
        Write-Host "日志位置："
        Write-Host "  $LogLocation"
    }
    Write-Host ""

    Write-LogEntry "ERROR_DETAIL" "title=$Title reason=$Reason"
}

# ========================================
# 日志系统
# ========================================

function Initialize-Logging {
    param([string]$LogType = "install")

    $dateStr = Get-Date -Format "yyyy-MM-dd"

    if (-not (Test-Path $Script:LogDir)) {
        try {
            New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
        } catch {
            Write-Host "[警告] 无法创建日志目录: $Script:LogDir" -ForegroundColor Yellow
        }
    }

    $Script:LogFile = Join-Path $Script:LogDir "$LogType-$dateStr.log"

    try {
        if (-not (Test-Path $Script:LogFile)) {
            New-Item -ItemType File -Path $Script:LogFile -Force | Out-Null
        }
    } catch {
        # 静默处理
    }

    Write-LogEntry "INFO" "========== 日志开始 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =========="
    Write-LogEntry "INFO" "Bootstrap 版本: $Script:BootstrapVersion"
    Write-LogEntry "INFO" "操作类型: $LogType"
}

function Write-LogEntry {
    param(
        [string]$Level,
        [string]$Message
    )

    if ([string]::IsNullOrEmpty($Script:LogFile)) { return }

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $entry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $Script:LogFile -Value $entry -ErrorAction SilentlyContinue
    } catch {
        # 日志写入失败静默处理
    }
}

# ========================================
# 预检结果收集
# ========================================

function Add-PreflightPass {
    param([string]$Item, [string]$Detail = "")
    $Script:PreflightResults += [PSCustomObject]@{
        Status = "PASS"; Item = $Item; Detail = $Detail
    }
    Write-Dbg "预检通过: $Item $Detail"
}

function Add-PreflightWarn {
    param([string]$Item, [string]$Detail = "")
    $Script:PreflightResults += [PSCustomObject]@{
        Status = "WARN"; Item = $Item; Detail = $Detail
    }
    Write-Warn "预检警告: $Item - $Detail"
}

function Add-PreflightFail {
    param([string]$Item, [string]$Detail = "")
    $Script:PreflightResults += [PSCustomObject]@{
        Status = "FAIL"; Item = $Item; Detail = $Detail
    }
    $Script:PreflightHasFail = $true
    Write-Err "预检失败: $Item - $Detail"
}

function Show-PreflightReport {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "  环境预检报告"
    Write-Host "========================================"
    Write-Host ""

    foreach ($result in $Script:PreflightResults) {
        switch ($result.Status) {
            "PASS" {
                Write-Host "  " -NoNewline
                Write-Host "\u221a 通过" -ForegroundColor Green -NoNewline
                Write-Host "  $($result.Item)  $($result.Detail)"
            }
            "WARN" {
                Write-Host "  " -NoNewline
                Write-Host "! 警告" -ForegroundColor Yellow -NoNewline
                Write-Host "  $($result.Item)  $($result.Detail)"
            }
            "FAIL" {
                Write-Host "  " -NoNewline
                Write-Host "X 失败" -ForegroundColor Red -NoNewline
                Write-Host "  $($result.Item)  $($result.Detail)"
            }
        }
    }

    Write-Host ""
    Write-Host "========================================"

    if ($Script:PreflightHasFail) {
        Write-Host "  预检未通过，存在阻塞项，请先修复后重试。" -ForegroundColor Red
    } else {
        Write-Host "  预检通过，可以继续安装。" -ForegroundColor Green
    }
    Write-Host "========================================"
    Write-Host ""
}

# ========================================
# 工具函数
# ========================================

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Compare-Version {
    <#
    .SYNOPSIS
    比较两个语义化版本号。返回: 1 = $v1 > $v2, 0 = 相等, -1 = $v1 < $v2
    #>
    param([string]$v1, [string]$v2)

    $v1 = $v1 -replace '^v', ''
    $v2 = $v2 -replace '^v', ''

    $parts1 = $v1 -split '\.' | ForEach-Object { [int]$_ }
    $parts2 = $v2 -split '\.' | ForEach-Object { [int]$_ }

    for ($i = 0; $i -lt 3; $i++) {
        $p1 = if ($i -lt $parts1.Count) { $parts1[$i] } else { 0 }
        $p2 = if ($i -lt $parts2.Count) { $parts2[$i] } else { 0 }
        if ($p1 -gt $p2) { return 1 }
        if ($p1 -lt $p2) { return -1 }
    }
    return 0
}

function Read-JsonFile {
    <#
    .SYNOPSIS
    读取 JSON 文件并返回 PSObject
    #>
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-Dbg "JSON 文件不存在: $Path"
        return $null
    }

    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        return $content | ConvertFrom-Json
    } catch {
        Write-Err "无法解析 JSON: $Path - $($_.Exception.Message)"
        return $null
    }
}

function Confirm-UserAction {
    <#
    .SYNOPSIS
    交互确认。非交互模式下使用默认值。
    #>
    param(
        [string]$Prompt,
        [string]$Default = "n"
    )

    if ($Script:NonInteractive) {
        Write-Dbg "非交互模式，跳过确认: $Prompt (默认: $Default)"
        return ($Default -eq "y")
    }

    $hint = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }

    while ($true) {
        Write-Host "$Prompt $hint`: " -ForegroundColor Cyan -NoNewline
        $answer = Read-Host
        if ([string]::IsNullOrEmpty($answer)) { $answer = $Default }

        switch -Regex ($answer) {
            '^[Yy]' { return $true }
            '^[Nn]' { return $false }
            default { Write-Host "请输入 y 或 n" }
        }
    }
}

function Read-UserInput {
    <#
    .SYNOPSIS
    交互输入。非交互模式下返回默认值。
    #>
    param(
        [string]$Prompt,
        [string]$Default = ""
    )

    if ($Script:NonInteractive) {
        Write-Dbg "非交互模式，使用默认值: $Prompt -> $Default"
        return $Default
    }

    $displayDefault = if (-not [string]::IsNullOrEmpty($Default)) { " (默认: $Default)" } else { "" }
    Write-Host "${Prompt}${displayDefault}: " -ForegroundColor Cyan -NoNewline
    $input_val = Read-Host
    if ([string]::IsNullOrEmpty($input_val)) { return $Default }
    return $input_val
}

function Test-UrlDomainAllowed {
    <#
    .SYNOPSIS
    校验 URL 域名是否在白名单中
    #>
    param([string]$Url)

    # 提取域名
    if ($Url -match '^https?://([^/:]+)') {
        $domain = $Matches[1]
    } else {
        Write-Err "无法从 URL 中提取域名: $Url"
        return $false
    }

    if (-not (Test-Path $Script:SourceAllowlistFile)) {
        Write-Warn "白名单文件不存在: $Script:SourceAllowlistFile"
        return $false
    }

    $allowlist = Read-JsonFile $Script:SourceAllowlistFile
    if ($null -eq $allowlist) { return $false }

    foreach ($allowed in $allowlist.allowed_domains) {
        if ($domain -eq $allowed -or $domain.EndsWith(".$allowed")) {
            Write-Dbg "域名校验通过: $domain (匹配 $allowed)"
            return $true
        }
    }

    Write-Err "域名不在白名单中: $domain"
    return $false
}

function Invoke-SafeDownload {
    <#
    .SYNOPSIS
    安全下载（带白名单校验）
    #>
    param(
        [string]$Url,
        [string]$OutFile = ""
    )

    # 校验初始 URL 域名
    if (-not (Test-UrlDomainAllowed $Url)) {
        Write-ErrorDetail `
            -Title "下载被阻止" `
            -Reason "目标 URL 域名不在可信白名单中: $Url" `
            -Impact "为保护系统安全，安装器拒绝从不可信来源下载文件。" `
            -FixSteps "1. 确认下载地址是否正确`n2. 如需添加新的可信域名，请编辑 checks\source-allowlist.json"
        return $false
    }

    try {
        # 使用 TLS 1.2+
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

        if (-not [string]::IsNullOrEmpty($OutFile)) {
            Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
        } else {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
            return $response.Content
        }

        # 检查最终重定向 URL
        # 注意: PowerShell 的 Invoke-WebRequest 默认跟随重定向
        # 在此处暂不做重定向后的二次域名校验，因为 PowerShell 5.1 获取最终 URL 较复杂
        # TODO: 在 PowerShell 7 中可用 -MaximumRedirection 0 来手动控制重定向

        return $true
    } catch {
        Write-ErrorDetail `
            -Title "下载失败" `
            -Reason "无法从 $Url 下载: $($_.Exception.Message)" `
            -Impact "所需文件未成功下载。" `
            -FixSteps "1. 检查网络连接`n2. 检查是否有代理设置`n3. 检查系统安全软件是否拦截了下载"
        return $false
    }
}

function Backup-File {
    <#
    .SYNOPSIS
    备份文件
    #>
    param([string]$FilePath)

    if (Test-Path $FilePath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$FilePath.backup.$timestamp"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Info "已备份: $FilePath -> $backupPath"
        return $true
    }
    return $false
}

function Test-Checksum {
    <#
    .SYNOPSIS
    校验和验证（预留，待官方提供 checksum 后启用）
    #>
    param(
        [string]$FilePath,
        [string]$ExpectedHash = ""
    )

    if ([string]::IsNullOrEmpty($ExpectedHash)) {
        Write-Dbg "未提供校验和，跳过校验"
        return $true
    }

    $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -eq $ExpectedHash.ToLower()) {
        Write-Dbg "校验和验证通过: $FilePath"
        return $true
    } else {
        Write-Err "校验和不匹配: 期望 $ExpectedHash, 实际 $actualHash"
        return $false
    }
}

function Test-Signature {
    <#
    .SYNOPSIS
    签名校验占位函数
    TODO: 当官方提供签名机制后实现
    #>
    param([string]$FilePath)
    Write-Dbg "签名校验功能尚未启用 (文件: $FilePath)"
    return $true
}

function Show-Banner {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  OpenClaw Bootstrap Installer v$Script:BootstrapVersion" -ForegroundColor Cyan
    Write-Host "  平台: Windows" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Help {
    Show-Banner
    Write-Host "用法: .\install-openclaw-windows.ps1 [选项]"
    Write-Host ""
    Write-Host "选项:"
    Write-Host "  -Install          执行安装 (默认)"
    Write-Host "  -Upgrade          升级已安装的 OpenClaw"
    Write-Host "  -Repair           修复安装问题"
    Write-Host "  -Verify           验证当前安装状态"
    Write-Host "  -ResetConfig      重置配置为默认值"
    Write-Host "  -NonInteractive   非交互模式，使用默认值"
    Write-Host "  -VerboseMode      输出详细调试信息"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\install-openclaw-windows.ps1 -Install"
    Write-Host "  .\install-openclaw-windows.ps1 -Install -NonInteractive"
    Write-Host "  .\install-openclaw-windows.ps1 -Upgrade"
    Write-Host "  .\install-openclaw-windows.ps1 -Verify"
    Write-Host "  .\install-openclaw-windows.ps1 -Repair"
    Write-Host "  .\install-openclaw-windows.ps1 -ResetConfig"
    Write-Host ""
    Write-Host "日志目录: $Script:LogDir"
    Write-Host ""
}
