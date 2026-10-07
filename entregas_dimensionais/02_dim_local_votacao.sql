if object_id('dbo.Dim_Local_Votacao', 'u') is not null drop table dbo.Dim_Local_Votacao;

create table dbo.Dim_Local_Votacao (
    SK_LOCAL_VOTACAO int identity(1,1) not null,
    NK_LOCAL_VOTACAO varchar(50) not null,
    CD_MUNICIPIO int not null,
    NM_MUNICIPIO varchar(100) not null,
    NR_ZONA varchar(10) not null,
    NR_LOCAL_VOTACAO varchar(10) not null,
    NM_LOCAL_VOTACAO varchar(200) not null,
    SG_UF varchar(2) not null constraint DF_Dim_Local_Votacao_SG_UF default 'SP',
    FL_GRANDE_ABC bit not null constraint DF_Dim_Local_Votacao_ABC default 0,
    FL_RMSP bit not null constraint DF_Dim_Local_Votacao_RMSP default 0,
    constraint PK_Dim_Local_Votacao primary key (SK_LOCAL_VOTACAO),
    constraint UQ_Dim_Local_Votacao_NK unique (NK_LOCAL_VOTACAO)
);

with Locais_Unificados as (
    select
        2022 as NR_ANO, CD_MUNICIPIO, upper(NM_MUNICIPIO) as NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, upper(NM_LOCAL_VOTACAO) as NM_LOCAL_VOTACAO, coalesce(SG_UF, 'SP') as SG_UF
    from dbo.Staging_VotacaoSecao_2022_SP
    group by CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, SG_UF
    union
    select
        2018 as NR_ANO, CD_MUNICIPIO, upper(NM_MUNICIPIO) as NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, upper(NM_LOCAL_VOTACAO) as NM_LOCAL_VOTACAO, coalesce(SG_UF, 'SP') as SG_UF
    from dbo.Staging_VotacaoSecao_2018_SP
    group by CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, SG_UF
),
Locais_Agrupados as (
    select 
        concat_ws('_', CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO) as NK_LOCAL_VOTACAO,
        CD_MUNICIPIO, max(NM_MUNICIPIO) as NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, max(coalesce(NM_LOCAL_VOTACAO, 'LOCAL NÃO INFORMADO')) as NM_LOCAL_VOTACAO, max(SG_UF) as SG_UF
    from Locais_Unificados
    group by CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO
)
insert into dbo.Dim_Local_Votacao (NK_LOCAL_VOTACAO, CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, SG_UF, FL_GRANDE_ABC, FL_RMSP)
select 
    NK_LOCAL_VOTACAO, CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, SG_UF,
    case when NM_MUNICIPIO in ('SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL', 'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA') then 1 else 0 end as FL_GRANDE_ABC,
    case when NM_MUNICIPIO in ('SÃO PAULO', 'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL', 'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA', 'GUARULHOS', 'OSASCO', 'BARUERI', 'CARAPICUÍBA', 'COTIA', 'EMBU DAS ARTES', 'EMBU-GUAÇU', 'FERRAZ DE VASCONCELOS', 'FRANCISCO MORATO', 'FRANCO DA ROCHA', 'ITAPECERICA DA SERRA', 'ITAPEVI', 'ITAQUAQUECETUBA', 'JANDIRA', 'JUQUITIBA', 'MOGI DAS CRUZES', 'POÁ', 'SALESÓPOLIS', 'SANTA ISABEL', 'SANTANA DE PARNAÍBA', 'SUZANO', 'TABOÃO DA SERRA', 'VARGEM GRANDE PAULISTA', 'ARUJÁ', 'BIRITIBA MIRIM', 'CAIEIRAS', 'CAJAMAR', 'GUARAREMA', 'PIRAPORA DO BOM JESUS', 'SÃO LOURENÇO DA SERRA') then 1 else 0 end as FL_RMSP
from Locais_Agrupados;
