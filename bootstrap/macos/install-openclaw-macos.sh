#!/usr/bin/env bash
# ============================================================================
# install-openclaw-macos.sh — OpenClaw Bootstrap 主入口 (macOS)
# ============================================================================
# 用法: ./install-openclaw-macos.sh [选项]
#
# 选项:
#   --install          执行安装 (默认)
#   --upgrade          升级已安装的 OpenClaw
#   --repair           修复安装问题
#   --verify           验证当前安装状态
#   --reset-config     重置配置为默认值
#   --non-interactive  非交互模式
#   --verbose          详细输出
#   --help             显示帮助
# ============================================================================

set -euo pipefail

# ========================================
# 定位脚本目录并加载库
# ========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/lib-common.sh"
source "${SCRIPT_DIR}/lib-preflight.sh"
source "${SCRIPT_DIR}/lib-install.sh"
source "${SCRIPT_DIR}/lib-config.sh"
source "${SCRIPT_DIR}/lib-verify.sh"
source "${SCRIPT_DIR}/lib-upgrade.sh"
source "${SCRIPT_DIR}/lib-repair.sh"

# ========================================
# 参数解析
# ========================================

ACTION="install"
SHOW_HELP=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --install)
                ACTION="install"
                shift
                ;;
            --upgrade)
                ACTION="upgrade"
                shift
                ;;
            --repair)
                ACTION="repair"
                shift
                ;;
            --verify)
                ACTION="verify"
                shift
                ;;
            --reset-config)
                ACTION="reset-config"
                shift
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --verbose)
                VERBOSE_MODE=true
                shift
                ;;
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            *)
                log_error "未知参数: $1"
                echo "使用 --help 查看可用选项。"
                exit 1
                ;;
        esac
    done
}

# ========================================
# 主流程
# ========================================

main() {
    parse_args "$@"

    # 帮助信息
    if [[ "${SHOW_HELP}" == "true" ]]; then
        print_help
        exit 0
    fi

    # 初始化日志
    init_logging "${ACTION}"

    # 打印横幅
    print_banner

    log_debug "操作: ${ACTION}"
    log_debug "非交互模式: ${NON_INTERACTIVE}"
    log_debug "详细模式: ${VERBOSE_MODE}"
    log_debug "脚本目录: ${SCRIPT_DIR}"
    log_debug "项目根目录: ${PROJECT_ROOT}"

    # 根据操作执行对应流程
    case "${ACTION}" in
        install)
            run_install_flow
            ;;
        upgrade)
            run_upgrade_flow
            ;;
        repair)
            run_repair_flow
            ;;
        verify)
            run_verify_flow
            ;;
        reset-config)
            run_reset_config_flow
            ;;
        *)
            log_error "未知操作: ${ACTION}"
            exit 1
            ;;
    esac
}

# ========================================
# 安装流程
# ========================================

run_install_flow() {
    log_step "========== 安装流程开始 =========="

    # 阶段 1: 预检
    log_step "[1/4] 环境预检"
    if ! run_preflight_checks; then
        log_error "预检未通过，安装中止。"
        log_info "请根据上方报告修复问题后重试。"
        log_info "日志文件: ${LOG_FILE}"
        exit 1
    fi

    # 阶段 2: 安装
    log_step "[2/4] 执行安装"
    if ! perform_install; then
        log_error "安装失败。"
        log_info "日志文件: ${LOG_FILE}"
        exit 1
    fi

    # 阶段 3: 配置
    log_step "[3/4] 配置向导"
    perform_configure

    # 阶段 4: 验证
    log_step "[4/4] 安装验证"
    if perform_verify; then
        echo ""
        log_success "========== 安装完成 =========="
        echo ""
        echo "下一步:"
        echo "  1. 如果修改了 PATH，请重新打开终端"
        echo "  2. 运行 openclaw --help 了解基本用法"
        echo "  3. 如遇问题，运行 $0 --repair"
        echo ""
        echo "日志文件: ${LOG_FILE}"
    else
        echo ""
        log_warn "安装已完成但验证存在警告，请检查上方信息。"
        log_info "日志文件: ${LOG_FILE}"
    fi
}

# ========================================
# 升级流程
# ========================================

run_upgrade_flow() {
    log_step "========== 升级流程开始 =========="

    # 简化预检
    log_step "[1/2] 环境检查"
    check_os
    check_node
    check_npm
    check_network

    if [[ "${PREFLIGHT_HAS_FAIL}" == "true" ]]; then
        print_preflight_report
        log_error "环境检查未通过，升级中止。"
        exit 1
    fi

    # 执行升级
    log_step "[2/2] 执行升级"
    if perform_upgrade; then
        log_success "========== 升级完成 =========="
    else
        log_error "升级过程出现问题，请查看日志。"
        log_info "日志文件: ${LOG_FILE}"
        exit 1
    fi
}

# ========================================
# 修复流程
# ========================================

run_repair_flow() {
    log_step "========== 修复流程开始 =========="
    perform_repair
    log_success "========== 修复完成 =========="
    log_info "日志文件: ${LOG_FILE}"
}

# ========================================
# 验证流程
# ========================================

run_verify_flow() {
    log_step "========== 验证流程开始 =========="
    if perform_verify; then
        log_success "========== 验证通过 =========="
    else
        log_warn "========== 验证存在问题 =========="
        log_info "运行 $0 --repair 尝试修复"
    fi
    log_info "日志文件: ${LOG_FILE}"
}

# ========================================
# 重置配置流程
# ========================================

run_reset_config_flow() {
    log_step "========== 配置重置 =========="
    reset_config
    log_info "日志文件: ${LOG_FILE}"
}

# ========================================
# 入口
# ========================================

main "$@"
