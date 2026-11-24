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

-- Fabric for the Ocean as Home T-shirt (also fixes it if this file was already run).
update public.catalog set fabric = 'Organic cotton' where ref = 'BR1-01' and fabric is null;

notify pgrst, 'reload schema';


-- MCCNS website update 4: the BR1 catalog, 29 products with photos.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.

alter table public.catalog add column if not exists ref text check (char_length(ref) <= 20);
alter table public.catalog add column if not exists fabric text check (char_length(fabric) <= 160);
alter table public.catalog drop constraint if exists catalog_description_check;
alter table public.catalog add constraint catalog_description_check check (char_length(description) <= 600);
alter table public.catalog drop constraint if exists catalog_category_check;
alter table public.catalog add constraint catalog_category_check check (category in ('tshirt', 'sweat', 'jacket', 'bottoms', 'headwear', 'bag', 'drink', 'polo', 'shirt', 'shorts', 'cap', 'other'));

-- Remove the six starting placeholder categories (only the untouched ones, without a photo).
delete from public.catalog where photo is null and ref is null and name in ('Polo shirts', 'Shirts', 'Shorts and trousers', 'Outerwear', 'Caps and accessories', 'Bags');

-- The products. A product whose reference already exists is skipped, so running this twice is safe.
insert into public.catalog (ref, name, category, description, fabric, photo, ord)
select v.ref, v.name, v.category, v.description, v.fabric, v.photo, v.ord from (values
  ('BR1-01', 'Ocean as Home T-shirt', 'tshirt', 'White T-shirt with the claim "Wind as fuel. Ocean as home." printed in red on the back, finished with a patch cut from an upcycled sail.', 'Organic cotton', 'img/cat-br1-01.webp', 1),
  ('BR1-02', 'Sport T-shirt', 'tshirt', 'Short sleeve raglan T-shirt with flatlock seams, breathable fabric and a sweat-absorbing neck tape. Side-seamed for a better fit.', '100% microperforated polyester · 140 g/m²', 'img/cat-br1-02.webp', 2),
  ('BR1-03', 'Contrast Panel T-shirt', 'tshirt', 'Short sleeve T-shirt with contrast panels and twin-needle stitching. Very hard-wearing, light and breathable.', '100% polyester · 140 g/m²', 'img/cat-br1-03.webp', 3),
  ('BR1-04', 'Technical Polo', 'tshirt', 'Technical short sleeve polo with three matching buttons and raglan sleeves. Double side seams for a better fit, longer drop hem at the back, reflective details on the sleeves and back of the collar, contrast neck tape.', '140 g/m²', 'img/cat-br1-04.webp', 4),
  ('BR1-05', 'Crew Neck Sweatshirt', 'sweat', 'Interlock crew neck sweatshirt with a zipped sleeve pocket and drawcord, cuffs in the same fabric.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-05.webp', 5),
  ('BR1-06', 'Zip Hoodie', 'sweat', 'Interlock hoodie with full zip, two open front pockets, a zipped sleeve pocket with drawcord, matching cuffs and an elasticated hem.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-06.webp', 6),
  ('BR1-07', 'Hoodie', 'sweat', 'Interlock hoodie with a double-layer hood, front pocket and a zipped sleeve pocket with drawcord.', '60% cotton, 40% polyester · 320 g/m²', 'img/cat-br1-07.webp', 7),
  ('BR1-08', 'Recycled Fleece Jacket', 'jacket', 'Soft, easy-care fleece jacket in recycled polyester with woven fabric inserts. Two side pockets, zipped chest pocket, two inner pockets, two-way front zip and high collar.', '100% recycled polyester · 280 g/m²', 'img/cat-br1-08.webp', 8),
  ('BR1-09', 'Heavy Fleece Jacket', 'jacket', 'Heavy, soft polyester fleece reinforced with ripstop on the shoulders and elbows. Quality zips, two large front pockets and elasticated cuffs for a close fit against the cold.', 'Polyester fleece with ripstop polyester · 344 g/m²', 'img/cat-br1-09.webp', 9),
  ('BR1-10', 'Hooded Jacket', 'jacket', 'Jacket with chin guard and a removable, adjustable hood. Two front pockets with double opening, elasticated hem and cuffs, inner press-stud pocket.', '88% polyester, 12% spandex', 'img/cat-br1-10.webp', 10),
  ('BR1-11', 'Softshell Gilet', 'jacket', 'Two-tone softshell gilet with metal auto-lock zip and branded puller. Two zipped side pockets, coated zip chest pocket, reflective detail on the back yoke and adjustable hem.', '95% polyester, 5% elastane · 320 g/m²', 'img/cat-br1-11.webp', 11),
  ('BR1-12', 'Technical Knit Jacket', 'jacket', 'Technical knit jacket with contrast softshell inserts, taped zip and shaped hood. Trimmed cuffs and hem, two zipped side pockets and a chest pocket.', '100% polyester · 380 g/m²', 'img/cat-br1-12.webp', 12),
  ('BR1-13', 'Softshell Jacket', 'jacket', 'Ergonomic softshell jacket with raglan sleeves, shaped hood with drawcord and taped full zip. Adjustable cuffs with rubberised tabs, two zipped side pockets, a chest pocket and a pocket on the left sleeve.', '100% polyester · 280 g/m²', 'img/cat-br1-13.webp', 13),
  ('BR1-14', 'Technical Shorts', 'bottoms', 'Light, strong, two-way stretch shorts with a water and stain repellent finish (BIONIC-FINISH® ECO). Quick drying, partly elasticated waist with belt loops, two side pockets, back pocket and leg pocket, all zipped.', '85% polyamide, 15% elastane', 'img/cat-br1-14.webp', 14),
  ('BR1-15', 'Technical Trousers', 'bottoms', 'Light, water and stain repellent trousers (BIONIC-FINISH® ECO), quick drying, with contrast inserts on the knees and back. Elasticated waist with belt loops, two side pockets, back pocket and leg pocket.', '85% polyamide, 15% elastane', 'img/cat-br1-15.webp', 15),
  ('BR1-16', 'Belt', 'bottoms', 'Strong belt with tone-on-tone metal buckle. Can be cut to length, adjustable from XS to 3XL.', '100% polyester', 'img/cat-br1-16.webp', 16),
  ('BR1-17', 'UPF50+ Cap', 'headwear', 'Six-panel cap in UPF50+ fabric with a quick-dry inner sweatband. Pre-curved peak, embroidered eyelets, velcro closure.', '75% nylon, 20% cotton, 5% elastane', 'img/cat-br1-17.webp', 17),
  ('BR1-18', 'Vented Cap', 'headwear', 'Six-panel cap with laser-cut ventilation, pre-curved peak and adjustable buckle closure. One size.', '100% recycled polyester', 'img/cat-br1-18.webp', 18),
  ('BR1-19', 'Ponytail Cap', 'headwear', 'Light, breathable cap with a ponytail opening at the back, pre-curved peak, elastic band and adjustable buckle closure. One size.', '100% recycled polyester', 'img/cat-br1-19.webp', 19),
  ('BR1-20', 'Outdoor Hat', 'headwear', 'Wide brim hat in coated polyester with taped main seams for water resistance. The brim folds up and fastens with press studs on the sides; ventilation eyelets keep it breathable.', 'Coated polyester · 85 g/m²', 'img/cat-br1-20.webp', 20),
  ('BR1-21', 'Bucket Hat', 'headwear', 'Casual bucket hat with a safety chin cord and float, a sloping brim and parallel decorative stitching.', 'Polyester', 'img/cat-br1-21.webp', 21),
  ('BR1-22', 'Beanie', 'headwear', 'Rib knit beanie with turn-up and micro fleece lining, durable water repellent finish.', '100% acrylic, lining 100% polyester', 'img/cat-br1-22.webp', 22),
  ('BR1-23', 'Waterproof Duffel', 'bag', 'Waterproof PVC duffel bag with a fully waterproof front pocket and detachable shoulder strap. Made for the deck, the tender and the dock.', 'PVC', 'img/cat-br1-23.webp', 23),
  ('BR1-24', 'Roll-top Dry Bag', 'bag', 'Fully waterproof bag with roll-top closure and shoulder straps. Available in several sizes for large capacity.', null, 'img/cat-br1-24.webp', 24),
  ('BR1-25', 'Roll-top Backpack', 'bag', 'Waterproof tarpaulin backpack with roll-top closure, a fully waterproof zipped front pocket, padded breathable shoulder straps and a mesh side pocket.', 'PVC tarpaulin', 'img/cat-br1-25.webp', 25),
  ('BR1-26', 'Waterproof Backpack', 'bag', 'Water resistant backpack with roll-top closure, vertical zipped front pocket and a stow-away carry net. Padded breathable straps, release valve to push out air and water, safety whistle on the chest strap.', null, 'img/cat-br1-26.webp', 26),
  ('BR1-27', 'Insulated Bottle', 'drink', 'Double-wall insulated bottle in recycled stainless steel with a rubber finish and silicone handle. 500 ml.', '90% recycled stainless steel, 10% stainless steel', 'img/cat-br1-27.webp', 27),
  ('BR1-28', 'Travel Tumbler', 'drink', 'Double-wall tumbler in recycled stainless steel with a PP outer layer and RPET wrist strap. 350 ml.', 'Recycled stainless steel, PP, RPET', 'img/cat-br1-28.webp', 28),
  ('BR1-29', 'Carabiner Mug', 'drink', 'Double-wall stainless steel mug with carabiner handle. 300 ml.', 'Stainless steel', 'img/cat-br1-29.webp', 29)
) as v(ref, name, category, description, fabric, photo, ord)
where not exists (select 1 from public.catalog c where c.ref = v.ref);

-- Fabric for the Ocean as Home T-shirt (also fixes it if this file was already run).
update public.catalog set fabric = 'Organic cotton' where ref = 'BR1-01' and fabric is null;

notify pgrst, 'reload schema';
