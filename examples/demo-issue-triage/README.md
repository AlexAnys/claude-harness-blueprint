# Demo: Issue Triage

> 虚构 GitHub Issue 自动分流系统，展示 operations harness 的结构。

## 虚构项目信息

- **项目名**：CloudDB Issue Triage --- 为虚构的开源数据库项目做 issue 分流
- **模式**：operations（Coordinator → Executor → Monitor）
- **核心特点**：持续循环 + experience layer + frontier tracking

## 展示内容

- `.harness/spec.md` --- pipeline 定义
- `.harness/progress.tsv` --- 处理进度
- `.harness/experience/patterns.md` --- 已蒸馏的处理模式
- `.harness/experience/failures.md` --- 故障记录

## 注意

所有 issue 数据和处理模式均为虚构，仅用于演示 operations harness 的工作方式。
