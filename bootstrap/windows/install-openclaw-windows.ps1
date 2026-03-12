<#
.SYNOPSIS
    OpenClaw Bootstrap Installer (Windows)

.DESCRIPTION
    面向新系统的一键安装与引导配置工具。
    支持安装、升级、修复、验证、配置重置。

.PARAMETER Install
    执行安装 (默认操作)

.PARAMETER Upgrade
    升级已安装的 OpenClaw

.PARAMETER Repair
    修复安装问题

.PARAMETER Verify
    验证当前安装状态

.PARAMETER ResetConfig
    重置配置为默认值

.PARAMETER NonInteractive
    非交互模式，使用默认值

.PARAMETER VerboseMode
    输出详细调试信息

.EXAMPLE
    .\install-openclaw-windows.ps1 -Install
    .\install-openclaw-windows.ps1 -Install -NonInteractive
    .\install-openclaw-windows.ps1 -Upgrade
    .\install-openclaw-windows.ps1 -Verify
    .\install-openclaw-windows.ps1 -Repair
    .\install-openclaw-windows.ps1 -ResetConfig
#>

[CmdletBinding()]
param(
    [switch]$Install,
    [switch]$Upgrade,
    [switch]$Repair,
    [switch]$Verify,
    [switch]$ResetConfig,
    [switch]$NonInteractive,
    [switch]$VerboseMode
)

# ========================================
# 严格模式与错误处理
# ========================================
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 确保 UTF-8 输出
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # 某些环境下可能失败，忽略
}

# ========================================
# 加载模块
# ========================================
$scriptDir = $PSScriptRoot

. (Join-Path $scriptDir "Lib.Common.ps1")
. (Join-Path $scriptDir "Lib.Preflight.ps1")
. (Join-Path $scriptDir "Lib.Install.ps1")
. (Join-Path $scriptDir "Lib.Config.ps1")
. (Join-Path $scriptDir "Lib.Verify.ps1")
. (Join-Path $scriptDir "Lib.Upgrade.ps1")
. (Join-Path $scriptDir "Lib.Repair.ps1")

# ========================================
# 确定操作
# ========================================
$action = "install"

if ($Upgrade)     { $action = "upgrade" }
if ($Repair)      { $action = "repair" }
if ($Verify)      { $action = "verify" }
if ($ResetConfig) { $action = "reset-config" }

# 设置全局选项
$Script:NonInteractive = $NonInteractive.IsPresent
$Script:VerboseMode = $VerboseMode.IsPresent

# ========================================
# 主流程
# ========================================

function Start-Main {
    # 初始化日志
    Initialize-Logging $action

    # 打印横幅
    Show-Banner

    Write-Dbg "操作: $action"
    Write-Dbg "非交互模式: $Script:NonInteractive"
    Write-Dbg "详细模式: $Script:VerboseMode"
    Write-Dbg "脚本目录: $scriptDir"
    Write-Dbg "项目根目录: $Script:ProjectRoot"

    switch ($action) {
        "install"      { Start-InstallFlow }
        "upgrade"      { Start-UpgradeFlow }
        "repair"       { Start-RepairFlow }
        "verify"       { Start-VerifyFlow }
        "reset-config" { Start-ResetConfigFlow }
        default {
            Write-Err "未知操作: $action"
            exit 1
        }
    }
}

# ========================================
# 安装流程
# ========================================

function Start-InstallFlow {
    Write-Step "========== 安装流程开始 =========="

    # 阶段 1: 预检
    Write-Step "[1/4] 环境预检"
    if (-not (Invoke-PreflightChecks)) {
        Write-Err "预检未通过，安装中止。"
        Write-Info "请根据上方报告修复问题后重试。"
        Write-Info "日志文件: $Script:LogFile"
        exit 1
    }

    # 阶段 2: 安装
    Write-Step "[2/4] 执行安装"
    if (-not (Invoke-Install)) {
        Write-Err "安装失败。"
        Write-Info "日志文件: $Script:LogFile"
        exit 1
    }

    # 阶段 3: 配置
    Write-Step "[3/4] 配置向导"
    Invoke-Configure

    # 阶段 4: 验证
    Write-Step "[4/4] 安装验证"
    if (Invoke-Verify) {
        Write-Host ""
        Write-Success "========== 安装完成 =========="
        Write-Host ""
        Write-Host "下一步:"
        Write-Host "  1. 如果修改了 PATH，请重新打开 PowerShell"
        Write-Host "  2. 运行 openclaw --help 了解基本用法"
        Write-Host "  3. 如遇问题，运行 .\install-openclaw-windows.ps1 -Repair"
        Write-Host ""
        Write-Host "日志文件: $Script:LogFile"
    } else {
        Write-Host ""
        Write-Warn "安装已完成但验证存在警告，请检查上方信息。"
        Write-Info "日志文件: $Script:LogFile"
    }
}

# ========================================
# 升级流程
# ========================================

function Start-UpgradeFlow {
    Write-Step "========== 升级流程开始 =========="

    # 简化预检
    Write-Step "[1/2] 环境检查"
    Test-OperatingSystem
    Test-NodeJs
    Test-Npm
    Test-NetworkConnectivity

    if ($Script:PreflightHasFail) {
        Show-PreflightReport
        Write-Err "环境检查未通过，升级中止。"
        exit 1
    }

    # 执行升级
    Write-Step "[2/2] 执行升级"
    if (Invoke-Upgrade) {
        Write-Success "========== 升级完成 =========="
    } else {
        Write-Err "升级过程出现问题，请查看日志。"
        Write-Info "日志文件: $Script:LogFile"
        exit 1
    }
}

# ========================================
# 修复流程
# ========================================

function Start-RepairFlow {
    Write-Step "========== 修复流程开始 =========="
    Invoke-Repair
    Write-Success "========== 修复完成 =========="
    Write-Info "日志文件: $Script:LogFile"
}

# ========================================
# 验证流程
# ========================================

function Start-VerifyFlow {
    Write-Step "========== 验证流程开始 =========="
    if (Invoke-Verify) {
        Write-Success "========== 验证通过 =========="
    } else {
        Write-Warn "========== 验证存在问题 =========="
        Write-Info "运行 .\install-openclaw-windows.ps1 -Repair 尝试修复"
    }
    Write-Info "日志文件: $Script:LogFile"
}

# ========================================
# 重置配置流程
# ========================================

function Start-ResetConfigFlow {
    Write-Step "========== 配置重置 =========="
    Reset-OpenClawConfig
    Write-Info "日志文件: $Script:LogFile"
}

# ========================================
# 全局异常处理与入口
# ========================================

try {
    Start-Main
} catch {
    Write-Host ""
    Write-Host "[严重错误] 安装器遇到未预期的错误" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误信息: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "错误位置: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "请将以下信息反馈给维护者:" -ForegroundColor Yellow
    Write-Host "  1. 上方错误信息"
    Write-Host "  2. 日志文件: $Script:LogFile"
    Write-Host "  3. PowerShell 版本: $($PSVersionTable.PSVersion)"
    Write-Host "  4. Windows 版本: $([System.Environment]::OSVersion.Version)"
    Write-Host ""

    if (-not [string]::IsNullOrEmpty($Script:LogFile)) {
        try {
            Write-LogEntry "FATAL" "未捕获异常: $($_.Exception.Message)"
            Write-LogEntry "FATAL" "Stack Trace: $($_.ScriptStackTrace)"
        } catch {
            # 忽略日志写入失败
        }
    }

    exit 1
}
