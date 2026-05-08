#!/usr/bin/env bash
set -uo pipefail

TARGET="${1:-.}"
TARGET="$(cd "$TARGET" && pwd)"

pass=0
fail=0
warn=0

check() {
  if eval "$2" >/dev/null 2>&1; then
    echo "  ✓ $1"
    pass=$((pass + 1))
  else
    echo "  ✗ $1"
    fail=$((fail + 1))
  fi
}

warning() {
  echo "  ⚠ $1"
  warn=$((warn + 1))
}

echo "验证部署: $TARGET"
echo ""

# 基础结构
echo "--- 基础结构 ---"
check ".claude/ 目录存在" "[[ -d '$TARGET/.claude' ]]"
check "settings.json 存在" "[[ -f '$TARGET/.claude/settings.json' ]]"
check "CLAUDE.md 存在" "[[ -f '$TARGET/CLAUDE.md' ]]"

# settings.json 内容
if [[ -f "$TARGET/.claude/settings.json" ]]; then
  check "settings.json 含 agent 默认入口" "grep -q '\"agent\"' '$TARGET/.claude/settings.json'"
fi

# Agent 定义
echo ""
echo "--- Agent 定义 ---"
agent_count=0
if [[ -d "$TARGET/.claude/agents" ]]; then
  for agent_file in "$TARGET/.claude/agents/"*.md; do
    [[ -f "$agent_file" ]] || continue
    name=$(basename "$agent_file" .md)
    ((agent_count++))

    # model check
    if grep -q 'model:.*opus\[1m\]' "$agent_file" 2>/dev/null; then
      check "agent '$name' 使用 opus[1m]" "true"
    else
      check "agent '$name' 使用 opus[1m]" "false"
    fi

    # QA/monitor should not have Edit
    if [[ "$name" == "qa" || "$name" == "monitor" ]]; then
      if grep -qi 'Edit' "$agent_file" 2>/dev/null | head -5 | grep -qi 'tools.*Edit'; then
        warning "agent '$name' 可能有 Edit 工具（QA/Monitor 不应有 Edit）"
      fi
    fi
  done
fi
check "至少 2 个 agent 定义" "[[ $agent_count -ge 2 ]]"

# Hooks
echo ""
echo "--- Hooks ---"
if [[ -f "$TARGET/.claude/settings.json" ]]; then
  if grep -q '"hooks"' "$TARGET/.claude/settings.json" 2>/dev/null; then
    check "settings.json 含 hooks 配置" "true"
  else
    warning "settings.json 无 hooks — 没有自动 QA gate"
  fi
fi

# Harness 结构（软件/运维类）
if [[ -d "$TARGET/.harness" ]]; then
  echo ""
  echo "--- Harness 结构 ---"
  check ".harness/ 存在" "true"
  [[ -f "$TARGET/.harness/progress.tsv" ]] && check "progress.tsv 存在" "true"
  [[ -d "$TARGET/.harness/experience" ]] && check "experience/ 存在" "true"
  [[ -d "$TARGET/.harness/reports" ]] || warning ".harness/reports/ 不存在（agents 会尝试写入这里）"
fi

# Wiki 结构
if [[ -d "$TARGET/wiki" ]]; then
  echo ""
  echo "--- Wiki 结构 ---"
  check "wiki/ 存在" "true"
  check "wiki/index.md 存在" "[[ -f '$TARGET/wiki/index.md' ]]"
  [[ -d "$TARGET/raw" ]] && check "raw/ 存在" "true"
fi

# Scripts
if [[ -d "$TARGET/scripts" ]]; then
  echo ""
  echo "--- Scripts ---"
  for script in "$TARGET/scripts/"*.sh; do
    [[ -f "$script" ]] || continue
    name=$(basename "$script")
    if [[ -x "$script" ]]; then
      check "scripts/$name 可执行" "true"
    else
      warning "scripts/$name 不可执行 — 运行 chmod +x"
    fi
  done
fi

# 前置工具
echo ""
echo "--- 前置工具 ---"
which gh >/dev/null 2>&1 && check "gh (GitHub CLI)" "true" || warning "gh 未安装 — brew install gh"
which jq >/dev/null 2>&1 && check "jq" "true" || warning "jq 未安装 — brew install jq"

echo ""
echo "================================================"
echo "结果: $pass 通过, $fail 失败, $warn 警告"
if [[ $fail -eq 0 ]]; then
  echo "状态: PASS"
else
  echo "状态: FAIL — 请修复上述失败项"
fi
echo "================================================"

exit $fail
