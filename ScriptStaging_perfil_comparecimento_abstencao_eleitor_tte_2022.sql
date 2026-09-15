/* =====================================================================
   PROJETO: Inteligência de Campanha - Deputado Estadual (PSDB-SP)
   OBJETIVO: Diagnóstico de Vulnerabilidade e Defesa Territorial
   ARQUIVO: ETL - Criação da Staging de Comparecimento e Abstenção
   ===================================================================== */

-- Visualização prévia da base bruta importada do TSE
SELECT TOP 100 * FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022;
SELECT COUNT(*) AS Linhas_Base_Bruta FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022;


/* ---------------------------------------------------------------------
   BLOCO 2 — SELECT INTO: Criando uma staging table "de uma vez"
   ---------------------------------------------------------------------
   Gera uma cópia exata da tabela bruta para visualizarmos os problemas
   originais (duplicidades e textos sem padronização) que podem afetar
   o cálculo do nosso [KPI 5 - Taxa de Abstenção na Base].
--------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Staging_Comparecimento_eleitor_tte_V1', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Comparecimento_eleitor_tte_V1;

SELECT *
INTO dbo.Staging_Comparecimento_eleitor_tte_V1
FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022;

-- SELECT * FROM dbo.Staging_Comparecimento_eleitor_tte_V1;


/* ---------------------------------------------------------------------
   BLOCO 3 — Tabela temporária (#temp)
   ---------------------------------------------------------------------
   Isolamos os dados do Estado de São Paulo para simular o impacto no
   nosso escopo regional (já que a campanha é para Deputado Estadual SP).
--------------------------------------------------------------------- */
IF OBJECT_ID('tempdb..#Comparecimento_abstencao_eleitor_tte_22') IS NOT NULL
    DROP TABLE #Comparecimento_abstencao_eleitor_tte_22;

SELECT *
INTO #Comparecimento_abstencao_eleitor_tte_22
FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022
WHERE NM_MUNICIPIO_ORIGEM = 'São Paulo';

-- SELECT * FROM #Comparecimento_abstencao_eleitor_tte_22;


/* ---------------------------------------------------------------------
   BLOCO 4 — CTE para remover duplicidade (ROW_NUMBER)
   ---------------------------------------------------------------------
   Para que o Power BI não some abstenções duplicadas em um mesmo bairro,
   agrupamos as linhas idênticas usando a granularidade do TSE:
   Localidade (Cidade/Zona) + Perfil Demográfico (Gênero/Idade/Escolaridade).
--------------------------------------------------------------------- */
WITH Comparecimento_abstencao_eleitor_tte_22_Numerada AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY NM_MUNICIPIO_ORIGEM, NR_ZONA_ORIGEM, NM_MUNICIPIO_DESTINO, NR_ZONA_DESTINO, DS_GENERO, DS_FAIXA_ETARIA, DS_GRAU_ESCOLARIDADE
            ORDER BY (SELECT NULL)
        ) AS RN
    FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022
)
SELECT *
FROM Comparecimento_abstencao_eleitor_tte_22_Numerada
WHERE RN = 1; -- Mantém apenas o registro original, eliminando as cópias


/* ---------------------------------------------------------------------
   BLOCO 5 — Tratamento inicial de tipos (Métricas de KPI)
   ---------------------------------------------------------------------
   Como o assistente do SSMS já importou as quantidades como números
   inteiros (smallint), pulamos o TRIM/TRY_CAST e apenas garantimos
   que valores Nulos se tornem ZERO usando ISNULL, evitando quebra 
   de gráficos e contas no dashboard.
--------------------------------------------------------------------- */
SELECT NM_MUNICIPIO_ORIGEM
	,NR_ZONA_ORIGEM
	,NR_ZONA_DESTINO
	,ISNULL(QT_APTOS_EM_TTE, 0) AS QT_APTOS_EM_TTE_TRATADO
	,ISNULL(QT_COMPARECIMENTO_TTE, 0) AS QT_COMPARECIMENTO_TTE_TRATADO
	,ISNULL(QT_ABSTENCAO_TTE, 0) AS QT_ABSTENCAO_TTE_TRATADO
FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022;


