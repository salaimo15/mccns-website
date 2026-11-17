-- MCCNS website update 3: Ocean as Home t-shirt orders.
-- Run once in Supabase: SQL Editor > New query > paste all of this > Run.

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
