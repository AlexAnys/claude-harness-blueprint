# knowledge-wiki 模板

Ingest → Compile → Lint 循环，适用于知识库编译与维护。

## 快速开始

```bash
# 复制到你的项目
cp -r .claude/   /path/to/your-wiki/.claude
cp -r wiki/      /path/to/your-wiki/wiki
cp -r raw/       /path/to/your-wiki/raw
cp log.md        /path/to/your-wiki/log.md
cp CLAUDE.md.example /path/to/your-wiki/CLAUDE.md
```

## 角色

| 角色 | 文件 | 职责 | 不可用工具 |
|------|------|------|-----------|
| Coordinator | `.claude/agents/coordinator.md` | 路由 ingest/query/lint 请求 | Edit |
| Compiler | `.claude/agents/compiler.md` | raw → wiki 编译 | Agent, TeamCreate |
| QA | `.claude/agents/qa.md` | 7 项 lint 验收 | Edit, Agent |

## 工作流

```
原始材料 → raw/
         ↓
Coordinator: 识别类型 → 分配编译
         ↓
Compiler: 提取 → 结构化 → 写入 wiki/ → 更新 index
         ↓
QA: 7 项 lint（覆盖/断链/孤儿/格式/索引/矛盾/过时）
```

## 目录结构

```
.claude/
├── settings.json
└── agents/
    ├── coordinator.md
    ├── compiler.md
    └── qa.md

wiki/
├── CLAUDE.md              # Wiki Schema 定义（frontmatter 格式约束）
├── index.md               # 知识库索引
└── (编译后的 wiki 页面)

raw/                       # 原始材料存放处
log.md                     # 编译和 lint 日志
CLAUDE.md.example          # 项目 CLAUDE.md 示例
```

## 三种请求类型

1. **Ingest**：有新的原始材料需要编译进 wiki
2. **Query**：需要从 wiki 中查找信息
3. **Lint**：需要检查 wiki 的健康状态

Coordinator 根据请求类型路由到对应处理流程。
