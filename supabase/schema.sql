-- FocusLoop cloud schema for multi-device sync.
-- Run this whole file once in: Supabase Dashboard -> SQL Editor -> New query.

create table if not exists public.categories (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color bigint not null default 0,
  sort_order bigint not null default 0,
  target_seconds bigint not null default 0,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted boolean not null default false
);

alter table public.categories add column if not exists target_seconds bigint not null default 0;

alter table public.categories enable row level security;

create policy "categories own rows"
  on public.categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.tasks (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  note text,
  category_id text,
  due_date timestamptz,
  target_seconds bigint not null default 0,
  accumulated_seconds bigint not null default 0,
  status text not null default 'active',
  timed boolean not null default true,
  review_enabled boolean not null default false,
  review_template_id text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted boolean not null default false
);

alter table public.tasks add column if not exists due_date timestamptz;

alter table public.tasks enable row level security;

create policy "tasks own rows"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.time_logs (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  task_id text not null,
  device_id text not null,
  started_at timestamptz not null,
  duration_seconds bigint not null,
  created_at timestamptz not null
);

alter table public.time_logs enable row level security;

create policy "time_logs own rows"
  on public.time_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.review_schedules (
  id text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  task_id text not null,
  round bigint not null,
  due_at timestamptz not null,
  completed_at timestamptz,
  result text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted boolean not null default false
);

alter table public.review_schedules enable row level security;

create policy "review_schedules own rows"
  on public.review_schedules for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
