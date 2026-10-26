-- Correção de segurança Stock Tabaco Central.
-- NÃO executar sem backup. Executar no SQL Editor depois do esquema e do patch de permissões.
-- Assume que public.profiles tem as colunas user_id (uuid de auth.users) e role ('admin' ou 'staff').

-- 0. Ver as políticas atuais antes de mudar (políticas permissivas somam-se: rever as de profiles).
-- select tablename, policyname, roles, cmd, qual, with_check from pg_policies where schemaname = 'public';

-- 1. Fechar a função de movimentos a quem não tem sessão.
revoke execute on function public.register_stock_move(text,text,integer,text,text) from anon, public;
grant execute on function public.register_stock_move(text,text,integer,text,text) to authenticated;

-- 2. Função auxiliar para saber se o utilizador atual é admin.
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.profiles where user_id = auth.uid() and role = 'admin');
$$;
revoke execute on function public.is_admin() from anon, public;
grant execute on function public.is_admin() to authenticated;

-- 3. Substituir as políticas de demonstração.
drop policy if exists "demo read products" on public.products;
drop policy if exists "demo insert products" on public.products;
drop policy if exists "demo update products" on public.products;
drop policy if exists "demo read moves" on public.stock_moves;

drop policy if exists "auth read products" on public.products;
drop policy if exists "admin insert products" on public.products;
drop policy if exists "admin update products" on public.products;
drop policy if exists "auth read moves" on public.stock_moves;
create policy "auth read products" on public.products for select to authenticated using (true);
create policy "admin insert products" on public.products for insert to authenticated with check (public.is_admin());
create policy "admin update products" on public.products for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "auth read moves" on public.stock_moves for select to authenticated using (true);

-- 4. Perfis: cada utilizador lê o seu; só o SQL Editor atribui funções.
alter table public.profiles enable row level security;
drop policy if exists "read own profile" on public.profiles;
create policy "read own profile" on public.profiles for select to authenticated using (user_id = auth.uid() or public.is_admin());
revoke insert, update, delete on public.profiles from authenticated, anon;
