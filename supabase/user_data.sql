-- ============================================================
-- 粤春考助手 · 个人数据云端存储表（一次性执行）
-- 用于把每个用户的学习计划、错题本、收藏、学习统计上云
-- 用法：Supabase 控制台 → SQL Editor → 粘贴全部执行一次
-- 说明：通用 key-value JSON 存储，按用户隔离，可重复执行
-- ============================================================

create table if not exists public.user_data (
  user_id uuid not null references auth.users(id) on delete cascade,
  key text not null,
  data jsonb not null default '{}',
  updated_at timestamptz default now(),
  primary key (user_id, key)
);

alter table public.user_data enable row level security;

-- 每个用户只能读写自己的数据
drop policy if exists "user_data_own" on public.user_data;
create policy "user_data_own" on public.user_data
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
