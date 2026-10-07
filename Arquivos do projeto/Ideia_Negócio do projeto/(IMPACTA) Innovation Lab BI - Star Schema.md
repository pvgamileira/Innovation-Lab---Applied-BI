# 1. Definição das Tabelas Dimensão (O Contexto)
As dimensões consolidam os dados cadastrais, eliminando duplicidades e padronizando os nomes.
### Dim_Candidato_Partido
- **Origem principal:** `consulta_cand_2022_SP`.
- **O que vira dimensão:** Dados dos concorrentes, siglas e federações.
- **Chave Primária (PK):** `SQ_CANDIDATO` (ou um código composto para candidatos/legenda/brancos/nulos).
- **Atributos principais:** `NR_CANDIDATO`, `NM_URNA_CANDIDATO`, `SG_PARTIDO`, `SG_FEDERACAO`, `DS_COMPOSICAO_FEDERACAO`, `FL_CONCORRENTE_REGIONAL` (indicador se pertence ao Grande ABC / RMSP).
### Dim_Local_Votacao (Geografia)
- **Origem principal:** Agrupamento das chaves de local extraídas de `votacao_secao_2022_SP` / `perfil_eleitor_secao_2022_SP`.
- **O que vira dimensão:** A hierarquia geográfica dos colégios eleitorais.
- **Chave Primária (PK):** `SK_LOCAL_VOTACAO` (ou Chave Composta: `CD_MUNICIPIO` + `NR_ZONA` + `NR_LOCAL_VOTACAO`).
- **Atributos principais:** `NM_MUNICIPIO`, `CD_MUNICIPIO`, `NR_ZONA`, `NR_LOCAL_VOTACAO`, `NM_LOCAL_VOTACAO`, `FL_GRANDE_ABC`, `FL_RMSP`.
### Dim_Perfil_Demografico
- **Origem principal:** `perfil_eleitor_secao_2022_SP` / `perfil_comparecimento_abstencao_2022_SP`.
- **O que vira dimensão:** Os atributos descritivos do eleitorado.
- **Chave Primária (PK):** `SK_PERFIL` (gerada por combinação única).
- **Atributos principais:** `CD_FAIXA_ETARIA`, `DS_FAIXA_ETARIA`, `CD_ESCOLARIDADE`, `DS_ESCOLARIDADE`, `CD_GENERO`, `DS_GENERO`.
### Dim_Eleicao (Tempo)
- **Origem principal:** Tabela gerada no banco.
- **Chave Primária (PK):** `ANO_ELEICAO` (2018, 2022).
- **Atributos principais:** `DS_ELEICAO`, `NR_TURNO`.


# 2. Definição das Tabelas Fato (As Métricas)
As tabelas fato contêm apenas números acumuláveis e chaves de ligação.
### Fato_Votacao
- **Origem principal:** União (`UNION ALL`) de `votacao_secao_2018_SP` e `votacao_secao_2022_SP`.
- **Granularidade:** Um registro por Seção / Candidato Votado por Eleição.
- **Chaves de Ligação (FKs):** `ANO_ELEICAO`, `SK_LOCAL_VOTACAO`, `SQ_CANDIDATO`.
- **Métrica Numérica:** `QT_VOTOS`.
- **Utilidade nos KPIs:** Alimenta os KPIs 1, 2, 3, 4, 6, 9 e 10.
### Fato_Perfil_Eleitorado
- **Origem principal:** `perfil_eleitor_secao_2022_SP`.
- **Granularidade:** Um registro por Seção / Perfil Demográfico.
- **Chaves de Ligação (FKs):** `ANO_ELEICAO`, `SK_LOCAL_VOTACAO`, `SK_PERFIL`.
- **Métrica Numérica:** `QT_ELEITORES_PERFIL`.
- **Utilidade nos KPIs:** Alimenta os KPIs 5 e 8.
### Fato_Comparecimento_Abstencao
- **Origem principal:** `detalhe_votacao_secao_2022_SP` (ou `perfil_comparecimento_abstencao_2022_SP`).
- **Granularidade:** Um registro por Seção Eleitoral.
- **Chaves de Ligação (FKs):** `ANO_ELEICAO`, `SK_LOCAL_VOTACAO`.
- **Métricas Numéricas:** `QT_APTOS`, `QT_COMPARECIMENTO`, `QT_ABSTENCAO`.
- **Utilidade nos KPIs:** Alimenta o KPI 7.


# 3. Tabela Física vs. View: Qual é a melhor opção para Fatos e Dimensões?
**A melhor opção é utilizar TABELAS FÍSICAS para o Star Schema**, exatamente como o seu professor estruturou no script (`CREATE TABLE dbo.Dim_...` e `CREATE TABLE dbo.Fato_...`).
### A Abordagem Híbrida Ideal (A Prática do Mercado):
- **Camada de DW (Modelo Fisicalizado):** Crie e popule as **Tabelas Físicas** (`Fato_Votacao`, `Dim_Candidato`, etc.).
- **Camada Semântica (Views para o BI):** Crie **Views por cima das Tabelas Físicas** (ex: `CREATE VIEW vw_bi_Fato_Votacao AS SELECT * FROM dbo.Fato_Votacao`). O Power BI se conecta a essas Views. Assim, se você precisar alterar uma regra de negócio ou nome de coluna no futuro, basta alterar a View sem precisar recriar as tabelas físicas do banco.


