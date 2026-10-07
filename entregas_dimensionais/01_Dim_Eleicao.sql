if object_id('dbo.Dim_Eleicao', 'u') is not null drop table dbo.Dim_Eleicao;

create table dbo.Dim_Eleicao (
    SK_ELEICAO int not null,
    DT_ELEICAO date not null,
    NR_ANO smallint not null,
    NR_TURNO tinyint not null,
    DS_ELEICAO varchar(100) not null,
    constraint PK_Dim_Eleicao primary key (SK_ELEICAO),
    constraint UQ_Dim_Eleicao_DataTurno unique (DT_ELEICAO, NR_TURNO)
);

insert into dbo.Dim_Eleicao (SK_ELEICAO, DT_ELEICAO, NR_ANO, NR_TURNO, DS_ELEICAO)
values 
    (20181007, '2018-10-07', 2018, 1, 'ELEIÇÕES GERAIS 2018 - 1º TURNO'),
    (20181028, '2018-10-28', 2018, 2, 'ELEIÇÕES GERAIS 2018 - 2º TURNO'),
    (20221002, '2022-10-02', 2022, 1, 'ELEIÇÕES GERAIS 2022 - 1º TURNO'),
    (20221030, '2022-10-30', 2022, 2, 'ELEIÇÕES GERAIS 2022 - 2º TURNO');
