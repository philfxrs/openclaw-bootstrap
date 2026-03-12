#!/usr/bin/env bash
# ============================================================================
# lib-verify.sh — OpenClaw Bootstrap 验证模块 (macOS)
# ============================================================================
# 负责验证安装结果、CLI 可用性、服务运行状态。
# ============================================================================

[[ -n "${_LIB_VERIFY_LOADED:-}" ]] && return 0
_LIB_VERIFY_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主验证入口
# ========================================

perform_verify() {
    log_step "开始验证安装状态..."
    echo ""

    local all_ok=true

    verify_cli_exists       || all_ok=false
    verify_cli_version      || all_ok=false
    verify_cli_executable   || all_ok=false
    verify_path_correct     || all_ok=false
    verify_basic_commands   || all_ok=false
    verify_daemon_status
    verify_config_exists

    echo ""
    echo "========================================"
    if [[ "${all_ok}" == "true" ]]; then
        echo -e "  ${COLOR_GREEN}\u2714 验证全部通过${COLOR_RESET}"
    else
        echo -e "  ${COLOR_RED}\u2718 验证存在失败项${COLOR_RESET}"
        echo ""
        echo "  修复建议: 运行 $0 --repair"
    fi
    echo "========================================"
    echo ""

    [[ "${all_ok}" == "true" ]]
}

# ========================================
# CLI 存在性验证
# ========================================

verify_cli_exists() {
    log_info "检查 openclaw 命令是否存在..."

    # TODO: confirm openclaw CLI command name
    if command_exists openclaw; then
        log_success "  \u2714 openclaw 命令已找到: $(which openclaw)"
        return 0
    fi

    log_error "  \u2718 openclaw 命令未找到"
    print_error_detail \
        "openclaw 命令不存在" \
        "在 PATH 中未找到 openclaw 可执行文件。" \
        "无法使用 OpenClaw CLI。" \
        "1. 检查是否已正确安装\n2. 检查 PATH 环境变量\n3. 尝试重新安装" \
        "- which openclaw\n- echo \$PATH\n- npm list -g openclaw" \
        "${LOG_FILE}"
    return 1
}

# ========================================
# 版本验证
# ========================================

verify_cli_version() {
    if ! command_exists openclaw; then
        return 1
    fi

    log_info "检查 openclaw 版本..."

    # TODO: confirm openclaw version command
    local version
    version="$(openclaw --version 2>/dev/null)"
    local exit_code=$?

    if [[ ${exit_code} -eq 0 && -n "${version}" ]]; then
        log_success "  \u2714 版本: ${version}"
        return 0
    fi

    log_error "  \u2718 openclaw --version 执行失败 (退出码: ${exit_code})"
    return 1
}

# ========================================
# 可执行性验证
# ========================================

verify_cli_executable() {
    if ! command_exists openclaw; then
        return 1
    fi

    log_info "检查 openclaw 可执行性..."

    local cli_path
    cli_path="$(which openclaw)"

    if [[ -x "${cli_path}" ]]; then
        log_success "  \u2714 文件可执行: ${cli_path}"
        return 0
    fi

    log_error "  \u2718 文件不可执行: ${cli_path}"
    return 1
}

# ========================================
# PATH 正确性验证
# ========================================

verify_path_correct() {
    log_info "检查 PATH 配置..."

    if command_exists npm; then
        local npm_prefix
        npm_prefix="$(npm config get prefix 2>/dev/null)"
        local npm_bin="${npm_prefix}/bin"

        if [[ ":${PATH}:" == *":${npm_bin}:"* ]]; then
            log_success "  \u2714 npm 全局目录在 PATH 中: ${npm_bin}"
            return 0
        else
            log_warn "  \u26a0 npm 全局目录不在 PATH 中: ${npm_bin}"
            return 0  # 警告但不阻塞
        fi
    fi

    return 0
}

# ========================================
# 基本命令验证
# ========================================

verify_basic_commands() {
    if ! command_exists openclaw; then
        return 1
    fi

    log_info "检查基本命令..."

    # TODO: confirm openclaw subcommands
    local commands=("--version" "--help")
    local all_ok=true

    for cmd in "${commands[@]}"; do
        if openclaw ${cmd} >/dev/null 2>&1; then
            log_success "  \u2714 openclaw ${cmd} 正常"
        else
            log_warn "  \u26a0 openclaw ${cmd} 执行异常"
            all_ok=false
        fi
    done

    [[ "${all_ok}" == "true" ]]
}

# ========================================
# Daemon / Gateway 状态验证
# ========================================

verify_daemon_status() {
    log_info "检查 daemon / gateway 状态..."

    # TODO: confirm gateway/daemon health check command
    log_debug "  TODO: daemon / gateway 状态检查命令待确认"
    log_info "  ⊘ 跳过 (daemon 检查待实现)"
}

# ========================================
# 配置文件存在性验证
# ========================================

verify_config_exists() {
    log_info "检查配置文件..."

    if [[ -d "${CONFIG_DIR}" ]]; then
        log_success "  \u2714 配置目录存在: ${CONFIG_DIR}"
    else
        log_warn "  \u26a0 配置目录不存在: ${CONFIG_DIR}"
    fi

    # TODO: confirm config file name and path
    if [[ -f "${CONFIG_DIR}/config.json" ]]; then
        log_success "  \u2714 配置文件存在"
    else
        log_info "  \u2298 配置文件不存在 (可通过配置向导生成)"
    fi
}
