# ============================================================================
# Lib.Install.ps1 — OpenClaw Bootstrap 安装模块 (Windows)
# ============================================================================
# 负责调用官方安装链路完成 OpenClaw 安装。
# ============================================================================

if ($Script:LibInstallLoaded) { return }
$Script:LibInstallLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

# ========================================
# 主安装入口
# ========================================

function Invoke-Install {
    Write-Step "开始安装 OpenClaw..."

    # 检查是否已安装
    if (Test-CommandExists "openclaw") {
        $installedVersion = try { openclaw --version 2>$null } catch { "未知" }
        Write-Warn "检测到已安装 OpenClaw (版本: $installedVersion)"

        if ($Script:NonInteractive) {
            Write-Info "非交互模式，跳过已安装版本，不执行重复安装。"
            Write-Info "如需升级，请使用 -Upgrade 参数。"
            return $true
        }

        Write-Host ""
        Write-Host "检测到 OpenClaw 已安装（版本: $installedVersion）。"
        Write-Host "请选择操作:"
        Write-Host "  1) 跳过安装"
        Write-Host "  2) 升级到最新版本"
        Write-Host "  3) 修复当前安装"
        Write-Host "  4) 重置配置"
        Write-Host ""
        Write-Host "请输入选项 [1/2/3/4] (默认: 1): " -ForegroundColor Cyan -NoNewline
        $choice = Read-Host
        if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }

        switch ($choice) {
            "1" { Write-Info "用户选择跳过安装。"; return $true }
            "2" {
                Write-Info "用户选择升级，切换到升级流程..."
                . (Join-Path $PSScriptRoot "Lib.Upgrade.ps1")
                return (Invoke-Upgrade)
            }
            "3" {
                Write-Info "用户选择修复，切换到修复流程..."
                . (Join-Path $PSScriptRoot "Lib.Repair.ps1")
                return (Invoke-Repair)
            }
            "4" {
                Write-Info "用户选择重置配置..."
                . (Join-Path $PSScriptRoot "Lib.Config.ps1")
                return (Reset-OpenClawConfig)
            }
            default { Write-Info "无效选项，跳过安装。"; return $true }
        }
    }

    if (-not (Test-CommandExists "node")) {
        Write-ErrorDetail `
            -Title "无法安装 OpenClaw" `
            -Reason "Node.js 未安装，OpenClaw 安装需要 Node.js 环境。" `
            -Impact "安装无法继续。" `
            -FixSteps "1. 请先安装 Node.js 22 或更高版本`n2. 安装完成后重新打开终端`n3. 再次运行本安装脚本" `
            -FixCommands "- winget install OpenJS.NodeJS.LTS`n- 或访问 https://nodejs.org 下载"
        return $false
    }

    return (Start-OpenClawInstall)
}

function Start-OpenClawInstall {
    Write-Step "正在安装 OpenClaw..."

    # TODO: confirm official install command
    $installCmd = "npm install -g openclaw"
    $installSource = "https://registry.npmjs.org"

    if (-not (Test-UrlDomainAllowed $installSource)) {
        Write-Err "安装源域名校验失败，中止安装。"
        return $false
    }

    Write-Info "安装命令: $installCmd"
    Write-Info "安装源: $installSource"

    try {
        $output = Invoke-Expression $installCmd 2>&1
        $output | ForEach-Object { Write-Host $_ }
        Write-LogEntry "INFO" "安装命令输出: $($output -join "`n")"

        if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
            throw "安装命令返回非零退出码: $LASTEXITCODE"
        }
    } catch {
        Write-ErrorDetail `
            -Title "OpenClaw 安装失败" `
            -Reason "安装命令执行失败: $($_.Exception.Message)" `
            -Impact "OpenClaw 未成功安装。" `
            -FixSteps "1. 检查网络连接`n2. 检查 npm 是否正常工作`n3. 查看日志文件了解详细错误`n4. 尝试手动执行: $installCmd" `
            -FixCommands "- npm cache clean --force`n- $installCmd"
        return $false
    }

    return (Test-InstallResult)
}

function Test-InstallResult {
    Write-Step "验证安装结果..."

    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

    # TODO: confirm openclaw CLI command name
    if (Test-CommandExists "openclaw") {
        $version = try { openclaw --version 2>$null } catch { "未知" }
        Write-Success "OpenClaw 安装成功！版本: $version"
        return $true
    }

    Write-Warn "openclaw 命令未找到，可能需要重新打开 PowerShell 终端。"

    $possiblePaths = @()
    if (Test-CommandExists "npm") {
        $npmPrefix = try { npm config get prefix 2>$null } catch { "" }
        if (-not [string]::IsNullOrEmpty($npmPrefix)) {
            $possiblePaths += Join-Path $npmPrefix "openclaw.cmd"
            $possiblePaths += Join-Path $npmPrefix "openclaw"
        }
    }
    $possiblePaths += Join-Path $env:APPDATA "npm\openclaw.cmd"

    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            $dir = Split-Path $p -Parent
            Write-Info "在 $dir 找到 openclaw，但可能不在当前 PATH 中。"
            Write-ErrorDetail `
                -Title "PATH 配置需要更新" `
                -Reason "OpenClaw 已安装到 $dir，但该目录不在 PATH 中。" `
                -Impact "在当前终端中无法直接运行 openclaw 命令。" `
                -FixSteps "1. 关闭当前 PowerShell 窗口`n2. 重新打开一个新的 PowerShell 窗口`n3. 如仍不可用，手动将路径添加到用户 PATH" `
                -FixCommands "`$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')`n[Environment]::SetEnvironmentVariable('PATH', "`$userPath;$dir`", 'User')"
            return $false
        }
    }

    Write-ErrorDetail `
        -Title "安装验证失败" `
        -Reason "安装命令已执行但未找到 openclaw 可执行文件。" `
        -Impact "安装可能未成功完成。" `
        -FixSteps "1. 查看上方安装输出是否有错误`n2. 检查日志文件`n3. 尝试手动安装`n4. 重新打开终端再试" `
        -FixCommands "- npm list -g openclaw`n- where.exe openclaw"
    return $false
}
