-- Novas categorias e referências (relatório de vendas Repsol de 25/09 a 25/10/2026, 31 dias).
-- Acrescenta 68 artigos: tabaco aquecido, cigarros eletrónicos e o código Repsol das 3 cigarrilhas.
-- Correr ANTES de supabase_codigos_barras.sql (que depois liga os códigos de barras a estes artigos).
-- Pode ser corrido mais do que uma vez. Não apaga nada e não mexe no stock nem nas vendas dos artigos que já existem.

with v(code, name, category, sales) as (values
  ('59000025', 'CAMEL STICKS AZURE', 'Tabaco aquecido', 3),
  ('59000028', 'CAMEL AMBER STICKS', 'Tabaco aquecido', 3),
  ('59020000', 'VEEV ONE CHERRY RECARGA', 'Cigarros eletrónicos', 37),
  ('59020012', 'VUSE GREEN APPLE 20MG 2PODS', 'Cigarros eletrónicos', 8),
  ('59020173', 'VEEV ONE EXTRA STRAWBERRY X 20MG', 'Cigarros eletrónicos', 11),
  ('59020174', 'VEEV ONE EXTRA WATERMELON 1.8MG', 'Cigarros eletrónicos', 21),
  ('59020404', 'LYO FOR PLOOM WILD BERRY', 'Tabaco aquecido', 23),
  ('59020405', 'LYO FOR PLOOM ARCTIC MINT', 'Tabaco aquecido', 3),
  ('59020522', 'LEVIA BLUEBERRY STRAWBERRY', 'Tabaco aquecido', 1),
  ('59020576', 'VUSE PEPPERMINT ICE 20MG 2 PODS', 'Cigarros eletrónicos', 1),
  ('59020578', 'EVO BRONZE', 'Tabaco aquecido', 71),
  ('59020581', 'EVO AMBER', 'Tabaco aquecido', 2),
  ('59020582', 'EVO GOLD', 'Tabaco aquecido', 5),
  ('59020589', 'VEO INDIGO TWIST', 'Tabaco aquecido', 6),
  ('59020608', 'LEVIA MINTY STRAWBERRY PEARL', 'Tabaco aquecido', 1),
  ('59020609', 'LEVIA LIME STRAWBERRY PEARL', 'Tabaco aquecido', 3),
  ('59020611', 'VEEV ONE PASSION FRUIT KIWI GUAVA', 'Cigarros eletrónicos', 27),
  ('59020612', 'VEEV ONE BLUBERRY X', 'Cigarros eletrónicos', 36),
  ('59020680', 'VEO ANANAS SOL CLIQUE', 'Tabaco aquecido', 10),
  ('59020681', 'LYO FOR PLOOM ZESTY PEAR', 'Tabaco aquecido', 6),
  ('59020682', 'NEO SIGNATURE TOBACCO', 'Tabaco aquecido', 1),
  ('59711809', 'TEREA TURQUOISE', 'Tabaco aquecido', 1697),
  ('59713919', 'VEEV ONE BLUE MINT 20 MG', 'Cigarros eletrónicos', 95),
  ('59713922', 'VEEV ONE BLUEBERRY', 'Cigarros eletrónicos', 9),
  ('59713930', 'VEEV ONE LEMON LIME 20MG', 'Cigarros eletrónicos', 18),
  ('59713936', 'VEEV ONE SOUR APPLE 20MG', 'Cigarros eletrónicos', 49),
  ('59713941', 'VEEV ONE STRAWBERRY 20 MG', 'Cigarros eletrónicos', 37),
  ('59713942', 'VEEV ONE WATERMELON 20 MG', 'Cigarros eletrónicos', 42),
  ('59713945', 'VEEV ULTRA BLUE RASPBERRY', 'Cigarros eletrónicos', 5),
  ('59713946', 'VEEV ULTRA CLASSIC MINT', 'Cigarros eletrónicos', 2),
  ('59713947', 'VEEV ULTRA LEMON LIME', 'Cigarros eletrónicos', 4),
  ('59713951', 'VEEV ULTRA SOUR APPLE', 'Cigarros eletrónicos', 1),
  ('59713952', 'VEEV ULTRA STRAWBERRY', 'Cigarros eletrónicos', 4),
  ('59713953', 'VEEV ULTRA WATERMELON 20MG', 'Cigarros eletrónicos', 4),
  ('59714073', 'VEO RUBY TWIST', 'Tabaco aquecido', 47),
  ('59714075', 'VEO TROPICAL TWIST', 'Tabaco aquecido', 57),
  ('59715304', 'VUSE GO 1000 WATERMELON ICE 20MG', 'Cigarros eletrónicos', 1),
  ('59715344', 'VUSE POD WATERMELLON ICE 20 MG', 'Cigarros eletrónicos', 2),
  ('59800000', 'VEO POLAR TWIST', 'Tabaco aquecido', 50),
  ('59800001', 'VEO BLOSSOM TWIST', 'Tabaco aquecido', 29),
  ('59800002', 'LEVIA STRAWBERRY WATERMELON', 'Tabaco aquecido', 16),
  ('59800008', 'LEVIA FRESH MINT', 'Tabaco aquecido', 56),
  ('59800079', 'VEO SCARLET CLICK', 'Tabaco aquecido', 18),
  ('59800081', 'VEO GREEN CLICK', 'Tabaco aquecido', 15),
  ('59800848', 'TEREA SIENNA', 'Tabaco aquecido', 303),
  ('59800851', 'TEREA YELLOW', 'Tabaco aquecido', 45),
  ('59800854', 'TEREA AMBER', 'Tabaco aquecido', 186),
  ('59801138', 'TEREA SILVER', 'Tabaco aquecido', 42),
  ('59801150', 'TEREA RUSSET', 'Tabaco aquecido', 132),
  ('59801498', 'FIITZ MARINE', 'Tabaco aquecido', 45),
  ('59801499', 'FIITZ REGULAR', 'Tabaco aquecido', 9),
  ('59801510', 'NEO CLASSIC TOBACCO', 'Tabaco aquecido', 47),
  ('59802205', 'TEREA TEAK', 'Tabaco aquecido', 48),
  ('59802214', 'VEO ARCTIC CLICK', 'Tabaco aquecido', 3),
  ('59802249', 'NEO GOLDEN TOBACCO', 'Tabaco aquecido', 4),
  ('59806746', 'CAMEL EMERALD STICKS', 'Tabaco aquecido', 6),
  ('59808800', 'CAMEL ACTIVATE PURPLE C/10', 'Cigarrilhas', 9),
  ('59810080', 'CHESTERFIELD RED FILTER C/17', 'Cigarrilhas', 56),
  ('59810151', 'CAMEL ACTIVATE DOUBLE C/17', 'Cigarrilhas', 144),
  ('59812560', 'DELIA CLASSIC GOLD', 'Tabaco aquecido', 119),
  ('59812562', 'DELIA CLASSIC RED', 'Tabaco aquecido', 23),
  ('59812563', 'DELIA CLASSIC SILVER', 'Tabaco aquecido', 106),
  ('59812565', 'DELIA CLASSIC ZEPHYR', 'Tabaco aquecido', 173),
  ('59819972', 'LEVIA DEEP MINT', 'Tabaco aquecido', 48),
  ('59819975', 'LEVIA CRISP MINT', 'Tabaco aquecido', 36),
  ('59823922', 'NEO BRIGHT TOBACCO', 'Tabaco aquecido', 2),
  ('59823925', 'NEO TERRACOTA TOBACCO', 'Tabaco aquecido', 18),
  ('59827734', 'CAMEL GOLD STICKS', 'Tabaco aquecido', 1)
),
-- As cigarrilhas já existiam na app sem código Repsol: liga-as pelo nome.
lig as (
  update public.products p set repsol_code = v.code, sales_month = v.sales, sales_days = 31
  from v where p.repsol_code is null and upper(p.name) = v.name
    and not exists (select 1 from public.products x where x.repsol_code = v.code)
  returning p.repsol_code
)
insert into public.products (id, name, category, repsol_code, barcode, volume_barcode, stock, notes, sales_month, sales_days)
select 'r' || v.code, v.name, v.category, v.code, null, null, 0, '', v.sales, 31
from v
where not exists (select 1 from public.products x where x.repsol_code = v.code or upper(x.name) = v.name)
  and v.code not in (select repsol_code from lig)
on conflict (id) do nothing;

-- Verificação: artigos por categoria (deve dar 141 com código Repsol).
select category, count(*) as artigos, count(repsol_code) as com_codigo_repsol
from public.products group by category order by category;
