# ============================================================================
# Lib.Preflight.ps1 — OpenClaw Bootstrap 预检模块 (Windows)
# ============================================================================
# 负责在安装前检查系统环境是否满足所有前提条件。
# ============================================================================

if ($Script:LibPreflightLoaded) { return }
$Script:LibPreflightLoaded = $true

. (Join-Path $PSScriptRoot "Lib.Common.ps1")

# ========================================
# 主预检入口
# ========================================

function Invoke-PreflightChecks {
    Write-Step "开始环境预检..."
    Write-Host ""

    Test-OperatingSystem
    Test-PowerShellVersion
    Test-AdminPrivileges
    Test-ExecutionPolicy
    Test-NodeJs
    Test-Npm
    Test-ExistingInstallation
    Test-PathEnvironment
    Test-NetworkConnectivity
    Test-SystemProxy
    Test-SourceAllowlistConfig
    Test-LogDirectoryWritable
    Test-ConfigDirectoryWritable

    Show-PreflightReport

    if ($Script:PreflightHasFail) {
        Write-Err "预检存在阻塞项，请根据上方报告修复后重试。"
        return $false
    }

    return $true
}

# ========================================
# 操作系统检查
# ========================================

function Test-OperatingSystem {
    Write-Dbg "检查操作系统..."

    if ($env:OS -ne "Windows_NT") {
        Add-PreflightFail "操作系统" "当前系统非 Windows，此脚本仅支持 Windows"
        Write-ErrorDetail `
            -Title "不支持的操作系统" `
            -Reason "此脚本仅适用于 Windows 系统。" `
            -Impact "无法继续安装。" `
            -FixSteps "如果你使用 macOS，请使用 install-openclaw-macos.sh"
        return
    }

    $osVersion = [System.Environment]::OSVersion.Version
    $osCaption = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if ([string]::IsNullOrEmpty($osCaption)) {
        $osCaption = "Windows $($osVersion.Major).$($osVersion.Minor)"
    }

    Add-PreflightPass "操作系统" $osCaption
}

# ========================================
# PowerShell 版本检查
# ========================================

function Test-PowerShellVersion {
    Write-Dbg "检查 PowerShell 版本..."

    $psVersion = $PSVersionTable.PSVersion
    $psEdition = if ($PSVersionTable.PSEdition) { $PSVersionTable.PSEdition } else { "Desktop" }

    $minVersion = "5.1"
    $policy = Read-JsonFile $Script:VersionPolicyFile
    if ($null -ne $policy) {
        $minVersion = $policy.minimum_powershell_version
        if ([string]::IsNullOrEmpty($minVersion)) { $minVersion = "5.1" }
    }

    $versionStr = "$($psVersion.Major).$($psVersion.Minor)"
    if ((Compare-Version $versionStr $minVersion) -ge 0) {
        Add-PreflightPass "PowerShell" "v$psVersion ($psEdition) (最低要求: v$minVersion)"
    } else {
        Add-PreflightFail "PowerShell" "版本过低: v$psVersion (最低要求: v$minVersion)"
    }
}

# ========================================
# 管理员权限检查
# ========================================

function Test-AdminPrivileges {
    Write-Dbg "检查管理员权限..."

    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    )
    $isAdmin = $currentPrincipal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )

    if ($isAdmin) {
        Add-PreflightPass "管理员权限" "已获得管理员权限"
    } else {
        Add-PreflightWarn "管理员权限" "未以管理员身份运行 (部分操作可能需要管理员权限)"
    }
}

# ========================================
# ExecutionPolicy 检查
# ========================================

function Test-ExecutionPolicy {
    Write-Dbg "检查 ExecutionPolicy..."

    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    $processPolicy = Get-ExecutionPolicy -Scope Process
    $machinePolicy = Get-ExecutionPolicy -Scope LocalMachine

    Write-Dbg "  CurrentUser: $currentPolicy"
    Write-Dbg "  Process: $processPolicy"
    Write-Dbg "  LocalMachine: $machinePolicy"

    # 如果当前进程策略允许，则通过
    $effectivePolicy = Get-ExecutionPolicy
    switch ($effectivePolicy) {
        "Unrestricted" { Add-PreflightPass "ExecutionPolicy" "$effectivePolicy" }
        "RemoteSigned" { Add-PreflightPass "ExecutionPolicy" "$effectivePolicy" }
        "Bypass"       { Add-PreflightPass "ExecutionPolicy" "$effectivePolicy" }
        "AllSigned"    {
            Add-PreflightWarn "ExecutionPolicy" "$effectivePolicy (可能需要调整)"
        }
        "Restricted"   {
            Add-PreflightFail "ExecutionPolicy" "$effectivePolicy (脚本执行被禁止)"
            Write-ErrorDetail `
                -Title "ExecutionPolicy 阻止脚本执行" `
                -Reason "当前 ExecutionPolicy 为 $effectivePolicy，PowerShell 禁止运行脚本。" `
                -Impact "安装器脚本无法执行。" `
                -FixSteps "1. 以管理员身份打开 PowerShell`n2. 设置当前用户的执行策略为 RemoteSigned`n3. 重新运行安装脚本" `
                -FixCommands "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`n# 如果你只想针对当前进程临时放开：`nSet-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process"
        }
        default {
            Add-PreflightWarn "ExecutionPolicy" "未知策略: $effectivePolicy"
        }
    }
}

