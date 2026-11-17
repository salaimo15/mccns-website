-- MCCNS website update 2: BR1 catalog and quotation requests.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.

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
