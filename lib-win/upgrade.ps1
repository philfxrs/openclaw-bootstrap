# lib-win/upgrade.ps1 — 升级 / 修复 / 重置配置模块（Windows）
# -------------------------------------------------------
# 用法：. "$PSScriptRoot\upgrade.ps1"
#        Invoke-Upgrade
#        Invoke-Repair
#        Invoke-Reset

. "$PSScriptRoot\logger.ps1"
. "$PSScriptRoot\installer.ps1"
. "$PSScriptRoot\config.ps1"
. "$PSScriptRoot\verify.ps1"

function Test-CommandAvailable {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ---- 升级 ------------------------------------------------------
function Invoke-Upgrade {
    Write-LogSection "升级 OpenClaw 及依赖"

    # 升级包管理器
    if (Test-CommandAvailable "winget") {
        Write-LogStep "正在通过 winget 升级 Node.js …"
        winget upgrade --id OpenJS.NodeJS.LTS -e --source winget --silent 2>$null
        Write-LogOk "Node.js 升级步骤已执行。"

        Write-LogStep "正在通过 winget 升级 Git …"
        winget upgrade --id Git.Git -e --source winget --silent 2>$null
        Write-LogOk "Git 升级步骤已执行。"
    } elseif (Test-CommandAvailable "scoop") {
        Write-LogStep "正在通过 Scoop 升级 Node.js 和 Git …"
        scoop update nodejs-lts git 2>$null
        Write-LogOk "Scoop 升级步骤已执行。"
    } else {
        Write-LogWarn "未检测到 winget 或 Scoop，跳过依赖升级。"
    }

    # 升级 OpenClaw
    Write-LogStep "正在升级 OpenClaw …"
    if (Test-CommandAvailable "npm") {
        try {
            npm update -g openclaw 2>$null
            Write-LogOk "OpenClaw 通过 npm 升级完成（$(& openclaw --version 2>$null)）。"
        } catch {
            Write-LogWarn "npm 升级失败，请尝试手动运行：npm update -g openclaw"
        }
    } elseif (Test-CommandAvailable "openclaw") {
        try {
            & openclaw upgrade 2>$null
            Write-LogOk "OpenClaw 通过自身 upgrade 命令升级成功。"
        } catch {
            Write-LogWarn "openclaw upgrade 失败，请手动运行：npm update -g openclaw"
        }
    } else {
        Write-LogWarn "未找到 npm 或 openclaw 命令，无法自动升级。"
    }

    Write-LogOk "升级流程完成。"
    Invoke-Verify | Out-Null
}

# ---- 修复 ------------------------------------------------------
function Invoke-Repair {
    Write-LogSection "修复安装"
    Write-LogHint "将重新安装所有缺失组件，已安装的组件不会被重复安装。"

    Install-GitWindows   | Out-Null
    Install-NodeWindows  | Out-Null
    Install-OpenClaw     | Out-Null

    Write-LogOk "修复流程完成。"
    Invoke-Verify | Out-Null
}

# ---- 重置配置 --------------------------------------------------
function Invoke-Reset {
    Write-LogSection "重置配置"
    $cfgDir = if ($env:OPENCLAW_CONFIG_DIR) { $env:OPENCLAW_CONFIG_DIR } else { Join-Path $env:APPDATA "openclaw" }
    Write-LogWarn "此操作将备份并重置 OpenClaw 配置文件，程序本身不会被卸载。"
    Write-LogHint "配置目录：$cfgDir"

    if ($env:OPENCLAW_NONINTERACTIVE -ne "1") {
        $answer = Read-Host "确认重置配置？[y/N]"
        if ($answer -notmatch '^[yY]') {
            Write-LogInfo "已取消重置。"
            return
        }
    }

    Reset-OpenClawConfig
    Write-LogOk "配置已重置。如需重新运行初始化向导，请执行：openclaw onboard"
}
