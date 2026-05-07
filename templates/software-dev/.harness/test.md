# Harness 自身验收清单

每一项都是 observable（可观测）、binary（是/否）、specific（具体）的。
用于验证 harness 配置本身的正确性，不是验证业务代码。

## 结构完整性

- [ ] `.claude/settings.json` 存在且 JSON 合法
- [ ] `.claude/agents/coordinator.md` 存在且包含 YAML frontmatter
- [ ] `.claude/agents/builder.md` 存在且包含 YAML frontmatter
- [ ] `.claude/agents/qa.md` 存在且包含 YAML frontmatter

## 工具约束

- [ ] `coordinator.md` 的 tools 列表中**不包含** Edit
- [ ] `qa.md` 的 tools 列表中**不包含** Edit
- [ ] `builder.md` 的 tools 列表中**包含** Edit
- [ ] 所有 agent 的 model 字段为 `opus[1m]`

## Harness 文件

- [ ] `.harness/spec.md` 存在且包含模板注释
- [ ] `.harness/progress.tsv` 存在且包含表头
- [ ] `.harness/HANDOFF.md` 存在
- [ ] `.harness/test.md` 存在（本文件）
- [ ] `.harness/experience/patterns.md` 存在
- [ ] `.harness/experience/failures.md` 存在
- [ ] `.harness/contracts/` 目录存在
- [ ] `.harness/reports/` 目录存在

## 流程验证

- [ ] Coordinator 可以读取 spec.md
- [ ] Coordinator 可以调用 Builder agent
- [ ] Coordinator 可以调用 QA agent
- [ ] Builder 可以通过 SendMessage 回报 Coordinator
- [ ] QA 可以通过 SendMessage 回报 Coordinator
