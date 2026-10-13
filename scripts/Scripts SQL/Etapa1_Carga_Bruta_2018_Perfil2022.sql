/* =====================================================================
   ETAPA 1 - CARGA BRUTA (camada landing) - padrao Bloco 0 do aula5-staging.sql
   ===================================================================== */

-- 1. Votacao 2018 SP (Filtro Cargo 7 - Deputado Estadual)
if object_id('dbo.VotacaoSecao_2018_SP_Bruta', 'u') is not null drop table dbo.VotacaoSecao_2018_SP_Bruta;

create table dbo.VotacaoSecao_2018_SP_Bruta (
    DT_GERACAO varchar(500),
    HH_GERACAO varchar(500),
    ANO_ELEICAO varchar(500),
    CD_TIPO_ELEICAO varchar(500),
    NM_TIPO_ELEICAO varchar(500),
    NR_TURNO varchar(500),
    CD_ELEICAO varchar(500),
    DS_ELEICAO varchar(500),
    DT_ELEICAO varchar(500),
    TP_ABRANGENCIA varchar(500),
    SG_UF varchar(500),
    SG_UE varchar(500),
    NM_UE varchar(500),
    CD_MUNICIPIO varchar(500),
    NM_MUNICIPIO varchar(500),
    NR_ZONA varchar(500),
    NR_SECAO varchar(500),
    CD_CARGO varchar(500),
    DS_CARGO varchar(500),
    NR_VOTAVEL varchar(500),
    NM_VOTAVEL varchar(500),
    QT_VOTOS varchar(500),
    NR_LOCAL_VOTACAO varchar(500),
    SQ_CANDIDATO varchar(500),
    NM_LOCAL_VOTACAO varchar(500),
    DS_LOCAL_VOTACAO_ENDERECO varchar(500)
);

print 'Iniciando carga de VotacaoSecao_2018_SP_Bruta...';
bulk insert dbo.VotacaoSecao_2018_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\votacao_secao_2018_SP_FiltroCargo7_DeputadoEstadual.csv'
with (
    format = 'csv',
    fieldterminator = ';',
    rowterminator = '0x0d0a',
    firstrow = 2,
    codepage = 'ACP',
    tablock
);

-- 2. Perfil Eleitorado 2022 SP (Original com 31 colunas)
if object_id('dbo.Perfil_Eleitor_Secao_2022_SP_Bruta', 'u') is not null drop table dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;

create table dbo.Perfil_Eleitor_Secao_2022_SP_Bruta (
    DT_GERACAO varchar(500),
    HH_GERACAO varchar(500),
    ANO_ELEICAO varchar(500),
    SG_UF varchar(500),
    CD_MUNICIPIO varchar(500),
    NM_MUNICIPIO varchar(500),
    NR_ZONA varchar(500),
    NR_SECAO varchar(500),
    NR_LOCAL_VOTACAO varchar(500),
    NM_LOCAL_VOTACAO varchar(500),
    CD_GENERO varchar(500),
    DS_GENERO varchar(500),
    CD_ESTADO_CIVIL varchar(500),
    DS_ESTADO_CIVIL varchar(500),
    CD_FAIXA_ETARIA varchar(500),
    DS_FAIXA_ETARIA varchar(500),
    CD_GRAU_ESCOLARIDADE varchar(500),
    DS_GRAU_ESCOLARIDADE varchar(500),
    CD_RACA_COR varchar(500),
    DS_RACA_COR varchar(500),
    CD_IDENTIDADE_GENERO varchar(500),
    DS_IDENTIDADE_GENERO varchar(500),
    CD_QUILOMBOLA varchar(500),
    DS_QUILOMBOLA varchar(500),
    CD_INTERPRETE_LIBRAS varchar(500),
    DS_INTERPRETE_LIBRAS varchar(500),
    TP_OBRIGATORIEDADE_VOTO varchar(500),
    QT_ELEITORES_PERFIL varchar(500),
    QT_ELEITORES_BIOMETRIA varchar(500),
    QT_ELEITORES_DEFICIENCIA varchar(500),
    QT_ELEITORES_INC_NM_SOCIAL varchar(500)
);

print 'Iniciando carga de Perfil_Eleitor_Secao_2022_SP_Bruta...';
bulk insert dbo.Perfil_Eleitor_Secao_2022_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\perfil_eleitor_secao_2022_SP.csv'
with (
    format = 'csv',
    fieldterminator = ';',
    rowterminator = '0x0d0a',
    firstrow = 2,
    codepage = 'ACP',
    tablock
);

-- Conferência rápida
select 'VotacaoSecao_2018_SP_Bruta' as TABELA, count(*) as LINHAS_CARREGADAS from dbo.VotacaoSecao_2018_SP_Bruta
union all
select 'Perfil_Eleitor_Secao_2022_SP_Bruta', count(*) from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta
union all
select 'Consulta_Cand_2018_SP_Bruta', count(*) from dbo.Consulta_Cand_2018_SP_Bruta;
