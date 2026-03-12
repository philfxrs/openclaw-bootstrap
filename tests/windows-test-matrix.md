# Windows 测试矩阵

本文档定义 Windows 平台的测试覆盖矩阵。

## Windows 版本

| 版本 | 优先级 | 备注 |
|------|--------|------|
| Windows 11 23H2+ | P0 | 当前最新 |
| Windows 11 22H2 | P0 | 主流使用 |
| Windows 10 22H2 | P1 | 仍在支持 |
| Windows Server 2022 | P2 | 服务器场景 |

## PowerShell 版本

| 版本 | 优先级 | 备注 |
|------|--------|------|
| PowerShell 5.1 | P0 | Windows 内置 |
| PowerShell 7.4+ | P0 | 跨平台最新 |
| PowerShell 7.2 LTS | P1 | 长期支持版 |

## 权限模式

| 模式 | 优先级 | 说明 |
|------|--------|------|
| 普通用户 | P0 | 标准用户权限 |
| 管理员 (Run as Admin) | P1 | 提升权限 |

## 网络环境

| 环境 | 优先级 | 说明 |
|------|--------|------|
| 直连 (家庭/办公) | P0 | 无代理 |
| 企业代理 (HTTP_PROXY) | P1 | 外资/大型公司 |
| 系统代理 (注册表) | P2 | Windows 系统级代理 |

## ExecutionPolicy

| 策略 | 优先级 | 说明 |
|------|--------|------|
| RemoteSigned | P0 | 推荐设置 |
| Restricted | P1 | Windows 默认（需处理） |
| AllSigned | P2 | 严格环境 |
| Bypass (临时) | P0 | 脚本推荐方式 |

## Node.js 安装方式

| 安装方式 | 优先级 | 注意事项 |
|----------|--------|----------|
| 官方安装包 | P0 | 从 nodejs.org 下载的 .msi |
| winget | P1 | Windows 包管理器 |
| nvm-windows | P1 | Windows 版 nvm |
| fnm | P2 | 快速版本管理器 |
| Scoop | P2 | 包管理器 |
| Chocolatey | P2 | 包管理器 |

## 测试矩阵

### 优先级 P0（必须通过）

| # | Windows | PS 版本 | 权限 | 网络 | EP | Node 方式 | 场景 |
|---|---------|---------|------|------|----|-----------|------|
| 1 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | 官方 .msi | 全新安装 |
| 2 | 11 23H2 | 7.4 | 普通 | 直连 | Bypass | 官方 .msi | 全新安装 |
| 3 | 11 22H2 | 5.1 | 普通 | 直连 | RemoteSigned | 官方 .msi | 全新安装 |
| 4 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | - | Node 缺失 |
| 5 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | 官方 .msi | 升级 |
| 6 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | 官方 .msi | 修复 |

### 优先级 P1（应该通过）

| # | Windows | PS 版本 | 权限 | 网络 | EP | Node 方式 | 场景 |
|---|---------|---------|------|------|----|-----------|------|
| 7 | 10 22H2 | 5.1 | 普通 | 直连 | RemoteSigned | 官方 .msi | 全新安装 |
| 8 | 11 23H2 | 5.1 | 普通 | 企业代理 | Bypass | 官方 .msi | 全新安装 |
| 9 | 11 23H2 | 5.1 | 管理员 | 直连 | Bypass | 官方 .msi | 全新安装 |
| 10 | 11 23H2 | 5.1 | 普通 | 直连 | Restricted | 官方 .msi | EP 受限 |
| 11 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | nvm-windows | 全新安装 |
| 12 | 11 23H2 | 7.2 | 普通 | 直连 | Bypass | winget | 全新安装 |
| 13 | 11 23H2 | 5.1 | 普通 | 直连 | Bypass | 官方 .msi | 非交互安装 |

### 优先级 P2（可选）

| # | Windows | PS 版本 | 权限 | 网络 | EP | Node 方式 | 场景 |
|---|---------|---------|------|------|----|-----------|------|
| 14 | Server 2022 | 5.1 | 管理员 | 直连 | RemoteSigned | 官方 .msi | 全新安装 |
| 15 | 11 23H2 | 5.1 | 普通 | 直连 | AllSigned | 官方 .msi | 严格策略 |
| 16 | 11 23H2 | 5.1 | 普通 | 系统代理 | Bypass | Chocolatey | 全新安装 |
| 17 | 11 23H2 | 5.1 | 普通 | 断开 | Bypass | 官方 .msi | 网络断开 |
| 18 | 10 22H2 | 7.4 | 管理员 | 企业代理 | RemoteSigned | Scoop | 全新安装 |

## 额外注意事项

- 中文用户名路径（例如 `C:\Users\张三`）
- 路径中包含空格
- npm 全局安装路径在不同安装方式下的差异
- Windows Defender 对下载文件的拦截
- 企业组策略对 PowerShell 的限制
- Windows Terminal vs 传统 cmd / PowerShell 窗口
