-- Tabaco aquecido e recargas (LOGISTA), 01/11/2026. Custo = "Total euros a pagar" (com o desconto de ~0,15 % por transferência,
-- quando a fatura o tem), repartido pelas linhas. Faturas ZIDR B011/2392031898 … 2392051414 (09/10 a 30/10/2026). Só acrescenta.
insert into public.tabaco_margens(categoria, marca, pct, fonte) values
 ('Tabaco aquecido','TEREA',7.0,'faturas Logista'),('Tabaco aquecido','DELIA',7.0,'faturas Logista'),('Tabaco aquecido','LEVIA',7.0,'faturas Logista'),
 ('Tabaco aquecido','BLENDS',7.0,'faturas Logista'),('Tabaco aquecido','LYO',8.0,'faturas Logista'),('Tabaco aquecido','EVO',8.0,'faturas Logista'),
 ('Tabaco aquecido','VEO',9.1,'faturas Logista'),('Tabaco aquecido','NEO',9.1,'faturas Logista'),('Cigarros eletrónicos','VEEV ONE',8.7,'faturas Logista')
on conflict (categoria, marca) do update set pct = excluded.pct, fonte = excluded.fonte;
insert into public.tabaco_precos(product_id,pvp_c,custo_c,unidade,fornecedor,fatura,data,designacao,fonte) values
('r59812565',4500,4186,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','DELIA CLASSIC ZEPHYR TT (26#) 4,50','fatura'),
('r59819975',4500,4185,'volume','LOGISTA','ZIDR B011/2392031898','2026-10-09','LEVIA CRISP MINT (26#) 4,50','fatura'),
('r59711809',5000,4651,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','TEREA TURQUOISE TT (26#) 5,00','fatura'),
('r59020404',4000,3680,'volume','LOGISTA','ZIDR B011/2392040009','2026-10-20','LYO WILD BERRY (26#) 4,00','fatura'),
('r59020405',4000,3674,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','LYO ARCTIC MINT (26#) 4,00','fatura'),
('r59800000',3800,3453,'volume','LOGISTA','ZIDR B011/2392040112','2026-10-20','VEO POLAR TWIST (4,3gr) (26#) 3,80','fatura'),
('r59823925',3800,3453,'volume','LOGISTA','ZIDR B011/2392040112','2026-10-20','NEO TERRACOTA TABACO TT 5,2gr (26#) 3,80','fatura'),
('r59801510',3800,3453,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','NEO CLASSIC TOBACCO - 5,2gr TT(26#) 3,80','fatura'),
('r59823922',3800,3453,'volume','LOGISTA','ZIDR B011/2392040112','2026-10-20','NEO BRIGHT TOBACCO 5,2gr T&T (26#) 3,80','fatura'),
('r59020000',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE CHERRY BMN 20mg 1 (26#) 3,99','fatura'),
('r59812563',4500,4185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','DELIA CLASSIC SILVER TT (26#) 4,50','fatura'),
('r59802205',5000,4651,'volume','LOGISTA','ZIDR B011/2392040112','2026-10-20','TEREA TEAK TT (26#) 5,00','fatura'),
('r59812560',4500,4186,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','DELIA CLASSIC GOLD TT (26#) 4,50','fatura'),
('r59713941',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE STRAWBERRY BMN 20mg 1 (26#)3,','fatura'),
('r59713919',2394,2185,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEEV ONE BLUE MINT BMN 20mg 1 (26#) 3,99','fatura'),
('r59800848',5000,4651,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','TEREA SIENNA TT (26#) 5,00','fatura'),
('r59713936',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE SOUR APPLE BMN 20mg 1 (26#)3,9','fatura'),
('r59801150',5000,4651,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','TEREA RUSSET TT (26#) 5,00','fatura'),
('r59713922',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE BLUEBERRY BMN 20mg 1 (26#) 3,9','fatura'),
('r59020174',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE EXTRA WATERMELON X (26#) 3,99','fatura'),
('r59800854',5000,4651,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','TEREA AMBER TT (26#) 5,00','fatura'),
('r59020611',2394,2185,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEEV ONE PFRUT KI GU BMN 20mg 1(26#)3,99','fatura'),
('r59020612',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE BLUEBERRY X (26#) 3,99','fatura'),
('r59713942',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE WATERMELON BMN 20mg 1 (26#)3','fatura'),
('r59800851',5000,4651,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','TEREA YELLOW TT (26#) 5,00','fatura'),
('r59819972',4500,4186,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','LEVIA DEEP MINT (26#) 4,50','fatura'),
('r59713930',2394,2185,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEEV ONE LEMON LIME BMN 20mg 1 (26#)3,99','fatura'),
('r59020173',2394,2185,'volume','LOGISTA','ZIDR B011/2392049586','2026-10-29','VEEV ONE EXTRA STRAWBERRY X (26#) 3,99','fatura'),
('r59800079',3800,3453,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEO SCARLET CLICK (4,1gr) (26#) 3,80','fatura'),
('r59714075',3800,3453,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEO TROPICAL TWIST (4,2gr) (26#) 3,80','fatura'),
('r59714073',3800,3453,'volume','LOGISTA','ZIDR B011/2392051393','2026-10-30','VEO RUBY TWIST (4,2gr) (26#) 3,80','fatura'),
('r59020578',4000,3680,'volume','LOGISTA','ZIDR B011/2392051414','2026-10-30','EVO BRONZE TT (26#) 4,00','fatura')
on conflict (product_id) do update set pvp_c=excluded.pvp_c, custo_c=excluded.custo_c, unidade=excluded.unidade, fornecedor=excluded.fornecedor, fatura=excluded.fatura, data=excluded.data, designacao=excluded.designacao, fonte=excluded.fonte, atualizado=now();
-- Artigos Logista sem fatura: PVP das vendas de 24/10 a 31/10/2026 × margem da marca.
insert into public.tabaco_precos(product_id,pvp_c,custo_c,unidade,fornecedor,fatura,data,designacao,fonte) values
('r59020581',4000,3680,'volume','LOGISTA','','2026-10-31','EVO AMBER','vendas+margem'),
('r59020589',3700,3363,'volume','LOGISTA','','2026-10-31','VEO INDIGO TWIST','vendas+margem'),
('r59800001',3700,3363,'volume','LOGISTA','','2026-10-31','VEO BLOSSOM TWIST','vendas+margem'),
('r59800081',3700,3363,'volume','LOGISTA','','2026-10-31','VEO GREEN CLICK','vendas+margem'),
('r59802214',3700,3363,'volume','LOGISTA','','2026-10-31','VEO ARCTIC CLICK','vendas+margem'),
('r59802249',3700,3363,'volume','LOGISTA','','2026-10-31','NEO GOLDEN TOBACCO','vendas+margem'),
('r59020682',3800,3454,'volume','LOGISTA','','2026-10-31','NEO SIGNATURE TOBACCO','vendas+margem'),
('r59020608',4500,4185,'volume','LOGISTA','','2026-10-31','LEVIA MINTY STRAWBERRY PEARL','vendas+margem'),
('r59020609',4500,4185,'volume','LOGISTA','','2026-10-31','LEVIA LIME STRAWBERRY PEARL','vendas+margem'),
('r59800002',4500,4185,'volume','LOGISTA','','2026-10-31','LEVIA STRAWBERRY WATERMELON','vendas+margem'),
('r59800008',4500,4185,'volume','LOGISTA','','2026-10-31','LEVIA FRESH MINT','vendas+margem'),
('r59801138',5000,4650,'volume','LOGISTA','','2026-10-31','TEREA SILVER','vendas+margem'),
('r59812562',4500,4185,'volume','LOGISTA','','2026-10-31','DELIA CLASSIC RED','vendas+margem')
on conflict (product_id) do nothing;
