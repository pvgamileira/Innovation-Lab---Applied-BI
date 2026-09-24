/* =====================================================================
   INNOVATION LAB: APPLIED BI — AULA 5
   Extração de dados transacionais com T-SQL para Staging
   (Tabelas temporárias, CTEs, SELECT INTO, tratamento inicial de tipos)

   Como usar: execute este script bloco a bloco,
   na ordem em que aparece. Cada bloco tem um título e um comentário
   explicando o que ele demonstra.
   ===================================================================== */


/* ---------------------------------------------------------------------
   BLOCO 0 — Preparar a "fonte transacional" (só para simular o cenário)
   Em uma situação real, esta tabela já existiria no sistema de origem
   (ex.: uma exportação bruta dos arquivos abertos do TSE). Aqui vamos
   criá-la à mão para termos algo concreto para extrair.
   Observação proposital: QT_VOTOS está como VARCHAR, e alguns dados
   estão "sujos" (nulos disfarçados, espaços, duplicidade) — isso é
   comum em fontes reais e vamos tratar isso ao longo da aula.
--------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Fonte_Votacao_Bruta', 'U') IS NOT NULL
    DROP TABLE dbo.Fonte_Votacao_Bruta;

CREATE TABLE dbo.Fonte_Votacao_Bruta (
    DT_ELEICAO      VARCHAR(10),
    SG_UF           VARCHAR(2),
    NM_MUNICIPIO    VARCHAR(100),
    NR_ZONA         VARCHAR(10),
    NR_SECAO        VARCHAR(10),
    NR_CANDIDATO    VARCHAR(10),
    NM_CANDIDATO    VARCHAR(100),
    SG_PARTIDO      VARCHAR(10),
    DS_CARGO        VARCHAR(50),
    QT_VOTOS        VARCHAR(10)
);

INSERT INTO dbo.Fonte_Votacao_Bruta VALUES
('02/10/2022', 'SP', 'CAMPINAS',      '015', '0042', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '187'),
('02/10/2022', 'SP', 'CAMPINAS',      '015', '0042', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '203'),
('02/10/2022', 'SP', 'CAMPINAS',      '015', '0043', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '95'),
('02/10/2022', 'SP', 'campinas',      '016', '0011', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '310'),
('02/10/2022', 'SP', 'CAMPINAS',      '016', '0011', '45', 'CANDIDATO C', 'MDB', 'DEPUTADO ESTADUAL', 'NULL'),
('02/10/2022', 'SP', 'CAMPINAS',      '016', '0011', '45', 'CANDIDATO C', 'MDB', 'DEPUTADO ESTADUAL', 'NULL'),  -- linha duplicada de propósito
('02/10/2022', 'SP', 'SOROCABA',      '008', '0101', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '77'),
('02/10/2022', 'SP', 'SOROCABA',      '008', '0101', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '  142'),
('02/10/2022', 'SP', 'SOROCABA',      '008', '0102', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '58'),
('02/10/2022', 'SP', 'SOROCABA',      NULL,  '0102', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '61'),
('02/10/2022', 'SP', 'ITU',           '021', '0005', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '40'),
('02/10/2022', 'SP', 'ITU',           '021', '0005', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '52'),
('02/10/2022', 'SP', 'ITU',           '021', '0006', '45', 'CANDIDATO C', 'MDB', 'DEPUTADO ESTADUAL', 'abstenção'),  -- valor inválido de propósito
('02/10/2022', 'SP', 'INDAIATUBA',    '030', '0201', '13', 'CANDIDATO A', 'PT',  'DEPUTADO ESTADUAL', '29'),
('02/10/2022', 'SP', 'INDAIATUBA',    '030', '0201', '22', 'CANDIDATO B', 'PL',  'DEPUTADO ESTADUAL', '88');

-- Dê uma olhada na "bagunça" antes de começar:
SELECT * FROM dbo.Fonte_Votacao_Bruta;


/* ---------------------------------------------------------------------
   BLOCO 1 — Revisão rápida de DML (SELECT com filtro e ordenação)
   Antes de extrair para staging, vale relembrar o básico que vamos
   usar o tempo todo hoje.
--------------------------------------------------------------------- */
SELECT NM_MUNICIPIO, NR_ZONA, NM_CANDIDATO, QT_VOTOS
FROM dbo.Fonte_Votacao_Bruta
WHERE SG_UF = 'SP'
ORDER BY NM_MUNICIPIO, NR_ZONA;


