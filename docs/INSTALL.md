# 安装指南

## 前提条件

| 项目 | macOS | Windows |
|------|-------|----------|
| 操作系统 | macOS 12+（推荐 13+） | Windows 10 22H2 / Windows 11 |
| 架构 | Apple Silicon / Intel | x64 / arm64 |
| Node.js | >= 22.0.0 | >= 22.0.0 |
| npm | >= 10.0.0 (Node 22 自带) | >= 10.0.0 |
| Shell | zsh / bash | PowerShell 5.1+ |
| 网络 | 可连接 registry.npmjs.org | 可连接 registry.npmjs.org |

## 安装步骤

### 阶段一：预检查

安装脚本会自动检查以下项目：

| 检查项 | 说明 |
|--------|------|
| 操作系统版本 | 验证 macOS/Windows 版本支持 |
| 架构 | 验证 CPU 架构支持 |
| Node.js 版本 | >= 22.0.0 |
| npm 可用性 | 验证 npm 已就绪（随 Node 安装） |
| PATH 环境 | node 在 PATH 中可调用 |
| 网络连通 | 可刺孔 registry.npmjs.org |
| 来源白名单 | 查看目标 URL 在白名单中 |

### 阶段二：安装

```
npm install -g openclaw
```

支持幂等操作：已安装时提示更新或重安。

### 阶段三：配置

交互式配置向导：

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| 工作目录 | OpenClaw 工作文件存放位置 | ~/openclaw |
| Daemon | 是否启动 Daemon 服务 | 否 |
| Provider | 配置 AI 服务提供商 | （可选） |
| Onboarding | 是否立即运行 onboarding | 是 |

### 阶段四：验证

安装器自动验证：
- `openclaw` 命令可展开
- 版本符合预期
- PATH 设置正确
- 验证基本命令可执行
- 配置文件存在

## 非交互模式

适合 CI / 自动化环境：

```bash
# macOS
bash install-openclaw-macos.sh --install --non-interactive

# Windows
powershell -ExecutionPolicy Bypass -File install-openclaw-windows.ps1 -Install -NonInteractive
```

非交互模式下所有向导使用默认值或环境变量，不弹出任何用户提示。

## 卸载

```bash
npm uninstall -g openclaw
```

配置文件位于：
- macOS: `~/.config/openclaw/`
- Windows: `%APPDATA%\openclaw\`

如需删除配置：
```bash
# macOS
rm -rf ~/.config/openclaw

# Windows
Remove-Item -Recurse "$env:APPDATA\openclaw"
```
