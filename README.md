# OpenClaw Bootstrap Installer

一键安装、升级、修复 OpenClaw 的引导脚本，支持 macOS 和 Windows 平台。

---

## 功能特点

- **全平台支持**：macOS (zsh/bash, Apple Silicon / Intel) 和 Windows (PowerShell 5.1 / 7.x)
- **四大模式**：`--install` / `--upgrade` / `--repair` / `--verify`
- **预检查机制**：运行前检查操作系统、Node.js 版本、网络、前置依赖，不满足条件时给出明确提示
- **幂等操作**：重复运行全程安全
- **安全设计**：来源白名单验证、敏感信息不回显、备份升级
- **结构化日志**：带时间戳的分级日志（INFO / WARN / ERROR / DEBUG）
- **非交互模式**：支持 CI 或自动化流水线

---

## 快速开始

### macOS

```bash
# 下载脚本
curl -fsSL https://raw.githubusercontent.com/philfxrs/openclaw-bootstrap/main/bootstrap/macos/install-openclaw-macos.sh -o install-openclaw-macos.sh
bash install-openclaw-macos.sh --install
```

### Windows

```powershell
# 下载脚本
Invoke-WebRequest -Uri https://raw.githubusercontent.com/philfxrs/openclaw-bootstrap/main/bootstrap/windows/install-openclaw-windows.ps1 -OutFile install-openclaw-windows.ps1
powershell -ExecutionPolicy Bypass -File install-openclaw-windows.ps1 -Install
```

---

## 主要命令

| 操作 | macOS | Windows |
|------|-------|----------|
| 安装 | `bash install-openclaw-macos.sh --install` | `...ps1 -Install` |
| 升级 | `bash install-openclaw-macos.sh --upgrade` | `...ps1 -Upgrade` |
| 修复 | `bash install-openclaw-macos.sh --repair` | `...ps1 -Repair` |
| 验证 | `bash install-openclaw-macos.sh --verify` | `...ps1 -Verify` |
| 重置配置 | `bash install-openclaw-macos.sh --reset-config` | `...ps1 -ResetConfig` |
| 帮助 | `bash install-openclaw-macos.sh --help` | `...ps1 -Help` |

通用选项（两平台均支持）：
- `--non-interactive` / `-NonInteractive` — 非交互模式
- `--verbose` / `-VerboseMode` — 显示 debug 日志

---

## 项目结构

```
openclaw-bootstrap/
├── bootstrap/
│   ├── macos/              # macOS 安装器模块
│   └── windows/            # Windows 安装器模块
├── checks/             # 策略配置（白名单、版本策略）
├── templates/          # 配置模板
├── docs/               # 文档
├── tests/              # 测试文档
└── scripts/            # lint / 自动化工具
```

---

## 安全说明

- 安装器仅从 `checks/source-allowlist.json` 列出的域名下载内容。
- API Key 、provider 配置储存在权限为 600 的文件中，不会写入日志。
- 不需要超级用户/管理员权限即可安装。
- 详见 [docs/SECURITY.md](docs/SECURITY.md)。

---

## 开发 / 贡献

### 运行 lint

```bash
# macOS (shellcheck)
bash scripts/lint-shell.sh

# Windows (PSScriptAnalyzer)
pwsh scripts/lint-powershell.ps1
```

### 克隆仓库

```bash
git clone https://github.com/philfxrs/openclaw-bootstrap.git
cd openclaw-bootstrap
```

### 文档

- [INSTALL.md](docs/INSTALL.md) — 详细安装指南
- [UPGRADE.md](docs/UPGRADE.md) — 升级说明
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — 常见问题
- [SECURITY.md](docs/SECURITY.md) — 安全说明
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — 模块架构

---

## License

MIT — 详见 [LICENSE](LICENSE)。

本项目是独立的安装引导工具，不是 OpenClaw 官方本体的一部分。
