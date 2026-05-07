# 不变量与反模式

本文档定义了 Harness 设计的 10 条不变量和 5 个反模式。
不变量是硬约束 --- 违反任何一条，harness 就退化为"一个 agent 假装是三个"。

---

## 不变量

### 1. Planner ≠ Generator

**陈述**：负责规划（写 spec、定义需求）的 agent 不得执行实现（写代码、编译文档）。

**原因**：人类工程中，架构师自己写代码时会不自觉地让设计迁就实现。
AI agent 也一样 --- 如果 planner 持有 Edit 工具，它会在规划阶段就"顺手"实现，
跳过 spec 审查环节，导致 spec 变成事后文档而非事前契约。

**实践**：
- Coordinator/Planner 的 tools 列表中**不包含 Edit**
- Spec 文件由 Planner 写入 `.harness/spec.md`，Generator 只读取不修改
- 如果 Generator 发现 spec 不可行，通过 `SendMessage` 回报 Coordinator 修改，而非自行改 spec

---

### 2. Generator ≠ Evaluator

**陈述**：执行实现的 agent 不得执行验收。

**原因**：这是人类代码审查存在的根本原因 --- 作者对自己的代码有盲区。
AI agent 的自评偏差更严重：它倾向于认为自己刚写的代码满足了需求，
即使存在边界条件遗漏或逻辑错误。

**实践**：
- Builder/Generator 提交 build report 后，由独立的 QA agent 验收
- QA agent 不持有 Edit 工具 --- 它只能报告问题，不能"顺手修"
- 验收基于 `.harness/test.md` 中的可观测、二元、具体的检查项

---

### 3. Coordinator = Planner（默认合并）

**陈述**：在大多数场景中，Coordinator 和 Planner 是同一个 agent。

**原因**：分离 Coordinator 和 Planner 会增加一轮通信开销，
但在典型项目中，"澄清意图 → 写 spec"是一个连贯的思维过程，拆开反而割裂。
只有当规划本身非常复杂（如跨多个子系统的架构设计）时，才值得独立 Planner。

**实践**：
- 默认使用 `coordinator.md` 同时承担规划和调度职责
- Coordinator 在 spec 完成后切换为调度模式，不再修改 spec
- 需要独立 Planner 时，从 Coordinator 中拆出 `planner.md`

---

### 4. Agent Teams ≠ Subagent

**陈述**：使用 Claude Code 原生 Agent Teams（`agents/*.md`），不使用 subagent 嵌套。

**原因**：Subagent（在 agent 内部再调用 agent）会导致：
- 上下文在嵌套层之间丢失
- 调试时无法看到中间状态
- Token 消耗成倍增长

Agent Teams 是平级的：每个 agent 有独立的 context、独立的 tools、
通过文件和 SendMessage 通信。Coordinator 通过 Agent tool 调度它们，
而非在自己内部嵌套子 agent。

**实践**：
- 每个 agent 是 `.claude/agents/` 下的独立 `.md` 文件
- Agent 间通信通过 `.harness/` 下的文件（spec、report、progress）
- 实时协调通过 `SendMessage`
- 不在 agent prompt 中嵌套 agent 调用

---

### 5. Coordinator 对齐意图

**陈述**：Coordinator 的首要职责是确保团队行动与用户意图一致。

**原因**：没有意图对齐，Generator 会按字面意思执行，
Evaluator 会按字面标准验收 --- 但字面正确不等于意图正确。
Coordinator 是唯一同时持有"用户说了什么"和"团队在做什么"两个视角的角色。

**实践**：
- Coordinator 在分配任务前，先与用户确认 spec 的关键决策点
- 每轮循环后，Coordinator 检查 build report 是否偏离原始意图
- 遇到歧义时，Coordinator 向用户提问，而非自行假设

---

### 6. 工具限制 = 流程强制

**陈述**：通过限制 agent 的 tools 来强制执行分工，而非依赖 prompt 约束。

**原因**：Prompt 约束是"软性"的 --- agent 在长会话中可能忘记或绕过。
Tools 限制是"硬性"的 --- 没有 Edit 工具就物理上无法修改文件。

**实践**：
- QA agent：无 Edit（不能修代码，只能报告）
- Coordinator：无 Edit（不能写业务代码，只能写 spec 和调度）
- Builder：完整工具集（Read, Write, Edit, Bash, Glob, Grep, SendMessage）
- 每个 agent 的 tools 在 YAML frontmatter 中显式声明

---

### 7. Overlay 不替代

**陈述**：Harness 模板是 overlay（叠加层），不替代项目原有的 CLAUDE.md 和工具链。

**原因**：每个项目都有自己的构建系统、测试框架、CI/CD、代码规范。
Harness 不应该要求项目改变这些 --- 它只在项目之上叠加多 agent 协作结构。

**实践**：
- `.claude/agents/*.md` 叠加到项目的 `.claude/` 目录
- `.harness/` 是独立目录，不与项目源码混合
- `CLAUDE.md.example` 提供示例，用户按自己项目定制
- 模板中的 `[YOUR_PROJECT: ...]` 标记指出需要定制的位置

---

### 8. 文件 = 审计 + 通信

**陈述**：Agent 间的通信和决策必须通过文件持久化。

