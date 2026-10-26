-- Cigarrilhas encomendadas em volumes (26/10/2026).
-- Camel Activate Double C/17 e Chesterfield Red Filter C/17: 10 unidades por volume.
-- Camel Activate Purple C/10 fica com 20 por volume, como no catálogo Repsol.
update public.products set volume_size = 10
where repsol_code in ('59810151', '59810080') and volume_size is distinct from 10;
select name, volume_size from public.products where category = 'Cigarrilhas' order by name;
