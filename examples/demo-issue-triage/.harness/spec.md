# Issue Triage Pipeline 定义

## 目标

自动分流 CloudDB 项目的 GitHub Issues，包括：
- 分类（bug / feature / question / docs）
- 优先级标注（P0-P3）
- 标签分配
- 必要时请求补充信息

## Pipeline 流程

```
新 Issue 到达
    │
    ▼
Coordinator 扫描（基于 frontier）
    │
    ├── 读取 issue 标题 + 正文
    ├── 匹配 experience/patterns.md
    │     ├── 有匹配 → 附加 pattern 给 Executor
    │     └── 无匹配 → 标记为"新模式"
    └── 分配给 Executor
         │
         ▼
    Executor 处理
    ├── 分类 + 标注优先级
    ├── 添加标签
    ├── 如需更多信息 → 添加评论
    └── 写处理报告
         │
         ▼
    Monitor 检查
    ├── 分类是否准确
    ├── 优先级是否合理
    ├── 是否可抽象为新 pattern
    └── 更新 frontier
```

## 分类规则

| 类型 | 特征 |
|------|------|
| bug | 包含错误信息、堆栈跟踪、"不工作"、"崩溃" |
| feature | "希望能"、"建议"、"是否可以" |
| question | "如何"、"怎么"、"是否支持" |
| docs | "文档"、"README"、"示例"、"教程" |

## 优先级规则

| 级别 | 条件 |
|------|------|
| P0 | 数据丢失、安全漏洞、生产环境崩溃 |
| P1 | 核心功能不可用、严重性能退化 |
| P2 | 非核心功能问题、有 workaround |
| P3 | 改善建议、美观问题、文档修正 |

## Frontier

```
last_processed: 2026-05-06T18:00:00Z
last_issue_number: 347
```
