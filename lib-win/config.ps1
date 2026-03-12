# lib-win/config.ps1 — 安装后初始化配置模块（Windows）
# -------------------------------------------------------
# 用法：. "$PSScriptRoot\config.ps1"
#        Invoke-Config

. "$PSScriptRoot\logger.ps1"

# ---- 配置目录 --------------------------------------------------
$Script:OpenClawConfigDir = if ($env:OPENCLAW_CONFIG_DIR) {
    $env:OPENCLAW_CONFIG_DIR
} else {
    Join-Path $env:APPDATA "openclaw"
}
$Script:OpenClawConfigFile = Join-Path $Script:OpenClawConfigDir "config.json"

# ---- 确保配置目录存在 ------------------------------------------
function Ensure-ConfigDir {
    if (-not (Test-Path $Script:OpenClawConfigDir)) {
        New-Item -ItemType Directory -Path $Script:OpenClawConfigDir -Force | Out-Null
        Write-LogOk "配置目录已创建：$($Script:OpenClawConfigDir)"
    } else {
        Write-LogInfo "配置目录已存在：$($Script:OpenClawConfigDir)"
    }
}

# ---- 写入默认配置（仅当配置文件不存在时）-----------------------
function Write-DefaultConfig {
    if (Test-Path $Script:OpenClawConfigFile) {
        Write-LogInfo "配置文件已存在，跳过默认写入：$($Script:OpenClawConfigFile)"
        return
    }

    $defaultConfig = @{
        version    = "1.0"
        language   = "zh-CN"
        telemetry  = $false
        autoUpdate = $true
        logLevel   = "info"
    } | ConvertTo-Json -Depth 10

    $defaultConfig | Out-File -FilePath $Script:OpenClawConfigFile -Encoding UTF8
    Write-LogOk "默认配置文件已写入：$($Script:OpenClawConfigFile)"
}

# ---- 用户 PATH 集成 -------------------------------------------
function Set-UserPath {
    $localBin = Join-Path $env:LOCALAPPDATA "Programs\openclaw\bin"
    $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$localBin*") {
        [System.Environment]::SetEnvironmentVariable(
            "PATH", "$currentPath;$localBin", "User"
        )
        Write-LogOk "已将 $localBin 添加到用户 PATH（重新打开终端后生效）。"
    } else {
        Write-LogInfo "PATH 已包含 OpenClaw bin 目录，无需修改。"
    }
}

# ---- 交互式初始化（可通过 OPENCLAW_NONINTERACTIVE=1 跳过）------
function Invoke-Onboard {
    if ($env:OPENCLAW_NONINTERACTIVE -eq "1") {
        Write-LogInfo "非交互模式，跳过 openclaw onboard。"
        return
    }
    if (-not (Get-Command "openclaw" -ErrorAction SilentlyContinue)) {
        Write-LogWarn "openclaw 命令未找到，跳过 onboard 步骤。"
        return
    }
    Write-LogStep "正在运行 openclaw onboard（初始化向导）…"
    Write-LogHint  "如果向导卡住，可按 Ctrl+C 跳过，稍后手动运行：openclaw onboard"
    try {
        openclaw onboard
    } catch {
        Write-LogWarn "onboard 未能完成，请稍后手动运行：openclaw onboard"
    }
}

# ---- 汇总入口 --------------------------------------------------
function Invoke-Config {
    Write-LogSection "初始化配置"
    Ensure-ConfigDir
    Write-DefaultConfig
    Set-UserPath
    Invoke-Onboard
    Write-LogOk "配置初始化完成。"
}

# ---- 重置配置（供 upgrade.ps1 调用）----------------------------
function Reset-OpenClawConfig {
    Write-LogSection "重置配置"
    if (Test-Path $Script:OpenClawConfigFile) {
        $backup = "$($Script:OpenClawConfigFile).bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -Path $Script:OpenClawConfigFile -Destination $backup
        Write-LogInfo "旧配置已备份至：$backup"
        Remove-Item -Path $Script:OpenClawConfigFile -Force
    }
    Write-DefaultConfig
    Write-LogOk "配置已重置为默认值。"
}