# 4. Qual é o impacto de usar 3 Tabelas Fato diferentes?
Usar **3 Tabelas Fato diferentes** configura um modelo chamado **Fact Constellation Schema** (ou Modelo em Constelação / Galáxia). Essa é a decisão arquitetural **correta** para o projeto eleitoral.

As suas 3 bases possuem **grãos (granularidades) totalmente incompatíveis**:
- **`Fato_Votacao`**: O grão é _Candidato x Seção Eleitoral_.
- **`Fato_Comparecimento_Abstencao`**: O grão é _Seção Eleitoral_ (não existe candidato aqui).
- **`Fato_Perfil_Eleitorado`**: O grão é _Perfil Demográfico (Idade/Escolaridade) x Seção Eleitoral_.

Se você tentasse juntar tudo numa **única tabela fato**, ocorreria uma **Anomalia de Duplicação (Fan Trap / Chasm Trap)**: os votos dos candidatos seriam multiplicados centenas de vezes para se ajustarem às linhas de perfil demográfico, destruindo a precisão das somas.


# 5. Execução das Tabelas Dimensão e Fato no MSSQL
Na modelagem dimensional, a regra de integridade relacional exige que todas as **Tabelas Dimensão** sejam criadas e populadas **antes** das Tabelas Fato. Isso ocorre porque a tabela fato conterá Chaves Estrangeiras (`FOREIGN KEY`) apontando para as Chaves Primárias (`PRIMARY KEY` / `SK`) das dimensões.

A ordem de execução do pipeline será:
1. **`Dim_Eleicao`** (Tempo / Calendário)
2. **`Dim_Local_Votacao`**
3. **`Dim_Candidato_Partido`**
4. **`Dim_Perfil_Demografico`**
5. **`Fato_Votacao`**
6. **`Fato_Perfil_Eleitorado`**
7. **`Fato_Comparecimento_Abstencao`**

### Passo 1: `Dim_Eleicao`
Começamos pela **`Dim_Eleicao`**, pois ela define o grão temporal dos pleitos (2018 e 2022) e serve de base para os cruzamentos de todos os KPIs.
Seguiremos o padrão demonstrado no script, utilizando uma chave substituta de data numéricas no formato `AAAAMMDD`.
###### 1. Script DDL (`CREATE TABLE`)
```
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
```
###### 2. Script DML (`INSERT INTO`)
Como os pleitos de 2018 e 2022 possuem datas fixas e conhecidas, a inserção é feita de forma estática direta:
```
INSERT INTO dbo.Dim_Eleicao (SK_Eleicao, DT_Eleicao, NR_Ano, NR_Turno, DS_Eleicao)
VALUES 
    (20181007, '2018-10-07', 2018, 1, 'ELEIÇÕES GERAIS 2018 - 1º TURNO'),
    (20181028, '2018-10-28', 2018, 2, 'ELEIÇÕES GERAIS 2018 - 2º TURNO'),
    (20221002, '2022-10-02', 2022, 1, 'ELEIÇÕES GERAIS 2022 - 1º TURNO'),
    (20221030, '2022-10-30', 2022, 2, 'ELEIÇÕES GERAIS 2022 - 2º TURNO');

-- Validação de carga
SELECT * FROM dbo.Dim_Eleicao;
```

### Passo 2: `Dim_Local_Votacao` (Geografia)
A **`Dim_Local_Votacao`** consolida toda a hierarquia geográfica e administrativa dos colégios eleitorais.
Esta dimensão utiliza uma **Chave Substituta (`SK_Local_Votacao`)** como Chave Primária (`IDENTITY`) e mapeia uma **Chave Natural Composta (`NK_Local_Votacao`)** concatenando os códigos do município, zona e local de votação para garantir a unicidade de cada colégio eleitoral.
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Dim_Local_Votacao', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Local_Votacao;

