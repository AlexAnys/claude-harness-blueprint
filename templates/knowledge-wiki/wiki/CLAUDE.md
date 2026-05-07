# Wiki Schema 定义

本文件定义 wiki 页面的格式约束。Compiler 创建或修改 wiki 页面时必须遵守。

## Frontmatter 格式

每个 wiki 页面必须以 YAML frontmatter 开头：

```yaml
---
title: "页面标题"          # 必需 — 人类可读的标题
slug: "unique-slug"        # 必需 — URL 友好的唯一标识符，小写，用 - 分隔
tags: ["tag1", "tag2"]     # 必需 — 至少一个 tag
created: "YYYY-MM-DD"     # 必需 — 创建日期
updated: "YYYY-MM-DD"     # 必需 — 最后更新日期
source: "raw/filename"     # 必需 — 原始材料路径，多个用逗号分隔
---
```

## 字段约束

- **slug**：全局唯一，一旦创建不可修改（其他页面可能引用）
- **tags**：使用已有 tag，新 tag 需在 index.md 的 tag 列表中注册
- **source**：指向 `raw/` 中的文件，如果是综合多份材料，列出所有来源

## 正文格式

- 使用标准 Markdown
- 交叉引用使用 `[[slug]]` 语法
- 一级标题 `#` 与 frontmatter title 一致
- 二级及以下标题用于内容组织
- 代码块标注语言
- 外部链接使用标准 `[text](url)` 语法

## 命名约定

- 文件名 = slug + `.md`
- 例：slug 为 `distributed-consensus` → 文件名为 `distributed-consensus.md`
