-- SIDAR uses USD as its only catalog currency.
-- Run once in the Supabase SQL Editor.

alter table public.products
  alter column currency set default 'USD';

alter table public.companies
  alter column support_currency set default 'USD';

-- Existing entries are now authored/displayed as USD values.
update public.products
set currency = 'USD'
where currency is distinct from 'USD';

update public.companies
set support_currency = 'USD'
where support_currency is distinct from 'USD';
