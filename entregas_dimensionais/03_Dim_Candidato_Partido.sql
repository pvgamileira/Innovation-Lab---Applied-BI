if object_id('dbo.Dim_Candidato_Partido', 'u') is not null drop table dbo.Dim_Candidato_Partido;

create table dbo.Dim_Candidato_Partido (
    SK_CANDIDATO_PARTIDO int identity(1,1) not null,
    NK_CANDIDATO varchar(20) not null,
    NR_CANDIDATO varchar(10) not null,
    NM_URNA_CANDIDATO varchar(100) not null,
    DS_CARGO varchar(50) not null,
    SG_PARTIDO varchar(10) not null,
    SG_FEDERACAO varchar(20) not null constraint DF_Dim_Candidato_Federacao default 'SEM FEDERAÇÃO',
    FL_CONCORRENTE_REGIONAL bit not null constraint DF_Dim_Candidato_Regional default 0,
    constraint PK_Dim_Candidato_Partido primary key (SK_CANDIDATO_PARTIDO),
    constraint UQ_Dim_Candidato_Partido_NK unique (NK_CANDIDATO)
);

insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
values 
    ('-1', '-1', 'VOTO NÃO IDENTIFICADO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('95', '95', 'VOTO EM BRANCO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('96', '96', 'VOTO NULO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0);

with Candidatos_Todos as (
    select cast(SQ_CANDIDATO as varchar(20)) as NK_CANDIDATO, cast(NR_CANDIDATO as varchar(10)) as NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO as DS_CARGO, SG_PARTIDO as SG_PARTIDO, coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO from dbo.Staging_Consulta_Cand_2022_SP where DS_CARGO = 'DEPUTADO ESTADUAL'
    union
    select cast(SQ_CANDIDATO as varchar(20)) as NK_CANDIDATO, cast(NR_CANDIDATO as varchar(10)) as NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO as DS_CARGO, SG_PARTIDO as SG_PARTIDO, coalesce(nullif(SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO from dbo.Staging_Consulta_Cand_2018_SP where DS_CARGO = 'DEPUTADO ESTADUAL'
),
Concentracao_Candidatos as (
    select c.SQ_CANDIDATO, sum(v.QT_VOTOS) as VOTOS_TOTAIS_ESTADO, sum(case when v.CD_MUNICIPIO in (select CD_MUNICIPIO from dbo.Dim_Local_Votacao where FL_GRANDE_ABC = 1 or FL_RMSP = 1) then v.QT_VOTOS else 0 end) as VOTOS_REGIAO
    from dbo.Staging_VotacaoSecao_2022_SP v
    inner join dbo.Staging_Consulta_Cand_2022_SP c on v.SQ_CANDIDATO = c.SQ_CANDIDATO
    where c.DS_CARGO = 'DEPUTADO ESTADUAL'
    group by c.SQ_CANDIDATO
)
insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select distinct
    ct.NK_CANDIDATO, ct.NR_CANDIDATO, ct.NM_URNA_CANDIDATO, ct.DS_CARGO, ct.SG_PARTIDO, ct.SG_FEDERACAO,
    case when cc.VOTOS_TOTAIS_ESTADO > 0 and (cc.VOTOS_REGIAO * 1.0 / cc.VOTOS_TOTAIS_ESTADO) >= 0.50 then 1 else 0 end as FL_CONCORRENTE_REGIONAL
from Candidatos_Todos ct
left join Concentracao_Candidatos cc on ct.NK_CANDIDATO = cast(cc.SQ_CANDIDATO as varchar(20))
where not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = ct.NK_CANDIDATO);

insert into dbo.Dim_Candidato_Partido (NK_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, DS_CARGO, SG_PARTIDO, SG_FEDERACAO, FL_CONCORRENTE_REGIONAL)
select distinct
    left(v.NR_VOTAVEL, 2) as NK_CANDIDATO, left(v.NR_VOTAVEL, 2) as NR_CANDIDATO, concat('VOTO DE LEGENDA - PARTIDO ', left(v.NR_VOTAVEL, 2)) as NM_URNA_CANDIDATO, 'DEPUTADO ESTADUAL' as DS_CARGO, coalesce(c.SG_PARTIDO, concat('PTDO_', left(v.NR_VOTAVEL, 2))) as SG_PARTIDO, coalesce(nullif(c.SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO, 0 as FL_CONCORRENTE_REGIONAL
from dbo.Staging_VotacaoSecao_2022_SP v
left join dbo.Staging_Consulta_Cand_2022_SP c on left(v.NR_VOTAVEL, 2) = cast(c.NR_PARTIDO as varchar)
where len(v.NR_VOTAVEL) = 2 and v.NR_VOTAVEL not in ('95', '96') and not exists (select 1 from dbo.Dim_Candidato_Partido d where d.NK_CANDIDATO = left(v.NR_VOTAVEL, 2));
