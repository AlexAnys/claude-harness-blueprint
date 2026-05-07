# demo-weekly-report — Automation Task Harness 示例

虚构案例：每周一自动生成代码质量趋势报告。

## 展示内容

- `tasks/weekly-report/TASK.md` — 任务定义（来源、调度、步骤、成功标准）
- `tasks/weekly-report/runs/2026-05-05.md` — 一次执行记录
- `tasks/weekly-report/review/2026-05-07.md` — task-reviewer 的审查报告

## 三角色

| 角色 | 何时运行 | 做什么 |
|------|----------|--------|
| task-planner | 一次性（任务创建时） | 定义 TASK.md + context/ + skill/ |
| task-executor | 每周一 09:00（cron） | 执行步骤，输出 runs/YYYY-MM-DD.md |
| task-reviewer | 每月一次 | 审查最近 N 次执行，提出优化建议 |

详见 `templates/automation-task/` 模板。
