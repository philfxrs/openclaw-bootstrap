# 冒烟测试说明

本文档说明如何对 OpenClaw Bootstrap Installer 进行冒烟测试。

## 什么是冒烟测试

冒烟测试是快速验证安装脚本核心路径是否正常的最小化测试集。
通过冒烟测试并不意味着完全没有问题，但它能快速发现严重的阻断性缺陷。

## macOS 冒烟测试

### 前置条件
- macOS 13+ (Ventura 或更高)
- 已安装 Node.js >= 22.0.0
- 已安装 npm
- 网络可用

### 测试步骤

```bash
# 1. 语法检查 — 所有脚本可被 bash 正确解析
for f in bootstrap/macos/*.sh; do
    bash -n "$f" && echo "✓ $f" || echo "✗ $f"
done

# 2. 帮助信息 — 主脚本可正常显示帮助
bash bootstrap/macos/install-openclaw-macos.sh --help

# 3. 预检查 — 单独运行预检查（不实际安装）
bash bootstrap/macos/install-openclaw-macos.sh --verify

# 4. 非交互模式 — 检查非交互标志生效
bash bootstrap/macos/install-openclaw-macos.sh --install --non-interactive --verbose 2>&1 | head -50
# 观察：应显示预检查步骤，不应弹出任何交互提示
```

## Windows 冒烟测试

### 前置条件
- Windows 10/11
- PowerShell 5.1 或 7.x
- 已安装 Node.js >= 22.0.0
- 已安装 npm
- 网络可用

### 测试步骤

```powershell
# 1. 语法检查 — 所有脚本可被 PowerShell 正确解析
Get-ChildItem bootstrap\windows\*.ps1 | ForEach-Object {
    try {
        [System.Management.Automation.Language.Parser]::ParseFile(
            $_.FullName, [ref]$null, [ref]$null
        ) | Out-Null
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    } catch {
        Write-Host "✗ $($_.Name)" -ForegroundColor Red
    }
}

# 2. 帮助信息 — 主脚本可正常显示帮助
powershell -ExecutionPolicy Bypass -File bootstrap\windows\install-openclaw-windows.ps1 -Help

# 3. 预检查 — 单独运行验证
powershell -ExecutionPolicy Bypass -File bootstrap\windows\install-openclaw-windows.ps1 -Verify

# 4. 非交互模式 — 检查非交互标志生效
powershell -ExecutionPolicy Bypass -File bootstrap\windows\install-openclaw-windows.ps1 -Install -NonInteractive -VerboseMode
# 观察：应显示预检查步骤，不应弹出任何交互提示
```

## 判定标准

| 步骤 | 通过标准 |
|------|----------|
| 语法检查 | 所有文件 ✓ |
| 帮助信息 | 正常输出，退出码 0 |
| 预检查/验证 | 正常输出检查结果 |
| 非交互模式 | 无交互提示，正常执行 |

## 失败时

如果冒烟测试失败：
1. 检查错误信息中指出的具体文件和行号
2. 参考 `docs/TROUBLESHOOTING.md` 排查常见问题
3. 运行 lint 工具查找代码问题:
   - macOS: `bash scripts/lint-shell.sh`
   - Windows: `pwsh scripts/lint-powershell.ps1`
