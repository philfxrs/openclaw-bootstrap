#!/usr/bin/env bash
# lib/config.sh — 安装后初始化配置模块
# -------------------------------------------------------
# 用法：source lib/config.sh
#        run_config

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# ---- 配置目录 --------------------------------------------------
OPENCLAW_CONFIG_DIR="${OPENCLAW_CONFIG_DIR:-$HOME/.config/openclaw}"
OPENCLAW_CONFIG_FILE="${OPENCLAW_CONFIG_DIR}/config.json"

# ---- 确保配置目录存在 ------------------------------------------
_ensure_config_dir() {
  if [ ! -d "$OPENCLAW_CONFIG_DIR" ]; then
    mkdir -p "$OPENCLAW_CONFIG_DIR"
    log_ok "配置目录已创建：${OPENCLAW_CONFIG_DIR}"
  else
    log_info "配置目录已存在：${OPENCLAW_CONFIG_DIR}"
  fi
}

# ---- 写入默认配置（仅当配置文件不存在时）-----------------------
_write_default_config() {
  if [ -f "$OPENCLAW_CONFIG_FILE" ]; then
    log_info "配置文件已存在，跳过默认写入：${OPENCLAW_CONFIG_FILE}"
    return 0
  fi

  cat > "$OPENCLAW_CONFIG_FILE" <<'EOF'
{
  "version": "1.0",
  "language": "zh-CN",
  "telemetry": false,
  "autoUpdate": true,
  "logLevel": "info"
}
EOF
  log_ok "默认配置文件已写入：${OPENCLAW_CONFIG_FILE}"
}

# ---- Shell 集成（追加 PATH 配置）-------------------------------
_setup_shell_integration() {
  local shell_rc=""
  case "$SHELL" in
    */zsh)  shell_rc="$HOME/.zshrc"  ;;
    */bash) shell_rc="$HOME/.bashrc" ;;
    *)      shell_rc="$HOME/.profile" ;;
  esac

  local marker="# openclaw-bootstrap"
  if grep -q "$marker" "$shell_rc" 2>/dev/null; then
    log_info "Shell 集成已存在，跳过写入（${shell_rc}）。"
    return 0
  fi

  {
    echo ""
    echo "$marker"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
  } >> "$shell_rc"
  log_ok "Shell 集成已写入 ${shell_rc}，重新打开终端后生效。"
}

# ---- 交互式初始化（可通过 OPENCLAW_NONINTERACTIVE=1 跳过）------
_interactive_onboard() {
  if [ "${OPENCLAW_NONINTERACTIVE:-0}" = "1" ]; then
    log_info "非交互模式，跳过 openclaw onboard。"
    return 0
  fi

  if ! command -v openclaw &>/dev/null; then
    log_warn "openclaw 命令未找到，跳过 onboard 步骤。"
    return 0
  fi

  log_step "正在运行 openclaw onboard（初始化向导）…"
  log_hint  "如果向导卡住，可按 Ctrl+C 跳过，稍后手动运行：openclaw onboard"
  openclaw onboard || log_warn "onboard 未能完成，请稍后手动运行：openclaw onboard"
}

# ---- 汇总入口 --------------------------------------------------
run_config() {
  log_section "初始化配置"
  _ensure_config_dir
  _write_default_config
  _setup_shell_integration
  _interactive_onboard
  log_ok "配置初始化完成。"
}

# ---- 重置配置（供 upgrade.sh 调用）----------------------------
reset_config() {
  log_section "重置配置"
  if [ -f "$OPENCLAW_CONFIG_FILE" ]; then
    local backup="${OPENCLAW_CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$OPENCLAW_CONFIG_FILE" "$backup"
    log_info "旧配置已备份至：${backup}"
    rm -f "$OPENCLAW_CONFIG_FILE"
  fi
  _write_default_config
  log_ok "配置已重置为默认值。"
}
