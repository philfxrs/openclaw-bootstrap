#!/usr/bin/env bash
# install.sh — OpenClaw Bootstrap 主入口（macOS）
# ==========================================================
# 用法：
#   bash install.sh              # 全新安装
#   bash install.sh install      # 同上
#   bash install.sh upgrade      # 升级 OpenClaw 及依赖
#   bash install.sh repair       # 修复/重新安装缺失组件
#   bash install.sh config       # 重新生成默认配置
#   bash install.sh reset        # 重置为出厂配置
#   bash install.sh verify       # 仅执行安装验证
#   bash install.sh help         # 显示帮助
#
# 环境变量：
#   OPENCLAW_NONINTERACTIVE=1    跳过交互确认
#   OPENCLAW_REQUIRED_DISK_MB    最小磁盘需求（MB，默认 2048）
#   OPENCLAW_NODE_MIN_MAJOR      Node.js 最低主版本（默认 18）
#   OPENCLAW_CONFIG_DIR          配置目录（默认 ~/.config/openclaw）
# ==========================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- 加载模块 --------------------------------------------------
# shellcheck source=lib/logger.sh
source "${SCRIPT_DIR}/lib/logger.sh"
# shellcheck source=lib/preflight.sh
source "${SCRIPT_DIR}/lib/preflight.sh"
# shellcheck source=lib/installer.sh
source "${SCRIPT_DIR}/lib/installer.sh"
# shellcheck source=lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=lib/verify.sh
source "${SCRIPT_DIR}/lib/verify.sh"
# shellcheck source=lib/upgrade.sh
source "${SCRIPT_DIR}/lib/upgrade.sh"

# ---- 帮助信息 --------------------------------------------------
_show_help() {
  cat <<EOF

$(echo -e "\033[1mOpenClaw Bootstrap 安装器\033[0m")

用法：
  bash install.sh [命令]

命令：
  install    （默认）全新安装：预检 → 安装 → 配置 → 验证
  upgrade    升级 OpenClaw 及所有依赖
  repair     修复/重新安装缺失组件
  config     重新初始化配置文件
  reset      重置为出厂默认配置（会备份旧配置）
  verify     仅验证当前安装状态
  help       显示此帮助

环境变量：
  OPENCLAW_NONINTERACTIVE=1    跳过所有交互确认
  OPENCLAW_REQUIRED_DISK_MB    安装所需最小磁盘空间（MB）
  OPENCLAW_NODE_MIN_MAJOR      Node.js 最低主版本号
  OPENCLAW_CONFIG_DIR          覆盖默认配置目录

EOF
}

# ---- 操作系统检测 ----------------------------------------------
_assert_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "此脚本仅支持 macOS。"
    log_hint  "Windows 用户请运行：pwsh install.ps1"
    exit 1
  fi
}

# ---- 全新安装流程 ----------------------------------------------
run_full_install() {
  log_banner "OpenClaw Bootstrap — 全新安装"
  run_preflight_checks
  run_install
  run_config
  run_verify
  echo ""
  log_ok "🎉 OpenClaw 安装完成！"
  log_hint "运行 'openclaw --help' 开始使用。"
}

# ---- 分发命令 --------------------------------------------------
main() {
  _assert_macos

  local cmd="${1:-install}"

  case "$cmd" in
    install)  run_full_install ;;
    upgrade)  run_upgrade ;;
    repair)   run_repair ;;
    config)   run_config ;;
    reset)    run_reset ;;
    verify)   run_verify ;;
    help|--help|-h) _show_help ;;
    *)
      log_error "未知命令：${cmd}"
      _show_help
      exit 1
      ;;
  esac
}

main "$@"
