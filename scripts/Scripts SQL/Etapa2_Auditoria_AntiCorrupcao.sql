/* =====================================================================
   ETAPA 2 - AUDITORIA ANTI-CORRUPCAO E RECONCILIACAO CSV x BANCO
   ===================================================================== */
set nocount on;

print '=== 1. AUDITORIA DA VOTACAO 2018 (BRUTA) ===';
select 
    count(*) as Linhas_Bruta,
    count(distinct CD_MUNICIPIO) as Mun_Distintos,
    count(distinct NR_LOCAL_VOTACAO) as Locais_Distintos,
    sum(case when ANO_ELEICAO <> '2018' then 1 else 0 end) as Anos_Invalidos,
    sum(case when SG_UF <> 'SP' then 1 else 0 end) as UFs_Invalidas,
    sum(case when CD_CARGO <> '7' then 1 else 0 end) as Cargos_Diferente_7,
    sum(case when try_cast(QT_VOTOS as int) is null or try_cast(QT_VOTOS as int) < 0 then 1 else 0 end) as Votos_Corrompidos,
    sum(cast(QT_VOTOS as bigint)) as Total_Votos_Validados
from dbo.VotacaoSecao_2018_SP_Bruta;

print 'Amostra de texto e acentuacao 2018:';
select top 3 CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, NR_VOTAVEL, NM_VOTAVEL, QT_VOTOS
from dbo.VotacaoSecao_2018_SP_Bruta
where NM_MUNICIPIO like '%S_O%';

print '=== 2. AUDITORIA DO PERFIL ELEITORAL 2022 (BRUTA) ===';
select 
    count(*) as Linhas_Bruta,
    count(distinct CD_MUNICIPIO) as Mun_Distintos,
    count(distinct NR_LOCAL_VOTACAO) as Locais_Distintos,
    sum(case when ANO_ELEICAO <> '2022' then 1 else 0 end) as Anos_Invalidos,
    sum(case when SG_UF <> 'SP' then 1 else 0 end) as UFs_Invalidas,
    sum(case when try_cast(QT_ELEITORES_PERFIL as int) is null then 1 else 0 end) as Nao_Numericos,
    sum(case when try_cast(QT_ELEITORES_PERFIL as int) < 0 then 1 else 0 end) as Qtd_Negativos,
    sum(cast(QT_ELEITORES_PERFIL as bigint)) as Total_Eleitores_SP_2022
from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;

print 'Amostra de colunas demograficas 2022:';
select top 3 CD_MUNICIPIO, NM_MUNICIPIO, NR_LOCAL_VOTACAO, DS_GENERO, DS_FAIXA_ETARIA, DS_GRAU_ESCOLARIDADE, QT_ELEITORES_PERFIL
from dbo.Perfil_Eleitor_Secao_2022_SP_Bruta;

print '=== 3. AUDITORIA DOS CANDIDATOS 2018 (BRUTA) ===';
select 
    count(*) as Total_Candidatos,
    sum(case when DS_CARGO = 'DEPUTADO ESTADUAL' then 1 else 0 end) as Total_Deputado_Estadual,
    count(distinct SQ_CANDIDATO) as SQ_Distintos,
    count(distinct SG_PARTIDO) as Partidos_Distintos
from dbo.Consulta_Cand_2018_SP_Bruta;
