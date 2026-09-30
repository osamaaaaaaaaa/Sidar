create extension if not exists "pgcrypto";

alter table public.profiles
  add column if not exists location_text text,
  add column if not exists notifications_enabled boolean default true;

alter table public.profiles
  alter column preferred_language set default 'en';

alter table public.scan_sessions
  add column if not exists report_title text,
  add column if not exists issue_type text,
  add column if not exists concern_category text,
  add column if not exists analysis_target text,
  add column if not exists problem_description text,
  add column if not exists overall_score numeric(5,2),
  add column if not exists hydration_score numeric(5,2),
  add column if not exists pore_clarity_score numeric(5,2),
  add column if not exists fine_lines_score numeric(5,2),
  add column if not exists overall_tone_score numeric(5,2),
  add column if not exists hair_density_score numeric(5,2),
  add column if not exists hair_texture_score numeric(5,2),
  add column if not exists hair_strength_score numeric(5,2),
  add column if not exists scalp_health_score numeric(5,2),
  add column if not exists morning_routine text[] default '{}'::text[],
  add column if not exists evening_routine text[] default '{}'::text[],
  add column if not exists natural_product_suggestions jsonb default '[]'::jsonb,
  add column if not exists commercial_product_suggestions jsonb default '[]'::jsonb,
  add column if not exists nearby_doctors jsonb default '[]'::jsonb,
  add column if not exists raw_ai_response jsonb default '{}'::jsonb,
  add column if not exists status text default 'completed';

alter table public.scan_sessions
  drop constraint if exists scan_sessions_analysis_target_check,
  add constraint scan_sessions_analysis_target_check check (analysis_target in ('skin', 'hair', 'both'));

alter table public.scan_sessions
  drop constraint if exists scan_sessions_status_check,
  add constraint scan_sessions_status_check check (status in ('pending', 'processing', 'completed', 'failed'));

alter table public.scan_images
  add column if not exists sort_order integer default 0;

alter table public.scan_findings
  add column if not exists severity text,
  add column if not exists category text,
  add column if not exists created_at timestamptz default now();

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
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.handle_updated_at();

drop trigger if exists trg_scan_sessions_updated_at on public.scan_sessions;
create trigger trg_scan_sessions_updated_at
before update on public.scan_sessions
for each row execute function public.handle_updated_at();

drop trigger if exists trg_wellness_plans_updated_at on public.wellness_plans;
create trigger trg_wellness_plans_updated_at
before update on public.wellness_plans
for each row execute function public.handle_updated_at();

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
create policy "Users can view own profile"
on public.profiles for select
using (auth.uid() = id);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
on public.profiles for insert
with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can view own scan sessions" on public.scan_sessions;
create policy "Users can view own scan sessions"
on public.scan_sessions for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own scan sessions" on public.scan_sessions;
create policy "Users can insert own scan sessions"
on public.scan_sessions for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own scan sessions" on public.scan_sessions;
create policy "Users can update own scan sessions"
on public.scan_sessions for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can delete own scan sessions" on public.scan_sessions;
create policy "Users can delete own scan sessions"
on public.scan_sessions for delete
using (auth.uid() = user_id);

drop policy if exists "Users can view own scan images" on public.scan_images;
create policy "Users can view own scan images"
on public.scan_images for select
using (
  exists (
    select 1 from public.scan_sessions s
    where s.id = scan_images.scan_id
    and s.user_id = auth.uid()
  )
);

drop policy if exists "Users can insert own scan images" on public.scan_images;
create policy "Users can insert own scan images"
on public.scan_images for insert
with check (
  exists (
    select 1 from public.scan_sessions s
    where s.id = scan_images.scan_id
    and s.user_id = auth.uid()
  )
);

drop policy if exists "Users can view own scan findings" on public.scan_findings;
create policy "Users can view own scan findings"
on public.scan_findings for select
using (
  exists (
    select 1 from public.scan_sessions s
    where s.id = scan_findings.scan_id
    and s.user_id = auth.uid()
  )
);

drop policy if exists "Users can insert own scan findings" on public.scan_findings;
create policy "Users can insert own scan findings"
on public.scan_findings for insert
with check (
  exists (
    select 1 from public.scan_sessions s
    where s.id = scan_findings.scan_id
    and s.user_id = auth.uid()
  )
);

drop policy if exists "Users can view own plan" on public.wellness_plans;
create policy "Users can view own plan"
on public.wellness_plans for select
using (auth.uid() = user_id);

drop policy if exists "Users can insert own plan" on public.wellness_plans;
create policy "Users can insert own plan"
on public.wellness_plans for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can update own plan" on public.wellness_plans;
create policy "Users can update own plan"
on public.wellness_plans for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('scan-images', 'scan-images', false, 10485760, array['image/png', 'image/jpeg', 'image/webp'])
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
