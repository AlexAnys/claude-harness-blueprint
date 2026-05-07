# software-dev 模板

Plan → Build → QA 循环，适用于 Web 应用、CLI 工具、库开发等软件项目。

## 快速开始

```bash
# 复制到你的项目
cp -r .claude/   /path/to/your-project/.claude
cp -r .harness/  /path/to/your-project/.harness
cp CLAUDE.md.example /path/to/your-project/CLAUDE.md

# 定制 --- 搜索并替换所有占位符
grep -rn '\[YOUR_PROJECT' /path/to/your-project/.claude/
```

## 角色

| 角色 | 文件 | 职责 | 不可用工具 |
|------|------|------|-----------|
| Coordinator | `.claude/agents/coordinator.md` | 意图对齐 → spec → 调度 → 裁决 | Edit |
| Builder | `.claude/agents/builder.md` | 读 spec → 实现 → 全局审计 → report | Agent, TeamCreate |
| QA | `.claude/agents/qa.md` | 实际运行 → 维度评分 → report | Edit, Agent |

## 文件结构

```
.claude/
├── settings.json          # agent 配置 + hooks
└── agents/
    ├── coordinator.md     # 规划 + 调度
    ├── builder.md         # 实现
    └── qa.md              # 验收

.harness/
├── spec.md                # 需求 spec（Coordinator 写，Builder/QA 读）
├── progress.tsv           # 任务状态跟踪
├── HANDOFF.md             # 会话交接文档
├── test.md                # harness 自身验收清单
├── experience/
│   ├── patterns.md        # 有效模式记录
│   └── failures.md        # 失败记录
├── contracts/             # 跨 agent 契约
└── reports/               # build/QA 报告
```

## 使用流程

1. 在 Claude Code 中启动对话
2. Coordinator 自动接管（settings.json 中配置了默认 agent）
3. 告诉 Coordinator 你想做什么
4. Coordinator 写 spec → 调度 Builder → 调度 QA → 交付结果

## 定制指南

搜索 `[YOUR_PROJECT: ...]` 查看所有需要定制的位置：

- **coordinator.md** 中的项目特定约束
- **qa.md** 中的 QA 维度（从项目 CLAUDE.md 的 gotchas 提取）
- **CLAUDE.md.example** 作为你项目 CLAUDE.md 的起点

## 验收 harness

```
@coordinator 请按照 .harness/test.md 验收 harness 配置
```
