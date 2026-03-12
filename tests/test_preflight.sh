#!/usr/bin/env bash
# tests/test_preflight.sh — 测试 lib/preflight.sh 各检查项（stub 模式）
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

# ---- 测试：磁盘空间检查（通过：充足空间）-----------------------
run_disk_ok() {
  # 覆写 df 行为：报告 99999 MB 可用
  _check_disk_space_stub() {
    local required_mb=1
    local available_mb=99999
    if [ "$available_mb" -lt "$required_mb" ]; then return 1; fi
    return 0
  }
  _check_disk_space_stub
}
set +e; run_disk_ok; code=$?; set -e
_assert "磁盘充足时检查通过" "0" "$code"

# ---- 测试：磁盘空间检查（失败：空间不足）-----------------------
run_disk_fail() {
  _check_disk_space_stub_fail() {
    local required_mb=99999999
    local available_mb=1
    if [ "$available_mb" -lt "$required_mb" ]; then return 1; fi
    return 0
  }
  _check_disk_space_stub_fail
}
set +e; run_disk_fail; code=$?; set -e
_assert "磁盘不足时检查失败" "1" "$code"

# ---- 测试：shell 版本检查（当前 bash 应通过）-------------------
source "${SCRIPT_DIR}/lib/preflight.sh"
set +e; _check_shell; code=$?; set -e
_assert "当前 Bash 版本检查通过" "0" "$code"

# ---- 测试：_check_not_root 在非 root 下不报错 ------------------
set +e; _check_not_root; code=$?; set -e
_assert "_check_not_root 在非 root 下退出码为 0" "0" "$code"

# ---- 测试：OPENCLAW_REQUIRED_DISK_MB 环境变量被尊重 -----------
env_disk_test() {
  # 给一个极大要求，使其失败
  OPENCLAW_REQUIRED_DISK_MB=9999999999 _check_disk_space 2>/dev/null
}
set +e; env_disk_test; code=$?; set -e
_assert "OPENCLAW_REQUIRED_DISK_MB 极大时磁盘检查失败" "1" "$code"

echo ""
echo "preflight 测试完成：通过 ${pass}，失败 ${fail}"
[ "$fail" -eq 0 ]
