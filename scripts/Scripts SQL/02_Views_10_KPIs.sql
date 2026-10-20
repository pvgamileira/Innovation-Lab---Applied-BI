/* =====================================================================
   CAMADA SEMANTICA (VIEWS OLAP) - OS 10 KPIS OFICIAIS DA MATRIZ TSE
   Cliente: Deputada Estadual Ana Carolina Serra (23023 - Cidadania/PSDB)
   Equipe : Start Phoenix Consultoria | Innovation Lab - Applied BI
   Nota   : Executar com UTF-8: sqlcmd -S localhost -d InnovationLab_AppliedBI -E -f 65001 -i "02_Views_10_KPIs.sql"
   ===================================================================== */
set nocount on;
go

-- =====================================================================
-- VIEW 1: PAINEL CONSOLIDADO POR LOCAL DE VOTACAO (KPIS 1, 2, 4, 5, 6, 9, 10)
-- Grao: 1 linha por Colegio Eleitoral (11.164 locais de votacao em SP)
-- =====================================================================
create or alter view dbo.vw_KPI_Painel_Local_Votacao as
with Votacao_Por_Local as (
    select
        f.SK_LOCAL_VOTACAO,
        -- Votos Depositados na Urna (Validos + Brancos + Nulos)
        sum(case when e.NR_ANO = 2018 then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_TOTAIS_2018,
        sum(case when e.NR_ANO = 2022 then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_TOTAIS_2022,

        -- Votos Validos do Cargo Deputado Estadual (Exclui 95-Branco, 96-Nulo, -1)
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_VALIDOS_2018,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_VALIDOS_2022,

        -- KPI 1 (VHMS): Baseline PSDB 2018 vs Federacao PSDB/Cidadania 2022
        sum(case when e.NR_ANO = 2018 and c.SG_PARTIDO = 'PSDB' and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_PSDB_2018,
        sum(case when e.NR_ANO = 2018 and (c.SG_PARTIDO in ('PSDB', 'PPS', 'CIDADANIA') or c.SG_FEDERACAO = 'PSDB/CIDADANIA') and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_PSDB_CIDADANIA_2018,
        sum(case when e.NR_ANO = 2022 and c.SG_FEDERACAO = 'PSDB/CIDADANIA' and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_FEDERACAO_2022,
        sum(case when e.NR_ANO = 2022 and c.SG_PARTIDO = 'PSDB' and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_PSDB_2022,

        -- KPI 2 (TDL%): Votos Nominais da Deputada Ana Carolina Serra (23023)
        sum(case when e.NR_ANO = 2022 and c.NR_CANDIDATO = '23023' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_ANA_CAROLINA_2022,

        -- KPI 4 (RML%): Votos Nominais vs Legenda Partidaria (2018 e 2022)
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO not in ('-1', '95', '96') and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_NOMINAIS_2018,
        sum(case when e.NR_ANO = 2018 and c.NM_URNA_CANDIDATO like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_LEGENDA_2018,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO not in ('-1', '95', '96') and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_NOMINAIS_2022,
        sum(case when e.NR_ANO = 2022 and c.NM_URNA_CANDIDATO like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_LEGENDA_2022,
        sum(case when e.NR_ANO = 2022 and c.SG_FEDERACAO <> 'PSDB/CIDADANIA' and c.NM_URNA_CANDIDATO like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_RIVAIS_LEGENDA_2022,
        sum(case when e.NR_ANO = 2022 and c.SG_FEDERACAO <> 'PSDB/CIDADANIA' and c.NK_CANDIDATO not in ('-1', '95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_RIVAIS_TOTAL_2022,

        -- KPI 9 (Delta IAR p.p.): Votos Alienados (Brancos 95 + Nulos 96)
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO = '95' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_BRANCOS_2018,
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO = '96' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_NULOS_2018,
        sum(case when e.NR_ANO = 2018 and c.NK_CANDIDATO in ('95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_ALIENADOS_2018,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO = '95' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_BRANCOS_2022,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO = '96' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_NULOS_2022,
        sum(case when e.NR_ANO = 2022 and c.NK_CANDIDATO in ('95', '96') then cast(f.QT_VOTOS as bigint) else 0 end) as QT_ALIENADOS_2022,

        -- KPI 10 (ICF%): Canibalizacao por Outros Candidatos da Federacao PSDB/Cidadania com base no ABC/RMSP
        sum(case when e.NR_ANO = 2022 and c.SG_FEDERACAO = 'PSDB/CIDADANIA' and c.NR_CANDIDATO <> '23023' and c.FL_CONCORRENTE_REGIONAL = 1 then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_OUTROS_FED_REGIONAL_2022,
        sum(case when e.NR_ANO = 2022 and c.SG_FEDERACAO = 'PSDB/CIDADANIA' and c.NR_CANDIDATO <> '23023' and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_OUTROS_FED_NOMINAIS_2022,
        sum(case when e.NR_ANO = 2022 and c.FL_CONCORRENTE_REGIONAL = 1 then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_CONCORRENTE_REGIONAL_2022
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    group by f.SK_LOCAL_VOTACAO
),
Comparecimento_Por_Local as (
    select
        f.SK_LOCAL_VOTACAO,
        sum(cast(f.QT_APTOS as bigint)) as QT_APTOS,
        sum(cast(f.QT_COMPARECIMENTO as bigint)) as QT_COMPARECIMENTO,
        sum(cast(f.QT_ABSTENCAO as bigint)) as QT_ABSTENCAO
    from dbo.Fato_Comparecimento_Abstencao f
    group by f.SK_LOCAL_VOTACAO
),
Municipio_Vulnerabilidade as (
    select
        l.CD_MUNICIPIO,
        cast((sum(isnull(v.QT_VOTOS_PSDB_2018, 0)) * 100.0) / nullif(sum(isnull(v.QT_VOTOS_VALIDOS_2018, 0)), 0) as decimal(7,2)) as MS_PSDB_2018_MUN_PCT,
        cast(
            ((sum(isnull(v.QT_VOTOS_FEDERACAO_2022, 0)) * 100.0) / nullif(sum(isnull(v.QT_VOTOS_VALIDOS_2022, 0)), 0))
            - ((sum(isnull(v.QT_VOTOS_PSDB_2018, 0)) * 100.0) / nullif(sum(isnull(v.QT_VOTOS_VALIDOS_2018, 0)), 0))
        as decimal(7,2)) as VHMS_FED_MUN_PP
    from dbo.Dim_Local_Votacao l
    left join Votacao_Por_Local v on l.SK_LOCAL_VOTACAO = v.SK_LOCAL_VOTACAO
    where l.SK_LOCAL_VOTACAO > 0
    group by l.CD_MUNICIPIO
)
select
    l.SK_LOCAL_VOTACAO,
    l.NK_LOCAL_VOTACAO,
    l.CD_MUNICIPIO,
    l.NM_MUNICIPIO,
    concat(l.NM_MUNICIPIO, ', São Paulo, Brasil') as LOCALIZACAO_MAPA,
    l.NR_ZONA,
    l.NR_LOCAL_VOTACAO,
    l.NM_LOCAL_VOTACAO,
    l.SG_UF,
    l.FL_GRANDE_ABC,
    l.FL_RMSP,
    case
        when l.FL_GRANDE_ABC = 1 then 'GRANDE ABC'
        when l.FL_RMSP = 1 then 'RMSP (EXCETO ABC)'
        else 'INTERIOR / LITORAL'
    end as REGIAO,

    -- Participacao Eleitoral e KPI 6 (TABF%)
    isnull(ca.QT_APTOS, 0) as QT_APTOS,
    isnull(ca.QT_COMPARECIMENTO, 0) as QT_COMPARECIMENTO,
    isnull(ca.QT_ABSTENCAO, 0) as QT_ABSTENCAO,
    cast(round(case when isnull(ca.QT_APTOS, 0) > 0 then (ca.QT_ABSTENCAO * 100.0) / ca.QT_APTOS else 0 end, 2) as decimal(5,2)) as TAXA_ABSTENCAO_PCT,

    -- Volumes de Votos Depositados e Validos
    isnull(v.QT_VOTOS_TOTAIS_2018, 0) as QT_VOTOS_2018,
    isnull(v.QT_VOTOS_TOTAIS_2022, 0) as QT_VOTOS_2022,
    isnull(v.QT_VOTOS_VALIDOS_2018, 0) as QT_VOTOS_VALIDOS_2018,
    isnull(v.QT_VOTOS_VALIDOS_2022, 0) as QT_VOTOS_VALIDOS_2022,

    -- KPI 1: Variacao Historica do Market Share Partidario (VHMS p.p.)
    isnull(v.QT_VOTOS_PSDB_2018, 0) as QT_VOTOS_PSDB_2018,
    isnull(v.QT_VOTOS_FEDERACAO_2022, 0) as QT_VOTOS_FEDERACAO_2022,
    isnull(v.QT_VOTOS_PSDB_2022, 0) as QT_VOTOS_PSDB_2022,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2018, 0) > 0 then (v.QT_VOTOS_PSDB_2018 * 100.0) / v.QT_VOTOS_VALIDOS_2018 else 0 end, 2) as decimal(5,2)) as MS_PSDB_2018_PCT,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_FEDERACAO_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as MS_FEDERACAO_2022_PCT,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_PSDB_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as MS_PSDB_2022_PCT,
    cast(round(
        case when isnull(v.QT_VOTOS_VALIDOS_2018, 0) > 0 and isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then
            ((v.QT_VOTOS_FEDERACAO_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022) - ((v.QT_VOTOS_PSDB_2018 * 100.0) / v.QT_VOTOS_VALIDOS_2018)
        else null end
    , 2) as decimal(7,2)) as VHMS_FED_VS_PSDB18_PP,
    cast(round(
        case when isnull(v.QT_VOTOS_VALIDOS_2018, 0) > 0 and isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then
            ((v.QT_VOTOS_PSDB_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022) - ((v.QT_VOTOS_PSDB_2018 * 100.0) / v.QT_VOTOS_VALIDOS_2018)
        else null end
    , 2) as decimal(7,2)) as VHMS_PSDB_ESTRITO_PP,

    -- KPI 2: Taxa de Dominancia por Local da Ana Carolina Serra (TDL%)
    isnull(v.QT_VOTOS_ANA_CAROLINA_2022, 0) as QT_VOTOS_ANA_CAROLINA_2022,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as TDL_ANA_CAROLINA_PCT,
    case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 and ((v.QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022) > 25.00 then 1 else 0 end as FL_DOMINANCIA_25_PCT,
    case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 and ((v.QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022) >= 20.00 then 1 else 0 end as FL_BASE_FIEL_20_PCT,

    -- KPI 4: Razao de Migracao por Legenda Rival (RML%) e Saldos Nominais vs Legenda
    isnull(v.QT_VOTOS_NOMINAIS_2018, 0) as QT_VOTOS_NOMINAIS_2018,
    isnull(v.QT_VOTOS_LEGENDA_2018, 0) as QT_VOTOS_LEGENDA_2018,
    isnull(v.QT_VOTOS_NOMINAIS_2022, 0) as QT_VOTOS_NOMINAIS_2022,
    isnull(v.QT_VOTOS_LEGENDA_2022, 0) as QT_VOTOS_LEGENDA_2022,
    (isnull(v.QT_VOTOS_NOMINAIS_2022, 0) - isnull(v.QT_VOTOS_NOMINAIS_2018, 0)) as SALDO_VOTOS_NOMINAIS,
    (isnull(v.QT_VOTOS_LEGENDA_2022, 0) - isnull(v.QT_VOTOS_LEGENDA_2018, 0)) as SALDO_VOTOS_LEGENDA,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_LEGENDA_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_VOTO_LEGENDA_PCT,
    cast(round(case when isnull(v.QT_VOTOS_RIVAIS_TOTAL_2022, 0) > 0 then (v.QT_VOTOS_RIVAIS_LEGENDA_2022 * 100.0) / v.QT_VOTOS_RIVAIS_TOTAL_2022 else 0 end, 2) as decimal(5,2)) as RML_RIVAIS_2022_PCT,

    -- KPI 5: Densidade de Eleitores no Local Vulneravel (DELV) e IVM
    case when mv.MS_PSDB_2018_MUN_PCT >= 15.00 and mv.VHMS_FED_MUN_PP <= -5.00 then 1 else 0 end as FL_MUNICIPIO_VULNERAVEL_IVM,
    case when mv.MS_PSDB_2018_MUN_PCT >= 15.00 and mv.VHMS_FED_MUN_PP <= -5.00 then isnull(ca.QT_APTOS, 0) else 0 end as DELV_QT_APTOS_VULNERAVEL,

    -- KPI 6: Taxa de Abstencao na Base Fiel (TABF% para locais com TDL >= 20%)
    cast(round(
        case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 and ((v.QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022) >= 20.00 and isnull(ca.QT_APTOS, 0) > 0 then
            (ca.QT_ABSTENCAO * 100.0) / ca.QT_APTOS
        else null end
    , 2) as decimal(5,2)) as TABF_BASE_FIEL_PCT,

    -- KPI 9: Variacao de Votos Alienados no Reduto (Delta IAR p.p.)
    isnull(v.QT_BRANCOS_2022, 0) as QT_BRANCOS_2022,
    isnull(v.QT_NULOS_2022, 0) as QT_NULOS_2022,
    isnull(v.QT_ALIENADOS_2018, 0) as QT_ALIENADOS_2018,
    isnull(v.QT_ALIENADOS_2022, 0) as QT_ALIENADOS_2022,
    cast(round(case when isnull(v.QT_VOTOS_TOTAIS_2018, 0) > 0 then (v.QT_ALIENADOS_2018 * 100.0) / v.QT_VOTOS_TOTAIS_2018 else 0 end, 2) as decimal(5,2)) as TAXA_ALIENACAO_2018_PCT,
    cast(round(case when isnull(v.QT_VOTOS_TOTAIS_2022, 0) > 0 then (v.QT_ALIENADOS_2022 * 100.0) / v.QT_VOTOS_TOTAIS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_ALIENACAO_2022_PCT,
    cast(round(
        case when isnull(v.QT_VOTOS_TOTAIS_2018, 0) > 0 and isnull(v.QT_VOTOS_TOTAIS_2022, 0) > 0 then
            ((v.QT_ALIENADOS_2022 * 100.0) / v.QT_VOTOS_TOTAIS_2022) - ((v.QT_ALIENADOS_2018 * 100.0) / v.QT_VOTOS_TOTAIS_2018)
        else null end
    , 2) as decimal(7,2)) as DELTA_IAR_PP,
    case when isnull(v.QT_VOTOS_TOTAIS_2018, 0) > 0 and isnull(v.QT_VOTOS_TOTAIS_2022, 0) > 0
          and (((v.QT_ALIENADOS_2022 * 100.0) / v.QT_VOTOS_TOTAIS_2022) - ((v.QT_ALIENADOS_2018 * 100.0) / v.QT_VOTOS_TOTAIS_2018)) > 3.00
         then 1 else 0 end as FL_GATILHO_ALIENACAO_3PP,

    -- KPI 10: Indice de Canibalizacao Regional na Federacao (ICF%)
    isnull(v.QT_VOTOS_OUTROS_FED_REGIONAL_2022, 0) as QT_VOTOS_OUTROS_FED_REGIONAL_2022,
    cast(round(case when isnull(v.QT_VOTOS_FEDERACAO_2022, 0) > 0 then (v.QT_VOTOS_OUTROS_FED_REGIONAL_2022 * 100.0) / v.QT_VOTOS_FEDERACAO_2022 else 0 end, 2) as decimal(5,2)) as ICF_FEDERACAO_REGIONAL_PCT,

    -- Colunas mantidas por retrocompatibilidade
    cast(round(case when isnull(v.QT_VOTOS_TOTAIS_2018, 0) > 0 then ((v.QT_VOTOS_TOTAIS_2022 - v.QT_VOTOS_TOTAIS_2018) * 100.0) / v.QT_VOTOS_TOTAIS_2018 else null end, 2) as decimal(7,2)) as VARIACAO_VOTOS_PCT,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_PSDB_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as DOMINANCIA_PSDB_PCT,
    cast(round(
        case when isnull(v.QT_VOTOS_TOTAIS_2018, 0) > 0 and isnull(v.QT_VOTOS_TOTAIS_2022, 0) > 0 then
            ((v.QT_ALIENADOS_2022 * 100.0) / v.QT_VOTOS_TOTAIS_2022) - ((v.QT_ALIENADOS_2018 * 100.0) / v.QT_VOTOS_TOTAIS_2018)
        else null end
    , 2) as decimal(7,2)) as VARIACAO_ALIENACAO_PCT,
    isnull(v.QT_VOTOS_CONCORRENTE_REGIONAL_2022, 0) as QT_VOTOS_CONCORRENTE_REGIONAL_2022,
    cast(round(case when isnull(v.QT_VOTOS_VALIDOS_2022, 0) > 0 then (v.QT_VOTOS_CONCORRENTE_REGIONAL_2022 * 100.0) / v.QT_VOTOS_VALIDOS_2022 else 0 end, 2) as decimal(5,2)) as TAXA_CONCORRENCIA_REGIONAL_PCT
from dbo.Dim_Local_Votacao l
left join Votacao_Por_Local v on l.SK_LOCAL_VOTACAO = v.SK_LOCAL_VOTACAO
left join Comparecimento_Por_Local ca on l.SK_LOCAL_VOTACAO = ca.SK_LOCAL_VOTACAO
left join Municipio_Vulnerabilidade mv on l.CD_MUNICIPIO = mv.CD_MUNICIPIO
where l.SK_LOCAL_VOTACAO > 0;
go

-- =====================================================================
-- VIEW 2: PAINEL POR MUNICIPIO PARA MAPA DO ESTADO DE SP (645 MUNICIPIOS)
-- Grao: 1 linha por Municipio de SP (Pronta para Azure Map / Shape Map)
-- =====================================================================
create or alter view dbo.vw_KPI_Painel_Municipio_Mapa_SP as
with Base_Municipio as (
    select
        CD_MUNICIPIO,
        NM_MUNICIPIO,
        SG_UF,
        LOCALIZACAO_MAPA,
        FL_GRANDE_ABC,
        FL_RMSP,
        REGIAO,
        count(distinct NR_ZONA) as QTD_ZONAS,
        count(distinct SK_LOCAL_VOTACAO) as QTD_LOCAIS_VOTACAO,
        sum(FL_DOMINANCIA_25_PCT) as QTD_LOCAIS_DOMINANCIA_25_TDL,
        sum(FL_BASE_FIEL_20_PCT) as QTD_LOCAIS_BASE_FIEL_20_TDL,
        sum(FL_GATILHO_ALIENACAO_3PP) as QTD_LOCAIS_GATILHO_IAR_3PP,
        sum(QT_APTOS) as QT_APTOS,
        sum(QT_COMPARECIMENTO) as QT_COMPARECIMENTO,
        sum(QT_ABSTENCAO) as QT_ABSTENCAO,
        sum(case when FL_BASE_FIEL_20_PCT = 1 then QT_APTOS else 0 end) as QT_APTOS_BASE_FIEL_20,
        sum(case when FL_BASE_FIEL_20_PCT = 1 then QT_ABSTENCAO else 0 end) as QT_ABSTENCAO_BASE_FIEL_20,
        sum(QT_VOTOS_2018) as QT_VOTOS_TOTAIS_2018,
        sum(QT_VOTOS_2022) as QT_VOTOS_TOTAIS_2022,
        sum(QT_VOTOS_VALIDOS_2018) as QT_VOTOS_VALIDOS_2018,
        sum(QT_VOTOS_VALIDOS_2022) as QT_VOTOS_VALIDOS_2022,
        sum(QT_VOTOS_PSDB_2018) as QT_VOTOS_PSDB_2018,
        sum(QT_VOTOS_FEDERACAO_2022) as QT_VOTOS_FEDERACAO_2022,
        sum(QT_VOTOS_PSDB_2022) as QT_VOTOS_PSDB_2022,
        sum(QT_VOTOS_ANA_CAROLINA_2022) as QT_VOTOS_ANA_CAROLINA_2022,
        sum(QT_VOTOS_NOMINAIS_2018) as QT_VOTOS_NOMINAIS_2018,
        sum(QT_VOTOS_LEGENDA_2018) as QT_VOTOS_LEGENDA_2018,
        sum(QT_VOTOS_NOMINAIS_2022) as QT_VOTOS_NOMINAIS_2022,
        sum(QT_VOTOS_LEGENDA_2022) as QT_VOTOS_LEGENDA_2022,
        sum(QT_ALIENADOS_2018) as QT_ALIENADOS_2018,
        sum(QT_ALIENADOS_2022) as QT_ALIENADOS_2022,
        sum(QT_VOTOS_OUTROS_FED_REGIONAL_2022) as QT_VOTOS_OUTROS_FED_REGIONAL_2022
    from dbo.vw_KPI_Painel_Local_Votacao
    group by CD_MUNICIPIO, NM_MUNICIPIO, SG_UF, LOCALIZACAO_MAPA, FL_GRANDE_ABC, FL_RMSP, REGIAO
),
Metricas_Municipio as (
    select
        b.*,
        cast((b.QT_VOTOS_PSDB_2018 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2018, 0) as decimal(7,2)) as MS_PSDB_2018_RAW,
        cast((b.QT_VOTOS_FEDERACAO_2022 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2022, 0) as decimal(7,2)) as MS_FED_2022_RAW,
        cast((b.QT_VOTOS_PSDB_2022 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2022, 0) as decimal(7,2)) as MS_PSDB_2022_RAW,
        cast(
            ((b.QT_VOTOS_FEDERACAO_2022 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2022, 0))
            - ((b.QT_VOTOS_PSDB_2018 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2018, 0))
        as decimal(7,2)) as VHMS_FED_RAW,
        cast(
            ((b.QT_VOTOS_PSDB_2022 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2022, 0))
            - ((b.QT_VOTOS_PSDB_2018 * 100.0) / nullif(b.QT_VOTOS_VALIDOS_2018, 0))
        as decimal(7,2)) as VHMS_PSDB_RAW
    from Base_Municipio b
)
select
    CD_MUNICIPIO,
    NM_MUNICIPIO,
    SG_UF,
    LOCALIZACAO_MAPA,
    FL_GRANDE_ABC,
    FL_RMSP,
    REGIAO,
    QTD_ZONAS,
    QTD_LOCAIS_VOTACAO,
    QTD_LOCAIS_DOMINANCIA_25_TDL,
    QTD_LOCAIS_BASE_FIEL_20_TDL,
    QTD_LOCAIS_GATILHO_IAR_3PP,
    QT_APTOS,
    QT_COMPARECIMENTO,
    QT_ABSTENCAO,
    cast(round((QT_ABSTENCAO * 100.0) / nullif(QT_APTOS, 0), 2) as decimal(5,2)) as TAXA_ABSTENCAO_MUN_PCT,
    cast(round((QT_ABSTENCAO_BASE_FIEL_20 * 100.0) / nullif(QT_APTOS_BASE_FIEL_20, 0), 2) as decimal(5,2)) as TABF_BASE_FIEL_MUN_PCT,
    QT_VOTOS_TOTAIS_2018,
    QT_VOTOS_TOTAIS_2022,
    QT_VOTOS_VALIDOS_2018,
    QT_VOTOS_VALIDOS_2022,
    QT_VOTOS_PSDB_2018,
    QT_VOTOS_FEDERACAO_2022,
    QT_VOTOS_PSDB_2022,
    QT_VOTOS_ANA_CAROLINA_2022,

    -- KPI 1: Market Share e Variacao Historica (VHMS p.p.)
    MS_PSDB_2018_RAW as MS_PSDB_2018_PCT,
    MS_FED_2022_RAW as MS_FEDERACAO_2022_PCT,
    MS_PSDB_2022_RAW as MS_PSDB_2022_PCT,
    VHMS_FED_RAW as VHMS_FED_VS_PSDB18_PP,
    VHMS_PSDB_RAW as VHMS_PSDB_ESTRITO_PP,
    case
        when VHMS_FED_RAW > 0.50 then 'CRESCIMENTO (> +0,5 p.p.)'
        when VHMS_FED_RAW > -0.50 then 'ESTÁVEL (-0,5 a +0,5 p.p.)'
        when VHMS_FED_RAW > -5.00 then 'QUEDA MODERADA (-0,5 a -5 p.p.)'
        else 'CRÍTICO (<= -5,0 p.p.)'
    end as STATUS_VHMS_MUNICIPIO,

    -- KPI 2: Dominancia Eleitoral de Ana Carolina Serra no Municipio (TDL%)
    cast(round((QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / nullif(QT_VOTOS_VALIDOS_2022, 0), 2) as decimal(5,2)) as TDL_ANA_CAROLINA_MUN_PCT,

    -- KPI 4: Migracao de Legenda no Municipio (RML%)
    QT_VOTOS_NOMINAIS_2018,
    QT_VOTOS_LEGENDA_2018,
    QT_VOTOS_NOMINAIS_2022,
    QT_VOTOS_LEGENDA_2022,
    cast(round((QT_VOTOS_LEGENDA_2018 * 100.0) / nullif(QT_VOTOS_VALIDOS_2018, 0), 2) as decimal(5,2)) as RML_GERAL_2018_PCT,
    cast(round((QT_VOTOS_LEGENDA_2022 * 100.0) / nullif(QT_VOTOS_VALIDOS_2022, 0), 2) as decimal(5,2)) as RML_GERAL_2022_PCT,

    -- KPI 5: Vulnerabilidade (IVM) e Densidade Eleitoral (DELV)
    case when MS_PSDB_2018_RAW >= 15.00 and VHMS_FED_RAW <= -5.00 then 1 else 0 end as FL_VULNERAVEL_IVM,
    case when MS_PSDB_2018_RAW >= 15.00 and VHMS_FED_RAW <= -5.00 then QT_APTOS else 0 end as DELV_ELEITORES_VULNERAVEIS,

    -- KPI 7: Indice de Dependencia da Federacao PSDB/Cidadania (IDF%)
    cast(round((QT_VOTOS_ANA_CAROLINA_2022 * 100.0) / nullif(QT_VOTOS_FEDERACAO_2022, 0), 2) as decimal(5,2)) as IDF_DEPENDENCIA_FEDERACAO_PCT,

    -- KPI 9: Alienacao Eleitoral no Municipio (Delta IAR p.p.)
    QT_ALIENADOS_2018,
    QT_ALIENADOS_2022,
    cast(round((QT_ALIENADOS_2018 * 100.0) / nullif(QT_VOTOS_TOTAIS_2018, 0), 2) as decimal(5,2)) as IAR_2018_PCT,
    cast(round((QT_ALIENADOS_2022 * 100.0) / nullif(QT_VOTOS_TOTAIS_2022, 0), 2) as decimal(5,2)) as IAR_2022_PCT,
    cast(round(
        ((QT_ALIENADOS_2022 * 100.0) / nullif(QT_VOTOS_TOTAIS_2022, 0))
        - ((QT_ALIENADOS_2018 * 100.0) / nullif(QT_VOTOS_TOTAIS_2018, 0))
    , 2) as decimal(7,2)) as DELTA_IAR_PP,

    -- KPI 10: Indice de Canibalizacao Regional na Federacao (ICF%)
    QT_VOTOS_OUTROS_FED_REGIONAL_2022,
    cast(round((QT_VOTOS_OUTROS_FED_REGIONAL_2022 * 100.0) / nullif(QT_VOTOS_FEDERACAO_2022, 0), 2) as decimal(5,2)) as ICF_CANIBALIZACAO_REGIONAL_PCT
from Metricas_Municipio;
go

-- =====================================================================
-- VIEW 3: MARGEM DE DISPUTA DA ZONA ELEITORAL / SWING ZONES (KPI 3 - MDZ)
-- Grao: 1 linha por Zona Eleitoral x Municipio em 2022
-- =====================================================================
create or alter view dbo.vw_KPI_Margem_Disputa_Zona as
with Votos_Candidato_Zona as (
    select
        l.NR_ZONA,
        l.CD_MUNICIPIO,
        l.NM_MUNICIPIO,
        l.FL_GRANDE_ABC,
        l.FL_RMSP,
        c.SK_CANDIDATO_PARTIDO,
        c.NR_CANDIDATO,
        c.NM_URNA_CANDIDATO,
        c.SG_PARTIDO,
        c.SG_FEDERACAO,
        sum(cast(f.QT_VOTOS as bigint)) as QT_VOTOS_CANDIDATO,
        row_number() over (
            partition by l.NR_ZONA, l.CD_MUNICIPIO
            order by sum(cast(f.QT_VOTOS as bigint)) desc
        ) as RANKING_ZONA
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022
      and c.NK_CANDIDATO not in ('-1', '95', '96')
      and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%'
    group by l.NR_ZONA, l.CD_MUNICIPIO, l.NM_MUNICIPIO, l.FL_GRANDE_ABC, l.FL_RMSP,
             c.SK_CANDIDATO_PARTIDO, c.NR_CANDIDATO, c.NM_URNA_CANDIDATO, c.SG_PARTIDO, c.SG_FEDERACAO
),
Totais_Zona as (
    select
        l.NR_ZONA,
        l.CD_MUNICIPIO,
        l.NM_MUNICIPIO,
        sum(cast(f.QT_VOTOS as bigint)) as QT_VOTOS_VALIDOS_ZONA
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022
      and c.NK_CANDIDATO not in ('-1', '95', '96')
    group by l.NR_ZONA, l.CD_MUNICIPIO, l.NM_MUNICIPIO
),
Votos_Ana_Zona as (
    select
        NR_ZONA,
        CD_MUNICIPIO,
        QT_VOTOS_CANDIDATO as QT_VOTOS_ANA_CAROLINA,
        RANKING_ZONA as RANKING_ANA_CAROLINA_ZONA
    from Votos_Candidato_Zona
    where NR_CANDIDATO = '23023'
)
select
    z1.NR_ZONA,
    z1.CD_MUNICIPIO,
    z1.NM_MUNICIPIO,
    case
        when z1.FL_GRANDE_ABC = 1 then 'GRANDE ABC'
        when z1.FL_RMSP = 1 then 'RMSP (EXCETO ABC)'
        else 'INTERIOR / LITORAL'
    end as REGIAO,
    z1.FL_GRANDE_ABC,
    z1.FL_RMSP,
    tz.QT_VOTOS_VALIDOS_ZONA,

    -- Desempenho da Cliente Ana Carolina Serra (23023) na Zona
    isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) as QT_VOTOS_ANA_CAROLINA,
    cast(round((isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as PCT_ANA_CAROLINA,
    ana.RANKING_ANA_CAROLINA_ZONA,

    -- 1o Colocado Geral na Zona
    z1.NM_URNA_CANDIDATO as PRIMEIRO_COLOCADO,
    z1.SG_PARTIDO as SG_PARTIDO_PRIMEIRO,
    z1.QT_VOTOS_CANDIDATO as VOTOS_PRIMEIRO,
    cast(round((z1.QT_VOTOS_CANDIDATO * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as PCT_PRIMEIRO,

    -- 2o Colocado Geral na Zona
    z2.NM_URNA_CANDIDATO as SEGUNDO_COLOCADO,
    z2.SG_PARTIDO as SG_PARTIDO_SEGUNDO,
    z2.QT_VOTOS_CANDIDATO as VOTOS_SEGUNDO,
    cast(round((z2.QT_VOTOS_CANDIDATO * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as PCT_SEGUNDO,

    -- KPI 3 Oficial (Matriz TSE): (Votos Ana Carolina - Votos 1o Colocado Geral) / Votos Validos da Zona * 100
    cast(round(((isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) - z1.QT_VOTOS_CANDIDATO) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(6,2)) as MDZ_OFICIAL_VS_LIDER_PP,

    -- KPI 3 Competitivo (Positivo quando Ana lidera sobre o 2o colocado; Negativo quando esta atras do 1o colocado)
    cast(round((
        (isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) - case when z1.NR_CANDIDATO = '23023' then isnull(z2.QT_VOTOS_CANDIDATO, 0) else z1.QT_VOTOS_CANDIDATO end) * 100.0
    ) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(6,2)) as MDZ_COMPETITIVO_PP,

    -- Classificacao Estrategica de Swing Zone
    case
        when z1.NR_CANDIDATO = '23023' then '1. LIDERANÇA ANA CAROLINA (1º LUGAR)'
        when isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) > 0 and abs(((isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) - z1.QT_VOTOS_CANDIDATO) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0)) <= 10.00 then '2. SWING ZONE PRIORITÁRIA (ATÉ 10 p.p. DO LÍDER)'
        when isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) > 0 and abs(((isnull(ana.QT_VOTOS_ANA_CAROLINA, 0) - z1.QT_VOTOS_CANDIDATO) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0)) <= 20.00 then '3. DISPUTA INTERMEDIÁRIA (10 A 20 p.p. DO LÍDER)'
        else '4. BAIXA PENETRAÇÃO (> 20 p.p. DO LÍDER)'
    end as STATUS_SWING_ZONE,

    -- Retrocompatibilidade: Margem 1o vs 2o Geral
    cast(round(((z1.QT_VOTOS_CANDIDATO - isnull(z2.QT_VOTOS_CANDIDATO, 0)) * 100.0) / nullif(tz.QT_VOTOS_VALIDOS_ZONA, 0), 2) as decimal(5,2)) as MARGEM_DISPUTA_PP
from Votos_Candidato_Zona z1
left join Votos_Candidato_Zona z2 on z1.NR_ZONA = z2.NR_ZONA and z1.CD_MUNICIPIO = z2.CD_MUNICIPIO and z2.RANKING_ZONA = 2
inner join Totais_Zona tz on z1.NR_ZONA = tz.NR_ZONA and z1.CD_MUNICIPIO = tz.CD_MUNICIPIO
left join Votos_Ana_Zona ana on z1.NR_ZONA = ana.NR_ZONA and z1.CD_MUNICIPIO = ana.CD_MUNICIPIO
where z1.RANKING_ZONA = 1;
go

-- =====================================================================
-- VIEW 4: DEPENDENCIA E CANIBALIZACAO NA FEDERACAO POR MUNICIPIO (KPIS 7 e 10)
-- Grao: 1 linha por Candidato Nominal da Federacao PSDB/Cidadania x Municipio
-- =====================================================================
create or alter view dbo.vw_KPI_Canibalizacao_Federacao_Municipio as
with Votos_Por_Candidato_Mun as (
    select
        l.CD_MUNICIPIO,
        l.NM_MUNICIPIO,
        l.FL_GRANDE_ABC,
        l.FL_RMSP,
        c.NR_CANDIDATO,
        c.NM_URNA_CANDIDATO,
        c.SG_PARTIDO,
        c.SG_FEDERACAO,
        c.FL_CONCORRENTE_REGIONAL,
        sum(cast(f.QT_VOTOS as bigint)) as QT_VOTOS_CANDIDATO
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022
      and c.SG_FEDERACAO = 'PSDB/CIDADANIA'
      and c.NK_CANDIDATO not in ('-1', '95', '96')
      and c.NM_URNA_CANDIDATO not like 'VOTO DE LEGENDA%'
    group by l.CD_MUNICIPIO, l.NM_MUNICIPIO, l.FL_GRANDE_ABC, l.FL_RMSP,
             c.NR_CANDIDATO, c.NM_URNA_CANDIDATO, c.SG_PARTIDO, c.SG_FEDERACAO, c.FL_CONCORRENTE_REGIONAL
),
Votos_Totais_Federacao_Mun as (
    select
        l.CD_MUNICIPIO,
        sum(cast(f.QT_VOTOS as bigint)) as QT_VOTOS_TOTAIS_FEDERACAO,
        sum(case when c.NR_CANDIDATO = '23023' then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_ANA_CAROLINA,
        sum(case when c.NR_CANDIDATO <> '23023' and c.FL_CONCORRENTE_REGIONAL = 1 then cast(f.QT_VOTOS as bigint) else 0 end) as QT_VOTOS_OUTROS_FED_REGIONAL
    from dbo.Fato_Votacao f
    inner join dbo.Dim_Eleicao e on f.SK_ELEICAO = e.SK_ELEICAO
    inner join dbo.Dim_Local_Votacao l on f.SK_LOCAL_VOTACAO = l.SK_LOCAL_VOTACAO
    inner join dbo.Dim_Candidato_Partido c on f.SK_CANDIDATO_PARTIDO = c.SK_CANDIDATO_PARTIDO
    where e.NR_ANO = 2022
      and c.SG_FEDERACAO = 'PSDB/CIDADANIA'
      and c.NK_CANDIDATO not in ('-1', '95', '96')
    group by l.CD_MUNICIPIO
)
select
    c.CD_MUNICIPIO,
    c.NM_MUNICIPIO,
    case
        when c.FL_GRANDE_ABC = 1 then 'GRANDE ABC'
        when c.FL_RMSP = 1 then 'RMSP (EXCETO ABC)'
        else 'INTERIOR / LITORAL'
    end as REGIAO,
    c.FL_GRANDE_ABC,
    c.FL_RMSP,
    c.NR_CANDIDATO,
    c.NM_URNA_CANDIDATO,
    c.SG_PARTIDO,
    c.SG_FEDERACAO,
    c.FL_CONCORRENTE_REGIONAL,
    c.QT_VOTOS_CANDIDATO,
    t.QT_VOTOS_TOTAIS_FEDERACAO,
    t.QT_VOTOS_ANA_CAROLINA,
    t.QT_VOTOS_OUTROS_FED_REGIONAL,
    (t.QT_VOTOS_TOTAIS_FEDERACAO - c.QT_VOTOS_CANDIDATO) as QT_VOTOS_OUTROS_COLEGAS,
    -- Participacao / Dependencia do Candidato na Federacao no Municipio (KPI 7 - IDF%)
    cast(round((c.QT_VOTOS_CANDIDATO * 100.0) / nullif(t.QT_VOTOS_TOTAIS_FEDERACAO, 0), 2) as decimal(5,2)) as IDF_PARTICIPACAO_FEDERACAO_PCT,
    -- Indice de Canibalizacao Regional na Federacao (KPI 10 - ICF%)
    cast(round((t.QT_VOTOS_OUTROS_FED_REGIONAL * 100.0) / nullif(t.QT_VOTOS_TOTAIS_FEDERACAO, 0), 2) as decimal(5,2)) as ICF_CANIBALIZACAO_REGIONAL_PCT,
    cast(round(((t.QT_VOTOS_TOTAIS_FEDERACAO - c.QT_VOTOS_CANDIDATO) * 100.0) / nullif(t.QT_VOTOS_TOTAIS_FEDERACAO, 0), 2) as decimal(5,2)) as INDICE_CANIBALIZACAO_PCT
from Votos_Por_Candidato_Mun c
inner join Votos_Totais_Federacao_Mun t on c.CD_MUNICIPIO = t.CD_MUNICIPIO;
go

-- Alias de retrocompatibilidade para a View 4
create or alter view dbo.vw_KPI_Canibalizacao_Partidaria_Municipio as
select * from dbo.vw_KPI_Canibalizacao_Federacao_Municipio;
go

-- =====================================================================
-- VIEW 5: PERFIL DEMOGRAFICO DOMINANTE POR LOCAL DE VOTACAO (KPI 8 - PDL)
-- Grao: 1 linha por Local de Votacao com Moda de Faixa Etaria x Escolaridade
-- =====================================================================
create or alter view dbo.vw_KPI_Perfil_Demografico_Dominante as
with Perfil_Faixa_Escolaridade as (
    select
        f.SK_LOCAL_VOTACAO,
        d.DS_FAIXA_ETARIA,
        d.DS_ESCOLARIDADE,
        sum(cast(f.QT_ELEITORES_PERFIL as bigint)) as QT_ELEITORES_COMBINACAO,
        row_number() over (
            partition by f.SK_LOCAL_VOTACAO
            order by sum(cast(f.QT_ELEITORES_PERFIL as bigint)) desc, d.DS_FAIXA_ETARIA asc, d.DS_ESCOLARIDADE asc
        ) as RANKING_COMBINACAO
    from dbo.Fato_Perfil_Eleitorado f
    inner join dbo.Dim_Perfil_Demografico d on f.SK_PERFIL_DEMOGRAFICO = d.SK_PERFIL_DEMOGRAFICO
    where d.SK_PERFIL_DEMOGRAFICO > 1
    group by f.SK_LOCAL_VOTACAO, d.DS_FAIXA_ETARIA, d.DS_ESCOLARIDADE
),
Genero_Dominante_Local as (
    select
        f.SK_LOCAL_VOTACAO,
        d.DS_GENERO,
        row_number() over (
            partition by f.SK_LOCAL_VOTACAO
            order by sum(cast(f.QT_ELEITORES_PERFIL as bigint)) desc, d.DS_GENERO asc
        ) as RANKING_GENERO
    from dbo.Fato_Perfil_Eleitorado f
    inner join dbo.Dim_Perfil_Demografico d on f.SK_PERFIL_DEMOGRAFICO = d.SK_PERFIL_DEMOGRAFICO
    where d.SK_PERFIL_DEMOGRAFICO > 1
    group by f.SK_LOCAL_VOTACAO, d.DS_GENERO
),
Total_Eleitores_Local as (
    select
        SK_LOCAL_VOTACAO,
        sum(cast(QT_ELEITORES_PERFIL as bigint)) as QT_TOTAL_ELEITORES_LOCAL
    from dbo.Fato_Perfil_Eleitorado
    group by SK_LOCAL_VOTACAO
),
Quartis_TDL as (
    select
        SK_LOCAL_VOTACAO,
        CD_MUNICIPIO,
        NM_MUNICIPIO,
        NR_ZONA,
        NR_LOCAL_VOTACAO,
        NM_LOCAL_VOTACAO,
        REGIAO,
        FL_GRANDE_ABC,
        FL_RMSP,
        QT_VOTOS_ANA_CAROLINA_2022,
        QT_VOTOS_VALIDOS_2022,
        TDL_ANA_CAROLINA_PCT,
        case when QT_VOTOS_VALIDOS_2022 > 0 then
            ntile(4) over (
                partition by case when QT_VOTOS_VALIDOS_2022 > 0 then 1 else 0 end
                order by TDL_ANA_CAROLINA_PCT asc, QT_VOTOS_VALIDOS_2022 desc
            )
        else null end as QUARTIL_TDL_ESTADO,
        case when FL_GRANDE_ABC = 1 and QT_VOTOS_VALIDOS_2022 > 0 then
            ntile(4) over (
                partition by FL_GRANDE_ABC, case when QT_VOTOS_VALIDOS_2022 > 0 then 1 else 0 end
                order by TDL_ANA_CAROLINA_PCT asc, QT_VOTOS_VALIDOS_2022 desc
            )
        else null end as QUARTIL_TDL_GRANDE_ABC
    from dbo.vw_KPI_Painel_Local_Votacao
)
select
    q.SK_LOCAL_VOTACAO,
    q.CD_MUNICIPIO,
    q.NM_MUNICIPIO,
    q.NR_ZONA,
    q.NR_LOCAL_VOTACAO,
    q.NM_LOCAL_VOTACAO,
    q.REGIAO,
    q.FL_GRANDE_ABC,
    q.FL_RMSP,
    q.QT_VOTOS_ANA_CAROLINA_2022,
    q.QT_VOTOS_VALIDOS_2022,
    q.TDL_ANA_CAROLINA_PCT,
    q.QUARTIL_TDL_ESTADO,
    q.QUARTIL_TDL_GRANDE_ABC,
    case when q.QUARTIL_TDL_ESTADO = 1 then 1 else 0 end as FL_PIOR_DESEMPENHO_Q1_ESTADO,
    case when q.QUARTIL_TDL_GRANDE_ABC = 1 then 1 else 0 end as FL_PIOR_DESEMPENHO_Q1_ABC,
    p.DS_FAIXA_ETARIA as FAIXA_ETARIA_DOMINANTE,
    p.DS_ESCOLARIDADE as ESCOLARIDADE_DOMINANTE,
    concat(p.DS_FAIXA_ETARIA, ' | ', p.DS_ESCOLARIDADE) as PERFIL_MODAL_COMPLETO,
    g.DS_GENERO as GENERO_DOMINANTE,
    p.QT_ELEITORES_COMBINACAO as QT_ELEITORES_PERFIL_DOMINANTE,
    t.QT_TOTAL_ELEITORES_LOCAL,
    cast(round((p.QT_ELEITORES_COMBINACAO * 100.0) / nullif(t.QT_TOTAL_ELEITORES_LOCAL, 0), 2) as decimal(5,2)) as PCT_REPRESENTATIVIDADE_PERFIL
from Quartis_TDL q
inner join Perfil_Faixa_Escolaridade p on q.SK_LOCAL_VOTACAO = p.SK_LOCAL_VOTACAO and p.RANKING_COMBINACAO = 1
inner join Total_Eleitores_Local t on q.SK_LOCAL_VOTACAO = t.SK_LOCAL_VOTACAO
left join Genero_Dominante_Local g on q.SK_LOCAL_VOTACAO = g.SK_LOCAL_VOTACAO and g.RANKING_GENERO = 1;
go
