# openclaw-bootstrap

> 面向全新系统的 OpenClaw **一键安装与引导配置工具**  
> One-click installer & bootstrap configurator for OpenClaw on fresh systems

[![平台](https://img.shields.io/badge/平台-macOS%20%7C%20Windows-blue)](#)
[![Shell](https://img.shields.io/badge/Shell-Bash%203%2B-green)](#)
[![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-blue)](#)

---

## 简介

`openclaw-bootstrap` **不是** OpenClaw 本体，也不是 fork。  
它的职责是：

| 功能 | 说明 |
|------|------|
| 🔍 环境预检 | 检测 OS 版本、磁盘空间、网络连通性 |
| 📦 依赖安装 | Homebrew / winget / Scoop + Node.js + Git |
| 🚀 官方安装 | 调用 OpenClaw 官方推荐安装链路 |
| ⚙️ 初始化配置 | 写入默认配置、Shell 集成、运行 `openclaw onboard` |
| ✅ 安装验证 | 逐项验证安装结果并给出修复提示 |
| 🔄 升级 / 修复 / 重置 | 一键升级所有组件、修复缺失组件、重置为默认配置 |
| 🇨🇳 中文友好 | 所有错误、警告、提示均有清晰中文说明和下一步指引 |

---

## 目录结构

```
openclaw-bootstrap/
├── install.sh          # macOS 入口脚本
├── install.ps1         # Windows 入口脚本
├── lib/                # macOS Shell 模块
│   ├── logger.sh       # 彩色日志 + 中文提示
│   ├── preflight.sh    # 环境预检
│   ├── installer.sh    # Homebrew + Node.js + OpenClaw 安装
│   ├── config.sh       # 初始化配置
│   ├── verify.sh       # 安装验证
│   └── upgrade.sh      # 升级 / 修复 / 重置
├── lib-win/            # Windows PowerShell 模块
│   ├── logger.ps1
│   ├── preflight.ps1
│   ├── installer.ps1
│   ├── config.ps1
│   ├── verify.ps1
│   └── upgrade.ps1
└── tests/              # Shell 单元测试
    ├── run_tests.sh
    ├── test_logger.sh
    ├── test_preflight.sh
    ├── test_verify.sh
    └── test_config.sh
```

---

## 快速开始

### macOS

```bash
# 克隆仓库
git clone https://github.com/philfxrs/openclaw-bootstrap.git
cd openclaw-bootstrap

# 全新安装（推荐）
bash install.sh

# 或使用子命令
bash install.sh upgrade   # 升级
bash install.sh repair    # 修复
bash install.sh verify    # 验证
bash install.sh reset     # 重置配置
bash install.sh help      # 帮助
```

### Windows（PowerShell）

```powershell
# 克隆仓库
git clone https://github.com/philfxrs/openclaw-bootstrap.git
cd openclaw-bootstrap

# 全新安装（推荐）
.\install.ps1

# 或使用子命令
.\install.ps1 upgrade   # 升级
.\install.ps1 repair    # 修复
.\install.ps1 verify    # 验证
.\install.ps1 reset     # 重置配置
.\install.ps1 help      # 帮助
```

> **提示（Windows）**：首次运行建议以管理员身份打开 PowerShell，并执行：  
> `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 子命令说明

| 命令 | 说明 |
|------|------|
| `install`（默认） | 完整流程：预检 → 安装 → 配置 → 验证 |
| `upgrade` | 升级 OpenClaw 及 Node.js、Git 等依赖 |
| `repair` | 重新安装所有缺失组件（已安装的不重复安装） |
| `config` | 重新生成默认配置文件并执行 Shell 集成 |
| `reset` | 备份旧配置并重置为出厂默认值 |
| `verify` | 仅检查当前安装是否完整 |
| `help` | 显示帮助信息 |

---

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `OPENCLAW_NONINTERACTIVE` | `0` | 设为 `1` 可跳过所有交互确认 |
| `OPENCLAW_REQUIRED_DISK_MB` | `2048` | 安装所需最小磁盘空间（MB） |
| `OPENCLAW_NODE_MIN_MAJOR` | `18` | Node.js 最低主版本号 |
| `OPENCLAW_CONFIG_DIR` | `~/.config/openclaw`（macOS）/ `%APPDATA%\openclaw`（Windows） | 配置目录 |

---

## 运行测试

```bash
# 运行所有单元测试（仅 macOS / Linux）
bash tests/run_tests.sh
```

---

## 系统要求

| 平台 | 最低版本 |
|------|---------|
| macOS | 12 (Monterey) |
| Windows | 10 Build 19041 (2004) |
| Bash | 3.x+ |
| PowerShell | 5+ |

---

## 常见问题

**Q：安装失败，提示网络不通怎么办？**  
A：请确认可以访问 `github.com`。若使用代理，请配置 `http_proxy` / `https_proxy` 环境变量。

**Q：macOS 提示"无法打开来自身份不明的开发者的 App"？**  
A：右键点击 → 打开，或在"系统偏好设置 → 安全性与隐私"中允许运行。

**Q：Windows 执行策略报错？**  
A：以管理员身份运行 PowerShell，执行：  
`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Q：如何完全卸载 OpenClaw？**  
A：请参考 [OpenClaw 官方文档](https://github.com/openclaw/openclaw)。  
本工具不负责卸载 OpenClaw 本体。

---

## 贡献

欢迎提交 Issue 和 Pull Request！请确保：
1. 所有 Shell 测试通过：`bash tests/run_tests.sh`
2. 遵循现有的模块化结构
3. 错误提示使用中文，并包含下一步指引

---

## License

MIT

