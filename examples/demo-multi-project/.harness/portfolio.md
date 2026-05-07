# Portfolio 视图

> CoS 维护。每周一更新。

## 活跃项目

| 项目 | 类型 | Harness | 当前状态 | 优先级 |
|------|------|---------|----------|--------|
| CloudSync API | software-dev | Coordinator → Builder → QA | v2.1 迭代中，认证模块重构 | P0 |
| ML Paper Vault | knowledge-wiki | Coordinator → Compiler → QA | 已编译 47/62 篇，覆盖率 76% | P1 |
| Support Bot | operations | Coordinator → Executor → Monitor | 稳定运行，接纳率 89% | P2 |

## 跨项目依赖

- CloudSync API 的 webhook 格式变更会影响 Support Bot 的事件解析
- ML Paper Vault 中新编译的 RAG 架构页面可能影响 CloudSync 的向量检索设计

## 本周决策记录

| 日期 | 决策 | 影响范围 | 决策人 |
|------|------|----------|--------|
| 2026-05-05 | CloudSync 认证从 JWT 切换到 OAuth2 | CloudSync + Support Bot | 用户确认 |
| 2026-05-06 | ML Paper Vault 暂停新源导入，集中修复断链 | ML Paper Vault | CoS 建议，用户同意 |

## 资源分配

- 本周重点：CloudSync API 认证重构（P0）
- ML Paper Vault 降为维护模式直到断链修复完成
- Support Bot 保持自动运行，仅监控 frontier signal
