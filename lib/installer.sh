#!/usr/bin/env bash
# lib/installer.sh — 安装模块（Homebrew + OpenClaw 官方安装链路）
# ---------------------------------------------------------------
# 用法：source lib/installer.sh
#        run_install

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# ---- Homebrew --------------------------------------------------

_is_homebrew_installed() {
  _check_command brew
}

_check_command() {
  command -v "$1" &>/dev/null
}

install_homebrew() {
  if _is_homebrew_installed; then
    log_ok "Homebrew 已安装（$(brew --version | head -1)）"
    return 0
  fi

  log_step "正在安装 Homebrew …"
  log_hint "Homebrew 是 macOS 上最常用的包管理器，安装需要联网，可能需要几分钟。"

  if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log_error "Homebrew 安装失败。"
    log_hint  "常见解决方法："
    log_hint  "  1. 检查网络，确保可访问 raw.githubusercontent.com"
    log_hint  "  2. 手动安装 Homebrew：https://brew.sh"
    return 1
  fi

  # Apple Silicon 路径适配
  local brew_path="/usr/local/bin/brew"
  if [ -f "/opt/homebrew/bin/brew" ]; then
    brew_path="/opt/homebrew/bin/brew"
    eval "$("$brew_path" shellenv)"
  fi

  log_ok "Homebrew 安装成功（$(brew --version | head -1)）"
}

# ---- Node.js ---------------------------------------------------

_node_version_ok() {
  local min_major="${OPENCLAW_NODE_MIN_MAJOR:-18}"
  local current
  current=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
  [ -n "$current" ] && [ "$current" -ge "$min_major" ]
}

install_node() {
  if _check_command node && _node_version_ok; then
    log_ok "Node.js 已安装（$(node --version)），版本符合要求。"
    return 0
  fi

  log_step "正在通过 Homebrew 安装 Node.js …"
  if ! brew install node; then
    log_error "Node.js 安装失败。"
    log_hint  "您也可以手动从 https://nodejs.org 下载安装包。"
    return 1
  fi
  log_ok "Node.js 安装成功（$(node --version)）"
}

# ---- Git -------------------------------------------------------

install_git() {
  if _check_command git; then
    log_ok "Git 已安装（$(git --version)）"
    return 0
  fi

  log_step "正在通过 Homebrew 安装 Git …"
  if ! brew install git; then
    log_error "Git 安装失败。"
    return 1
  fi
  log_ok "Git 安装成功（$(git --version)）"
}

# ---- OpenClaw 本体 ---------------------------------------------

install_openclaw() {
  if _check_command openclaw; then
    log_ok "OpenClaw 已安装（$(openclaw --version 2>/dev/null || echo '版本未知')）"
    log_hint "如需升级，请运行：$0 upgrade"
    return 0
  fi

  log_step "正在安装 OpenClaw …"
  log_hint "将通过官方推荐安装方式（npm 全局安装）进行，请稍候。"

  if ! npm install -g openclaw 2>/dev/null; then
    log_warn "npm 安装未成功，尝试 curl 安装链路 …"
    if curl -fsSL https://install.openclaw.ai/install.sh -o /tmp/openclaw_install.sh \
        && bash /tmp/openclaw_install.sh; then
      rm -f /tmp/openclaw_install.sh
      log_ok "OpenClaw 通过官方脚本安装成功。"
    else
      rm -f /tmp/openclaw_install.sh
      log_error "OpenClaw 安装失败。"
      log_hint  "请尝试手动安装：npm install -g openclaw"
      log_hint  "或访问官方文档：https://github.com/openclaw/openclaw"
      return 1
    fi
  else
    log_ok "OpenClaw 通过 npm 安装成功（$(openclaw --version 2>/dev/null || echo '版本未知')）"
  fi
}

# ---- 汇总入口 --------------------------------------------------

run_install() {
  log_section "安装依赖与 OpenClaw"

  install_homebrew || return 1
  install_git      || return 1
  install_node     || return 1
  install_openclaw || return 1

  log_ok "所有组件安装完成。"
}
