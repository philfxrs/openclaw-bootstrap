# 安全说明

## 责任边界

OpenClaw Bootstrap Installer 是一个安装引导工具，其安全边界如下：

**在范围内：**
- 安全执行安装流程本身
- 保护用户提供的敏感配置（API Key 等）
- 限制下载来源（白名单）
- 确保安装的是官方 npm 包

**超出范围：**
- OpenClaw 本身的安全性（属于 OpenClaw 官方责任）
- 用户使用 OpenClaw 后的行为安全

---

## 来源白名单

安装器仅从 `checks/source-allowlist.json` 列出的域名下载内容。

**当前允许域名：**
- `openclaw.ai` / `docs.openclaw.ai`
- `github.com` / `raw.githubusercontent.com`
- `registry.npmjs.org` / `npmjs.com`
- `nodejs.org`

如需添加新域名，请提交 PR 并说明理由。**不应随意扩大白名单。**

---

## Checksum / 签名验证

当前状态：`checksum_enabled: false`（预留结构，待官方提供机制后开启）

- `checks/checksum-policy.example.json` 定义了校验配置结构
- 一旦官方提供 SHA-256 校验文件，可将 `checksum_enabled` 改为 `true` 并填入校验值

---

## 敏感数据保护

| 数据类型 | macOS 存储 | Windows 存储 | 权限 |
|----------|------------|-------------|------|
| API Key | `~/.config/openclaw/config.providers.json` | `%APPDATA%\openclaw\config.providers.json` | 600 |
| 日志文件 | `~/Library/Logs/openclaw-bootstrap/` | `%LOCALAPPDATA%\openclaw-bootstrap\logs\` | 600 |

**安全措施：**
- 用户输入的 API Key 在 macOS 上使用 `read -rs`，在 Windows 上使用 `Read-Host -AsSecureString`，不会回显到屏幕
- 敏感内容不会写入日志
- `config.providers.json` 已在 `.gitignore` 中排除
- Windows 上在写入文件前将 API Key 从 SecureString 释放后立即清除内存

---

## ExecutionPolicy (Windows)

推荐用 `-ExecutionPolicy Bypass` 启动脚本，而不是永久修改系统策略：

```powershell
# 推荐方式（不修改系统设置）
powershell -ExecutionPolicy Bypass -File install-openclaw-windows.ps1 -Install

# 不推荐（永久修改）
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser  # 仅当你理解其含义时才使用
```

---

## 已知限制

- 本安装器未经过任何安全审计
- 尚不支持安装包的签名验证（待 OpenClaw 官方提供机制）
- 如发现安全问题，请通过 GitHub Issues 报告
