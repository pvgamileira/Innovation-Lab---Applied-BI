A lógica da extração por _substring_ baseia-se na regra de numeração da Justiça Eleitoral brasileira para eleições proporcionais (como a de Deputado Estadual):
- **Voto Nominal (5 dígitos):** O número do candidato possui 5 dígitos (ex: `45123`). Os dois primeiros dígitos (`45`) identificam o partido (PSDB).
- **Voto de Legenda (2 dígitos):** O eleitor digita apenas os dois dígitos do partido (ex: `45` ou `23`).
- **Votos Alienados (2 dígitos):** O TSE utiliza os códigos estáticos `95` para Voto em Branco e `96` para Voto Nulo.
Com a técnica de _substring_, recortam-se os dois primeiros caracteres do campo `NR_VOTAVEL` para inferir o número do partido.

# Como fazer essa extração no MSSQL (T-SQL)
O **Microsoft SQL Server (MSSQL)** executa essa operação nativamente e de forma performática. Pode utilizar as funções `LEFT`, `LEN` e uma estrutura `CASE WHEN`.
### Script T-SQL para MSSQL
Eis uma estrutura de consulta SQL que executa esse processo (adapte de acordo com seu banco e suas bases):

```
SELECT 
    v.CD_MUNICIPIO,
    v.NR_ZONA,
    v.NR_LOCAL_VOTACAO,
    v.NR_VOTAVEL,
    
    -- Extrai o número do partido ou classifica o tipo de voto
    CASE 
        WHEN v.NR_VOTAVEL = '95' THEN 'BRANCO'
        WHEN v.NR_VOTAVEL = '96' THEN 'NULO'
        WHEN LEN(v.NR_VOTAVEL) IN (2, 5) THEN LEFT(v.NR_VOTAVEL, 2)
        ELSE 'OUTROS'
    END AS NR_PARTIDO,

    -- Classifica a modalidade do voto
    CASE 
        WHEN LEN(v.NR_VOTAVEL) = 5 THEN 'VOTO NOMINAL'
        WHEN LEN(v.NR_VOTAVEL) = 2 AND v.NR_VOTAVEL NOT IN ('95', '96') THEN 'VOTO LEGENDA'
        WHEN v.NR_VOTAVEL = '95' THEN 'VOTO BRANCO'
        WHEN v.NR_VOTAVEL = '96' THEN 'VOTO NULO'
        ELSE 'INVALIDO'
    END AS TIPO_VOTO,
    
    v.QT_VOTOS

FROM votacao_secao_2022_SP v;
```

### JOIN Híbrido com a `consulta_cand_2022_SP`
Como já foi definida a inclusão da base `consulta_cand_2022_SP`, ela traz as colunas oficiais `NR_PARTIDO`, `SG_PARTIDO`, `SG_FEDERACAO` e `NM_URNA_CANDIDATO`.

Basta fazer um `LEFT JOIN` pela chave `SQ_CANDIDATO` ou `NR_VOTAVEL` = `NR_CANDIDATO` e tratar as exceções (Legenda, Branco e Nulo) com `COALESCE` ou `CASE`, retornando a sigla real e o nome do candidato/federação com dados oficiais do TSE, sem depender de listas manuais:

```
SELECT 
    v.NR_ZONA,
    v.NR_LOCAL_VOTACAO,
    v.NR_VOTAVEL,
    
    -- Se for candidato, pega a sigla oficial; se for legenda/branco/nulo, aplica a regra de exceção
    COALESCE(c.SG_PARTIDO, 
        CASE 
            WHEN v.NR_VOTAVEL = '45' THEN 'PSDB'
            WHEN v.NR_VOTAVEL = '23' THEN 'CIDADANIA'
            WHEN v.NR_VOTAVEL = '95' THEN 'BRANCO'
            WHEN v.NR_VOTAVEL = '96' THEN 'NULO'
            ELSE 'OUTROS'
        END
    ) AS SG_PARTIDO,
    
    COALESCE(c.SG_FEDERACAO, 'SEM FEDERAÇÃO') AS SG_FEDERACAO,
    v.QT_VOTOS

FROM votacao_secao_2022_SP v
LEFT JOIN consulta_cand_2022_SP c 
    ON v.SQ_CANDIDATO = c.SQ_CANDIDATO;
```

