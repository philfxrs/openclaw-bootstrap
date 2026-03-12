#!/usr/bin/env bash
# lib/verify.sh — 安装验证模块
# -------------------------------------------------------
# 用法：source lib/verify.sh
#        run_verify

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# ---- 工具 ------------------------------------------------------
_check_command() {
  command -v "$1" &>/dev/null
}

# ---- 单项检查辅助 -----------------------------------------------
_assert_command() {
  local cmd="$1"
  local label="${2:-$1}"
  if _check_command "$cmd"; then
    log_ok "${label} 可用（$($cmd --version 2>/dev/null | head -1 || echo '版本未知')）"
    return 0
  else
    log_error "${label} 未找到，安装可能未完成。"
    return 1
  fi
}

# ---- 验证 Homebrew ---------------------------------------------
_verify_homebrew() {
  if _check_command brew; then
    log_ok "Homebrew 可用（$(brew --version | head -1)）"
  else
    log_error "Homebrew 未找到。"
    log_hint  "请运行：$0 repair"
    return 1
  fi
}

# ---- 验证 Node.js ----------------------------------------------
_verify_node() {
  _assert_command node "Node.js" || return 1
  local min_major="${OPENCLAW_NODE_MIN_MAJOR:-18}"
  local current
  current=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
  if [ -z "$current" ] || [ "$current" -lt "$min_major" ]; then
    log_error "Node.js 版本（v${current}）低于最低要求 v${min_major}。"
    log_hint  "请运行：brew upgrade node"
    return 1
  fi
}

# ---- 验证 Git --------------------------------------------------
_verify_git() {
  _assert_command git "Git"
}

# ---- 验证 OpenClaw ---------------------------------------------
_verify_openclaw() {
  if ! _check_command openclaw; then
    log_error "openclaw 命令未找到。"
    log_hint  "请检查安装日志，或运行：$0 repair"
    return 1
  fi

  local ver
  ver=$(openclaw --version 2>/dev/null | head -1)
  log_ok "OpenClaw 已安装（${ver:-版本未知}）"

  # 快速健康检查
  if openclaw --help &>/dev/null; then
    log_ok "openclaw --help 响应正常。"
  else
    log_warn "openclaw --help 返回异常，请查阅官方文档排查。"
  fi
}

# ---- 验证配置文件 ----------------------------------------------
_verify_config() {
  local cfg="${OPENCLAW_CONFIG_DIR:-$HOME/.config/openclaw}/config.json"
  if [ -f "$cfg" ]; then
    log_ok "配置文件存在：${cfg}"
  else
    log_warn "配置文件未找到：${cfg}"
    log_hint  "可运行：$0 config  来重新生成默认配置。"
  fi
}

# ---- 汇总入口 --------------------------------------------------
run_verify() {
  log_section "验证安装结果"
  local failed=0

  _verify_homebrew || failed=$((failed + 1))
  _verify_git      || failed=$((failed + 1))
  _verify_node     || failed=$((failed + 1))
  _verify_openclaw || failed=$((failed + 1))
  _verify_config

  echo ""
  if [ "$failed" -eq 0 ]; then
    log_ok "✅ 所有验证项通过！OpenClaw 已就绪。"
    log_hint "运行 'openclaw --help' 查看可用命令。"
  else
    log_error "❌ 有 ${failed} 项验证未通过，请按上述提示修复。"
    log_hint  "如需一键修复，请运行：$0 repair"
    return 1
  fi
}
