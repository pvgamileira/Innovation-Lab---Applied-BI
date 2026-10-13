/* =====================================================================
   ETAPA 3 - CRIACAO DAS STAGINGS DEFINITIVAS
   Seguindo rigorosamente o padrao do professor (aula5-staging.sql):
   - Bloco 4: CTE com ROW_NUMBER() para deduplicacao
   - Bloco 5: Tratamento de tipos (TRY_CAST / TRIM) e padronizacao (UPPER)
   - Bloco 6: SELECT INTO para materializar a Staging
   - Bloco 7: Auditoria pos-carga
   ===================================================================== */
set nocount on;
go

-- ---------------------------------------------------------------------
-- 1. Staging_VotacaoSecao_2018_SP (Estrutura IDENTICA a de 2022)
-- ---------------------------------------------------------------------
if object_id('dbo.Staging_VotacaoSecao_2018_SP', 'u') is not null 
    drop table dbo.Staging_VotacaoSecao_2018_SP;
go

with Votacao_Numerada_2018 as (
    select
        trim(ANO_ELEICAO) as ANO_ELEICAO,
        trim(CD_TIPO_ELEICAO) as CD_TIPO_ELEICAO,
        upper(trim(NM_TIPO_ELEICAO)) as NM_TIPO_ELEICAO,
        trim(NR_TURNO) as NR_TURNO,
        trim(CD_ELEICAO) as CD_ELEICAO,
        upper(trim(DS_ELEICAO)) as DS_ELEICAO,
        trim(DT_ELEICAO) as DT_ELEICAO,
        trim(TP_ABRANGENCIA) as TP_ABRANGENCIA,
        upper(trim(SG_UF)) as SG_UF,
        trim(SG_UE) as SG_UE,
        upper(trim(NM_UE)) as NM_UE,
        trim(CD_MUNICIPIO) as CD_MUNICIPIO,
        upper(trim(NM_MUNICIPIO)) as NM_MUNICIPIO,
        trim(NR_ZONA) as NR_ZONA,
        trim(NR_SECAO) as NR_SECAO,
        trim(CD_CARGO) as CD_CARGO,
        upper(trim(DS_CARGO)) as DS_CARGO,
        trim(NR_VOTAVEL) as NR_VOTAVEL,
        upper(trim(NM_VOTAVEL)) as NM_VOTAVEL,
        trim(NR_LOCAL_VOTACAO) as NR_LOCAL_VOTACAO,
        case 
            when trim(SQ_CANDIDATO) in ('#NULO', '', 'NULL') or SQ_CANDIDATO is null then '-1' 
            else trim(SQ_CANDIDATO) 
        end as SQ_CANDIDATO,
        upper(trim(NM_LOCAL_VOTACAO)) as NM_LOCAL_VOTACAO,
        upper(trim(DS_LOCAL_VOTACAO_ENDERECO)) as DS_LOCAL_VOTACAO_ENDERECO,
        try_cast(trim(QT_VOTOS) as int) as QT_VOTOS_TRATADO,
        row_number() over (
            partition by trim(CD_MUNICIPIO), trim(NR_ZONA), trim(NR_SECAO), trim(NR_VOTAVEL)
            order by (select null)
        ) as RN
    from dbo.VotacaoSecao_2018_SP_Bruta
)
select
    ANO_ELEICAO,
    CD_TIPO_ELEICAO,
    NM_TIPO_ELEICAO,
    NR_TURNO,
    CD_ELEICAO,
    DS_ELEICAO,
    DT_ELEICAO,
    TP_ABRANGENCIA,
    SG_UF,
    SG_UE,
    NM_UE,
    CD_MUNICIPIO,
    NM_MUNICIPIO,
    NR_ZONA,
    NR_SECAO,
    CD_CARGO,
    DS_CARGO,
    NR_VOTAVEL,
    NM_VOTAVEL,
    NR_LOCAL_VOTACAO,
    SQ_CANDIDATO,
    NM_LOCAL_VOTACAO,
    DS_LOCAL_VOTACAO_ENDERECO,
    isnull(QT_VOTOS_TRATADO, 0) as QT_VOTOS