/* ---------------------------------------------------------------------
   BLOCO 2 — SELECT INTO: criando uma staging table "de uma vez"
   SELECT INTO cria a tabela automaticamente, com os tipos herdados
   da consulta. É rápido, mas não permite definir PK/constraints na
   hora (só estrutura básica).
--------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Staging_Votacao_V1', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Votacao_V1;

SELECT *
INTO dbo.Staging_Votacao_V1
FROM dbo.Fonte_Votacao_Bruta;

SELECT * FROM dbo.Staging_Votacao_V1;
-- Quais problemas dos dados brutos continuam
-- aqui, sem tratamento nenhum? (duplicidade, QT_VOTOS como texto,
-- município com caixa inconsistente, zona nula)


/* ---------------------------------------------------------------------
   BLOCO 3 — Tabela temporária (#temp) para isolar um passo intermediário
   Tabelas temporárias (#nome) existem só durante a sessão atual e são
   úteis para dividir uma extração complexa em etapas mais legíveis.
--------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Votacao_Campinas') IS NOT NULL
    DROP TABLE #Votacao_Campinas;

SELECT *
INTO #Votacao_Campinas
FROM dbo.Fonte_Votacao_Bruta
WHERE NM_MUNICIPIO = 'CAMPINAS';

SELECT * FROM #Votacao_Campinas;
-- Reparem que a fonte bruta tem 'CAMPINAS' e
-- 'campinas' escritos de formas diferentes (Bloco 0). Dependendo da
-- collation do banco, esse WHERE pode ou não distinguir maiúsculas de
-- minúsculas — o que é exatamente o tipo de comportamento "escondido"
-- que não dá pra confiar. Por isso, no Bloco 6, padronizamos o texto
-- com UPPER(TRIM(...)) em vez de depender da collation do servidor.


/* ---------------------------------------------------------------------
   BLOCO 4 — CTE para remover duplicidade (ROW_NUMBER)
   Common Table Expressions (WITH ... AS) deixam consultas em várias
   etapas muito mais legíveis do que subqueries aninhadas.
--------------------------------------------------------------------- */
WITH Votacao_Numerada AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NM_MUNICIPIO, NR_ZONA, NR_SECAO, NR_CANDIDATO
            ORDER BY (SELECT NULL)
        ) AS RN
    FROM dbo.Fonte_Votacao_Bruta
)
SELECT *
FROM Votacao_Numerada
WHERE RN = 1;   -- mantém só a primeira ocorrência de cada linha "igual"
-- Comparem a contagem de linhas aqui com a contagem da fonte bruta:
-- SELECT COUNT(*) FROM dbo.Fonte_Votacao_Bruta;


/* ---------------------------------------------------------------------
   BLOCO 5 — Tratamento inicial de tipos (TRY_CAST / TRY_CONVERT / TRIM)
   QT_VOTOS está como VARCHAR e tem lixo dentro ('NULL' como texto,
   espaços, 'abstenção'). TRY_CAST devolve NULL quando a conversão
   falha, em vez de quebrar a consulta inteira.
--------------------------------------------------------------------- */
SELECT
    NM_MUNICIPIO,
    NR_ZONA,
    NM_CANDIDATO,
    QT_VOTOS AS QT_VOTOS_ORIGINAL,
    TRY_CAST(TRIM(QT_VOTOS) AS INT) AS QT_VOTOS_TRATADO
