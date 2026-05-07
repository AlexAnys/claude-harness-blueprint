# Coordinator = Planner 默认合并

## 为什么默认合并

多 agent 系统的第一原则是**最小化角色数量**。每多一个角色就多一层通信开销。

在大多数项目中，Coordinator（调度谁做什么）和 Planner（想清楚做什么）
的信息需求完全重叠 —— 都需要理解用户意图、项目上下文、技术约束。
把它们拆成两个 agent 意味着 Planner 写完 spec 后要把所有上下文传给 Coordinator，
这纯粹是开销，没有收益。

**默认规则：Coordinator 兼任 Planner，一个 agent 同时负责意图翻译和任务调度。**

## 何时该拆

出现以下 3 个信号中的任意 2 个，考虑拆分：

### 信号 1：Spec 编写本身需要深度研究

当生成一份 spec 需要读 30+ 个文件、做技术调研、对比方案时，
Coordinator 的 context 会被 spec 编写过程填满，影响后续调度质量。

例：一个编译器项目，spec 需要分析目标语言的 AST 结构，
这个过程本身就是一项复杂任务。

### 信号 2：Spec 需要多轮和用户交互

当 spec 需要反复和用户确认需求细节（"你说的优化是指性能还是可维护性？"），
这些交互会打断 Coordinator 的调度节奏。

### 信号 3：一个会话内有多个不相关的 spec 任务

当 Coordinator 需要同时管理 3 个不相关模块的 spec 编写，
合并角色会导致 context 混乱。

## 拆分后的接口图

```
用户
 │
 ▼
[Coordinator]  ─── SendMessage ──→  [Planner]
 │                                      │
 │  ← spec.md 写入 .harness/ ──────────┘
 │
 ├── SendMessage ──→  [Generator]
 │                        │
 │  ← progress.tsv ──────┘
 │
 └── SendMessage ──→  [Evaluator]
                          │
    ← report.md ─────────┘
```

**通信协议**：
- Coordinator → Planner：自然语言任务描述
- Planner → Coordinator：`spec.md` 写入 `.harness/`（文件通信）
- Coordinator 读取 spec 后调度 Generator

## 常见误用

### 误用 1：拆分后 Coordinator 仍然写 spec

拆分了但 Coordinator 的 prompt 里还保留着 spec 编写指令。
结果两个 agent 都在写 spec，产出冲突。

**修复**：Coordinator prompt 中明确写"你不生成 spec，你调度 Planner 生成"。

### 误用 2：Planner 直接调度 Generator

拆分后 Planner 越权，直接用 SendMessage 指挥 Generator。
Coordinator 失去全局视野。

**修复**：Planner 的 tools 列表中不包含 Agent 和 TeamCreate。

### 误用 3：不需要拆分时强行拆分

三个人的项目硬要设五个角色。每次改一行配置都要走完整流程。
**Harness 的目标是减少 overhead，不是增加 ceremony。**

## 拆分 Checklist

准备拆分 Coordinator 和 Planner 时，逐条确认：

- [ ] 至少满足上述 3 个信号中的 2 个
- [ ] 新 Planner agent 的 tools 列表不含 Agent / TeamCreate
- [ ] Coordinator prompt 中移除所有 spec 编写指令
- [ ] Planner 产出路径明确（写入 `.harness/spec.md`）
- [ ] Coordinator 知道去哪里读 Planner 的产出
- [ ] 测试：给 Coordinator 一个需要 spec 的任务，确认它调度 Planner 而非自己写
