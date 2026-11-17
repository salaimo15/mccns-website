-- MCCNS website: fleet and crew tables, photo storage and access rules.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.
-- Change the admin email below if you sign in with a different address.

-- Who may edit: the admin account(s) listed here.
create or replace function public.is_admin()
returns boolean language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', '')) in ('stefano.alaimo@outlook.com')
$$;

-- Yachts (current fleet and previously managed)
create table if not exists public.fleet (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  type text,
  length text,
  built text,
  port text,
  link text,
  yacht_use text check (yacht_use in ('private', 'commercial')),
  status text not null default 'current' check (status in ('current', 'past')),
  mgmt jsonb not null default '{}'::jsonb,
  photo text,
  example boolean not null default false,
  ord double precision not null default 0,
  created_at timestamptz not null default now()
);

-- Crew members
create table if not exists public.crew (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text,
  yacht text,
  photo text,
  example boolean not null default false,
  ord double precision not null default 0,
  created_at timestamptz not null default now()
);

-- Everyone can read; only the admin can add, change or delete.
alter table public.fleet enable row level security;
alter table public.crew enable row level security;

drop policy if exists "fleet read" on public.fleet;
drop policy if exists "fleet admin" on public.fleet;
create policy "fleet read" on public.fleet for select to anon, authenticated using (true);
create policy "fleet admin" on public.fleet for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "crew read" on public.crew;
drop policy if exists "crew admin" on public.crew;
create policy "crew read" on public.crew for select to anon, authenticated using (true);
create policy "crew admin" on public.crew for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Photo storage: public to view, only the admin can upload or remove.
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do update set public = true;

drop policy if exists "photos admin insert" on storage.objects;
drop policy if exists "photos admin update" on storage.objects;
drop policy if exists "photos admin delete" on storage.objects;
create policy "photos admin insert" on storage.objects for insert to authenticated with check (bucket_id = 'photos' and public.is_admin());
create policy "photos admin update" on storage.objects for update to authenticated using (bucket_id = 'photos' and public.is_admin());
create policy "photos admin delete" on storage.objects for delete to authenticated using (bucket_id = 'photos' and public.is_admin());
