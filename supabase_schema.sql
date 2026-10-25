-- Stock Tabaco Central - executar no SQL Editor do Supabase
create extension if not exists pgcrypto;

create table if not exists public.products (
  id text primary key,
  name text not null,
  category text not null default 'Outros',
  barcode text unique,
  stock integer not null default 0 check (stock >= 0),
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.stock_moves (
  id uuid primary key default gen_random_uuid(),
  product_id text not null references public.products(id),
  product_name text not null,
  barcode text,
  move_type text not null check (move_type in ('Entrada','Saída','Contagem')),
  quantity integer not null check (quantity >= 0),
  stock_before integer not null,
  stock_after integer not null check (stock_after >= 0),
  note text not null default '',
  operator text not null default '',
  created_at timestamptz not null default now()
);

alter table public.products enable row level security;
alter table public.stock_moves enable row level security;

-- IMPORTANTE: Estas políticas permitem acesso público à chave anon.
-- Não as use numa loja real sem autenticação. Para produção, configurar Supabase Auth
-- e políticas RLS que limitem acesso aos utilizadores autorizados.
create policy "demo read products" on public.products for select to anon, authenticated using (true);
create policy "demo insert products" on public.products for insert to anon, authenticated with check (true);
create policy "demo update products" on public.products for update to anon, authenticated using (true) with check (true);
create policy "demo read moves" on public.stock_moves for select to anon, authenticated using (true);

create or replace function public.register_stock_move(
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
  after_stock integer;
  m public.stock_moves%rowtype;
begin
  if p_move_type not in ('Entrada','Saída','Contagem') then
    raise exception 'Tipo de movimento inválido';
  end if;
  if p_quantity < 0 or (p_move_type <> 'Contagem' and p_quantity = 0) then
    raise exception 'Quantidade inválida';
  end if;
  select * into p from public.products where id = p_product_id for update;
  if not found then raise exception 'Produto não encontrado'; end if;
  if p_move_type = 'Saída' then
    if p.stock < p_quantity then raise exception 'Stock insuficiente'; end if;
    after_stock := p.stock - p_quantity;
  elsif p_move_type = 'Entrada' then
    after_stock := p.stock + p_quantity;
  else
    after_stock := p_quantity;
  end if;
  update public.products set stock = after_stock where id = p_product_id;
  insert into public.stock_moves(product_id, product_name, barcode, move_type, quantity, stock_before, stock_after, note, operator)
  values (p.id, p.name, p.barcode, p_move_type, p_quantity, p.stock, after_stock, coalesce(p_note,''), coalesce(p_operator,'')) returning * into m;
  return json_build_object('id',m.id,'stock_before',m.stock_before,'stock_after',m.stock_after);
end;
$$;

grant execute on function public.register_stock_move(text,text,integer,text,text) to anon, authenticated;
grant select, insert, update on public.products to anon, authenticated;
grant select on public.stock_moves to anon, authenticated;

-- Inserir catálogo inicial é opcional: pode importar CSV ou inserir os produtos pela aplicação.
