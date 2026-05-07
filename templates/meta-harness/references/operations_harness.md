# 运营 Harness 参考

> 持续循环模式。不是做一次就结束，而是每天/每周重复。

## 核心理念

运营 harness 和软件/知识 harness 的关键区别：

- **没有终态** --- 不存在"做完了"，只有"本轮处理完了"
- **Experience Layer** --- 跨轮次积累经验，越做越快
- **Frontier Tracking** --- 追踪已处理/未处理的边界

## 角色

| 角色 | 身份 | 核心职责 |
|------|------|----------|
| Coordinator | 运营经理 | 扫描新工作项、分配、跟踪 |
| Executor | 执行人 | 处理具体工单/事件 |
| Monitor | 质检员 | 检查处理质量、更新经验库 |

## 持续循环

```
[新事件到达]
     │
     ▼
Coordinator 扫描
├── 分类（优先级、类型）
├── 匹配已有 pattern
│   ├── 有 → 附加 pattern 给 Executor
│   └── 无 → 标记为"新模式"
└── 调度 Executor
     │
     ▼
Executor 处理
├── 按 pattern 执行（如有）
├── 记录处理过程
└── 输出处理结果
     │
     ▼
Monitor 检查
├── 处理是否正确
├── 是否可以抽象为 pattern
│   ├── 是 → 写入 experience/patterns.md
│   └── 否 → 仅记录
└── 更新 frontier
     │
     ▼
[等待下一个事件]
```

## Experience Layer

```
.harness/experience/
├── patterns.md          # 已验证的处理模式
│   格式：
│   ## Pattern: [名称]
│   - 触发条件：[什么情况下使用]
│   - 处理步骤：[1, 2, 3...]
│   - 验证标准：[怎么判断处理正确]
│   - 首次发现：[日期]
│   - 使用次数：[N]
│
├── failures.md          # 失败记录
│   格式：
│   ## Failure: [日期] [描述]
│   - 触发场景：[...]
│   - 错误根因：[...]
│   - 修正方案：[...]
│   - 是否已纳入 pattern：[是/否]
│
└── frontier.md          # 已处理/未处理边界
    格式：
    - 最后处理时间：[timestamp]
    - 已处理范围：[描述]
    - 待处理队列：[列表]
```

## Frontier Tracking

Frontier 是运营 harness 的关键概念 --- 它标记"上次处理到哪里了"。

示例场景：GitHub Issue Triage
```
frontier:
  last_processed: 2026-05-06T18:00:00Z
  last_issue_number: 234
  pending: [235, 236, 237]
```

每次启动循环时：
1. 读取 frontier，知道从哪里继续
2. 扫描 frontier 之后的新事件
3. 处理完后更新 frontier

## Executor 的约束

- 只处理 Coordinator 分配的工作项
- 使用 experience/patterns.md 中的模式（如有匹配）
- 遇到新情况不自行决策 --- 标记后交给 Coordinator
- 每个工作项输出处理报告到 `.harness/reports/`

## Monitor 的职责

- **质量检查**：Executor 的处理是否正确
- **模式发现**：重复出现的处理方式是否可以抽象为 pattern
- **故障记录**：失败案例是否已记录到 failures.md
- **Frontier 维护**：确保 frontier 准确反映当前状态

## 注意事项

- 运营 harness 的价值随时间增长 --- experience 越丰富，处理越快
- 不要清空 experience/ --- 它是跨 session 的核心资产
- Frontier 必须持久化 --- 丢失 frontier 意味着不知道处理到哪里了
- 新模式需要 Monitor 验证后才写入 patterns.md
