# Claude Harness Blueprint

从生产环境导出的多智能体 Harness 基础设施。每套 Harness 都经过真实项目的持续迭代验证，不是理论模板。

## Harnesses

| Harness | Agent 数 | 模式 | 用途 |
|---------|---------|------|------|
| [**llm-wiki**](harnesses/llm-wiki/) | 4 | Coordinator → Compiler → QA | 个人知识编译，wiki-is-blackboard |
| [**opensource-lab**](harnesses/opensource-lab/) | 7 | Coordinator → Scout/Planner/Executor/QA/Curator/Comparator | 开源项目发现、安装、对比、维护 |
| [**meta-harness**](harnesses/meta-harness/) | — | Claude Code Skill | 为任意项目自动设计 Harness 的方法论 |

## 三个不变量

1. **Planner ≠ Generator** — 写 spec 的 agent 不写实现
2. **Generator ≠ Evaluator** — 做事的 agent 不验收自己
3. **Agent Teams + Coordinator** — 持久化团队通过 SendMessage 直接协作，Coordinator 对齐用户意图

## 使用方式

每套 Harness 可独立复制到你的项目中：

```bash
# 以 llm-wiki 为例
cp -r harnesses/llm-wiki/.claude your-project/.claude
cp harnesses/llm-wiki/CLAUDE.md your-project/CLAUDE.md
# 然后搜索占位符并替换为你的项目信息
```

Meta Harness 安装为 Claude Code skill：

```bash
cp -r harnesses/meta-harness ~/.claude/skills/harness-design
```

详见各 Harness 目录下的 README.md。

## License

MIT
