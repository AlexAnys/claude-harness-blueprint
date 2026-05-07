# 反模式实战

以下 8 个反模式均来自生产经验，用虚构案例说明。

---

## 反模式 1：Coordinator 直接动手

**场景**：Dashboard App 项目中，Coordinator 需要修改 `agentConfig.ts` 中的
路由配置。它没有调度 Builder，而是直接用 Edit 工具改了文件。

**后果**：`agentConfig.ts` 改好了，但同样引用该配置的 5 个组件文件
没有更新。Builder 的 prompt 中有"全局审计"指令，Coordinator 没有。

**根因**：Coordinator 有 Edit 权限 → 它可以"顺手"改 → 绕过了 Builder 的审计流程。

**修复**：Coordinator 的 tools 列表不包含 Edit。
想改代码？写入 spec，调度 Builder。

---

## 反模式 2：QA 拿到 Edit 权限

**场景**：QA 发现一个 CSS 样式错位，它直接修复了。
然后自己验收自己的修复，报告"全部通过"。

**后果**：QA 变成了"既是裁判又是运动员"。这次修复恰好是对的，
下次可能不是 —— 但你已经失去了独立验证。

**根因**：QA 有 Edit → 它可以修复 → 修复后自己验收 → 验收失去独立性。

**修复**：QA agent 的 tools 中永远不包含 Edit 和 Write。
它只能 Read + Bash（运行测试/检查）+ SendMessage（报告结果）。

---

## 反模式 3：Unit Tests 通过 ≠ 功能正常

**场景**：一个 API 网关项目，Builder 写完代码后运行了 472 个 unit tests，
全部通过。但用浏览器访问时，所有 API 调用返回 `undefined`。

**根因**：测试中 mock 了 HTTP client 的返回格式 `{ data: {...} }`，
但真实 API 返回的是 `{ result: {...} }`。Mock 和现实不一致。

**教训**：
- Unit tests 是必要条件，不是充分条件
- QA 必须包含至少一种"真实环境"验证（浏览器测试、curl 调用、集成测试）
- 不要用 mock 覆盖率给自己安全感

---

## 反模式 4：Builder 不做全局审计

**场景**：一个表单处理项目，Builder 修复了 `UserForm.tsx` 中的
日期格式问题。QA 通过了。

一周后发现 `OrderForm.tsx`、`PaymentForm.tsx`、`SettingsForm.tsx`
有完全相同的 bug —— **Whack-a-Mole 模式。**

**根因**：Builder 只看了 spec 指定的文件，没有全局搜索相同模式。

**修复**：Builder prompt 中加入审计指令：
```
每次修复 bug 后，必须在整个项目中搜索相同模式。
使用 grep -rn 或 find + grep 确认没有同类问题。
将搜索结果写入 .harness/progress.tsv。
```

---

## 反模式 5：固定轮次 Review

**场景**：Harness 配置为"Builder 完成后 QA review 一轮，通过就结束"。

Builder 第一轮修了 3 个 bug，QA review 发现 2 个新问题。
按规则 QA 只 review 一轮，所以这 2 个问题被标记为"下次处理"。

**根因**：用固定轮次代替了"收敛到零缺陷"的循环。

**修复**：循环条件是"QA report 全 PASS"，不是"已经 review 了 N 轮"。
设置最大轮次（如 5 轮）作为安全阀，防止无限循环。
达到最大轮次仍有 FAIL 时 escalate 给用户。

---

## 反模式 6：用行数判断 Ceremony 级别

**场景**："改动少于 50 行不需要 spec，直接写。"

一个 3 行的配置修改影响了整个认证流程。
没有 spec，没有 QA，直接合入，生产环境用户无法登录。

**根因**：行数和影响范围没有相关性。3 行改动可能比 300 行改动更危险。

**修复**：Ceremony 级别由影响范围决定，不由行数决定：
- 影响单个函数内部 → 轻量流程
- 影响跨文件接口 → 标准流程
- 影响认证/支付/数据迁移等关键路径 → 完整流程

---

## 反模式 7：把 Harness 做成代码框架

**场景**：团队给 Harness 添加了 Python 脚本来自动解析 spec、
生成 report 模板、管理 agent 生命周期。

3 个月后，维护这套"Harness 框架"本身消耗的精力超过了它节省的。
新成员要学框架的 API 才能开始用 Harness。

**根因**：Harness 的价值在于简单 —— 几个 `.md` 文件 + 一个 `settings.json`。
一旦加入代码依赖，它就不再是"随时可拆除的 overlay"。

**修复**：Harness 中唯一允许的可执行文件是辅助 shell 脚本
（init、verify、upgrade）。不写应用代码，不引入依赖。

---

## 反模式 8：跳过意图对齐直接执行

**场景**：用户说"优化搜索性能"。Coordinator 没有写 spec，
直接调度 Builder 开始优化。

Builder 做了索引优化。用户其实想要的是"搜索结果的 UI 响应速度"，
不是后端查询速度。两天的工作方向错误。

**根因**：省略了意图翻译步骤。"优化性能"可以有 10 种理解。

**修复**：Coordinator 在收到模糊请求时，必须先产出 spec 并请用户确认。
spec 中写明具体的验收标准（"首页搜索结果在 200ms 内渲染完成"）。
用户确认后再调度 Generator。
