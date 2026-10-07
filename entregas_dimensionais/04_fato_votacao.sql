-- 04_fato_votacao.sql
-- fato: um registro por secao / candidato (ou tipo de voto) por eleicao
-- empilha 2018 + 2022 com union all e resgata as sks das 3 dimensoes
-- lookup do candidato: sq_candidato (12 digitos) -> legenda/branco/nulo pelo nr_votavel (2 digitos) -> fallback '-1'

use innovationlab_appliedbi;
go

if object_id('dbo.fato_votacao', 'u') is not null
    drop table dbo.fato_votacao;
go

create table dbo.fato_votacao (
    sk_votacao int identity(1,1) not null,
    sk_eleicao int not null,
    sk_local_votacao int not null,
    sk_candidato_partido int not null,
    nr_secao varchar(10) not null,
    qt_votos int not null,
    constraint pk_fato_votacao primary key (sk_votacao),
    constraint fk_fato_votacao_eleicao foreign key (sk_eleicao)
        references dbo.dim_eleicao (sk_eleicao),
    constraint fk_fato_votacao_local_votacao foreign key (sk_local_votacao)
        references dbo.dim_local_votacao (sk_local_votacao),
    constraint fk_fato_votacao_candidato_partido foreign key (sk_candidato_partido)
        references dbo.dim_candidato_partido (sk_candidato_partido),
    constraint ck_fato_votacao_qt_votos check (qt_votos >= 0)
);
go

with votos_empilhados as (
    select
        cast(ano_eleicao as smallint) as nr_ano,
        cast(nr_turno as tinyint) as nr_turno,
        cd_municipio, nr_zona, nr_local_votacao, nr_secao,
        nr_votavel, sq_candidato, qt_votos
    from dbo.staging_votacaosecao_2018_sp
    union all
    select
        cast(ano_eleicao as smallint) as nr_ano,
        cast(nr_turno as tinyint) as nr_turno,
        cd_municipio, nr_zona, nr_local_votacao, nr_secao,
        nr_votavel, sq_candidato, qt_votos
    from dbo.staging_votacaosecao_2022_sp
),
chave_candidato as (
    select sk_candidato_partido as sk_nao_identificado
    from dbo.dim_candidato_partido
    where nk_candidato = '-1'
)
insert into dbo.fato_votacao (
    sk_eleicao,
    sk_local_votacao,
    sk_candidato_partido,
    nr_secao,
    qt_votos
)
select
    de.sk_eleicao,
    dlv.sk_local_votacao,
    coalesce(dcp.sk_candidato_partido, ck.sk_nao_identificado) as sk_candidato_partido,
    left(v.nr_secao, 10),
    v.qt_votos
from votos_empilhados v
inner join dbo.dim_eleicao de
    on de.nr_ano = v.nr_ano
   and de.nr_turno = v.nr_turno
inner join dbo.dim_local_votacao dlv
    on dlv.nk_local_votacao = concat_ws('_', v.cd_municipio, v.nr_zona, v.nr_local_votacao)
left join dbo.dim_candidato_partido dcp
    on dcp.nk_candidato = case
        when len(v.sq_candidato) = 12 then v.sq_candidato
        when len(v.nr_votavel) = 2 then v.nr_votavel
        else '-1'
    end
cross join chave_candidato ck;
go
