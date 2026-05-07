# 方法论

本文档详解 6 种 harness 模式的角色、循环、约束和决策树。

---

## 全景图

```
                         ┌─────────────────────────────┐
                         │        用户意图              │
                         └──────────┬──────────────────┘
                                    │
                         ┌──────────▼──────────────────┐
                         │      Coordinator            │
                         │  (意图对齐 + 规划 + 调度)    │
                         └──┬───────────────────────┬──┘
                            │                       │
               ┌────────────▼────────┐   ┌─────────▼──────────┐
               │    Generator        │   │    Evaluator        │
               │  (Builder/Compiler/ │   │  (QA/Monitor/       │
               │   Executor/Worker)  │   │   Reviewer)         │
               └────────────┬────────┘   └─────────┬──────────┘
                            │                       │
                    ┌───────▼───────┐       ┌──────▼───────┐
                    │  产出物        │       │  验收报告     │
                    │  (代码/文档/   │       │  (pass/fail   │
                    │   操作结果)    │       │   + 维度评分)  │
                    └───────┬───────┘       └──────┬───────┘
                            │                       │
                         ┌──▼───────────────────────▼──┐
                         │      .harness/               │
                         │  (spec + progress + reports  │
                         │   + experience + contracts)  │
                         └─────────────────────────────┘
```

---

## 模式 1：software-dev

**用途**：Web 应用、CLI 工具、库开发 --- 任何需要 Plan → Build → QA 循环的软件项目。

### 角色表

| 角色 | Agent 文件 | 核心职责 | 关键工具 |
|------|-----------|----------|----------|
| Coordinator | `coordinator.md` | 澄清意图 → 写 spec → 调度 Builder/QA → 裁决 | Read, Write, Bash, Agent, SendMessage, TeamCreate |
| Builder | `builder.md` | 读 spec → 实现 → 全局审计 → 提交 build report | Read, Write, Edit, Bash, Glob, Grep, SendMessage |
| QA | `qa.md` | 读 spec + 代码 → 实际运行 → 维度评分 → QA report | Read, Bash, Write, Glob, Grep, SendMessage |

### 循环

```
用户需求
   │
   ▼
Coordinator: 澄清 → spec.md
   │
   ▼
Builder: 读 spec → 实现 → build report
   │
   ▼
QA: 读 spec + 代码 → 验收 → QA report
   │
   ├── PASS → Coordinator 交付 + 更新 experience
   │
   └── FAIL → Coordinator 裁决
              ├── spec 问题 → Coordinator 修改 spec → 重新循环
              └── 实现问题 → Builder 修复 → QA 重新验收
```

### 关键约束

- Builder 完成后必须执行 global audit（搜索 TODO、console.log、硬编码等）
- QA 必须实际运行产品（`npm run build`、`npm test` 等），不能只读代码
- 每轮循环产出的 report 存入 `.harness/reports/`
- Coordinator 在 3 轮 FAIL 后必须停下来与用户重新对齐

### 适用场景

- 新功能开发（greenfield）
- Bug 修复（需要理解 → 修复 → 验证循环）
- 重构（需要 spec 约束范围 + QA 验证行为不变）

### 模板路径

`templates/software-dev/`

---

## 模式 2：knowledge-wiki

**用途**：将散乱的原始材料（笔记、文章、代码注释）编译为结构化知识库。

### 角色表

| 角色 | Agent 文件 | 核心职责 | 关键工具 |
|------|-----------|----------|----------|
| Coordinator | `coordinator.md` | 路由 ingest/query/lint 请求 | Read, Write, Bash, Agent, SendMessage, TeamCreate |
| Compiler | `compiler.md` | raw → wiki 编译：提取、结构化、交叉引用 | Read, Write, Edit, Bash, Glob, Grep, SendMessage |
| QA | `qa.md` | 7 项 lint 验收 | Read, Bash, Write, Glob, Grep, SendMessage |

### 循环

