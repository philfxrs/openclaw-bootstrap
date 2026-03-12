# 故障排查指南

## 目录

- [Node.js 相关](#nodejs-相关)
- [PATH 问题](#path-问题)
- [Windows ExecutionPolicy](#windows-executionpolicy)
- [代理网络](#代理网络)
- [安装失败](#安装失败)
- [配置问题](#配置问题)
- [Daemon 问题](#daemon-问题)
- [日志位置](#日志位置)

---

## Node.js 相关

### 错误: Node.js 未找到 / 版本过低

**现象**: 预检查失败，提示需要 Node.js >= 22.0.0

**macOS 解决方案**:
```bash
# Homebrew 安装
brew install node@22

# 或者从官网下载 LTS 安装包
# https://nodejs.org/

# 验证
node --version  # 应显示 >= v22.0.0
```

**Windows 解决方案**:
```powershell
# 从官网下载 .msi 安装包
# https://nodejs.org/

# 安装后重新打开 PowerShell 并验证
node --version
```

**nvm 用户 (macOS)**:
```bash
nvm install 22
nvm use 22
nvm alias default 22
```

### 错误: `node` 命令不在 PATH 中

参见下方 [PATH 问题](#path-问题) 部分。

---

## PATH 问题

### macOS: npm 全局安装的命令不可用

**方案**:
```bash
# 查看 npm 全局目录
npm config get prefix
# 输出类似: /usr/local 或 /opt/homebrew

# 检查 ~/.zshrc 或 ~/.bash_profile
grep -n 'PATH' ~/.zshrc

# 添加到 PATH 方式 (Homebrew arm64 示例)
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 也可以运行修复命令
bash install-openclaw-macos.sh --repair
```

### Windows: npm 全局安装目录不在 PATH

**方案**:
```powershell
# 查看 npm 全局目录
npm config get prefix

# 运行修复命令自动修正
.\install-openclaw-windows.ps1 -Repair

# 或手动添加
$npmGlobal = (npm config get prefix) + "\node_modules\.bin"
[Environment]::SetEnvironmentVariable(
    "PATH",
    $env:PATH + ";$npmGlobal",
    [EnvironmentVariableTarget]::User
)
```

---

## Windows ExecutionPolicy

### 错误: 无法加载文件...因为在此系统上禁止运行脚本

**现象**: PowerShell ExecutionPolicy 为 `Restricted`

**解决方案**:

```powershell
# 方案 1（推荐）：使用 -ExecutionPolicy Bypass 启动
# 不修改系统设置，仅对当前会话生效
powershell -ExecutionPolicy Bypass -File install-openclaw-windows.ps1 -Install

# 方案 2：修改当前用户策略
# 请确保了解其含义
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 代理网络

### 现象: 安装器无法连接到 npm / GitHub

**macOS**:
```bash
# 在终端中设置代理
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080
export NO_PROXY=localhost,127.0.0.1

# 然后重新运行安装器
bash install-openclaw-macos.sh --install
```

**Windows**:
```powershell
# 设置代理
$env:HTTP_PROXY = "http://proxy.example.com:8080"
$env:HTTPS_PROXY = "http://proxy.example.com:8080"
$env:NO_PROXY = "localhost,127.0.0.1"

# 然后重新运行安装器
.\install-openclaw-windows.ps1 -Install
```

---

## 安装失败

### 错误: npm install -g openclaw 失败

**可能原因**:
1. 网络问题 → 检查代理配置
2. npm 权限问题 (macOS) → 运行 `npm config get prefix` 确认路径
3. npm 缓存损坏 → `npm cache clean --force`
4. 包不存在 → 检查 npm 上是否有 `openclaw` 包

### 错误: 重复安装报错

```bash
# macOS: 先卸载再重安装
npm uninstall -g openclaw
bash install-openclaw-macos.sh --install

# Windows
npm uninstall -g openclaw
.\install-openclaw-windows.ps1 -Install
```

---

## 配置问题

### 现象: 配置文件损坏 / 错误

**方案**:
```bash
# 重置配置（备份当前配置并重新配置）
bash install-openclaw-macos.sh --reset-config

# Windows
.\install-openclaw-windows.ps1 -ResetConfig
```

**配置文件位置**:
- macOS: `~/.config/openclaw/`
- Windows: `%APPDATA%\openclaw\`

---

## Daemon 问题

### 现象: Daemon 无法启动

**方案**:
```bash
# 验证安装状态
bash install-openclaw-macos.sh --verify

# 修复
bash install-openclaw-macos.sh --repair
```

---

## 日志位置

| 平台 | 日志目录 |
|------|----------|
| macOS | `~/Library/Logs/openclaw-bootstrap/` |
| Windows | `%LOCALAPPDATA%\openclaw-bootstrap\logs\` |

```bash
# macOS: 查看最新日志
tail -50 ~/Library/Logs/openclaw-bootstrap/<latest-log-file>

# Windows: 查看日志
Get-ChildItem "$env:LOCALAPPDATA\openclaw-bootstrap\logs\" | Sort-Object LastWriteTime | Select-Object -Last 1
```

当请求支持时，请一并提供日志文件内容（注意隐消敏感信息）。
