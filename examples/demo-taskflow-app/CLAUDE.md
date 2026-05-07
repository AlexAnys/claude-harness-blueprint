# TaskFlow CLAUDE.md

## 项目信息

- **名称**：TaskFlow（任务管理应用）
- **技术栈**：Next.js 14 + TypeScript + SQLite（better-sqlite3）
- **包管理器**：pnpm
- **UI 语言**：中文
- **代码注释**：英文

## 规则

- 所有变更必须回溯到 `.harness/spec.md`
- 组件使用 React Server Components 优先
- 数据库操作使用 better-sqlite3 同步 API
- API 路由统一放在 `app/api/` 下
- 提交前运行 `pnpm test && pnpm lint`
- 不引入 ORM --- 手写 SQL
- 错误消息面向用户时使用中文

## Harness 配置

- Coordinator 负责拆解需求、调度 Builder 和 QA
- Builder 写代码，完成后写报告
- QA 对照 spec 验收，不改代码
- 所有中间产物在 `.harness/`
