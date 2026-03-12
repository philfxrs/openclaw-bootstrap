#!/usr/bin/env bash
# tests/test_config.sh — 测试 lib/config.sh 模块
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

# ---- 测试：_ensure_config_dir 创建目录 -------------------------
tmp_dir=$(mktemp -d)
test_config_dir="${tmp_dir}/openclaw_test_config"

(
  OPENCLAW_CONFIG_DIR="$test_config_dir"
  source "${SCRIPT_DIR}/lib/config.sh"
  _ensure_config_dir
)
_assert "_ensure_config_dir 创建了目录" "true" "$([ -d "$test_config_dir" ] && echo true || echo false)"

# ---- 测试：_write_default_config 写入文件 ----------------------
test_config_file="${test_config_dir}/config.json"
(
  OPENCLAW_CONFIG_DIR="$test_config_dir"
  OPENCLAW_CONFIG_FILE="$test_config_file"
  source "${SCRIPT_DIR}/lib/config.sh"
  _write_default_config
)
_assert "_write_default_config 创建了 config.json" "true" "$([ -f "$test_config_file" ] && echo true || echo false)"
_assert "config.json 包含 version 字段" "true" "$(grep -q '"version"' "$test_config_file" && echo true || echo false)"
_assert "config.json 包含 language 字段" "true" "$(grep -q '"language"' "$test_config_file" && echo true || echo false)"

# ---- 测试：_write_default_config 不覆盖已有配置 ----------------
echo '{"version":"custom"}' > "$test_config_file"
(
  OPENCLAW_CONFIG_DIR="$test_config_dir"
  OPENCLAW_CONFIG_FILE="$test_config_file"
  source "${SCRIPT_DIR}/lib/config.sh"
  _write_default_config
)
_assert "_write_default_config 不覆盖已有配置" "true" "$(grep -q 'custom' "$test_config_file" && echo true || echo false)"

# ---- 测试：reset_config 备份并重写 ----------------------------
(
  OPENCLAW_CONFIG_DIR="$test_config_dir"
  OPENCLAW_CONFIG_FILE="$test_config_file"
  source "${SCRIPT_DIR}/lib/config.sh"
  OPENCLAW_NONINTERACTIVE=1 reset_config
)
_assert "reset_config 后 config.json 包含默认 version" "true" "$(grep -q '"version"' "$test_config_file" && echo true || echo false)"
_assert "reset_config 创建了 .bak 备份" "true" "$(ls "${test_config_file}".bak.* &>/dev/null && echo true || echo false)"

# 清理
rm -rf "$tmp_dir"

echo ""
echo "config 测试完成：通过 ${pass}，失败 ${fail}"
[ "$fail" -eq 0 ]
