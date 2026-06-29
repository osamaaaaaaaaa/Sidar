-- Internal-only provider telemetry. It deliberately excludes prompts, chat
-- messages, images, and other user content.
create table if not exists public.ai_model_audit (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  feature text not null check (feature in ('analysis', 'chat')),
  provider text not null default 'google',
  model_name text not null,
  status text not null check (status in ('success', 'error')),
  response_kind text not null,
  provider_status integer,
  latency_ms integer check (latency_ms >= 0),
  input_kind text not null,
  input_count integer check (input_count >= 0)
);

alter table public.ai_model_audit enable row level security;
revoke all on table public.ai_model_audit from anon, authenticated;

create index if not exists ai_model_audit_created_at_idx
  on public.ai_model_audit (created_at desc);
