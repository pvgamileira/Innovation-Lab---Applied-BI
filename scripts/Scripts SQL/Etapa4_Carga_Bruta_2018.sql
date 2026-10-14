/* =====================================================================
   ETAPA 4 - CARGA BRUTA 2018 (somente 2018; nao carrega o perfil 2022 de 4 GB)
   CSV do TSE em Latin1 -> codepage = 'ACP' (1252). Este arquivo e ASCII puro.
   ===================================================================== */
set nocount on;

if object_id('dbo.VotacaoSecao_2018_SP_Bruta', 'u') is not null drop table dbo.VotacaoSecao_2018_SP_Bruta;
create table dbo.VotacaoSecao_2018_SP_Bruta (
    DT_GERACAO varchar(500), HH_GERACAO varchar(500), ANO_ELEICAO varchar(500), CD_TIPO_ELEICAO varchar(500),
    NM_TIPO_ELEICAO varchar(500), NR_TURNO varchar(500), CD_ELEICAO varchar(500), DS_ELEICAO varchar(500),
    DT_ELEICAO varchar(500), TP_ABRANGENCIA varchar(500), SG_UF varchar(500), SG_UE varchar(500), NM_UE varchar(500),
    CD_MUNICIPIO varchar(500), NM_MUNICIPIO varchar(500), NR_ZONA varchar(500), NR_SECAO varchar(500),
    CD_CARGO varchar(500), DS_CARGO varchar(500), NR_VOTAVEL varchar(500), NM_VOTAVEL varchar(500),
    QT_VOTOS varchar(500), NR_LOCAL_VOTACAO varchar(500), SQ_CANDIDATO varchar(500),
    NM_LOCAL_VOTACAO varchar(500), DS_LOCAL_VOTACAO_ENDERECO varchar(500)
);

bulk insert dbo.VotacaoSecao_2018_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\votacao_secao_2018_SP_FiltroCargo7_DeputadoEstadual.csv'
with (format = 'csv', fieldterminator = ';', rowterminator = '0x0d0a', firstrow = 2, codepage = 'ACP', tablock, batchsize = 1000000);

if object_id('dbo.Consulta_Cand_2018_SP_Bruta', 'u') is not null drop table dbo.Consulta_Cand_2018_SP_Bruta;
create table dbo.Consulta_Cand_2018_SP_Bruta (
    DT_GERACAO varchar(500), HH_GERACAO varchar(500), ANO_ELEICAO varchar(500), CD_TIPO_ELEICAO varchar(500), NM_TIPO_ELEICAO varchar(500), NR_TURNO varchar(500), CD_ELEICAO varchar(500), DS_ELEICAO varchar(500), DT_ELEICAO varchar(500), TP_ABRANGENCIA varchar(500), SG_UF varchar(500), SG_UE varchar(500), NM_UE varchar(500), CD_CARGO varchar(500), DS_CARGO varchar(500), SQ_CANDIDATO varchar(500), NR_CANDIDATO varchar(500), NM_CANDIDATO varchar(500), NM_URNA_CANDIDATO varchar(500), NM_SOCIAL_CANDIDATO varchar(500), NR_CPF_CANDIDATO varchar(500), DS_EMAIL varchar(500), CD_SITUACAO_CANDIDATURA varchar(500), DS_SITUACAO_CANDIDATURA varchar(500), TP_AGREMIACAO varchar(500), NR_PARTIDO varchar(500), SG_PARTIDO varchar(500), NM_PARTIDO varchar(500), NR_FEDERACAO varchar(500), NM_FEDERACAO varchar(500), SG_FEDERACAO varchar(500), DS_COMPOSICAO_FEDERACAO varchar(max), SQ_COLIGACAO varchar(500), NM_COLIGACAO varchar(max), DS_COMPOSICAO_COLIGACAO varchar(max), SG_UF_NASCIMENTO varchar(500), DT_NASCIMENTO varchar(500), NR_TITULO_ELEITORAL_CANDIDATO varchar(500), CD_GENERO varchar(500), DS_GENERO varchar(500), CD_GRAU_INSTRUCAO varchar(500), DS_GRAU_INSTRUCAO varchar(500), CD_ESTADO_CIVIL varchar(500), DS_ESTADO_CIVIL varchar(500), CD_COR_RACA varchar(500), DS_COR_RACA varchar(500), CD_OCUPACAO varchar(500), DS_OCUPACAO varchar(500), CD_SIT_TOT_TURNO varchar(500), DS_SIT_TOT_TURNO varchar(500)
);

bulk insert dbo.Consulta_Cand_2018_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\consulta_cand_2018_SP.csv'
with (format = 'csv', fieldterminator = ';', rowterminator = '0x0d0a', firstrow = 2, codepage = 'ACP', tablock);

select 'VotacaoSecao_2018_SP_Bruta' as TABELA, count(*) as LINHAS, sum(cast(QT_VOTOS as bigint)) as VOTOS from dbo.VotacaoSecao_2018_SP_Bruta
union all
select 'Consulta_Cand_2018_SP_Bruta', count(*), null from dbo.Consulta_Cand_2018_SP_Bruta;
