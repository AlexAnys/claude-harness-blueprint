# Claude Code Harness Blueprint

> **TL;DR** A library of copy-paste templates that turn a single Claude Code session into
> a disciplined multi-agent pipeline. No framework, no dependency, no build step ---
> just `.claude/agents/*.md` files and a `.harness/` folder you drop into any repo.

---

## 缘起

Claude Code 的单 agent 模式在简单任务上表现出色，但遇到复杂项目时会出现
三种可预测的失败模式：

| 失败模式 | 症状 | 根因 |
|----------|------|------|
| **自评偏差** | agent 认为自己写的代码没问题，跳过验证 | Generator = Evaluator |
| **Scope Creep** | 一次改动牵连十几个文件，最终回不去 | 缺少 spec 锚点 |
| **Context 丢失** | 长会话后忘记早期约定 | 无持久化中间产物 |

好消息是：Claude Code 原生能力（Agent Teams、`agents/*.md`、hooks、`SendMessage`）
已经足够解决这些问题。**Harness 不是一个框架**，而是对这些原生能力的最优利用路径。

核心洞察很简单 --- **把一个 agent 的三种角色拆开，分配给不同 agent**：

```
Planner (想)  -->  spec.md
Generator (做) -->  代码 / 文档
Evaluator (查) -->  report + 验收
```

## 三个核心不变量

1. **Planner ≠ Generator** --- 写 spec 的 agent 不写代码，写代码的 agent 不改 spec
2. **Generator ≠ Evaluator** --- 写代码的 agent 不跑验收，跑验收的 agent 不改代码
3. **Agent Teams + Coordinator** --- 用 Claude Code 原生 Agent Teams 而非 subagent 嵌套

## 5 分钟上手

```bash
# 1. 克隆
git clone https://github.com/your-org/claude-harness-blueprint.git
cd claude-harness-blueprint

# 2. 选模板（以 software-dev 为例）
cp -r templates/software-dev/.claude   your-project/.claude
cp -r templates/software-dev/.harness  your-project/.harness
cp templates/software-dev/CLAUDE.md.example your-project/CLAUDE.md

# 3. 定制 --- 搜索 [YOUR_PROJECT: ...] 标记并替换
grep -rn '\[YOUR_PROJECT' your-project/.claude/

# 4. 启动 Claude Code
cd your-project
claude

# 5. 验证 harness 自身
# 在 Claude Code 中运行：
#   @coordinator 请按照 .harness/test.md 验收 harness 配置
```

## 6 种模式速览

| 模式 | 角色 | 典型场景 | 模板路径 |
|------|------|----------|----------|
| **software-dev** | Coordinator → Builder → QA | Web App、CLI、库开发 | `templates/software-dev/` |
| **knowledge-wiki** | Coordinator → Compiler → QA | 知识库编译与维护 | `templates/knowledge-wiki/` |
| **operations** | Coordinator → Executor → Monitor | Issue triage、日常运维 | `templates/operations/` |
| **orchestrator** | Coordinator → N x Worker | 多项目/多仓库协调 | `templates/orchestrator/` |
| **automation-task** | Task Runner → Reviewer | 定时/触发式自动化 | `templates/automation-task/` |
| **meta-harness** | Harness Designer → Validator | 设计 harness 本身 | `templates/meta-harness/` |

## 仓库结构

```
claude-harness-blueprint/
├── README.md               # 本文件
├── PRINCIPLES.md           # 10 条不变量 + 5 个反模式
├── METHODOLOGY.md          # 6 种模式详解 + 决策树
├── CLAUDE.md               # 仓库自身约束
├── LICENSE                 # MIT
│
├── templates/
│   ├── software-dev/       # Plan → Build → QA
│   │   ├── .claude/
│   │   │   ├── settings.json
│   │   │   └── agents/
│   │   │       ├── coordinator.md
│   │   │       ├── builder.md
│   │   │       └── qa.md
│   │   ├── .harness/
│   │   │   ├── spec.md
│   │   │   ├── progress.tsv
│   │   │   ├── HANDOFF.md
│   │   │   ├── test.md
│   │   │   ├── experience/
│   │   │   ├── contracts/
│   │   │   └── reports/
│   │   └── CLAUDE.md.example
│   │
│   ├── knowledge-wiki/     # Ingest → Compile → Lint
│   ├── operations/         # Route → Execute → Monitor
│   ├── orchestrator/       # 多项目协调
│   ├── automation-task/    # 自动化任务
│   └── meta-harness/       # 设计 harness 自身
│
├── docs/                   # 补充文档
├── examples/               # 端到端示例
├── reference/              # Agent / Hook / Schema 参考
└── scripts/                # 辅助脚本
```

## 适合谁

- 已经在用 Claude Code，想让它在复杂任务中更可靠
- 需要可审计、可回溯的 AI 辅助开发流程
- 团队中有多人使用 Claude Code，需要统一规范
- 想把重复性工作流模板化

## 不适合谁

- 只需要单次问答（直接用 Claude Code 即可）
- 需要实时 API 服务（这不是 runtime 框架）
- 寻找 LangChain / AutoGen 替代品（这是 prompt 模板，不是代码库）

## 核心原则

详见 [PRINCIPLES.md](PRINCIPLES.md) --- 10 条不变量约束 harness 设计，
5 个反模式帮你避坑。

## 方法论

详见 [METHODOLOGY.md](METHODOLOGY.md) --- 6 种模式的完整决策树和升级路径。

## License

MIT --- 详见 [LICENSE](LICENSE)
