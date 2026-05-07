# Demo: TaskFlow App

> 虚构任务管理 Web App，展示 software-dev harness 的运行后状态。

## 虚构项目信息

- **项目名**：TaskFlow --- 一个轻量级任务管理应用
- **技术栈**：Next.js 14 + TypeScript + SQLite（via better-sqlite3）
- **包管理器**：pnpm
- **UI 语言**：中文

## 展示内容

本示例展示一个 software-dev harness **运行后**的状态：

- `.claude/agents/` --- 三个 agent 定义（coordinator, builder, qa）
- `.harness/spec.md` --- 一个已完成的 spec（用户认证模块）
- `.harness/progress.tsv` --- 进度跟踪数据
- `.harness/reports/` --- Builder 和 QA 的报告

## 注意

所有数据均为虚构，用于演示 harness 的文件结构和协作产物。
这不是一个可运行的应用 --- 没有实际源代码。
