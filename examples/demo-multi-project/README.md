# demo-multi-project — Orchestrator Harness 示例

虚构案例：一个开发者同时管理 3 个项目（CloudSync API、ML Paper Vault、Support Bot），使用 Orchestrator Harness 进行跨项目协调。

## 展示内容

- `.harness/portfolio.md` — 项目组合视图，包含状态、优先级、跨项目依赖、本周决策

## 使用方式

Orchestrator Harness 的 CoS（Chief of Staff）维护 portfolio 视图，每周更新一次。用户与 CoS 对话时，CoS 根据 portfolio 判断请求应路由到哪个项目的 Harness。

详见 `templates/orchestrator/` 模板。
