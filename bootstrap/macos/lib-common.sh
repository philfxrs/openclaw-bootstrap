#!/usr/bin/env bash
# ============================================================================
# lib-common.sh — OpenClaw Bootstrap 公共函数库
# ============================================================================
# 提供统一的输出、日志、工具函数，供所有模块引用。
# ============================================================================

# 防止重复加载
[[ -n "${_LIB_COMMON_LOADED:-}" ]] && return 0
_LIB_COMMON_LOADED=1

# ========================================
# 颜色定义
# ========================================
if [[ -t 1 ]]; then
    COLOR_RESET="\033[0m"
    COLOR_RED="\033[1;31m"
    COLOR_GREEN="\033[1;32m"
    COLOR_YELLOW="\033[1;33m"
    COLOR_BLUE="\033[1;34m"
    COLOR_CYAN="\033[1;36m"
    COLOR_GRAY="\033[0;37m"
else
    COLOR_RESET=""
    COLOR_RED=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_BLUE=""
    COLOR_CYAN=""
    COLOR_GRAY=""
fi

# ========================================
# 全局变量
# ========================================
BOOTSTRAP_VERSION="0.1.0"
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${BOOTSTRAP_DIR}/../.." && pwd)"

# 日志目录
LOG_DIR="${HOME}/Library/Logs/openclaw-bootstrap"
LOG_FILE=""

# 配置目录
CONFIG_DIR="${HOME}/.config/openclaw"

# 工作目录
WORK_DIR="${HOME}/openclaw"

# 策略文件路径
VERSION_POLICY_FILE="${PROJECT_ROOT}/checks/version-policy.json"
SOURCE_ALLOWLIST_FILE="${PROJECT_ROOT}/checks/source-allowlist.json"

# 运行模式
NON_INTERACTIVE=false
VERBOSE_MODE=false

# 预检结果收集
declare -a PREFLIGHT_RESULTS=()
PREFLIGHT_HAS_FAIL=false

# ========================================
# 统一输出函数
# ========================================

log_info() {
    echo -e "${COLOR_BLUE}[信息]${COLOR_RESET} $*"
    _write_log "INFO" "$*"
}

log_success() {
    echo -e "${COLOR_GREEN}[成功]${COLOR_RESET} $*"
    _write_log "SUCCESS" "$*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[警告]${COLOR_RESET} $*"
    _write_log "WARN" "$*"
}

log_error() {
    echo -e "${COLOR_RED}[错误]${COLOR_RESET} $*" >&2
    _write_log "ERROR" "$*"
}

log_step() {
    echo -e "${COLOR_CYAN}[步骤]${COLOR_RESET} $*"
    _write_log "STEP" "$*"
}

log_debug() {
    if [[ "${VERBOSE_MODE}" == "true" ]]; then
        echo -e "${COLOR_GRAY}[调试]${COLOR_RESET} $*"
    fi
    _write_log "DEBUG" "$*"
}

# ========================================
# 结构化错误输出
# ========================================

print_error_detail() {
    local title="$1"
    local reason="$2"
    local impact="$3"
    local fix_steps="$4"
    local fix_commands="${5:-}"
    local log_location="${6:-${LOG_FILE}}"

    echo ""
    echo -e "${COLOR_RED}[错误] ${title}${COLOR_RESET}"
    echo ""
    echo "原因："
    echo "  ${reason}"
    echo ""
    echo "影响："
    echo "  ${impact}"
    echo ""
    echo "修复步骤："
    echo "${fix_steps}" | sed 's/^/  /'
    if [[ -n "${fix_commands}" ]]; then
        echo ""
        echo "建议命令 / 操作："
        echo "${fix_commands}" | sed 's/^/  /'
    fi
    if [[ -n "${log_location}" ]]; then
        echo ""
        echo "日志位置："
        echo "  ${log_location}"
    fi
    echo ""

    _write_log "ERROR_DETAIL" "title=${title} reason=${reason}"
}

# ========================================
# 日志系统
# ========================================

init_logging() {
    local log_type="${1:-install}"
    local date_str
    date_str="$(date '+%Y-%m-%d')"

    mkdir -p "${LOG_DIR}" 2>/dev/null || true
    LOG_FILE="${LOG_DIR}/${log_type}-${date_str}.log"
    touch "${LOG_FILE}" 2>/dev/null || true

    _write_log "INFO" "========== 日志开始 $(date '+%Y-%m-%d %H:%M:%S') =========="
    _write_log "INFO" "Bootstrap 版本: ${BOOTSTRAP_VERSION}"
    _write_log "INFO" "操作类型: ${log_type}"
}

