# 工具增强（可选）

## 核心声明

**Harness 不依赖任何外部工具。**

所有 agent 用 Claude Code 原生能力（Read / Write / Edit / Bash / SendMessage）
即可完成完整的 Plan → Build → QA 流程。

本文介绍的工具都是**可选增强**，用于提升特定环节的效率。
不装任何一个，Harness 的核心价值不受影响。

## Playwright MCP（推荐）

Playwright MCP 是 Microsoft 开源的浏览器自动化 MCP 工具，
特别适合 QA agent 做浏览器级验证。

### 为什么推荐

- 开源免费，MIT 协议
- 专为 AI agent 设计的 MCP 接口
- 支持 Chromium / Firefox / WebKit
- 可截图、可交互、可检查 DOM

### 配置方法

```bash
# 添加到 Claude Code 的 MCP 配置
claude mcp add playwright -- npx @anthropic-ai/mcp-playwright
```

### QA 集成

在 QA agent 的 prompt 中添加：

```markdown
## 浏览器验证
当验收涉及 UI 功能时：
1. 用 Playwright MCP 打开目标页面
2. 按 spec 中的每条 UI 要求逐一验证
3. 截图作为证据保存到 .harness/reports/
4. 在 report 中引用截图路径
```

## 其他浏览器自动化工具

| 工具 | 特点 | 适用场景 |
|------|------|----------|
| Playwright MCP | 开源，MCP 原生 | QA 浏览器验证（首选） |
| Puppeteer | 成熟稳定，Chromium only | 已有 Puppeteer 基础设施的项目 |
| Selenium | 多浏览器支持最全 | 需要跨浏览器测试 |

## 可选工具增强表

| 工具类型 | 具体工具 | 对应角色 | 用途 |
|----------|----------|----------|------|
| 浏览器自动化 | Playwright MCP | Evaluator | UI 验证、截图取证 |
| 文件搜索 | ripgrep (`rg`) | Generator | 全局审计、模式搜索 |
| API 测试 | curl + jq | Evaluator | API 端点验证 |
| 代码分析 | tree-sitter | Generator | AST 级代码理解 |
| 文档渲染 | pandoc | Generator | Markdown → 其他格式 |
| Git 操作 | gh CLI | Coordinator | PR 创建、Issue 管理 |
| 数据库查询 | psql / sqlite3 | Evaluator | 数据层验证 |

## 无外部工具时的替代方案

完全不装任何额外工具时，每个环节的替代方案：

### UI 验证替代

```bash
# 用 curl 检查页面是否正常返回
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000

# 检查关键 HTML 元素存在
curl -s http://localhost:3000 | grep -c 'id="search-form"'
```

### API 测试替代

```bash
# 测试 API 端点
curl -s http://localhost:3000/api/users | jq '.status'

# 验证响应结构
curl -s http://localhost:3000/api/users | jq 'keys'
```

### 代码审查替代

```bash
# 用 git diff 审查改动范围
git diff --stat HEAD~1

# 搜索潜在问题模式
grep -rn 'TODO\|FIXME\|HACK' src/

# 检查改动是否引入新依赖
git diff HEAD~1 -- package.json
```

### 测试运行替代

```bash
# 直接用项目自带的测试命令
npm test
pytest
go test ./...

# Bash 级集成测试
#!/bin/bash
# 启动服务 → 发请求 → 检查响应 → 关闭服务
```

## 总结

工具增强遵循一个原则：**先用原生能力跑通，遇到瓶颈再加工具。**

不要在 day 1 就配齐所有工具。先用最小配置运行几个任务，
观察哪个环节最痛（通常是 QA 的 UI 验证），再针对性地加工具。
