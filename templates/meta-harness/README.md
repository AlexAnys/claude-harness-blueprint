# Meta-Harness 模板

> Harness 方法论自身的 skill 化封装。让 AI 为你的项目自动设计 harness。

## 是什么

Meta-Harness 是一个可安装的 Claude Code skill，它：

1. 分析你的项目特征（技术栈、规模、团队结构）
2. 选择合适的 harness 模式（software-dev / knowledge-wiki / operations / 混合）
3. 生成完整的 agent 定义和 harness 结构
4. 验证生成结果符合三角色分离等核心不变量

## 安装为 Claude Code Skill

```bash
# 方式一：直接引用（推荐）
# 在你的项目 CLAUDE.md 中添加：
# 参考 claude-harness-blueprint/templates/meta-harness/SKILL.md 来设计 harness

# 方式二：复制到项目
cp -r templates/meta-harness/.claude   your-project/.claude
cp -r templates/meta-harness/.harness  your-project/.harness

# 方式三：作为独立工作区
cd templates/meta-harness && claude
```

## 使用方式

启动后告诉 Coordinator 你的项目信息：

```
我有一个 [项目类型] 项目，技术栈是 [...]，
主要工作是 [...]，请帮我设计 harness。
```

Coordinator 会：
1. 提问澄清项目特征
2. 选择模式并生成 spec
3. 调度 Builder 生成 agent 定义和目录结构
4. 调度 QA 验证生成结果

## 角色

| 角色 | 职责 |
|------|------|
| Coordinator | 分析项目 → 选模式 → 调度 |
| Builder | 读 spec → 生成 agent 和结构 |
| QA | 验证生成结果 → 反馈问题 |

## 参考资料

`references/` 目录包含各类 harness 的设计参考：

- `software_harness.md` --- 软件开发 harness 示例
- `knowledge_harness.md` --- 知识编译 harness 示例
- `operations_harness.md` --- 运营 harness 示例
- `enforcement.md` --- 四层 enforcement 机制
- `agent_definitions.md` --- Agent 定义规范
