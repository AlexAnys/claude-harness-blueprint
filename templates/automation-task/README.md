# Automation Task 模板

> cron + agent 的标准范式。把重复性工作流封装为可调度、可审查的自动化任务。

## 适用场景

- 定时报告生成（每周质量报告、每日摘要）
- 数据管道触发（抓取 → 清洗 → 入库）
- 监控巡检（依赖更新、安全扫描、健康检查）
- 任何"每隔 N 天/周做一次"的工作

## 目录结构

```
automation-task/
├── tasks/
│   └── example-task/
│       ├── TASK.md          # 任务定义（来源/调度/目标/步骤）
│       ├── context/
│       │   ├── soul.md      # 执行态度和质量标准
│       │   ├── tools.md     # 可用工具和端点
│       │   └── memory.md    # 跨执行记忆（初始为空）
│       ├── skill/
│       │   └── SKILL.md     # 完整执行指令
│       ├── runs/            # 每次执行的产物
│       │   └── .gitkeep
│       └── review/          # 人工审查记录
│           └── .gitkeep
└── CLAUDE.md.example
```

## 安装

```bash
# 1. 复制模板
cp -r templates/automation-task/tasks ~/my-automations/tasks
cp templates/automation-task/CLAUDE.md.example ~/my-automations/CLAUDE.md

# 2. 定制任务
# 编辑 tasks/example-task/TASK.md --- 替换为你的任务定义
# 编辑 tasks/example-task/context/ --- 配置工具和标准

# 3. 手动执行测试
cd ~/my-automations
claude --agent tasks/example-task/skill/SKILL.md

# 4. 配置定时调度（可选）
# crontab -e
# 0 9 * * 1  cd ~/my-automations && claude --agent tasks/example-task/skill/SKILL.md
```

## 生命周期

```
TASK.md（定义）→ SKILL.md（执行）→ runs/（产物）→ review/（审查）→ memory.md（学习）
```

1. **定义**：TASK.md 描述任务的 what / when / why
2. **执行**：SKILL.md 是 agent 的完整指令，引用 context/ 下的文件
3. **产物**：每次执行输出到 runs/，文件名包含日期
4. **审查**：人工检查执行质量，记录到 review/
5. **学习**：审查结论反馈到 memory.md，优化后续执行