CREATE TABLE dbo.Dim_Local_Votacao (
    SK_Local_Votacao INT IDENTITY(1,1) NOT NULL,
    NK_Local_Votacao VARCHAR(50) NOT NULL,          -- Chave composta: CD_MUNICIPIO + NR_ZONA + NR_LOCAL_VOTACAO
    CD_Municipio INT NOT NULL,                      -- Código do município no TSE
    NM_Municipio VARCHAR(100) NOT NULL,             -- Nome do município
    NR_Zona VARCHAR(10) NOT NULL,                   -- Número da Zona Eleitoral
    NR_Local_Votacao VARCHAR(10) NOT NULL,          -- Número do Local de Votação (Prédio/Escola)
    NM_Local_Votacao VARCHAR(200) NOT NULL,         -- Nome do Colégio Eleitoral
    SG_UF VARCHAR(2) NOT NULL DEFAULT 'SP',         -- Estado (UF)
    FL_Grande_ABC BIT NOT NULL DEFAULT 0,            -- Indicador (1 = Município do Grande ABC, 0 = Outros)
    FL_RMSP BIT NOT NULL DEFAULT 0,                  -- Indicador (1 = Município da RMSP, 0 = Outros)

    CONSTRAINT PK_Dim_Local_Votacao PRIMARY KEY (SK_Local_Votacao),
    CONSTRAINT UQ_Dim_Local_Votacao_NK UNIQUE (NK_Local_Votacao)
);
```
###### 2. Script DML (`INSERT INTO` com Mapeamento Completo de RMSP e ABC)
A carga extrai os locais de votação únicos da base de votação por seção e calcula os sinalizadores regionais para análises dos KPIs:
```
INSERT INTO dbo.Dim_Local_Votacao (
    NK_Local_Votacao,
    CD_Municipio,
    NM_Municipio,
    NR_Zona,
    NR_Local_Votacao,
    NM_Local_Votacao,
    SG_UF,
    FL_Grande_ABC,
    FL_RMSP
)
WITH Locais_Unificados AS (
    SELECT CD_MUNICIPIO, UPPER(NM_MUNICIPIO) AS NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, UPPER(NM_LOCAL_VOTACAO) AS NM_LOCAL_VOTACAO, COALESCE(SG_UF, 'SP') AS SG_UF
    FROM votacao_secao_2022_SP
    UNION
    SELECT CD_MUNICIPIO, UPPER(NM_MUNICIPIO) AS NM_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, UPPER(NM_LOCAL_VOTACAO) AS NM_LOCAL_VOTACAO, COALESCE(SG_UF, 'SP') AS SG_UF
    FROM votacao_secao_2018_SP
),
Locais_Agrupados AS (
    SELECT 
        CONCAT(CD_MUNICIPIO, '_', NR_ZONA, '_', NR_LOCAL_VOTACAO) AS NK_Local_Votacao,
        CD_MUNICIPIO,
        MAX(NM_MUNICIPIO) AS NM_Municipio,
        NR_ZONA AS NR_Zona,
        NR_LOCAL_VOTACAO AS NR_Local_Votacao,
        MAX(COALESCE(NM_LOCAL_VOTACAO, 'LOCAL NÃO INFORMADO')) AS NM_Local_Votacao,
        MAX(SG_UF) AS SG_UF
    FROM Locais_Unificados
    GROUP BY CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO
)
SELECT 
    NK_Local_Votacao,
    CD_Municipio,
    NM_Municipio,
    NR_Zona,
    NR_Local_Votacao,
    NM_Local_Votacao,
    SG_UF,
    CASE 
        WHEN NM_Municipio IN (
            'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL', 
            'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA'
        ) THEN 1 ELSE 0
    END AS FL_Grande_ABC,
    CASE 
        WHEN NM_Municipio IN (
            'SÃO PAULO', 'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL', 
            'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA', 'GUARULHOS', 
            'OSASCO', 'BARUERI', 'CARAPICUÍBA', 'COTIA', 'EMBU DAS ARTES', 'EMBU-GUAÇU', 
            'FERRAZ DE VASCONCELOS', 'FRANCISCO MORATO', 'FRANCO DA ROCHA', 
            'ITAPECERICA DA SERRA', 'ITAPEVI', 'ITAQUAQUECETUBA', 'JANDIRA', 'JUQUITIBA', 
            'MOGI DAS CRUZES', 'POÁ', 'SALESÓPOLIS', 'SANTA ISABEL', 'SANTANA DE PARNAÍBA', 
            'SUZANO', 'TABOÃO DA SERRA', 'VARGEM GRANDE PAULISTA', 'ARUJÁ', 'BIRITIBA MIRIM', 
            'CAIEIRAS', 'CAJAMAR', 'GUARAREMA', 'PIRAPORA DO BOM JESUS', 'SÃO LOURENÇO DA SERRA'
        ) THEN 1 ELSE 0
    END AS FL_RMSP
