if object_id('dbo.Fato_Votacao', 'u') is not null drop table dbo.Fato_Votacao;

create table dbo.Fato_Votacao (
    SK_VOTACAO int identity(1,1) not null,
    SK_ELEICAO int not null,
    SK_LOCAL_VOTACAO int not null,
    SK_CANDIDATO_PARTIDO int not null,
    NR_SECAO varchar(10) not null,
    QT_VOTOS int not null,
    constraint PK_Fato_Votacao primary key (SK_VOTACAO),
    constraint FK_Fato_Votacao_Eleicao foreign key (SK_ELEICAO) references dbo.Dim_Eleicao (SK_ELEICAO),
    constraint FK_Fato_Votacao_LocalVotacao foreign key (SK_LOCAL_VOTACAO) references dbo.Dim_Local_Votacao (SK_LOCAL_VOTACAO),
    constraint FK_Fato_Votacao_CandidatoPartido foreign key (SK_CANDIDATO_PARTIDO) references dbo.Dim_Candidato_Partido (SK_CANDIDATO_PARTIDO),
    constraint CK_Fato_Votacao_QT_Votos check (QT_VOTOS >= 0)
);

insert into dbo.Fato_Votacao (SK_ELEICAO, SK_LOCAL_VOTACAO, SK_CANDIDATO_PARTIDO, NR_SECAO, QT_VOTOS)
select 
    20221002 as SK_ELEICAO,
    dlv.SK_LOCAL_VOTACAO,
    coalesce(dcp.SK_CANDIDATO_PARTIDO, dleg.SK_CANDIDATO_PARTIDO, case when v.NR_VOTAVEL = '95' then (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '95') when v.NR_VOTAVEL = '96' then (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '96') else (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '-1') end) as SK_CANDIDATO_PARTIDO,
    v.NR_SECAO,
    v.QT_VOTOS
from dbo.Staging_VotacaoSecao_2022_SP v
inner join dbo.Dim_Local_Votacao dlv on concat_ws('_', v.CD_MUNICIPIO, v.NR_ZONA, v.NR_LOCAL_VOTACAO) = dlv.NK_LOCAL_VOTACAO
left join dbo.Dim_Candidato_Partido dcp on cast(v.SQ_CANDIDATO as varchar(20)) = dcp.NK_CANDIDATO
left join dbo.Dim_Candidato_Partido dleg on len(v.NR_VOTAVEL) = 2 and left(v.NR_VOTAVEL, 2) = dleg.NK_CANDIDATO;

insert into dbo.Fato_Votacao (SK_ELEICAO, SK_LOCAL_VOTACAO, SK_CANDIDATO_PARTIDO, NR_SECAO, QT_VOTOS)
select 
    20181007 as SK_ELEICAO,
    dlv.SK_LOCAL_VOTACAO,
    coalesce(dcp.SK_CANDIDATO_PARTIDO, dleg.SK_CANDIDATO_PARTIDO, case when v.NR_VOTAVEL = '95' then (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '95') when v.NR_VOTAVEL = '96' then (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '96') else (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '-1') end) as SK_CANDIDATO_PARTIDO,
    v.NR_SECAO,
    v.QT_VOTOS
from dbo.Staging_VotacaoSecao_2018_SP v
inner join dbo.Dim_Local_Votacao dlv on concat_ws('_', v.CD_MUNICIPIO, v.NR_ZONA, v.NR_LOCAL_VOTACAO) = dlv.NK_LOCAL_VOTACAO
left join dbo.Dim_Candidato_Partido dcp on cast(v.SQ_CANDIDATO as varchar(20)) = dcp.NK_CANDIDATO
left join dbo.Dim_Candidato_Partido dleg on len(v.NR_VOTAVEL) = 2 and left(v.NR_VOTAVEL, 2) = dleg.NK_CANDIDATO;
