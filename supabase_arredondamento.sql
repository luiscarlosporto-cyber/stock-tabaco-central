-- Regras de compra (26/10/2026): VEEV ONE em volumes de 6 e arredondamento com memória.
-- Colar no SQL Editor do Supabase e carregar em Run. Pode ser corrido mais do que uma vez.

-- 1. VEEV ONE: volumes de 6 unidades (incluindo os que não têm código de volume no catálogo).
update public.products set volume_size = 6
where name like 'VEEV ONE%' and volume_size is distinct from 6;

-- 2. Saldo do arredondamento por artigo, em volumes.
--    Ex.: precisa 4,5 volumes, compra 5, fica +0,5; na encomenda seguinte desconta-se 0,5.
alter table public.products add column if not exists order_carry numeric not null default 0;

-- 3. Guarda o saldo de cada artigo depois de uma encomenda ser enviada.
--    Corre com as permissões de quem chama: só um administrador consegue alterar produtos (RLS).
create or replace function public.apply_order_carry(p_lines jsonb)
returns integer language sql security invoker set search_path = public as $$
  with v as (
    select x.id, greatest(-1, least(1, x.carry)) as carry
    from jsonb_to_recordset(p_lines) as x(id text, carry numeric)
  ), u as (
    update public.products p set order_carry = v.carry from v where p.id = v.id returning 1
  )
  select count(*)::integer from u;
$$;
revoke execute on function public.apply_order_carry(jsonb) from anon, public;
grant execute on function public.apply_order_carry(jsonb) to authenticated;

-- Verificação.
select name, category, volume_size, order_carry from public.products
where category in ('Tabaco aquecido', 'Cigarros eletrónicos') order by category, name;