# ========================================
# Node.js 检查
# ========================================

function Test-NodeJs {
    Write-Dbg "检查 Node.js..."

    if (-not (Test-CommandExists "node")) {
        Add-PreflightFail "Node.js" "未安装"
        Write-ErrorDetail `
            -Title "未检测到 Node.js" `
            -Reason "OpenClaw 运行依赖 Node.js，但当前系统中未找到 node 命令。" `
            -Impact "安装器无法继续执行 OpenClaw 安装。" `
            -FixSteps "1. 安装 Node.js 22 或更高版本`n2. 安装完成后重新打开终端`n3. 再次运行本安装脚本" `
            -FixCommands "- 访问 https://nodejs.org 下载 Windows 安装包`n- 或使用 winget: winget install OpenJS.NodeJS.LTS`n- 或使用 scoop: scoop install nodejs-lts"
        return
    }

    $nodeVersion = (node --version 2>$null)
    if ([string]::IsNullOrEmpty($nodeVersion)) {
        Add-PreflightFail "Node.js" "node 命令存在但无法获取版本"
        return
    }

    $nodeVersion = $nodeVersion -replace '^v', ''

    $minVersion = "22.0.0"
    $policy = Read-JsonFile $Script:VersionPolicyFile
    if ($null -ne $policy -and -not [string]::IsNullOrEmpty($policy.minimum_node_version)) {
        $minVersion = $policy.minimum_node_version
    }

    if ((Compare-Version $nodeVersion $minVersion) -ge 0) {
        Add-PreflightPass "Node.js" "v$nodeVersion (最低要求: v$minVersion)"
    } else {
        Add-PreflightFail "Node.js" "版本过低: v$nodeVersion (最低要求: v$minVersion)"
        Write-ErrorDetail `
            -Title "Node.js 版本过低" `
            -Reason "当前 Node.js 版本为 v$nodeVersion，最低要求 v$minVersion。" `
            -Impact "部分 OpenClaw 功能可能无法正常运行。" `
            -FixSteps "1. 升级 Node.js 到 v$minVersion 或更高版本`n2. 升级完成后重新打开终端`n3. 再次运行本安装脚本" `
            -FixCommands "- winget upgrade OpenJS.NodeJS.LTS`n- 或访问 https://nodejs.org 下载新版本"
    }
}

# ========================================
# npm 检查
# ========================================

function Test-Npm {
    Write-Dbg "检查 npm..."

    if (-not (Test-CommandExists "npm")) {
        Add-PreflightFail "npm" "未安装或不在 PATH 中"
        Write-ErrorDetail `
            -Title "未检测到 npm" `
            -Reason "npm 通常随 Node.js 一起安装，但当前系统中未找到 npm 命令。" `
            -Impact "无法通过 npm 安装 OpenClaw。" `
            -FixSteps "1. 确认 Node.js 是否正确安装`n2. 检查 PATH 环境变量`n3. 重新安装 Node.js" `
            -FixCommands "- node --version`n- where.exe npm`n- echo `$env:PATH"
        return
    }

    $npmVersion = (npm --version 2>$null)
    Add-PreflightPass "npm" "v$npmVersion"
}

# ========================================
# 已安装状态检查
# ========================================

function Test-ExistingInstallation {
    Write-Dbg "检查已安装状态..."

    # TODO: confirm openclaw CLI command name
    if (Test-CommandExists "openclaw") {
        $installedVersion = try { openclaw --version 2>$null } catch { "未知" }
        Add-PreflightWarn "已安装状态" "已安装 OpenClaw (版本: $installedVersion)"
    } else {
        Add-PreflightPass "已安装状态" "未安装 (全新安装)"
    }
}

# ========================================
# PATH 检查
# ========================================

function Test-PathEnvironment {
    Write-Dbg "检查 PATH..."

    $issues = @()

    if (-not (Test-CommandExists "node")) {
        $issues += "node 不在 PATH 中"
    }

    if (-not (Test-CommandExists "npm")) {
        $issues += "npm 不在 PATH 中"
    }

    # 检查 npm 全局安装目录是否在 PATH 中
    if (Test-CommandExists "npm") {
        try {
            $npmPrefix = (npm config get prefix 2>$null)
            if (-not [string]::IsNullOrEmpty($npmPrefix)) {
                $npmBinDir = $npmPrefix
                if ($env:PATH -notlike "*$npmBinDir*") {
                    $issues += "npm 全局安装目录不在 PATH 中: $npmBinDir"
                }
            }
        } catch {
            # 忽略
        }
    }

    if ($issues.Count -eq 0) {
        Add-PreflightPass "PATH" "node 和 npm 均在 PATH 中"
    } else {
        $detail = $issues -join "; "
        Add-PreflightWarn "PATH" $detail
    }
}