into dbo.Staging_VotacaoSecao_2018_SP
from Votacao_Numerada_2018
where RN = 1;
go

-- ---------------------------------------------------------------------
-- 2. Staging_Consulta_Cand_2018_SP (Escopo: Deputado Estadual)
-- ---------------------------------------------------------------------
if object_id('dbo.Staging_Consulta_Cand_2018_SP', 'u') is not null 
    drop table dbo.Staging_Consulta_Cand_2018_SP;
go

with Candidatos_Numerados_2018 as (
    select
        trim(ANO_ELEICAO) as ANO_ELEICAO,
        trim(CD_CARGO) as CD_CARGO,
        upper(trim(DS_CARGO)) as DS_CARGO,
        trim(SQ_CANDIDATO) as SQ_CANDIDATO,
        trim(NR_CANDIDATO) as NR_CANDIDATO,
        upper(trim(NM_URNA_CANDIDATO)) as NM_URNA_CANDIDATO,
        trim(NR_PARTIDO) as NR_PARTIDO,
        upper(trim(SG_PARTIDO)) as SG_PARTIDO,
        coalesce(nullif(upper(trim(SG_FEDERACAO)), '#NULO'), 'SEM FEDERAÇÃO') as SG_FEDERACAO,
        row_number() over (
            partition by trim(SQ_CANDIDATO)
            order by (select null)
        ) as RN
    from dbo.Consulta_Cand_2018_SP_Bruta
    where upper(trim(DS_CARGO)) = 'DEPUTADO ESTADUAL'
)
select
    ANO_ELEICAO,
    CD_CARGO,
    DS_CARGO,
    SQ_CANDIDATO,
    NR_CANDIDATO,
    NM_URNA_CANDIDATO,
    NR_PARTIDO,
    SG_PARTIDO,
    SG_FEDERACAO
into dbo.Staging_Consulta_Cand_2018_SP
from Candidatos_Numerados_2018
where RN = 1;
go

-- ---------------------------------------------------------------------
-- 3. Staging_Perfil_Eleitor_Secao_2022 (Recriada com NR_LOCAL_VOTACAO e Dados Corretos)
-- ---------------------------------------------------------------------
if object_id('dbo.Staging_Perfil_Eleitor_Secao_2022', 'u') is not null 
    drop table dbo.Staging_Perfil_Eleitor_Secao_2022;
go

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
into dbo.Staging_Perfil_Eleitor_Secao_2022
from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;
go

-- ---------------------------------------------------------------------
-- 4. CONFERENCIA POS-CARGA (Bloco 7 do Professor)
-- ---------------------------------------------------------------------
print '=== CONFERENCIA STAGING VOTACAO 2018 ===';
select 
    (select count(*) from dbo.VotacaoSecao_2018_SP_Bruta) as Linhas_Bruta,
    count(*) as Linhas_Staging,
    sum(case when NR_LOCAL_VOTACAO is null then 1 else 0 end) as Linhas_Local_Nulo,
    sum(case when QT_VOTOS = 0 then 1 else 0 end) as Linhas_Voto_Zerado,
    sum(QT_VOTOS) as Total_Votos_Computados
from dbo.Staging_VotacaoSecao_2018_SP;

print '=== CONFERENCIA STAGING CANDIDATOS 2018 ===';
select count(*) as Total_Candidatos_DepEstadual_2018 from dbo.Staging_Consulta_Cand_2018_SP;

print '=== CONFERENCIA STAGING PERFIL ELEITORADO 2022 ===';
select 
    count(*) as Linhas_Staging_Perfil,
    sum(case when NR_LOCAL_VOTACAO is null then 1 else 0 end) as Linhas_Local_Nulo,
    sum(case when QT_ELEITORES_PERFIL < 0 then 1 else 0 end) as Linhas_Qtd_Negativa,
    sum(cast(QT_ELEITORES_PERFIL as bigint)) as Total_Eleitores_Mapeados
from dbo.Staging_Perfil_Eleitor_Secao_2022;
go