```
原始材料 → raw/
   │
   ▼
Coordinator: 识别材料类型 → 分配编译任务
   │
   ▼
Compiler: 提取知识 → 结构化 → 写入 wiki/ → 更新索引
   │
   ▼
QA: 7 项 lint
   ├── 覆盖度：raw/ 中的关键概念是否都出现在 wiki/ 中
   ├── 断链：wiki 内部链接是否都指向存在的页面
   ├── 孤儿：是否有 wiki 页面不被任何其他页面引用
   ├── 格式：frontmatter 是否符合 schema 定义
   ├── 索引：index.md 是否包含所有页面
   ├── 矛盾：同一概念在不同页面的描述是否一致
   └── 过时：是否有页面引用了已删除的 raw 材料
```

### 关键约束

- Compiler 不得删除 raw/ 中的原始材料
- 每个 wiki 页面必须有标准 frontmatter（定义在 `wiki/CLAUDE.md`）
- QA 的 lint 结果写入 log.md
- 编译是幂等的：重新编译同一份 raw 材料应该得到相同结果

### 适用场景

- 团队知识库构建
- 研究笔记整理
- 文档体系建设

### 模板路径

`templates/knowledge-wiki/`

---

## 模式 3：operations

**用途**：重复性运维任务 --- issue triage、日报生成、监控告警处理。

### 角色表

| 角色 | Agent 文件 | 核心职责 | 关键工具 |
|------|-----------|----------|----------|
| Coordinator | `coordinator.md` | 事件路由 + frontier signal 检测 | Read, Write, Bash, Agent, SendMessage, TeamCreate |
| Executor | `executor.md` | 单项任务处理 | Read, Write, Edit, Bash, Glob, Grep, SendMessage |
| Monitor | `monitor.md` | 模式漂移检测 + health report | Read, Bash, Write, Glob, Grep, SendMessage |

### 循环

```
事件流（issue、告警、定时触发）
   │
   ▼
Coordinator: 分类 → 优先级 → 分配
   │
   ├── 常规事件 → Executor 处理 → 结果入 reports/
   │
   └── frontier signal（新模式/异常）→ Coordinator 标记 → 人工介入
   │
   ▼
Monitor: 定期扫描
   ├── 模式漂移：处理结果是否偏离历史基线
   ├── 积压：未处理事件是否超阈值
   └── health report → .harness/reports/
```

### 关键约束

- Coordinator 必须识别 frontier signal --- 超出已知模式的事件不自动处理
- Monitor 不持有 Edit --- 只观测和报告
- 每次处理结果写入 `progress.tsv`
- Experience layer 记录新模式，供后续 Coordinator 参考

### 适用场景

- GitHub issue triage
- 日常运维自动化
- 监控告警响应
- 定期报告生成

### 模板路径

`templates/operations/`

---

## 模式 4：orchestrator

**用途**：跨多个项目或子系统的协调，Coordinator 管理多个 Worker agent。

### 角色表

| 角色 | Agent 文件 | 核心职责 |
|------|-----------|----------|
| Coordinator | `coordinator.md` | 全局规划 + 跨项目依赖管理 + 合并决策 |
| Worker (N) | `worker.md` | 单项目/单子系统的执行 |

### 循环

```
跨项目需求
   │
   ▼
Coordinator: 拆分为子任务 → 识别依赖 → 编排执行顺序
   │
   ▼
Worker A: 子任务 1 → report
Worker B: 子任务 2 → report（依赖 A 的产出时等待）
Worker C: 子任务 3 → report
   │
   ▼
Coordinator: 合并 reports → 验证跨项目一致性
   │
   ├── 一致 → 交付
   └── 不一致 → 识别冲突 → 重新协调
```

### 关键约束

- 每个 Worker 的作用域限定在单个项目/目录
- 跨项目通信只通过 `.harness/contracts/` 中的契约文件
- Coordinator 不直接修改任何子项目的代码

### 适用场景

- Monorepo 中的跨包改动
- 多仓库同步升级
- 大规模重构的分阶段执行

### 模板路径

`templates/orchestrator/`

---

## 模式 5：automation-task

