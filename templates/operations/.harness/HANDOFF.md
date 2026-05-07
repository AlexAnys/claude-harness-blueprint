# 会话交接文档

<!-- 
  每次会话结束前由 Coordinator 写入。
  下一次会话开始时，Coordinator 首先读取本文件恢复上下文。
-->

## 上次会话摘要

<!-- 处理了多少事件、frontier signal 情况 -->

## 待处理队列

<!-- 
  从 progress.tsv 摘要：
  - Critical: N 件
  - High: N 件
  - Frontier: N 件（需人工决策）
-->

## 最近 Health Report

<!-- 摘要 Monitor 最近一次的 health report 关键指标 -->

## 新发现的模式

<!-- 本次会话中发现的新模式，已记录到 experience/patterns.md -->

## 注意事项

<!-- 下一会话需要特别注意的事项 -->
