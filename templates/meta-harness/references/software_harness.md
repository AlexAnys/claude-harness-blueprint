# 软件开发 Harness 参考

> Planner → Builder → QA 模式，适用于任何代码项目。

## 角色

| 角色 | 身份 | 核心职责 |
|------|------|----------|
| Coordinator | 项目经理 | 拆解需求为 spec，调度 Builder 和 QA |
| Builder | 工程师 | 按 spec 写代码，不偏离 |
| QA | 测试工程师 | 对照 spec 验收，不改代码 |

## 黑板布局

```
.harness/
├── spec.md              # Coordinator 写，Builder 读
│   格式：
│   ## Feature: [名称]
│   ### 需求
│   ### 技术方案
│   ### 验收标准（逐条可勾选）
│   ### 边界条件
│
├── progress.tsv         # 自动更新
│   格式：task_id \t status \t agent \t timestamp \t notes
│   示例：auth-01 \t building \t builder \t 2026-05-07T10:30 \t 实现登录 API
│
├── HANDOFF.md           # 控制权交接
│   格式：
│   ## 当前持有者：[agent]
│   ## 上下文：[做了什么，下一步是什么]
│   ## 待处理问题：[如有]
│
├── test.md              # harness 自身的验收清单
├── reports/
│   ├── build_xxx_r1.md  # Builder 第 1 轮报告
│   └── qa_xxx_r1.md     # QA 第 1 轮报告
├── contracts/           # API 接口约定
└── experience/          # 跨 session 经验
    ├── patterns.md      # 有效的做法
    └── failures.md      # 失败的尝试
```

## 控制循环

```
Coordinator
│
├── 写 spec.md（或接收用户需求后更新）
│
├── 调度 Builder
│   │  Builder 读 spec.md
│   │  Builder 写代码
│   │  Builder 写 reports/build_xxx_rN.md
│   │  Builder 更新 progress.tsv
│   └── Builder 停止
│
├── 调度 QA
│   │  QA 读 spec.md（验收标准）
│   │  QA 读 reports/build_xxx_rN.md
│   │  QA 运行测试 / 检查代码
│   │  QA 写 reports/qa_xxx_rN.md（含维度评分）
│   └── QA 停止
│
├── Coordinator 读 QA 报告
│   ├── PASS（连续 2 次）→ 标记完成，进入下一个 spec item
│   ├── FAIL → 将 QA 反馈注入下一次 Builder 调度
│   └── 3 次同一失败 → replan（修改 spec 或拆分任务）
│
└── 所有 spec items 完成 → 输出最终报告
```

## QA 评分维度

QA 报告使用以下维度打分（每项 0-10）：

| 维度 | 含义 |
|------|------|
| 功能完整性 | 是否实现了 spec 中列出的所有需求 |
| 代码质量 | 可读性、命名、结构 |
| 测试覆盖 | 是否有对应的测试，测试是否有效 |
| 边界处理 | 错误处理、极端情况 |
| Spec 对齐 | 实现是否偏离了 spec |

## Parallel Worktrees（高级）

当有多个独立的 spec items 时，可以用 Git worktree 并行构建：

```
main/          # Coordinator 所在
├── worktree-auth/   # Builder A 处理 auth 模块
└── worktree-api/    # Builder B 处理 api 模块
```

前提：
- spec items 之间无依赖
- 每个 worktree 有独立的 Builder agent
- Coordinator 负责最终合并

## 注意事项

- Builder 报告必须包含"改了哪些文件"和"为什么这样改"
- QA 不运行 Builder 没提到的测试（避免引入新依赖）
- experience/ 在项目生命周期内持续积累，不随 spec 清空
