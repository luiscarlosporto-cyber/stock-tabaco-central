-- Propostas de encomenda ao fornecedor. Executar no SQL Editor do Supabase depois de supabase_rls_fix.sql.
-- Pode ser corrido mais de uma vez. Não altera produtos nem movimentos.
-- Fluxo: ao enviar a contagem, a app cria uma proposta (pendente). Um administrador revê, ajusta
-- e aprova; a Edge Function enviar-encomenda manda o PDF ao fornecedor e marca-a como enviada.
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  created_by uuid not null default auth.uid() references auth.users(id),
  operator text not null default '',
  status text not null default 'pendente' check (status in ('pendente','enviada','cancelada')),
  lines jsonb not null default '[]'::jsonb,
  count_lines jsonb,
  approved_by uuid references auth.users(id),
  sent_at timestamptz,
  sent_to text
);
alter table public.orders enable row level security;

drop policy if exists "orders read" on public.orders;
drop policy if exists "orders insert" on public.orders;
drop policy if exists "orders update" on public.orders;
-- Quem conta vê as suas propostas; o administrador vê todas.
create policy "orders read" on public.orders for select to authenticated
  using (created_by = auth.uid() or public.is_admin());
-- Qualquer utilizador com sessão cria uma proposta, sempre pendente e em seu nome.
create policy "orders insert" on public.orders for insert to authenticated
  with check (created_by = auth.uid() and status = 'pendente' and sent_at is null and approved_by is null);
-- Uma proposta pendente pode ser corrigida por quem a criou; aprovar, cancelar e marcar como enviada é só do administrador.
create policy "orders update" on public.orders for update to authenticated
  using (status = 'pendente' and (created_by = auth.uid() or public.is_admin()))
  with check (public.is_admin() or (status = 'pendente' and sent_at is null and approved_by is null));

revoke all on public.orders from anon;
grant select, insert, update on public.orders to authenticated;
