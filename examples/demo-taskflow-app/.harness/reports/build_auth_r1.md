# Build Report: auth-01 / auth-02 Round 1

> Builder | 2026-05-05

## 改动范围

### 新增文件

| 文件 | 说明 |
|------|------|
| `lib/db/schema.sql` | users + sessions 表定义 |
| `lib/db/init.ts` | 数据库初始化脚本 |
| `lib/auth/password.ts` | bcrypt 哈希和验证 |
| `lib/auth/session.ts` | Session 创建、验证、清理 |
| `app/api/auth/register/route.ts` | 注册 API |
| `app/api/auth/login/route.ts` | 登录 API |
| `app/api/auth/logout/route.ts` | 登出 API |
| `app/api/auth/me/route.ts` | 获取当前用户 API |
| `lib/validations/auth.ts` | zod schema 定义 |
| `__tests__/auth.test.ts` | 认证模块集成测试 |

### 修改文件

| 文件 | 说明 |
|------|------|
| `package.json` | 添加 bcrypt, better-sqlite3, zod 依赖 |
| `lib/db/index.ts` | 添加 users 和 sessions 相关查询 |

## 实现说明

### 密码哈希

使用 bcrypt（cost = 12），按 spec 要求。选择 bcrypt 而非 argon2
是因为 better-sqlite3 的同步 API 配合 bcrypt 更简单。

### Session 管理

Session ID 使用 `crypto.randomUUID()`，存储在 HTTP-only cookie 中。
有效期 7 天，每次请求不续期（固定过期时间）。

添加了 session 清理函数 `cleanExpiredSessions()`，
在每次登录时顺带清理过期 session。

### 输入校验

所有 API 入口使用 zod schema 校验。统一错误格式：

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

### 并发处理

注册时使用 SQLite 的 UNIQUE 约束处理邮箱重复。
捕获 SQLITE_CONSTRAINT_UNIQUE 错误并返回 409。

## 测试

- 10 个集成测试，覆盖所有 API 路由
- 包含正常流程和错误流程
- `pnpm test` 全部通过
