# LLM Wiki Harness

从生产环境导出的 Knowledge Wiki Harness。基于 Karpathy 的 LLM Wiki 概念，使用 wiki-is-blackboard 模式实现知识的一次编译、持续维护。

## 架构

4 个 agent 协作的知识编译系统：

| Agent | 角色 |
|-------|------|
| **coordinator** | 主协调者，理解用户意图，路由到 compiler/qa/batch-compiler，直接处理 query |
| **compiler** | 知识编译器，读取 raw 源文件，编译成 wiki 页面，建立交叉引用 |
| **batch-compiler** | 批量编译器，处理外部文件夹/Obsidian vault 的大规模导入 |
| **qa** | 质量检查，执行断链/孤儿/矛盾/过时/覆盖/格式 6 项检查 |

## 三层架构

```
Layer 3: SCHEMA（CLAUDE.md）        <- 编译规则 + 页面格式约定
   |
Layer 2: WIKI（wiki/）              <- 编译产物（sources/concepts/entities/synthesis）
   | 编译自
Layer 1: RAW SOURCES（raw/）        <- 不可变源文件
```

## 核心模式：Wiki-is-Blackboard

- `wiki/` 目录是 agent 之间的共享黑板
- coordinator 读 index 理解全局状态，compiler 写 wiki 页面，qa 读 wiki 验证质量
- `log.md` 是 append-only 活动时间线，替代 handover 文件实现跨 session 连续性
- SessionStart hook 自动输出 wiki 统计，Stop hook 自动触发轻量 QA

## 三个核心操作

1. **Ingest**：raw 源文件 -> wiki 页面（源摘要 + 概念更新 + 实体更新 + 交叉引用）
2. **Query**：读 wiki 回答问题，有价值的答案 filed back 到 wiki/synthesis/（知识复利）
3. **Lint**：6 项健康检查（断链/孤儿/矛盾/过时/覆盖/格式）

## 快速开始

1. 将源文件放入 `raw/` 目录
2. 运行 `claude --agent coordinator`
3. 告诉 coordinator："编译 raw/ 中的新文件"
4. coordinator 会委派 compiler 执行编译，完成后自动触发 QA 检查

## 文件结构

```
llm-wiki/
├── CLAUDE.md              <- Schema（编译规则 + 格式约定）
├── .claude/
│   ├── agents/            <- 4 个 agent 定义
│   │   ├── coordinator.md
│   │   ├── compiler.md
│   │   ├── batch-compiler.md
│   │   └── qa.md
│   └── settings.json      <- Hooks（SessionStart + Stop QA）
├── raw/                   <- 放入你的源文件
├── wiki/
│   ├── index.md           <- 内容目录
│   ├── sources/           <- 源摘要页
│   ├── concepts/          <- 概念页
│   ├── entities/          <- 实体页
│   └── synthesis/         <- 综合分析页
├── log.md                 <- 活动时间线
└── scripts/
    └── export-public.sh   <- 隐私导出脚本
```
