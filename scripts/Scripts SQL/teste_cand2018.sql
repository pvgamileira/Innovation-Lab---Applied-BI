if object_id('dbo.Consulta_Cand_2018_SP_Bruta', 'u') is not null drop table dbo.Consulta_Cand_2018_SP_Bruta;
create table dbo.Consulta_Cand_2018_SP_Bruta (
    DT_GERACAO varchar(500), HH_GERACAO varchar(500), ANO_ELEICAO varchar(500), CD_TIPO_ELEICAO varchar(500), NM_TIPO_ELEICAO varchar(500), NR_TURNO varchar(500), CD_ELEICAO varchar(500), DS_ELEICAO varchar(500), DT_ELEICAO varchar(500), TP_ABRANGENCIA varchar(500), SG_UF varchar(500), SG_UE varchar(500), NM_UE varchar(500), CD_CARGO varchar(500), DS_CARGO varchar(500), SQ_CANDIDATO varchar(500), NR_CANDIDATO varchar(500), NM_CANDIDATO varchar(500), NM_URNA_CANDIDATO varchar(500), NM_SOCIAL_CANDIDATO varchar(500), NR_CPF_CANDIDATO varchar(500), DS_EMAIL varchar(500), CD_SITUACAO_CANDIDATURA varchar(500), DS_SITUACAO_CANDIDATURA varchar(500), TP_AGREMIACAO varchar(500), NR_PARTIDO varchar(500), SG_PARTIDO varchar(500), NM_PARTIDO varchar(500), NR_FEDERACAO varchar(500), NM_FEDERACAO varchar(500), SG_FEDERACAO varchar(500), DS_COMPOSICAO_FEDERACAO varchar(max), SQ_COLIGACAO varchar(500), NM_COLIGACAO varchar(max), DS_COMPOSICAO_COLIGACAO varchar(max), SG_UF_NASCIMENTO varchar(500), DT_NASCIMENTO varchar(500), NR_TITULO_ELEITORAL_CANDIDATO varchar(500), CD_GENERO varchar(500), DS_GENERO varchar(500), CD_GRAU_INSTRUCAO varchar(500), DS_GRAU_INSTRUCAO varchar(500), CD_ESTADO_CIVIL varchar(500), DS_ESTADO_CIVIL varchar(500), CD_COR_RACA varchar(500), DS_COR_RACA varchar(500), CD_OCUPACAO varchar(500), DS_OCUPACAO varchar(500), CD_SIT_TOT_TURNO varchar(500), DS_SIT_TOT_TURNO varchar(500)
);
bulk insert dbo.Consulta_Cand_2018_SP_Bruta
from 'C:\Innovation-Lab---Applied-BI\CSV - TSE\consulta_cand_2018_SP.csv'
with (
    format = 'csv',
    fieldterminator = ';',
    rowterminator = '0x0d0a',
    firstrow = 2,
    codepage = 'ACP',
    tablock
);
select count(*) as Linhas, count(distinct SQ_CANDIDATO) as Cand_Unicos, max(ANO_ELEICAO) as Ano, max(SG_UF) as UF from dbo.Consulta_Cand_2018_SP_Bruta;
select top 3 SQ_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, SG_PARTIDO, DS_CARGO from dbo.Consulta_Cand_2018_SP_Bruta where DS_CARGO like '%ESTADUAL%';
