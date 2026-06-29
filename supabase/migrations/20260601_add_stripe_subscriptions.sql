alter table public.pricing_plans
add column if not exists stripe_price_id text unique;

create table if not exists public.user_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  plan_id uuid not null references public.pricing_plans(id) on delete restrict,
  plan_name text,
  stripe_customer_id text,
  stripe_subscription_id text unique,
  status text not null default 'active' check (status in ('active', 'trialing', 'past_due', 'canceled', 'incomplete', 'unpaid')),
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_subscriptions enable row level security;

drop policy if exists "user_can_read_own_subscription" on public.user_subscriptions;

create policy "user_can_read_own_subscription"
on public.user_subscriptions
for select
to authenticated
using (auth.uid() = user_id);

