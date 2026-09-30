create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text,
  language text default 'en' check (language in ('en', 'ar')),
  skin_goals text,
  avatar_url text,
  age integer,
  gender text,
  height double precision,
  weight double precision,
  skin_type text,
  allergies text,
  medications text,
  sun_sensitive boolean default false,
  preferred_language text default 'en',
  location_text text,
  notifications_enabled boolean default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scan_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text,
  report_title text,
  scan_type text not null,
  body_location text,
  symptoms text[] default '{}',
  duration text,
  severity text,
  notes text,
  issue_type text,
  concern_category text,
  analysis_target text check (analysis_target in ('skin', 'hair', 'both')),
  image_urls text[] default '{}',
  images_count integer default 0,
  language_code text default 'en' check (language_code in ('en', 'ar')),
  ai_confidence text,
  summary text,
  problem_description text,
  urgency text check (urgency in ('low', 'medium', 'high')),
  image_quality text,
  visible_findings text[] default '{}',
  care_steps text[] default '{}',
  reasons text[] default '{}',
  disclaimer text,
  overall_score numeric(5,2),
  hydration_score numeric(5,2),
  pore_clarity_score numeric(5,2),
  fine_lines_score numeric(5,2),
  overall_tone_score numeric(5,2),
  hair_density_score numeric(5,2),
  hair_texture_score numeric(5,2),
  hair_strength_score numeric(5,2),
  scalp_health_score numeric(5,2),
  morning_routine text[] default '{}',
  evening_routine text[] default '{}',
  natural_product_suggestions jsonb default '[]'::jsonb,
  commercial_product_suggestions jsonb default '[]'::jsonb,
  nearby_doctors jsonb default '[]'::jsonb,
  raw_ai_response jsonb default '{}'::jsonb,
  status text default 'completed' check (status in ('pending', 'processing', 'completed', 'failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.scan_images (
  id uuid primary key default gen_random_uuid(),
  scan_id uuid not null references public.scan_sessions(id) on delete cascade,
  image_url text not null,
  image_path text,
  sort_order integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.scan_findings (
  id uuid primary key default gen_random_uuid(),
  scan_id uuid not null references public.scan_sessions(id) on delete cascade,
  title text not null,
  description text,
  severity text,
  category text,
  sort_order integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.wellness_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  morning_routine text,
  evening_routine text,
  plan_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at before update on public.profiles for each row execute function public.handle_updated_at();
drop trigger if exists trg_scan_sessions_updated_at on public.scan_sessions;
create trigger trg_scan_sessions_updated_at before update on public.scan_sessions for each row execute function public.handle_updated_at();
drop trigger if exists trg_wellness_plans_updated_at on public.wellness_plans;
create trigger trg_wellness_plans_updated_at before update on public.wellness_plans for each row execute function public.handle_updated_at();

create index if not exists idx_scan_sessions_user_id on public.scan_sessions(user_id);
create index if not exists idx_scan_sessions_created_at on public.scan_sessions(created_at desc);
create index if not exists idx_scan_sessions_scan_type on public.scan_sessions(scan_type);
create index if not exists idx_scan_images_scan_id on public.scan_images(scan_id);
create index if not exists idx_scan_findings_scan_id on public.scan_findings(scan_id);

alter table public.profiles enable row level security;
alter table public.scan_sessions enable row level security;
alter table public.scan_images enable row level security;
alter table public.scan_findings enable row level security;
alter table public.wellness_plans enable row level security;

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile" on public.profiles for insert with check (auth.uid() = id);
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Users can view own scan sessions" on public.scan_sessions;
create policy "Users can view own scan sessions" on public.scan_sessions for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own scan sessions" on public.scan_sessions;
create policy "Users can insert own scan sessions" on public.scan_sessions for insert with check (auth.uid() = user_id);
drop policy if exists "Users can update own scan sessions" on public.scan_sessions;
create policy "Users can update own scan sessions" on public.scan_sessions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "Users can delete own scan sessions" on public.scan_sessions;
create policy "Users can delete own scan sessions" on public.scan_sessions for delete using (auth.uid() = user_id);

drop policy if exists "Users can view own scan images" on public.scan_images;
create policy "Users can view own scan images" on public.scan_images for select using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can insert own scan images" on public.scan_images;
create policy "Users can insert own scan images" on public.scan_images for insert with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can update own scan images" on public.scan_images;
create policy "Users can update own scan images" on public.scan_images for update using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can delete own scan images" on public.scan_images;
create policy "Users can delete own scan images" on public.scan_images for delete using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));

drop policy if exists "Users can view own scan findings" on public.scan_findings;
create policy "Users can view own scan findings" on public.scan_findings for select using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can insert own scan findings" on public.scan_findings;
create policy "Users can insert own scan findings" on public.scan_findings for insert with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can update own scan findings" on public.scan_findings;
create policy "Users can update own scan findings" on public.scan_findings for update using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
drop policy if exists "Users can delete own scan findings" on public.scan_findings;
create policy "Users can delete own scan findings" on public.scan_findings for delete using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));

drop policy if exists "Users can view own plan" on public.wellness_plans;
create policy "Users can view own plan" on public.wellness_plans for select using (auth.uid() = user_id);
drop policy if exists "Users can insert own plan" on public.wellness_plans;
create policy "Users can insert own plan" on public.wellness_plans for insert with check (auth.uid() = user_id);
drop policy if exists "Users can update own plan" on public.wellness_plans;
create policy "Users can update own plan" on public.wellness_plans for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('scan-images','scan-images',false,10485760,array['image/png','image/jpeg','image/webp'])
on conflict (id) do nothing;

drop policy if exists "Public can read scan images" on storage.objects;
drop policy if exists "Authenticated users can upload scan images" on storage.objects;
drop policy if exists "Authenticated users can update scan images" on storage.objects;
drop policy if exists "Authenticated users can delete scan images" on storage.objects;
drop policy if exists "Users can upload only to their scan-image folder" on storage.objects;
drop policy if exists "Users can read only their scan-image folder" on storage.objects;
drop policy if exists "Users can update only their scan-image folder" on storage.objects;
drop policy if exists "Users can delete only their scan-image folder" on storage.objects;

create policy "Users can upload only to their scan-image folder" on storage.objects for insert to authenticated
with check (bucket_id = 'scan-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can read only their scan-image folder" on storage.objects for select to authenticated
using (bucket_id = 'scan-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can update only their scan-image folder" on storage.objects for update to authenticated
using (bucket_id = 'scan-images' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'scan-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can delete only their scan-image folder" on storage.objects for delete to authenticated
using (bucket_id = 'scan-images' and (storage.foldername(name))[1] = auth.uid()::text);
