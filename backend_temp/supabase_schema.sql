-- Run these in Supabase SQL editor.

-- Documents analyzed by a user
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  backend_document_id text not null,
  filename text not null,
  language text not null,
  safety_score double precision not null default 0,
  risk_level text not null default 'Unknown',
  analysis_json jsonb,
  created_at timestamptz not null default now()
);

-- Chat messages per document (threaded by backend_document_id)
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  backend_document_id text not null,
  role text not null check (role in ('user','assistant')),
  content text not null,
  created_at timestamptz not null default now()
);

-- Enable Row Level Security
alter table public.documents enable row level security;
alter table public.chat_messages enable row level security;

-- Policies: users can only access their own rows
drop policy if exists "documents_select_own" on public.documents;
create policy "documents_select_own"
on public.documents for select
using (auth.uid() = user_id);

drop policy if exists "documents_insert_own" on public.documents;
create policy "documents_insert_own"
on public.documents for insert
with check (auth.uid() = user_id);

drop policy if exists "chat_select_own" on public.chat_messages;
create policy "chat_select_own"
on public.chat_messages for select
using (auth.uid() = user_id);

drop policy if exists "chat_insert_own" on public.chat_messages;
create policy "chat_insert_own"
on public.chat_messages for insert
with check (auth.uid() = user_id);
