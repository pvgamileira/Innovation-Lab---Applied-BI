/* ETAPA 8a - CARGA BRUTA do perfil do eleitorado 2022 SP (CSV TSE, Latin1, 31 colunas). ASCII puro. */
set nocount on;
if object_id('dbo.Perfil_Eleitor_Secao_2022_SP_Bruta', 'u') is not null drop table dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;
create table dbo.Perfil_Eleitor_Secao_2022_SP_Bruta (
    DT_GERACAO varchar(100), HH_GERACAO varchar(100), ANO_ELEICAO varchar(100), SG_UF varchar(100), CD_MUNICIPIO varchar(100),
    NM_MUNICIPIO varchar(200), NR_ZONA varchar(100), NR_SECAO varchar(100), NR_LOCAL_VOTACAO varchar(100), NM_LOCAL_VOTACAO varchar(300),
    CD_GENERO varchar(100), DS_GENERO varchar(100), CD_ESTADO_CIVIL varchar(100), DS_ESTADO_CIVIL varchar(100),
    CD_FAIXA_ETARIA varchar(100), DS_FAIXA_ETARIA varchar(100), CD_GRAU_ESCOLARIDADE varchar(100), DS_GRAU_ESCOLARIDADE varchar(200),
    CD_RACA_COR varchar(100), DS_RACA_COR varchar(100), CD_IDENTIDADE_GENERO varchar(100), DS_IDENTIDADE_GENERO varchar(100),
    CD_QUILOMBOLA varchar(100), DS_QUILOMBOLA varchar(100), CD_INTERPRETE_LIBRAS varchar(100), DS_INTERPRETE_LIBRAS varchar(100),
    TP_OBRIGATORIEDADE_VOTO varchar(100), QT_ELEITORES_PERFIL varchar(100), QT_ELEITORES_BIOMETRIA varchar(100),
    QT_ELEITORES_DEFICIENCIA varchar(100), QT_ELEITORES_INC_NM_SOCIAL varchar(100)
);
bulk insert dbo.Perfil_Eleitor_Secao_2022_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\perfil_eleitor_secao_2022_SP.csv'
with (format = 'csv', fieldterminator = ';', rowterminator = '0x0d0a', firstrow = 2, codepage = 'ACP', tablock, batchsize = 2000000);
select count(*) as LINHAS, sum(cast(QT_ELEITORES_PERFIL as bigint)) as ELEITORES from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;
