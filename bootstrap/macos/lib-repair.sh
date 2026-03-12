#!/usr/bin/env bash
# ============================================================================
# lib-repair.sh — OpenClaw Bootstrap 修复模块 (macOS)
# ============================================================================
# 负责修复 PATH、依赖缺失、配置损坏、安装不完整等问题。
# ============================================================================

[[ -n "${_LIB_REPAIR_LOADED:-}" ]] && return 0
_LIB_REPAIR_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主修复入口
# ========================================

perform_repair() {
    log_step "开始诊断与修复..."
    echo ""

    local issues_found=0

    repair_path         && : || issues_found=$((issues_found + 1))
    repair_node         && : || issues_found=$((issues_found + 1))
    repair_installation && : || issues_found=$((issues_found + 1))
    repair_config       && : || issues_found=$((issues_found + 1))
    repair_permissions  && : || issues_found=$((issues_found + 1))

    echo ""
    echo "========================================"
    if [[ ${issues_found} -eq 0 ]]; then
        echo -e "  ${COLOR_GREEN}修复完成，未发现需要修复的问题。${COLOR_RESET}"
    else
        echo -e "  ${COLOR_YELLOW}修复完成，处理了 ${issues_found} 个问题。${COLOR_RESET}"
        echo "  建议运行验证确认: $0 --verify"
    fi
    echo "========================================"
    echo ""
}

# ========================================
# PATH 修复
# ========================================

repair_path() {
    log_info "检查 PATH..."

    if ! command_exists npm; then
        log_warn "  npm 不可用，跳过 PATH 修复。"
        return 0
    fi

    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null)"
    local npm_bin="${npm_prefix}/bin"

    if [[ ":${PATH}:" == *":${npm_bin}:"* ]]; then
        log_success "  \u2714 PATH 正常"
        return 0
    fi

    log_warn "  npm 全局目录不在 PATH 中: ${npm_bin}"

    # 检测用户使用的 shell
    local shell_name
    shell_name="$(basename "${SHELL:-/bin/zsh}")"
    local shell_rc=""

    case "${shell_name}" in
        zsh)  shell_rc="${HOME}/.zshrc" ;;
        bash) shell_rc="${HOME}/.bashrc" ;;
        *)    shell_rc="${HOME}/.profile" ;;
    esac

    if confirm_action "是否将 ${npm_bin} 添加到 PATH？(修改 ${shell_rc})"; then
        # 避免重复添加
        if ! grep -q "${npm_bin}" "${shell_rc}" 2>/dev/null; then
            echo "" >> "${shell_rc}"
            echo "# OpenClaw Bootstrap: npm 全局目录" >> "${shell_rc}"
            echo "export PATH=\"${npm_bin}:\$PATH\"" >> "${shell_rc}"
            log_success "  已添加到 ${shell_rc}"
            log_info "  请重新打开终端或执行: source ${shell_rc}"
        else
            log_info "  ${shell_rc} 中已包含该路径。"
        fi
        return 0
    else
        log_info "  跳过 PATH 修复。"
        echo "  手动修复: 在 ${shell_rc} 中添加:"
        echo "  export PATH=\"${npm_bin}:\$PATH\""
        return 1
    fi
}

# ========================================
# Node.js 修复
# ========================================

repair_node() {
    log_info "检查 Node.js..."

    if ! command_exists node; then
        print_error_detail \
            "Node.js 未安装" \
            "系统中未找到 node 命令。" \
            "OpenClaw 无法运行。" \
            "1. 安装 Node.js 22 或更高版本\n2. 重新打开终端" \
            "- brew install node\n- 或访问 https://nodejs.org" \
            "${LOG_FILE}"
        return 1
    fi

    local node_version
    node_version="$(node --version 2>/dev/null)"
    node_version="${node_version#v}"

    local min_version
    min_version=$(json_get_value "${VERSION_POLICY_FILE}" "minimum_node_version")
    min_version="${min_version:-22.0.0}"

    if version_gte "${node_version}" "${min_version}"; then
        log_success "  \u2714 Node.js 版本正常: v${node_version}"
        return 0
    fi

    log_warn "  Node.js 版本过低: v${node_version} (要求 >= v${min_version})"
    echo "  建议升级: brew upgrade node 或 nvm install ${min_version}"
    return 1
}

