/* =====================================================================
   DEPLOY STAR SCHEMA COMPLETO - INNOVATION LAB APPLIED BI
   Execucao sequencial das 4 Dimensoes e 3 Fatos em ordem de integridade
   ===================================================================== */
set nocount on;

print 'Limpando tabelas existentes em ordem de dependencia...';
if object_id('dbo.Fato_Votacao', 'u') is not null drop table dbo.Fato_Votacao;
if object_id('dbo.Fato_Perfil_Eleitorado', 'u') is not null drop table dbo.Fato_Perfil_Eleitorado;
if object_id('dbo.Fato_Comparecimento_Abstencao', 'u') is not null drop table dbo.Fato_Comparecimento_Abstencao;
if object_id('dbo.Dim_Candidato_Partido', 'u') is not null drop table dbo.Dim_Candidato_Partido;
if object_id('dbo.Dim_Local_Votacao', 'u') is not null drop table dbo.Dim_Local_Votacao;
if object_id('dbo.Dim_Perfil_Demografico', 'u') is not null drop table dbo.Dim_Perfil_Demografico;
if object_id('dbo.Dim_Eleicao', 'u') is not null drop table dbo.Dim_Eleicao;
go

print '1/7 Criando Dim_Eleicao...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\01_Dim_Eleicao.sql"
go

print '2/7 Criando Dim_Local_Votacao...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\02_dim_local_votacao.sql"
go

print '3/7 Criando Dim_Candidato_Partido...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\03_Dim_Candidato_Partido.sql"
go

print '4/7 Criando Fato_Votacao (2022 + 2018)...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\04_fato_votacao.sql"
go

print '5/7 Criando Dim_Perfil_Demografico...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\05_dim_perfil_demografico.sql"
go

print '6/7 Criando Fato_Perfil_Eleitorado (2022)...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\06_Fato_Perfil_Eleitorado.sql"
go

print '7/7 Criando Fato_Comparecimento_Abstencao (2022)...';
:r "c:\Innovation-Lab---Applied-BI\entregas_dimensionais\07_Fato_Comparecimento_Abstencao.sql"
go

print 'Deploy do Star Schema concluido com sucesso!';