_write_log() {
    local level="$1"
    shift
    local message="$*"
    if [[ -n "${LOG_FILE}" && -w "${LOG_FILE}" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] ${message}" >> "${LOG_FILE}"
    fi
}

# ========================================
# 预检结果收集
# ========================================

preflight_pass() {
    local item="$1"
    local detail="${2:-}"
    PREFLIGHT_RESULTS+=("PASS|${item}|${detail}")
    log_debug "预检通过: ${item} ${detail}"
}

preflight_warn() {
    local item="$1"
    local detail="${2:-}"
    PREFLIGHT_RESULTS+=("WARN|${item}|${detail}")
    log_warn "预检警告: ${item} - ${detail}"
}

preflight_fail() {
    local item="$1"
    local detail="${2:-}"
    PREFLIGHT_RESULTS+=("FAIL|${item}|${detail}")
    PREFLIGHT_HAS_FAIL=true
    log_error "预检失败: ${item} - ${detail}"
}

print_preflight_report() {
    echo ""
    echo "========================================"
    echo "  环境预检报告"
    echo "========================================"
    echo ""

    for result in "${PREFLIGHT_RESULTS[@]}"; do
        local status="${result%%|*}"
        local rest="${result#*|}"
        local item="${rest%%|*}"
        local detail="${rest#*|}"

        case "${status}" in
            PASS)
                echo -e "  ${COLOR_GREEN}\u2714 通过${COLOR_RESET}  ${item}  ${detail}"
                ;;
            WARN)
                echo -e "  ${COLOR_YELLOW}\u26a0 警告${COLOR_RESET}  ${item}  ${detail}"
                ;;
            FAIL)
                echo -e "  ${COLOR_RED}\u2718 失败${COLOR_RESET}  ${item}  ${detail}"
                ;;
        esac
    done

    echo ""
    echo "========================================"

    if [[ "${PREFLIGHT_HAS_FAIL}" == "true" ]]; then
        echo -e "  ${COLOR_RED}预检未通过，存在阻塞项，请先修复后重试。${COLOR_RESET}"
    else
        echo -e "  ${COLOR_GREEN}预检通过，可以继续安装。${COLOR_RESET}"
    fi
    echo "========================================"
    echo ""
}

# ========================================
# 工具函数
# ========================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

version_gte() {
    local v1="$1"
    local v2="$2"
    v1="${v1#v}"
    v2="${v2#v}"

    local IFS='.'
    local -a parts1=($v1)
    local -a parts2=($v2)

    for i in 0 1 2; do
        local p1="${parts1[$i]:-0}"
        local p2="${parts2[$i]:-0}"
        if (( p1 > p2 )); then
            return 0
        elif (( p1 < p2 )); then
            return 1
        fi
    done
    return 0
}

json_get_value() {
    local file="$1"
    local key="$2"
    if [[ ! -f "${file}" ]]; then
        echo ""
        return 1
    fi
    grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "${file}" \
        | head -1 \
        | sed 's/.*"'"${key}"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

json_get_bool() {
    local file="$1"
    local key="$2"
    local val
    val=$(grep -o "\"${key}\"[[:space:]]*:[[:space:]]*[a-z]*" "${file}" \
        | head -1 \
        | sed 's/.*:[[:space:]]*//')
    echo "${val}"
}

json_get_array_values() {
    local file="$1"
    local key="$2"
    if [[ ! -f "${file}" ]]; then
        return 1
    fi
    sed -n '/"'"${key}"'"[[:space:]]*:/,/\]/p' "${file}" \
        | grep '"' \
        | grep -v "\"${key}\"" \
        | sed 's/.*"\([^"]*\)".*/\1/'
}

confirm_action() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        log_debug "非交互模式，跳过确认: ${prompt} (默认: ${default})"
        [[ "${default}" == "y" ]] && return 0 || return 1
    fi

    local yn_hint
    if [[ "${default}" == "y" ]]; then
        yn_hint="[Y/n]"
    else
        yn_hint="[y/N]"
    fi

    while true; do
        echo -en "${COLOR_CYAN}${prompt} ${yn_hint}: ${COLOR_RESET}"
        read -r answer
        answer="${answer:-${default}}"
        case "${answer}" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "请输入 y 或 n" ;;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local var_name="$3"

    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        log_debug "非交互模式，使用默认值: ${prompt} -> ${default}"
        eval "${var_name}='${default}'"
        return 0
    fi

    local display_default=""
    if [[ -n "${default}" ]]; then
        display_default=" (默认: ${default})"
    fi

    echo -en "${COLOR_CYAN}${prompt}${display_default}: ${COLOR_RESET}"
    read -r input
    input="${input:-${default}}"
    eval "${var_name}='${input}'"
}

