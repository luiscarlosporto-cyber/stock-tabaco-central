-- Regras de movimentos Stock Tabaco Central.
-- Executar no SQL Editor DEPOIS de supabase_rls_fix.sql (usa public.is_admin()). Fazer backup antes.
-- Efeito: só utilizadores com sessão registam movimentos; Entrada e Contagem só para admin;
-- cada movimento passa a guardar o utilizador que o fez (user_id).

alter table public.stock_moves add column if not exists user_id uuid default auth.uid();

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
  if auth.uid() is null then
    raise exception 'Sessão obrigatória';
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
  insert into public.stock_moves(product_id, product_name, barcode, move_type, quantity, stock_before, stock_after, note, operator, user_id)
  values (p.id, p.name, p.barcode, p_move_type, p_quantity, p.stock, after_stock, coalesce(p_note,''), coalesce(p_operator,''), auth.uid()) returning * into m;
  return json_build_object('id',m.id,'stock_before',m.stock_before,'stock_after',m.stock_after);
end;
$$;

revoke execute on function public.register_stock_move(text,text,integer,text,text) from anon, public;
grant execute on function public.register_stock_move(text,text,integer,text,text) to authenticated;
