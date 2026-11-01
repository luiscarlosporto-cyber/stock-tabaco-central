-- Margens por associação (01/11/2026): cada marca/família tem sempre a mesma margem sobre o PVP.
-- Os artigos sem fatura ficam com PVP das vendas (montante ÷ quantidade) e custo = PVP × (1 − margem). Só acrescenta; só administradores.
create table if not exists public.tabaco_margens (
  categoria text not null,
  marca     text not null default '',      -- início do nome do artigo ('' = toda a categoria)
  pct       numeric(5,2) not null check (pct >= 0 and pct < 100),
  fonte     text not null default '',
  primary key (categoria, marca)
);
alter table public.tabaco_margens enable row level security;
revoke all on public.tabaco_margens from anon;
drop policy if exists "margens so admin" on public.tabaco_margens;
create policy "margens so admin" on public.tabaco_margens for all to authenticated using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.tabaco_margens to authenticated;
insert into public.tabaco_margens(categoria, marca, pct, fonte) values
 ('Cigarros','MARLBORO',6.5,'faturas'),('Cigarros','CHESTERFIELD',6.5,'faturas'),('Cigarros','LM ',6.5,'faturas'),('Cigarros','L&M',6.5,'faturas'),
 ('Cigarros','PORTUGUES',6.5,'faturas'),('Cigarros','SG VENTIL',6.5,'faturas'),('Cigarros','CAMEL',7.2,'faturas'),('Cigarros','WINSTON',7.2,'faturas'),
 ('Cigarros','LUCKY',7.2,'faturas'),('Cigarros','JPS',6.9,'faturas'),('Cigarros','KARELIA',7.0,'faturas'),('Cigarros','AUSTIN',7.5,'faturas'),
 ('Cigarros','DENIM',7.5,'faturas'),('Cigarros','DENINM',7.5,'faturas'),
 ('Cigarrilhas','',10,'faturas'),('Onças','',6,'faturas'),('Latas','',6,'faturas'),('Sacos','',6,'faturas')
on conflict (categoria, marca) do update set pct = excluded.pct, fonte = excluded.fonte;

alter table public.tabaco_precos add column if not exists fonte text not null default 'fatura';   -- 'fatura' ou 'vendas+margem'
-- Artigos sem fatura, com PVP das vendas de 24/10 a 31/10/2026 (Santo Tirso) × margem da marca.
insert into public.tabaco_precos(product_id,pvp_c,custo_c,unidade,fornecedor,fatura,data,designacao,fonte) values
 ('r59020080',4900,round(4900*(1-0.075)),'volume','ADELAIDE SOUSA FERREIRA','','2026-10-31','DENINM AMAERICAN BLEND','vendas+margem'),
 ('r59810088',5400,round(5400*(1-0.072)),'volume','ADELAIDE SOUSA FERREIRA','','2026-10-31','WINSTON BLUE','vendas+margem'),
 ('r59821882',5700,round(5700*(1-0.065)),'volume','ADELAIDE SOUSA FERREIRA','','2026-10-31','MARLBORO RED 100''S','vendas+margem'),
 ('r59808800',4800,round(4800*(1-0.10)),'volume','ADELAIDE SOUSA FERREIRA','','2026-10-31','CAMEL ACTIVATE PURPLE C/10','vendas+margem'),
 ('r59708444',1125,round(1125*(1-0.06)),'unidade','ADELAIDE SOUSA FERREIRA','','2026-10-31','JPS BLACK 33 GR (LATA)','vendas+margem'),
 ('r59708462',1230,round(1230*(1-0.06)),'unidade','ADELAIDE SOUSA FERREIRA','','2026-10-31','MARLBORO 36 GR (LATA)','vendas+margem'),
 ('r59708480',1030,round(1030*(1-0.06)),'unidade','ADELAIDE SOUSA FERREIRA','','2026-10-31','RYO WINSTON LATA 30G','vendas+margem')
on conflict (product_id) do nothing;
