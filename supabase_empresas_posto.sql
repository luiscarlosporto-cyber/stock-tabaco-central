-- Código do posto no software Repsol (relatório de vendas: "Posto: E1344 - E.S. STO. TIRSO"). Só acrescenta. Aplicado a 01/11/2026.
alter table public.companies add column if not exists posto_repsol text not null default '';
update public.companies set posto_repsol = 'E1344' where id = 'sto';
