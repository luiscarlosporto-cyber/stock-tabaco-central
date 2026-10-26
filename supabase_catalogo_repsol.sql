-- Catálogo Repsol: código interno, nome, categoria e vendas de 1 mês (31 dias a partir de 27/09/2026).
-- Colar no SQL Editor do Supabase e carregar em Run. Pode ser corrido mais de uma vez.
-- Não apaga produtos, não mexe no stock nem nos códigos de barras já associados.

-- 1) Cópia de segurança da tabela de produtos, antes de qualquer alteração.
create table if not exists public.products_backup_20261026 as select * from public.products;

-- 2) Novos campos.
alter table public.products add column if not exists repsol_code text;
alter table public.products add column if not exists volume_barcode text;
alter table public.products add column if not exists sales_month integer;
alter table public.products add column if not exists sales_days integer;
create unique index if not exists products_repsol_code_key on public.products(repsol_code);
create unique index if not exists products_volume_barcode_key on public.products(volume_barcode);

-- 3) Produtos do software Repsol. old_id = produto que já existia na app com o mesmo artigo.
with v(code, name, category, sales, old_id) as (values
  ('59020001', 'MARLBORO CRAFTED BLUE', 'Cigarros', 52, 'p32'),
  ('59020080', 'DENINM AMAERICAN BLEND', 'Cigarros', 51, 'p19'),
  ('59020484', 'CHESTERFIELD ORIGINAL XXL 24U', 'Cigarros', 47, 'p15'),
  ('59020597', 'MARLBORO CRAFTED RED 22', 'Cigarros', 50, 'p34'),
  ('59020637', 'CAMEL LEGEND', 'Cigarros', 9, null),
  ('59020638', 'CAMEL LEGEND 100S', 'Cigarros', 29, null),
  ('59020639', 'CAMEL LEGEND SOFT', 'Cigarros', 20, null),
  ('59708054', 'DENIM RED BOX', 'Cigarros', 66, 'p18'),
  ('59708601', 'AUSTIN BLUE', 'Cigarros', 34, 'p1'),
  ('59709486', 'SG VENTIL RS BOX', 'Cigarros', 186, 'p49'),
  ('59800077', 'CAMEL 100''S', 'Cigarros', 9, 'p4'),
  ('59800137', 'MARLBORO RED XL 22', 'Cigarros', 65, 'p42'),
  ('59800225', 'MARLBORO RED BOX', 'Cigarros', 89, 'p39'),
  ('59800516', 'LM RED', 'Cigarros', 9, 'p27'),
  ('59800590', 'WINSTON RED', 'Cigarros', 27, 'p51'),
  ('59800797', 'WINSTON RED 22', 'Cigarros', 35, 'p54'),
  ('59800835', 'MARLBORO RED SOFT', 'Cigarros', 85, 'p40'),
  ('59800908', 'JPS BLACK', 'Cigarros', 38, 'p20'),
  ('59800916', 'WINSTON RED SOFT', 'Cigarros', 242, 'p55'),
  ('59800987', 'SG VENTIL GIGANTE', 'Cigarros', 9, 'p48'),
  ('59801031', 'WINSTON RED 100´S', 'Cigarros', 225, 'p52'),
  ('59801090', 'LM BLUE', 'Cigarros', 114, 'p25'),
  ('59801377', 'SG VENTIL RS SOFT', 'Cigarros', 112, 'p50'),
  ('59801530', 'KARELIA S', 'Cigarros', 45, 'p24'),
  ('59801533', 'LM FORWARD HYBRID', 'Cigarros', 106, 'p26'),
  ('59801578', 'CAMEL 23', 'Cigarros', 30, 'p5'),
  ('59801668', 'CAMEL', 'Cigarros', 20, 'p3'),
  ('59801670', 'CAMEL SOFT', 'Cigarros', 10, 'p8'),
  ('59802361', 'MARLBORO GOLD', 'Cigarros', 138, 'p36'),
  ('59803190', 'AUSTIN RED', 'Cigarros', 45, 'p2'),
  ('59806722', 'CAMEL ACTIVATE', 'Cigarros', 231, 'p6'),
  ('59806735', 'CAMEL ACTIVATE WHITE', 'Cigarros', 95, 'p7'),
  ('59809443', 'CHESTERFIELD ORIGINAL 100''S', 'Cigarros', 25, 'p12'),
  ('59809450', 'CHESTERFIELD BLUE BOX', 'Cigarros', 28, 'p10'),
  ('59809455', 'CHESTERFIELD BLACK', 'Cigarros', 45, 'p9'),
  ('59809464', 'CHESTERFIELD BLUE SOFT', 'Cigarros', 48, 'p11'),
  ('59809473', 'CHESTERFIELD ORIGINAL BOX', 'Cigarros', 1, 'p13'),
  ('59809479', 'CHESTERFIELD ORIGINAL XXL 33', 'Cigarros', 71, null),
  ('59809487', 'CHESTERFIELD REMIX HYBRID', 'Cigarros', 46, 'p17'),
  ('59809494', 'CHESTERFIELD ORIGINAL SOFT', 'Cigarros', 59, 'p14'),
  ('59810088', 'WINSTON BLUE', 'Cigarros', 3, null),
  ('59818533', 'JPS BLACK 100''S', 'Cigarros', 31, 'p21'),
  ('59818543', 'JPS RED SOFT', 'Cigarros', 139, 'p22'),
  ('59818585', 'KARELIA I (CREAM)', 'Cigarros', 25, 'p23'),
  ('59820817', 'LM RED 22', 'Cigarros', 57, 'p28'),
  ('59820957', 'LUCKY STRIKE ORIGINAL', 'Cigarros', 59, 'p29'),
  ('59820963', 'LUCKY STRIKE SOFT', 'Cigarros', 83, 'p30'),
  ('59821882', 'MARLBORO RED 100''S', 'Cigarros', 11, 'p38'),
  ('59821888', 'MARLBORO CRAFTED 100''S', 'Cigarros', 135, 'p31'),
  ('59821889', 'MARLBORO CRAFTED RED', 'Cigarros', 74, 'p33'),
  ('59821891', 'MARLBORO CRAFTED SOFT', 'Cigarros', 167, 'p35'),
  ('59821903', 'MARLBORO POCKET PACK', 'Cigarros', 98, 'p37'),
  ('59821908', 'MARLBORO RED XXL 26', 'Cigarros', 168, 'p43'),
  ('59821914', 'MARLBORO SILVER BLUE', 'Cigarros', 15, 'p44'),
  ('59821919', 'MARLBORO RED TOUCH', 'Cigarros', 75, 'p41'),
  ('59828140', 'PORTUGUES AZUL', 'Cigarros', 45, 'p45'),
  ('59828154', 'PORTUGUES VERMELHO 100''S', 'Cigarros', 18, 'p46'),
  ('59828161', 'PORTUGUES VERMELHO SOFT', 'Cigarros', 390, 'p47'),
  ('59860101', 'WINSTON RED 100''S XL 26', 'Cigarros', 76, 'p53'),
  ('59801396', 'AMBER LEAF 30G', 'Onças', 49, 'p56'),
  ('59813737', 'WINSTON 30G', 'Onças', 25, 'p57'),
  ('59824959', 'ONCA CAMEL 30G', 'Onças', 15, 'p58'),
  ('59824964', 'JPS BLACK 30 GR', 'Onças', 2, 'p59'),
  ('59824965', 'MARLBORO VOLUME 30 GR', 'Onças', 12, 'p60'),
  ('59824967', 'ONCA WEST RED 30 GR', 'Onças', 20, 'p61'),
  ('59824971', 'ONCA CHESTERFIELD 30G', 'Onças', 7, 'p62'),
  ('59708444', 'JPS BLACK 33 GR (LATA)', 'Latas', 5, 'p63'),
  ('59708462', 'MARLBORO 36 GR (LATA)', 'Latas', 6, 'p67'),
  ('59708480', 'RYO WINSTON LATA 30G', 'Latas', 7, 'p66'),
  ('59806719', 'CAMEL 34 GR (LATA)', 'Latas', 7, 'p65'),
  ('59819524', 'CHESTERFIELD VOLUME 36 GR (LATA)', 'Latas', 1, 'p64'),
  ('59020204', 'WEST ORIGINAL RED 49G (SACO)', 'Sacos', 8, 'p69'),
  ('59813738', 'WINSTON 40 GR (SACO)', 'Sacos', 6, 'p68')
),
upd as (
  update public.products p
     set repsol_code = v.code, name = v.name, category = v.category, sales_month = v.sales, sales_days = 31
    from v
   where p.id = v.old_id and (p.repsol_code is null or p.repsol_code = v.code)
  returning p.repsol_code
)
insert into public.products (id, name, category, repsol_code, stock, notes, sales_month, sales_days)
select 'r' || v.code, v.name, v.category, v.code, 0, '', v.sales, 31
  from v
 where v.code not in (select repsol_code from upd)
   and not exists (select 1 from public.products p where p.repsol_code = v.code or p.id = v.old_id or p.id = 'r' || v.code);

