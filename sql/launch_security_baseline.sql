-- SIDAR launch security baseline.
-- Run AFTER production_schema.sql, provider_catalog_migration.sql,
-- account_management_migration.sql, privacy_hardening_migration.sql,
-- analysis_rate_limit_migration.sql, and the admin dashboard migration.
-- This is intentionally safe to rerun and repairs an accidental development
-- setting that disabled Row Level Security.

alter table if exists public.admin_users enable row level security;
alter table if exists public.profiles enable row level security;
alter table if exists public.scan_sessions enable row level security;
alter table if exists public.scan_images enable row level security;
alter table if exists public.scan_findings enable row level security;
alter table if exists public.wellness_plans enable row level security;
alter table if exists public.doctors enable row level security;
alter table if exists public.products enable row level security;
alter table if exists public.appointments enable row level security;
alter table if exists public.companies enable row level security;
alter table if exists public.partnerships enable row level security;
alter table if exists public.pricing_plans enable row level security;
alter table if exists public.notifications enable row level security;
alter table if exists public.faqs enable row level security;
alter table if exists public.platform_settings enable row level security;
alter table if exists public.analysis_rate_limits enable row level security;

-- Remove any legacy/public policies from the sensitive account and analysis
-- tables, then install the exact allow-list required by the client/admin apps.
do $$
declare
  target_table text;
  existing_policy record;
begin
  foreach target_table in array array['profiles', 'scan_sessions', 'scan_images', 'scan_findings', 'wellness_plans']
  loop
    for existing_policy in
      select policyname from pg_policies where schemaname = 'public' and tablename = target_table
    loop
      execute format('drop policy if exists %I on public.%I', existing_policy.policyname, target_table);
    end loop;
  end loop;
end;
$$;

create policy "Users can view own profile" on public.profiles for select to authenticated using (auth.uid() = id);
create policy "Users can insert own profile" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);
create policy "Admins manage profiles" on public.profiles for all to authenticated using (public.is_sidar_admin()) with check (public.is_sidar_admin());

create policy "Users can view own scan sessions" on public.scan_sessions for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert own scan sessions" on public.scan_sessions for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update own scan sessions" on public.scan_sessions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own scan sessions" on public.scan_sessions for delete to authenticated using (auth.uid() = user_id);
create policy "Admins read all scans" on public.scan_sessions for select to authenticated using (public.is_sidar_admin());

create policy "Users can view own scan images" on public.scan_images for select to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can insert own scan images" on public.scan_images for insert to authenticated with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can update own scan images" on public.scan_images for update to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can delete own scan images" on public.scan_images for delete to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));

create policy "Users can view own scan findings" on public.scan_findings for select to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can insert own scan findings" on public.scan_findings for insert to authenticated with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can update own scan findings" on public.scan_findings for update to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can delete own scan findings" on public.scan_findings for delete to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));

create policy "Users can view own plan" on public.wellness_plans for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert own plan" on public.wellness_plans for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update own plan" on public.wellness_plans for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Admins read all wellness plans" on public.wellness_plans for select to authenticated using (public.is_sidar_admin());

revoke all on function public.is_sidar_admin() from public;
grant execute on function public.is_sidar_admin() to authenticated, anon;
revoke all on function public.consume_analysis_quota() from public, anon;
grant execute on function public.consume_analysis_quota() to authenticated;
revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;

-- Analysis image privacy is non-negotiable, even if an earlier deployment
-- accidentally made the bucket public.
update storage.buckets set public = false where id = 'scan-images';
