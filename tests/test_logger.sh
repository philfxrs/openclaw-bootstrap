#!/usr/bin/env bash
# tests/test_logger.sh — 测试 lib/logger.sh 模块
# -------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/lib/logger.sh"

pass=0
fail=0

_assert() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" = "$expected" ]; then
    echo "[PASS] $desc"
    pass=$((pass + 1))
  else
    echo "[FAIL] $desc"
    echo "       期望：$expected"
    echo "       实际：$actual"
    fail=$((fail + 1))
  fi
}

# ---- 测试各 log 函数输出非空 ----------------------------------
_assert "log_info 有输出"   "ok" "$(log_info  '测试消息' | grep -q '.' && echo ok || echo empty)"
_assert "log_ok 有输出"     "ok" "$(log_ok    '成功消息' | grep -q '.' && echo ok || echo empty)"
_assert "log_step 有输出"   "ok" "$(log_step  '步骤消息' | grep -q '.' && echo ok || echo empty)"
_assert "log_warn 有输出"   "ok" "$(log_warn  '警告消息' 2>&1 | grep -q '.' && echo ok || echo empty)"
_assert "log_error 有输出"  "ok" "$(log_error '错误消息' 2>&1 | grep -q '.' && echo ok || echo empty)"
_assert "log_hint 有输出"   "ok" "$(log_hint  '提示消息' | grep -q '.' && echo ok || echo empty)"
_assert "log_banner 有输出" "ok" "$(log_banner '横幅标题' | grep -q '.' && echo ok || echo empty)"
_assert "log_section 有输出" "ok" "$(log_section '节标题' | grep -q '.' && echo ok || echo empty)"

# ---- 测试 log_fatal 以非零退出 --------------------------------
set +e
bash -c "source '${SCRIPT_DIR}/lib/logger.sh'; log_fatal '退出测试' 2>/dev/null"
fatal_exit=$?
set -e
_assert "log_fatal 退出码为 1" "1" "$fatal_exit"

echo ""
echo "logger 测试完成：通过 ${pass}，失败 ${fail}"
[ "$fail" -eq 0 ]
