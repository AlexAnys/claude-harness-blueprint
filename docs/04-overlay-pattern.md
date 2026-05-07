# 增量叠加，不替代

## 层次关系图

```
┌─────────────────────────────────────────┐
│  项目原有配置                              │
│  ├── CLAUDE.md          (项目约束)        │
│  ├── .claude/settings.json (权限/hooks)  │
│  └── 项目代码                             │
├─────────────────────────────────────────┤
│  Harness 叠加层                           │
│  ├── .claude/agents/*.md  (角色定义)      │
│  ├── .claude/settings.json (agent 路由)  │
│  └── .harness/            (中间产物)      │
└─────────────────────────────────────────┘
```

Harness 是一层 **overlay**，覆盖在你现有项目之上。
移除 overlay，项目回到叠加之前的状态，零副作用。

## 为什么不能动 CLAUDE.md

CLAUDE.md 是项目的核心约束文件。它可能包含：
- 编码规范（"所有 API 返回 camelCase"）
- 禁止操作（"不要修改 migrations/ 下的已有文件"）
- 依赖约束（"不引入新的 npm 包"）

**这些约束对 Harness 中的每个 agent 都有效。**

如果 init 脚本修改了 CLAUDE.md，你需要手动 diff 确认哪些是原有约束、
哪些是 Harness 添加的。一旦要移除 Harness，你无法干净地还原 CLAUDE.md。

**规则：init 脚本不修改已有的 CLAUDE.md。Harness 的配置全部在
`.claude/agents/` 和 `.claude/settings.json` 中。**

## 3 个 Overlay 关键原则

### 原则 1：只添加，不修改

init 脚本只创建新文件：
- `.claude/agents/coordinator.md`（新文件）
- `.claude/agents/builder.md`（新文件）
- `.claude/agents/qa.md`（新文件）
- `.harness/`（新目录）

如果文件已存在，跳过并提示用户手动处理。

### 原则 2：settings.json 是唯一冲突点

`settings.json` 可能已经存在（用户之前配置了权限）。
init 脚本不能直接覆盖，必须提示用户手动 merge。

需要 merge 的关键字段：
- `"agent"`: 设置默认 agent（Coordinator）
- `"hooks"`: 添加 Stop hook
- `"permissions"`: 添加 agent 需要的权限

### 原则 3：.harness/ 是 Harness 的私有空间

`.harness/` 目录完全属于 Harness。里面的所有文件：
- 由 agent 创建和维护
- 不混入项目代码
- 可以整体删除而不影响项目

不要把项目文档放进 `.harness/`，也不要把 `.harness/` 中的内容
引用到项目代码中。

## init 脚本行为说明

```bash
init-harness.sh <template-id> <target-dir>
```

| 目标状态 | 行为 |
|----------|------|
| `.claude/` 不存在 | 创建目录，复制 agents + settings.json |
| `.claude/` 存在，无 agents/ | 创建 agents/，跳过已有 settings.json |
| `.claude/agents/` 已有文件 | 跳过已有的 agent 文件，只创建缺失的 |
| `.harness/` 不存在 | 创建完整结构 |
| `.harness/` 已存在 | 报错，提示用户先备份 |
| `CLAUDE.md` 不存在 | 复制 example 文件 |
| `CLAUDE.md` 已存在 | 跳过，打印提示 |

## 移除 Harness 的 3 步

如果你决定不再使用 Harness：

```bash
# 1. 删除 agent 定义
rm -rf .claude/agents/

# 2. 删除 harness 产物
rm -rf .harness/

# 3. 清理 settings.json
# 手动移除 "agent" 和 Harness 相关的 hooks
# 保留你原有的 permissions 配置
```

三步之后，项目回到 Harness 之前的状态。
CLAUDE.md 从未被修改，所以不需要还原。

**这就是 overlay 的价值 —— 随时铺设，随时拆除。**
