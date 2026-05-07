#!/usr/bin/env bash
# SessionStart hook — 打印 Harness 状态 banner
#
# 在 settings.json 中配置:
# "hooks": {
#   "SessionStart": [
#     { "matcher": "", "command": ".claude/hooks/session-start.sh" }
#   ]
# }

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}  Harness Active${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"

# 检测模式
if [[ -d ".harness" ]]; then
  echo -e "  模式: Software / Operations"
elif [[ -d "wiki" ]]; then
  echo -e "  模式: Knowledge Wiki"
elif [[ -d "tasks" ]]; then
  echo -e "  模式: Automation Task"
else
  echo -e "  模式: ${YELLOW}未检测到${NC}"
fi

# 显示 agent 列表
if [[ -d ".claude/agents" ]]; then
  AGENTS=$(ls .claude/agents/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')
  echo -e "  Agents: $AGENTS"
fi

# 显示最近活动
if [[ -f ".harness/progress.tsv" ]]; then
  LINES=$(wc -l < .harness/progress.tsv | tr -d ' ')
  echo -e "  Progress: $LINES 条记录"
fi

if [[ -d ".harness/reports" ]]; then
  REPORTS=$(find .harness/reports -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo -e "  Reports: $REPORTS 份"
fi

# 检查是否有未完成的 spec
if [[ -f ".harness/spec.md" ]]; then
  echo -e "  ${GREEN}Spec: 已就绪${NC}"
else
  echo -e "  ${YELLOW}Spec: 无（等待新任务）${NC}"
fi

echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""
