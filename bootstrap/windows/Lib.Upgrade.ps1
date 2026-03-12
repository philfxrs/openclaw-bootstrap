# ============================================================================
# Lib.Upgrade.ps1 — OpenClaw Bootstrap 升级模块 (Windows)
# ============================================================================
# 负责执行 OpenClaw 升级、版本检测、回滚建议。
# ============================================================================

if ($Script:LibUpgradeLoaded) { return }
$Script:LibUpgradeLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

function Invoke-Upgrade {
    Write-Step "开始升级 OpenClaw..."

    if (-not (Test-CommandExists "openclaw")) {
        Write-Err "未检测到已安装的 OpenClaw，无法升级。"
        Write-Info "请先执行安装: .\install-openclaw-windows.ps1 -Install"
        return $false
    }

    $currentVersion = try { openclaw --version 2>$null } catch { "未知" }
    Write-Info "当前版本: $currentVersion"

    $policy = Read-JsonFile $Script:VersionPolicyFile
    $backupBefore = $true
    if ($null -ne $policy -and $null -ne $policy.upgrade_policy) {
        $backupBefore = $policy.upgrade_policy.backup_before_upgrade
    }

    # TODO: confirm how to check latest version
    Write-Info "检查最新版本..."
    Write-Warn "TODO: 获取最新版本的具体方式待确认"

    if ($backupBefore) {
        Backup-BeforeUpgrade
    }

    Write-LogEntry "INFO" "升级前版本: $currentVersion"

    if (-not (Start-OpenClawUpgrade)) {
        Write-Err "升级失败！"
        Show-RollbackGuidance $currentVersion
        return $false
    }

    Write-Step "升级后验证..."
    . (Join-Path $PSScriptRoot "Lib.Verify.ps1")
    if (Invoke-Verify) {
        $newVersion = try { openclaw --version 2>$null } catch { "未知" }
        Write-Success "升级成功！$currentVersion -> $newVersion"
    } else {
        Write-Warn "升级后验证存在警告，请检查。"
        Show-RollbackGuidance $currentVersion
    }

    return $true
}

function Backup-BeforeUpgrade {
    Write-Step "备份当前配置..."

    if (Test-Path $Script:ConfigDir) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "$($Script:ConfigDir).pre-upgrade.$timestamp"
        try {
            Copy-Item -Path $Script:ConfigDir -Destination $backupDir -Recurse -Force
            Write-Success "配置已备份到: $backupDir"
        } catch {
            Write-Warn "配置备份失败: $($_.Exception.Message)"
        }
    } else {
        Write-Info "配置目录不存在，跳过备份。"
    }
}

function Start-OpenClawUpgrade {
    # TODO: confirm official upgrade command
    $upgradeCmd = "npm update -g openclaw"

    Write-Info "升级命令: $upgradeCmd"

    try {
        $output = Invoke-Expression $upgradeCmd 2>&1
        $output | ForEach-Object { Write-Host $_ }
        Write-LogEntry "INFO" "升级命令输出: $($output -join "`n")"

        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            throw "升级命令返回非零退出码: $LASTEXITCODE"
        }
        return $true
    } catch {
        Write-ErrorDetail `
            -Title "OpenClaw 升级失败" `
            -Reason "升级命令执行失败: $($_.Exception.Message)" `
            -Impact "OpenClaw 可能仍停留在旧版本。" `
            -FixSteps "1. 检查网络连接`n2. 检查 npm 是否正常`n3. 查看日志文件`n4. 尝试手动升级: $upgradeCmd" `
            -FixCommands "- npm cache clean --force`n- $upgradeCmd"
        return $false
    }
}

function Show-RollbackGuidance {
    param([string]$PreviousVersion)

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "  升级回滚指引" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "如果升级后出现问题，你可以尝试以下操作:"
    Write-Host ""
    Write-Host "1. 回退到之前的版本:"
    Write-Host "   npm install -g openclaw@$PreviousVersion"
    Write-Host ""
    Write-Host "2. 恢复配置备份:"
    Write-Host "   查看 $($Script:ConfigDir).pre-upgrade.* 目录"
    Write-Host "   Copy-Item -Path <备份目录> -Destination $Script:ConfigDir -Recurse -Force"
    Write-Host ""
    Write-Host "3. 运行修复:"
    Write-Host "   .\install-openclaw-windows.ps1 -Repair"
    Write-Host ""
    Write-Host "4. 查看日志:"
    Write-Host "   $Script:LogFile"
    Write-Host ""
}
