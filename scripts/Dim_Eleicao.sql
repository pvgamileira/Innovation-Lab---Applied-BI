-- 1. Criação da Tabela Física
IF OBJECT_ID('dbo.Dim_Eleicao', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Eleicao;

CREATE TABLE dbo.Dim_Eleicao (
    SK_Eleicao INT NOT NULL,                  -- Chave Substituta no formato AAAAMMDD (ex: 20221002)
    DT_Eleicao DATE NOT NULL,                 -- Data exata da eleição
    NR_Ano SMALLINT NOT NULL,                 -- Ano do pleito (2018, 2022)
    NR_Turno TINYINT NOT NULL,                -- Turno (1 ou 2)
    DS_Eleicao VARCHAR(100) NOT NULL,         -- Descrição oficial do pleito
    CONSTRAINT PK_Dim_Eleicao PRIMARY KEY (SK_Eleicao),
    CONSTRAINT UQ_Dim_Eleicao_DataTurno UNIQUE (DT_Eleicao, NR_Turno)
);

-- 2. Carga dos Dados (Estática)
INSERT INTO dbo.Dim_Eleicao (SK_Eleicao, DT_Eleicao, NR_Ano, NR_Turno, DS_Eleicao)
VALUES 
    (20181007, '2018-10-07', 2018, 1, 'ELEIÇÕES GERAIS 2018 - 1º TURNO'),
    (20181028, '2018-10-28', 2018, 2, 'ELEIÇÕES GERAIS 2018 - 2º TURNO'),
    (20221002, '2022-10-02', 2022, 1, 'ELEIÇÕES GERAIS 2022 - 1º TURNO'),
    (20221030, '2022-10-30', 2022, 2, 'ELEIÇÕES GERAIS 2022 - 2º TURNO');

-- 3. Verificação
SELECT * FROM dbo.Dim_Eleicao;