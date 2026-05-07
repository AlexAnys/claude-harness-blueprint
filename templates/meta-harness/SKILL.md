# Harness 设计方法论

> 本文件是 Harness 方法论的完整蒸馏。用于指导为任意项目设计多 agent 协作结构。

---

## 核心思想

单个 AI agent 同时承担规划、执行、验证三个角色时，会产生自评偏差、scope creep
和 context 丢失。解决方法不是更强的 agent，而是**角色分离**。

Harness 不是框架，不是代码库。它是一组文件约定：
- `.claude/agents/*.md` 定义 agent 角色
- `.harness/` 存放协作产物（spec、report、progress）
- `CLAUDE.md` 提供项目级约束

---

## 三个不变量

**无论什么项目类型，以下三点不可违反：**

1. **Planner ≠ Generator** --- 写 spec 的 agent 不执行，执行的 agent 不改 spec
2. **Generator ≠ Evaluator** --- 做事的 agent 不自评，评估的 agent 不改产物
3. **Agent Teams 而非 Subagent** --- 使用 Claude Code 原生 Agent Teams 机制，
   Coordinator 通过 `Agent` 工具调度，不嵌套 subagent

---

## 黑板模式（Blackboard Pattern）

所有 agent 通过文件系统上的共享目录（`.harness/`）通信。这是"黑板"。

```
.harness/
├── spec.md           # Planner 的输出，Builder 的输入
├── progress.tsv      # 进度跟踪（TSV 格式，易于 grep）
├── HANDOFF.md        # 当前控制权归谁 + 上下文
├── test.md           # 验收清单（QA 的评判标准）
├── reports/          # 每次 build/QA 循环的报告
├── contracts/        # agent 间的接口约定
└── experience/       # 跨 session 的经验积累
```

关键原则：
- **spec.md 是锚点**：所有变更必须回溯到 spec
- **报告是不可变的**：写入 reports/ 后不修改，只追加新报告
- **progress.tsv 是真相源**：用 TSV 而非自由文本跟踪进度

---

## 四层 Enforcement

约束 agent 行为的四层机制，从软到硬：

| 层级 | 机制 | 强度 | 作用 |
|------|------|------|------|
| L1 | `CLAUDE.md` 规则 | 软约束 | 项目级指令 --- agent 应该遵守 |
| L2 | Agent 定义的 `tools` 字段 | 结构默认 | 没给的工具用不了 |
| L3 | `settings.json` 中的 hooks | 硬拦截 | Stop hook 在执行后检查 |
| L4 | `permissions` 白名单 | 硬限制 | 未列入的工具直接拒绝 |

最佳实践：
- L1 处理"应该怎么做"
- L2 处理"能做什么"（给 QA agent 去掉 Write/Edit 就无法改代码）
- L3 处理"做完后检查"（比如检查是否有未提交的文件）
- L4 处理"绝对不能做什么"

---

## 核心循环

所有 harness 共享同一个控制循环：

```
Coordinator
    ├── 读取/创建 spec.md
    ├── 调度 Builder/Generator
    │     └── Builder 执行 → 写 report → 更新 progress
    ├── 调度 QA/Evaluator
    │     └── QA 检查 → 写 report → 标记 pass/fail
    ├── 判断是否通过
    │     ├── PASS → 继续下一个 spec item
    │     └── FAIL → 将 QA 反馈附加到下一次 Builder 调度
    └── 循环直到完成或退出
```

### 动态退出条件

- **2 consecutive passes = ship** --- 连续两次 QA 通过，当前 spec item 完成
- **3 same failures = replan** --- 同一个问题失败 3 次，回到 Coordinator 重新规划
- **Coordinator 可手动终止** --- 判断当前路径不可行时直接终止

---

## 分类：duration x domain

选择 harness 模式时，用两个轴判断：

```
             短期（小时/天）         长期（周/月）
            ┌─────────────────────┬─────────────────────┐
  软件开发  │  software-dev       │  software-dev       │
            │  (单次 feature)     │  (多次迭代)         │
            ├─────────────────────┼─────────────────────┤
  知识管理  │  knowledge-wiki     │  knowledge-wiki     │
            │  (单次编译)         │  (持续维护)         │
            ├─────────────────────┼─────────────────────┤
  运营执行  │  operations         │  operations         │
            │  (单次 triage)      │  (持续监控)         │
            ├─────────────────────┼─────────────────────┤
  多项目    │  orchestrator       │  orchestrator       │
            │  (临时协调)         │  (常态管理)         │
            ├─────────────────────┼─────────────────────┤
  自动化    │  automation-task    │  automation-task     │
            │  (一次性脚本)       │  (定期调度)         │
            └─────────────────────┴─────────────────────┘
```

