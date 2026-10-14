/* =====================================================================
   ETAPA 5 - STAGINGS 2018 (estrutura identica a Staging_VotacaoSecao_2022_SP)
   - Texto em maiusculas/trim; acentos preservados (CSV Latin1 -> varchar Latin1)
   - Nulos do TSE ('#NULO', '#NULO#', '', 'NULL') viram NULL de verdade
   - SQ_CANDIDATO preserva a convencao da 2022: -1 (branco/nulo), -3 (legenda)
   Arquivo ASCII puro (acentos via nchar nao necessarios aqui).
   ===================================================================== */
set nocount on;

if object_id('dbo.Staging_VotacaoSecao_2018_SP', 'u') is not null drop table dbo.Staging_VotacaoSecao_2018_SP;

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
        trim(SQ_CANDIDATO) as SQ_CANDIDATO,
        upper(trim(NM_LOCAL_VOTACAO)) as NM_LOCAL_VOTACAO,
        upper(trim(DS_LOCAL_VOTACAO_ENDERECO)) as DS_LOCAL_VOTACAO_ENDERECO,
        isnull(try_cast(trim(QT_VOTOS) as int), 0) as QT_VOTOS,
        row_number() over (
            partition by trim(CD_MUNICIPIO), trim(NR_ZONA), trim(NR_SECAO), trim(NR_VOTAVEL)
            order by (select null)
        ) as RN
    from dbo.VotacaoSecao_2018_SP_Bruta
)
select
    ANO_ELEICAO, CD_TIPO_ELEICAO, NM_TIPO_ELEICAO, NR_TURNO, CD_ELEICAO, DS_ELEICAO, DT_ELEICAO, TP_ABRANGENCIA,
    SG_UF, SG_UE, NM_UE, CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_SECAO, CD_CARGO, DS_CARGO, NR_VOTAVEL, NM_VOTAVEL,
    NR_LOCAL_VOTACAO, SQ_CANDIDATO, NM_LOCAL_VOTACAO, DS_LOCAL_VOTACAO_ENDERECO, QT_VOTOS
into dbo.Staging_VotacaoSecao_2018_SP
from Votacao_Numerada_2018
where RN = 1;
go

if object_id('dbo.Staging_Consulta_Cand_2018_SP', 'u') is not null drop table dbo.Staging_Consulta_Cand_2018_SP;

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
        nullif(nullif(upper(trim(SG_FEDERACAO)), '#NULO#'), '#NULO') as SG_FEDERACAO,
        row_number() over (partition by trim(SQ_CANDIDATO) order by (select null)) as RN
    from dbo.Consulta_Cand_2018_SP_Bruta
    where upper(trim(DS_CARGO)) = 'DEPUTADO ESTADUAL'
)
select ANO_ELEICAO, CD_CARGO, DS_CARGO, SQ_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO, NR_PARTIDO, SG_PARTIDO, SG_FEDERACAO
into dbo.Staging_Consulta_Cand_2018_SP
from Candidatos_Numerados_2018
where RN = 1;
go

go
select 'Staging_VotacaoSecao_2018_SP' as TABELA, count(*) as LINHAS, sum(cast(QT_VOTOS as bigint)) as VOTOS,
       sum(case when NR_LOCAL_VOTACAO is null then 1 else 0 end) as LOCAL_NULO from dbo.Staging_VotacaoSecao_2018_SP
union all
select 'Staging_Consulta_Cand_2018_SP', count(*), null, sum(case when SG_FEDERACAO is null then 1 else 0 end) from dbo.Staging_Consulta_Cand_2018_SP;

