# Orchestrator 模板

> 跨项目协调层。当你同时管理 3 个以上项目，需要一个统一入口分发任务时使用。

## 适用场景

- 多仓库 portfolio：你有 3+ 独立项目，每个项目可能有自己的 harness
- 战略规划：需要跨项目做资源分配、优先级排序
- 统一视图：想在一个地方看到所有项目的进度和风险

## 不适用场景

- 只有一个项目 --- 直接用 software-dev / knowledge-wiki 模板
- 项目之间完全独立、不需要协调 --- 分别管理更简单

## 角色分工

| 角色 | 文件 | 职责 | 可用工具 |
|------|------|------|----------|
| **CoS** | `cos.md` | 用户唯一对话方，任务路由与调度 | Agent, SendMessage, Read, Write, Bash, TeamCreate |
| **Advisor** | `advisor.md` | 战略分析，不执行 | Read, Write, SendMessage |
| **Ops** | `ops.md` | 跨项目扫描与执行，不派发 | Read, Write, Edit, Bash, SendMessage |

## 安装

```bash
# 复制模板到你的 orchestrator 目录
cp -r templates/orchestrator/.claude   ~/orchestrator/.claude
cp -r templates/orchestrator/.harness  ~/orchestrator/.harness
cp templates/orchestrator/CLAUDE.md.example ~/orchestrator/CLAUDE.md

# 编辑 portfolio
vim ~/orchestrator/.harness/portfolio.md

# 启动
cd ~/orchestrator && claude
```

## 运营规则

1. **有 Harness 项目三档调度**：A = 信息查询直答；B = 轻量改动调用项目自身 agent；C = 重要变更走完整 Harness
2. **无 Harness 项目临时 TeamCreate**：为没有预配置的项目即时创建 agent team
3. **战略讨论调度 Advisor**：涉及跨项目优先级、资源分配时交给 Advisor 分析
4. **纯信息查询直答**：不需要修改的查询由 CoS 直接回答
5. **双层通信**：SendMessage 实时协调 + `.harness/` 审计留痕