# Passo a Passo de Aplicação no MSSQL
### Passo 1: Sanitização e Compatibilização das Chaves
No leiaute do TSE, valores nulos em campos de texto costumam vir preenchidos como `'#NULO'` ou `-1`. Antes de rodar o `JOIN`, certifique-se de que a chave `SQ_CANDIDATO` possui o mesmo tipo de dado em ambas as tabelas (recomendado: `BIGINT` ou `VARCHAR(20)`).


### Passo 2: Construção da Lógica com `LEFT JOIN` e Tratamento de Exceções
Crie a lógica SQL utilizando `COALESCE` para dar prioridade aos dados oficiais da `consulta_cand_2022_SP` e o `CASE WHEN` para capturar votos de legenda, brancos e nulos:

```
SELECT 
    v.CD_MUNICIPIO,
    v.NR_ZONA,
    v.NR_LOCAL_VOTACAO,
    v.NR_SECAO,
    v.NR_VOTAVEL,
    v.QT_VOTOS,

    -- 1. Nome do Candidato / Tipo de Voto
    COALESCE(c.NM_URNA_CANDIDATO, 
        CASE 
            WHEN v.NR_VOTAVEL = '95' THEN 'VOTO EM BRANCO'
            WHEN v.NR_VOTAVEL = '96' THEN 'VOTO NULO'
            WHEN LEN(v.NR_VOTAVEL) = 2 THEN CONCAT('LEGENDA - ', v.NR_VOTAVEL)
            ELSE 'OUTROS / NÃO IDENTIFICADO'
        END
    ) AS NM_VOTAVEL_AJUSTADO,

    -- 2. Sigla do Partido
    COALESCE(c.SG_PARTIDO, 
        CASE 
            WHEN v.NR_VOTAVEL IN ('45', '95', '96') THEN 'PSDB' -- Ou mapeamento do número
            WHEN v.NR_VOTAVEL = '23' THEN 'CIDADANIA'
            WHEN LEN(v.NR_VOTAVEL) = 5 THEN LEFT(v.NR_VOTAVEL, 2) -- Extrai o nº do partido para nominais sem cadastro
            ELSE 'OUTROS'
        END
    ) AS SG_PARTIDO_AJUSTADO,

    -- 3. Sigla da Federação
    COALESCE(c.SG_FEDERACAO, 'SEM FEDERAÇÃO') AS SG_FEDERACAO,

    -- 4. Classificação da Modalidade do Voto
    CASE 
        WHEN c.SQ_CANDIDATO IS NOT NULL THEN 'NOMINAL'
        WHEN LEN(v.NR_VOTAVEL) = 2 AND v.NR_VOTAVEL NOT IN ('95', '96') THEN 'LEGENDA'
        WHEN v.NR_VOTAVEL = '95' THEN 'BRANCO'
        WHEN v.NR_VOTAVEL = '96' THEN 'NULO'
        ELSE 'OUTROS'
    END AS TIPO_VOTO

FROM votacao_secao_2022_SP v
LEFT JOIN consulta_cand_2022_SP c 
    ON v.SQ_CANDIDATO = c.SQ_CANDIDATO
   AND c.DS_CARGO = 'DEPUTADO ESTADUAL'; -- Mantém o foco no cargo analisado
```

### Passo 3: Criação de uma `VIEW` no Banco de Dados
Para evitar reescrever esse código em cada KPI ou relatório, materialize essa estrutura como uma `VIEW` no MSSQL:

```
CREATE VIEW vw_votacao_enriquecida_2022 AS
-- (Inserir a consulta do Passo 2 aqui)
```

A partir desse momento, todas as consultas dos KPIs do Dashboard consumirão diretamente a `vw_votacao_enriquecida_2022`, que já trará as colunas de partido, federação e candidato devidamente preenchidas.

### Passo 4: Validação de Integridade (Auditoria)
Execute este teste rápido para validar se o `JOIN` não duplicou nem perdeu votos:

```
-- O somatório deve ser 100% idêntico nas duas tabelas
SELECT SUM(QT_VOTOS) AS Total_Original FROM votacao_secao_2022_SP;
SELECT SUM(QT_VOTOS) AS Total_Enriquecido FROM vw_votacao_enriquecida_2022;
```

Se ambos os valores forem exatamente iguais, a ligação das bases está concluída e validada com sucesso.