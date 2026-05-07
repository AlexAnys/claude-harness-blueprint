# 知识编译 Harness 参考

> Wiki-is-Blackboard 模式。raw 原始素材不可变，wiki 是编译产物。

## 核心理念

知识 harness 的核心区别在于：**wiki 本身就是黑板**。
不需要额外的 `.harness/` 来跟踪进度 --- wiki 的结构就是进度。

## 角色

| 角色 | 身份 | 核心职责 |
|------|------|----------|
| Coordinator | 编辑主任 | 决定编译什么、分配给谁、审核质量 |
| Compiler | 编辑 | 从 raw 素材中提取知识，写入 wiki |
| QA | 审稿人 | 检查准确性、完整性、一致性 |

## 目录结构

```
project/
├── raw/                    # 原始素材（不可变）
│   ├── papers/             # 论文、文章
│   ├── notes/              # 笔记、摘录
│   └── transcripts/        # 会议记录、访谈
│
├── wiki/                   # 编译产物（wiki = 黑板）
│   ├── index.md            # 入口 + 全局结构
│   ├── concepts/           # 概念页
│   ├── how-to/             # 操作指南
│   └── reference/          # 参考资料
│
├── log.md                  # 编译日志（谁在什么时候编译了什么）
│
└── .claude/
    └── agents/
        ├── coordinator.md
        ├── compiler.md
        └── qa.md
```

## Raw 不可变原则

**raw/ 下的文件一旦放入，就不再修改。** 理由：

- 原始素材是"证据"，编译产物是"结论"
- 如果结论有误，需要回溯到原始证据
- 修改原始素材会导致编译产物的可追溯性断裂

如果需要纠正 raw 中的错误：
- 新建一个 correction 文件（不改原文件）
- 在 wiki 中引用 correction

## Filed-Back Loop

```
raw/（输入） → Compiler → wiki/（输出）
                              │
                              ├── QA 审核
                              │     ├── PASS → 标记完成
                              │     └── FAIL → 反馈给 Compiler
                              │
                              └── 使用中发现的问题
                                    └── 新建 raw/ 条目 → 触发新的编译循环
```

关键点：**wiki 使用中发现的知识缺口，以新 raw 条目的形式"回填"到输入端**，
而不是直接修改 wiki。这保持了编译流程的单向性。

## Compiler 的工作模式

1. 读取 raw/ 下的一个或多个素材
2. 提取关键知识点
3. 检查 wiki/ 中是否已有相关页面
   - 有 → 更新（追加或修订，注明来源）
   - 无 → 创建新页面
4. 更新 `wiki/index.md` 的目录结构
5. 在 `log.md` 中记录本次编译

## QA 检查维度

| 维度 | 检查内容 |
|------|----------|
| 准确性 | wiki 内容是否忠实反映 raw 素材 |
| 完整性 | raw 中的关键信息是否都已编译 |
| 一致性 | 不同页面之间是否存在矛盾 |
| 可发现性 | 通过 index.md 能否找到任意知识点 |
| 来源标注 | 每条关键信息是否注明了 raw 出处 |

## 注意事项

- Compiler 不创造新知识 --- 只从 raw 中提取和组织
- QA 不改 wiki --- 发现问题写 report，由 Coordinator 决定如何修正
- index.md 是 wiki 的"目录"，必须与实际页面保持同步
- log.md 按时间顺序记录，不修改历史条目
