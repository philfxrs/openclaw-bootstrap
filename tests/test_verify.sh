#!/usr/bin/env bash
# tests/test_verify.sh — 测试 lib/verify.sh 各验证项（stub 模式）
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

# ---- 辅助：运行子 bash 并捕获退出码（丢弃 stdout/stderr）-----
_run_in_subshell() {
  set +e
  bash -c "$1" >/dev/null 2>&1
  local rc=$?
  set -e
  echo "$rc"
}

# ---- 测试：_assert_command 找到命令时返回 0 -------------------
code=$(_run_in_subshell "
  source '${SCRIPT_DIR}/lib/logger.sh'
  source '${SCRIPT_DIR}/lib/verify.sh'
  _assert_command bash 'Bash'
")
_assert "_assert_command 找到 bash 时通过" "0" "$code"

# ---- 测试：_assert_command 找不到命令时返回非 0 ---------------
code=$(_run_in_subshell "
  source '${SCRIPT_DIR}/lib/logger.sh'
  source '${SCRIPT_DIR}/lib/verify.sh'
  _assert_command __nonexistent_cmd_xyz__ '测试命令'
")
_assert "_assert_command 找不到命令时失败" "1" "$code"

# ---- 测试：_verify_config 配置文件存在时不报错 ----------------
tmp_cfg_dir=$(mktemp -d)
tmp_cfg_file="${tmp_cfg_dir}/config.json"
echo '{"version":"1.0"}' > "$tmp_cfg_file"

code=$(_run_in_subshell "
  source '${SCRIPT_DIR}/lib/logger.sh'
  source '${SCRIPT_DIR}/lib/verify.sh'
  OPENCLAW_CONFIG_DIR='${tmp_cfg_dir}' _verify_config
")
_assert "_verify_config 配置文件存在时退出码 0" "0" "$code"
rm -rf "$tmp_cfg_dir"

# ---- 测试：_verify_config 配置文件不存在时输出警告（退出码 0）--
code=$(_run_in_subshell "
  source '${SCRIPT_DIR}/lib/logger.sh'
  source '${SCRIPT_DIR}/lib/verify.sh'
  OPENCLAW_CONFIG_DIR='/tmp/__no_such_dir_xyz__' _verify_config
")
_assert "_verify_config 配置文件不存在时退出码仍为 0" "0" "$code"

echo ""
echo "verify 测试完成：通过 ${pass}，失败 ${fail}"
[ "$fail" -eq 0 ]