FROM Locais_Agrupados;
```

### Passo 3: `Dim_Candidato_Partido`
A **`Dim_Candidato_Partido`** centraliza as informações cadastrais dos candidatos, partidos e federações.
Esta dimensão utiliza uma **Chave Substituta (`SK_Candidato_Partido`)** gerada automaticamente pelo banco (`IDENTITY`) e mapeia a **Chave Natural (`NK_Candidato`)** do TSE (representada pelo `SQ_CANDIDATO`). Também inclui os registros sintéticos para mapear **Votos em Branco, Nulos e de Legenda**.
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Dim_Candidato_Partido', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Candidato_Partido;

CREATE TABLE dbo.Dim_Candidato_Partido (
    SK_Candidato_Partido INT IDENTITY(1,1) NOT NULL,
    NK_Candidato VARCHAR(20) NOT NULL,             -- SQ_CANDIDATO do TSE ou Códigos Especiais (95, 96, etc.)
    NR_Candidato VARCHAR(10) NOT NULL,              -- Número de urna (ex: 13, 22, 45123)
    NM_Urna_Candidato VARCHAR(100) NOT NULL,        -- Nome de urna ou descrição do voto
    DS_Cargo VARCHAR(50) NOT NULL,                  -- Cargo disputado (ex: DEPUTADO ESTADUAL)
    SG_Partido VARCHAR(10) NOT NULL,                -- Sigla do Partido
    SG_Federacao VARCHAR(20) NOT NULL DEFAULT 'SEM FEDERAÇÃO', -- Sigla da Federação
    FL_Concorrente_Regional BIT NOT NULL DEFAULT 0, -- Indicador (1 = Concorrente Regional com >= 50% dos votos na região, 0 = Outros)
    
    CONSTRAINT PK_Dim_Candidato_Partido PRIMARY KEY (SK_Candidato_Partido),
    CONSTRAINT UQ_Dim_Candidato_Partido_NK UNIQUE (NK_Candidato)
);
```
###### 2. Script DML (`INSERT INTO`)
A carga é dividida entre os registos especiais de controlo e a consulta com `WITH (CTE)` que calcula a taxa de concentração regional ($\ge 50\%$) para classificar a flag `FL_Concorrente_Regional`:
```
-- 1. Registos Especiais (Brancos, Nulos e Fallback Genérico)
INSERT INTO dbo.Dim_Candidato_Partido (
    NK_Candidato, NR_Candidato, NM_Urna_Candidato, DS_Cargo, SG_Partido, SG_Federacao, FL_Concorrente_Regional
)
VALUES 
    ('95', '95', 'VOTO EM BRANCO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('96', '96', 'VOTO NULO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0),
    ('-1', '-1', 'VOTO NÃO IDENTIFICADO', 'DEPUTADO ESTADUAL', 'N/A', 'SEM FEDERAÇÃO', 0);

-- 2. Carga Unificada de Candidatos (2022 + 2018)
WITH Candidatos_Todos AS (
    SELECT CAST(SQ_CANDIDATO AS VARCHAR(20)) AS NK_Candidato, CAST(NR_CANDIDATO AS VARCHAR(10)) AS NR_Candidato, COALESCE(NM_URNA_CANDIDATO, NM_CANDIDATO) AS NM_Urna_Candidato, DS_CARGO AS DS_Cargo, SG_PARTIDO AS SG_Partido, COALESCE(SG_FEDERACAO, 'SEM FEDERAÇÃO') AS SG_Federacao FROM consulta_cand_2022_SP WHERE DS_CARGO = 'DEPUTADO ESTADUAL'
    UNION
    SELECT CAST(SQ_CANDIDATO AS VARCHAR(20)) AS NK_Candidato, CAST(NR_CANDIDATO AS VARCHAR(10)) AS NR_Candidato, COALESCE(NM_URNA_CANDIDATO, NM_CANDIDATO) AS NM_Urna_Candidato, DS_CARGO AS DS_Cargo, SG_PARTIDO AS SG_Partido, COALESCE(SG_FEDERACAO, 'SEM FEDERAÇÃO') AS SG_Federacao FROM consulta_cand_2018_SP WHERE DS_CARGO = 'DEPUTADO ESTADUAL'
),
Concentracao_Candidatos AS (
    SELECT c.SQ_CANDIDATO, SUM(v.QT_VOTOS) AS Votos_Totais_Estado, SUM(CASE WHEN v.CD_MUNICIPIO IN (SELECT CD_MUNICIPIO FROM dbo.Dim_Local_Votacao WHERE FL_Grande_ABC = 1 OR FL_RMSP = 1) THEN v.QT_VOTOS ELSE 0 END) AS Votos_Regiao
    FROM votacao_secao_2022_SP v
    INNER JOIN consulta_cand_2022_SP c ON v.SQ_CANDIDATO = c.SQ_CANDIDATO
    WHERE c.DS_CARGO = 'DEPUTADO ESTADUAL'
    GROUP BY c.SQ_CANDIDATO
)
INSERT INTO dbo.Dim_Candidato_Partido (
    NK_Candidato, NR_Candidato, NM_Urna_Candidato, DS_Cargo, SG_Partido, SG_Federacao, FL_Concorrente_Regional
)
SELECT DISTINCT
    ct.NK_Candidato,
    ct.NR_Candidato,
    ct.NM_Urna_Candidato,
    ct.DS_Cargo,
    ct.SG_Partido,
    ct.SG_Federacao,
    CASE WHEN cc.Votos_Totais_Estado > 0 AND (cc.Votos_Regiao * 1.0 / cc.Votos_Totais_Estado) >= 0.50 THEN 1 ELSE 0 END AS FL_Concorrente_Regional
FROM Candidatos_Todos ct
LEFT JOIN Concentracao_Candidatos cc ON ct.NK_Candidato = CAST(cc.SQ_CANDIDATO AS VARCHAR(20))
WHERE NOT EXISTS (SELECT 1 FROM dbo.Dim_Candidato_Partido d WHERE d.NK_Candidato = ct.NK_Candidato);

-- 3. Inserção das Legendas Partidárias (2 dígitos)
INSERT INTO dbo.Dim_Candidato_Partido (
    NK_Candidato, NR_Candidato, NM_Urna_Candidato, DS_Cargo, SG_Partido, SG_Federacao, FL_Concorrente_Regional
)
SELECT DISTINCT
    LEFT(v.NR_VOTAVEL, 2) AS NK_Candidato,
    LEFT(v.NR_VOTAVEL, 2) AS NR_Candidato,
    CONCAT('VOTO DE LEGENDA - PARTIDO ', LEFT(v.NR_VOTAVEL, 2)) AS NM_Urna_Candidato,
    'DEPUTADO ESTADUAL' AS DS_Cargo,
    COALESCE(c.SG_PARTIDO, CONCAT('PTDO_', LEFT(v.NR_VOTAVEL, 2))) AS SG_Partido,
    COALESCE(c.SG_FEDERACAO, 'SEM FEDERAÇÃO') AS SG_Federacao,
    0 AS FL_Concorrente_Regional
FROM votacao_secao_2022_SP v
LEFT JOIN consulta_cand_2022_SP c ON LEFT(v.NR_VOTAVEL, 2) = CAST(c.NR_PARTIDO AS VARCHAR)
WHERE LEN(v.NR_VOTAVEL) = 2 
  AND v.NR_VOTAVEL NOT IN ('95', '96')
  AND NOT EXISTS (SELECT 1 FROM dbo.Dim_Candidato_Partido d WHERE d.NK_Candidato = LEFT(v.NR_VOTAVEL, 2));
```

