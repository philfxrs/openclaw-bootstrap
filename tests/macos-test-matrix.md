# macOS 测试矩阵

本文档定义 macOS 平台的测试覆盖矩阵。

## 硬件架构

| 架构 | 说明 | 优先级 |
|------|------|--------|
| Apple Silicon (arm64) | M1/M2/M3/M4 系列 | P0 |
| Intel (x86_64) | 2020 年及更早的 Mac | P1 |

## macOS 版本

| 版本 | 名称 | 优先级 | 备注 |
|------|------|--------|------|
| 15.x | Sequoia | P0 | 当前最新 |
| 14.x | Sonoma | P0 | 主流使用 |
| 13.x | Ventura | P1 | 仍在支持 |
| 12.x | Monterey | P2 | 逐步退出支持 |

## Shell 环境

| Shell | 优先级 | 备注 |
|-------|--------|------|
| zsh | P0 | macOS 默认 shell (Catalina+) |
| bash | P1 | 旧版 macOS 默认 |

## Node.js 安装方式

| 安装方式 | 优先级 | 注意事项 |
|----------|--------|----------|
| Homebrew | P0 | 最常用 |
| 官方安装包 | P0 | 从 nodejs.org 下载 |
| nvm | P1 | 开发者常用 |
| fnm | P2 | 新兴版本管理器 |
| volta | P2 | 另一种版本管理器 |

## 测试矩阵

### 优先级 P0（必须通过）

| # | 架构 | macOS | Shell | Node 方式 | 场景 |
|---|------|-------|-------|-----------|------|
| 1 | arm64 | 15.x | zsh | Homebrew | 全新安装 |
| 2 | arm64 | 14.x | zsh | 官方安装包 | 全新安装 |
| 3 | arm64 | 15.x | zsh | Homebrew | 升级 |
| 4 | arm64 | 15.x | zsh | - | Node 缺失 |
| 5 | arm64 | 15.x | zsh | Homebrew | 修复 |

### 优先级 P1（应该通过）

| # | 架构 | macOS | Shell | Node 方式 | 场景 |
|---|------|-------|-------|-----------|------|
| 6 | x86_64 | 14.x | zsh | Homebrew | 全新安装 |
| 7 | arm64 | 13.x | zsh | nvm | 全新安装 |
| 8 | arm64 | 15.x | bash | Homebrew | 全新安装 |
| 9 | arm64 | 15.x | zsh | - | Node 版本过低 |
| 10 | arm64 | 15.x | zsh | Homebrew | 非交互安装 |

### 优先级 P2（可选）

| # | 架构 | macOS | Shell | Node 方式 | 场景 |
|---|------|-------|-------|-----------|------|
| 11 | x86_64 | 12.x | bash | 官方安装包 | 全新安装 |
| 12 | arm64 | 15.x | zsh | volta | 全新安装 |
| 13 | arm64 | 15.x | zsh | Homebrew | 网络断开 |
| 14 | arm64 | 15.x | zsh | Homebrew | 重置配置 |

## 额外注意事项

- Rosetta 2 环境下的兼容性
- Homebrew 在 `/opt/homebrew`（arm64）vs `/usr/local`（x86_64）的路径差异
- SIP (System Integrity Protection) 对文件操作的影响
- FileVault 加密环境
