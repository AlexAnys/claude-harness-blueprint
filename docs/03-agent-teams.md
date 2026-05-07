# Agent Teams ≠ Subagent Dispatch

## 关键差异

| 维度 | Agent Teams（正确） | Subagent Dispatch（错误） |
|------|---------------------|--------------------------|
| **定义位置** | `.claude/agents/*.md` + `settings.json` | Coordinator prompt 中内联指令 |
| **生命周期** | 跨会话持久 | 单次会话内 |
| **通信方式** | SendMessage（双向） | 嵌套调用（单向） |
| **工具权限** | 独立配置 | 继承父 agent |
| **审计追踪** | 各 agent 有独立日志 | 混在同一日志流 |
| **失败恢复** | 可以独立重启 | 父 agent 崩溃全部丢失 |

## 错误用法的 3 个具体症状

### 症状 1：Coordinator 的 prompt 里有代码模板

```markdown
# 错误示范
当需要写代码时，按以下模板生成：
- 先写测试文件
- 再写实现文件
- 最后运行测试
```

这不是 Coordinator —— 这是一个伪装成 Coordinator 的 Generator。
Coordinator 不应该知道"怎么写代码"，它只需要知道"找谁写代码"。

### 症状 2：所有 agent 共享同一个 tools 列表

如果 Coordinator、Generator、Evaluator 的 tools 完全一样，
说明你没有真正做角色分离 —— 任何 agent 都能做任何事。

### 症状 3：没有 SendMessage，只有 Agent

Coordinator 用 `Agent` 工具创建临时子 agent，但不用 `SendMessage` 通信。
子 agent 完成后结果直接返回给 Coordinator，没有独立的产物文件。

**后果**：子 agent 的中间思考过程全部丢失，无法审计。

## 正确用法流程

```
1. 用户发起请求
        │
        ▼
2. Coordinator 接收（settings.json 中 "agent": "coordinator"）
        │
        ▼
3. Coordinator 分析意图，写 spec → .harness/spec.md
        │
        ▼
4. Coordinator 用 SendMessage 指派 Generator
        │
        ▼
5. Generator 执行，写入代码 + 更新 progress.tsv
        │
        ▼
6. Generator 完成后 SendMessage 通知 Coordinator
        │
        ▼
7. Coordinator 用 SendMessage 调用 Evaluator
        │
        ▼
8. Evaluator 独立验收，写 report → .harness/reports/
        │
        ▼
9. Evaluator SendMessage 返回结果
        │
        ▼
10. Coordinator 向用户汇报（或循环回步骤 4）
```

## SendMessage 两种用法

### 用法 1：实时协作

Generator 执行过程中发现 spec 模糊，立刻用 SendMessage 询问 Coordinator：

```
SendMessage → coordinator:
  "spec.md 第 14 行要求'支持多语言'，是指 i18n 框架还是仅 UI 文案翻译？
   请澄清后我继续执行。"
```

Coordinator 回复后 Generator 继续。**会话不中断。**

### 用法 2：Escalation

Evaluator 发现严重问题，升级给 Coordinator：

```
SendMessage → coordinator:
  "CRITICAL: 搜索功能在空字符串输入时返回 500 错误。
   这不是 spec 中列出的 edge case，建议补充 spec 后重新执行。
   详见 .harness/reports/search-validation.md"
```

Coordinator 决定是更新 spec 还是标记为 WONTFIX。

## 文件 + 消息双层通信

| 层级 | 机制 | 用途 | 持久性 |
|------|------|------|--------|
| **消息层** | SendMessage | 实时协调、状态通知、escalation | 会话内 |
| **文件层** | .harness/ 下的文件 | spec、progress、report、经验 | 跨会话 |

**规则**：所有重要决策必须同时在文件层留记录。
SendMessage 可以丢失（会话结束），`.harness/` 中的文件不会。

## 何时仍然用 Subagent

并非所有场景都需要持久 agent。三档判断：

| 档位 | 条件 | 方式 |
|------|------|------|
| **A 档** | 一次性任务，不需要审计追踪 | Subagent / TeamCreate |
| **B 档** | 可能重复的任务，需要经验积累 | Agent Teams（推荐） |
| **C 档** | 核心流程，必须可审计可回溯 | Agent Teams（必须） |

A 档示例：临时格式化一批 Markdown 文件。
B 档示例：每次 PR 前的 lint 检查。
C 档示例：功能开发的 Plan → Build → QA 全流程。
