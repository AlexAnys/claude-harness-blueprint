# Agent 定义规范参考

> 每个 `.claude/agents/*.md` 文件的编写规范。

## 文件结构

```markdown
---
model: opus[1m]
tools:
  - Tool1
  - Tool2
---

# 角色名称

角色描述（一句话说明这个 agent 是谁、做什么）。

## 身份

明确 agent 的定位和边界。

## 职责

具体列出这个 agent 负责什么。

## 工作方式

步骤化描述工作流程。

## 输出格式

定义输出的结构化格式。

## 约束

明确列出不能做什么。
```

---

## YAML Frontmatter

### model

```yaml
model: opus[1m]
```

使用 `opus[1m]`（1M context）。不要用 `opus`（200k）或其他较短上下文的模型。
1M context 确保 agent 能处理大型代码库和长对话。

### tools

```yaml
tools:
  - Agent        # 调度其他 agent（仅 Coordinator）
  - Read         # 读取文件
  - Write        # 创建/覆盖文件
  - Edit         # 编辑文件
  - Bash         # 执行命令
  - SendMessage  # 与其他 agent 通信
  - TeamCreate   # 创建临时 agent team（仅 Orchestrator）
```

---

## 工具分配模式

### Coordinator / Planner

```yaml
tools:
  - Agent
  - Read
  - Write
  - SendMessage
```

特点：有 Agent 权限，可以调度。有 SendMessage，可以通信。
通常没有 Bash --- Coordinator 不直接执行命令。

### Builder / Generator / Compiler

```yaml
tools:
  - Read
  - Write
  - Edit
  - Bash
```

特点：有完整的文件操作和命令执行能力。
没有 Agent --- 不能自行派发子 agent。
没有 SendMessage --- 通过文件（blackboard）通信。

### QA / Evaluator / Monitor

```yaml
tools:
  - Read
  - Bash
  - SendMessage
```

特点：**没有 Write 和 Edit** --- 不能修改被测产物。
有 Bash --- 可以运行测试。
有 SendMessage --- 可以向 Coordinator 报告结果。

### Advisor（只读分析）

```yaml
tools:
  - Read
  - Write
  - SendMessage
```

特点：**没有 Bash** --- 不能执行命令。
只做分析和建议，不做任何执行。
Write 权限仅用于写分析报告。

---

## Permission Mode 原则

### 默认拒绝

不在 `tools` 列表中的工具，agent 无法使用。这是结构性保证。

### 最小权限

给每个 agent 恰好够完成任务的工具，不多给。问自己：
- 这个 agent 需要写文件吗？不需要就不给 Write
- 这个 agent 需要运行命令吗？不需要就不给 Bash
- 这个 agent 需要调度别人吗？不需要就不给 Agent

### Bash 细粒度

在 `settings.json` 的 permissions 中进一步限制 Bash：

```json
"Bash(git:*)"         // 只允许 git 命令
"Bash(pnpm test:*)"   // 只允许测试命令
"Bash(ls:*)"          // 只允许目录浏览
```

---

## Idle Discipline

agent 完成任务后应该**立即停止**，不要等待新指令。

在 agent 定义中明确写：

```markdown
## 约束
- 完成任务后立即停止，不要等待新指令
- 不要主动寻找额外工作
- 如果发现 spec 之外的问题，记录到报告中，但不要自行处理
```

兜底机制：在 settings.json 中配置 Stop hook。

---

## 常见错误

| 错误 | 后果 | 修正 |
|------|------|------|
| QA agent 有 Write 工具 | QA 自己改代码，失去独立验证价值 | 移除 Write 和 Edit |
| Builder 有 Agent 工具 | Builder 自行派发 agent，脱离 Coordinator 控制 | 移除 Agent |
| Coordinator 有 Bash | Coordinator 直接执行而不是调度 | 通常移除 Bash |
| 使用 `model: opus` | 200k context 不够处理大型项目 | 改为 `model: opus[1m]` |
| 忘记 Idle Discipline | agent 完成后空转消耗资源 | 在约束中明确写"完成后停止" |
