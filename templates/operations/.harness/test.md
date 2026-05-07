# Harness 自身验收清单

每一项都是 observable / binary / specific 的。

## 结构完整性

- [ ] `.claude/settings.json` 存在且 JSON 合法
- [ ] `.claude/agents/coordinator.md` 存在且包含 YAML frontmatter
- [ ] `.claude/agents/executor.md` 存在且包含 YAML frontmatter
- [ ] `.claude/agents/monitor.md` 存在且包含 YAML frontmatter

## 工具约束

- [ ] `coordinator.md` 的 tools 列表中**不包含** Edit
- [ ] `monitor.md` 的 tools 列表中**不包含** Edit
- [ ] `executor.md` 的 tools 列表中**包含** Edit
- [ ] 所有 agent 的 model 字段为 `opus[1m]`

## Harness 文件

- [ ] `.harness/spec.md` 存在且包含 pipeline 定义模板
- [ ] `.harness/progress.tsv` 存在且包含表头
- [ ] `.harness/HANDOFF.md` 存在
- [ ] `.harness/test.md` 存在（本文件）
- [ ] `.harness/experience/patterns.md` 存在
- [ ] `.harness/experience/failures.md` 存在
- [ ] `.harness/experience/replay.json` 存在且是合法 JSON
- [ ] `.harness/reports/` 目录存在

## 流程验证

- [ ] Coordinator 可以调用 Executor agent
- [ ] Coordinator 可以调用 Monitor agent
- [ ] Executor 可以通过 SendMessage 回报 Coordinator
- [ ] Monitor 可以通过 SendMessage 回报 Coordinator
- [ ] `spec.md` 定义了至少一种事件类型的处理模板
