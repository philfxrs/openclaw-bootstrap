# lib-win/verify.ps1 — 安装验证模块（Windows）
# -------------------------------------------------------
# 用法：. "$PSScriptRoot\verify.ps1"
#        Invoke-Verify

. "$PSScriptRoot\logger.ps1"

function Test-CommandAvailable {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ---- 验证 Node.js ----------------------------------------------
function Confirm-Node {
    $minMajor = if ($env:OPENCLAW_NODE_MIN_MAJOR) { [int]$env:OPENCLAW_NODE_MIN_MAJOR } else { 18 }
    if (-not (Test-CommandAvailable "node")) {
        Write-LogError "Node.js 未找到，安装可能未完成。"
        Write-LogHint  "请运行：.\install.ps1 repair"
        return $false
    }
    $versionStr = (node --version 2>$null) -replace '^v', ''
    $major = ([int]($versionStr -split '\.')[0])
    if ($major -lt $minMajor) {
        Write-LogError "Node.js 版本（v$versionStr）低于最低要求 v$minMajor。"
        Write-LogHint  "请运行：winget upgrade OpenJS.NodeJS.LTS  或  scoop update nodejs-lts"
        return $false
    }
    Write-LogOk "Node.js 已安装（v$versionStr），版本符合要求。"
    return $true
}

# ---- 验证 Git --------------------------------------------------
function Confirm-Git {
    if (-not (Test-CommandAvailable "git")) {
        Write-LogError "Git 未找到。"
        Write-LogHint  "请运行：.\install.ps1 repair"
        return $false
    }
    Write-LogOk "Git 已安装（$(git --version 2>$null)）"
    return $true
}

# ---- 验证 OpenClaw ---------------------------------------------
function Confirm-OpenClaw {
    if (-not (Test-CommandAvailable "openclaw")) {
        Write-LogError "openclaw 命令未找到。"
        Write-LogHint  "请查阅安装日志，或运行：.\install.ps1 repair"
        return $false
    }
    $ver = & openclaw --version 2>$null
    Write-LogOk "OpenClaw 已安装（$($ver ?? '版本未知')）"

    try {
        & openclaw --help 2>&1 | Out-Null
        Write-LogOk "openclaw --help 响应正常。"
    } catch {
        Write-LogWarn "openclaw --help 返回异常，请查阅官方文档排查。"
    }
    return $true
}

# ---- 验证配置文件 ----------------------------------------------
function Confirm-ConfigFile {
    $cfgDir  = if ($env:OPENCLAW_CONFIG_DIR) { $env:OPENCLAW_CONFIG_DIR } else { Join-Path $env:APPDATA "openclaw" }
    $cfgFile = Join-Path $cfgDir "config.json"
    if (Test-Path $cfgFile) {
        Write-LogOk "配置文件存在：$cfgFile"
    } else {
        Write-LogWarn "配置文件未找到：$cfgFile"
        Write-LogHint  "可运行：.\install.ps1 config  来重新生成默认配置。"
    }
}

# ---- 汇总入口 --------------------------------------------------
function Invoke-Verify {
    Write-LogSection "验证安装结果"
    $failed = 0

    if (-not (Confirm-Git))       { $failed++ }
    if (-not (Confirm-Node))      { $failed++ }
    if (-not (Confirm-OpenClaw))  { $failed++ }
    Confirm-ConfigFile

    Write-Host ""
    if ($failed -eq 0) {
        Write-LogOk "✅ 所有验证项通过！OpenClaw 已就绪。"
        Write-LogHint "运行 'openclaw --help' 查看可用命令。"
    } else {
        Write-LogError "❌ 有 $failed 项验证未通过，请按上述提示修复。"
        Write-LogHint  "如需一键修复，请运行：.\install.ps1 repair"
        return $false
    }
    return $true
}
