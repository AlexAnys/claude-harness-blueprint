# Spec: 用户认证模块

> 状态：已完成 (2026-05-06)

## 需求

TaskFlow 需要用户认证功能，支持注册、登录、登出。

## 技术方案

### 数据库

```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  display_name TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### API 路由

| 路由 | 方法 | 功能 |
|------|------|------|
| `/api/auth/register` | POST | 注册新用户 |
| `/api/auth/login` | POST | 登录，返回 session |
| `/api/auth/logout` | POST | 登出，删除 session |
| `/api/auth/me` | GET | 获取当前用户信息 |

### 安全措施

- 密码使用 bcrypt 哈希（cost = 12）
- Session ID 使用 crypto.randomUUID()
- Session 有效期 7 天
- 所有输入做 zod 校验

## 验收标准

- [x] 注册：邮箱 + 密码 + 显示名 → 创建用户 → 自动登录
- [x] 登录：邮箱 + 密码 → 返回 session cookie
- [x] 登出：清除 session cookie + 删除 DB 记录
- [x] 获取当前用户：有效 session → 返回用户信息，无效 → 401
- [x] 邮箱重复注册 → 返回 409
- [x] 密码错误 → 返回 401（不暴露"用户不存在"）
- [x] 过期 session → 返回 401

## 边界条件

- [x] 空字符串输入 → 400
- [x] 超长输入（email > 320, name > 100）→ 400
- [x] 并发注册相同邮箱 → 只有一个成功
- [x] Session 过期后自动清理
