/* =====================================================================
   ETAPA 6 - DIM_CANDIDATO_PARTIDO: carga incremental de 2018 (ASCII puro)
   - Nao recria a dimensao: preserva SKs ja usados por Fato_Votacao 2022
   - FL_CONCORRENTE_REGIONAL (KPI 10): >= 50% dos votos do candidato em
     municipios com FL_GRANDE_ABC = 1 ou FL_RMSP = 1, calculado com os VOTOS 2018
   - SG_FEDERACAO: valor padrao copiado da propria dimensao (registro -1),
     sem literais acentuados -> imune a encoding do sqlcmd
   ===================================================================== */
set nocount on;
set xact_abort on;

declare @ds_sem_federacao varchar(50) = (select SG_FEDERACAO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '-1');

begin transaction;

if object_id('tempdb..#Municipios_Alvo') is not null drop table #Municipios_Alvo;
select distinct cast(CD_MUNICIPIO as varchar(20)) as CD_MUNICIPIO
into #Municipios_Alvo
from dbo.Dim_Local_Votacao
where FL_GRANDE_ABC = 1 or FL_RMSP = 1;

if object_id('tempdb..#Concentracao_2018') is not null drop table #Concentracao_2018;
select
    v.SQ_CANDIDATO,
    sum(cast(v.QT_VOTOS as bigint)) as VOTOS_TOTAIS_ESTADO,
    sum(case when m.CD_MUNICIPIO is not null then cast(v.QT_VOTOS as bigint) else 0 end) as VOTOS_REGIAO
into #Concentracao_2018
from dbo.Staging_VotacaoSecao_2018_SP v
left join #Municipios_Alvo m on v.CD_MUNICIPIO = m.CD_MUNICIPIO
where v.SQ_CANDIDATO not in ('-1', '-3')
group by v.SQ_CANDIDATO;

-- 1. Candidatos nominais 2018
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select
    c.SQ_CANDIDATO,
    c.NR_CANDIDATO,
    c.NM_URNA_CANDIDATO,
    c.DS_CARGO,
    c.SG_PARTIDO,
    coalesce(c.SG_FEDERACAO, @ds_sem_federacao),
    case when cc.VOTOS_TOTAIS_ESTADO > 0 and (cc.VOTOS_REGIAO * 1.0 / cc.VOTOS_TOTAIS_ESTADO) >= 0.50 then 1 else 0 end
from dbo.Staging_Consulta_Cand_2018_SP c
left join #Concentracao_2018 cc on c.SQ_CANDIDATO = cc.SQ_CANDIDATO
where not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = c.SQ_CANDIDATO);

-- 2. Legendas de 2018 ainda ausentes (2 digitos)
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select
    vl.NR_VOTAVEL,
    vl.NR_VOTAVEL,
    concat('VOTO DE LEGENDA - PARTIDO ', vl.NR_VOTAVEL),
    'DEPUTADO ESTADUAL',
    coalesce(p.SG_PARTIDO, concat('PTDO_', vl.NR_VOTAVEL)),
    @ds_sem_federacao,
    0
from (select distinct NR_VOTAVEL from dbo.Staging_VotacaoSecao_2018_SP where len(NR_VOTAVEL) = 2 and NR_VOTAVEL not in ('95', '96')) vl
left join (select distinct NR_PARTIDO, SG_PARTIDO from dbo.Staging_Consulta_Cand_2018_SP) p on vl.NR_VOTAVEL = p.NR_PARTIDO
where not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = vl.NR_VOTAVEL);

commit transaction;

select count(*) as TOTAL_DIM_CANDIDATO, sum(cast(FL_CONCORRENTE_REGIONAL as int)) as REGIONAIS from dbo.Dim_Candidato_Partido;
