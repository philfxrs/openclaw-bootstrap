#!/usr/bin/env bash
# lib/upgrade.sh — 升级 / 修复 / 重置配置模块
# -------------------------------------------------------
# 用法：source lib/upgrade.sh
#        run_upgrade   # 升级 OpenClaw 及依赖
#        run_repair    # 重新安装缺失组件
#        run_reset     # 重置为默认配置

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"
# shellcheck source=lib/installer.sh
source "$(dirname "${BASH_SOURCE[0]}")/installer.sh"
# shellcheck source=lib/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
# shellcheck source=lib/verify.sh
source "$(dirname "${BASH_SOURCE[0]}")/verify.sh"

# ---- 升级 ------------------------------------------------------
run_upgrade() {
  log_section "升级 OpenClaw 及依赖"

  if ! command -v brew &>/dev/null; then
    log_warn "Homebrew 未安装，跳过依赖升级。"
  else
    log_step "正在更新 Homebrew …"
    brew update || log_warn "brew update 失败，继续升级其他组件。"

    log_step "正在升级 Node.js …"
    brew upgrade node 2>/dev/null && log_ok "Node.js 升级成功。" \
      || log_info "Node.js 已是最新版本或升级失败（非致命）。"

    log_step "正在升级 Git …"
    brew upgrade git 2>/dev/null && log_ok "Git 升级成功。" \
      || log_info "Git 已是最新版本或升级失败（非致命）。"
  fi

  log_step "正在升级 OpenClaw …"
  if command -v npm &>/dev/null && npm update -g openclaw 2>/dev/null; then
    log_ok "OpenClaw 通过 npm 升级成功（$(openclaw --version 2>/dev/null || echo '版本未知')）。"
  elif command -v openclaw &>/dev/null && openclaw upgrade 2>/dev/null; then
    log_ok "OpenClaw 通过自身 upgrade 命令升级成功。"
  else
    log_warn "OpenClaw 自动升级失败，请尝试手动运行：npm update -g openclaw"
  fi

  log_ok "升级流程完成。"
  run_verify || true
}

# ---- 修复 ------------------------------------------------------
run_repair() {
  log_section "修复安装"
  log_hint "将重新安装所有缺失组件，已安装的组件不会被重复安装。"

  install_homebrew || log_warn "Homebrew 修复失败，后续步骤可能受影响。"
  install_git      || log_warn "Git 修复失败。"
  install_node     || log_warn "Node.js 修复失败。"
  install_openclaw || log_warn "OpenClaw 修复失败。"

  log_ok "修复流程完成。"
  run_verify || true
}

# ---- 重置配置 --------------------------------------------------
run_reset() {
  log_section "重置配置"
  log_warn "此操作将备份并重置 OpenClaw 配置文件，程序本身不会被卸载。"
  log_hint  "配置目录：${OPENCLAW_CONFIG_DIR:-$HOME/.config/openclaw}"

  if [ "${OPENCLAW_NONINTERACTIVE:-0}" != "1" ]; then
    read -r -p "确认重置配置？[y/N] " answer
    case "$answer" in
      [yY][eE][sS]|[yY]) ;;
      *) log_info "已取消重置。"; return 0 ;;
    esac
  fi

  reset_config
  log_ok "配置已重置。如需重新运行初始化向导，请执行：openclaw onboard"
}