### 模式选择决策树

```
你的工作主要是…
├── 写代码 → software-dev
├── 整理/编译知识 → knowledge-wiki
├── 处理工单/事件/巡检 → operations
├── 管理多个项目 → orchestrator
├── 定时重复执行 → automation-task
└── 不确定 → 从 software-dev 开始，按需演化
```

---

## 反模式

| 反模式 | 症状 | 修正 |
|--------|------|------|
| **God Agent** | 一个 agent 包揽所有角色 | 拆分为 Coordinator + Builder + QA |
| **Spec Drift** | Builder 偏离 spec 但没人发现 | QA 的第一步是对照 spec 逐条检查 |
| **Report 篡改** | agent 修改已写入的 report | reports/ 下的文件只追加、不修改 |
| **Tool 泄露** | QA agent 有 Write 权限 → 自己改代码 | 在 agent 定义中严格限制 tools |
| **Subagent 嵌套** | Builder 自己再 spawn agent | 只有 Coordinator 有 Agent 工具 |
| **忽略 memory** | 每次 session 从零开始 | 用 experience/ 或 memory.md 做跨 session 积累 |
| **过度 Harness** | 简单任务也走完整流程 | A/B/C 三档分级，简单任务直答 |

---

## Agent 定义原则

### YAML Frontmatter

每个 agent 定义文件的头部：

```yaml
---
model: opus[1m]
tools:
  - Tool1
  - Tool2
---
```

### 工具分配指南

| 角色 | 必须有 | 必须没有 | 原因 |
|------|--------|----------|------|
| Coordinator | Agent, Read, Write, SendMessage | - | 需要调度和通信 |
| Builder | Read, Write, Edit, Bash | Agent | 不能自己派发 agent |
| QA | Read, Bash, SendMessage | Write, Edit | 不能修改被测产物 |

### Idle Discipline

agent 完成任务后应该主动停止，而不是等待新指令。实现方式：
- 在 agent 定义中明确写"完成后立即停止"
- 使用 Stop hook 作为兜底

### Permission Mode

- **默认拒绝**：只列出明确允许的工具
- **最小权限**：给 agent 恰好够用的工具，不多给
- **Bash 细粒度**：用 `Bash(command:pattern)` 限制可执行的命令

---

## 验收测试 test.md

每个 harness 必须有 `test.md`，包含：

1. **结构检查** --- agent 文件是否存在，tools 配置是否正确
2. **角色分离检查** --- Planner ≠ Generator ≠ Evaluator
3. **黑板检查** --- .harness/ 结构是否完整
4. **通信检查** --- SendMessage 路径是否可用
5. **循环检查** --- build → QA → 反馈循环是否可运行

---

## 实例化 Checklist

为新项目创建 harness 时，逐条检查：

- [ ] 确定了项目的 domain（软件/知识/运营/混合）
- [ ] 确定了 duration（一次性/持续）
- [ ] 选择了基础模式
- [ ] 创建了 `.claude/settings.json`，指定入口 agent
- [ ] 创建了 Coordinator agent，有 `Agent` 工具
- [ ] 创建了 Builder/Generator agent，**没有** `Agent` 工具
- [ ] 创建了 QA/Evaluator agent，**没有** `Write`/`Edit` 工具
- [ ] 创建了 `.harness/spec.md`（或对应的黑板入口）
- [ ] 创建了 `.harness/test.md`
- [ ] 创建了 `CLAUDE.md`，包含项目特定规则
- [ ] 运行 `test.md` 验收通过
- [ ] 所有 agent 定义使用 `model: opus[1m]`

---

## 参考

详细示例见 `references/` 目录：
- `software_harness.md` --- 软件开发模式详解
- `knowledge_harness.md` --- 知识编译模式详解
- `operations_harness.md` --- 运营模式详解
- `enforcement.md` --- 四层 enforcement 配置示例
- `agent_definitions.md` --- Agent 定义完整规范
