if object_id('dbo.Fato_Perfil_Eleitorado', 'u') is not null drop table dbo.Fato_Perfil_Eleitorado;

create table dbo.Fato_Perfil_Eleitorado (
    SK_PERFIL_ELEITORADO int identity(1,1) not null,
    SK_ELEICAO int not null,
    SK_LOCAL_VOTACAO int not null,
    SK_PERFIL_DEMOGRAFICO int not null,
    NR_SECAO varchar(10) not null,
    QT_ELEITORES_PERFIL int not null,
    constraint PK_Fato_Perfil_Eleitorado primary key (SK_PERFIL_ELEITORADO),
    constraint FK_Fato_Perfil_Eleitorado_Eleicao foreign key (SK_ELEICAO) references dbo.Dim_Eleicao (SK_ELEICAO),
    constraint FK_Fato_Perfil_Eleitorado_LocalVotacao foreign key (SK_LOCAL_VOTACAO) references dbo.Dim_Local_Votacao (SK_LOCAL_VOTACAO),
    constraint FK_Fato_Perfil_Eleitorado_PerfilDemografico foreign key (SK_PERFIL_DEMOGRAFICO) references dbo.Dim_Perfil_Demografico (SK_PERFIL_DEMOGRAFICO)
);

insert into dbo.Fato_Perfil_Eleitorado (SK_ELEICAO, SK_LOCAL_VOTACAO, SK_PERFIL_DEMOGRAFICO, NR_SECAO, QT_ELEITORES_PERFIL)
select 
    20221002 as SK_ELEICAO,
    dlv.SK_LOCAL_VOTACAO,
    coalesce(dpd.SK_PERFIL_DEMOGRAFICO, (select SK_PERFIL_DEMOGRAFICO from dbo.Dim_Perfil_Demografico where NK_PERFIL_DEMOGRAFICO = '-1_-1_-1')) as SK_PERFIL_DEMOGRAFICO,
    p.NR_SECAO,
    p.QT_ELEITORES_PERFIL
from dbo.Staging_Perfil_Eleitor_Secao_2022 p
inner join dbo.Dim_Local_Votacao dlv on concat_ws('_', p.CD_MUNICIPIO, p.NR_ZONA, p.NR_SECAO) = dlv.NK_LOCAL_VOTACAO
left join dbo.Dim_Perfil_Demografico dpd on concat(coalesce(p.CD_FAIXA_ETARIA, -1), '_', coalesce(p.CD_GRAU_ESCOLARIDADE, -1), '_', coalesce(p.CD_GENERO, -1)) = dpd.NK_PERFIL_DEMOGRAFICO;
