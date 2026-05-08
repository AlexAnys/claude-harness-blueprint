# Open Source Lab 部署指南

## 这是什么

一个 7-agent 的开源项目管理实验室。部署完成后，你可以：
- 粘贴一个 GitHub 链接 → 自动研究、规划、安装、验证
- 说一个品类（"AI 记忆层"）→ 自动搜索 3-5 个候选项目并对比
- 所有项目集中在 `projects/` 文件夹下统一管理
- 自动积累安装经验，下次装类似项目更快更稳

## 部署步骤

### 步骤 1：选择安装位置

用户需要提供一个目录路径，Open Source Lab 会在该路径下创建。建议：
- 放在有足够磁盘空间的位置（开源项目可能占几 GB）
- 不要放在 iCloud / Dropbox 同步目录（git 仓库会产生大量小文件）

```bash
# 示例路径（向导应该先问用户，用户指定后替换）
LAB_DIR="<用户指定的路径>/opensource-lab"
```

### 步骤 2：复制基础设施

```bash
mkdir -p "$LAB_DIR"
# 复制 harness 基础设施（不含 .git）
cp -r harnesses/opensource-lab/.claude "$LAB_DIR/.claude"
cp -r harnesses/opensource-lab/.harness "$LAB_DIR/.harness"
cp -r harnesses/opensource-lab/scripts "$LAB_DIR/scripts"
cp harnesses/opensource-lab/CLAUDE.md "$LAB_DIR/CLAUDE.md"
cp harnesses/opensource-lab/test.md "$LAB_DIR/test.md"
cp harnesses/opensource-lab/registry.md "$LAB_DIR/registry.md"

# 创建项目目录结构
mkdir -p "$LAB_DIR/projects"
mkdir -p "$LAB_DIR/projects/_archive"
mkdir -p "$LAB_DIR/projects/_scouting"

# 设置脚本可执行
chmod +x "$LAB_DIR/scripts/"*.sh
chmod +x "$LAB_DIR/.claude/hooks/qa-gate.sh"
```

### 步骤 3：适配 CLAUDE.md

打开 `$LAB_DIR/CLAUDE.md`，做以下调整：

1. **Secrets 管理**：原版使用 `bws`（Bitwarden Secrets Manager）。如果你没有 bws：
   - 选项 A（推荐）：安装 bws → `brew install bitwarden/bws/bws`，然后配置 access token
   - 选项 B（简化）：在 CLAUDE.md 中将 "Secrets via bws" 规则改为你的 secrets 管理方式（环境变量、.env 文件等），并更新 `.harness/secrets-map.md`

2. **端口范围**：默认 8080-8999。如果与你的其他服务冲突，修改 CLAUDE.md 中的端口范围和 `scripts/port-registry.sh` 中的检查逻辑。

3. **工具链偏好**：默认使用 `mise`（`.tool-versions`）管理 Node/Python/Go 版本。如果你用其他方式（nvm/pyenv/直接 brew），在 CLAUDE.md 的 Conventions 中调整。

### 步骤 4：检查前置工具

```bash
# 必要工具
which gh     || echo "需要安装: brew install gh"       # GitHub CLI
which jq     || echo "需要安装: brew install jq"       # JSON 处理

# 推荐工具（没有也能跑，但体验更好）
which mise   || echo "推荐安装: brew install mise"     # 多版本管理
which direnv || echo "推荐安装: brew install direnv"   # 按目录切环境

# Secrets 管理（如果选了 bws）
which bws    || echo "如需 bws: brew install bitwarden/bws/bws"
```

### 步骤 5：初始化 registry

向导应帮用户确认 registry.md 的表头格式已就位（导出时已清空数据行，表头保留）。

### 步骤 6：验证部署

```bash
cd "$LAB_DIR"
claude
```

Claude Code 会自动进入 @coordinator（因为 `settings.json` 设了 `"agent": "coordinator"`）。

验证方式：
- 告诉 coordinator："lab health?" — 它应该跑 `scripts/disk-audit.sh` 并报告空 lab 状态
- 告诉 coordinator："test harness" — 它应该读 `test.md` 并逐项检查基础设施

### 步骤 7：第一个项目

部署完成后，试一下：

```
粘贴一个 GitHub 链接，比如：https://github.com/plandex-ai/plandex
```

Coordinator 会：
1. 跑 `scripts/similarity-check.sh` 检查是否与已有项目重复
2. 调度 @planner 研究项目 → 生成 `projects/plandex/plan.md` + `decisions.md` + `data-touched.md`
3. 让你审核 plan 并做决策
4. 审核通过后调度 @executor 按 plan 安装
5. 安装完成后调度 @qa 用 8 维度 scorecard 独立验证
6. 更新 `registry.md`

或者说一个品类：

```
我想找一个 AI 代码 review 工具
```

Coordinator 会调度 @scout 搜索候选项目，生成对比表，你选中后再走安装流程。

## 日常使用

| 你说 | Lab 做什么 |
|------|-----------|
| 粘贴 GitHub URL | Planner → 审批 → Executor → QA → 注册 |
| "我想找一个 XX" | Scout → 对比表 → 你选 → 安装流程 |
| "对比 A 和 B" | Comparator → 8 维度并排报告 |
| "重新验证 XX" | Curator → scripts/reverify.sh |
| "归档 XX" | Curator → scripts/archive.sh |
| "上游有什么新的" | scripts/upstream-digest.sh |
| "lab 状态" | scripts/disk-audit.sh + registry 巡检 |

## 卸载

```bash
rm -rf "$LAB_DIR"
```

所有项目数据都在 `$LAB_DIR` 内，没有外部残留（除非某个项目在 `~/.<name>/` 下创建了状态目录——这些会在每个项目的 `setup-log.md` 中记录）。
