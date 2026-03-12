# lib-win/preflight.ps1 — 环境预检模块（Windows）
# -------------------------------------------------------
# 用法：. "$PSScriptRoot\preflight.ps1"
#        Invoke-PreflightChecks

. "$PSScriptRoot\logger.ps1"

# ---- Windows 版本检查 ------------------------------------------
function Test-WindowsVersion {
    $min_build = 19041  # Windows 10 2004
    $build = [System.Environment]::OSVersion.Version.Build
    $caption = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
    if ($build -lt $min_build) {
        Write-LogError "检测到 Windows 版本过低（Build $build）。"
        Write-LogHint  "openclaw-bootstrap 要求 Windows 10 Build 19041（2004）及以上。"
        Write-LogHint  "请升级您的系统后重试。"
        return $false
    }
    Write-LogOk "Windows 版本：$caption（Build $build，符合要求）"
    return $true
}

# ---- 磁盘空间检查（默认 2 GB）----------------------------------
function Test-DiskSpace {
    param([long]$RequiredMB = 2048)
    $drive = (Get-Location).Drive.Name + ":"
    $disk = Get-PSDrive -Name (Get-Location).Drive.Name -ErrorAction SilentlyContinue
    if (-not $disk) {
        Write-LogWarn "无法获取磁盘信息，跳过磁盘空间检查。"
        return $true
    }
    $availableMB = [math]::Floor($disk.Free / 1MB)
    if ($availableMB -lt $RequiredMB) {
        Write-LogError "磁盘剩余空间不足。当前可用：${availableMB} MB，需要至少 ${RequiredMB} MB。"
        Write-LogHint  "请清理磁盘后重试。"
        return $false
    }
    Write-LogOk "磁盘剩余空间：${availableMB} MB（符合要求）"
    return $true
}

# ---- 网络连通性检查 --------------------------------------------
function Test-NetworkConnectivity {
    $testHost = "github.com"
    try {
        $result = Test-NetConnection -ComputerName $testHost -Port 443 -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Write-LogOk "网络连接正常（可访问 $testHost）"
            return $true
        }
    } catch {}
    Write-LogError "无法连接到 $testHost，请检查您的网络连接。"
    Write-LogHint  "OpenClaw 安装需要访问 GitHub。如使用代理，请确保已正确配置。"
    return $false
}

# ---- 管理员权限检查 --------------------------------------------
function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
    if (-not $isAdmin) {
        Write-LogWarn "当前未以管理员权限运行。部分安装步骤可能需要管理员权限。"
        Write-LogHint "如遇权限错误，请右键 PowerShell → 以管理员身份运行，再重试。"
    } else {
        Write-LogOk "已检测到管理员权限。"
    }
    return $true  # 警告而非阻止
}

# ---- PowerShell 版本检查 --------------------------------------
function Test-PowerShellVersion {
    $minVersion = 5
    $current = $PSVersionTable.PSVersion.Major
    if ($current -lt $minVersion) {
        Write-LogError "PowerShell 版本过低（当前：$current），需要 PowerShell $minVersion 及以上。"
        return $false
    }
    Write-LogOk "PowerShell 版本：$($PSVersionTable.PSVersion)"
    return $true
}

# ---- 汇总入口 --------------------------------------------------
function Invoke-PreflightChecks {
    Write-LogSection "环境预检"
    $failed = 0

    if (-not (Test-PowerShellVersion))    { $failed++ }
    Test-AdminPrivileges | Out-Null
    if (-not (Test-WindowsVersion))       { $failed++ }
    $requiredMB = if ($env:OPENCLAW_REQUIRED_DISK_MB) { [long]$env:OPENCLAW_REQUIRED_DISK_MB } else { 2048 }
    if (-not (Test-DiskSpace -RequiredMB $requiredMB)) { $failed++ }
    if (-not (Test-NetworkConnectivity))  { $failed++ }

    if ($failed -gt 0) {
        Write-LogFatal "预检发现 $failed 项问题，请按上述提示解决后重新运行安装程序。"
    }
    Write-LogOk "所有预检项通过，开始安装。"
}