### Passo 4: `Dim_Perfil_Demografico`
A **`Dim_Perfil_Demografico`** consolida os atributos sociodemográficos do eleitorado (faixa etária, grau de escolaridade e gênero).
Como os dados de perfil vêm categorizados pelas codificações do TSE, criamos uma **Chave Substituta (`SK_Perfil_Demografico`)** via `IDENTITY` e mapeamos uma **Chave Natural Composta (`NK_Perfil_Demografico`)** concatenando os códigos numéricos dos três atributos (`CD_FAIXA_ETARIA_CD_ESCOLARIDADE_CD_GENERO`). Esta abordagem trata também a divergência de nomenclatura vista anteriormente entre `DS_GRAU_ESCOLARIDADE` e `DS_GRAU_INSTRUCAO`.
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Dim_Perfil_Demografico', 'U') IS NOT NULL
    DROP TABLE dbo.Dim_Perfil_Demografico;

CREATE TABLE dbo.Dim_Perfil_Demografico (
    SK_Perfil_Demografico INT IDENTITY(1,1) NOT NULL,
    NK_Perfil_Demografico VARCHAR(50) NOT NULL,          -- Chave composta: CD_FAIXA_ETARIA_CD_ESCOLARIDADE_CD_GENERO
    CD_Faixa_Etaria INT NOT NULL,
    DS_Faixa_Etaria VARCHAR(50) NOT NULL,
    CD_Escolaridade INT NOT NULL,
    DS_Escolaridade VARCHAR(100) NOT NULL,
    CD_Genero INT NOT NULL,
    DS_Genero VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Dim_Perfil_Demografico PRIMARY KEY (SK_Perfil_Demografico),
    CONSTRAINT UQ_Dim_Perfil_Demografico_NK UNIQUE (NK_Perfil_Demografico)
);
```
###### 2. Script DML (`INSERT INTO`)
O povoamento insere primeiramente um registo sintético de _fallback_ (para tratar eventuais dados nulos/não informados) e extrai as combinações únicas a partir da base de perfil do eleitorado:
```
-- 1. Inserção do Registo de Controlo (Fallback para dados não informados)
INSERT INTO dbo.Dim_Perfil_Demografico (
    NK_Perfil_Demografico, 
    CD_Faixa_Etaria, 
    DS_Faixa_Etaria, 
    CD_Escolaridade, 
    DS_Escolaridade, 
    CD_Genero, 
    DS_Genero
)
VALUES (
    '-1_-1_-1', 
    -1, 'NÃO INFORMADO', 
    -1, 'NÃO INFORMADO', 
    -1, 'NÃO INFORMADO'
);

-- 2. Carga dos Perfis Demográficos Únicos da Base do TSE
INSERT INTO dbo.Dim_Perfil_Demografico (
    NK_Perfil_Demografico,
    CD_Faixa_Etaria,
    DS_Faixa_Etaria,
    CD_Escolaridade,
    DS_Escolaridade,
    CD_Genero,
    DS_Genero
)
SELECT DISTINCT
    -- Construção da Chave Natural (NK)
    CONCAT(
        COALESCE(CD_FAIXA_ETARIA, -1), '_',
        COALESCE(CD_GRAU_ESCOLARIDADE, -1), '_',
        COALESCE(CD_GENERO, -1)
    ) AS NK_Perfil_Demografico,
    
    COALESCE(CD_FAIXA_ETARIA, -1) AS CD_Faixa_Etaria,
    COALESCE(UPPER(DS_FAIXA_ETARIA), 'NÃO INFORMADO') AS DS_Faixa_Etaria,
    
    COALESCE(CD_GRAU_ESCOLARIDADE, -1) AS CD_Escolaridade,
    COALESCE(UPPER(DS_GRAU_ESCOLARIDADE), 'NÃO INFORMADO') AS DS_Escolaridade,
    
    COALESCE(CD_GENERO, -1) AS CD_Genero,
    COALESCE(UPPER(DS_GENERO), 'NÃO INFORMADO') AS DS_Genero

