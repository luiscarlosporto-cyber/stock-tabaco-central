-- Observações livres da encomenda (aparecem no PDF e no email ao fornecedor). Só acrescenta. Aplicado a 01/11/2026.
alter table public.orders add column if not exists notes text not null default '';
