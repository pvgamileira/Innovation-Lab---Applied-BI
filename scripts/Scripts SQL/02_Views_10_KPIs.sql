/* =====================================================================
   VIEWS ANALÍTICAS DOS 10 KPIS - INNOVATION LAB APPLIED BI
   Objetivo: Camada semântica pronta para consumo direto no Power BI
   ===================================================================== */
use InnovationLab_AppliedBI;
go

-- ---------------------------------------------------------------------
-- VIEW 1: PAINEL CONSOLIDADO POR LOCAL DE VOTAÇÃO (KPIS 1, 2, 4, 5, 7, 9, 10)
-- ---------------------------------------------------------------------
create or alter view dbo.vw_KPI_Painel_Local_Votacao as
with Votacao_Consolidada as (
    select
        f.SK_LOCAL_VOTACAO,
        -- Votos Totais (KPI 1)
        sum(case when e.NR_ANO = 2018 then f.QT_VOTOS else 0 end) as QT_VOTOS_2018,
        sum(case when e.NR_ANO = 2022 then f.QT_VOTOS else 0 end) as QT_VOTOS_2022,
        
        -- Votos Alienados: Brancos e Nulos (KPI 9)
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO in ('95', '96') then f.QT_VOTOS else 0 end) as QT_ALIENADOS_2018,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO = '95' then f.QT_VOTOS else 0 end) as QT_BRANCOS_2022,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO = '96' then f.QT_VOTOS else 0 end) as QT_NULOS_2022,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO in ('95', '96') then f.QT_VOTOS else 0 end) as QT_ALIENADOS_2022,
        
        -- Votos de Legenda Partidária (KPI 4)
        sum(case when e.NR_ANO = 2022 and c.NM_URNA_CANDIDATO like 'VOTO DE LEGENDA%' then f.QT_VOTOS else 0 end) as QT_VOTOS_LEGENDA_2022,
        
        -- Votos em Concorrentes Regionais da RMSP e Grande ABC (KPI 10)
        sum(case when e.NR_ANO = 2022 and c.FL_CONCORRENTE_REGIONAL = 1 then f.QT_VOTOS else 0 end) as QT_VOTOS_CONCORRENTE_REGIONAL_2022,
        
        -- Votos do Partido Alvo (PSDB - KPI 2)
        sum(case when e.NR_ANO = 2022 and c.SG_PARTIDO = 'PSDB' then f.QT_VOTOS else 0 end) as QT_VOTOS_PSDB_2022
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    group by f.SK_LOCAL_VOTACAO
),
Comparecimento_Consolidado as (
    select
        f.SK_LOCAL_VOTACAO,
        sum(f.QT_APTOS) as QT_APTOS,
        sum(f.QT_COMPARECIMENTO) as QT_COMPARECIMENTO,
        sum(f.QT_ABSTENCAO) as QT_ABSTENCAO
    from dbo.Fato_Comparecimento_Abstencao f
    group by f.SK_LOCAL_VOTACAO
)
select
    l.SK_LOCAL_VOTACAO,
    l.NK_LOCAL_VOTACAO,
    l.CD_MUNICIPIO,
    l.NM_MUNICIPIO,
    l.NR_ZONA,
    l.NR_LOCAL_VOTACAO,
    l.NM_LOCAL_VOTACAO,
    l.FL_GRANDE_ABC,
    l.FL_RMSP,
    
    -- Participação Eleitoral (KPI 5 e 7)
    isnull(ca.QT_APTOS, 0) as QT_APTOS,
    isnull(ca.QT_COMPARECIMENTO, 0) as QT_COMPARECIMENTO,
    isnull(ca.QT_ABSTENCAO, 0) as QT_ABSTENCAO,
    cast(round(case when isnull(ca.QT_APTOS, 0) > 0 then (ca.QT_ABSTENCAO * 100.0) / ca.QT_APTOS else 0 end, 2) as decimal(5,2)) as TAXA_ABSTENCAO_PCT,
    
    -- Votos Totais e Erosão Territorial (KPI 1)
    isnull(v.QT_VOTOS_2018, 0) as QT_VOTOS_2018,
    isnull(v.QT_VOTOS_2022, 0) as QT_VOTOS_2022,
    cast(round(case when isnull(v.QT_VOTOS_2018, 0) > 0 then ((v.QT_VOTOS_2022 - v.QT_VOTOS_2018) * 100.0) / v.QT_VOTOS_2018 else null end, 2) as decimal(7,2)) as VARIACAO_VOTOS_PCT,
    
    -- Dominância Territorial PSDB (KPI 2)
    isnull(v.QT_VOTOS_PSDB_2022, 0) as QT_VOTOS_PSDB_2022,
    cast(round(case when isnull(v.QT_VOTOS_2022, 0) > 0 then (v.QT_VOTOS_PSDB_2022 * 100.0) / v.QT_VOTOS_2022 else 0 end, 2) as decimal(5,2)) as DOMINANCIA_PSDB_PCT,
    
    -- Votos Alienados e Variação (KPI 9)
    isnull(v.QT_BRANCOS_2022, 0) as QT_BRANCOS_2022,
    isnull(v.QT_NULOS_2022, 0) as QT_NULOS_2022,
    isnull(v.QT_ALIENADOS_2022, 0) as QT_ALIENADOS_2022,
    cast(round(case when isnull(v.QT_VOTOS_2022, 0) > 0 then (v.QT_ALIENADOS_2022 * 100.0) / v.QT_VOTOS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_ALIENACAO_2022_PCT,
    isnull(v.QT_ALIENADOS_2018, 0) as QT_ALIENADOS_2018,
    cast(round(case when isnull(v.QT_ALIENADOS_2018, 0) > 0 then ((v.QT_ALIENADOS_2022 - v.QT_ALIENADOS_2018) * 100.0) / v.QT_ALIENADOS_2018 else null end, 2) as decimal(7,2)) as VARIACAO_ALIENACAO_PCT,
    
    -- Voto Residual de Legenda (KPI 4)
    isnull(v.QT_VOTOS_LEGENDA_2022, 0) as QT_VOTOS_LEGENDA_2022,
    cast(round(case when isnull(v.QT_VOTOS_2022, 0) > 0 then (v.QT_VOTOS_LEGENDA_2022 * 100.0) / v.QT_VOTOS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_VOTO_LEGENDA_PCT,
    
    -- Concorrência e Canibalização Regional (KPI 10)
    isnull(v.QT_VOTOS_CONCORRENTE_REGIONAL_2022, 0) as QT_VOTOS_CONCORRENTE_REGIONAL_2022,
    cast(round(case when isnull(v.QT_VOTOS_2022, 0) > 0 then (v.QT_VOTOS_CONCORRENTE_REGIONAL_2022 * 100.0) / v.QT_VOTOS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_CONCORRENCIA_REGIONAL_PCT

from dbo.Dim_Local_Votacao l
left join Votacao_Consolidada v on l.SK_LOCAL_VOTACAO = v.SK_LOCAL_VOTACAO
left join Comparecimento_Consolidado ca on l.SK_LOCAL_VOTACAO = ca.SK_LOCAL_VOTACAO
where l.SK_LOCAL_VOTACAO > 1;
go

-- ---------------------------------------------------------------------
-- VIEW 2: MARGEM DE DISPUTA POR ZONA ELEITORAL / SWING ZONES (KPI 3)
-- ---------------------------------------------------------------------
create or alter view dbo.vw_KPI_Margem_Disputa_Zona as
with Votos_Candidato_Zona as (
    select
        l.NR_ZONA,
        l.NM_MUNICIPIO,
        c.SK_CANDIDATO_PARTIDO,
        c.NM_URNA_CANDIDATO,
        c.SG_PARTIDO,
        sum(f.QT_VOTOS) as QT_VOTOS_CANDIDATO,
        row_number() over (
            partition by l.NR_ZONA, l.NM_MUNICIPIO 
            order by sum(f.QT_VOTOS) desc
        ) as RANKING_ZONA
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96')
    group by l.NR_ZONA, l.NM_MUNICIPIO, c.SK_CANDIDATO_PARTIDO, c.NM_URNA_CANDIDATO, c.SG_PARTIDO
),
Totais_Zona as (
    select
        l.NR_ZONA,
        l.NM_MUNICIPIO,
        sum(f.QT_VOTOS) as QT_VOTOS_VALIDOS_ZONA
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96')
    group by l.NR_ZONA, l.NM_MUNICIPIO
)
select
    z1.NR_ZONA,
    z1.NM_MUNICIPIO,
    tz.QT_VOTOS_VALIDOS_ZONA,
    
    -- 1º Colocado
    z1.NM_URNA_CANDIDATO as PRIMEIRO_COLOCADO,
    z1.SG_PARTIDO as SG_PARTIDO_PRIMEIRO,
    z1.QT_VOTOS_CANDIDATO as VOTOS_PRIMEIRO,
    cast(round((z1.QT_VOTOS_CANDIDATO * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as PCT_PRIMEIRO,
    
    -- 2º Colocado
    z2.NM_URNA_CANDIDATO as SEGUNDO_COLOCADO,
    z2.SG_PARTIDO as SG_PARTIDO_SEGUNDO,
    z2.QT_VOTOS_CANDIDATO as VOTOS_SEGUNDO,
    cast(round((z2.QT_VOTOS_CANDIDATO * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as PCT_SEGUNDO,
    
    -- Margem de Disputa em pontos percentuais (KPI 3)
    cast(round(((z1.QT_VOTOS_CANDIDATO - isnull(z2.QT_VOTOS_CANDIDATO, 0)) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as MARGEM_DISPUTA_PP
from Votos_Candidato_Zona z1
left join Votos_Candidato_Zona z2 on z1.NR_ZONA = z2.NR_ZONA and z1.NM_MUNICIPIO = z2.NM_MUNICIPIO and z2.RANKING_ZONA = 2
inner join Totais_Zona tz on z1.NR_ZONA = tz.NR_ZONA and z1.NM_MUNICIPIO = tz.NM_MUNICIPIO
where z1.RANKING_ZONA = 1;
go

-- ---------------------------------------------------------------------
-- VIEW 3: CANIBALIZAÇÃO PARTIDÁRIA POR MUNICÍPIO (KPI 6)
-- ---------------------------------------------------------------------
create or alter view dbo.vw_KPI_Canibalizacao_Partidaria_Municipio as
with Votos_Por_Candidato_Mun as (
    select
        l.CD_MUNICIPIO,
        l.NM_MUNICIPIO,
        c.SG_PARTIDO,
        c.NM_URNA_CANDIDATO,
        sum(f.QT_VOTOS) as QT_VOTOS_CANDIDATO
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96') and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%'
    group by l.CD_MUNICIPIO, l.NM_MUNICIPIO, c.SG_PARTIDO, c.NM_URNA_CANDIDATO
),
Votos_Totais_Partido_Mun as (
    select
        l.CD_MUNICIPIO,
        l.NM_MUNICIPIO,
        c.SG_PARTIDO,
        sum(f.QT_VOTOS) as QT_VOTOS_TOTAIS_PARTIDO
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96')
    group by l.CD_MUNICIPIO, l.NM_MUNICIPIO, c.SG_PARTIDO
)
select
    c.CD_MUNICIPIO,
    c.NM_MUNICIPIO,
    c.SG_PARTIDO,
    c.NM_URNA_CANDIDATO,
    c.QT_VOTOS_CANDIDATO,
    t.QT_VOTOS_TOTAIS_PARTIDO,
    (t.QT_VOTOS_TOTAIS_PARTIDO - c.QT_VOTOS_CANDIDATO) as QT_VOTOS_OUTROS_COLEGAS,
    -- Índice de Canibalização Partidária (KPI 6)
    cast(round(((t.QT_VOTOS_TOTAIS_PARTIDO - c.QT_VOTOS_CANDIDATO) * 100.0) / nullif(t.QT_VOTOS_TOTAIS_PARTIDO, 0), 2) as decimal(5,2)) as INDICE_CANIBALIZACAO_PCT
from Votos_Por_Candidato_Mun c
inner join Votos_Totais_Partido_Mun t on c.CD_MUNICIPIO = t.CD_MUNICIPIO and c.SG_PARTIDO = t.SG_PARTIDO;
go

-- ---------------------------------------------------------------------
-- VIEW 4: PERFIL DEMOGRÁFICO DOMINANTE POR LOCAL DE VOTAÇÃO (KPI 8)
-- ---------------------------------------------------------------------
create or alter view dbo.vw_KPI_Perfil_Demografico_Dominante as
with Perfil_Agrupado as (
    select
        l.SK_LOCAL_VOTACAO,
        l.NM_MUNICIPIO,
        l.NM_LOCAL_VOTACAO,
        d.DS_FAIXA_ETARIA,
        d.DS_ESCOLARIDADE,
        d.DS_GENERO,
        sum(f.QT_ELEITORES_PERFIL) as QT_ELEITORES,
        row_number() over (
            partition by l.SK_LOCAL_VOTACAO 
            order by sum(f.QT_ELEITORES_PERFIL) desc
        ) as RANKING_PERFIL_LOCAL
    from dbo.Fato_Perfil_Eleitorado f
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Perfil_Demografico d on f.SK_PERFIL_DEMOGRAFICO = d.SK_PERFIL_DEMOGRAFICO
    where d.SK_PERFIL_DEMOGRAFICO > 1
    group by l.SK_LOCAL_VOTACAO, l.NM_MUNICIPIO, l.NM_LOCAL_VOTACAO, d.DS_FAIXA_ETARIA, d.DS_ESCOLARIDADE, d.DS_GENERO
),
Total_Eleitores_Local as (
    select
        SK_LOCAL_VOTACAO,
        sum(QT_ELEITORES_PERFIL) as QT_TOTAL_ELEITORES_LOCAL
    from dbo.Fato_Perfil_Eleitorado
    group by SK_LOCAL_VOTACAO
)
select
    p.SK_LOCAL_VOTACAO,
    p.NM_MUNICIPIO,
    p.NM_LOCAL_VOTACAO,
    p.DS_FAIXA_ETARIA as FAIXA_ETARIA_DOMINANTE,
    p.DS_ESCOLARIDADE as ESCOLARIDADE_DOMINANTE,
    p.DS_GENERO as GENERO_DOMINANTE,
    p.QT_ELEITORES as QT_ELEITORES_PERFIL_DOMINANTE,
    t.QT_TOTAL_ELEITORES_LOCAL,
    cast(round((p.QT_ELEITORES * 100.0) / nullif(t.QT_TOTAL_ELEITORES_LOCAL, 0), 2) as decimal(5,2)) as PCT_REPRESENTATIVIDADE_PERFIL
from Perfil_Agrupado p
inner join Total_Eleitores_Local t on p.SK_LOCAL_VOTACAO = t.SK_LOCAL_VOTACAO
where p.RANKING_PERFIL_LOCAL = 1;
go
