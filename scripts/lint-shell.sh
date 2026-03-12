#!/usr/bin/env bash
# lint-shell.sh — 使用 shellcheck 对 macOS 脚本进行静态检查
# 用法: bash scripts/lint-shell.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
macOS_DIR="$PROJECT_ROOT/bootstrap/macos"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if ! command -v shellcheck &>/dev/null; then
    echo -e "${RED}[错误]${NC} 未找到 shellcheck，请先安装："
    echo "  macOS:   brew install shellcheck"
    echo "  Ubuntu:  sudo apt install shellcheck"
    exit 1
fi

echo "=========================================="
echo " ShellCheck 代码检查"
echo "=========================================="
echo ""

ERRORS=0
CHECKED=0

for f in "$macOS_DIR"/*.sh; do
    if [[ ! -f "$f" ]]; then
        continue
    fi
    CHECKED=$((CHECKED + 1))
    BASENAME="$(basename "$f")"
    echo -n "  检查 $BASENAME ... "

    if shellcheck -x -S warning "$f" 2>/dev/null; then
        echo -e "${GREEN}通过${NC}"
    else
        echo -e "${RED}失败${NC}"
        echo ""
        shellcheck -x -S warning "$f" 2>/dev/null || true
        echo ""
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""
echo "=========================================="
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}全部通过${NC} ($CHECKED 个文件)"
else
    echo -e "${RED}$ERRORS 个文件有问题${NC} (共 $CHECKED 个文件)"
    exit 1
fi
