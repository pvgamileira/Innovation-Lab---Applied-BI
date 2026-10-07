if object_id('dbo.fato_perfil_eleitorado_bkp', 'u') is not null drop table dbo.fato_perfil_eleitorado_bkp;
if object_id('dbo.fato_perfil_eleitorado', 'u') is not null select * into dbo.fato_perfil_eleitorado_bkp from dbo.fato_perfil_eleitorado;
if object_id('dbo.fato_perfil_eleitorado', 'u') is not null drop table dbo.fato_perfil_eleitorado;

create table dbo.fato_perfil_eleitorado (
    sk_perfil_eleitorado int identity(1,1) not null,
    sk_eleicao int not null,
    sk_local_votacao int not null,
    sk_perfil_demografico int not null,
    nr_secao varchar(10) not null,
    qt_eleitores_perfil int not null,
    constraint pk_fato_perfil_eleitorado primary key (sk_perfil_eleitorado),
    constraint fk_fato_perfil_eleitorado_eleicao foreign key (sk_eleicao) references dbo.dim_eleicao (sk_eleicao),
    constraint fk_fato_perfil_eleitorado_localvotacao foreign key (sk_local_votacao) references dbo.dim_local_votacao (sk_local_votacao),
    constraint fk_fato_perfil_eleitorado_perfildemografico foreign key (sk_perfil_demografico) references dbo.dim_perfil_demografico (sk_perfil_demografico)
);

insert into dbo.fato_perfil_eleitorado (sk_eleicao, sk_local_votacao, sk_perfil_demografico, nr_secao, qt_eleitores_perfil)
select 
    20221002 as sk_eleicao,
    dlv.sk_local_votacao,
    coalesce(dpd.sk_perfil_demografico, (select sk_perfil_demografico from dbo.dim_perfil_demografico where nk_perfil_demografico = '-1_-1_-1')) as sk_perfil_demografico,
    p.nr_secao,
    p.qt_eleitores_perfil
from dbo.staging_perfil_eleitor_secao_2022 p
inner join dbo.dim_local_votacao dlv on concat_ws('_', p.cd_municipio, p.nr_zona, p.nr_secao) = dlv.nk_local_votacao
left join dbo.dim_perfil_demografico dpd on concat(coalesce(p.cd_faixa_etaria, -1), '_', coalesce(p.cd_grau_escolaridade, -1), '_', coalesce(p.cd_genero, -1)) = dpd.nk_perfil_demografico;
