# 四层 Enforcement 参考

> 从软约束到硬限制，逐层收紧 agent 行为。

## 总览

```
L1  CLAUDE.md       "你应该..."       软约束，agent 可能忽略
L2  tools 字段      "你只能用..."     结构默认，没给的工具不可用
L3  hooks           "做完后检查..."   硬拦截，Stop/PreToolUse 时执行
L4  permissions     "绝对不能..."     硬限制，直接拒绝
```

---

## L1：CLAUDE.md 规则

最灵活的一层。用自然语言描述项目约束。

```markdown
# CLAUDE.md 示例

## 规则
- 所有变更必须回溯到 .harness/spec.md
- 不要修改 reports/ 下已有的文件
- 中文交互，代码注释用英文
- 提交前运行 pnpm test
```

适合：项目级惯例、风格指南、工作流偏好。
不适合：安全关键约束（agent 可能在长会话中遗忘）。

---

## L2：Agent 定义的 tools 字段

通过 YAML frontmatter 控制 agent 可用的工具。

```yaml
# qa.md --- QA agent 没有 Write/Edit，无法修改代码
---
model: opus[1m]
tools:
  - Read
  - Bash
  - SendMessage
---
```

```yaml
# builder.md --- Builder 没有 Agent，无法自行派发
---
model: opus[1m]
tools:
  - Read
  - Write
  - Edit
  - Bash
---
```

```yaml
# coordinator.md --- Coordinator 有 Agent，可以调度
---
model: opus[1m]
tools:
  - Agent
  - Read
  - Write
  - SendMessage
---
```

适合：角色分离的核心保证。
关键：QA 没 Write → 不能改代码；Builder 没 Agent → 不能自行调度。

---

## L3：Hooks（settings.json）

在特定生命周期事件时执行检查。

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "command": "bash -c 'if [ -n \"$(git status --porcelain)\" ]; then echo \"WARNING: Uncommitted changes detected\"; fi'"
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write",
        "command": "bash -c 'echo \"Write operation detected: $TOOL_INPUT\" >> .harness/audit.log'"
      },
      {
        "matcher": "Bash",
        "command": "bash -c 'if echo \"$TOOL_INPUT\" | grep -q \"rm -rf\"; then echo \"BLOCKED: destructive command\" >&2; exit 1; fi'"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "command": "bash -c 'echo \"[$(date)] Bash executed\" >> .harness/audit.log'"
      }
    ]
  }
}
```

Hook 类型：
- **Stop**：agent 停止时执行（清理检查）
- **PreToolUse**：工具调用前执行（拦截危险操作）
- **PostToolUse**：工具调用后执行（审计记录）

适合：审计、安全拦截、自动化检查。

---

## L4：Permissions 白名单

最严格的一层。只有明确列出的工具/命令才可用。

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Write",
      "Edit",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(pnpm test:*)",
      "Bash(pnpm lint:*)",
      "SendMessage"
    ]
  }
}
```

Bash 细粒度控制：
- `Bash(ls:*)` --- 只允许 ls 命令
- `Bash(git:*)` --- 允许所有 git 命令
- `Bash(pnpm test:*)` --- 只允许 pnpm test

适合：生产环境、安全敏感项目。
注意：过度限制会让 agent 无法完成工作，需要平衡。

---

## 推荐组合

### 开发环境（宽松）

```
L1: CLAUDE.md 基础规则
L2: 角色 tools 分离
L3: Stop hook 做清理检查
L4: 不设 permissions（或极宽松）
```

### 生产环境（严格）

```
L1: CLAUDE.md 详细规则
L2: 角色 tools 严格分离
L3: PreToolUse hook 拦截危险命令 + 审计日志
L4: permissions 白名单，只放必要命令
```
