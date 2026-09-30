-- EMERGENCY: run this immediately in the Supabase SQL Editor if the anonymous
-- RLS audit can read scan_sessions, scan_images, or scan_findings.
-- It intentionally removes every legacy policy on those three sensitive tables
-- and restores only signed-in owner access. It is safe to rerun.

alter table if exists public.scan_sessions enable row level security;
alter table if exists public.scan_images enable row level security;
alter table if exists public.scan_findings enable row level security;

do $$
declare
  target_table text;
  existing_policy record;
begin
  foreach target_table in array array['scan_sessions', 'scan_images', 'scan_findings']
  loop
    for existing_policy in
      select policyname from pg_policies where schemaname = 'public' and tablename = target_table
    loop
      execute format('drop policy if exists %I on public.%I', existing_policy.policyname, target_table);
    end loop;
  end loop;
end;
$$;

create policy "Users can view own scan sessions" on public.scan_sessions for select to authenticated using (auth.uid() = user_id);
create policy "Users can insert own scan sessions" on public.scan_sessions for insert to authenticated with check (auth.uid() = user_id);
create policy "Users can update own scan sessions" on public.scan_sessions for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own scan sessions" on public.scan_sessions for delete to authenticated using (auth.uid() = user_id);

create policy "Users can view own scan images" on public.scan_images for select to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can insert own scan images" on public.scan_images for insert to authenticated with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can update own scan images" on public.scan_images for update to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));
create policy "Users can delete own scan images" on public.scan_images for delete to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_images.scan_id and s.user_id = auth.uid()));

create policy "Users can view own scan findings" on public.scan_findings for select to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can insert own scan findings" on public.scan_findings for insert to authenticated with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can update own scan findings" on public.scan_findings for update to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid())) with check (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));
create policy "Users can delete own scan findings" on public.scan_findings for delete to authenticated using (exists (select 1 from public.scan_sessions s where s.id = scan_findings.scan_id and s.user_id = auth.uid()));

-- Disable direct public object delivery for sensitive scan images immediately.
update storage.buckets set public = false where id = 'scan-images';
