-- SIDAR verified doctor and product catalog.
-- Run this file once in Supabase SQL Editor after production_schema.sql.

create extension if not exists "pgcrypto";

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.is_sidar_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (select 1 from public.admin_users where user_id = auth.uid());
$$;

revoke all on function public.is_sidar_admin() from public;
grant execute on function public.is_sidar_admin() to authenticated, anon;

create table if not exists public.doctors (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(full_name) between 2 and 160),
  specialization text not null check (specialization in ('skin', 'hair', 'both')),
  concerns text[] not null default '{}',
  country text not null check (country ~ '^[A-Z]{2}$'),
  city text not null,
  clinic_hospital text not null,
  booking_url text not null check (booking_url ~ '^https?://'),
  contact_url text check (contact_url is null or contact_url ~ '^https?://'),
  license_number text,
  status text not null default 'Pending' check (status in ('Pending', 'Active', 'Inactive')),
  is_verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 2 and 160),
  brand text not null,
  category text not null check (category in ('skin', 'hair', 'both')),
  concerns text[] not null default '{}',
  skin_types text[] not null default '{}',
  description text,
  price numeric(12,2) check (price is null or price >= 0),
  currency text not null default 'USD',
  product_url text not null check (product_url ~ '^https?://'),
  image_url text check (image_url is null or image_url ~ '^https?://'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Existing SIDAR installations may already have earlier versions of these tables.
-- `create table if not exists` does not change them, so retrofit every column used
-- by the dashboard before creating indexes, policies, or seed data.
alter table public.doctors
  add column if not exists full_name text,
  add column if not exists specialization text,
  add column if not exists concerns text[] not null default '{}',
  add column if not exists country text,
  add column if not exists city text,
  add column if not exists clinic_hospital text,
  add column if not exists booking_url text,
  add column if not exists contact_url text,
  add column if not exists license_number text,
  add column if not exists status text not null default 'Pending',
  add column if not exists is_verified boolean not null default false,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.products
  add column if not exists name text,
  add column if not exists brand text,
  add column if not exists category text,
  add column if not exists concerns text[] not null default '{}',
  add column if not exists skin_types text[] not null default '{}',
  add column if not exists description text,
  add column if not exists price numeric(12,2),
  add column if not exists currency text not null default 'USD',
  add column if not exists product_url text,
  add column if not exists image_url text,
  add column if not exists is_active boolean not null default true,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

-- Earlier product tables used a narrower category enum/check (for example,
-- `Skincare` only). SIDAR catalog uses the stable values skin, hair, and both.
-- Drop the legacy constraint so existing records remain valid and new catalog
-- records can be written consistently by the dashboard.
alter table public.products drop constraint if exists products_category_check;

drop trigger if exists trg_doctors_updated_at on public.doctors;
create trigger trg_doctors_updated_at before update on public.doctors for each row execute function public.handle_updated_at();
drop trigger if exists trg_products_updated_at on public.products;
create trigger trg_products_updated_at before update on public.products for each row execute function public.handle_updated_at();

create index if not exists idx_doctors_active_location on public.doctors(status, is_verified, country);
create index if not exists idx_products_active_category on public.products(is_active, category);
create unique index if not exists idx_products_brand_name_unique on public.products(brand, name);

alter table public.admin_users enable row level security;
alter table public.doctors enable row level security;
alter table public.products enable row level security;

drop policy if exists "Users can see their admin marker" on public.admin_users;
create policy "Users can see their admin marker" on public.admin_users for select using (auth.uid() = user_id);

drop policy if exists "Public reads verified doctors" on public.doctors;
create policy "Public reads verified doctors" on public.doctors for select using (status = 'Active' and is_verified = true);
drop policy if exists "Admins manage doctors" on public.doctors;
create policy "Admins manage doctors" on public.doctors for all using (public.is_sidar_admin()) with check (public.is_sidar_admin());

drop policy if exists "Public reads active products" on public.products;
create policy "Public reads active products" on public.products for select using (is_active = true);
drop policy if exists "Admins manage products" on public.products;
create policy "Admins manage products" on public.products for all using (public.is_sidar_admin()) with check (public.is_sidar_admin());

-- Replace the UUID with the SIDAR account that may manage the catalog.
-- insert into public.admin_users (user_id) values ('PASTE_AUTH_USERS_ID_HERE') on conflict do nothing;

-- Product records below are real, non-prescription skincare products. Verify local availability and price before publishing.
insert into public.products (name, brand, category, concerns, skin_types, description, product_url, is_active)
values
  ('Hydrating Facial Cleanser', 'CeraVe', 'skin', array['dryness','redness','sensitive'], array['normal','dry','sensitive'], 'Gentle cleanser for normal to dry skin.', 'https://www.cerave.com/skincare/cleansers/hydrating-facial-cleanser', true),
  ('Cicaplast Baume B5+', 'La Roche-Posay', 'skin', array['dryness','redness','sensitive'], array['dry','sensitive'], 'Soothing multi-purpose balm for compromised skin barrier support.', 'https://www.laroche-posay.us/our-products/face/face-moisturizer/cicaplast-baume-b5-for-dry-skin-3337872412998.html', true),
  ('Niacinamide 10% + Zinc 1%', 'The Ordinary', 'skin', array['oiliness','acne','texture'], array['oily','combination'], 'Water-based serum for blemish-prone skin.', 'https://theordinary.com/en-us/niacinamide-10-zinc-1-serum-100436.html', true)
on conflict (brand, name) do nothing;
