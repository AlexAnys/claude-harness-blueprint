#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
用法: deploy.sh <framework-name> <install-path>

Framework:
  opensource-lab    开源项目发现/安装/对比/维护 (7 agents)
  llm-wiki         个人知识编译系统 (4 agents)
  meta-harness     Harness 设计方法论 (安装为 Claude Code Skill)

示例:
  bash scripts/deploy.sh opensource-lab ~/dev/opensource-lab
  bash scripts/deploy.sh llm-wiki ~/Documents/my-wiki
  bash scripts/deploy.sh meta-harness ~/.claude/skills/harness-design
USAGE
  exit 1
}

[[ $# -lt 2 ]] && usage

FRAMEWORK="$1"
INSTALL_PATH="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$REPO_ROOT/harnesses/$FRAMEWORK"

if [[ ! -d "$SOURCE" ]]; then
  echo "错误: 未找到 framework '$FRAMEWORK'"
  echo "可用: $(ls "$REPO_ROOT/harnesses/" | tr '\n' ' ')"
  exit 1
fi

# meta-harness 走特殊路径（安装为 skill）
if [[ "$FRAMEWORK" == "meta-harness" ]]; then
  if [[ -d "$INSTALL_PATH" ]]; then
    echo "目标已存在: $INSTALL_PATH"
    echo "如果要覆盖，请先删除: rm -rf $INSTALL_PATH"
    exit 1
  fi
  cp -r "$SOURCE" "$INSTALL_PATH"
  echo "✓ MetaSkill 已安装到 $INSTALL_PATH"
  echo ""
  echo "使用方式:"
  echo "  cd <你的项目目录>"
  echo "  claude"
  echo "  /harness-design <项目描述>"
  exit 0
fi

# 常规 framework 部署
INSTALL_PATH="${INSTALL_PATH%/}"

if [[ -d "$INSTALL_PATH/.claude" ]]; then
  echo "错误: $INSTALL_PATH/.claude 已存在"
  echo "为避免覆盖已有配置，请先备份或删除。"
  exit 1
fi

mkdir -p "$INSTALL_PATH"

echo "部署 $FRAMEWORK → $INSTALL_PATH"
echo ""

# 复制所有文件
cp -r "$SOURCE/." "$INSTALL_PATH/"

# 移除不需要的文件
rm -f "$INSTALL_PATH/SETUP.md" 2>/dev/null

# 确保目录结构完整
case "$FRAMEWORK" in
  opensource-lab)
    mkdir -p "$INSTALL_PATH/projects"
    mkdir -p "$INSTALL_PATH/projects/_archive"
    mkdir -p "$INSTALL_PATH/projects/_scouting"
    mkdir -p "$INSTALL_PATH/.harness/reports"
    chmod +x "$INSTALL_PATH/scripts/"*.sh 2>/dev/null
    chmod +x "$INSTALL_PATH/.claude/hooks/"*.sh 2>/dev/null
    ;;
  llm-wiki)
    mkdir -p "$INSTALL_PATH/raw/assets"
    mkdir -p "$INSTALL_PATH/wiki/sources"
    mkdir -p "$INSTALL_PATH/wiki/concepts"
    mkdir -p "$INSTALL_PATH/wiki/entities"
    mkdir -p "$INSTALL_PATH/wiki/synthesis"
    chmod +x "$INSTALL_PATH/scripts/"*.sh 2>/dev/null
    ;;
esac

echo "✓ 文件已复制"

# 运行验证
echo ""
bash "$SCRIPT_DIR/verify-deployment.sh" "$INSTALL_PATH"

echo ""
echo "================================================"
echo "部署完成！下一步："
echo ""
echo "  cd $INSTALL_PATH"
echo "  claude"
echo ""

case "$FRAMEWORK" in
  opensource-lab)
    echo "Claude Code 会自动进入 @coordinator。"
    echo "试试粘贴一个 GitHub 链接，比如："
    echo "  https://github.com/plandex-ai/plandex"
    ;;
  llm-wiki)
    echo "Claude Code 会自动进入 @coordinator。"
    echo "把源文件放到 raw/ 目录，然后说："
    echo "  编译 raw/ 中的新文件"
    ;;
esac
echo "================================================"
