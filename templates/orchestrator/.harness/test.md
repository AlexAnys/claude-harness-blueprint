# Orchestrator Harness 验收清单

## 结构验证

- [ ] `.claude/settings.json` 中 `"agent": "cos"` 已配置
- [ ] `.claude/agents/cos.md` 存在且包含五大运营规则
- [ ] `.claude/agents/advisor.md` 存在且**没有 Bash** 工具
- [ ] `.claude/agents/ops.md` 存在且**没有 Agent** 工具
- [ ] `.harness/portfolio.md` 已填入实际项目数据
- [ ] `.harness/contracts/` 目录存在
- [ ] `.harness/reports/` 目录存在

## 角色分离验证

- [ ] CoS 不直接写代码或改文档（只调度）
- [ ] Advisor 只读写文件和通信（不执行命令）
- [ ] Ops 只执行操作（不派发 agent）

## 通信验证

- [ ] CoS → Advisor 的 SendMessage 路径可用
- [ ] CoS → Ops 的 SendMessage 路径可用
- [ ] Advisor/Ops → CoS 的 SendMessage 回报路径可用

## 运营规则验证

- [ ] A 档查询：CoS 能直接读取 `.harness/` 并回答
- [ ] B 档改动：CoS 能正确调用项目自身 agent
- [ ] C 档变更：CoS 能启动完整 Harness 循环
- [ ] 战略问题：CoS 能正确路由到 Advisor
- [ ] 审计留痕：每次操作后 `.harness/reports/` 有记录
