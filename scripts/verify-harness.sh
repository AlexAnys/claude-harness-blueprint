#!/usr/bin/env bash
# 用法: verify-harness.sh [target-dir]
# 默认: 当前目录
#
# 验证 Harness 配置完整性。输出 PASS/FAIL 报告。

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TARGET_DIR="${1:-.}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} 目录不存在: $TARGET_DIR"
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "════════════════════════════════════════════"
echo "  Harness 配置验证"
echo "  目标: $TARGET_DIR"
echo "════════════════════════════════════════════"
echo ""

TOTAL=0
PASSED=0
FAILED=0

check() {
  local desc="$1"
  local result="$2"  # "pass" or "fail"
  local detail="${3:-}"

  TOTAL=$((TOTAL + 1))
  if [[ "$result" == "pass" ]]; then
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}PASS${NC} $desc"
  else
    FAILED=$((FAILED + 1))
    echo -e "  ${RED}FAIL${NC} $desc"
    if [[ -n "$detail" ]]; then
      echo -e "       ${YELLOW}→ $detail${NC}"
    fi
  fi
}

# ── 1. settings.json 存在且含 "agent" ─────────────
echo -e "${CYAN}[1/5] settings.json${NC}"

SETTINGS="$TARGET_DIR/.claude/settings.json"
if [[ -f "$SETTINGS" ]]; then
  check "settings.json 存在" "pass"

  if grep -q '"agent"' "$SETTINGS"; then
    check "settings.json 含 \"agent\" 字段" "pass"
  else
    check "settings.json 含 \"agent\" 字段" "fail" "添加 \"agent\": \"coordinator\" 到 settings.json"
  fi
else
  check "settings.json 存在" "fail" "缺少 .claude/settings.json"
  check "settings.json 含 \"agent\" 字段" "fail" "settings.json 不存在"
fi

echo ""

# ── 2. 至少 2 个 agent 定义 ───────────────────────
echo -e "${CYAN}[2/5] Agent 定义${NC}"

AGENTS_DIR="$TARGET_DIR/.claude/agents"
if [[ -d "$AGENTS_DIR" ]]; then
  AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
  if [[ "$AGENT_COUNT" -ge 2 ]]; then
    check "至少 2 个 agent 定义 (找到 $AGENT_COUNT 个)" "pass"
  else
    check "至少 2 个 agent 定义 (找到 $AGENT_COUNT 个)" "fail" "Harness 至少需要 Coordinator + 1 个执行角色"
  fi

  # 列出 agent 文件
  for f in "$AGENTS_DIR"/*.md; do
    [[ -f "$f" ]] && echo -e "       $(basename "$f")"
  done
else
  check "至少 2 个 agent 定义" "fail" "agents/ 目录不存在"
fi

echo ""

# ── 3. .harness/ 或 wiki/ 结构 ────────────────────
echo -e "${CYAN}[3/5] Harness 结构${NC}"

if [[ -d "$TARGET_DIR/.harness" ]]; then
  check "Harness 产物目录 (.harness/) 存在" "pass"
elif [[ -d "$TARGET_DIR/wiki" ]]; then
  check "Harness 产物目录 (wiki/) 存在" "pass"
elif [[ -d "$TARGET_DIR/tasks" ]]; then
  check "Harness 产物目录 (tasks/) 存在" "pass"
else
  check "Harness 产物目录存在" "fail" "缺少 .harness/ 或 wiki/ 或 tasks/"
fi

echo ""

# ── 4. QA agent 不含 Edit ─────────────────────────
echo -e "${CYAN}[4/5] QA Agent 工具约束${NC}"

QA_CHECKED=false
if [[ -d "$AGENTS_DIR" ]]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue
    fname="$(basename "$agent_file")"

    # 识别 QA/Monitor/Evaluator/Reviewer 角色
    if echo "$fname" | grep -iqE 'qa|monitor|evaluator|reviewer'; then
      QA_CHECKED=true
      if grep -q 'Edit' "$agent_file"; then
        check "$fname 不含 Edit 工具" "fail" "QA/Evaluator 不应有 Edit 权限（破坏独立验收）"
      else
        check "$fname 不含 Edit 工具" "pass"
      fi
    fi
  done
fi

if [[ "$QA_CHECKED" = false ]]; then
  check "QA agent 存在" "fail" "未找到名称含 qa/monitor/evaluator/reviewer 的 agent"
fi

echo ""

# ── 5. 所有 agent 有 model: opus[1m] ──────────────
echo -e "${CYAN}[5/5] Agent Model 配置${NC}"

if [[ -d "$AGENTS_DIR" ]]; then
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue
    fname="$(basename "$agent_file")"

    if grep -q 'model:.*opus\[1m\]' "$agent_file"; then
      check "$fname: model = opus[1m]" "pass"
    elif grep -q 'model:' "$agent_file"; then
      MODEL=$(grep 'model:' "$agent_file" | head -1 | sed 's/.*model:[[:space:]]*//')
      check "$fname: model = opus[1m]" "fail" "当前: $MODEL"
    else
      check "$fname: model 字段存在" "fail" "缺少 model 字段"
    fi
  done
fi

# ── 汇总 ──────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo "  总计: $TOTAL 项检查"
echo -e "  ${GREEN}通过${NC}: $PASSED"
echo -e "  ${RED}失败${NC}: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
  echo -e "  ${GREEN}结果: ALL PASS${NC}"
  echo "════════════════════════════════════════════"
  exit 0
else
  echo -e "  ${RED}结果: $FAILED 项需要修复${NC}"
  echo "════════════════════════════════════════════"
  exit 1
fi
