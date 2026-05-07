# 已验证的处理模式

## Pattern: WAL-corruption

- **触发条件**：Issue 提到 WAL 文件损坏、"write-ahead log"、"wal corrupted"
- **处理步骤**：
  1. 分类为 bug，优先级 P1
  2. 添加标签：`bug`, `storage-engine`, `wal`
  3. 回复模板：请求提供 `db.wal` 文件大小、最后成功写入时间、操作系统版本
  4. 指派给 storage-engine 负责人
- **验证标准**：issue 在 48 小时内得到负责人回复
- **首次发现**：2026-04-15
- **使用次数**：7

## Pattern: Replication-lag-question

- **触发条件**：Issue 提到副本延迟、"replica lag"、"replication delay"
- **处理步骤**：
  1. 分类为 question，优先级 P3
  2. 添加标签：`question`, `replication`
  3. 回复文档链接：docs/operations/replication-monitoring.md
  4. 如果延迟 > 30s，升级为 bug + P2
- **验证标准**：提问者确认问题已解决或提供了更多信息
- **首次发现**：2026-04-20
- **使用次数**：4

## Pattern: API-enhancement-request

- **触发条件**：Issue 请求新增 API 端点或修改现有 API 行为
- **处理步骤**：
  1. 分类为 feature，优先级 P3
  2. 添加标签：`enhancement`, `api`
  3. 评估复杂度：简单 → 标记 `good-first-issue`
  4. 如果涉及 breaking change → 升级为 P2，标记 `breaking-change`
- **验证标准**：分类和优先级经 Monitor 确认无误
- **首次发现**：2026-04-22
- **使用次数**：11
