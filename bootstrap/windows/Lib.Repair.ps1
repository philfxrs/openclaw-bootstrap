# ============================================================================
# Lib.Repair.ps1 — OpenClaw Bootstrap 修复模块 (Windows)
# ============================================================================
# 负责修复 PATH、依赖缺失、配置损坏、安装不完整等问题。
# ============================================================================

if ($Script:LibRepairLoaded) { return }
$Script:LibRepairLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

function Invoke-Repair {
    Write-Step "开始诊断与修复..."
    Write-Host ""

    $issuesFound = 0

    if (-not (Repair-PathEnvironment)) { $issuesFound++ }
    if (-not (Repair-NodeJs))          { $issuesFound++ }
    if (-not (Repair-Installation))    { $issuesFound++ }
    if (-not (Repair-Configuration))   { $issuesFound++ }
    Repair-ExecutionPolicyIssue

    Write-Host ""
    Write-Host "========================================"
    if ($issuesFound -eq 0) {
        Write-Host "  修复完成，未发现需要修复的问题。" -ForegroundColor Green
    } else {
        Write-Host "  修复完成，处理了 $issuesFound 个问题。" -ForegroundColor Yellow
        Write-Host "  建议运行验证确认: .\install-openclaw-windows.ps1 -Verify"
    }
    Write-Host "========================================"
    Write-Host ""

    return $true
}

function Repair-PathEnvironment {
    Write-Info "检查 PATH..."

    if (-not (Test-CommandExists "npm")) {
        Write-Warn "npm 不可用，跳过 PATH 修复。"
        return $true
    }

    $npmPrefix = try { npm config get prefix 2>$null } catch { "" }
    if ([string]::IsNullOrEmpty($npmPrefix)) {
        Write-Warn "无法获取 npm 全局目录。"
        return $true
    }

    if ($env:PATH -like "*$npmPrefix*") {
        Write-Success "  \u221a PATH 正常"
        return $true
    }

    Write-Warn "  npm 全局目录不在 PATH 中: $npmPrefix"

    if (Confirm-UserAction "是否将 $npmPrefix 添加到用户 PATH？") {
        try {
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -notlike "*$npmPrefix*") {
                [Environment]::SetEnvironmentVariable("PATH", "$userPath;$npmPrefix", "User")
                $env:PATH = "$env:PATH;$npmPrefix"
                Write-Success "  已添加到用户 PATH"
                Write-Info "  请重新打开 PowerShell 窗口使更改完全生效。"
            } else {
                Write-Info "  用户 PATH 中已包含该路径（可能是进程级 PATH 未同步）。"
            }
            return $true
        } catch {
            Write-Err "  添加 PATH 失败: $($_.Exception.Message)"
            Write-Host "  手动修复: 在系统环境变量中将 $npmPrefix 添加到 PATH"
            return $false
        }
    } else {
        Write-Info "  跳过 PATH 修复。"
        Write-Host "  手动修复:"
        Write-Host "  `$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')"
        Write-Host "  [Environment]::SetEnvironmentVariable('PATH', "`$userPath;$npmPrefix`", 'User')"
        return $false
    }
}

function Repair-NodeJs {
    Write-Info "检查 Node.js..."

    if (-not (Test-CommandExists "node")) {
        Write-ErrorDetail `
            -Title "Node.js 未安装" `
            -Reason "系统中未找到 node 命令。" `
            -Impact "OpenClaw 无法运行。" `
            -FixSteps "1. 安装 Node.js 22 或更高版本`n2. 重新打开终端" `
            -FixCommands "- winget install OpenJS.NodeJS.LTS`n- 或访问 https://nodejs.org 下载"
        return $false
    }

    $nodeVersion = (node --version 2>$null) -replace '^v', ''

    $minVersion = "22.0.0"
    $policy = Read-JsonFile $Script:VersionPolicyFile
    if ($null -ne $policy -and -not [string]::IsNullOrEmpty($policy.minimum_node_version)) {
        $minVersion = $policy.minimum_node_version
    }

    if ((Compare-Version $nodeVersion $minVersion) -ge 0) {
        Write-Success "  \u221a Node.js 版本正常: v$nodeVersion"
        return $true
    }

    Write-Warn "  Node.js 版本过低: v$nodeVersion (要求 >= v$minVersion)"
    Write-Host "  建议升级: winget upgrade OpenJS.NodeJS.LTS"
    return $false
}

function Repair-Installation {
    Write-Info "检查 OpenClaw 安装..."

    # TODO: confirm openclaw CLI command name
    if (Test-CommandExists "openclaw") {
        try {
            $null = openclaw --version 2>$null
            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                Write-Success "  \u221a OpenClaw 安装正常"
                return $true
            }
        } catch {
            # 继续
        }

        Write-Warn "  openclaw 命令存在但执行异常"
        if (Confirm-UserAction "是否尝试重新安装？") {
            . (Join-Path $PSScriptRoot "Lib.Install.ps1")
            return (Start-OpenClawInstall)
        }
        return $false
    }

    Write-Warn "  openclaw 命令未找到"

    # 尝试刷新 PATH 后重试
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    if (Test-CommandExists "openclaw") {
        Write-Success "  \u221a 刷新 PATH 后找到 openclaw"
        Write-Info "  建议重新打开 PowerShell 窗口。"
        return $true
    }

    if (Confirm-UserAction "是否执行安装？") {
        . (Join-Path $PSScriptRoot "Lib.Install.ps1")
        return (Start-OpenClawInstall)
    }
    return $false
}

function Repair-Configuration {
    Write-Info "检查配置文件..."

    if (-not (Test-Path $Script:ConfigDir)) {
        Write-Warn "  配置目录不存在，创建中..."
        try {
            New-Item -ItemType Directory -Path $Script:ConfigDir -Force | Out-Null
            Write-Success "  \u221a 配置目录已创建: $Script:ConfigDir"
        } catch {
            Write-Err "  X 无法创建配置目录: $Script:ConfigDir"
            return $false
        }
    }

    # TODO: confirm config file name
    $configFile = Join-Path $Script:ConfigDir "config.json"
    if (-not (Test-Path $configFile)) {
        Write-Warn "  配置文件不存在"
        if (Confirm-UserAction "是否从模板创建默认配置？") {
            $template = Join-Path $Script:ProjectRoot "templates\config.default.json"
            if (Test-Path $template) {
                Copy-Item -Path $template -Destination $configFile -Force
                Write-Success "  \u221a 默认配置已创建"
            } else {
                Write-Err "  X 配置模板不存在: $template"
                return $false
            }
        }
    } else {
        Write-Success "  \u221a 配置文件存在"
    }

    return $true
}

function Repair-ExecutionPolicyIssue {
    Write-Info "检查 ExecutionPolicy..."

    $effectivePolicy = Get-ExecutionPolicy
    if ($effectivePolicy -in @("Unrestricted", "RemoteSigned", "Bypass")) {
        Write-Success "  \u221a ExecutionPolicy 正常: $effectivePolicy"
        return
    }

    Write-Warn "  ExecutionPolicy 为 $effectivePolicy，可能影响脚本执行"
    Write-Host ""
    Write-Host "  建议修复方式（选择其一）："
    Write-Host "  1. 设置当前用户策略（推荐，安全风险低）："
    Write-Host "     Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser"
    Write-Host ""
    Write-Host "  2. 仅针对当前进程临时放开（最安全，仅当前会话有效）："
    Write-Host "     Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process"
    Write-Host ""
    Write-Host "  注意: 不建议修改 LocalMachine 级别的 ExecutionPolicy，"
    Write-Host "  这会影响所有用户，修改前请评估安全风险。"
}
