-- 03_dim_candidato_partido.sql
-- dimensao de candidatos/partidos (cargo deputado estadual)
-- ordem: 1) controles (95, 96, -1)  2) candidatos 2022 + 2018 (union)  3) legendas partidarias (2 digitos)
-- obs: nao existe staging de candidatos para 2018; os candidatos de 2018 sao derivados da staging
--      de votacao 2018 (sq_candidato, nr_votavel, nm_votavel) e a federacao e inserida
--      estaticamente como 'SEM FEDERAÇÃO' (federacoes so existem a partir de 2022)
-- flag fl_concorrente_regional = 1 quando >= 50% dos votos do candidato vieram da rmsp/grande abc

use innovationlab_appliedbi;
go

if object_id('dbo.fato_votacao', 'u') is not null
    drop table dbo.fato_votacao;

if object_id('dbo.dim_candidato_partido', 'u') is not null
    drop table dbo.dim_candidato_partido;
go

create table dbo.dim_candidato_partido (
    sk_candidato_partido int identity(1,1) not null,
    nk_candidato varchar(20) not null,
    nr_candidato varchar(10) not null,
    nm_urna_candidato varchar(100) not null,
    ds_cargo varchar(50) not null,
    sg_partido varchar(20) not null,
    sg_federacao varchar(50) not null constraint df_dim_candidato_partido_fed default 'SEM FEDERAÇÃO',
    fl_concorrente_regional bit not null constraint df_dim_candidato_partido_reg default 0,
    constraint pk_dim_candidato_partido primary key (sk_candidato_partido),
    constraint uq_dim_candidato_partido_nk unique (nk_candidato)
);
go

-- 1. registros de controle (branco, nulo e fallback para voto nao identificado)
insert into dbo.dim_candidato_partido (
    nk_candidato, nr_candidato, nm_urna_candidato, ds_cargo, sg_partido, sg_federacao, fl_concorrente_regional
)
values
    ('95', '95', 'VOTO EM BRANCO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('96', '96', 'VOTO NULO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('-1', '-1', 'VOTO NÃO IDENTIFICADO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0);
go

-- 2. mapa partido -> sigla/federacao (base: consulta_cand 2022, deputado estadual)
if object_id('tempdb..#mapa_partido') is not null
    drop table #mapa_partido;

select
    try_cast(nr_partido as int) as nr_partido,
    max(sg_partido) as sg_partido,
    max(case when sg_federacao in ('#NULO', '#NE', '') or sg_federacao is null
             then 'SEM FEDERAÇÃO' else sg_federacao end) as sg_federacao
into #mapa_partido
from dbo.staging_consulta_cand_2022_sp
where ds_cargo = 'DEPUTADO ESTADUAL'
group by try_cast(nr_partido as int);

-- 3. concentracao regional: votos do candidato na rmsp/grande abc sobre o total de votos (2018 + 2022)
if object_id('tempdb..#concentracao') is not null
    drop table #concentracao;

with municipios_regiao as (
    select distinct cd_municipio
    from dbo.dim_local_votacao
    where fl_grande_abc = 1 or fl_rmsp = 1
),
votos_empilhados as (
    select sq_candidato, cd_municipio, qt_votos
    from dbo.staging_votacaosecao_2022_sp
    where len(sq_candidato) = 12
    union all
    select sq_candidato, cd_municipio, qt_votos
    from dbo.staging_votacaosecao_2018_sp
    where len(sq_candidato) = 12
)
select
    v.sq_candidato,
    sum(cast(v.qt_votos as bigint)) as votos_totais_estado,
    sum(case when mr.cd_municipio is not null then cast(v.qt_votos as bigint) else 0 end) as votos_regiao
into #concentracao
from votos_empilhados v
left join municipios_regiao mr
    on mr.cd_municipio = try_cast(v.cd_municipio as int)
group by v.sq_candidato;

create unique clustered index ix_concentracao_sq on #concentracao (sq_candidato);
go

-- 4. carga unificada de candidatos (union 2022 + 2018) com a flag de market share
with candidatos_todos as (
    select
        sq_candidato as nk_candidato,
        max(nr_candidato) as nr_candidato,
        max(coalesce(nm_urna_candidato, 'NÃO INFORMADO')) as nm_urna_candidato,
        max(ds_cargo) as ds_cargo,
        max(sg_partido) as sg_partido,
        max(case when sg_federacao in ('#NULO', '#NE', '') or sg_federacao is null
                 then 'SEM FEDERAÇÃO' else sg_federacao end) as sg_federacao
    from dbo.staging_consulta_cand_2022_sp
    where ds_cargo = 'DEPUTADO ESTADUAL'
    group by sq_candidato
    union
    select
        v.sq_candidato as nk_candidato,
        max(v.nr_votavel) as nr_candidato,
        max(coalesce(v.nm_votavel, 'NÃO INFORMADO')) as nm_urna_candidato,
        max(v.ds_cargo) as ds_cargo,
        max(coalesce(mp.sg_partido, concat('PTDO_', left(v.nr_votavel, 2)))) as sg_partido,
        'SEM FEDERAÇÃO' as sg_federacao
    from dbo.staging_votacaosecao_2018_sp v
    left join #mapa_partido mp
        on mp.nr_partido = try_cast(left(v.nr_votavel, 2) as int)
    where len(v.sq_candidato) = 12
      and v.ds_cargo = 'DEPUTADO ESTADUAL'
    group by v.sq_candidato
)
insert into dbo.dim_candidato_partido (
    nk_candidato, nr_candidato, nm_urna_candidato, ds_cargo, sg_partido, sg_federacao, fl_concorrente_regional
)
select
    ct.nk_candidato,
    left(ct.nr_candidato, 10),
    left(ct.nm_urna_candidato, 100),
    left(ct.ds_cargo, 50),
    left(coalesce(ct.sg_partido, 'N/A'), 20),
    left(ct.sg_federacao, 50),
    case
        when cc.votos_totais_estado > 0
         and (cc.votos_regiao * 1.0 / cc.votos_totais_estado) >= 0.50
        then 1 else 0
    end as fl_concorrente_regional
from candidatos_todos ct
left join #concentracao cc
    on cc.sq_candidato = ct.nk_candidato
where not exists (
    select 1 from dbo.dim_candidato_partido d where d.nk_candidato = ct.nk_candidato
);
go

-- 5. legendas partidarias (2 digitos, exceto 95 e 96), unindo as duas eleicoes
with legendas as (
    select distinct nr_votavel
    from dbo.staging_votacaosecao_2022_sp
    where len(nr_votavel) = 2 and nr_votavel not in ('95', '96')
    union
    select distinct nr_votavel
    from dbo.staging_votacaosecao_2018_sp
    where len(nr_votavel) = 2 and nr_votavel not in ('95', '96')
)
insert into dbo.dim_candidato_partido (
    nk_candidato, nr_candidato, nm_urna_candidato, ds_cargo, sg_partido, sg_federacao, fl_concorrente_regional
)
select
    l.nr_votavel,
    l.nr_votavel,
    concat('VOTO DE LEGENDA - PARTIDO ', l.nr_votavel),
    'DEPUTADO ESTADUAL',
    left(coalesce(mp.sg_partido, concat('PTDO_', l.nr_votavel)), 20),
    coalesce(mp.sg_federacao, 'SEM FEDERAÇÃO'),
    0
from legendas l
left join #mapa_partido mp
    on mp.nr_partido = try_cast(l.nr_votavel as int)
where not exists (
    select 1 from dbo.dim_candidato_partido d where d.nk_candidato = l.nr_votavel
);
go

drop table #mapa_partido;
drop table #concentracao;
go
