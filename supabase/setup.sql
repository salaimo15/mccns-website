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
  photo_pos text,
  example boolean not null default false,
  ord double precision not null default 0,
  created_at timestamptz not null default now()
);
alter table public.fleet add column if not exists photo_pos text;

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


-- Catalog products (BR1 crew uniforms)
create table if not exists public.catalog (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'other' check (category in ('polo', 'shirt', 'shorts', 'jacket', 'cap', 'bag', 'other')),
  description text check (char_length(description) <= 300),
  photo text,
  photo_pos text,
  ord double precision not null default 0,
  created_at timestamptz not null default now()
);
alter table public.catalog enable row level security;
drop policy if exists "catalog read" on public.catalog;
drop policy if exists "catalog admin" on public.catalog;
create policy "catalog read" on public.catalog for select to anon, authenticated using (true);
create policy "catalog admin" on public.catalog for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Starting categories, only if the catalog is empty. Edit or delete them from the website.
insert into public.catalog (name, category, description, ord)
select * from (values
  ('Polo shirts', 'polo', 'Breathable piqué and technical polos for deck and interior crew.', 1),
  ('Shirts', 'shirt', 'Oxford and technical shirts for guests on board and evenings ashore.', 2),
  ('Shorts and trousers', 'shorts', 'Hard wearing bottoms cut for work on deck.', 3),
  ('Outerwear', 'jacket', 'Light jackets and foul weather layers for every season.', 4),
  ('Caps and accessories', 'cap', 'Caps, belts and small items in the yacht''s colours.', 5),
  ('Bags', 'bag', 'Crew bags and kit bags, branded for the yacht.', 6)
) as v(name, category, description, ord)
where not exists (select 1 from public.catalog);

-- Quotation requests: anyone can send one, only the admin can read, update or delete them.
create table if not exists public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null check (char_length(name) between 1 and 120),
  yacht text check (char_length(yacht) <= 120),
  email text not null check (char_length(email) between 3 and 200),
  phone text check (char_length(phone) <= 60),
  crew_size text check (char_length(crew_size) <= 20),
  needed_by text check (char_length(needed_by) <= 60),
  items text[] not null default '{}' check (cardinality(items) <= 20),
  details text check (char_length(details) <= 3000),
  status text not null default 'new' check (status in ('new', 'answered'))
);
alter table public.quote_requests enable row level security;
drop policy if exists "quotes send" on public.quote_requests;
drop policy if exists "quotes admin" on public.quote_requests;
create policy "quotes send" on public.quote_requests for insert to anon, authenticated with check (status = 'new');
create policy "quotes admin" on public.quote_requests for all to authenticated using (public.is_admin()) with check (public.is_admin());


create table if not exists public.tshirt_orders (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null check (char_length(name) between 1 and 120),
  email text not null check (char_length(email) between 3 and 200),
  phone text check (char_length(phone) <= 60),
  sizes jsonb not null default '{}'::jsonb,
  total integer not null check (total between 1 and 100),
  delivery text not null default 'pickup' check (delivery in ('pickup', 'ship')),
  address text check (char_length(address) <= 500),
  notes text check (char_length(notes) <= 1000),
  status text not null default 'new' check (status in ('new', 'done'))
);
alter table public.tshirt_orders enable row level security;
drop policy if exists "orders send" on public.tshirt_orders;
drop policy if exists "orders admin" on public.tshirt_orders;
create policy "orders send" on public.tshirt_orders for insert to anon, authenticated with check (status = 'new');
create policy "orders admin" on public.tshirt_orders for all to authenticated using (public.is_admin()) with check (public.is_admin());

notify pgrst, 'reload schema';
