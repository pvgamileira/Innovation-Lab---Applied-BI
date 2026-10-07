if object_id('dbo.Dim_Perfil_Demografico', 'u') is not null drop table dbo.Dim_Perfil_Demografico;

create table dbo.Dim_Perfil_Demografico (
    SK_PERFIL_DEMOGRAFICO int identity(1,1) not null,
    NK_PERFIL_DEMOGRAFICO varchar(50) not null,
    CD_FAIXA_ETARIA int not null,
    DS_FAIXA_ETARIA varchar(50) not null,
    CD_ESCOLARIDADE int not null,
    DS_ESCOLARIDADE varchar(100) not null,
    CD_GENERO int not null,
    DS_GENERO varchar(50) not null,
    constraint PK_Dim_Perfil_Demografico primary key (SK_PERFIL_DEMOGRAFICO),
    constraint UQ_Dim_Perfil_Demografico_NK unique (NK_PERFIL_DEMOGRAFICO)
);

insert into dbo.Dim_Perfil_Demografico (NK_PERFIL_DEMOGRAFICO, CD_FAIXA_ETARIA, DS_FAIXA_ETARIA, CD_ESCOLARIDADE, DS_ESCOLARIDADE, CD_GENERO, DS_GENERO)
values ('-1_-1_-1', -1, 'NÃO INFORMADO', -1, 'NÃO INFORMADO', -1, 'NÃO INFORMADO');

insert into dbo.Dim_Perfil_Demografico (NK_PERFIL_DEMOGRAFICO, CD_FAIXA_ETARIA, DS_FAIXA_ETARIA, CD_ESCOLARIDADE, DS_ESCOLARIDADE, CD_GENERO, DS_GENERO)
select distinct
    concat(coalesce(CD_FAIXA_ETARIA, -1), '_', coalesce(CD_GRAU_ESCOLARIDADE, -1), '_', coalesce(CD_GENERO, -1)) as NK_PERFIL_DEMOGRAFICO,
    coalesce(CD_FAIXA_ETARIA, -1) as CD_FAIXA_ETARIA,
    coalesce(upper(DS_FAIXA_ETARIA), 'NÃO INFORMADO') as DS_FAIXA_ETARIA,
    coalesce(CD_GRAU_ESCOLARIDADE, -1) as CD_ESCOLARIDADE,
    coalesce(upper(DS_GRAU_ESCOLARIDADE), 'NÃO INFORMADO') as DS_ESCOLARIDADE,
    coalesce(CD_GENERO, -1) as CD_GENERO,
    coalesce(upper(DS_GENERO), 'NÃO INFORMADO') as DS_GENERO
from dbo.Staging_Perfil_Eleitor_Secao_2022;
