#!/usr/bin/env bash
# ============================================================================
# lib-preflight.sh — OpenClaw Bootstrap 预检模块 (macOS)
# ============================================================================
# 负u8d23在安装前检查系统环境是否满足所有前提条件。
# ============================================================================

[[ -n "${_LIB_PREFLIGHT_LOADED:-}" ]] && return 0
_LIB_PREFLIGHT_LOADED=1

# 加载公共库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主预检入口
# ========================================

run_preflight_checks() {
    log_step "开始环境预检..."
    echo ""

    check_os
    check_architecture
    check_shell_environment
    check_basic_tools
    check_node
    check_npm
    check_path
    check_network
    check_source_allowlist
    check_existing_installation
    check_log_directory_writable
    check_config_directory_writable

    print_preflight_report

    if [[ "${PREFLIGHT_HAS_FAIL}" == "true" ]]; then
        log_error "预检存在阻塞项，请根据上方报告修复后重试。"
        return 1
    fi

    return 0
}

# ========================================
# 操作系统检查
# ========================================

check_os() {
    log_debug "检查操作系统..."
    local os_name
    os_name="$(uname -s)"

    if [[ "${os_name}" != "Darwin" ]]; then
        preflight_fail "操作系统" "当前系统为 ${os_name}，此脚本仅支持 macOS"
        print_error_detail \
            "不支持的操作系统" \
            "检测到当前系统为 ${os_name}，此脚本仅适用于 macOS。" \
            "无法继续安装。" \
            "1. 如果你使用 Windows，请使用 install-openclaw-windows.ps1\n2. 如果你使用 Linux，请参考官方文档" \
            ""
        return
    fi

    local macos_version
    macos_version="$(sw_vers -productVersion 2>/dev/null || echo '未知')"
    preflight_pass "操作系统" "macOS ${macos_version}"
}

# ========================================
# CPU 架构检查
# ========================================

check_architecture() {
    log_debug "检查 CPU 架构..."
    local arch
    arch="$(uname -m)"

    case "${arch}" in
        arm64)
            preflight_pass "CPU 架构" "Apple Silicon (arm64)"
            ;;
        x86_64)
            preflight_pass "CPU 架构" "Intel (x86_64)"
            ;;
        *)
            preflight_warn "CPU 架构" "未知架构: ${arch}，可能不受支持"
            ;;
    esac
}

# ========================================
# Shell 环境检查
# ========================================

check_shell_environment() {
    log_debug "检查 Shell 环境..."
    local current_shell
    current_shell="${SHELL:-未知}"
    local shell_name
    shell_name="$(basename "${current_shell}")"

    preflight_pass "Shell 环境" "${shell_name} (${current_shell})"

    # 检查 bash 版本
    local bash_version_str
    bash_version_str="${BASH_VERSION:-未知}"
    log_debug "Bash 版本: ${bash_version_str}"
}

# ========================================
# 基础工具检查
# ========================================

check_basic_tools() {
    log_debug "检查基础工具..."
    local tools=("curl" "bash" "uname" "sed" "awk" "grep")
    local all_found=true

    for tool in "${tools[@]}"; do
        if command_exists "${tool}"; then
            log_debug "  ✔ ${tool} 已找到"
        else
            preflight_fail "基础工具" "缺少必需工具: ${tool}"
            all_found=false
        fi
    done

    if [[ "${all_found}" == "true" ]]; then
        preflight_pass "基础工具" "curl, bash, uname, sed, awk, grep 均可用"
    fi
}

# ========================================
# Node.js 检查
# ========================================

check_node() {
    log_debug "检查 Node.js..."

    if ! command_exists node; then
        preflight_fail "Node.js" "未安装"
        print_error_detail \
            "未检测到 Node.js" \
            "OpenClaw 运行依赖 Node.js，但当前系统中未找到 node 命令。" \
            "安装器无法继续执行 OpenClaw 安装。" \
            "1. 安装 Node.js 22 或更高版本\n2. 安装完成后重新打开终端\n3. 再次运行本安装脚本" \
            "- 访问 https://nodejs.org 下载安装包\n- 或使用 Homebrew: brew install node\n- 或使用 nvm: nvm install 22" \
            "${LOG_FILE}"
        return
    fi

    local node_version
    node_version="$(node --version 2>/dev/null)"
    node_version="${node_version#v}"

    local min_version
    min_version=$(json_get_value "${VERSION_POLICY_FILE}" "minimum_node_version")
    min_version="${min_version:-22.0.0}"

    if version_gte "${node_version}" "${min_version}"; then
        preflight_pass "Node.js" "v${node_version} (最低要求: v${min_version})"
    else
        preflight_fail "Node.js" "版本过低: v${node_version} (最低要求: v${min_version})"
        print_error_detail \
            "Node.js 版本过低" \
            "当前 Node.js 版本为 v${node_version}，最低要求 v${min_version}。" \
            "部分 OpenClaw 功能可能无法正常运行。" \
            "1. 升级 Node.js 到 v${min_version} 或更高版本\n2. 升级完成后重新打开终端\n3. 再次运行本安装脚本" \
            "- brew upgrade node\n- 或 nvm install ${min_version}\n- 或访问 https://nodejs.org 下载" \
            "${LOG_FILE}"
    fi
}

# ========================================
# npm 检查
# ========================================

