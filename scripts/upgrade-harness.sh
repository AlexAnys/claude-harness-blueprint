#!/usr/bin/env bash
# 用法: upgrade-harness.sh <target-dir>
#
# 检查已有 Harness 配置的健康状况，输出诊断报告。
# 不修改任何文件，只读分析。

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC} $*"; }
warn() { echo -e "  ${YELLOW}WARN${NC} $*"; }
fail() { echo -e "  ${RED}FAIL${NC} $*"; }

# ── 参数 ──────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "用法: $0 <target-dir>"
  exit 1
fi

TARGET_DIR="$1"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} 目录不存在: $TARGET_DIR"
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "════════════════════════════════════════════"
echo "  Harness 升级诊断报告"
echo "  目标: $TARGET_DIR"
echo "════════════════════════════════════════════"
echo ""

ISSUES=0
WARNINGS=0

# ── 1. settings.json ──────────────────────────────
echo -e "${CYAN}── settings.json ──${NC}"

SETTINGS="$TARGET_DIR/.claude/settings.json"
if [[ ! -f "$SETTINGS" ]]; then
  fail "settings.json 不存在"
  ISSUES=$((ISSUES + 1))
else
  # 检查 "agent" 字段
  if grep -q '"agent"' "$SETTINGS"; then
    AGENT_VALUE=$(grep '"agent"' "$SETTINGS" | head -1 | sed 's/.*"agent"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    pass "默认 agent: $AGENT_VALUE"
  else
    fail "缺少 \"agent\" 字段（无默认入口 agent）"
    ISSUES=$((ISSUES + 1))
  fi

  # 检查 Stop hook
  if grep -q '"Stop"' "$SETTINGS"; then
    pass "Stop hook 已配置"
  else
    warn "缺少 Stop hook（建议添加审计追踪）"
    WARNINGS=$((WARNINGS + 1))
  fi

  # 检查 permissions
  if grep -q '"permissions"' "$SETTINGS"; then
    pass "permissions 已配置"
  else
    warn "缺少 permissions 配置"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

echo ""

# ── 2. Agent 定义 ─────────────────────────────────
echo -e "${CYAN}── Agent 定义 ──${NC}"

AGENTS_DIR="$TARGET_DIR/.claude/agents"
if [[ ! -d "$AGENTS_DIR" ]]; then
  fail "agents/ 目录不存在"
  ISSUES=$((ISSUES + 1))
else
  AGENT_COUNT=$(find "$AGENTS_DIR" -name "*.md" -type f | wc -l | tr -d ' ')
  if [[ "$AGENT_COUNT" -lt 2 ]]; then
    fail "只找到 $AGENT_COUNT 个 agent 定义（至少需要 2 个）"
    ISSUES=$((ISSUES + 1))
  else
    pass "找到 $AGENT_COUNT 个 agent 定义"
  fi

  # 逐个检查 agent
  for agent_file in "$AGENTS_DIR"/*.md; do
    [[ -f "$agent_file" ]] || continue
    fname="$(basename "$agent_file")"

    # 检查 model
    if grep -q 'model:.*opus\[1m\]' "$agent_file"; then
      pass "$fname: model 正确 (opus[1m])"
    elif grep -q 'model:' "$agent_file"; then
      MODEL=$(grep 'model:' "$agent_file" | head -1 | sed 's/.*model:[[:space:]]*//')
      fail "$fname: model 不正确 ($MODEL)，应为 opus[1m]"
      ISSUES=$((ISSUES + 1))
    else
      fail "$fname: 缺少 model 字段"
      ISSUES=$((ISSUES + 1))
    fi

    # 检查 QA agent 不含 Edit
    if echo "$fname" | grep -iq 'qa\|monitor\|evaluator\|reviewer'; then
      if grep -q 'Edit' "$agent_file"; then
        fail "$fname: QA/Evaluator agent 不应有 Edit 工具！"
        ISSUES=$((ISSUES + 1))
      else
        pass "$fname: 无 Edit 工具（正确）"
      fi
    fi
  done
fi

echo ""

# ── 3. Harness 结构 ───────────────────────────────
echo -e "${CYAN}── Harness 结构 ──${NC}"

if [[ -d "$TARGET_DIR/.harness" ]]; then
  pass ".harness/ 目录存在"

  # 检查关键文件
  for expected in spec.md progress.tsv test.md; do
    if [[ -f "$TARGET_DIR/.harness/$expected" ]]; then
      pass ".harness/$expected 存在"
    else
      warn ".harness/$expected 不存在"
      WARNINGS=$((WARNINGS + 1))
    fi
  done

  # 检查 experience 目录
  if [[ -d "$TARGET_DIR/.harness/experience" ]]; then
    pass ".harness/experience/ 存在"
  else
    warn ".harness/experience/ 不存在（建议创建）"
    WARNINGS=$((WARNINGS + 1))
  fi

  # 检查 reports 目录
  if [[ -d "$TARGET_DIR/.harness/reports" ]]; then
    pass ".harness/reports/ 存在"
  else
    warn ".harness/reports/ 不存在（建议创建）"
    WARNINGS=$((WARNINGS + 1))
  fi
elif [[ -d "$TARGET_DIR/wiki" ]]; then
  pass "wiki/ 目录存在（knowledge-wiki 模式）"
elif [[ -d "$TARGET_DIR/tasks" ]]; then
  pass "tasks/ 目录存在（automation-task 模式）"
else
  warn "无 .harness/、wiki/ 或 tasks/ 目录"
  WARNINGS=$((WARNINGS + 1))
fi

echo ""

# ── 报告 ──────────────────────────────────────────
echo "════════════════════════════════════════════"
if [[ $ISSUES -eq 0 && $WARNINGS -eq 0 ]]; then
  echo -e "  ${GREEN}结果: 全部通过${NC}"
elif [[ $ISSUES -eq 0 ]]; then
  echo -e "  ${YELLOW}结果: 通过，但有 $WARNINGS 个建议${NC}"
else
  echo -e "  ${RED}结果: $ISSUES 个问题需要修复, $WARNINGS 个建议${NC}"
fi
echo "════════════════════════════════════════════"
