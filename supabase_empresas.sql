-- NexStock: duas empresas (REPSOL SANTO TIRSO e REPSOL PENAFIEL CIRCULAR).
-- Correr de uma vez no SQL Editor do Supabase. Só acrescenta: não apaga colunas nem linhas.
-- Os dados atuais ficam todos em Santo Tirso ('sto'). Penafiel ('pnf') começa com stock 0.
-- As colunas antigas de products (stock, sales_month, sales_days, order_carry) continuam a ser
-- atualizadas para Santo Tirso, para se poder voltar à versão anterior da app sem perder nada.

begin;

-- 1. Cópias de segurança
create table if not exists public.products_backup_20261027 as select * from public.products;
create table if not exists public.stock_moves_backup_20261027 as select * from public.stock_moves;
create table if not exists public.orders_backup_20261027 as select * from public.orders;
create table if not exists public.profiles_backup_20261027 as select * from public.profiles;
alter table public.products_backup_20261027 enable row level security;
alter table public.stock_moves_backup_20261027 enable row level security;
alter table public.orders_backup_20261027 enable row level security;
alter table public.profiles_backup_20261027 enable row level security;

-- 2. Empresas. Os emails não são segredos; as palavras-passe ficam nos secrets das funções.
--    gmail_suffix escolhe os secrets: '' -> GMAIL_USER/GMAIL_APP_PASSWORD,
--    '_PENAFIEL' -> GMAIL_USER_PENAFIEL/GMAIL_APP_PASSWORD_PENAFIEL.
create table if not exists public.companies (
  id text primary key,
  name text not null,
  short_name text not null,
  email_empresa text not null default '',
  email_tabaco text not null default '',
  email_aquecido text not null default '',
  gmail_suffix text not null default '',
  sort integer not null default 0
);
insert into public.companies (id, name, short_name, email_empresa, gmail_suffix, sort) values
  ('sto', 'REPSOL SANTO TIRSO', 'Santo Tirso', 'portojoaonuneslda@gmail.com', '', 1),
  ('pnf', 'REPSOL PENAFIEL CIRCULAR', 'Penafiel', 'portonuneslda@gmail.com', '_PENAFIEL', 2)
on conflict (id) do nothing;
-- Enquanto se testa, as encomendas de Penafiel vão para o email do Luís.
update public.companies set email_tabaco = 'luiscarlosporto@gmail.com', email_aquecido = 'luiscarlosporto@gmail.com'
where id = 'pnf' and email_tabaco = '' and email_aquecido = '';

-- 3. Utilizadores por empresa. As contas atuais ficam em Santo Tirso; o administrador vê as duas.
alter table public.profiles add column if not exists company_id text not null default 'sto' references public.companies(id);
-- Lojas a mais a que a conta também tem acesso (ex.: quem trabalha nas duas). Ex.: update public.profiles
-- set other_companies = '{pnf}' where display_name = 'Carlos';
alter table public.profiles add column if not exists other_companies text[] not null default '{}';

create or replace function public.my_company() returns text
language sql stable security definer set search_path = public as $$
  select company_id from public.profiles where user_id = auth.uid();
$$;
create or replace function public.can_company(c text) returns boolean
language sql stable security definer set search_path = public as $$
  select public.is_admin() or exists (
    select 1 from public.profiles where user_id = auth.uid() and (company_id = c or c = any(other_companies)));
$$;
revoke execute on function public.my_company() from anon, public;
revoke execute on function public.can_company(text) from anon, public;
grant execute on function public.my_company() to authenticated;
grant execute on function public.can_company(text) to authenticated;

alter table public.companies enable row level security;
drop policy if exists "companies read" on public.companies;
drop policy if exists "companies admin" on public.companies;
create policy "companies read" on public.companies for select to authenticated using (public.can_company(id));
create policy "companies admin" on public.companies for update to authenticated using (public.is_admin()) with check (public.is_admin());
revoke all on public.companies from anon;
grant select, update on public.companies to authenticated;

-- 4. Stock, vendas e acerto por empresa. maquina = reposto pela ADELAIDE na máquina de tabaco:
--    nessa loja não tem stock nem entra em encomendas.
create table if not exists public.product_company (
  product_id text not null references public.products(id) on delete cascade,
  company_id text not null references public.companies(id),
  stock integer not null default 0 check (stock >= 0),
  sales_month numeric,
  sales_days integer not null default 0,
  order_carry numeric not null default 0,
  maquina boolean not null default false,
  primary key (product_id, company_id)
);
insert into public.product_company (product_id, company_id, stock, sales_month, sales_days, order_carry)
select id, 'sto', stock, sales_month, coalesce(sales_days, 0), coalesce(order_carry, 0) from public.products
on conflict do nothing;
insert into public.product_company (product_id, company_id)
select p.id, c.id from public.products p cross join public.companies c where c.id <> 'sto'
on conflict do nothing;

