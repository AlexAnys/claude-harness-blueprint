# Claude Harness Blueprint — 仓库约束

## 身份
本仓库是 Claude Code 多 agent harness 的模板库。不含可执行代码，只含 prompt 模板和配置。

## 编辑规则
- 模板文件中的 `[YOUR_PROJECT: ...]` 占位符必须保留，不可替换为具体值
- 所有 agent 定义必须使用 `model: opus[1m]`（1M context）
- 不引用任何真实项目名、人名、组织名
- 中文主体 + 关键术语保留英文（agent、harness、spec、coordinator 等）
- 不添加 Co-Authored-By 或任何 AI attribution 标记

## 文件约定
- Agent 定义：`templates/*/. claude/agents/*.md`
- Harness 产物：`templates/*/.harness/`
- 核心文档：根目录 `*.md`

## 不变量
- Planner ≠ Generator：写 spec 的 agent 不写代码
- Generator ≠ Evaluator：写代码的 agent 不跑验收
- QA/Monitor agent 不持有 Edit 工具

## 提交
- 每次改动需更新对应 test.md 的验收项
- 新模板必须包含完整的 `.claude/` + `.harness/` 结构
