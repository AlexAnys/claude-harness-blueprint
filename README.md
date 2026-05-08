# Claude Harness Blueprint

从生产环境导出的多 Agent Harness 基础设施。每套都经过真实项目的持续迭代验证，不是理论模板。

**最快的上手方式**：在本仓库目录下打开 Claude Code，向导会引导你完成部署。

## Frameworks

| Framework | Agents | 模式 | 用途 |
|-----------|--------|------|------|
| [**opensource-lab**](harnesses/opensource-lab/) | 7 | Scout → Planner → Executor → QA + Curator + Comparator | 开源项目发现、安装、对比、维护 |
| [**llm-wiki**](harnesses/llm-wiki/) | 4 | Coordinator → Compiler → QA | 个人知识编译，wiki-is-blackboard |
| [**meta-harness**](harnesses/meta-harness/) | — | Claude Code Skill | 为任意项目自动设计 Harness |

## 快速部署

```bash
# 克隆
git clone https://github.com/AlexAnys/claude-harness-blueprint.git
cd claude-harness-blueprint

# 方式 1：向导模式（推荐）
claude
# Claude Code 会自动进入向导，引导你选择和部署

# 方式 2：一键脚本
bash scripts/deploy.sh opensource-lab ~/dev/opensource-lab
bash scripts/deploy.sh llm-wiki ~/Documents/my-wiki
bash scripts/deploy.sh meta-harness ~/.claude/skills/harness-design
```

## 三个不变量

1. **Planner ≠ Generator** — 写 spec 的 agent 不写实现
2. **Generator ≠ Evaluator** — 做事的 agent 不验收自己
3. **Agent Teams + Coordinator** — 持久化团队通过 SendMessage 直接协作，Coordinator 对齐用户意图

## 前置条件

- Claude Code（Max 或 Pro 订阅）
- `gh`（GitHub CLI）— `brew install gh`
- `jq` — `brew install jq`
- 可选：`mise`（多版本管理）、`direnv`（按目录环境）、`bws`（secrets 管理）

## License

MIT
