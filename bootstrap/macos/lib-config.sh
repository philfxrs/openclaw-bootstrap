#!/usr/bin/env bash
# ============================================================================
# lib-config.sh — OpenClaw Bootstrap 配置模块 (macOS)
# ============================================================================
# 负责安装后的初始化配置、配置重置。
# ============================================================================

[[ -n "${_LIB_CONFIG_LOADED:-}" ]] && return 0
_LIB_CONFIG_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主配置入口
# ========================================

perform_configure() {
    log_step "开始配置向导..."
    echo ""

    # 确保配置目录存在
    mkdir -p "${CONFIG_DIR}" 2>/dev/null

    configure_work_directory
    configure_daemon
    configure_provider
    configure_onboarding
    configure_verify_prompt

    log_success "配置向导完成！"
    echo ""
}

# ========================================
# 工作目录配置
# ========================================

configure_work_directory() {
    log_info "配置项: 工作目录"
    echo "  说明: OpenClaw 的默认工作目录，用于存放项目和数据。"
    echo "  可跳过: 是 (使用默认值: ${WORK_DIR})"
    echo "  跳过影响: 将使用默认目录 ${WORK_DIR}"
    echo ""

    local work_dir
    prompt_input "请输入工作目录路径" "${WORK_DIR}" work_dir

    if [[ -n "${work_dir}" ]]; then
        WORK_DIR="${work_dir}"
        mkdir -p "${WORK_DIR}" 2>/dev/null
        if [[ -d "${WORK_DIR}" ]]; then
            log_success "工作目录已设置: ${WORK_DIR}"
        else
            log_warn "无法创建工作目录: ${WORK_DIR}，请稍后手动创建。"
        fi
    fi
    echo ""
}

# ========================================
# Daemon 配置
# ========================================

configure_daemon() {
    log_info "配置项: Daemon 服务"
    echo "  说明: OpenClaw daemon 提供后台服务能力，某些高级功能可能依赖它。"
    echo "  可跳过: 是"
    echo "  跳过影响: 部分高级功能可能不可用，可稍后手动配置。"
    echo ""

    # TODO: confirm daemon install command
    if confirm_action "是否安装 daemon 服务？"; then
        log_info "将安装 daemon 服务..."
        # TODO: confirm daemon install command
        log_warn "TODO: daemon 安装命令待确认，跳过实际安装。"
    else
        log_info "跳过 daemon 安装。你可以稍后手动执行安装。"
    fi
    echo ""
}

# ========================================
# Provider 配置
# ========================================

configure_provider() {
    log_info "配置项: Provider (AI 服务提供商)"
    echo "  说明: 配置 AI 服务提供商和 API Key，用于启用 AI 功能。"
    echo "  可跳过: 是"
    echo "  跳过影响: AI 相关功能将不可用，可稍后在配置文件中手动填写。"
    echo ""

    if ! confirm_action "是否现在配置 Provider？"; then
        log_info "跳过 Provider 配置。"
        log_info "你可以稍后编辑配置文件或执行 openclaw 的配置命令。"
        echo ""
        return
    fi

    # TODO: confirm provider configuration approach
    local provider_name
    prompt_input "请输入 Provider 名称" "" provider_name

    if [[ -n "${provider_name}" ]]; then
        log_info "Provider: ${provider_name}"

        if confirm_action "是否现在填写 API Key？"; then
            echo -en "${COLOR_CYAN}请输入 API Key (输入内容不会回显): ${COLOR_RESET}"
            read -rs api_key
            echo ""

            if [[ -n "${api_key}" ]]; then
                # 不在日志中记录 API Key
                log_info "API Key 已接收 (不会记录到日志)"
                _write_log "INFO" "API Key 已配置 (已脇敏)"

                # TODO: confirm how to save provider config
                local provider_config="${CONFIG_DIR}/providers.json"
                log_warn "TODO: Provider 配置保存逻辑待确认。"
                log_info "请确保 ${provider_config} 文件权限设置为仅当前用户可读。"
            fi
        else
            log_info "跳过 API Key 填写，可稍后配置。"
        fi
    fi
    echo ""
}

# ========================================
# Onboarding 配置
# ========================================

configure_onboarding() {
    log_info "配置项: Onboarding 新手引导"
    echo "  说明: 执行 OpenClaw 新手引导流程，帮助你了解基本用法。"
    echo "  可跳过: 是"
    echo "  跳过影响: 不影响功能，可稍后执行 onboarding 命令。"
    echo ""

    # TODO: confirm onboarding command
    if confirm_action "是否立即执行 onboarding？"; then
        log_info "启动 onboarding..."
        # TODO: confirm onboarding command
        if command_exists openclaw; then
            log_warn "TODO: onboarding 命令待确认 (例如: openclaw onboarding)"
        else
            log_warn "openclaw 命令不可用，无法执行 onboarding。"
        fi
    else
        log_info "跳过 onboarding。你可以稍后执行: openclaw onboarding"
    fi
    echo ""
}

# ========================================
# 验证提示
# ========================================

configure_verify_prompt() {
    echo "  说明: 配置完成后建议立即验证安装状态。"
    echo "  可跳过: 是"
    echo "  跳过影响: 可能不会发现安装问题，建议执行。"
    echo ""

    if confirm_action "是否立即执行安装验证？" "y"; then
        source "${SCRIPT_DIR}/lib-verify.sh"
        perform_verify
    else
        log_info "跳过验证。你可以稍后运行: $0 --verify"
    fi
}

# ========================================
# 重置配置
# ========================================

reset_config() {
    log_step "重置配置..."

    if [[ ! -d "${CONFIG_DIR}" ]]; then
        log_info "配置目录不存在，无需重置。"
        return 0
    fi

    # 备份现有配置
    local backup_dir="${CONFIG_DIR}.backup.$(date '+%Y%m%d_%H%M%S')"

    if confirm_action "将备份当前配置到 ${backup_dir}，并重置为默认配置。是否继续？"; then
        cp -r "${CONFIG_DIR}" "${backup_dir}"
        log_success "配置已备份到: ${backup_dir}"

        # 复制默认配置模板
        local default_config="${PROJECT_ROOT}/templates/config.default.json"
        if [[ -f "${default_config}" ]]; then
            cp "${default_config}" "${CONFIG_DIR}/config.json"
            log_success "配置已重置为默认值。"
        else
            log_warn "默认配置模板不存在: ${default_config}"
        fi
    else
        log_info "取消重置配置。"
    fi
}