-- Cada artigo novo do catálogo ganha uma linha em todas as empresas (Santo Tirso com o stock indicado).
create or replace function public.product_company_new() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.product_company (product_id, company_id, stock)
  select new.id, c.id, case when c.id = 'sto' then coalesce(new.stock, 0) else 0 end from public.companies c
  on conflict do nothing;
  return new;
end;
$$;
drop trigger if exists product_company_new on public.products;
create trigger product_company_new after insert on public.products
for each row execute function public.product_company_new();

alter table public.product_company enable row level security;
drop policy if exists "pc read" on public.product_company;
drop policy if exists "pc admin update" on public.product_company;
create policy "pc read" on public.product_company for select to authenticated using (public.can_company(company_id));
create policy "pc admin update" on public.product_company for update to authenticated using (public.is_admin()) with check (public.is_admin());
revoke all on public.product_company from anon;
grant select, update on public.product_company to authenticated;

-- 5. Movimentos e encomendas por empresa
alter table public.stock_moves add column if not exists company_id text not null default 'sto' references public.companies(id);
alter table public.orders add column if not exists company_id text not null default 'sto' references public.companies(id);
create index if not exists stock_moves_company_created on public.stock_moves (company_id, created_at desc);
create index if not exists orders_company_status on public.orders (company_id, status);

drop policy if exists "auth read moves" on public.stock_moves;
create policy "auth read moves" on public.stock_moves for select to authenticated using (public.can_company(company_id));

drop policy if exists "orders read" on public.orders;
drop policy if exists "orders insert" on public.orders;
drop policy if exists "orders update" on public.orders;
create policy "orders read" on public.orders for select to authenticated
  using (public.can_company(company_id) and (created_by = auth.uid() or public.is_admin()));
create policy "orders insert" on public.orders for insert to authenticated
  with check (public.can_company(company_id) and created_by = auth.uid() and status = 'pendente' and sent_at is null and approved_by is null);
create policy "orders update" on public.orders for update to authenticated
  using (status = 'pendente' and public.can_company(company_id) and (created_by = auth.uid() or public.is_admin()))
  with check (public.can_company(company_id) and (public.is_admin() or (status = 'pendente' and sent_at is null and approved_by is null)));

