with Historico_Votos_Codigo7 as (
select 
	ANO_ELEICAO, 
	CD_MUNICIPIO, 
	NR_ZONA, 
	NR_SECAO, 
	NR_VOTAVEL, 
	QT_VOTOS 
from dbo.Staging_VotacaoSecao_2018_SP
union all 
select 
	ANO_ELEICAO, 
	CD_MUNICIPIO, 
	NR_ZONA,  
	NR_SECAO, 
	NR_VOTAVEL, 
	QT_VOTOS 
from dbo.Staging_VotacaoSecao_2022_SP
where CD_CARGO = '7' )

select 
	hv.ANO_ELEICAO,
	hv.CD_MUNICIPIO, 
	hv.NR_ZONA, 
	hv.NR_SECAO, 
	hv.NR_VOTAVEL, 
	hv.QT_VOTOS, 
	cc.NM_URNA_CANDIDATO,
	cc.SG_PARTIDO,

	-- Tratando o #NULO e aplicando a regra de 'SEM FEDERAÇÃO' do PM
	COALESCE(NULLIF(cc.SG_FEDERACAO, '#NULO'), 'SEM FEDERAÇÃO') AS SG_FEDERACAO,
	case 
		when hv.NR_VOTAVEL = '95' then 'VOTO BRANCO' 
		when hv.NR_VOTAVEL = '96' then 'VOTO NULO'
		when len(hv.NR_VOTAVEL) = '2' and hv.NR_VOTAVEL not in('95','96') then 'VOTO LEGENDA' 
		else 'VOTO NOMINAL' 
	end as TIPO_VOTO,
	-- A Window Function calculando o total da Zona Eleitoral
	sum(hv.QT_VOTOS) over (partition by hv.ANO_ELEICAO, hv.CD_MUNICIPIO, hv.NR_ZONA) as TOTAL_VOTOS_ZONA
	
INTO dbo.Fato_Votacao_Historica
from historico_votos_codigo7 hv
left join dbo.Staging_Consulta_Cand_2022_SP cc 
	on hv.NR_VOTAVEL = cc.NR_CANDIDATO