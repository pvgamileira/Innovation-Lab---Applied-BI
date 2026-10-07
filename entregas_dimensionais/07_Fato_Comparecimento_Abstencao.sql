if object_id('dbo.Fato_Comparecimento_Abstencao', 'u') is not null drop table dbo.Fato_Comparecimento_Abstencao;

create table dbo.Fato_Comparecimento_Abstencao (
    SK_COMPARECIMENTO_ABSTENCAO int identity(1,1) not null,
    SK_ELEICAO int not null,
    SK_LOCAL_VOTACAO int not null,
    NR_SECAO varchar(10) not null,
    QT_APTOS int not null,
    QT_COMPARECIMENTO int not null,
    QT_ABSTENCAO int not null,
    constraint PK_Fato_Comparecimento_Abstencao primary key (SK_COMPARECIMENTO_ABSTENCAO),
    constraint FK_Fato_Comparecimento_Abstencao_Eleicao foreign key (SK_ELEICAO) references dbo.Dim_Eleicao (SK_ELEICAO),
    constraint FK_Fato_Comparecimento_Abstencao_LocalVotacao foreign key (SK_LOCAL_VOTACAO) references dbo.Dim_Local_Votacao (SK_LOCAL_VOTACAO),
    constraint CK_Fato_Comparecimento_Abstencao_Aptos check (QT_APTOS >= 0),
    constraint CK_Fato_Comparecimento_Abstencao_Comparecimento check (QT_COMPARECIMENTO >= 0),
    constraint CK_Fato_Comparecimento_Abstencao_Abstencao check (QT_ABSTENCAO >= 0)
);

insert into dbo.Fato_Comparecimento_Abstencao (SK_ELEICAO, SK_LOCAL_VOTACAO, NR_SECAO, QT_APTOS, QT_COMPARECIMENTO, QT_ABSTENCAO)
select 
    20221002 as SK_ELEICAO,
    dlv.SK_LOCAL_VOTACAO,
    d.NR_SECAO,
    sum(d.QT_APTOS) as QT_APTOS,
    sum(d.QT_COMPARECIMENTO) as QT_COMPARECIMENTO,
    sum(d.QT_ABSTENCOES) as QT_ABSTENCAO
from dbo.Staging_DetalheVotacaoSecao_2022_SP d
inner join dbo.Dim_Local_Votacao dlv on concat_ws('_', d.CD_MUNICIPIO, d.NR_ZONA, d.NR_LOCAL_VOTACAO) = dlv.NK_LOCAL_VOTACAO
group by dlv.SK_LOCAL_VOTACAO, d.NR_SECAO;