FROM perfil_eleitor_secao_2022_SP;

-- Validação da Carga
SELECT TOP 10 * FROM dbo.Dim_Perfil_Demografico;
```

### Passo 5: `Fato_Votacao`
A **`Fato_Votacao`** regista a métrica central do projeto (`QT_VOTOS`) no seu grão mais detalhado: **Candidato / Tipo de Voto por Seção Eleitoral e Pleito**.
Esta tabela conecta-se diretamente a três dimensões (`Dim_Eleicao`, `Dim_Local_Votacao` e `Dim_Candidato_Partido`) através de Chaves Estrangeiras (`FOREIGN KEY`). O número da seção eleitoral (`NR_Secao`) permanece na fato como um **atributo degenerado** (sem necessidade de uma dimensão própria para seções).
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Fato_Votacao', 'U') IS NOT NULL
    DROP TABLE dbo.Fato_Votacao;

CREATE TABLE dbo.Fato_Votacao (
    SK_Votacao INT IDENTITY(1,1) NOT NULL,
    SK_Eleicao INT NOT NULL,                      -- FK para Dim_Eleicao
    SK_Local_Votacao INT NOT NULL,                 -- FK para Dim_Local_Votacao
    SK_Candidato_Partido INT NOT NULL,             -- FK para Dim_Candidato_Partido
    NR_Secao VARCHAR(10) NOT NULL,                 -- Atributo degenerado (Número da Seção)
    QT_Votos INT NOT NULL,                         -- Métrica principal (Quantidade de Votos)

    CONSTRAINT PK_Fato_Votacao PRIMARY KEY (SK_Votacao),
    CONSTRAINT FK_Fato_Votacao_Eleicao FOREIGN KEY (SK_Eleicao) 
        REFERENCES dbo.Dim_Eleicao (SK_Eleicao),
    CONSTRAINT FK_Fato_Votacao_LocalVotacao FOREIGN KEY (SK_Local_Votacao) 
        REFERENCES dbo.Dim_Local_Votacao (SK_Local_Votacao),
    CONSTRAINT FK_Fato_Votacao_CandidatoPartido FOREIGN KEY (SK_Candidato_Partido) 
        REFERENCES dbo.Dim_Candidato_Partido (SK_Candidato_Partido),
    CONSTRAINT CK_Fato_Votacao_QT_Votos CHECK (QT_Votos >= 0)
);
```
###### 2. Script DML (`INSERT INTO` com Lookup de Chaves)
O povoamento realiza o _lookup_ (troca das chaves naturais pelas chaves substitutas `SK`) através de `JOIN`s com as dimensões. Para votos de legenda, brancos e nulos, utiliza-se a lógica de _fallback_ para mapear os registos especiais criados na `Dim_Candidato_Partido`.
```
INSERT INTO dbo.Fato_Votacao (
    SK_Eleicao,
    SK_Local_Votacao,
    SK_Candidato_Partido,
    NR_Secao,
    QT_Votos
)
SELECT 
    20221002 AS SK_Eleicao,
    dlv.SK_Local_Votacao,
    
    -- Mapeamento Hierárquico: 1. Candidato Nominal -> 2. Voto de Legenda -> 3. Branco/Nulo -> 4. Fallback
    COALESCE(
        dcp.SK_Candidato_Partido,      -- Busca por SQ_CANDIDATO
        dleg.SK_Candidato_Partido,     -- Busca por Legenda do Partido (2 dígitos)
        CASE 
            WHEN v.NR_VOTAVEL = '95' THEN (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '95')
            WHEN v.NR_VOTAVEL = '96' THEN (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '96')
            ELSE (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '-1')
        END
    ) AS SK_Candidato_Partido,
    
    v.NR_SECAO,
    v.QT_VOTOS

FROM votacao_secao_2022_SP v
INNER JOIN dbo.Dim_Local_Votacao dlv 
    ON CONCAT(v.CD_MUNICIPIO, '_', v.NR_ZONA, '_', v.NR_LOCAL_VOTACAO) = dlv.NK_Local_Votacao
LEFT JOIN dbo.Dim_Candidato_Partido dcp 
    ON CAST(v.SQ_CANDIDATO AS VARCHAR(20)) = dcp.NK_Candidato
LEFT JOIN dbo.Dim_Candidato_Partido dleg 
    ON LEN(v.NR_VOTAVEL) = 2 AND LEFT(v.NR_VOTAVEL, 2) = dleg.NK_Candidato;
```

