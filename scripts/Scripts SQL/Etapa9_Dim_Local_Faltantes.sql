/* ETAPA 9 - Dim_Local_Votacao: inclusao incremental dos locais de 2022 ausentes (perfil/detalhe). ASCII puro.
   Flags GRANDE_ABC/RMSP herdadas do municipio ja existente na dimensao (sem literais acentuados). */
set nocount on;
set xact_abort on;
begin transaction;

with Novos as (
    select CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO from dbo.Staging_Perfil_Eleitor_Secao_2022
    union
    select CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO from dbo.Staging_DetalheVotacaoSecao_2022_SP
),
Agrupados as (
    select concat_ws('_', CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO) as NK_LOCAL_VOTACAO,
           CD_MUNICIPIO, max(NM_MUNICIPIO) as NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, max(NM_LOCAL_VOTACAO) as NM_LOCAL_VOTACAO
    from Novos
    group by CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO
)
insert into dbo.Dim_Local_Votacao (NK_LOCAL_VOTACAO, CD_MUNICIPIO, NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, NM_LOCAL_VOTACAO, SG_UF, FL_GRANDE_ABC, FL_RMSP)
select a.NK_LOCAL_VOTACAO, a.CD_MUNICIPIO, a.NM_MUNICIPIO, a.NR_ZONA, a.NR_LOCAL_VOTACAO, coalesce(a.NM_LOCAL_VOTACAO, (select NM_LOCAL_VOTACAO from dbo.Dim_Local_Votacao where NK_LOCAL_VOTACAO = '-1')),
       'SP',
       coalesce((select max(cast(FL_GRANDE_ABC as int)) from dbo.Dim_Local_Votacao m where m.CD_MUNICIPIO = a.CD_MUNICIPIO), 0),
       coalesce((select max(cast(FL_RMSP as int)) from dbo.Dim_Local_Votacao m where m.CD_MUNICIPIO = a.CD_MUNICIPIO), 0)
from Agrupados a
where not exists (select 1 from dbo.Dim_Local_Votacao d where d.NK_LOCAL_VOTACAO = a.NK_LOCAL_VOTACAO);

select @@rowcount as LOCAIS_INSERIDOS;
commit transaction;
select count(*) as TOTAL_DIM_LOCAL from dbo.Dim_Local_Votacao;