**用途**：定义可重复执行的自动化任务，配合 hooks 或手动触发。

### 角色表

| 角色 | Agent 文件 | 核心职责 |
|------|-----------|----------|
| Task Runner | `runner.md` | 按 task 定义执行 |
| Reviewer | `reviewer.md` | 验证执行结果 |

### 循环

```
触发（cron / webhook / 手动）
   │
   ▼
Runner: 读 task 定义 → 执行 → 写入 runs/
   │
   ▼
Reviewer: 读执行结果 → 验证 → 写入 review/
   │
   ├── PASS → 归档
   └── FAIL → 标记待人工处理
```

### 适用场景

- 定期数据整理
- 自动化报告生成
- 批量文件处理

### 模板路径

`templates/automation-task/`

---

## 模式 6：meta-harness

**用途**：设计和验证 harness 本身 --- 当你需要为一个新场景创建 harness 时使用。

### 角色表

| 角色 | Agent 文件 | 核心职责 |
|------|-----------|----------|
| Designer | `designer.md` | 分析场景 → 设计角色分工 → 生成 agent 定义 |
| Validator | `validator.md` | 验证生成的 harness 是否满足不变量 |

### 循环

```
新场景描述
   │
   ▼
Designer: 分析 → 选择基础模式 → 定制角色 → 生成 .claude/ + .harness/
   │
   ▼
Validator: 对照 PRINCIPLES.md 10 条不变量逐项检查
   │
   ├── 全部通过 → 交付新模板
   └── 违反 → 报告具体违反项 → Designer 修正
```

### 适用场景

- 已有模式不能满足需求，需要定制
- 组合多种模式（如 software-dev + operations）
- 为组织内部创建特定领域的 harness

### 模板路径

`templates/meta-harness/`

---

## 决策树

```
你的任务是什么？
│
├── 写代码（新功能/bug修复/重构）
│   └── → software-dev
│
├── 整理知识（笔记/文档/wiki）
│   └── → knowledge-wiki
│
├── 处理重复性事件（issue/告警/报告）
│   └── → operations
│
├── 跨多个项目协调
│   └── → orchestrator
│
├── 定义可重复的自动化任务
│   └── → automation-task
│
├── 设计新的 harness
│   └── → meta-harness
│
└── 不确定
    ├── 有代码产出？ → software-dev
    ├── 有文档产出？ → knowledge-wiki
    └── 有操作产出？ → operations
```

## 升级路径

随着项目复杂度增长，harness 可以逐步升级：

| 起点 | 升级条件 | 目标 |
|------|----------|------|
| software-dev | 需要跨多个模块协调 | software-dev + orchestrator |
| knowledge-wiki | 需要自动 ingest 新材料 | knowledge-wiki + automation-task |
| operations | 处理逻辑变复杂，需要规划 | operations + software-dev（规划部分） |
| 任意单模式 | 需要定制角色 | meta-harness 先设计，再执行 |

升级的核心原则：**叠加而非替换**。新增的模式叠加在现有模式之上，
不改变已有 agent 的职责和约束。

---

## 附录：模式对比矩阵

| 维度 | software-dev | knowledge-wiki | operations | orchestrator | automation-task | meta-harness |
|------|-------------|---------------|-----------|-------------|----------------|-------------|
| 核心循环 | Plan→Build→QA | Ingest→Compile→Lint | Route→Execute→Monitor | Plan→Dispatch→Merge | Run→Review | Design→Validate |
| Generator 角色 | Builder | Compiler | Executor | Worker | Runner | Designer |
| Evaluator 角色 | QA | QA (lint) | Monitor | Coordinator | Reviewer | Validator |
| 产出类型 | 代码 | 结构化文档 | 操作结果 | 跨项目变更 | 任务结果 | Harness 模板 |
| 状态持久化 | spec + progress + reports | wiki/ + index + log | progress + reports | contracts + reports | runs/ + review/ | .harness/ |
| 典型循环次数 | 2-5 | 1-3 | 持续 | 1-2 | 1 | 1-2 |
