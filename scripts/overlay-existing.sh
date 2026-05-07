#!/usr/bin/env bash
# 用法: overlay-existing.sh <template-id> <target-dir>
#
# 更保守的初始化版本。绝不覆盖任何已存在文件，只创建缺失的文件。
# 详细报告每个文件的处理结果。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

VALID_TEMPLATES="software-dev knowledge-wiki operations orchestrator automation-task meta-harness"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[CREATED]${NC} $*"; }
skip()    { echo -e "${YELLOW}[SKIPPED]${NC} $*"; }
section() { echo -e "\n${CYAN}── $* ──${NC}"; }

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

if ! echo "$VALID_TEMPLATES" | grep -qw "$TEMPLATE_ID"; then
  echo -e "${RED}[ERROR]${NC} 无效模板: $TEMPLATE_ID"
  exit 1
fi

TEMPLATE_DIR="$REPO_ROOT/templates/$TEMPLATE_ID"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} 模板目录不存在: $TEMPLATE_DIR"
  exit 1
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo -e "${RED}[ERROR]${NC} 目标目录不存在: $TARGET_DIR"
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

CREATED=0
SKIPPED=0

# ── 递归复制（只创建缺失文件）──────────────────────
copy_missing() {
  local src_dir="$1"
  local dst_dir="$2"
  local rel_prefix="$3"

  if [[ ! -d "$src_dir" ]]; then
    return
  fi

  mkdir -p "$dst_dir"

  # 复制文件
  for item in "$src_dir"/*; do
    [[ -e "$item" ]] || continue
    local name="$(basename "$item")"
    local rel_path="$rel_prefix$name"

    if [[ -d "$item" ]]; then
      copy_missing "$item" "$dst_dir/$name" "$rel_path/"
    elif [[ -f "$item" ]]; then
      if [[ -f "$dst_dir/$name" ]]; then
        skip "$rel_path (已存在)"
        SKIPPED=$((SKIPPED + 1))
      else
        cp "$item" "$dst_dir/$name"
        info "$rel_path"
        CREATED=$((CREATED + 1))
      fi
    fi
  done
}

echo "模板: $TEMPLATE_ID"
echo "目标: $TARGET_DIR"

# ── .claude/ ──────────────────────────────────────
section ".claude/"
copy_missing "$TEMPLATE_DIR/.claude" "$TARGET_DIR/.claude" ".claude/"

# ── .harness/ ─────────────────────────────────────
if [[ -d "$TEMPLATE_DIR/.harness" ]]; then
  section ".harness/"
  copy_missing "$TEMPLATE_DIR/.harness" "$TARGET_DIR/.harness" ".harness/"
fi

# ── 特殊目录 ──────────────────────────────────────
for special_dir in wiki raw tasks references; do
  if [[ -d "$TEMPLATE_DIR/$special_dir" ]]; then
    section "$special_dir/"
    copy_missing "$TEMPLATE_DIR/$special_dir" "$TARGET_DIR/$special_dir" "$special_dir/"
  fi
done

# ── CLAUDE.md ─────────────────────────────────────
section "根目录文件"
if [[ -f "$TARGET_DIR/CLAUDE.md" ]]; then
  skip "CLAUDE.md (已存在)"
  SKIPPED=$((SKIPPED + 1))
elif [[ -f "$TEMPLATE_DIR/CLAUDE.md.example" ]]; then
  cp "$TEMPLATE_DIR/CLAUDE.md.example" "$TARGET_DIR/CLAUDE.md"
  info "CLAUDE.md (从 example 创建)"
  CREATED=$((CREATED + 1))
fi

# ── 报告 ──────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo -e "  ${GREEN}创建${NC}: $CREATED 个文件"
echo -e "  ${YELLOW}跳过${NC}: $SKIPPED 个文件 (已存在)"
echo "════════════════════════════════════════════"

if [[ $SKIPPED -gt 0 ]]; then
  echo ""
  echo "提示: 被跳过的文件可能需要手动检查是否需要更新。"
  echo "      特别是 .claude/settings.json — 确认包含 \"agent\" 和 hooks 配置。"
fi
