-- Morada de entrega, ligação ao mapa e nº de cliente na Logista, por loja (aparecem no PDF da encomenda). Só acrescenta.
-- Aplicado a 01/11/2026.
alter table public.companies add column if not exists morada_entrega text not null default '';
alter table public.companies add column if not exists mapa_url text not null default '';
alter table public.companies add column if not exists cliente_logista text not null default '';
update public.companies set morada_entrega = 'Rua da Misericórdia 244, 4780-501 Santo Tirso', mapa_url = 'https://maps.app.goo.gl/2Jh87aiSzoxVamwD7', cliente_logista = '277359' where id = 'sto';
update public.companies set morada_entrega = 'Circular Sul de Penafiel S/N, 4560-232 Penafiel', mapa_url = 'https://maps.app.goo.gl/6EKRpMAxmLvazRVN7', cliente_logista = '287016' where id = 'pnf';
