-- 01_dim_eleicao.sql
-- dimensao tempo/pleito: carga estatica de 2018 e 2022 (1o e 2o turno)
-- pk: sk_eleicao no formato aaaammdd

use innovationlab_appliedbi;
go

-- a fato depende desta dimensao: remove antes para permitir recarga idempotente
if object_id('dbo.fato_votacao', 'u') is not null
    drop table dbo.fato_votacao;

if object_id('dbo.dim_eleicao', 'u') is not null
    drop table dbo.dim_eleicao;
go

create table dbo.dim_eleicao (
    sk_eleicao int not null,
    dt_eleicao date not null,
    nr_ano smallint not null,
    nr_turno tinyint not null,
    ds_eleicao varchar(100) not null,
    constraint pk_dim_eleicao primary key (sk_eleicao),
    constraint uq_dim_eleicao_dataturno unique (dt_eleicao, nr_turno)
);
go

insert into dbo.dim_eleicao (sk_eleicao, dt_eleicao, nr_ano, nr_turno, ds_eleicao)
values
    (20181007, '2018-10-07', 2018, 1, 'ELEIÇÕES GERAIS 2018 - 1º TURNO'),
    (20181028, '2018-10-28', 2018, 2, 'ELEIÇÕES GERAIS 2018 - 2º TURNO'),
    (20221002, '2022-10-02', 2022, 1, 'ELEIÇÕES GERAIS 2022 - 1º TURNO'),
    (20221030, '2022-10-30', 2022, 2, 'ELEIÇÕES GERAIS 2022 - 2º TURNO');
go
