# 模块架构

## 模块责任表

### macOS 模块 (`bootstrap/macos/`)

| 文件 | 责任 |
|------|------|
| `lib-common.sh` | 公共工具函数：日志、彩色输出、JSON 读取、安全下载、备份、校验 |
| `lib-preflight.sh` | 验证操作系统、Node.js、网络、来源白名单、目录可写 |
| `lib-install.sh` | 执行 `npm install -g openclaw`，幂等、验证 |
| `lib-config.sh` | 工作目录、daemon、provider、onboarding 配置向导 |
| `lib-verify.sh` | 执行文件、版本、PATH、基本命令、daemon、配置文件验证 |
| `lib-upgrade.sh` | 备份 + `npm update -g openclaw` + 验证 |
| `lib-repair.sh` | 修复 PATH、重装 Node.js、重安装、修复配置和权限 |
| `install-openclaw-macos.sh` | 主入口：参数解析、调度各模块 |

### Windows 模块 (`bootstrap/windows/`)

| 文件 | 责任 |
|------|------|
| `Lib.Common.ps1` | 公共工具：日志、彩色输出、JSON 读取、安全下载、备份、校验 |
| `Lib.Preflight.ps1` | 检查 OS、PS 版本、管理员权限、ExecutionPolicy、Node.js、网络 |
| `Lib.Install.ps1` | 执行 `npm install -g openclaw`，幂等、PATH 刷新 |
| `Lib.Config.ps1` | 配置向导，SecureString 保护 API Key |
| `Lib.Verify.ps1` | 验证安装阶段的各项指标 |
| `Lib.Upgrade.ps1` | 备份 + 升级 + 验证 |
| `Lib.Repair.ps1` | 修复 PATH、Node.js、安装、配置、ExecutionPolicy |
| `install-openclaw-windows.ps1` | 主入口点：参数解析、调度各模块 |

## 依赖关系

```
install-openclaw-macos.sh
    |-- lib-common.sh    (global utils)
    |-- lib-preflight.sh
    |-- lib-install.sh
    |-- lib-config.sh
    |-- lib-verify.sh
    |-- lib-upgrade.sh
    `-- lib-repair.sh

install-openclaw-windows.ps1
    |-- Lib.Common.ps1    (global utils)
    |-- Lib.Preflight.ps1
    |-- Lib.Install.ps1
    |-- Lib.Config.ps1
    |-- Lib.Verify.ps1
    |-- Lib.Upgrade.ps1
    `-- Lib.Repair.ps1
```

## 数据流转图

```
User calls --install
    |
 main script
    |
 run_install_flow()
    |-- run_preflight_checks()   -> lib-preflight.sh
    |-- perform_install()        -> lib-install.sh
    |-- perform_configure()      -> lib-config.sh
    `-- perform_verify()         -> lib-verify.sh

All public functions -> lib-common.sh
All logging -> ~/Library/Logs/openclaw-bootstrap/
              %LOCALAPPDATA%\openclaw-bootstrap\logs\
```

## 输出体系

| 级别 | 颜色 | 前缀 | 用途 |
|------|------|------|------|
| INFO | 蓝色 | `[INFO]` | 常规流程信息 |
| SUCCESS | 绿色 | `[OK]` | 操作成功 |
| WARN | 黄色 | `[WARN]` | 非致命性问题 |
| ERROR | 红色 | `[ERROR]` | 错误，通常会中止执行 |
| STEP | 蓝色 | `[STEP x/N]` | 大步骤标志 |
| DEBUG | 灰色 | `[DEBUG]` | 详细调试信息（需 --verbose） |

所有输出同时写入日志文件（无颜色码版本）。

## 安全流程

```
User inputs API Key
    |
[Secure read] read -rs / Read-Host -AsSecureString
    |
[Access restricted] not written to logs, not echoed to terminal
    |
[Write to file] chmod 600 / Windows ACL
    |
[Windows extra] SecureString released and memory cleared
```

## 可扩展性

- 各模块可独立单元测试
- 策略文件（`checks/`）可在不修改脚本的情况下更新
- 日志系统、预检查项、模式均可独立扩展
