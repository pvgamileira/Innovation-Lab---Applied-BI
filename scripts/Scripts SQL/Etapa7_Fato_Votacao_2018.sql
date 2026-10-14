/* ETAPA 7 - FATO_VOTACAO 2018 (incremental; nao recria a fato). ASCII puro.
   Uso: sqlcmd -v LIMITE=1000 (teste: roda em transacao e faz rollback) ou LIMITE=0 (carga completa) */
set nocount on;
set xact_abort on;

declare @limite int = $(LIMITE);
declare @sk_nao_id int = (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '-1');
declare @sk_branco int = (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '95');
declare @sk_nulo   int = (select SK_CANDIDATO_PARTIDO from dbo.Dim_Candidato_Partido where NK_CANDIDATO = '96');

if exists (select 1 from dbo.Fato_Votacao where SK_ELEICAO = 20181007)
begin
    raiserror('Fato_Votacao ja possui 2018 - abortando para evitar duplicidade.', 16, 1);
    return;
end

begin transaction;

insert into dbo.Fato_Votacao with (tablock) (SK_ELEICAO, SK_LOCAL_VOTACAO, SK_CANDIDATO_PARTIDO, NR_SECAO, QT_VOTOS)
select top (case when @limite > 0 then @limite else 2147483647 end)
    20181007,
    dlv.SK_LOCAL_VOTACAO,
    case
        when v.NR_VOTAVEL = '95' then @sk_branco
        when v.NR_VOTAVEL = '96' then @sk_nulo
        when len(v.NR_VOTAVEL) = 2 then coalesce(dleg.SK_CANDIDATO_PARTIDO, @sk_nao_id)
        else coalesce(dcp.SK_CANDIDATO_PARTIDO, @sk_nao_id)
    end,
    v.NR_SECAO,
    v.QT_VOTOS
from dbo.Staging_VotacaoSecao_2018_SP v
inner join dbo.Dim_Local_Votacao dlv on concat_ws('_', v.CD_MUNICIPIO, v.NR_ZONA, v.NR_LOCAL_VOTACAO) = dlv.NK_LOCAL_VOTACAO
left join dbo.Dim_Candidato_Partido dcp on v.SQ_CANDIDATO = dcp.NK_CANDIDATO and v.SQ_CANDIDATO not in ('-1', '-3')
left join dbo.Dim_Candidato_Partido dleg on len(v.NR_VOTAVEL) = 2 and v.NR_VOTAVEL = dleg.NK_CANDIDATO;

select count(*) as LINHAS_2018, sum(cast(QT_VOTOS as bigint)) as VOTOS_2018,
       sum(case when SK_CANDIDATO_PARTIDO = @sk_nao_id then 1 else 0 end) as NAO_IDENTIFICADOS
from dbo.Fato_Votacao where SK_ELEICAO = 20181007;

if @limite > 0 rollback transaction; else commit transaction;