validate_url_domain() {
    local url="$1"
    local domain

    domain=$(echo "${url}" | sed -E 's|^https?://([^/:]+).*|\1|')

    if [[ -z "${domain}" ]]; then
        log_error "无法从 URL 中提取域名: ${url}"
        return 1
    fi

    if [[ ! -f "${SOURCE_ALLOWLIST_FILE}" ]]; then
        log_warn "白名单文件不存在: ${SOURCE_ALLOWLIST_FILE}"
        return 1
    fi

    local allowed_domains
    allowed_domains=$(json_get_array_values "${SOURCE_ALLOWLIST_FILE}" "allowed_domains")

    while IFS= read -r allowed; do
        if [[ "${domain}" == "${allowed}" || "${domain}" == *.${allowed} ]]; then
            log_debug "域名校验通过: ${domain} (匹配 ${allowed})"
            return 0
        fi
    done <<< "${allowed_domains}"

    log_error "域名不在白名单中: ${domain}"
    return 1
}

safe_download() {
    local url="$1"
    local output="${2:-}"

    if ! validate_url_domain "${url}"; then
        print_error_detail \
            "下载被阻止" \
            "目标 URL 域名不在可信白名单中: ${url}" \
            "为保护系统安全，安装器拒绝从不可信来源下载文件。" \
            "1. 确认下载地址是否正确\n2. 如需添加新的可信域名，请编辑 checks/source-allowlist.json" \
            ""
        return 1
    fi

    local final_url
    final_url=$(curl -fsSL -o /dev/null -w "%{url_effective}" "${url}" 2>/dev/null || echo "")

    if [[ -n "${final_url}" && "${final_url}" != "${url}" ]]; then
        log_debug "检测到重定向: ${url} -> ${final_url}"
        if ! validate_url_domain "${final_url}"; then
            print_error_detail \
                "重定向目标被阻止" \
                "下载 URL 重定向到不可信域名: ${final_url}" \
                "为防止供应链攻击，安装器拒绝不可信的重定向目标。" \
                "1. 检查网络环境是否正常\n2. 确认是否使用了代理\n3. 联系管理员确认" \
                ""
            return 1
        fi
    fi

    if [[ -n "${output}" ]]; then
        curl -fsSL -o "${output}" "${url}"
    else
        curl -fsSL "${url}"
    fi
}

backup_file() {
    local file="$1"
    if [[ -f "${file}" ]]; then
        local backup="${file}.backup.$(date '+%Y%m%d_%H%M%S')"
        cp "${file}" "${backup}"
        log_info "已备份: ${file} -> ${backup}"
        return 0
    fi
    return 1
}

verify_checksum() {
    local file="$1"
    local expected_hash="${2:-}"

    if [[ -z "${expected_hash}" ]]; then
        log_debug "未提供校验和，跳过校验"
        return 0
    fi

    local actual_hash
    actual_hash=$(shasum -a 256 "${file}" | awk '{print $1}')

    if [[ "${actual_hash}" == "${expected_hash}" ]]; then
        log_debug "校验和验证通过: ${file}"
        return 0
    else
        log_error "校验和不匹配: 期望 ${expected_hash}, 实际 ${actual_hash}"
        return 1
    fi
}

verify_signature() {
    local file="$1"
    log_debug "签名校验功能尚未启用 (文件: ${file})"
    return 0
}

print_banner() {
    echo ""
    echo -e "${COLOR_CYAN}========================================"
    echo "  OpenClaw Bootstrap Installer v${BOOTSTRAP_VERSION}"
    echo "  平台: macOS"
    echo "========================================${COLOR_RESET}"
    echo ""
}

print_help() {
    print_banner
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --install          执行安装 (默认)"
    echo "  --upgrade          升级已安装的 OpenClaw"
    echo "  --repair           修复安装问题"
    echo "  --verify           验证当前安装状态"
    echo "  --reset-config     重置配置为默认值"
    echo "  --non-interactive  非交互模式，使用默认值"
    echo "  --verbose          输出详细调试信息"
    echo "  --help             显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 --install                    # 全新安装"
    echo "  $0 --install --non-interactive  # 非交互安装"
    echo "  $0 --upgrade                    # 升级"
    echo "  $0 --verify                     # 仅验证"
    echo "  $0 --repair                     # 修复"
    echo "  $0 --reset-config               # 重置配置"
    echo ""
    echo "日志目录: ${LOG_DIR}"
    echo ""
}