check_npm() {
    log_debug "检查 npm..."

    if ! command_exists npm; then
        preflight_fail "npm" "未安装或不在 PATH 中"
        print_error_detail \
            "未检测到 npm" \
            "npm 通常随 Node.js 一起安装，但当前系统中未找到 npm 命令。" \
            "无法通过 npm 安装 OpenClaw。" \
            "1. 确认 Node.js 是否正确安装\n2. 检查 PATH 环境变量\n3. 重新安装 Node.js" \
            "- which node && which npm\n- echo \$PATH" \
            "${LOG_FILE}"
        return
    fi

    local npm_version
    npm_version="$(npm --version 2>/dev/null)"
    preflight_pass "npm" "v${npm_version}"
}

# ========================================
# PATH 检查
# ========================================

check_path() {
    log_debug "检查 PATH..."

    local issues=()

    # 检查 node 是否在 PATH 中
    if command_exists node; then
        local node_path
        node_path="$(which node)"
        log_debug "node 路径: ${node_path}"
    else
        issues+=("node 不在 PATH 中")
    fi

    # 检查 npm 是否在 PATH 中
    if command_exists npm; then
        local npm_path
        npm_path="$(which npm)"
        log_debug "npm 路径: ${npm_path}"
    else
        issues+=("npm 不在 PATH 中")
    fi

    # 检查常见 npm 全局 bin 目录是否在 PATH 中
    local npm_global_bin=""
    if command_exists npm; then
        npm_global_bin="$(npm config get prefix 2>/dev/null)/bin"
        if [[ -n "${npm_global_bin}" && ":${PATH}:" != *":${npm_global_bin}:"* ]]; then
            issues+=("npm 全局安装目录不在 PATH 中: ${npm_global_bin}")
        fi
    fi

    if [[ ${#issues[@]} -eq 0 ]]; then
        preflight_pass "PATH" "node 和 npm 均在 PATH 中"
    else
        local detail
        detail=$(printf '%s; ' "${issues[@]}")
        preflight_warn "PATH" "${detail}"
    fi
}

# ========================================
# 网络连通性检查
# ========================================

check_network() {
    log_debug "检查网络连通性..."

    # TODO: confirm official install source URL
    local test_urls=(
        "https://registry.npmjs.org"
        "https://github.com"
    )

    local all_ok=true

    for url in "${test_urls[@]}"; do
        local domain
        domain=$(echo "${url}" | sed -E 's|^https?://([^/:]+).*|\1|')

        if curl -fsSL --connect-timeout 10 --max-time 15 -o /dev/null "${url}" 2>/dev/null; then
            log_debug "  ✔ 网络可达: ${domain}"
        else
            log_warn "  ✘ 网络不可达: ${domain}"
            all_ok=false
        fi
    done

    if [[ "${all_ok}" == "true" ]]; then
        preflight_pass "网络连通性" "官方源可达"
    else
        preflight_fail "网络连通性" "部分官方源不可达，请检查网络或代理配置"
        print_error_detail \
            "网络连通性异常" \
            "无法连接到部分官方下载源。" \
            "安装过程中需要从网络下载依赖，网络不可达将导致安装失败。" \
            "1. 检查网络连接\n2. 检查是否使用了代理\n3. 检查 DNS 是否正常\n4. 如在公司网络中，联系 IT 确认出网策略" \
            "- curl -v https://registry.npmjs.org\n- ping github.com" \
            "${LOG_FILE}"
    fi
}

# ========================================
# 白名单校验
# ========================================

check_source_allowlist() {
    log_debug "检查来源白名单配置..."

    if [[ -f "${SOURCE_ALLOWLIST_FILE}" ]]; then
        local domain_count
        domain_count=$(json_get_array_values "${SOURCE_ALLOWLIST_FILE}" "allowed_domains" | wc -l | tr -d ' ')
        preflight_pass "来源白名单" "已配置 (${domain_count} 个可信域名)"
    else
        preflight_warn "来源白名单" "白名单文件不存在: ${SOURCE_ALLOWLIST_FILE}"
    fi
}

# ========================================
# 已安装状态检查
# ========================================

check_existing_installation() {
    log_debug "检查已安装状态..."

    # TODO: confirm openclaw CLI command name
    if command_exists openclaw; then
        local installed_version
        installed_version="$(openclaw --version 2>/dev/null || echo '未知')"
        preflight_warn "已安装状态" "已安装 OpenClaw (版本: ${installed_version})"
    else
        preflight_pass "已安装状态" "未安装 (全新安装)"
    fi
}

# ========================================
# 日志目录可写检查
# ========================================

check_log_directory_writable() {
    log_debug "检查日志目录可写性..."

    mkdir -p "${LOG_DIR}" 2>/dev/null
    if [[ -w "${LOG_DIR}" ]]; then
        preflight_pass "日志目录" "可写 (${LOG_DIR})"
    else
        preflight_warn "日志目录" "不可写: ${LOG_DIR}，日志将无法保存"
    fi
}

# ========================================
# 配置目录可写检查
# ========================================

check_config_directory_writable() {
    log_debug "检查配置目录可写性..."

    mkdir -p "${CONFIG_DIR}" 2>/dev/null
    if [[ -w "${CONFIG_DIR}" ]]; then
        preflight_pass "配置目录" "可写 (${CONFIG_DIR})"
    else
        preflight_warn "配置目录" "不可写: ${CONFIG_DIR}，配置将无法保存"
    fi
}
