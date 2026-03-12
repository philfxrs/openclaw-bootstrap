#!/usr/bin/env bash
# lib/logger.sh — 日志工具（颜色输出 + 中文友好提示）
# -------------------------------------------------------
# 用法：source lib/logger.sh

# ---- 颜色代码 --------------------------------------------------
_RESET="\033[0m"
_BOLD="\033[1m"
_RED="\033[0;31m"
_YELLOW="\033[0;33m"
_GREEN="\033[0;32m"
_CYAN="\033[0;36m"
_BLUE="\033[0;34m"

# 当输出不是终端时禁用颜色（如重定向到文件）
if [ ! -t 1 ]; then
  _RESET="" _BOLD="" _RED="" _YELLOW="" _GREEN="" _CYAN="" _BLUE=""
fi

# ---- 核心日志函数 -----------------------------------------------

# info: 普通信息（蓝色）
log_info() {
  echo -e "${_CYAN}[INFO]${_RESET}  $*"
}

# step: 操作步骤（带序号时由调用方传入前缀）
log_step() {
  echo -e "${_BLUE}${_BOLD}[步骤]${_RESET}  $*"
}

# ok: 成功（绿色）
log_ok() {
  echo -e "${_GREEN}[✔  OK]${_RESET}  $*"
}

# warn: 警告（黄色）
log_warn() {
  echo -e "${_YELLOW}[警告]${_RESET}  $*" >&2
}

# error: 错误（红色，输出到 stderr）
log_error() {
  echo -e "${_RED}[错误]${_RESET}  $*" >&2
}

# fatal: 严重错误，打印后退出
log_fatal() {
  echo -e "${_RED}${_BOLD}[致命]${_RESET}  $*" >&2
  echo -e "${_YELLOW}如需帮助，请访问：https://github.com/philfxrs/openclaw-bootstrap/issues${_RESET}" >&2
  exit 1
}

# hint: 操作提示（供下一步指引）
log_hint() {
  echo -e "${_YELLOW}[提示]${_RESET}  $*"
}

# banner: 打印醒目标题
log_banner() {
  local text="$*"
  local line
  line=$(printf '%0.s─' {1..50})
  echo -e "${_BOLD}${_CYAN}${line}${_RESET}"
  echo -e "${_BOLD}${_CYAN}  ${text}${_RESET}"
  echo -e "${_BOLD}${_CYAN}${line}${_RESET}"
}

# section: 小节标题
log_section() {
  echo ""
  echo -e "${_BOLD}▶ $*${_RESET}"
}