-- 6. Movimentos de stock por empresa
create or replace function public.register_stock_move(
  p_company text,
  p_product_id text,
  p_move_type text,
  p_quantity integer,
  p_note text default '',
  p_operator text default ''
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  p public.products%rowtype;
  pc public.product_company%rowtype;
  after_stock integer;
  m public.stock_moves%rowtype;
begin
  if auth.uid() is null then
    raise exception 'Sessão obrigatória';
  end if;
  if not public.can_company(p_company) then
    raise exception 'Sem acesso a esta loja';
  end if;
  if p_move_type not in ('Entrada','Saída','Contagem') then
    raise exception 'Tipo de movimento inválido';
  end if;
  if p_move_type <> 'Saída' and not public.is_admin() then
    raise exception 'Só o administrador pode registar entradas e contagens';
  end if;
  if p_quantity < 0 or (p_move_type <> 'Contagem' and p_quantity = 0) then
    raise exception 'Quantidade inválida';
  end if;
  select * into p from public.products where id = p_product_id;
  if not found then raise exception 'Produto não encontrado'; end if;
  select * into pc from public.product_company where product_id = p_product_id and company_id = p_company for update;
  if not found then raise exception 'Produto não encontrado nesta loja'; end if;
  if pc.maquina then raise exception 'Artigo da máquina de tabaco: não tem stock nesta loja'; end if;
  if p_move_type = 'Saída' then
    if pc.stock < p_quantity then raise exception 'Stock insuficiente'; end if;
    after_stock := pc.stock - p_quantity;
  elsif p_move_type = 'Entrada' then
    after_stock := pc.stock + p_quantity;
  else
    after_stock := p_quantity;
  end if;
  update public.product_company set stock = after_stock where product_id = p_product_id and company_id = p_company;
  if p_company = 'sto' then
    update public.products set stock = after_stock where id = p_product_id;
  end if;
  insert into public.stock_moves(product_id, product_name, barcode, move_type, quantity, stock_before, stock_after, note, operator, user_id, company_id)
  values (p.id, p.name, p.barcode, p_move_type, p_quantity, pc.stock, after_stock, coalesce(p_note,''), coalesce(p_operator,''), auth.uid(), p_company) returning * into m;
  return json_build_object('id',m.id,'stock_before',m.stock_before,'stock_after',m.stock_after);
end;
$$;
revoke execute on function public.register_stock_move(text,text,text,integer,text,text) from anon, public;
grant execute on function public.register_stock_move(text,text,text,integer,text,text) to authenticated;

-- A versão antiga (app ainda em cache) passa a registar na loja do utilizador.
create or replace function public.register_stock_move(
  p_product_id text,
  p_move_type text,
  p_quantity integer,
  p_note text default '',
  p_operator text default ''
) returns json
language sql
security definer
set search_path = public
as $$
  select public.register_stock_move(coalesce(public.my_company(), 'sto'), p_product_id, p_move_type, p_quantity, p_note, p_operator);
$$;
revoke execute on function public.register_stock_move(text,text,integer,text,text) from anon, public;
grant execute on function public.register_stock_move(text,text,integer,text,text) to authenticated;

-- 7. Acerto do arredondamento por empresa
create or replace function public.apply_order_carry(p_lines jsonb, p_company text)
returns integer language plpgsql security invoker set search_path = public as $$
declare n integer;
begin
  with v as (
    select x.id, greatest(-1, least(1, x.carry)) as carry
    from jsonb_to_recordset(p_lines) as x(id text, carry numeric)
  ), u as (
    update public.product_company pc set order_carry = v.carry from v
    where pc.product_id = v.id and pc.company_id = p_company returning 1
  )
  select count(*)::integer into n from u;
  if p_company = 'sto' then
    update public.products p set order_carry = greatest(-1, least(1, x.carry))
    from jsonb_to_recordset(p_lines) as x(id text, carry numeric) where p.id = x.id;
  end if;
  return n;
end;
$$;
revoke execute on function public.apply_order_carry(jsonb, text) from anon, public;
grant execute on function public.apply_order_carry(jsonb, text) to authenticated;

create or replace function public.apply_order_carry(p_lines jsonb)
returns integer language sql security invoker set search_path = public as $$
  select public.apply_order_carry(p_lines, 'sto');
$$;
revoke execute on function public.apply_order_carry(jsonb) from anon, public;
grant execute on function public.apply_order_carry(jsonb) to authenticated;

-- 8. Vendas por empresa, a partir do CSV de vendas carregado na app. Só substitui as vendas guardadas
--    quando o ficheiro cobre pelo menos tantos dias como as atuais (um mês não é trocado por uma semana).
create or replace function public.set_company_sales(p_company text, p_days integer, p_rows jsonb)
returns integer language plpgsql security invoker set search_path = public as $$
declare n integer;
begin
  if not public.is_admin() then raise exception 'Só o administrador pode guardar vendas'; end if;
  if p_days is null or p_days < 1 then raise exception 'Dias inválidos'; end if;
  with v as (select x.id, x.qty from jsonb_to_recordset(p_rows) as x(id text, qty numeric)),
  u as (
    update public.product_company pc set sales_month = v.qty, sales_days = p_days from v
    where pc.product_id = v.id and pc.company_id = p_company and pc.sales_days <= p_days returning pc.product_id
  ), w as (
    update public.products p set sales_month = v.qty, sales_days = p_days from v
    where p_company = 'sto' and p.id = v.id and p.id in (select product_id from u) returning 1
  )
  select count(*)::integer into n from u;
  return n;
end;
$$;
revoke execute on function public.set_company_sales(text, integer, jsonb) from anon, public;
grant execute on function public.set_company_sales(text, integer, jsonb) to authenticated;

commit;

-- 9. O Carlos trabalha nas duas lojas: tirar o "--" da linha abaixo e pôr o nome exatamente como aparece na
--    lista de contas no fim deste ficheiro. As contas novas de Penafiel: depois de criadas, mudar company_id para 'pnf'.
-- update public.profiles set other_companies = '{pnf}' where display_name = 'Carlos';

-- 10. Verificação: as duas linhas de cada par têm de ser iguais.
select 'stock Santo Tirso (antes)' as o, sum(stock) from public.products_backup_20261027
union all select 'stock Santo Tirso (agora)', sum(stock) from public.product_company where company_id = 'sto'
union all select 'artigos (antes)', count(*) from public.products_backup_20261027
union all select 'artigos em cada loja', count(*) / 2 from public.product_company
union all select 'movimentos (antes)', count(*) from public.stock_moves_backup_20261027
union all select 'movimentos Santo Tirso', count(*) from public.stock_moves where company_id = 'sto'
union all select 'stock Penafiel', sum(stock) from public.product_company where company_id = 'pnf';

select display_name, role, company_id, other_companies from public.profiles order by display_name;
