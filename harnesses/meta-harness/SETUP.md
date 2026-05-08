# Meta Skill 安装指南

## 这是什么

安装后，你可以在任意项目目录中使用 `/harness-design` 命令，Claude Code 会根据项目描述自动设计一套多 Agent Harness（agent 定义文件、settings.json、hooks、黑板结构）。

三种项目类型都支持：
- 软件开发 → Planner → Builder → QA
- 知识编译 → Coordinator → Compiler → QA
- 运维操作 → Coordinator → Executor → Monitor

## 安装步骤

### 步骤 1：检查前置条件

```bash
# 确认 Claude Code 已安装
claude --version
# 确认 skills 目录存在
ls ~/.claude/skills/ 2>/dev/null || mkdir -p ~/.claude/skills/
```

### 步骤 2：复制 Skill 文件

```bash
cp -r harnesses/meta-harness/ ~/.claude/skills/harness-design/
```

复制后的结构：
```
~/.claude/skills/harness-design/
├── SKILL.md                    # 核心方法论（Claude Code 自动读取）
├── references/                 # 5 个参考实现
│   ├── software_harness.md
│   ├── knowledge_harness.md
│   ├── operations_harness.md
│   ├── enforcement.md
│   └── agent_definitions.md
├── README.md
└── SETUP.md                    # 本文件（可删）
```

### 步骤 3：验证安装

在任意项目目录中打开 Claude Code，输入：

```
/harness-design 一个 Next.js 全栈应用
```

如果 Claude Code 开始分析项目并设计 agent 角色，说明安装成功。

## 使用方式

在你想搭建 Harness 的**项目目录**中，输入：

```
/harness-design <项目描述>
```

示例：
```
/harness-design 用 React + Python FastAPI 做的仪表盘应用
/harness-design 从 Markdown 文件构建文档知识库
/harness-design GitHub Issue 自动分流和标签管理
```

Skill 会：
1. 判断项目类型（软件/知识/运维）
2. 检查是否已有 harness（有则升级，无则新建）
3. 做领域研究（读代码、读 CLAUDE.md）
4. 生成 `.claude/agents/*.md`、`.claude/settings.json`、`.harness/` 结构
5. 生成 `test.md` 验收清单

## 卸载

```bash
rm -rf ~/.claude/skills/harness-design/
```
