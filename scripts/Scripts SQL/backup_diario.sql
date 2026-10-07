-- Script para Backup Full do Banco de Dados
-- Pode ser agendado no SQL Server Agent ou rodado via sqlcmd
BACKUP DATABASE InnovationLab_AppliedBI 
TO DISK = 'C:\Innovation-Lab---Applied-BI\InnovationLab_AppliedBI_Diario.bak' 
WITH FORMAT, INIT, 
NAME = 'Backup Diario - InnovationLab_AppliedBI';