# ========================================
# 安装修复
# ========================================

repair_installation() {
    log_info "检查 OpenClaw 安装..."

    # TODO: confirm openclaw CLI command name
    if command_exists openclaw; then
        if openclaw --version >/dev/null 2>&1; then
            log_success "  \u2714 OpenClaw 安装正常"
            return 0
        else
            log_warn "  openclaw 命令存在但执行异常"
            if confirm_action "是否尝试重新安装？"; then
                source "${SCRIPT_DIR}/lib-install.sh"
                _do_install
                return $?
            fi
            return 1
        fi
    fi

    log_warn "  openclaw 命令未找到"
    if confirm_action "是否执行安装？"; then
        source "${SCRIPT_DIR}/lib-install.sh"
        _do_install
        return $?
    fi
    return 1
}

# ========================================
# 配置修复
# ========================================

repair_config() {
    log_info "检查配置文件..."

    if [[ ! -d "${CONFIG_DIR}" ]]; then
        log_warn "  配置目录不存在，创建中..."
        mkdir -p "${CONFIG_DIR}" 2>/dev/null
        if [[ -d "${CONFIG_DIR}" ]]; then
            log_success "  \u2714 配置目录已创建: ${CONFIG_DIR}"
        else
            log_error "  \u2718 无法创建配置目录: ${CONFIG_DIR}"
            return 1
        fi
    fi

    # TODO: confirm config file name
    if [[ ! -f "${CONFIG_DIR}/config.json" ]]; then
        log_warn "  配置文件不存在"
        if confirm_action "是否从模板创建默认配置？"; then
            local template="${PROJECT_ROOT}/templates/config.default.json"
            if [[ -f "${template}" ]]; then
                cp "${template}" "${CONFIG_DIR}/config.json"
                log_success "  \u2714 默认配置已创建"
            else
                log_error "  \u2718 配置模板不存在: ${template}"
                return 1
            fi
        fi
    else
        log_success "  \u2714 配置文件存在"
    fi

    return 0
}

# ========================================
# 权限修复
# ========================================

repair_permissions() {
    log_info "检查文件权限..."

    local issues=0

    # 检查日志目录
    if [[ -d "${LOG_DIR}" && ! -w "${LOG_DIR}" ]]; then
        log_warn "  日志目录不可写: ${LOG_DIR}"
        chmod u+w "${LOG_DIR}" 2>/dev/null && log_success "  \u2714 已修复日志目录权限" || issues=$((issues + 1))
    fi

    # 检查配置目录
    if [[ -d "${CONFIG_DIR}" && ! -w "${CONFIG_DIR}" ]]; then
        log_warn "  配置目录不可写: ${CONFIG_DIR}"
        chmod u+w "${CONFIG_DIR}" 2>/dev/null && log_success "  \u2714 已修复配置目录权限" || issues=$((issues + 1))
    fi

    # 检查敏感配置文件权限
    if [[ -f "${CONFIG_DIR}/providers.json" ]]; then
        local perms
        perms="$(stat -f '%Lp' "${CONFIG_DIR}/providers.json" 2>/dev/null)"
        if [[ "${perms}" != "600" ]]; then
            chmod 600 "${CONFIG_DIR}/providers.json" 2>/dev/null
            log_success "  \u2714 已设置 providers.json 权限为 600"
        fi
    fi

    if [[ ${issues} -eq 0 ]]; then
        log_success "  \u2714 文件权限正常"
    fi

    return ${issues}
}
