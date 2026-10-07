if object_id('dbo.dim_perfil_demografico_bkp', 'u') is not null drop table dbo.dim_perfil_demografico_bkp;
if object_id('dbo.dim_perfil_demografico', 'u') is not null select * into dbo.dim_perfil_demografico_bkp from dbo.dim_perfil_demografico;
if object_id('dbo.dim_perfil_demografico', 'u') is not null drop table dbo.dim_perfil_demografico;

create table dbo.dim_perfil_demografico (
    sk_perfil_demografico int identity(1,1) not null,
    nk_perfil_demografico varchar(50) not null,
    cd_faixa_etaria int not null,
    ds_faixa_etaria varchar(50) not null,
    cd_escolaridade int not null,
    ds_escolaridade varchar(100) not null,
    cd_genero int not null,
    ds_genero varchar(50) not null,
    constraint pk_dim_perfil_demografico primary key (sk_perfil_demografico),
    constraint uq_dim_perfil_demografico_nk unique (nk_perfil_demografico)
);

insert into dbo.dim_perfil_demografico (nk_perfil_demografico, cd_faixa_etaria, ds_faixa_etaria, cd_escolaridade, ds_escolaridade, cd_genero, ds_genero)
values ('-1_-1_-1', -1, 'não informado', -1, 'não informado', -1, 'não informado');

insert into dbo.dim_perfil_demografico (nk_perfil_demografico, cd_faixa_etaria, ds_faixa_etaria, cd_escolaridade, ds_escolaridade, cd_genero, ds_genero)
select distinct
    concat(coalesce(cd_faixa_etaria, -1), '_', coalesce(cd_grau_escolaridade, -1), '_', coalesce(cd_genero, -1)) as nk_perfil_demografico,
    coalesce(cd_faixa_etaria, -1) as cd_faixa_etaria,
    coalesce(lower(ds_faixa_etaria), 'não informado') as ds_faixa_etaria,
    coalesce(cd_grau_escolaridade, -1) as cd_escolaridade,
    coalesce(lower(ds_grau_escolaridade), 'não informado') as ds_escolaridade,
    coalesce(cd_genero, -1) as cd_genero,
    coalesce(lower(ds_genero), 'não informado') as ds_genero
from staging_perfil_eleitor_secao_2022;
