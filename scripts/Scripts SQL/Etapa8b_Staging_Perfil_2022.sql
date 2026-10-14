/* ETAPA 8b - Staging_Perfil_Eleitor_Secao_2022 (com NR_LOCAL_VOTACAO e quantidades corretas). ASCII puro. */
set nocount on;
if object_id('dbo.Staging_Perfil_Eleitor_Secao_2022_NOVA', 'u') is not null drop table dbo.Staging_Perfil_Eleitor_Secao_2022_NOVA;
select
    trim(ANO_ELEICAO) as ANO_ELEICAO,
    upper(trim(SG_UF)) as SG_UF,
    trim(CD_MUNICIPIO) as CD_MUNICIPIO,
    upper(trim(NM_MUNICIPIO)) as NM_MUNICIPIO,
    trim(NR_ZONA) as NR_ZONA,
    trim(NR_SECAO) as NR_SECAO,
    trim(NR_LOCAL_VOTACAO) as NR_LOCAL_VOTACAO,
    upper(trim(NM_LOCAL_VOTACAO)) as NM_LOCAL_VOTACAO,
    try_cast(trim(CD_GENERO) as int) as CD_GENERO,
    upper(trim(DS_GENERO)) as DS_GENERO,
    try_cast(trim(CD_ESTADO_CIVIL) as int) as CD_ESTADO_CIVIL,
    upper(trim(DS_ESTADO_CIVIL)) as DS_ESTADO_CIVIL,
    try_cast(trim(CD_FAIXA_ETARIA) as int) as CD_FAIXA_ETARIA,
    upper(trim(DS_FAIXA_ETARIA)) as DS_FAIXA_ETARIA,
    try_cast(trim(CD_GRAU_ESCOLARIDADE) as int) as CD_GRAU_ESCOLARIDADE,
    upper(trim(DS_GRAU_ESCOLARIDADE)) as DS_GRAU_ESCOLARIDADE,
    isnull(try_cast(trim(QT_ELEITORES_PERFIL) as int), 0) as QT_ELEITORES_PERFIL,
    isnull(try_cast(trim(QT_ELEITORES_BIOMETRIA) as int), 0) as QT_ELEITORES_BIOMETRIA,
    isnull(try_cast(trim(QT_ELEITORES_DEFICIENCIA) as int), 0) as QT_ELEITORES_DEFICIENCIA,
    isnull(try_cast(trim(QT_ELEITORES_INC_NM_SOCIAL) as int), 0) as QT_ELEITORES_INC_NM_SOCIAL
into dbo.Staging_Perfil_Eleitor_Secao_2022_NOVA
from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;
