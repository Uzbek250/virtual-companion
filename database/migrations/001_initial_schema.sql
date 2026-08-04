create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create table if not exists public.companions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  species text not null default 'cat' check (species in ('cat')),
  mood text not null default 'content',
  energy integer not null default 100 check (energy between 0 and 100),
  current_room text not null default 'bedroom',
  current_activity text not null default 'idle' check (current_activity in ('idle', 'sleeping', 'walking', 'talking', 'reading')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists companions_user_id_idx on public.companions(user_id);

alter table public.profiles enable row level security;
alter table public.companions enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can create their own profile"
  on public.profiles for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users can view their own companions"
  on public.companions for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can create their own companions"
  on public.companions for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their own companions"
  on public.companions for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own companions"
  on public.companions for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- The application should grant Data API access to these tables only after
-- RLS policies are enabled and verified.
