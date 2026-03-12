# 升级指南

## 升级命令

```bash
# macOS
bash install-openclaw-macos.sh --upgrade

# Windows
powershell -ExecutionPolicy Bypass -File install-openclaw-windows.ps1 -Upgrade
```

## 升级流程

1. **预检查** — 验证当前环境满足升级条件
2. **备份** — 备份当前配置文件（`config.backup.<timestamp>.json`）
3. **执行升级** — `npm update -g openclaw`
4. **验证** — 验证升级后的安装状态
5. **完成提示** — 显示新版本信息和回滚方法

## 版本策略

`checks/version-policy.json` 定义了升级策略：

- `allow_major_upgrade: false` — 不自动处理跨大版本升级
- `backup_before_upgrade: true` — 升级前自动备份配置
- `verify_after_upgrade: true` — 升级后自动验证

## 备份详情

**macOS 备份位置**: `~/.config/openclaw/`
**Windows 备份位置**: `%APPDATA%\openclaw\`

备份文件命名格式：`config.backup.<timestamp>.json`

## 回滚方法

如果升级后出现问题：

```bash
# macOS
npm install -g openclaw@<old-version>

# Windows
npm install -g openclaw@<old-version>

# 恢复配置备份
cp ~/.config/openclaw/config.backup.<timestamp>.json ~/.config/openclaw/config.json
```

升级完成后安装器会显示具体回滚指导。

## 待定项

- 跨大版本升级的具体流程（待 OpenClaw 官方确认）
- 升级预览 / 更新日志获取方式
