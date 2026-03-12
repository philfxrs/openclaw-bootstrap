#Requires -Version 5
# install.ps1 — OpenClaw Bootstrap 主入口（Windows）
# ==========================================================
# 用法：
#   .\install.ps1              # 全新安装
#   .\install.ps1 install      # 同上
#   .\install.ps1 upgrade      # 升级 OpenClaw 及依赖
#   .\install.ps1 repair       # 修复/重新安装缺失组件
#   .\install.ps1 config       # 重新生成默认配置
#   .\install.ps1 reset        # 重置为出厂配置
#   .\install.ps1 verify       # 仅执行安装验证
#   .\install.ps1 help         # 显示帮助
#
# 环境变量：
#   OPENCLAW_NONINTERACTIVE=1    跳过交互确认
#   OPENCLAW_REQUIRED_DISK_MB    最小磁盘需求（MB，默认 2048）
#   OPENCLAW_NODE_MIN_MAJOR      Node.js 最低主版本（默认 18）
#   OPENCLAW_CONFIG_DIR          配置目录（默认 %APPDATA%\openclaw）
# ==========================================================

param(
    [Parameter(Position = 0)]
    [string]$Command = "install"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---- 加载模块 --------------------------------------------------
. "$ScriptDir\lib-win\logger.ps1"
. "$ScriptDir\lib-win\preflight.ps1"
. "$ScriptDir\lib-win\installer.ps1"
. "$ScriptDir\lib-win\config.ps1"
. "$ScriptDir\lib-win\verify.ps1"
. "$ScriptDir\lib-win\upgrade.ps1"

# ---- 帮助信息 --------------------------------------------------
function Show-Help {
    Write-Host @"

OpenClaw Bootstrap 安装器（Windows）

用法：
  .\install.ps1 [命令]

命令：
  install    （默认）全新安装：预检 → 安装 → 配置 → 验证
  upgrade    升级 OpenClaw 及所有依赖
  repair     修复/重新安装缺失组件
  config     重新初始化配置文件
  reset      重置为出厂默认配置（会备份旧配置）
  verify     仅验证当前安装状态
  help       显示此帮助

环境变量：
  OPENCLAW_NONINTERACTIVE=1    跳过所有交互确认
  OPENCLAW_REQUIRED_DISK_MB    安装所需最小磁盘空间（MB）
  OPENCLAW_NODE_MIN_MAJOR      Node.js 最低主版本号
  OPENCLAW_CONFIG_DIR          覆盖默认配置目录

"@
}

# ---- 操作系统检测 ----------------------------------------------
function Assert-Windows {
    if ($IsLinux -or $IsMacOS) {
        Write-LogError "此脚本仅支持 Windows。"
        Write-LogHint  "macOS/Linux 用户请运行：bash install.sh"
        exit 1
    }
}

# ---- 全新安装流程 ----------------------------------------------
function Invoke-FullInstall {
    Write-LogBanner "OpenClaw Bootstrap — 全新安装"
    Invoke-PreflightChecks
    $ok = Invoke-Install
    if (-not $ok) {
        Write-LogFatal "安装步骤失败，请查阅上方错误信息并重试。"
    }
    Invoke-Config
    Invoke-Verify
    Write-Host ""
    Write-LogOk "🎉 OpenClaw 安装完成！"
    Write-LogHint "运行 'openclaw --help' 开始使用。"
}

# ---- 主分发逻辑 ------------------------------------------------
Assert-Windows

switch ($Command.ToLower()) {
    "install" { Invoke-FullInstall }
    "upgrade" { Invoke-Upgrade }
    "repair"  { Invoke-Repair }
    "config"  { Invoke-Config }
    "reset"   { Invoke-Reset }
    "verify"  { Invoke-Verify }
    { $_ -in "help", "--help", "-h" } { Show-Help }
    default {
        Write-LogError "未知命令：$Command"
        Show-Help
        exit 1
    }
}
