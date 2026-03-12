# lib-win/installer.ps1 — 安装模块（Winget / Scoop + OpenClaw 官方安装链路）
# -----------------------------------------------------------------------
# 用法：. "$PSScriptRoot\installer.ps1"
#        Invoke-Install

. "$PSScriptRoot\logger.ps1"

# ---- 工具辅助 --------------------------------------------------
function Test-CommandAvailable {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

# ---- Node.js 版本检查 ------------------------------------------
function Test-NodeVersionOk {
    param([int]$MinMajor = 18)
    if (-not (Test-CommandAvailable "node")) { return $false }
    $versionStr = (node --version 2>$null) -replace '^v', ''
    $major = ($versionStr -split '\.')[0]
    return ([int]$major -ge $MinMajor)
}

# ---- 安装包管理器 (winget 优先，回退 Scoop) ----------------------
function Install-PackageManager {
    if (Test-CommandAvailable "winget") {
        Write-LogOk "winget 已可用。"
        return "winget"
    }
    if (Test-CommandAvailable "scoop") {
        Write-LogOk "Scoop 已可用。"
        return "scoop"
    }

    Write-LogStep "正在安装 Scoop 包管理器 …"
    Write-LogHint "Scoop 是 Windows 上广泛使用的命令行包管理器。"
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
        if (Test-CommandAvailable "scoop") {
            Write-LogOk "Scoop 安装成功。"
            return "scoop"
        }
    } catch {
        Write-LogError "Scoop 安装失败：$($_.Exception.Message)"
        Write-LogHint  "请手动安装 Scoop：https://scoop.sh"
        Write-LogHint  "或确保 winget 可用（Windows 10 1709+ 自带）。"
    }
    return $null
}

# ---- 安装 Git --------------------------------------------------
function Install-GitWindows {
    if (Test-CommandAvailable "git") {
        Write-LogOk "Git 已安装（$(git --version 2>$null)）"
        return $true
    }

    Write-LogStep "正在安装 Git …"
    $pm = Install-PackageManager
    $ok = $false
    switch ($pm) {
        "winget" {
            winget install --id Git.Git -e --source winget --silent 2>$null
            $ok = Test-CommandAvailable "git"
        }
        "scoop"  {
            scoop install git
            $ok = Test-CommandAvailable "git"
        }
        default {
            Write-LogError "未找到可用的包管理器，无法自动安装 Git。"
            Write-LogHint  "请手动下载并安装 Git：https://git-scm.com/download/win"
        }
    }

    if ($ok) {
        Write-LogOk "Git 安装成功（$(git --version 2>$null)）"
    } else {
        Write-LogError "Git 安装失败。"
    }
    return $ok
}

# ---- 安装 Node.js ----------------------------------------------
function Install-NodeWindows {
    $minMajor = if ($env:OPENCLAW_NODE_MIN_MAJOR) { [int]$env:OPENCLAW_NODE_MIN_MAJOR } else { 18 }
    if (Test-NodeVersionOk -MinMajor $minMajor) {
        Write-LogOk "Node.js 已安装（$(node --version 2>$null)），版本符合要求。"
        return $true
    }

    Write-LogStep "正在安装 Node.js …"
    $pm = Install-PackageManager
    $ok = $false
    switch ($pm) {
        "winget" {
            winget install --id OpenJS.NodeJS.LTS -e --source winget --silent 2>$null
            $ok = Test-NodeVersionOk -MinMajor $minMajor
        }
        "scoop"  {
            scoop install nodejs-lts
            $ok = Test-NodeVersionOk -MinMajor $minMajor
        }
        default {
            Write-LogError "未找到可用的包管理器，无法自动安装 Node.js。"
            Write-LogHint  "请手动下载并安装 Node.js LTS：https://nodejs.org"
        }
    }

    if ($ok) {
        Write-LogOk "Node.js 安装成功（$(node --version 2>$null)）"
    } else {
        Write-LogError "Node.js 安装失败或版本仍低于 v${minMajor}。"
        Write-LogHint  "请手动安装 Node.js LTS：https://nodejs.org"
    }
    return $ok
}

# ---- 安装 OpenClaw ---------------------------------------------
function Install-OpenClaw {
    if (Test-CommandAvailable "openclaw") {
        $ver = & openclaw --version 2>$null
        Write-LogOk "OpenClaw 已安装（$ver）"
        Write-LogHint "如需升级，请运行：.\install.ps1 upgrade"
        return $true
    }

    Write-LogStep "正在安装 OpenClaw …"
    Write-LogHint "将通过官方推荐安装方式（npm 全局安装）进行，请稍候。"

    # 尝试 npm 安装
    if (Test-CommandAvailable "npm") {
        try {
            npm install -g openclaw 2>$null
            if (Test-CommandAvailable "openclaw") {
                $ver = & openclaw --version 2>$null
                Write-LogOk "OpenClaw 通过 npm 安装成功（$ver）"
                return $true
            }
        } catch {}
    }

    # 回退：官方 PowerShell 安装脚本
    Write-LogWarn "npm 安装未成功，尝试官方 PowerShell 安装链路 …"
    try {
        $installScript = (New-TemporaryFile).FullName + ".ps1"
        Invoke-WebRequest -Uri "https://install.openclaw.ai/install.ps1" -OutFile $installScript -UseBasicParsing
        & PowerShell -ExecutionPolicy Bypass -File $installScript
        Remove-Item -Path $installScript -ErrorAction SilentlyContinue
        if (Test-CommandAvailable "openclaw") {
            Write-LogOk "OpenClaw 通过官方脚本安装成功。"
            return $true
        }
    } catch {
        Write-LogError "官方安装脚本失败：$($_.Exception.Message)"
    }

    Write-LogError "OpenClaw 安装失败。"
    Write-LogHint  "请尝试手动安装：npm install -g openclaw"
    Write-LogHint  "或访问官方文档：https://github.com/openclaw/openclaw"
    return $false
}

# ---- 汇总入口 --------------------------------------------------
function Invoke-Install {
    Write-LogSection "安装依赖与 OpenClaw"

    $ok = $true
    if (-not (Install-GitWindows))   { $ok = $false }
    if (-not (Install-NodeWindows))  { $ok = $false }
    if (-not (Install-OpenClaw))     { $ok = $false }

    if ($ok) {
        Write-LogOk "所有组件安装完成。"
    } else {
        Write-LogError "部分组件安装失败，请查阅上方提示。"
        return $false
    }
    return $true
}
