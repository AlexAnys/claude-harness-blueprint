# LLM Wiki 部署指南

## 这是什么

一个 4-agent 的个人知识编译系统。部署完成后，你可以：
- 把文章、论文、笔记丢进 `raw/` → 自动编译成结构化 wiki 页面
- 提问 → 从 wiki 中合成答案，有价值的答案自动回写到 wiki（知识复利）
- 自动检查断链、孤儿页、矛盾、过时信息

核心隐喻：`raw/` 是源代码，agent 是编译器，`wiki/` 是编译产物。

## 部署步骤

### 步骤 1：选择安装位置

用户需要提供一个目录路径。建议：
- 放在你日常使用的开发/文档目录下
- 如果计划用 Obsidian 打开 wiki/，这个目录就是你的 vault

```bash
# 示例（向导应先问用户）
WIKI_DIR="<用户指定的路径>/llm-wiki"
```

### 步骤 2：复制基础设施

```bash
mkdir -p "$WIKI_DIR"
cp -r harnesses/llm-wiki/.claude "$WIKI_DIR/.claude"
cp harnesses/llm-wiki/CLAUDE.md "$WIKI_DIR/CLAUDE.md"
cp harnesses/llm-wiki/.gitignore "$WIKI_DIR/.gitignore"
cp harnesses/llm-wiki/log.md "$WIKI_DIR/log.md"

# 创建目录结构
mkdir -p "$WIKI_DIR/raw/assets"
mkdir -p "$WIKI_DIR/wiki/sources"
mkdir -p "$WIKI_DIR/wiki/concepts"
mkdir -p "$WIKI_DIR/wiki/entities"
mkdir -p "$WIKI_DIR/wiki/synthesis"

# 创建初始 index
cp harnesses/llm-wiki/wiki/index.md "$WIKI_DIR/wiki/index.md"

# 可选：复制导出脚本
mkdir -p "$WIKI_DIR/scripts"
cp harnesses/llm-wiki/scripts/export-public.sh "$WIKI_DIR/scripts/export-public.sh"
chmod +x "$WIKI_DIR/scripts/export-public.sh"
```

### 步骤 3：适配 CLAUDE.md

`CLAUDE.md` 是知识库的 schema——定义了页面格式、编译规则和语言约定。你可能想调整：

1. **语言约定**：默认中文主体 + 英文专有名词。如果你的知识库主要是英文内容，修改 CLAUDE.md 中的"语言约定"章节。

2. **隐私分层**：CLAUDE.md 中有完整的隐私导出机制（`public: false`、`<!-- PRIVATE -->` 标记、替换规则）。如果你不需要公开导出，可以忽略这些。

3. **页面格式**：CLAUDE.md 定义了 sources/concepts/entities/synthesis 四种页面的 frontmatter 和正文格式。这些格式是经过实践验证的，建议先用默认格式跑一段时间，有需要再调。

### 步骤 4：初始化 Git（推荐）

```bash
cd "$WIKI_DIR"
git init
git add .
git commit -m "init: LLM Wiki infrastructure"
```

Git 让你追踪知识库的演化，也是 CLAUDE.md 中 "Git 闭环规则" 的前提。

### 步骤 5：验证部署

```bash
cd "$WIKI_DIR"
claude
```

Claude Code 会自动进入 @coordinator（因为 `settings.json` 设了 `"agent": "coordinator"`）。SessionStart hook 会自动输出 wiki 状态。

验证方式：问 coordinator "wiki 状态如何？"——它应该报告空 wiki，0 个源文件，0 个编译页。

### 步骤 6：第一次编译

在 `raw/` 中放入你的第一个源文件：

```bash
# 方式 1：直接复制文件
cp ~/Documents/some-article.md "$WIKI_DIR/raw/"

# 方式 2：用 Obsidian Web Clipper 抓取网页（如果已安装）
# 抓取的文件会自动出现在 raw/

# 方式 3：直接告诉 coordinator 一个 URL
# coordinator 会用 WebFetch 获取内容并保存到 raw/
```

然后在 Claude Code 中说：

```
编译 raw/ 中的新文件
```

Coordinator 会调度 compiler：
1. 读取 raw 文件
2. 创建 `wiki/sources/` 摘要页
3. 创建或更新 `wiki/concepts/` 概念页
4. 创建或更新 `wiki/entities/` 实体页
5. 添加交叉引用 wikilinks
6. 更新 `wiki/index.md`
7. 写入 `log.md`
8. 自动触发 QA 检查

## 日常使用

| 你做什么 | Wiki 做什么 |
|---------|-----------|
| 丢文件到 `raw/` → "编译新文件" | Compiler 编译 → 更新 index → QA 检查 |
| 提一个问题 | Coordinator 查 wiki → 合成答案 → 有价值则回写 synthesis/ |
| "lint" 或 "健康检查" | QA 跑 6 项检查（断链/孤儿/矛盾/过时/覆盖/格式） |
| "批量导入 ~/Notes/" | Batch-compiler 扫描 → 逐个编译 → 最后 lint |

## 与 Obsidian 配合

`wiki/` 目录可以直接作为 Obsidian vault 打开：
- `[[wikilinks]]` 格式兼容 Obsidian
- 每个 wiki 页面都是标准 Markdown
- frontmatter 兼容 Obsidian 的属性面板

建议：在 Obsidian 中打开 `wiki/` 子目录（不是整个 llm-wiki/），这样 `raw/` 和 `log.md` 不会干扰浏览。

## 卸载

```bash
rm -rf "$WIKI_DIR"
```
