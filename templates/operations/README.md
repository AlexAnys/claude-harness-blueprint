# operations 模板

Route → Execute → Monitor 循环，适用于 issue triage、日常运维、监控告警处理等重复性事件流。

## 快速开始

```bash
# 复制到你的项目
cp -r .claude/   /path/to/your-project/.claude
cp -r .harness/  /path/to/your-project/.harness
cp CLAUDE.md.example /path/to/your-project/CLAUDE.md
```

## 角色

| 角色 | 文件 | 职责 | 不可用工具 |
|------|------|------|-----------|
| Coordinator | `.claude/agents/coordinator.md` | 事件路由 + frontier signal 检测 | Edit |
| Executor | `.claude/agents/executor.md` | 单项任务处理 | Agent, TeamCreate |
| Monitor | `.claude/agents/monitor.md` | 模式漂移检测 + health report | Edit, Agent |

## 工作流

```
事件流（issue / 告警 / cron）
         ↓
Coordinator: 分类 → 优先级 → 路由
         ↓
    ┌────┴────┐
    │ 常规     │ frontier signal
    ↓         ↓
Executor   Coordinator 标记 → 人工介入
    ↓
Monitor: 定期扫描 → health report
```

## 核心概念

### Frontier Signal
超出已知模式的事件。Coordinator 不自动处理，而是标记为 frontier 等待人工决策。
识别后，处理方式沉淀到 `experience/patterns.md` 供后续参考。

### 模式漂移
Monitor 检测处理结果是否偏离历史基线。例如：
- 某类 issue 的处理时间突然翻倍
- 某类告警的频率异常增加
- 处理结果的通过率下降

## 文件结构

```
.claude/
├── settings.json
└── agents/
    ├── coordinator.md     # 路由 + frontier 检测
    ├── executor.md        # 单项处理
    └── monitor.md         # 漂移检测 + health

.harness/
├── spec.md                # pipeline 定义
├── progress.tsv           # 事件处理状态
├── HANDOFF.md             # 会话交接
├── test.md                # harness 自身验收
├── experience/
│   ├── patterns.md        # 已知模式
│   └── failures.md        # 失败记录
└── reports/               # health reports
```
