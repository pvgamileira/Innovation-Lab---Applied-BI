if object_id('dbo.Dim_Candidato_Partido', 'u') is not null drop table dbo.Dim_Candidato_Partido;

create table dbo.Dim_Candidato_Partido (
    SK_CANDIDATO_PARTIDO int identity(1,1) not null,
    NK_CANDIDATO varchar(20) not null,
    NR_CANDIDATO varchar(10) not null,
    NM_URNA_CANDIDATO varchar(100) not null,
    DS_CARGO varchar(50) not null,
    SG_PARTIDO varchar(20) not null,
    SG_FEDERACAO varchar(50) not null constraint DF_Dim_Candidato_Federacao default 'SEM FEDERAÇÃO',
    FL_CONCORRENTE_REGIONAL bit not null constraint DF_Dim_Candidato_Regional default 0,
    constraint PK_Dim_Candidato_Partido primary key (SK_CANDIDATO_PARTIDO),
    constraint UQ_Dim_Candidato_Partido_NK unique (NK_CANDIDATO)
);

-- 1. Registros especiais de controle
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
values 
    ('-1', '-1', 'VOTO NÃO IDENTIFICADO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('95', '95', 'VOTO EM BRANCO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('96', '96', 'VOTO NULO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0);

-- 2. Carga unificada de candidatos nominais (2022 + 2018)
if object_id('tempdb..#Municipios_Alvo') is not null drop table #Municipios_Alvo;
select distinct cast(CD_MUNICIPIO as varchar(20)) as CD_MUNICIPIO
into #Municipios_Alvo
from dbo.Dim_Local_Votacao
where FL_GRANDE_ABC = 1 or FL_RMSP = 1;

if object_id('tempdb..#Concentracao_Candidatos') is not null drop table #Concentracao_Candidatos;
select 
    c.SQ_CANDIDATO, 
    sum(v.QT_VOTOS) as VOTOS_TOTAIS_ESTADO, 
    sum(case when m.CD_MUNICIPIO is not null then v.QT_VOTOS else 0 end) as VOTOS_REGIAO
into #Concentracao_Candidatos
from dbo.Staging_VotacaoSecao_2022_SP v
inner join dbo.Staging_Consulta_Cand_2022_SP c on v.SQ_CANDIDATO = c.SQ_CANDIDATO
left join #Municipios_Alvo m on v.CD_MUNICIPIO = m.CD_MUNICIPIO
where c.DS_CARGO = 'DEPUTADO ESTADUAL'
group by c.SQ_CANDIDATO;

with Candidatos_Todos as (
    select 
        cast(SQ_CANDIDATO as varchar(20)) as NK_CANDIDATO, 
        cast(NR_CANDIDATO as varchar(10)) as NR_CANDIDATO, 
        NM_URNA_CANDIDATO, 
        DS_CARGO as DS_CARGO, 
        SG_PARTIDO as SG_PARTIDO, 
        coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO 
    from dbo.Staging_Consulta_Cand_2022_SP 
    where DS_CARGO = 'DEPUTADO ESTADUAL'
    union
    select 
        cast(SQ_CANDIDATO as varchar(20)) as NK_CANDIDATO, 
        cast(NR_CANDIDATO as varchar(10)) as NR_CANDIDATO, 
        NM_URNA_CANDIDATO, 
        DS_CARGO as DS_CARGO, 
        SG_PARTIDO as SG_PARTIDO, 
        coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO 
    from dbo.Staging_Consulta_Cand_2018_SP 
    where DS_CARGO = 'DEPUTADO ESTADUAL'
)
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select distinct
    ct.NK_CANDIDATO, 
    ct.NR_CANDIDATO, 
    ct.NM_URNA_CANDIDATO, 
    ct.DS_CARGO, 
    ct.SG_PARTIDO, 
    ct.SG_FEDERACAO,
    case when cc.VOTOS_TOTAIS_ESTADO > 0 and (cc.VOTOS_REGIAO * 1.0 / cc.VOTOS_TOTAIS_ESTADO) >= 0.50 then 1 else 0 end as FL_CONCORRENTE_REGIONAL
from Candidatos_Todos ct
left join #Concentracao_Candidatos cc on ct.NK_CANDIDATO = cast(cc.SQ_CANDIDATO as varchar(20))
where not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = ct.NK_CANDIDATO);

-- 3. Inserção dos votos de legenda partidária (2 dígitos)
with Partidos_2022 as (
    select distinct 
        cast(NR_PARTIDO as varchar(10)) as NR_PARTIDO, 
        SG_PARTIDO, 
        coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO
    from dbo.Staging_Consulta_Cand_2022_SP
),
Partidos_2018 as (
    select distinct 
        cast(NR_PARTIDO as varchar(10)) as NR_PARTIDO, 
        SG_PARTIDO, 
        coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO
    from dbo.Staging_Consulta_Cand_2018_SP
),
Votaveis_Legenda as (
    select distinct NR_VOTAVEL from dbo.Staging_VotacaoSecao_2022_SP where len(NR_VOTAVEL) = 2 and NR_VOTAVEL not in ('95', '96')
    union
    select distinct NR_VOTAVEL from dbo.Staging_VotacaoSecao_2018_SP where len(NR_VOTAVEL) = 2 and NR_VOTAVEL not in ('95', '96')
),
Legendas_Todas as (
    select 
        vl.NR_VOTAVEL as NR_LEGENDA,
        coalesce(p22.SG_PARTIDO, p18.SG_PARTIDO, concat('PTDO_', vl.NR_VOTAVEL)) as SG_PARTIDO,
        coalesce(p22.SG_FEDERACAO, p18.SG_FEDERACAO, 'SEM FEDERAÇÃO') as SG_FEDERACAO
    from Votaveis_Legenda vl
    left join Partidos_2022 p22 on vl.NR_VOTAVEL = p22.NR_PARTIDO
    left join Partidos_2018 p18 on vl.NR_VOTAVEL = p18.NR_PARTIDO
)
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select distinct
    l.NR_LEGENDA as NK_CANDIDATO,
    l.NR_LEGENDA as NR_CANDIDATO,
    concat('VOTO DE LEGENDA - PARTIDO ', l.NR_LEGENDA) as NM_URNA_CANDIDATO,
    'DEPUTADO ESTADUAL' as DS_CARGO,
    l.SG_PARTIDO,
    l.SG_FEDERACAO,
    0 as FL_CONCORRENTE_REGIONAL
from Legendas_Todas l
where not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = l.NR_LEGENDA);
