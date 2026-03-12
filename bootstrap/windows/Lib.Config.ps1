# ============================================================================
# Lib.Config.ps1 — OpenClaw Bootstrap 配置模块 (Windows)
# ============================================================================
# 负责安装后的初始化配置、配置重置。
# ============================================================================

if ($Script:LibConfigLoaded) { return }
$Script:LibConfigLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

function Invoke-Configure {
    Write-Step "开始配置向导..."
    Write-Host ""

    if (-not (Test-Path $Script:ConfigDir)) {
        New-Item -ItemType Directory -Path $Script:ConfigDir -Force | Out-Null
    }

    Set-WorkDirectory
    Set-DaemonConfig
    Set-ProviderConfig
    Set-OnboardingConfig
    Invoke-VerifyPrompt

    Write-Success "配置向导完成！"
    Write-Host ""
}

function Set-WorkDirectory {
    Write-Info "配置项: 工作目录"
    Write-Host "  说明: OpenClaw 的默认工作目录，用于存放项目和数据。"
    Write-Host "  可跳过: 是 (使用默认值: $Script:WorkDir)"
    Write-Host "  跳过影响: 将使用默认目录 $Script:WorkDir"
    Write-Host ""

    $workDir = Read-UserInput "请输入工作目录路径" $Script:WorkDir

    if (-not [string]::IsNullOrEmpty($workDir)) {
        $Script:WorkDir = $workDir
        if (-not (Test-Path $Script:WorkDir)) {
            try {
                New-Item -ItemType Directory -Path $Script:WorkDir -Force | Out-Null
                Write-Success "工作目录已设置: $Script:WorkDir"
            } catch {
                Write-Warn "无法创建工作目录: $Script:WorkDir，请稍后手动创建。"
            }
        } else {
            Write-Success "工作目录已设置: $Script:WorkDir"
        }
    }
    Write-Host ""
}

function Set-DaemonConfig {
    Write-Info "配置项: Daemon 服务"
    Write-Host "  说明: OpenClaw daemon 提供后台服务能力，某些高级功能可能依赖它。"
    Write-Host "  可跳过: 是"
    Write-Host "  跳过影响: 部分高级功能可能不可用，可稍后手动配置。"
    Write-Host ""

    # TODO: confirm daemon install command
    if (Confirm-UserAction "是否安装 daemon 服务？") {
        Write-Info "将安装 daemon 服务..."
        Write-Warn "TODO: daemon 安装命令待确认，跳过实际安装。"
    } else {
        Write-Info "跳过 daemon 安装。你可以稍后手动执行安装。"
    }
    Write-Host ""
}

function Set-ProviderConfig {
    Write-Info "配置项: Provider (AI 服务提供商)"
    Write-Host "  说明: 配置 AI 服务提供商和 API Key，用于启用 AI 功能。"
    Write-Host "  可跳过: 是"
    Write-Host "  跳过影响: AI 相关功能将不可用，可稍后在配置文件中手动填写。"
    Write-Host ""

    if (-not (Confirm-UserAction "是否现在配置 Provider？")) {
        Write-Info "跳过 Provider 配置。"
        Write-Info "你可以稍后编辑配置文件或执行 openclaw 的配置命令。"
        Write-Host ""
        return
    }

    # TODO: confirm provider configuration approach
    $providerName = Read-UserInput "请输入 Provider 名称" ""

    if (-not [string]::IsNullOrEmpty($providerName)) {
        Write-Info "Provider: $providerName"

        if (Confirm-UserAction "是否现在填写 API Key？") {
            $secureKey = Read-Host "请输入 API Key (输入内容不会回显)" -AsSecureString
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
            $apiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

            if (-not [string]::IsNullOrEmpty($apiKey)) {
                Write-Info "API Key 已接收 (不会记录到日志)"
                Write-LogEntry "INFO" "API Key 已配置 (已脱敏)"
                $providerConfig = Join-Path $Script:ConfigDir "providers.json"
                Write-Warn "TODO: Provider 配置保存逻辑待确认。"
                Write-Info "请确保 $providerConfig 文件权限设置合理。"
                $apiKey = $null
            }
        } else {
            Write-Info "跳过 API Key 填写，可稍后配置。"
        }
    }
    Write-Host ""
}

function Set-OnboardingConfig {
    Write-Info "配置项: Onboarding 新手引导"
    Write-Host "  说明: 执行 OpenClaw 新手引导流程，帮助你了解基本用法。"
    Write-Host "  可跳过: 是"
    Write-Host "  跳过影响: 不影响功能，可稍后执行 onboarding 命令。"
    Write-Host ""

    # TODO: confirm onboarding command
    if (Confirm-UserAction "是否立即执行 onboarding？") {
        Write-Info "启动 onboarding..."
        if (Test-CommandExists "openclaw") {
            Write-Warn "TODO: onboarding 命令待确认 (例如: openclaw onboarding)"
        } else {
            Write-Warn "openclaw 命令不可用，无法执行 onboarding。"
        }
    } else {
        Write-Info "跳过 onboarding。你可以稍后执行: openclaw onboarding"
    }
    Write-Host ""
}

function Invoke-VerifyPrompt {
    Write-Host "  说明: 配置完成后建议立即验证安装状态。"
    Write-Host "  可跳过: 是"
    Write-Host "  跳过影响: 可能不会发现安装问题，建议执行。"
    Write-Host ""

    if (Confirm-UserAction "是否立即执行安装验证？" "y") {
        . (Join-Path $PSScriptRoot "Lib.Verify.ps1")
        Invoke-Verify
    } else {
        Write-Info "跳过验证。你可以稍后运行: .\install-openclaw-windows.ps1 -Verify"
    }
}

function Reset-OpenClawConfig {
    Write-Step "重置配置..."

    if (-not (Test-Path $Script:ConfigDir)) {
        Write-Info "配置目录不存在，无需重置。"
        return $true
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "$($Script:ConfigDir).backup.$timestamp"

    if (Confirm-UserAction "将备份当前配置到 $backupDir ，并重置为默认配置。是否继续？") {
        try {
            Copy-Item -Path $Script:ConfigDir -Destination $backupDir -Recurse -Force
            Write-Success "配置已备份到: $backupDir"

            $defaultConfig = Join-Path $Script:ProjectRoot "templates\config.default.json"
            if (Test-Path $defaultConfig) {
                $targetConfig = Join-Path $Script:ConfigDir "config.json"
                Copy-Item -Path $defaultConfig -Destination $targetConfig -Force
                Write-Success "配置已重置为默认值。"
            } else {
                Write-Warn "默认配置模板不存在: $defaultConfig"
            }
            return $true
        } catch {
            Write-Err "重置配置失败: $($_.Exception.Message)"
            return $false
        }
    } else {
        Write-Info "取消重置配置。"
        return $true
    }
}