FROM dbo.Fonte_Votacao_Bruta;
-- Reparem que 'NULL' (texto), '  142' (com espaço) e 'abstenção' viram
-- NULL de tratamentos diferentes: os dois primeiros porque já eram
-- lixo ou tinham espaço, o segundo porque TRIM resolveu, e 'abstenção'
-- porque realmente não é um número.


/* ---------------------------------------------------------------------
   BLOCO 6 — Juntando tudo: a Staging definitiva
   Agora combinamos: CTE de deduplicação + tratamento de tipos +
   padronização de texto (UPPER) + SELECT INTO para gravar o resultado
   final como a tabela de staging do projeto.
--------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Staging_Votacao', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Votacao;

WITH Votacao_Numerada AS (
    SELECT
        DT_ELEICAO,
        SG_UF,
        UPPER(TRIM(NM_MUNICIPIO))              AS NM_MUNICIPIO,
        NR_ZONA,
        NR_SECAO,
        NR_CANDIDATO,
        NM_CANDIDATO,
        SG_PARTIDO,
        DS_CARGO,
        TRY_CAST(TRIM(QT_VOTOS) AS INT)        AS QT_VOTOS,
        ROW_NUMBER() OVER (
            PARTITION BY UPPER(TRIM(NM_MUNICIPIO)), NR_ZONA, NR_SECAO, NR_CANDIDATO
            ORDER BY (SELECT NULL)
        ) AS RN
    FROM dbo.Fonte_Votacao_Bruta
)
SELECT
    DT_ELEICAO,
    SG_UF,
    NM_MUNICIPIO,
    NR_ZONA,
    NR_SECAO,
    NR_CANDIDATO,
    NM_CANDIDATO,
    SG_PARTIDO,
    DS_CARGO,
    ISNULL(QT_VOTOS, 0) AS QT_VOTOS   -- decisão de negócio: voto ilegível vira 0, não some da base
INTO dbo.Staging_Votacao
FROM Votacao_Numerada
WHERE RN = 1;

SELECT * FROM dbo.Staging_Votacao ORDER BY NM_MUNICIPIO, NR_ZONA;


/* ---------------------------------------------------------------------
   BLOCO 7 — Conferência pós-carga 
   Antes de seguir em frente, sempre vale conferir o básico: quantas
   linhas entraram, quantos nulos sobraram, se a duplicidade sumiu.
--------------------------------------------------------------------- */
SELECT COUNT(*) AS Total_Linhas_Fonte        FROM dbo.Fonte_Votacao_Bruta;
SELECT COUNT(*) AS Total_Linhas_Staging      FROM dbo.Staging_Votacao;
SELECT COUNT(*) AS Linhas_Com_Zona_Nula      FROM dbo.Staging_Votacao WHERE NR_ZONA IS NULL;
SELECT COUNT(*) AS Linhas_Com_Voto_Zerado    FROM dbo.Staging_Votacao WHERE QT_VOTOS = 0;


/* =====================================================================
   EXERCÍCIO — cada grupo replica para os dados do próprio projeto
   =====================================================================
   1. Criem uma tabela bruta equivalente à Fonte_Votacao_Bruta, mas com a estrutura
      dos dados do TSE do escopo de vocês.
   2. Repitam o Bloco 2 (SELECT INTO) para criar uma primeira versão
      da staging.
   3. Repitam o Bloco 4 (CTE + ROW_NUMBER) para checar e remover
      duplicidade nos dados de vocês.
   4. Repitam o Bloco 5 (TRY_CAST / TRIM) nas colunas numéricas do
      seu escopo (ex.: quantidade de votos, número de zona).
   5. Montem a versão final da Staging_Votacao do projeto de vocês,
      juntando as etapas acima em um único script, como no Bloco 6.
   6. Rodem as conferências do Bloco 7 e tragam os números para para validação
   ===================================================================== */