-- Na segunda vez que corre, atualiza as vendas dos produtos já ligados ao código Repsol.
with v(code, sales) as (values
  ('59020001', 52),
  ('59020080', 51),
  ('59020484', 47),
  ('59020597', 50),
  ('59020637', 9),
  ('59020638', 29),
  ('59020639', 20),
  ('59708054', 66),
  ('59708601', 34),
  ('59709486', 186),
  ('59800077', 9),
  ('59800137', 65),
  ('59800225', 89),
  ('59800516', 9),
  ('59800590', 27),
  ('59800797', 35),
  ('59800835', 85),
  ('59800908', 38),
  ('59800916', 242),
  ('59800987', 9),
  ('59801031', 225),
  ('59801090', 114),
  ('59801377', 112),
  ('59801530', 45),
  ('59801533', 106),
  ('59801578', 30),
  ('59801668', 20),
  ('59801670', 10),
  ('59802361', 138),
  ('59803190', 45),
  ('59806722', 231),
  ('59806735', 95),
  ('59809443', 25),
  ('59809450', 28),
  ('59809455', 45),
  ('59809464', 48),
  ('59809473', 1),
  ('59809479', 71),
  ('59809487', 46),
  ('59809494', 59),
  ('59810088', 3),
  ('59818533', 31),
  ('59818543', 139),
  ('59818585', 25),
  ('59820817', 57),
  ('59820957', 59),
  ('59820963', 83),
  ('59821882', 11),
  ('59821888', 135),
  ('59821889', 74),
  ('59821891', 167),
  ('59821903', 98),
  ('59821908', 168),
  ('59821914', 15),
  ('59821919', 75),
  ('59828140', 45),
  ('59828154', 18),
  ('59828161', 390),
  ('59860101', 76),
  ('59801396', 49),
  ('59813737', 25),
  ('59824959', 15),
  ('59824964', 2),
  ('59824965', 12),
  ('59824967', 20),
  ('59824971', 7),
  ('59708444', 5),
  ('59708462', 6),
  ('59708480', 7),
  ('59806719', 7),
  ('59819524', 1),
  ('59020204', 8),
  ('59813738', 6)
)
update public.products p set sales_month = v.sales, sales_days = 31 from v where p.repsol_code = v.code;

-- 4) Verificação: produtos por categoria e os que ficaram sem código Repsol.
select category, count(*) as produtos, count(repsol_code) as com_codigo_repsol from public.products group by category order by category;
select id, name, category from public.products where repsol_code is null order by category, name;
