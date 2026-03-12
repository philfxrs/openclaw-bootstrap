#!/usr/bin/env bash
# ============================================================================
# lib-upgrade.sh — OpenClaw Bootstrap 升级模块 (macOS)
# ============================================================================
# 负责执行 OpenClaw 升级、版本检测、回滚建议。
# ============================================================================

[[ -n "${_LIB_UPGRADE_LOADED:-}" ]] && return 0
_LIB_UPGRADE_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主升级入口
# ========================================

perform_upgrade() {
    log_step "开始升级 OpenClaw..."

    # 检查当前安装状态
    if ! command_exists openclaw; then
        log_error "未检测到已安装的 OpenClaw，无法升级。"
        log_info "请先执行安装: $0 --install"
        return 1
    fi

    # 获取当前版本
    local current_version
    current_version="$(openclaw --version 2>/dev/null || echo '未知')"
    log_info "当前版本: ${current_version}"

    # 读取升级策略
    local backup_before
    backup_before=$(json_get_bool "${VERSION_POLICY_FILE}" "backup_before_upgrade")
    backup_before="${backup_before:-true}"

    local allow_major
    allow_major=$(json_get_bool "${VERSION_POLICY_FILE}" "allow_major_upgrade")
    allow_major="${allow_major:-false}"

    # TODO: confirm how to check latest version
    log_info "检查最新版本..."
    log_warn "TODO: 获取最新版本的具体方式待确认"

    # 备份配置
    if [[ "${backup_before}" == "true" ]]; then
        _backup_before_upgrade
    fi

    # 记录当前版本
    _write_log "INFO" "升级前版本: ${current_version}"

    # 执行升级
    if ! _do_upgrade; then
        log_error "升级失败！"
        _print_rollback_guidance "${current_version}"
        return 1
    fi

    # 升级后验证
    log_step "升级后验证..."
    source "${SCRIPT_DIR}/lib-verify.sh"
    if perform_verify; then
        local new_version
        new_version="$(openclaw --version 2>/dev/null || echo '未知')"
        log_success "升级成功！${current_version} -> ${new_version}"
    else
        log_warn "升级后验证存在警告，请检查。"
        _print_rollback_guidance "${current_version}"
    fi
}

# ========================================
# 升级前备份
# ========================================

_backup_before_upgrade() {
    log_step "备份当前配置..."

    if [[ -d "${CONFIG_DIR}" ]]; then
        local backup_dir="${CONFIG_DIR}.pre-upgrade.$(date '+%Y%m%d_%H%M%S')"
        cp -r "${CONFIG_DIR}" "${backup_dir}"
        log_success "配置已备份到: ${backup_dir}"
    else
        log_info "配置目录不存在，跳过备份。"
    fi
}

# ========================================
# 执行升级
# ========================================

_do_upgrade() {
    # TODO: confirm official upgrade command
    local upgrade_cmd="npm update -g openclaw"

    log_info "升级命令: ${upgrade_cmd}"

    if ! eval "${upgrade_cmd}" 2>&1 | tee -a "${LOG_FILE}"; then
        print_error_detail \
            "OpenClaw 升级失败" \
            "升级命令执行失败。" \
            "OpenClaw 可能仍停留在旧版本。" \
            "1. 检查网络连接\n2. 检查 npm 是否正常\n3. 查看日志文件\n4. 尝试手动升级: ${upgrade_cmd}" \
            "- npm cache clean --force\n- ${upgrade_cmd}" \
            "${LOG_FILE}"
        return 1
    fi

    return 0
}

# ========================================
# 回滚建议
# ========================================

_print_rollback_guidance() {
    local previous_version="$1"

    echo ""
    echo -e "${COLOR_YELLOW}========================================"
    echo "  升级回滚指引"
    echo "========================================${COLOR_RESET}"
    echo ""
    echo "如果升级后出现问题，你可以尝试以下操作:"
    echo ""
    echo "1. 回退到之前的版本:"
    echo "   npm install -g openclaw@${previous_version}"
    echo ""
    echo "2. 恢复配置备份:"
    echo "   查看 ${CONFIG_DIR}.pre-upgrade.* 目录"
    echo "   cp -r <备份目录> ${CONFIG_DIR}"
    echo ""
    echo "3. 运行修复:"
    echo "   $0 --repair"
    echo ""
    echo "4. 查看日志:"
    echo "   ${LOG_FILE}"
    echo ""
}