# ========================================
# 网络连通性检查
# ========================================

function Test-NetworkConnectivity {
    Write-Dbg "检查网络连通性..."

    # TODO: confirm official install source URL
    $testUrls = @(
        "https://registry.npmjs.org",
        "https://github.com"
    )

    $allOk = $true

    foreach ($url in $testUrls) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
            Write-Dbg "  \u221a 网络可达: $url"
        } catch {
            Write-Dbg "  X 网络不可达: $url - $($_.Exception.Message)"
            $allOk = $false
        }
    }

    if ($allOk) {
        Add-PreflightPass "网络连通性" "官方源可达"
    } else {
        Add-PreflightFail "网络连通性" "部分官方源不可达，请检查网络或代理配置"
        Write-ErrorDetail `
            -Title "网络连通性异常" `
            -Reason "无法连接到部分官方下载源。" `
            -Impact "安装过程中需要从网络下载依赖，网络不可达将导致安装失败。" `
            -FixSteps "1. 检查网络连接`n2. 检查是否使用了代理`n3. 检查 DNS 是否正常`n4. 如在公司网络中，联系 IT 确认出网策略`n5. 检查安全软件是否拦截了连接" `
            -FixCommands "- Test-NetConnection registry.npmjs.org -Port 443`n- [Net.ServicePointManager]::SecurityProtocol`n- netsh winhttp show proxy"
    }
}

# ========================================
# 系统代理检查
# ========================================

function Test-SystemProxy {
    Write-Dbg "检查系统代理..."

    $proxyEnabled = $false
    $proxyInfo = ""

    # 检查环境变量代理
    if (-not [string]::IsNullOrEmpty($env:HTTP_PROXY)) {
        $proxyEnabled = $true
        $proxyInfo += "HTTP_PROXY=$($env:HTTP_PROXY) "
    }
    if (-not [string]::IsNullOrEmpty($env:HTTPS_PROXY)) {
        $proxyEnabled = $true
        $proxyInfo += "HTTPS_PROXY=$($env:HTTPS_PROXY) "
    }

    # 检查系统代理设置
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $proxyEnabledReg = (Get-ItemProperty -Path $regPath -Name ProxyEnable -ErrorAction SilentlyContinue).ProxyEnable
        if ($proxyEnabledReg -eq 1) {
            $proxyServer = (Get-ItemProperty -Path $regPath -Name ProxyServer -ErrorAction SilentlyContinue).ProxyServer
            $proxyEnabled = $true
            $proxyInfo += "系统代理=$proxyServer"
        }
    } catch {
        # 忽略
    }

    if ($proxyEnabled) {
        Add-PreflightWarn "系统代理" "检测到代理配置: $proxyInfo (可能影响下载)"
    } else {
        Add-PreflightPass "系统代理" "未检测到代理"
    }
}

# ========================================
# 白名单配置检查
# ========================================

function Test-SourceAllowlistConfig {
    Write-Dbg "检查来源白名单配置..."

    if (Test-Path $Script:SourceAllowlistFile) {
        $allowlist = Read-JsonFile $Script:SourceAllowlistFile
        if ($null -ne $allowlist -and $null -ne $allowlist.allowed_domains) {
            $count = $allowlist.allowed_domains.Count
            Add-PreflightPass "来源白名单" "已配置 ($count 个可信域名)"
        } else {
            Add-PreflightWarn "来源白名单" "白名单文件格式异常"
        }
    } else {
        Add-PreflightWarn "来源白名单" "白名单文件不存在: $Script:SourceAllowlistFile"
    }
}

# ========================================
# 日志目录可写检查
# ========================================

function Test-LogDirectoryWritable {
    Write-Dbg "检查日志目录可写性..."

    try {
        if (-not (Test-Path $Script:LogDir)) {
            New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
        }
        $testFile = Join-Path $Script:LogDir ".write-test"
        Set-Content -Path $testFile -Value "test" -ErrorAction Stop
        Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        Add-PreflightPass "日志目录" "可写 ($Script:LogDir)"
    } catch {
        Add-PreflightWarn "日志目录" "不可写: $Script:LogDir"
    }
}

# ========================================
# 配置目录可写检查
# ========================================

function Test-ConfigDirectoryWritable {
    Write-Dbg "检查配置目录可写性..."

    try {
        if (-not (Test-Path $Script:ConfigDir)) {
            New-Item -ItemType Directory -Path $Script:ConfigDir -Force | Out-Null
        }
        $testFile = Join-Path $Script:ConfigDir ".write-test"
        Set-Content -Path $testFile -Value "test" -ErrorAction Stop
        Remove-Item -Path $testFile -ErrorAction SilentlyContinue
        Add-PreflightPass "配置目录" "可写 ($Script:ConfigDir)"
    } catch {
        Add-PreflightWarn "配置目录" "不可写: $Script:ConfigDir"
    }
}