**原因**：
- **审计**：事后可以回溯"为什么做了这个决策"
- **通信**：文件是 agent 间最可靠的通信通道，不受 context window 限制
- **恢复**：会话中断后，新会话可以从文件恢复上下文

**实践**：
- `spec.md` --- 需求契约
- `progress.tsv` --- 任务状态跟踪
- `HANDOFF.md` --- 会话间交接文档
- `reports/` --- 每轮 build/QA 报告
- `experience/` --- 跨会话的模式和失败记录

---

### 9. Experience Layer 反馈环

**陈述**：每次 harness 运行的经验（成功模式、失败教训）必须沉淀到 experience 文件。

**原因**：没有反馈环，同样的错误会在不同会话中重复。
Experience layer 让后续会话可以学习前序会话的教训，实现跨会话改进。

**实践**：
- `experience/patterns.md` --- 记录有效的操作模式
- `experience/failures.md` --- 记录失败及其根因
- Coordinator 在每轮循环开始时读取 experience 文件
- QA 在验收后更新 experience 文件

---

### 10. test.md 验收 Harness 自身

**陈述**：每个模板都包含 `test.md`，用于验收 harness 配置本身（不是验收业务代码）。

**原因**：Harness 配置也可能出错 --- agent 定义不完整、工具权限错配、
文件路径不存在。`test.md` 在 harness 投入使用前，先验证 harness 自身的正确性。

**实践**：
- `test.md` 中的每一项都是 observable（可观测）、binary（是/否）、specific（具体）的
- 示例："coordinator.md 的 tools 列表中不包含 Edit" --- 可观测、二元、具体
- 反例："harness 工作正常" --- 不可观测、不二元、不具体

---

## 反模式

### 反模式 1：Subagent 顶替 Agent Team

**症状**：在 Coordinator 的 prompt 中写"调用 builder 子任务"，
而非使用独立的 `builder.md` agent。

**危害**：
- Builder 的 context 嵌套在 Coordinator 的 context 中，无法独立审计
- Token 消耗翻倍
- Builder 出错时 Coordinator 的 context 也被污染

**修正**：使用 `.claude/agents/builder.md` 定义独立 agent，
Coordinator 通过 Agent tool 调度。

---

### 反模式 2：Evaluator 持有 Edit

**症状**：QA agent 发现问题后"顺手修了"。

**危害**：
- 破坏 Generator ≠ Evaluator 不变量
- QA 的修改未经 QA 验收（谁来验收 QA 的修改？）
- 审计链断裂：无法区分"Builder 写的"和"QA 改的"

**修正**：QA agent 的 tools 中移除 Edit。发现问题时写入报告，
由 Coordinator 决定是否让 Builder 修复。

---

### 反模式 3：Coordinator 直接动手

**症状**：Coordinator 在调度过程中"顺便"写了几行代码或改了配置。

**危害**：
- 破坏 Planner ≠ Generator 不变量
- Coordinator 的改动不在 Builder 的 build report 中，审计链断裂
- Coordinator 的 context 被实现细节污染，影响后续调度决策

**修正**：Coordinator 的 tools 中不包含 Edit。需要改动时，
创建任务分配给 Builder。

---

### 反模式 4：Harness 做成代码框架

**症状**：harness 需要 `npm install`、有 runtime、有 API 层。

**危害**：
- 增加依赖 = 增加维护成本
- 与项目自身的技术栈冲突
- 用户需要学习框架 API，而非专注于 prompt 设计

**修正**：Harness 是纯文件模板 --- `.md` 文件 + `.json` 配置。
不需要安装，不需要编译，不需要 runtime。

---

### 反模式 5：行数规则强制 ceremony

**症状**：要求 spec 必须 300 行以上，build report 必须覆盖 20 个维度。

**危害**：
- 把 harness 变成官僚流程
- Agent 会生成冗余内容来满足行数要求
- 实际有用信息被稀释

**修正**：spec 和 report 的要求是"完整"而非"冗长"。
一个简单任务的 spec 可能只有 10 行，这完全正常。

---

## 速查表

| 角色 | 可用工具 | 不可用工具 | 产出 |
|------|----------|------------|------|
| Coordinator | Read, Write, Bash, Agent, SendMessage, TeamCreate | **Edit** | spec.md, 调度决策 |
| Builder/Generator | Read, Write, Edit, Bash, Glob, Grep, SendMessage | Agent, TeamCreate | 代码, build report |
| QA/Evaluator | Read, Bash, Write, Glob, Grep, SendMessage | **Edit**, Agent | QA report, 验收结果 |
| Monitor | Read, Bash, Write, Glob, Grep, SendMessage | **Edit**, Agent | health report |

| 文件 | 写入者 | 读取者 | 用途 |
|------|--------|--------|------|
| spec.md | Coordinator | Builder, QA | 需求契约 |
| progress.tsv | Builder, Coordinator | 所有 | 状态跟踪 |
| build report | Builder | QA, Coordinator | 实现报告 |
| QA report | QA | Coordinator | 验收结果 |
| HANDOFF.md | Coordinator | 下一会话 | 会话交接 |
| experience/ | QA, Coordinator | Coordinator | 跨会话经验 |
