# ============================================================================
# Lib.Verify.ps1 — OpenClaw Bootstrap 验证模块 (Windows)
# ============================================================================
# 负责验证安装结果、CLI 可用性、服务运行状态。
# ============================================================================

if ($Script:LibVerifyLoaded) { return }
$Script:LibVerifyLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

function Invoke-Verify {
    Write-Step "开始验证安装状态..."
    Write-Host ""

    $allOk = $true

    if (-not (Test-CliExists))     { $allOk = $false }
    if (-not (Test-CliVersion))    { $allOk = $false }
    if (-not (Test-PathCorrect))   { $allOk = $false }
    if (-not (Test-BasicCommands)) { $allOk = $false }
    Test-DaemonStatus
    Test-ConfigExists

    Write-Host ""
    Write-Host "========================================"
    if ($allOk) {
        Write-Host "  \u221a 验证全部通过" -ForegroundColor Green
    } else {
        Write-Host "  X 验证存在失败项" -ForegroundColor Red
        Write-Host ""
        Write-Host "  修复建议: 运行 .\install-openclaw-windows.ps1 -Repair"
    }
    Write-Host "========================================"
    Write-Host ""

    return $allOk
}

function Test-CliExists {
    Write-Info "检查 openclaw 命令是否存在..."

    # TODO: confirm openclaw CLI command name
    if (Test-CommandExists "openclaw") {
        $cmdPath = (Get-Command "openclaw" -ErrorAction SilentlyContinue).Source
        Write-Success "  \u221a openclaw 命令已找到: $cmdPath"
        return $true
    }

    Write-Err "  X openclaw 命令未找到"
    Write-ErrorDetail `
        -Title "openclaw 命令不存在" `
        -Reason "在 PATH 中未找到 openclaw 可执行文件。" `
        -Impact "无法使用 OpenClaw CLI。" `
        -FixSteps "1. 检查是否已正确安装`n2. 检查 PATH 环境变量`n3. 尝试重新打开 PowerShell`n4. 尝试重新安装" `
        -FixCommands "- where.exe openclaw`n- `$env:PATH -split ';'`n- npm list -g openclaw"
    return $false
}

function Test-CliVersion {
    if (-not (Test-CommandExists "openclaw")) { return $false }

    Write-Info "检查 openclaw 版本..."

    try {
        # TODO: confirm openclaw version command
        $version = openclaw --version 2>$null
        if (-not [string]::IsNullOrEmpty($version)) {
            Write-Success "  \u221a 版本: $version"
            return $true
        }
    } catch {
        # 继续下方错误处理
    }

    Write-Err "  X openclaw --version 执行失败"
    return $false
}

function Test-PathCorrect {
    Write-Info "检查 PATH 配置..."

    if (Test-CommandExists "npm") {
        try {
            $npmPrefix = npm config get prefix 2>$null
            if (-not [string]::IsNullOrEmpty($npmPrefix)) {
                if ($env:PATH -like "*$npmPrefix*") {
                    Write-Success "  \u221a npm 全局目录在 PATH 中: $npmPrefix"
                    return $true
                } else {
                    Write-Warn "  ! npm 全局目录不在 PATH 中: $npmPrefix"
                    return $true  # 警告但不阻塞
                }
            }
        } catch {
            # 忽略
        }
    }

    return $true
}

function Test-BasicCommands {
    if (-not (Test-CommandExists "openclaw")) { return $false }

    Write-Info "检查基本命令..."

    # TODO: confirm openclaw subcommands
    $commands = @("--version", "--help")
    $allOk = $true

    foreach ($cmd in $commands) {
        try {
            $null = Invoke-Expression "openclaw $cmd" 2>$null
            if ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE) {
                Write-Success "  \u221a openclaw $cmd 正常"
            } else {
                Write-Warn "  ! openclaw $cmd 执行异常 (退出码: $LASTEXITCODE)"
                $allOk = $false
            }
        } catch {
            Write-Warn "  ! openclaw $cmd 执行异常"
            $allOk = $false
        }
    }

    return $allOk
}

function Test-DaemonStatus {
    Write-Info "检查 daemon / gateway 状态..."

    # TODO: confirm gateway/daemon health check command
    Write-Dbg "  TODO: daemon / gateway 状态检查命令待确认"
    Write-Info "  - 跳过 (daemon 检查待实现)"
}

function Test-ConfigExists {
    Write-Info "检查配置文件..."

    if (Test-Path $Script:ConfigDir) {
        Write-Success "  \u221a 配置目录存在: $Script:ConfigDir"
    } else {
        Write-Warn "  ! 配置目录不存在: $Script:ConfigDir"
    }

    # TODO: confirm config file name and path
    $configFile = Join-Path $Script:ConfigDir "config.json"
    if (Test-Path $configFile) {
        Write-Success "  \u221a 配置文件存在"
    } else {
        Write-Info "  - 配置文件不存在 (可通过配置向导生成)"
    }
}
