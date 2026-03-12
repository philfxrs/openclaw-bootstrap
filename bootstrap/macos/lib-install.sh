#!/usr/bin/env bash
# ============================================================================
# lib-install.sh — OpenClaw Bootstrap 安装模块 (macOS)
# ============================================================================
# 负责调用官方安装链路完成 OpenClaw 安装。
# ============================================================================

[[ -n "${_LIB_INSTALL_LOADED:-}" ]] && return 0
_LIB_INSTALL_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib-common.sh"

# ========================================
# 主安装入口
# ========================================

perform_install() {
    log_step "开始安装 OpenClaw..."

    # 检查是否已安装
    if command_exists openclaw; then
        local installed_version
        installed_version="$(openclaw --version 2>/dev/null || echo '未知')"
        log_warn "检测到已安装 OpenClaw (版本: ${installed_version})"

        if [[ "${NON_INTERACTIVE}" == "true" ]]; then
            log_info "非交互模式，跳过已安装版本，不执行重复安装。"
            log_info "如需升级，请使用 --upgrade 参数。"
            return 0
        fi

        echo ""
        echo "检测到 OpenClaw 已安装（版本: ${installed_version}）。"
        echo "请选择操作:"
        echo "  1) 跳过安装"
        echo "  2) 升级到最新版本"
        echo "  3) 修复当前安装"
        echo "  4) 重置配置"
        echo ""
        echo -en "${COLOR_CYAN}请输入选项 [1/2/3/4] (默认: 1): ${COLOR_RESET}"
        read -r choice
        choice="${choice:-1}"

        case "${choice}" in
            1)
                log_info "用户选择跳过安装。"
                return 0
                ;;
            2)
                log_info "用户选择升级，切换到升级流程..."
                source "${SCRIPT_DIR}/lib-upgrade.sh"
                perform_upgrade
                return $?
                ;;
            3)
                log_info "用户选择修复，切换到修复流程..."
                source "${SCRIPT_DIR}/lib-repair.sh"
                perform_repair
                return $?
                ;;
            4)
                log_info "用户选择重置配置..."
                source "${SCRIPT_DIR}/lib-config.sh"
                reset_config
                return $?
                ;;
            *)
                log_info "无效选项，跳过安装。"
                return 0
                ;;
        esac
    fi

    # 确认 Node.js 可用
    if ! command_exists node; then
        print_error_detail \
            "无法安装 OpenClaw" \
            "Node.js 未安装，OpenClaw 安装需要 Node.js 环境。" \
            "安装无法继续。" \
            "1. 请先安装 Node.js 22 或更高版本\n2. 安装完成后重新打开终端\n3. 再次运行本安装脚本" \
            "- brew install node\n- 或访问 https://nodejs.org 下载" \
            "${LOG_FILE}"
        return 1
    fi

    # 执行安装
    _do_install
}

# ========================================
# 实际安装执行
# ========================================

_do_install() {
    log_step "正在安装 OpenClaw..."

    # TODO: confirm official install command
    local install_cmd="npm install -g openclaw"
    local install_source="https://registry.npmjs.org"

    # 校验安装源
    if ! validate_url_domain "${install_source}"; then
        log_error "安装源域名校验失败，中止安装。"
        return 1
    fi

    log_info "安装命令: ${install_cmd}"
    log_info "安装源: ${install_source}"

    # TODO: confirm official install command
    if ! eval "${install_cmd}" 2>&1 | tee -a "${LOG_FILE}"; then
        print_error_detail \
            "OpenClaw 安装失败" \
            "安装命令执行失败，请查看上方输出或日志获取详细信息。" \
            "OpenClaw 未成功安装。" \
            "1. 检查网络连接\n2. 检查 npm 是否正常工作\n3. 查看日志文件了解详细错误\n4. 尝试手动执行: ${install_cmd}" \
            "- npm cache clean --force\n- ${install_cmd}" \
            "${LOG_FILE}"
        return 1
    fi

    # 验证安装
    _verify_install_result

    return $?
}

# ========================================
# 安装后验证
# ========================================

_verify_install_result() {
    log_step "验证安装结果..."

    # TODO: confirm openclaw CLI command name
    if command_exists openclaw; then
        local version
        version="$(openclaw --version 2>/dev/null || echo '未知')"
        log_success "OpenClaw 安装成功！版本: ${version}"
        return 0
    fi

    # 命令不存在，可能是 PATH 问题
    log_warn "openclaw 命令未找到，可能需要刷新环境变量。"

    # 尝试查找可能的安装位置
    local npm_prefix
    npm_prefix="$(npm config get prefix 2>/dev/null)"
    local possible_paths=(
        "${npm_prefix}/bin/openclaw"
        "/usr/local/bin/openclaw"
        "${HOME}/.npm-global/bin/openclaw"
    )

    for p in "${possible_paths[@]}"; do
        if [[ -x "${p}" ]]; then
            log_info "在 ${p} 找到 openclaw，但可能不在当前 PATH 中。"
            print_error_detail \
                "PATH 配置需要更新" \
                "OpenClaw 已安装到 $(dirname "${p}")，但该目录不在 PATH 中。" \
                "在当前终端中无法直接运行 openclaw 命令。" \
                "1. 将以下行添加到你的 shell 配置文件 (~/.zshrc 或 ~/.bashrc)\n2. 重新打开终端" \
                "echo 'export PATH=\"$(dirname "${p}"):\$PATH\"' >> ~/.zshrc\nsource ~/.zshrc" \
                "${LOG_FILE}"
            return 1
        fi
    done

    print_error_detail \
        "安装验证失败" \
        "安装命令已执行但未找到 openclaw 可执行文件。" \
        "安装可能未成功完成。" \
        "1. 查看上方安装输出是否有错误\n2. 检查日志文件\n3. 尝试手动安装" \
        "- npm list -g openclaw\n- which openclaw" \
        "${LOG_FILE}"
    return 1
}
