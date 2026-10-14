set nocount on;
select 'Fato_Votacao' t, count(*) n, sum(cast(QT_VOTOS as bigint)) v from dbo.Fato_Votacao
union all select 'FV 2018', count(*), sum(cast(QT_VOTOS as bigint)) from dbo.Fato_Votacao where SK_ELEICAO=20181007
union all select 'FV 2022', count(*), sum(cast(QT_VOTOS as bigint)) from dbo.Fato_Votacao where SK_ELEICAO=20221002
union all select 'Fato_Perfil', count(*), sum(cast(QT_ELEITORES_PERFIL as bigint)) from dbo.Fato_Perfil_Eleitorado
union all select 'Fato_Comp aptos', count(*), sum(cast(QT_APTOS as bigint)) from dbo.Fato_Comparecimento_Abstencao
union all select 'Dim_Eleicao', count(*), null from dbo.Dim_Eleicao
union all select 'Dim_Local', count(*), null from dbo.Dim_Local_Votacao
union all select 'Dim_Cand', count(*), sum(cast(FL_CONCORRENTE_REGIONAL as int)) from dbo.Dim_Candidato_Partido
union all select 'Dim_Perfil', count(*), null from dbo.Dim_Perfil_Demografico
union all select 'Stg Vot18', count(*), sum(cast(QT_VOTOS as bigint)) from dbo.Staging_VotacaoSecao_2018_SP
union all select 'Stg Vot22', count(*), sum(cast(QT_VOTOS as bigint)) from dbo.Staging_VotacaoSecao_2022_SP;
select 'orfas FV local' k, count(*) from dbo.Fato_Votacao f left join dbo.Dim_Local_Votacao d on d.SK_LOCAL_VOTACAO=f.SK_LOCAL_VOTACAO where d.SK_LOCAL_VOTACAO is null
union all select 'orfas FV cand', count(*) from dbo.Fato_Votacao f left join dbo.Dim_Candidato_Partido d on d.SK_CANDIDATO_PARTIDO=f.SK_CANDIDATO_PARTIDO where d.SK_CANDIDATO_PARTIDO is null
union all select 'orfas FV eleicao', count(*) from dbo.Fato_Votacao f left join dbo.Dim_Eleicao d on d.SK_ELEICAO=f.SK_ELEICAO where d.SK_ELEICAO is null
union all select 'FV nao identificado', count(*) from dbo.Fato_Votacao f join dbo.Dim_Candidato_Partido d on d.SK_CANDIDATO_PARTIDO=f.SK_CANDIDATO_PARTIDO and d.NK_CANDIDATO='-1'
union all select 'FP perfil -1', count(*) from dbo.Fato_Perfil_Eleitorado f join dbo.Dim_Perfil_Demografico d on d.SK_PERFIL_DEMOGRAFICO=f.SK_PERFIL_DEMOGRAFICO and d.NK_PERFIL_DEMOGRAFICO='-1_-1_-1'
union all select 'FV 2018 sem nominal ok', count(*) from dbo.Fato_Votacao where SK_ELEICAO=20181007 and QT_VOTOS<0;
select 'NULO em dims' k, (select count(*) from dbo.Dim_Candidato_Partido where SG_FEDERACAO like '%#NULO%' or NM_URNA_CANDIDATO like '%#NULO%' or SG_PARTIDO like '%#NULO%' or NR_CANDIDATO like '%#%')
 + (select count(*) from dbo.Dim_Local_Votacao where NM_LOCAL_VOTACAO like '%#NULO%' or NM_MUNICIPIO like '%#NULO%')
 + (select count(*) from dbo.Dim_Perfil_Demografico where DS_FAIXA_ETARIA like '%#N%' or DS_ESCOLARIDADE like '%#N%' or DS_GENERO like '%#N%')
 + (select count(*) from dbo.Dim_Eleicao where DS_ELEICAO like '%#N%') as n;
select 'bytes acentos' k, convert(varbinary(40), DS_ELEICAO) b from dbo.Dim_Eleicao where SK_ELEICAO=20181007
union all select 'cand sem federacao', convert(varbinary(40), SG_FEDERACAO) from dbo.Dim_Candidato_Partido where NK_CANDIDATO='-1'
union all select 'perfil nao inf', convert(varbinary(40), DS_GENERO) from dbo.Dim_Perfil_Demografico where SK_PERFIL_DEMOGRAFICO=1;
select 'texto com ? ou lixo utf8' k,
  (select count(*) from dbo.Dim_Local_Votacao where NM_LOCAL_VOTACAO like '%?%' or NM_LOCAL_VOTACAO like '%' + char(195) + char(131) + '%' or NM_MUNICIPIO like '%' + char(195) + '%' + char(131) + '%') as n_local,
  (select count(*) from dbo.Dim_Candidato_Partido where NM_URNA_CANDIDATO like '%?%' or NM_URNA_CANDIDATO like '%' + char(195) + char(131) + '%') as n_cand;
select top 5 * from dbo.Dim_Eleicao;
select top 5 * from dbo.Dim_Local_Votacao where SK_LOCAL_VOTACAO>1 order by SK_LOCAL_VOTACAO;
select top 5 * from dbo.Dim_Candidato_Partido where NK_CANDIDATO like '2500006%' order by SK_CANDIDATO_PARTIDO;
select top 5 * from dbo.Dim_Perfil_Demografico order by SK_PERFIL_DEMOGRAFICO;
select top 5 * from dbo.Fato_Votacao where SK_ELEICAO=20181007 order by SK_VOTACAO;
select top 5 * from dbo.Fato_Perfil_Eleitorado order by SK_PERFIL_ELEITORADO;
select top 5 * from dbo.Fato_Comparecimento_Abstencao order by SK_COMPARECIMENTO_ABSTENCAO;
select 'FL_REGIONAL 2022 (esperado 1081)' k, count(*) n from dbo.Dim_Candidato_Partido d where FL_CONCORRENTE_REGIONAL=1 and exists (select 1 from dbo.Staging_Consulta_Cand_2022_SP c where cast(c.SQ_CANDIDATO as varchar(20))=d.NK_CANDIDATO and c.DS_CARGO='DEPUTADO ESTADUAL');
