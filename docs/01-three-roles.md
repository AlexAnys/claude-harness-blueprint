# 三角色分离深度解释

## 一句话总结

**写 spec 的 agent 不写代码，写代码的 agent 不跑验收。**

## 为什么不能合并

### Planner ≠ Generator

当同一个 agent 既写 spec 又写代码，它会不自觉地让 spec 迁就实现。
遇到难以实现的需求，spec 会悄悄被降级 —— 你甚至不会注意到。

虚构案例：一个 Dashboard App 项目，spec 要求"用户搜索结果实时高亮"。
合并角色的 agent 发现实时高亮需要 debounce + virtual scroll，
于是把 spec 改成了"用户点击搜索按钮后高亮"。需求被无声降级。

### Generator ≠ Evaluator

自己检查自己写的代码，存在系统性偏差 —— **确认偏误。**

合并角色的 agent 会说"所有功能已实现"，因为它记得自己写了什么。
独立 Evaluator 不知道实现细节，只看 spec 的每条要求是否可验证。

## 三角色职责矩阵

| 维度 | Coordinator (Planner) | Generator (Builder) | Evaluator (QA) |
|------|----------------------|--------------------|--------------------|
| **核心产出** | spec.md | 代码/文档 | report.md |
| **可用工具** | Read, Write, SendMessage | Read, Write, Edit, Bash | Read, Bash, SendMessage |
| **不能做** | Edit 代码 | 修改 spec | Edit 任何文件 |
| **决策权** | 任务分解、优先级 | 实现方案 | 通过/失败判定 |

## Coordinator 4 职能

1. **意图翻译**：把用户自然语言转化为结构化 spec
2. **任务分解**：大任务拆成可验收的小步骤
3. **路由调度**：决定哪些步骤给 Generator，何时调用 Evaluator
4. **冲突仲裁**：当 Generator 和 Evaluator 意见不合时做最终判断

## Generator 4 职能

1. **按 spec 执行**：严格按照 spec 中的要求写代码/文档
2. **全局审计**：每次改动后检查相关文件是否有连锁影响
3. **产物记录**：把改动摘要写入 `.harness/progress.tsv`
4. **主动上报**：遇到 spec 模糊或矛盾时通过 SendMessage 请求 Coordinator 澄清

## Evaluator 4 职能

1. **独立验收**：基于 spec（不是代码）逐条检查功能
2. **环境验证**：在真实环境中测试（不只是看代码）
3. **结构化报告**：输出 PASS/FAIL + 证据 + 复现步骤
4. **回归检查**：确保新改动没有破坏已有功能

## 为什么 Evaluator 不能有 Edit

虚构场景：一个 TaskFlow App 项目中，QA agent 发现搜索功能的
分页参数传错了。如果 QA 有 Edit 权限，它会直接修复这个 bug。

问题来了 —— **谁来验收 QA 的修复？**

QA 既是检察官又是修理工，修复后自己说"通过了"。
这时你失去了独立验证，回到了单 agent 的自评偏差问题。

**规则：Evaluator 发现问题只能写 report，由 Coordinator 调度 Generator 修复。**

## 当 Generator 与 Evaluator 意见不合

常见场景：Generator 说"这是设计如此"，Evaluator 说"spec 要求不是这样"。

处理流程：

```
1. Evaluator 在 report 中标记 DISPUTED + 双方理由
2. Coordinator 读取 report + spec 原文
3. Coordinator 做出裁决：
   a. spec 确实模糊 → 更新 spec，Generator 重新执行
   b. Generator 理解错误 → Generator 重新执行
   c. Evaluator 标准过严 → 标记为 WONTFIX，记录 rationale
4. 裁决写入 .harness/reports/，成为后续参考
```

关键：**裁决权在 Coordinator，不在争议双方。**
