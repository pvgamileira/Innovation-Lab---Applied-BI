if object_id('dbo.fato_comparecimento_abstencao_bkp', 'u') is not null drop table dbo.fato_comparecimento_abstencao_bkp;
if object_id('dbo.fato_comparecimento_abstencao', 'u') is not null select * into dbo.fato_comparecimento_abstencao_bkp from dbo.fato_comparecimento_abstencao;
if object_id('dbo.fato_comparecimento_abstencao', 'u') is not null drop table dbo.fato_comparecimento_abstencao;

create table dbo.fato_comparecimento_abstencao (
    sk_comparecimento_abstencao int identity(1,1) not null,
    sk_eleicao int not null,
    sk_local_votacao int not null,
    nr_secao varchar(10) not null,
    qt_aptos int not null,
    qt_comparecimento int not null,
    qt_abstencao int not null,
    constraint pk_fato_comparecimento_abstencao primary key (sk_comparecimento_abstencao),
    constraint fk_fato_comparecimento_abstencao_eleicao foreign key (sk_eleicao) references dbo.dim_eleicao (sk_eleicao),
    constraint fk_fato_comparecimento_abstencao_localvotacao foreign key (sk_local_votacao) references dbo.dim_local_votacao (sk_local_votacao),
    constraint ck_fato_comparecimento_abstencao_aptos check (qt_aptos >= 0),
    constraint ck_fato_comparecimento_abstencao_comparecimento check (qt_comparecimento >= 0),
    constraint ck_fato_comparecimento_abstencao_abstencao check (qt_abstencao >= 0)
);

insert into dbo.fato_comparecimento_abstencao (sk_eleicao, sk_local_votacao, nr_secao, qt_aptos, qt_comparecimento, qt_abstencao)
select 
    20221002 as sk_eleicao,
    dlv.sk_local_votacao,
    d.nr_secao,
    sum(d.qt_aptos) as qt_aptos,
    sum(d.qt_comparecimento) as qt_comparecimento,
    sum(d.qt_abstencoes) as qt_abstencao
from staging_detalhevotacaosecao_2022_sp d
inner join dbo.dim_local_votacao dlv on concat(d.cd_municipio, '_', d.nr_zona, '_', d.nr_local_votacao) = dlv.nk_local_votacao
group by dlv.sk_local_votacao, d.nr_secao;
