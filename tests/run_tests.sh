#!/usr/bin/env bash
# tests/run_tests.sh — 运行所有 shell 单元测试
# -------------------------------------------------------
set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

run_test_file() {
  local file="$1"
  echo ""
  echo "══════════════════════════════════════════"
  echo "  运行测试：$(basename "$file")"
  echo "══════════════════════════════════════════"
  if bash "$file"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "[FAIL] $(basename "$file") 有测试失败。"
  fi
}

for test_file in "$TESTS_DIR"/test_*.sh; do
  run_test_file "$test_file"
done

echo ""
echo "══════════════════════════════════════════"
echo "  测试结果：通过 ${PASS} 个，失败 ${FAIL} 个"
echo "══════════════════════════════════════════"

[ "$FAIL" -eq 0 ]