```
-- Carga Histórica Complementar: Eleição 2018 (1º Turno) na Fato_Votacao
INSERT INTO dbo.Fato_Votacao (
    SK_Eleicao,
    SK_Local_Votacao,
    SK_Candidato_Partido,
    NR_Secao,
    QT_Votos
)
SELECT 
    20181007 AS SK_Eleicao, -- SK referente ao 1º Turno de 2018 na Dim_Eleicao
    dlv.SK_Local_Votacao,
    
    COALESCE(
        dcp.SK_Candidato_Partido,      -- Busca por SQ_CANDIDATO
        dleg.SK_Candidato_Partido,     -- Busca por Legenda do Partido (2 dígitos)
        CASE 
            WHEN v.NR_VOTAVEL = '95' THEN (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '95')
            WHEN v.NR_VOTAVEL = '96' THEN (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '96')
            ELSE (SELECT SK_Candidato_Partido FROM dbo.Dim_Candidato_Partido WHERE NK_Candidato = '-1')
        END
    ) AS SK_Candidato_Partido,
    
    v.NR_SECAO,
    v.QT_VOTOS

FROM votacao_secao_2018_SP v
INNER JOIN dbo.Dim_Local_Votacao dlv 
    ON CONCAT(v.CD_MUNICIPIO, '_', v.NR_ZONA, '_', v.NR_LOCAL_VOTACAO) = dlv.NK_Local_Votacao
LEFT JOIN dbo.Dim_Candidato_Partido dcp 
    ON CAST(v.SQ_CANDIDATO AS VARCHAR(20)) = dcp.NK_Candidato
LEFT JOIN dbo.Dim_Candidato_Partido dleg 
    ON LEN(v.NR_VOTAVEL) = 2 AND LEFT(v.NR_VOTAVEL, 2) = dleg.NK_Candidato;
```

### Passo 6: `Fato_Perfil_Eleitorado`
A **`Fato_Perfil_Eleitorado`** regista a distribuição quantitativa de eleitores aptos por perfil demográfico (faixa etária, escolaridade e género) em cada secção eleitoral.
Esta tabela conecta-se a três dimensões (`Dim_Eleicao`, `Dim_Local_Votacao` e `Dim_Perfil_Demografico`) via Chaves Estrangeiras (`FOREIGN KEY`) e mantém o número da secção (`NR_Secao`) como um atributo degenerado.
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Fato_Perfil_Eleitorado', 'U') IS NOT NULL
    DROP TABLE dbo.Fato_Perfil_Eleitorado;

CREATE TABLE dbo.Fato_Perfil_Eleitorado (
    SK_Perfil_Eleitorado INT IDENTITY(1,1) NOT NULL,
    SK_Eleicao INT NOT NULL,                          -- FK para Dim_Eleicao
    SK_Local_Votacao INT NOT NULL,                     -- FK para Dim_Local_Votacao
    SK_Perfil_Demografico INT NOT NULL,                -- FK para Dim_Perfil_Demografico
    NR_Secao VARCHAR(10) NOT NULL,                     -- Atributo degenerado (Número da Secção)
    QT_Eleitores_Perfil INT NOT NULL,                  -- Métrica (Quantidade de Eleitores no Perfil)

    CONSTRAINT PK_Fato_Perfil_Eleitorado PRIMARY KEY (SK_Perfil_Eleitorado),
    CONSTRAINT FK_Fato_Perfil_Eleitorado_Eleicao FOREIGN KEY (SK_Eleicao) 
        REFERENCES dbo.Dim_Eleicao (SK_Eleicao),
    CONSTRAINT FK_Fato_Perfil_Eleitorado_LocalVotacao FOREIGN KEY (SK_Local_Votacao) 
        REFERENCES dbo.Dim_Local_Votacao (SK_Local_Votacao),
    CONSTRAINT FK_Fato_Perfil_Eleitorado_PerfilDemografico FOREIGN KEY (SK_Perfil_Demografico) 
        REFERENCES dbo.Dim_Perfil_Demografico (SK_Perfil_Demografico),
    CONSTRAINT CK_Fato_Perfil_Eleitorado_QT_Eleitores CHECK (QT_Eleitores_Perfil >= 0)
);
```
###### 2. Script DML (`INSERT INTO` com Lookup de Chaves)
O povoamento realiza o _lookup_ das chaves substitutas `SK` combinando a localização e os códigos sociodemográficos da base de perfil do eleitorado com o registo de segurança (_fallback_) para perfis não identificados:
```
-- Carga dos Dados da Eleição de 2022 (1º Turno)
INSERT INTO dbo.Fato_Perfil_Eleitorado (
    SK_Eleicao,
    SK_Local_Votacao,
    SK_Perfil_Demografico,
    NR_Secao,
    QT_Eleitores_Perfil
)
SELECT 
    20221002 AS SK_Eleicao, -- SK do 1º Turno de 2022
    dlv.SK_Local_Votacao,
    
    -- Lookup da SK do Perfil Demográfico (com Fallback para não informado)
    COALESCE(dpd.SK_Perfil_Demografico, 
        (SELECT SK_Perfil_Demografico FROM dbo.Dim_Perfil_Demografico WHERE NK_Perfil_Demografico = '-1_-1_-1')
    ) AS SK_Perfil_Demografico,
    
    p.NR_SECAO,
    p.QT_ELEITORES_PERFIL

FROM perfil_eleitor_secao_2022_SP p
INNER JOIN dbo.Dim_Local_Votacao dlv 
    ON CONCAT(p.CD_MUNICIPIO, '_', p.NR_ZONA, '_', p.NR_LOCAL_VOTACAO) = dlv.NK_Local_Votacao
LEFT JOIN dbo.Dim_Perfil_Demografico dpd 
    ON CONCAT(
        COALESCE(p.CD_FAIXA_ETARIA, -1), '_',
        COALESCE(p.CD_GRAU_ESCOLARIDADE, -1), '_',
        COALESCE(p.CD_GENERO, -1)
    ) = dpd.NK_Perfil_Demografico;

