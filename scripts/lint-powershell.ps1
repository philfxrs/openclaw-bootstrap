# lint-powershell.ps1 — 使用 PSScriptAnalyzer 对 Windows 脚本进行静态检查
# 用法: pwsh scripts/lint-powershell.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$WindowsDir = Join-Path $ProjectRoot "bootstrap\windows"

# 检查 PSScriptAnalyzer
$hasAnalyzer = Get-Module -ListAvailable -Name PSScriptAnalyzer
if (-not $hasAnalyzer) {
    Write-Host "[错误] 未找到 PSScriptAnalyzer，请先安装：" -ForegroundColor Red
    Write-Host "  Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force"
    exit 1
}

Import-Module PSScriptAnalyzer

Write-Host "=========================================="
Write-Host " PSScriptAnalyzer 代码检查"
Write-Host "=========================================="
Write-Host ""

$errors = 0
$checked = 0

$files = Get-ChildItem -Path $WindowsDir -Filter "*.ps1" -File
foreach ($f in $files) {
    $checked++
    Write-Host "  检查 $($f.Name) ... " -NoNewline

    $results = Invoke-ScriptAnalyzer -Path $f.FullName -Severity @('Error', 'Warning') -ExcludeRule @(
        'PSAvoidUsingWriteHost'
    )

    if ($results.Count -eq 0) {
        Write-Host "通过" -ForegroundColor Green
    }
    else {
        Write-Host "失败" -ForegroundColor Red
        Write-Host ""
        $results | Format-Table -Property Severity, RuleName, Line, Message -AutoSize
        Write-Host ""
        $errors++
    }
}

Write-Host ""
Write-Host "=========================================="
if ($errors -eq 0) {
    Write-Host "全部通过 ($checked 个文件)" -ForegroundColor Green
}
else {
    Write-Host "$errors 个文件有问题 (共 $checked 个文件)" -ForegroundColor Red
    exit 1
}
