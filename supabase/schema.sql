-- ============================================================
-- 粤春考助手 · Supabase 数据库初始化脚本
-- 用法：在 Supabase 控制台 → SQL Editor → 粘贴全部执行一次
-- ============================================================

-- 1. 管理员表（只有这里面的用户才能写公共数据、进入管理后台）
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz default now()
);

-- 2. 用户资料表（关联 auth.users）
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  nickname text,
  created_at timestamptz default now()
);

-- 3. 题库
create table if not exists public.questions (
  id bigint generated always as identity primary key,
  subject text not null,
  type text not null,
  category text,
  stem text not null,
  options jsonb not null default '[]',
  answer int not null,
  analysis text,
  year text,
  created_at timestamptz default now()
);

-- 4. 单词
create table if not exists public.words (
  id bigint generated always as identity primary key,
  word text not null,
  meaning text not null,
  phonetic text,
  created_at timestamptz default now()
);

-- 5. 答题模板
create table if not exists public.templates (
  id bigint generated always as identity primary key,
  subject text not null,
  category text,
  title text not null,
  content text,
  created_at timestamptz default now()
);

-- 6. 分数线
create table if not exists public.score_lines (
  id bigint generated always as identity primary key,
  year int,
  batch text,
  college text,
  major text,
  score int,
  property text,
  region text,
  created_at timestamptz default now()
);

-- 7. 作文素材
create table if not exists public.essay_materials (
  id bigint generated always as identity primary key,
  type text,
  title text not null,
  content text,
  date date,
  created_at timestamptz default now()
);

-- 8. 政策解读
create table if not exists public.policies (
  id bigint generated always as identity primary key,
  title text not null,
  content text,
  date date,
  created_at timestamptz default now()
);

-- 9. 学习资料
create table if not exists public.materials (
  id bigint generated always as identity primary key,
  name text not null,
  type text,
  category text,
  content text,
  file_url text,
  upload_time text,
  created_at timestamptz default now()
);

-- 10. 公告
create table if not exists public.announcements (
  id bigint generated always as identity primary key,
  title text,
  content text,
  date date,
  created_at timestamptz default now()
);

-- 11. 学习计划（按用户）
create table if not exists public.study_plans (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  target_score int,
  raw jsonb,
  phase1 text,
  phase2 text,
  phase3 text,
  tips text,
  updated_at timestamptz default now()
);

-- 12. 错题本（按用户）
create table if not exists public.error_book (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id bigint not null,
  created_at timestamptz default now()
);

-- 13. 收藏（按用户）
create table if not exists public.favorites (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id bigint not null,
  created_at timestamptz default now()
);

-- 14. 社区帖子
create table if not exists public.posts (
  id bigint generated always as identity primary key,
  board text,
  title text,
  content text,
  author_id uuid references auth.users(id),
  author_name text,
  created_at timestamptz default now()
);

-- 15. 学习统计（按用户）
create table if not exists public.study_stats (
  id bigint generated always as identity primary key,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  total_questions int default 0,
  correct_questions int default 0,
  subject_stats jsonb default '{}',
  streak int default 0,
  word_learned int default 0,
  updated_at timestamptz default now()
);

-- ============================================================
-- 管理员判断函数
-- ============================================================
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- ============================================================
-- 启用 RLS（行级安全）
-- ============================================================
alter table public.admins enable row level security;
alter table public.profiles enable row level security;
alter table public.questions enable row level security;
alter table public.words enable row level security;
alter table public.templates enable row level security;
alter table public.score_lines enable row level security;
alter table public.essay_materials enable row level security;
alter table public.policies enable row level security;
alter table public.materials enable row level security;
alter table public.announcements enable row level security;
alter table public.study_plans enable row level security;
alter table public.error_book enable row level security;
alter table public.favorites enable row level security;
alter table public.posts enable row level security;
alter table public.study_stats enable row level security;

-- ============================================================
-- 公共数据表策略：所有人可读，仅管理员可写
-- ============================================================

