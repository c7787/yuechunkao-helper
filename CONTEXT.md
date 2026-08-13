# 粤春考助手 · 项目上下文摘要

> 本文件用于压缩/恢复对话上下文。开新会话时把本文档内容发给 AI，即可无缝接续工作。
> 最后更新：2026-08-13

## 一、项目概述
**粤春考助手**——广东省春季高考（依学考录取，语数英各150分满分450）备考单页应用。纯前端 SPA（HTML+CSS+JS，无框架）+ Supabase 后端。

## 二、关键信息（务必保存）
| 项目 | 值 |
|---|---|
| 项目路径 | `/Users/mini/workbuddy-ai/粤春考助手/`（主文件 `index.html` ~2900行） |
| GitHub 仓库 | `c7787/yuechunkao-helper`（SSH: `git@github.com:c7787/yuechunkao-helper.git`，分支 main） |
| 线上地址 | https://c7787.github.io/yuechunkao-helper/ |
| Supabase URL | `https://svfnivnzbncxqrsfxibp.supabase.co` |
| Supabase anon key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2Zm5pdm56Ym5jeHFyc2Z4aWJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY1NjE2MTQsImV4cCI6MjEwMjEzNzYxNH0.4I0tq3G0E3-EhcfO2KVivnDFt1Y9KTrS1b4S45oFSzA`（公开密钥，可存；service_role 绝不能泄露） |
| 考试时间 | `EXAM_TIME = new Date('2027-01-08T09:00:00+08:00')` |
| 管理后台 | 用户名 `admin`，密码 `zxc0123`；入口=首页标题连点5次（<0.5s间隔） |
| 管理员身份 | 已设置（用户注册后 INSERT 进 `admins` 表） |

## 三、已完成功能
1. **学生端**：首页倒计时、学习计划生成（按月目标+三阶段）、刷题、单词闯关、答题模板、作文素材、政策解读、分数线查询、资料库、错题本、收藏、学习统计、番茄钟、社区。
2. **管理员后台**：资料/题库/单词/模板/分数线/素材/政策 7 大管理模块（增删改查）。
3. **注册登录**：Supabase Auth 邮箱认证（密码加密存储）。
4. **记住账号**：登录页复选框，本地存邮箱密码预填（纯本地 key `rememberLogin`）。
5. **数据上云**：公共数据（8张表）+ 个人数据（user_data 通用表）。
6. **题库扩充**：42→132 题（数学43-72、语文73-102、英语103-132）。
7. **批量导入**：管理后台「⚡批量导入」，支持题目(JSON)/单词/资料/分数线。

## 四、数据层架构（关键）
- `DB` 对象：localStorage 同步读写，`DB.get(k)`/`DB.set(k)`（key 前缀 `yck_`）。
- `CLOUD_TABLES`：公共数据映射（questions/words/templates/scoreLines/materials/essayMaterials/policies/announcements），字段映射如 `materials.uploadTime↔upload_time`、`announcements.time↔date`。
- `CloudSync`：`pullAll()`（init时云端非空覆盖本地）、`push()`（DB.set公共key时整表删+重建，串行队列）。
- `PersonalSync`：`PERSONAL_KEYS=['studyPlan','errorBook','favorites','studyStats']`，走 `user_data` 表（user_id+key+data jsonb，复合主键，upsert）。
- `cloudSyncReady` 标志：init 完成会话+拉取后才置 true，避免初始化误推送。
- **id 策略**：本地用显式 id（序号/`Date.now()`），云端 id 列已 `drop identity` 接受显式值。
- Auth 会话：`App._currentUser` 同步缓存，`init()` 里 `getSession()` 异步初始化。

## 五、文件清单
- `index.html` — 主应用（HTML+CSS+JS 一体）
- `supabase/schema.sql` — 建表（15表+RLS+is_admin()）
- `supabase/migrate.sql` — 数据迁移（drop identity + 全量 INSERT，可重复执行）
- `supabase/user_data.sql` — 个人数据通用表
- `supabase/generate_migrate.js` — 从 index.html 提取种子数据生成 migrate.sql（Node 脚本）
- `.workbuddy-ai/memory/2026-08-13.md` — 工作日志
- `CONTEXT.md` — 本文件

## 六、当前待办 / 下一步
- ⏳ **用户需重跑 `migrate.sql`** 灌入新增 90 题（42→132，`on conflict do nothing` 可重复执行）
- 社区 posts 仍是 localStorage 未上云（次要，暂缓）
- 用户偏好：交付文档优先 PDF；抖音相关文档走 PDF

## 七、环境
- Node 托管版：`/Users/mini/.workbuddy/binaries/node/versions/22.22.2/bin/node`
- Python 托管版：`/Users/mini/.workbuddy/binaries/python/versions/3.13.12/bin/python3`

## 八、部署与提交流程
- 修改 `index.html` 或 `supabase/*.sql` 后：`git add` + `git commit` + `git push origin main`
- GitHub Pages 自动构建，约 1 分钟生效（CDN 有延迟）
- 数据变更需在 Supabase SQL Editor 重跑对应 `.sql` 脚本
