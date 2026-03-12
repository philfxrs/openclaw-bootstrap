#!/usr/bin/env bash
# lib/preflight.sh — 环境预检模块
# -------------------------------------------------------
# 用法：source lib/preflight.sh
#        run_preflight_checks

# shellcheck source=lib/logger.sh
source "$(dirname "${BASH_SOURCE[0]}")/logger.sh"

# ---- 内部工具 --------------------------------------------------

_check_command() {
  command -v "$1" &>/dev/null
}

# ---- macOS 版本检查 --------------------------------------------
_check_macos_version() {
  local min_major=12  # Monterey
  local os_version
  os_version=$(sw_vers -productVersion 2>/dev/null)
  local major
  major=$(echo "$os_version" | cut -d. -f1)
  if [ -z "$major" ] || [ "$major" -lt "$min_major" ]; then
    log_error "检测到 macOS 版本：${os_version:-未知}"
    log_hint  "openclaw-bootstrap 要求 macOS ${min_major} (Monterey) 及以上。"
    log_hint  "请升级您的系统后重试。"
    return 1
  fi
  log_ok "macOS 版本：${os_version}（符合要求）"
}

# ---- 磁盘空间检查（默认 2 GB）----------------------------------
_check_disk_space() {
  local required_mb="${OPENCLAW_REQUIRED_DISK_MB:-2048}"
  local available_mb
  available_mb=$(df -m "$HOME" | awk 'NR==2 {print $4}')
  if [ -z "$available_mb" ] || [ "$available_mb" -lt "$required_mb" ]; then
    log_error "磁盘剩余空间不足。当前可用：${available_mb:-未知} MB，需要至少 ${required_mb} MB。"
    log_hint  "请清理磁盘后重试。"
    return 1
  fi
  log_ok "磁盘剩余空间：${available_mb} MB（符合要求）"
}

# ---- 网络连通性检查 --------------------------------------------
_check_network() {
  local test_host="github.com"
  if ! curl --silent --max-time 10 --head "https://${test_host}" &>/dev/null; then
    log_error "无法连接到 ${test_host}，请检查您的网络连接。"
    log_hint  "OpenClaw 安装需要访问 GitHub。如使用代理，请确保已正确配置。"
    return 1
  fi
  log_ok "网络连接正常（可访问 ${test_host}）"
}

# ---- Shell 兼容性检查 -----------------------------------------
_check_shell() {
  local bash_version="${BASH_VERSION%%.*}"
  if [ -z "$bash_version" ] || [ "$bash_version" -lt 3 ]; then
    log_error "Bash 版本过低（当前：${BASH_VERSION:-未知}），需要 Bash 3.x 及以上。"
    return 1
  fi
  log_ok "Bash 版本：${BASH_VERSION}"
}

# ---- 是否以 root 运行（警告而非阻止）--------------------------
_check_not_root() {
  if [ "$(id -u)" -eq 0 ]; then
    log_warn "检测到以 root 用户运行。建议以普通用户身份执行安装。"
  fi
}

# ---- 汇总入口 --------------------------------------------------
run_preflight_checks() {
  log_section "环境预检"
  local failed=0

  _check_shell        || failed=$((failed + 1))
  _check_not_root
  _check_macos_version || failed=$((failed + 1))
  _check_disk_space   || failed=$((failed + 1))
  _check_network      || failed=$((failed + 1))

  if [ "$failed" -gt 0 ]; then
    log_fatal "预检发现 ${failed} 项问题，请按上述提示解决后重新运行安装程序。"
  fi
  log_ok "所有预检项通过，开始安装。"
}
