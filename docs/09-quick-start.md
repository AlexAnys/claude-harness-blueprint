# 15 分钟 First Harness

## 前置条件

- [x] Claude Code 已安装且可正常使用
- [x] 你有一个现有项目（或空目录）想要添加 Harness
- [x] 已 clone 本仓库（`claude-harness-blueprint`）

## 第一步：选模板

根据你的项目类型，选择对应模板：

```
你的项目主要是...
│
├── 写代码？（Web App / CLI / 库）
│   └── → software-dev
│
├── 编译知识？（Wiki / 文档库 / 研究笔记）
│   └── → knowledge-wiki
│
├── 运维操作？（Issue triage / 日常巡检）
│   └── → operations
│
├── 协调多个子项目？
│   └── → orchestrator
│
├── 定时/触发式自动化？
│   └── → automation-task
│
└── 设计 Harness 本身？
    └── → meta-harness
```

**不确定？从 `software-dev` 开始。** 它是最通用的模板。

## 第二步：复制到项目

```bash
# 方式 A：使用 init 脚本（推荐）
./scripts/init-harness.sh software-dev /path/to/your-project

# 方式 B：手动复制
cp -r templates/software-dev/.claude  /path/to/your-project/.claude
cp -r templates/software-dev/.harness /path/to/your-project/.harness
```

如果项目已有 `.claude/settings.json`，init 脚本会跳过并提示你手动 merge。

## 第三步：定制 Agent

这是最重要的一步。模板中的 agent 是通用的，你需要加入项目特定的约束。

### 3.1 从 CLAUDE.md 提取 gotchas

打开你项目的 CLAUDE.md，找出所有约束和易错点：

```bash
grep -n '不要\|禁止\|必须\|注意\|WARNING\|IMPORTANT' CLAUDE.md
```

### 3.2 写进 QA 维度

把这些约束转化为 QA agent 的验收维度。例如：

CLAUDE.md 中写着：
> "所有 API 响应必须使用 camelCase"

QA agent 添加：
```markdown
## 项目特定检查
- [ ] API 响应字段命名：grep 检查所有 response 对象的 key 是否 camelCase
```

### 3.3 搜索占位符

```bash
grep -rn '\[YOUR_PROJECT' .claude/agents/
```

替换所有 `[YOUR_PROJECT: ...]` 占位符为项目实际值。

## 第四步：验证配置

```bash
# 使用验证脚本
./scripts/verify-harness.sh /path/to/your-project
```

验证脚本检查：
- `.claude/settings.json` 存在且包含 `"agent"` 字段
- `.claude/agents/` 下至少有 2 个 agent 定义
- 所有 agent 包含 `model: opus[1m]`
- QA agent 不包含 Edit 工具
- `.harness/` 结构完整

全部 PASS 后进入下一步。

## 第五步：第一个真实任务

```bash
cd /path/to/your-project
claude
```

在 Claude Code 中输入一个任务，例如：

```
添加一个用户搜索功能，支持按姓名和邮箱搜索，结果分页显示。
```

观察 Harness 的运行：

1. **Coordinator 接收** → 分析意图，写 spec 到 `.harness/spec.md`
2. **Coordinator 调度 Builder** → Builder 按 spec 写代码
3. **Builder 完成** → 更新 `.harness/progress.tsv`
4. **Coordinator 调度 QA** → QA 独立验收
5. **QA 产出 report** → `.harness/reports/` 中的验收报告

如果 QA 发现问题，Coordinator 会调度 Builder 修复，然后再次 QA。

## 常见问题

### Q: Coordinator 没有调度其他 agent，自己在写代码

检查 `settings.json` 中 `"agent"` 是否指向 coordinator。
检查 coordinator 的 prompt 中是否有 Edit 工具 —— 如果有，移除。

### Q: QA agent 直接修复了 bug

检查 QA agent 的 tools 列表是否包含 Edit 或 Write —— 移除它们。

### Q: Agent 使用了错误的 model

```bash
grep -rn 'model:' .claude/agents/
```

所有 agent 必须使用 `model: opus[1m]`。

### Q: .harness/ 下没有产生任何文件

检查 agent prompt 中是否有写入 `.harness/` 的指令。
模板中的 agent 默认会写入，但如果你修改了 prompt 可能不小心删掉了。

### Q: 简单任务也走完整流程，太慢了

这是正常的。Harness 设计给复杂任务使用。
对于 10 分钟能完成的小任务，直接用 Claude Code 的默认模式更高效。

### Q: 我已经有 .claude/settings.json，怎么 merge？

手动添加以下字段到你的 settings.json：

```json
{
  "agent": "coordinator",
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "command": "echo '[STOP] Agent stopped. Check .harness/reports/ for audit trail.'"
      }
    ]
  }
}
```

保留你原有的 `permissions` 配置不变。