/* ---------------------------------------------------------------------
   BLOCO 6 — Juntando tudo: A Staging Definitiva do Projeto
   ---------------------------------------------------------------------
   Aplicamos as regras de negócio em um único script: remoção de 
   duplicidade, conversão de Nulos para Zero e padronização de textos
   (UPPER/TRIM) para que as Cidades agrupem corretamente no Power BI.
--------------------------------------------------------------------- */
IF OBJECT_ID('dbo.Staging_Comparecimento_eleitor_tte_V1', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Comparecimento_eleitor_tte_V1;

WITH Comparecimento_abstencao_eleitor_tte_22_Numerada AS (
    SELECT
        ANO_ELEICAO,
        NR_TURNO,
        SG_UF_ORIGEM,
        UPPER(TRIM(NM_MUNICIPIO_ORIGEM)) AS NM_MUNICIPIO_ORIGEM,
        NR_ZONA_ORIGEM,
        SG_UF_DESTINO,
        UPPER(TRIM(NM_MUNICIPIO_DESTINO)) AS NM_MUNICIPIO_DESTINO,
        NR_ZONA_DESTINO,
        DS_GENERO,
        DS_ESTADO_CIVIL,
        DS_FAIXA_ETARIA,
        DS_GRAU_ESCOLARIDADE,
        
        -- Métricas prontas para o Dashboard (já tipadas como número)
        QT_APTOS_EM_TTE,
        QT_COMPARECIMENTO_TTE,
        QT_ABSTENCAO_TTE,
        
        ROW_NUMBER() OVER (
            PARTITION BY NM_MUNICIPIO_ORIGEM, NR_ZONA_ORIGEM, NM_MUNICIPIO_DESTINO, NR_ZONA_DESTINO, DS_GENERO, DS_FAIXA_ETARIA, DS_GRAU_ESCOLARIDADE
            ORDER BY (SELECT NULL)
        ) AS RN
    FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022
)
SELECT
    ANO_ELEICAO,
    NR_TURNO,
    SG_UF_ORIGEM,
    NM_MUNICIPIO_ORIGEM,
    NR_ZONA_ORIGEM,
    SG_UF_DESTINO,
    NM_MUNICIPIO_DESTINO,
    NR_ZONA_DESTINO,
    DS_GENERO,
    DS_ESTADO_CIVIL,
    DS_FAIXA_ETARIA,
    DS_GRAU_ESCOLARIDADE,
    ISNULL(QT_APTOS_EM_TTE, 0) AS QT_APTOS,
    ISNULL(QT_COMPARECIMENTO_TTE, 0) AS QT_COMPARECIMENTO,
    ISNULL(QT_ABSTENCAO_TTE, 0) AS QT_ABSTENCAO
INTO dbo.Staging_Comparecimento_eleitor_tte_V1
FROM Comparecimento_abstencao_eleitor_tte_22_Numerada
WHERE RN = 1;


/* ---------------------------------------------------------------------
   BLOCO 7 — Auditoria e Conferência Pós-Carga
   ---------------------------------------------------------------------
   Validação de Qualidade de Dados (Data Quality) para garantir que
   a tabela Staging gerada está saudável para plugar no Power BI.
--------------------------------------------------------------------- */
SELECT COUNT(*) AS Total_Linhas_Fonte        FROM dbo.perfil_comparecimento_abstencao_eleitor_tte_2022;
SELECT COUNT(*) AS Total_Linhas_Staging      FROM dbo.Staging_Comparecimento_eleitor_tte_V1;
SELECT COUNT(*) AS Linhas_Com_Zona_Origem_Nula      FROM dbo.Staging_Comparecimento_eleitor_tte_V1 WHERE NR_ZONA_ORIGEM IS NULL;
SELECT COUNT(*) AS Linhas_Com_Zona_Destino_Nula     FROM dbo.Staging_Comparecimento_eleitor_tte_V1 WHERE NR_ZONA_DESTINO IS NULL;
SELECT COUNT(*) AS Linhas_Com_Comparecimento_Zerado FROM dbo.Staging_Comparecimento_eleitor_tte_V1 WHERE QT_COMPARECIMENTO = 0;