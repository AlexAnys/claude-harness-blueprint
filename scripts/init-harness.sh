#!/usr/bin/env bash
# 用法: init-harness.sh <template-id> <target-dir>
# 模板: software-dev | knowledge-wiki | operations | orchestrator | automation-task | meta-harness
#
# 交互式初始化 Harness。将模板复制到目标项目目录。
# 不覆盖已有文件，settings.json 冲突时提示手动 merge。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VALID_TEMPLATES="software-dev knowledge-wiki operations orchestrator automation-task meta-harness"

# ── 颜色 ──────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── 参数验证 ──────────────────────────────────────
if [[ $# -lt 2 ]]; then
  echo "用法: $0 <template-id> <target-dir>"
  echo ""
  echo "可用模板:"
  for t in $VALID_TEMPLATES; do
    echo "  - $t"
  done
  exit 1
fi

TEMPLATE_ID="$1"
TARGET_DIR="$2"

# 验证模板 ID
if ! echo "$VALID_TEMPLATES" | grep -qw "$TEMPLATE_ID"; then
  error "无效模板: $TEMPLATE_ID\n可用模板: $VALID_TEMPLATES"
fi

TEMPLATE_DIR="$REPO_ROOT/templates/$TEMPLATE_ID"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  error "模板目录不存在: $TEMPLATE_DIR"
fi

# 验证目标目录
if [[ ! -d "$TARGET_DIR" ]]; then
  error "目标目录不存在: $TARGET_DIR"
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

info "模板: $TEMPLATE_ID"
info "目标: $TARGET_DIR"
echo ""

# ── .harness/ ─────────────────────────────────────
if [[ -d "$TARGET_DIR/.harness" ]]; then
  error ".harness/ 已存在于 $TARGET_DIR\n请先备份后删除，再重新运行。"
fi

if [[ -d "$TEMPLATE_DIR/.harness" ]]; then
  info "创建 .harness/ ..."
  cp -r "$TEMPLATE_DIR/.harness" "$TARGET_DIR/.harness"
  info ".harness/ 已创建"
else
  # 有些模板可能没有 .harness（如 automation-task 用 tasks/）
  warn "模板中无 .harness/ 目录，跳过"
fi

# 复制模板特有目录（wiki/, tasks/ 等）
for special_dir in wiki raw tasks references; do
  if [[ -d "$TEMPLATE_DIR/$special_dir" ]]; then
    if [[ -d "$TARGET_DIR/$special_dir" ]]; then
      warn "$special_dir/ 已存在，跳过"
    else
      info "创建 $special_dir/ ..."
      cp -r "$TEMPLATE_DIR/$special_dir" "$TARGET_DIR/$special_dir"
    fi
  fi
done

# ── .claude/agents/ ───────────────────────────────
mkdir -p "$TARGET_DIR/.claude/agents"

if [[ -d "$TEMPLATE_DIR/.claude/agents" ]]; then
  COPIED=0
  SKIPPED=0
  for agent_file in "$TEMPLATE_DIR/.claude/agents"/*.md; do
    [[ -f "$agent_file" ]] || continue
    fname="$(basename "$agent_file")"
    if [[ -f "$TARGET_DIR/.claude/agents/$fname" ]]; then
      warn "agent 文件已存在，跳过: .claude/agents/$fname"
      SKIPPED=$((SKIPPED + 1))
    else
      cp "$agent_file" "$TARGET_DIR/.claude/agents/$fname"
      COPIED=$((COPIED + 1))
    fi
  done
  info "Agent 文件: $COPIED 个已复制, $SKIPPED 个已跳过"
fi

# ── .claude/settings.json ─────────────────────────
if [[ -f "$TEMPLATE_DIR/.claude/settings.json" ]]; then
  if [[ -f "$TARGET_DIR/.claude/settings.json" ]]; then
    warn "settings.json 已存在！"
    warn "请手动 merge 以下内容到你的 settings.json:"
    echo ""
    echo "  来源: $TEMPLATE_DIR/.claude/settings.json"
    echo ""
    echo "  关键字段:"
    echo "    - \"agent\": 设置默认入口 agent"
    echo "    - \"hooks\": 添加 Stop hook"
    echo "    - \"permissions\": 添加 agent 所需权限"
    echo ""
  else
    cp "$TEMPLATE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"
    info "settings.json 已复制"
  fi
fi

# ── CLAUDE.md ─────────────────────────────────────
if [[ -f "$TARGET_DIR/CLAUDE.md" ]]; then
  warn "CLAUDE.md 已存在，跳过（不修改已有约束文件）"
elif [[ -f "$TEMPLATE_DIR/CLAUDE.md.example" ]]; then
  cp "$TEMPLATE_DIR/CLAUDE.md.example" "$TARGET_DIR/CLAUDE.md"
  info "CLAUDE.md 已从 example 创建"
else
  warn "模板中无 CLAUDE.md.example，跳过"
fi

# ── 完成 ──────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
info "Harness 初始化完成！"
echo ""
echo "下一步:"
echo "  1. 搜索占位符并替换:"
echo "     grep -rn '\\[YOUR_PROJECT' $TARGET_DIR/.claude/"
echo ""
echo "  2. 从项目 CLAUDE.md 提取约束，写入 QA agent 的验收维度"
echo ""
echo "  3. 验证配置:"
echo "     $SCRIPT_DIR/verify-harness.sh $TARGET_DIR"
echo ""
echo "  4. 启动 Claude Code:"
echo "     cd $TARGET_DIR && claude"
echo "════════════════════════════════════════════"
