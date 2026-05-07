# Harness 设计 Spec

> Coordinator 在分析用户项目后填写此文件。Builder 根据此文件生成 harness。

## 项目信息

- **名称**：[待填]
- **类型**：[软件开发 / 知识管理 / 运营执行 / 混合]
- **技术栈**：[待填]
- **规模**：[待填]

## 模式选择

- **基础模式**：[software-dev / knowledge-wiki / operations / orchestrator / automation-task]
- **选择理由**：[待填]

## 角色定义

| 角色 | Agent 文件名 | 关键工具 | 职责概述 |
|------|-------------|----------|----------|
| Coordinator | [待填] | Agent, Read, Write, SendMessage | [待填] |
| Builder | [待填] | Read, Write, Edit, Bash | [待填] |
| QA | [待填] | Read, Bash, SendMessage | [待填] |

## 定制项

- **黑板结构**：[标准 / 自定义（描述）]
- **额外 agent**：[如有]
- **特殊 hook**：[如有]
- **Enforcement 级别**：[宽松 / 标准 / 严格]

## 验收标准

- [ ] 三角色分离
- [ ] 所有 agent 使用 `model: opus[1m]`
- [ ] 黑板结构完整
- [ ] test.md 验收通过
