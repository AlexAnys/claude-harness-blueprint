# Meta-Harness 验收清单

## 结构验证

- [ ] `.claude/settings.json` 存在，`"agent": "coordinator"`
- [ ] `.claude/agents/coordinator.md` 存在
- [ ] `.claude/agents/builder.md` 存在
- [ ] `.claude/agents/qa.md` 存在
- [ ] `SKILL.md` 存在且内容完整（约 250 行）
- [ ] `references/` 目录包含 5 个参考文件

## 角色分离

- [ ] Coordinator：有 Agent + SendMessage，没有 Bash
- [ ] Builder：有 Read + Write + Edit + Bash，没有 Agent
- [ ] QA：有 Read + Bash + SendMessage，没有 Write/Edit

## SKILL.md 内容完整性

- [ ] 包含三不变量定义
- [ ] 包含黑板模式说明
- [ ] 包含四层 enforcement
- [ ] 包含核心循环
- [ ] 包含动态退出条件（2 pass = ship, 3 fail = replan）
- [ ] 包含 duration x domain 分类矩阵
- [ ] 包含反模式列表
- [ ] 包含 agent 定义原则
- [ ] 包含实例化 checklist

## 参考文件完整性

- [ ] `references/software_harness.md` --- 软件 harness 示例
- [ ] `references/knowledge_harness.md` --- 知识 harness 示例
- [ ] `references/operations_harness.md` --- 运营 harness 示例
- [ ] `references/enforcement.md` --- 四层 enforcement 示例
- [ ] `references/agent_definitions.md` --- Agent 定义规范

## 功能验证

- [ ] Coordinator 能正确分析项目并选择模式
- [ ] Builder 能根据 spec 生成完整 harness
- [ ] QA 能验证生成结果并报告问题
- [ ] 循环能正常运行（Coordinator → Builder → QA → 反馈）
