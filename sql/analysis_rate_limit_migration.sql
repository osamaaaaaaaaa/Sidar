-- Server-side quota for the paid Gemini analysis endpoint.
-- A user can create at most 8 analyses per rolling hour. The browser has no
-- direct table access; only the authenticated RPC below can consume a slot.

create table if not exists public.analysis_rate_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0 check (request_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.analysis_rate_limits enable row level security;

create or replace function public.consume_analysis_quota()
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  current_user_id uuid := auth.uid();
  is_allowed boolean;
begin
  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  insert into public.analysis_rate_limits (user_id, window_started_at, request_count, updated_at)
  values (current_user_id, now(), 1, now())
  on conflict (user_id) do update
  set
    window_started_at = case
      when public.analysis_rate_limits.window_started_at <= now() - interval '1 hour' then now()
      else public.analysis_rate_limits.window_started_at
    end,
    request_count = case
      when public.analysis_rate_limits.window_started_at <= now() - interval '1 hour' then 1
      else public.analysis_rate_limits.request_count + 1
    end,
    updated_at = now()
  returning request_count <= 8 into is_allowed;

  return is_allowed;
end;
$$;

revoke all on table public.analysis_rate_limits from public, anon, authenticated;
revoke all on function public.consume_analysis_quota() from public, anon;
grant execute on function public.consume_analysis_quota() to authenticated;