-- Validação de Integridade
SELECT 
    e.NR_Ano,
    COUNT(*) AS Total_Linhas_Fato,
    SUM(f.QT_Eleitores_Perfil) AS Total_Eleitores_Mapeados
FROM dbo.Fato_Perfil_Eleitorado f
JOIN dbo.Dim_Eleicao e ON f.SK_Eleicao = e.SK_Eleicao
GROUP BY e.NR_Ano;
```

### Passo 7: `Fato_Comparecimento_Abstencao`
A **`Fato_Comparecimento_Abstencao`** regista os totais de eleitores aptos, o número de comparências e as abstenções ao nível de detalhe da secção eleitoral. Alimenta diretamente os cálculos de participação do eleitorado (como o KPI 7).
Esta tabela conecta-se a duas dimensões (`Dim_Eleicao` e `Dim_Local_Votacao`) através de Chaves Estrangeiras (`FOREIGN KEY`) e mantém o número da secção (`NR_Secao`) como um atributo degenerado.
###### 1. Script DDL (`CREATE TABLE`)
```
IF OBJECT_ID('dbo.Fato_Comparecimento_Abstencao', 'U') IS NOT NULL
    DROP TABLE dbo.Fato_Comparecimento_Abstencao;

CREATE TABLE dbo.Fato_Comparecimento_Abstencao (
    SK_Comparecimento_Abstencao INT IDENTITY(1,1) NOT NULL,
    SK_Eleicao INT NOT NULL,                          -- FK para Dim_Eleicao
    SK_Local_Votacao INT NOT NULL,                     -- FK para Dim_Local_Votacao
    NR_Secao VARCHAR(10) NOT NULL,                     -- Atributo degenerado (Número da Secção)
    QT_Aptos INT NOT NULL,                             -- Métrica: Eleitores aptos a votar
    QT_Comparecimento INT NOT NULL,                    -- Métrica: Eleitores que votaram
    QT_Abstencao INT NOT NULL,                         -- Métrica: Eleitores que abstiveram

    CONSTRAINT PK_Fato_Comparecimento_Abstencao PRIMARY KEY (SK_Comparecimento_Abstencao),
    CONSTRAINT FK_Fato_Comparecimento_Abstencao_Eleicao FOREIGN KEY (SK_Eleicao) 
        REFERENCES dbo.Dim_Eleicao (SK_Eleicao),
    CONSTRAINT FK_Fato_Comparecimento_Abstencao_LocalVotacao FOREIGN KEY (SK_Local_Votacao) 
        REFERENCES dbo.Dim_Local_Votacao (SK_Local_Votacao),
    CONSTRAINT CK_Fato_Comparecimento_Abstencao_Aptos CHECK (QT_Aptos >= 0),
    CONSTRAINT CK_Fato_Comparecimento_Abstencao_Comparecimento CHECK (QT_Comparecimento >= 0),
    CONSTRAINT CK_Fato_Comparecimento_Abstencao_Abstencao CHECK (QT_Abstencao >= 0)
);
```
###### 2. Script DML (`INSERT INTO` com Lookup de Chaves)
O povoamento extrai os dados acumulados por secção da base de detalhe do TSE (`detalhe_votacao_secao_2022_SP` ou `perfil_comparecimento_abstencao_2022_SP`) e substitui as chaves naturais pela `SK` da `Dim_Local_Votacao`:
```
WITH Mapa_Secao_Local AS (
    SELECT 
        CD_MUNICIPIO, 
        NR_ZONA, 
        NR_SECAO, 
        MAX(NR_LOCAL_VOTACAO) AS NR_LOCAL_VOTACAO
    FROM votacao_secao_2022_SP
    GROUP BY CD_MUNICIPIO, NR_ZONA, NR_SECAO
)
INSERT INTO dbo.Fato_Comparecimento_Abstencao (
    SK_Eleicao,
    SK_Local_Votacao,
    NR_Secao,
    QT_Aptos,
    QT_Comparecimento,
    QT_Abstencao
)
SELECT 
    20221002 AS SK_Eleicao,
    dlv.SK_Local_Votacao,
    d.NR_SECAO,
    SUM(d.QT_APTOS) AS QT_Aptos,
    SUM(d.QT_COMPARECIMENTO) AS QT_Comparecimento,
    SUM(d.QT_ABSTENCAO) AS QT_Abstencao
FROM detalhe_votacao_secao_2022_SP d
INNER JOIN Mapa_Secao_Local m
    ON d.CD_MUNICIPIO = m.CD_MUNICIPIO
   AND d.NR_ZONA = m.NR_ZONA
   AND d.NR_SECAO = m.NR_SECAO
INNER JOIN dbo.Dim_Local_Votacao dlv 
    ON CONCAT(m.CD_MUNICIPIO, '_', m.NR_ZONA, '_', m.NR_LOCAL_VOTACAO) = dlv.NK_Local_Votacao
GROUP BY 
    dlv.SK_Local_Votacao,
    d.NR_SECAO;
```