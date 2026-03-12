# lib-win/logger.ps1 — 日志工具（颜色输出 + 中文友好提示）
# -------------------------------------------------------
# 用法：. "$PSScriptRoot\logger.ps1"

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Cyan
}

function Write-LogStep {
    param([string]$Message)
    Write-Host "[步骤]  $Message" -ForegroundColor Blue
}

function Write-LogOk {
    param([string]$Message)
    Write-Host "[✔  OK]  $Message" -ForegroundColor Green
}

function Write-LogWarn {
    param([string]$Message)
    Write-Warning "[警告]  $Message"
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[错误]  $Message" -ForegroundColor Red -BackgroundColor Black
}

function Write-LogFatal {
    param([string]$Message)
    Write-Host "[致命]  $Message" -ForegroundColor Red -BackgroundColor Black
    Write-Host "如需帮助，请访问：https://github.com/philfxrs/openclaw-bootstrap/issues" -ForegroundColor Yellow
    exit 1
}

function Write-LogHint {
    param([string]$Message)
    Write-Host "[提示]  $Message" -ForegroundColor Yellow
}

function Write-LogBanner {
    param([string]$Text)
    $line = "─" * 50
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host $line -ForegroundColor Cyan
}

function Write-LogSection {
    param([string]$Text)
    Write-Host ""
    Write-Host "▶ $Text" -ForegroundColor White
}