-- questions
create policy "questions_read" on public.questions for select using (true);
create policy "questions_admin_insert" on public.questions for insert with check (public.is_admin());
create policy "questions_admin_update" on public.questions for update using (public.is_admin());
create policy "questions_admin_delete" on public.questions for delete using (public.is_admin());

-- words
create policy "words_read" on public.words for select using (true);
create policy "words_admin_insert" on public.words for insert with check (public.is_admin());
create policy "words_admin_update" on public.words for update using (public.is_admin());
create policy "words_admin_delete" on public.words for delete using (public.is_admin());

-- templates
create policy "templates_read" on public.templates for select using (true);
create policy "templates_admin_insert" on public.templates for insert with check (public.is_admin());
create policy "templates_admin_update" on public.templates for update using (public.is_admin());
create policy "templates_admin_delete" on public.templates for delete using (public.is_admin());

-- score_lines
create policy "score_lines_read" on public.score_lines for select using (true);
create policy "score_lines_admin_insert" on public.score_lines for insert with check (public.is_admin());
create policy "score_lines_admin_update" on public.score_lines for update using (public.is_admin());
create policy "score_lines_admin_delete" on public.score_lines for delete using (public.is_admin());

-- essay_materials
create policy "essay_materials_read" on public.essay_materials for select using (true);
create policy "essay_materials_admin_insert" on public.essay_materials for insert with check (public.is_admin());
create policy "essay_materials_admin_update" on public.essay_materials for update using (public.is_admin());
create policy "essay_materials_admin_delete" on public.essay_materials for delete using (public.is_admin());

-- policies
create policy "policies_read" on public.policies for select using (true);
create policy "policies_admin_insert" on public.policies for insert with check (public.is_admin());
create policy "policies_admin_update" on public.policies for update using (public.is_admin());
create policy "policies_admin_delete" on public.policies for delete using (public.is_admin());

-- materials
create policy "materials_read" on public.materials for select using (true);
create policy "materials_admin_insert" on public.materials for insert with check (public.is_admin());
create policy "materials_admin_update" on public.materials for update using (public.is_admin());
create policy "materials_admin_delete" on public.materials for delete using (public.is_admin());

-- announcements
create policy "announcements_read" on public.announcements for select using (true);
create policy "announcements_admin_insert" on public.announcements for insert with check (public.is_admin());
create policy "announcements_admin_update" on public.announcements for update using (public.is_admin());
create policy "announcements_admin_delete" on public.announcements for delete using (public.is_admin());

-- ============================================================
-- 用户资料表策略
-- ============================================================
create policy "profiles_read" on public.profiles for select using (true);
create policy "profiles_insert_own" on public.profiles for insert with check (id = auth.uid());
create policy "profiles_update_own" on public.profiles for update using (id = auth.uid());

-- ============================================================
-- 用户个人数据策略：只能读写自己的
-- ============================================================

-- study_plans
create policy "study_plans_own" on public.study_plans for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- error_book
create policy "error_book_own" on public.error_book for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- favorites
create policy "favorites_own" on public.favorites for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- study_stats
create policy "study_stats_own" on public.study_stats for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================
-- 社区帖子策略：所有人可读，登录用户可发/改/删自己的
-- ============================================================
create policy "posts_read" on public.posts for select using (true);
create policy "posts_insert_auth" on public.posts for insert with check (auth.uid() is not null);
create policy "posts_update_own" on public.posts for update using (author_id = auth.uid());
create policy "posts_delete_own" on public.posts for delete using (author_id = auth.uid());

-- ============================================================
-- 说明：如何把自己设为管理员
-- 1. 在网页端完成注册登录
-- 2. 回到 Supabase 控制台 → Authentication → Users，复制你的 User UUID
-- 3. 执行下面这条（把 '你的user-id' 替换成上面的 UUID）：
--
--   insert into public.admins (user_id) values ('你的user-id');
--
-- ============================================================
