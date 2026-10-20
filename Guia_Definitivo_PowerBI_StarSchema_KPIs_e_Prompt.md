# 📘 Guia Definitivo: Modelagem Star Schema, Gabarito Auditado dos 10 KPIs, Mapa Clicável de SP no Power BI & Super Prompt Mestre

**Projeto:** Innovation Lab — Applied BI & Relational Database Programming (T-SQL) — Faculdade Impacta  
**Equipe:** **Start Phoenix Consultoria** (Caique Gonçalves Sambrana, Henrique Castilho Pires de Carvalho, João Vitor Costa Matos, Paulo Vitor Gameleira Alves, Kauê Ribeiro Garcia Mendes)  
**Cliente Oficial:** Equipe de Inteligência de Campanha da **Deputada Estadual Ana Carolina Serra** (`NR_CANDIDATO = '23023'`, `NK_CANDIDATO = '250001611505'`, `SK_CANDIDATO_PARTIDO = 653`, `SG_PARTIDO = 'CIDADANIA'`, `SG_FEDERACAO = 'PSDB/CIDADANIA'`, `FL_CONCORRENTE_REGIONAL = 1`) — Reeleição 2026  
**Banco de Dados Ativo:** SQL Server (`localhost`), Database `InnovationLab_AppliedBI`

---

## 🔍 SEÇÃO 1: Por que os KPIs não estavam batendo? (As 4 Armadilhas Críticas do Projeto)

Durante a auditoria completa dos **84 arquivos do repositório** e das **7 tabelas dimensionais + 5 views** no banco `InnovationLab_AppliedBI`, identificamos **4 armadilhas técnicas** que faziam os números divergirem entre o SQL e o Power BI:

### ⚠️ Armadilha 1: Votos Totais Depositados vs. Votos Válidos no Denominador
Na tabela `Fato_Votacao`, estão carregados **todos os votos depositados na urna** para Deputado Estadual:
- **Votos Válidos** (`NK_CANDIDATO NOT IN ('95', '96', '-1')`): Votos Nominais em candidatos + Votos de Legenda Partidária (2 dígitos).
- **Votos Alienados** (`NK_CANDIDATO IN ('95', '96')`): Votos em Branco (`95`) e Votos Nulos (`96`).
- **Erro comum:** Dividir os votos da candidata ou do partido por `SUM(Fato_Votacao[QT_VOTOS])` sem filtrar `NK_CANDIDATO NOT IN ('95', '96', '-1')`.
  - Em **2018**: Total depositado = **`25.921.320`**, mas **Votos Válidos = `21.000.593`** (`4.920.727` foram brancos/nulos, ou `18,98%`).
  - Em **2022**: Total depositado = **`27.147.847`**, mas **Votos Válidos = `23.305.480`** (`3.842.367` foram brancos/nulos, ou `14,15%`).
- **Regra de Ouro:**
  - **KPIs 1 (VHMS), 2 (TDL%), 3 (MDZ p.p.) e 4 (RML%)** usam **VOTOS VÁLIDOS** no denominador!
  - **KPI 9 (ΔIAR p.p. — Votos Alienados)** usa **VOTOS TOTAIS DEPOSITADOS** no denominador!

### ⚠️ Armadilha 2: A Mudança Institucional de 2022 — `SG_PARTIDO = 'PSDB'` vs. `SG_FEDERACAO = 'PSDB/CIDADANIA'`
Esta é a pegadinha mais importante de negócio e de banco de dados:
1. A nossa cliente **Deputada Estadual Ana Carolina Serra (`23023`)** concorreu em 2022 pelo **CIDADANIA (`23`)**, que formou oficialmente a **Federação `PSDB/CIDADANIA`** com o PSDB (`45`). Na tabela `Dim_Candidato_Partido`, o registro dela (`SK_CANDIDATO_PARTIDO = 653`) possui:
   - `SG_PARTIDO = 'CIDADANIA'`
   - `SG_FEDERACAO = 'PSDB/CIDADANIA'`
   - Se alguém colocar um filtro `SG_PARTIDO = 'PSDB'` no Power BI, **os 198.698 votos da Ana Carolina Serra zeram!**
2. Já na eleição de **2018** (quando ainda não existia a lei das Federações Partidárias no TSE):
   - Os candidatos nominais do PSDB de 2018 foram carregados na `Dim_Candidato_Partido` com `SG_PARTIDO = 'PSDB'` e `SG_FEDERACAO = 'SEM FEDERAÇÃO'` (`1.727.478` votos).
   - Já o voto de legenda `45` foi unificado na `Dim_Candidato_Partido` com `SG_PARTIDO = 'PSDB'` e `SG_FEDERACAO = 'PSDB/CIDADANIA'` (`311.196` votos em 2018).
   - Portanto, se em 2018 você filtrar por `SG_FEDERACAO = 'PSDB/CIDADANIA'`, você pega **apenas os 311.196 votos de legenda** e perde os **1.727.478 votos nominais** do PSDB!
- **Regra de Ouro para o KPI 1 (VHMS) conforme a Matriz Oficial:**
  - **Baseline 2018 (`MS_PSDB, 2018`)**: Filtrar `NR_ANO = 2018` e `SG_PARTIDO = 'PSDB'` = **`2.038.674` votos** (`9,71%` dos votos válidos de SP).
  - **Cenário 2022 (`MS_Federação, 2022`)**: Filtrar `NR_ANO = 2022` e `SG_FEDERACAO = 'PSDB/CIDADANIA'` = **`2.552.319` votos** (`10,95%` dos votos válidos de SP, sendo `1.997.660` do PSDB + `554.659` do Cidadania).
  - **Nota Estratégica (Ambas as Variantes Documentadas):**
    - **Fórmula Oficial da Matriz (Federação 2022 vs PSDB 2018):** `10,95% - 9,71% = +1,24 p.p.` no Estado (`+14,44 p.p.` no Grande ABC e `+34,25 p.p.` em Santo André).
    - **Variante Estrita (Apenas PSDB 2022 vs Apenas PSDB 2018):** `8,57% - 9,71% = -1,14 p.p.` no Estado (`1.997.660` vs `2.038.674` votos). Tenha ambos os números na ponta da língua para a banca!

### ⚠️ Armadilha 3: As 3 Tabelas Fato com Grãos Diferentes (Fact Constellation) e a Linha `-1` da `Dim_Eleicao`
1. Nosso Data Warehouse possui **3 Tabelas Fato** porque os dados do TSE têm granularidades incompatíveis:
   - `Fato_Votacao` (**15.833.824 linhas**): Grão = `Candidato/Legenda × Seção × Eleição (2018 e 2022)`.
   - `Fato_Comparecimento_Abstencao` (**101.074 linhas**): Grão = `Seção × Eleição (2022)`. Não tem candidato!
   - `Fato_Perfil_Eleitorado` (**4.504.469 linhas**): Grão = `Perfil Demográfico × Seção × Eleição (2022)`. Não tem candidato!
   - **Nunca faça relacionamento muitos-para-muitos entre Fatos** nem ative filtro bidirecional (`Ambos`) por padrão, para evitar duplicação artificial (*Fan Trap*).
2. Na `Dim_Eleicao`, existem **5 registros**: `20181007` (1ºT 2018), `20181028` (2ºT 2018), `20221002` (1ºT 2022), `20221030` (2ºT 2022) e `-1` (`ELEIÇÃO NÃO IDENTIFICADA`, `NR_ANO = 0`). Como Deputado Estadual só é disputado no **1º Turno**, adicione no **Filtro de Todas as Páginas** do Power BI: `Dim_Eleicao[NR_ANO] IN (2018, 2022)` e `Dim_Eleicao[NR_TURNO] = 1` (ou filtre no Power Query `SK_ELEICAO IN (20181007, 20221002)`).

### ⚠️ Armadilha 4: Contexto de Filtro no DAX (`REMOVEFILTERS`) e Médias de Percentuais
- No Power BI, se o relatório tiver um filtro ou visual com a candidata `ANA CAROLINA SERRA`, uma medida comum `SUM(Fato_Votacao[QT_VOTOS])` retornará apenas os votos dela (`198.698`), fazendo `TDL% = 198.698 / 198.698 = 100%`!
- Por isso, a medida `[Votos Validos Cargo]` **DEVE** usar `REMOVEFILTERS(Dim_Candidato_Partido)` para manter o denominador íntegro em qualquer visual.
- Além disso, quando usar as Views SQL pré-calculadas (`vw_KPI_*`), **nunca** use `Média de TDL_PCT` para achar o consolidado do Estado/Município; use as medidas DAX com `DIVIDE(SUM(...), SUM(...))`.

---

## 🏗️ SEÇÃO 2: Como Montar o Star Schema (Fact Constellation) no Power BI com Estética Nota 10

### 2.1. Como Conectar no SQL Server
1. No Power BI Desktop, clique em **Obter Dados** → **SQL Server**.
2. **Servidor:** `localhost` | **Banco de Dados:** `InnovationLab_AppliedBI` | **Modo:** `Importar` (Import).
3. Marque as **7 tabelas oficiais do Star Schema**:
   - **Dimensões (4):** `Dim_Eleicao`, `Dim_Local_Votacao`, `Dim_Candidato_Partido`, `Dim_Perfil_Demografico`
   - **Fatos (3):** `Fato_Votacao`, `Fato_Comparecimento_Abstencao`, `Fato_Perfil_Eleitorado`
   - *(Opcional — Atalho Turbo)*: Marque também a view `vw_KPI_Painel_Municipio_Mapa_SP` e `vw_KPI_Margem_Disputa_Zona` se quiser arrastar campos prontos para o Mapa e para a tabela de Swing Zones!
4. Clique em **Transformar Dados (Power Query)** antes de carregar:
   - Na tabela `Dim_Eleicao`, filtre `SK_ELEICAO` mantendo apenas `20181007` e `20221002` (remove 2º turno sem votos de deputado e remove a linha `-1`).
   - Na tabela `Dim_Local_Votacao`, filtre `SK_LOCAL_VOTACAO > 0` (remove o registro `-1 LOCAL NÃO IDENTIFICADO`, preservando os `11.164` colégios reais, incluindo `SK_LOCAL_VOTACAO = 1`).

### 2.2. Layout Visual em 3 Camadas na Exibição de Modelo (Padrão Kimball / Roche)
Para deixar o diagrama do Modelo no Power BI com **estética executiva impecável** para o print da entrega e apresentação à banca, organize as caixas em **3 fileiras horizontais (Waterfall Layout)**:

```
====================================================================================================
CAMADA 1 (TOPO - MEDIDAS):                [ 📊 _Medidas_KPIs ]
                                    (Tabela vazia contendo todas as medidas DAX)
====================================================================================================

CAMADA 2 (MEIO - DIMENSÕES: O Contexto "Quem, Onde, Quando")
   [ 📅 Dim_Eleicao ]      [ 🏛️ Dim_Candidato_Partido ]      [ 📍 Dim_Local_Votacao ]      [ 👥 Dim_Perfil_Demografico ]
           |                            |                          /        |        \                      |
           | 1                        1 |                       1 /       1 |       1 \                     | 1
           |                            |                        /          |          \                    |
           *                            *                       *           *           *                   *
====================================================================================================
CAMADA 3 (BASE - TABELAS FATO: As Métricas Numéricas)
           [ 🗳️ Fato_Votacao ]                 [ 📋 Fato_Comparecimento_Abstencao ]        [ 📊 Fato_Perfil_Eleitorado ]
         (15.833.824 linhas)                            (101.074 linhas)                       (4.504.469 linhas)
====================================================================================================
```

### 2.3. Tabela Oficial dos 8 Relacionamentos (Todos `1 : *` e Direção `Única`)
Certifique-se de que **TODOS os 8 relacionamentos** na Exibição de Modelo estejam exatamente assim:

| Nº | Tabela Dimensão (Lado `1`) | Coluna PK (Dimensão) | Direção do Filtro | Cardinalidade | Tabela Fato (Lado `*`) | Coluna FK (Fato) | Ativo? |
|:--:|:---|:---|:---:|:---:|:---|:---|:---:|
| 1 | `Dim_Eleicao` | `SK_ELEICAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Votacao` | `SK_ELEICAO` | ✅ Sim |
| 2 | `Dim_Local_Votacao` | `SK_LOCAL_VOTACAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Votacao` | `SK_LOCAL_VOTACAO` | ✅ Sim |
| 3 | `Dim_Candidato_Partido` | `SK_CANDIDATO_PARTIDO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Votacao` | `SK_CANDIDATO_PARTIDO` | ✅ Sim |
| 4 | `Dim_Eleicao` | `SK_ELEICAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Comparecimento_Abstencao` | `SK_ELEICAO` | ✅ Sim |
| 5 | `Dim_Local_Votacao` | `SK_LOCAL_VOTACAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Comparecimento_Abstencao` | `SK_LOCAL_VOTACAO` | ✅ Sim |
| 6 | `Dim_Eleicao` | `SK_ELEICAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Perfil_Eleitorado` | `SK_ELEICAO` | ✅ Sim |
| 7 | `Dim_Local_Votacao` | `SK_LOCAL_VOTACAO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Perfil_Eleitorado` | `SK_LOCAL_VOTACAO` | ✅ Sim |
| 8 | `Dim_Perfil_Demografico` | `SK_PERFIL_DEMOGRAFICO` | **Única** (`Dim -> Fato`) | `1 : *` | `Fato_Perfil_Eleitorado` | `SK_PERFIL_DEMOGRAFICO` | ✅ Sim |

### 2.4. Higiene do Modelo: Colunas para Ocultar e Colunas Calculadas na `Dim_Local_Votacao`
1. **Ocultar na Exibição de Relatório (clique no ícone de "olho cortado" 👁️‍🗨️):**
   - Oculte **todas** as colunas `SK_*` e `NK_*` em todas as Fatos e Dimensões.
   - Nas 3 Tabelas Fato (`Fato_Votacao`, `Fato_Comparecimento_Abstencao`, `Fato_Perfil_Eleitorado`), oculte também as colunas de métricas brutas (`QT_VOTOS`, `QT_APTOS`, `QT_COMPARECIMENTO`, `QT_ABSTENCAO`, `QT_ELEITORES_PERFIL`) após criar as medidas na tabela `_Medidas_KPIs`. Assim os membros do grupo só verão a pasta limpa de medidas!
2. **Criar 2 Colunas Calculadas na `Dim_Local_Votacao` (para o Mapa de SP e Gráficos Regionais):**
   Clique na tabela `Dim_Local_Votacao` → **Nova Coluna** e adicione:

```dax
Localizacao_Mapa = 
Dim_Local_Votacao[NM_MUNICIPIO] & ", São Paulo, Brasil"
```
*(Importante: Selecione a coluna `Localizacao_Mapa`, vá em **Ferramentas de Coluna** → **Categoria de Dados** → escolha **Local** ou **Cidade**. Selecione `SG_UF` → Categoria de Dados: **Estado ou Província**).*

```dax
// As colunas FL_GRANDE_ABC e FL_RMSP são do tipo BIT no SQL Server (importadas como True/False no Power BI)
Regiao_Estrategica = 
SWITCH(
    TRUE(),
    Dim_Local_Votacao[FL_GRANDE_ABC] = TRUE(), "Grande ABC",
    Dim_Local_Votacao[FL_RMSP] = TRUE(), "RMSP (Exceto ABC)",
    "Interior e Litoral"
)
```

3. **Criar Hierarquia Geográfica na `Dim_Local_Votacao`:**
   Clique com o botão direito em `Regiao_Estrategica` → **Criar Hierarquia** (renomeie para `Hierarquia Geográfica SP`) e adicione em ordem:
   `Regiao_Estrategica` ➔ `NM_MUNICIPIO` ➔ `NR_ZONA` ➔ `NM_LOCAL_VOTACAO`.

---

## 🧮 SEÇÃO 3: Pacote Completo de Medidas DAX (Prontas para Copiar e Colar)

Crie uma tabela vazia pelo menu **Página Inicial** → **Inserir Dados** → Nomeie como `_Medidas_KPIs` → **Carregar**. Depois crie as medidas abaixo (e exclua a `Coluna1` vazia):

### 📁 Pasta 00. Medidas Base (Volumes e Denominadores)

```dax
// 1. Total de Votos Depositados na Urna (Inclui Válidos, Brancos 95 e Nulos 96)
Votos Depositados Urna = 
SUM(Fato_Votacao[QT_VOTOS])
```

```dax
// 2. Total de Votos Válidos do Cargo (Ignora filtro de candidato/partido para servir de denominador seguro)
Votos Validos Cargo = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"})
)
```

```dax
// 3. Votos Válidos Respeitando Filtro de Partido/Candidato da Tela
Votos Validos Filtrados = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"})
)
```

```dax
// 4. Votos Válidos em 2018 (1º Turno)
Votos Validos 2018 = 
CALCULATE(
    [Votos Validos Cargo],
    Dim_Eleicao[NR_ANO] = 2018
)
```

```dax
// 5. Votos Válidos em 2022 (1º Turno)
Votos Validos 2022 = 
CALCULATE(
    [Votos Validos Cargo],
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// 6. Votos Nominais da Cliente: Deputada Estadual Ana Carolina Serra (23023) em 2022
Votos Ana Carolina 2022 = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[NR_CANDIDATO] = "23023",
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// 7. Votos da Baseline Histórica PSDB em 2018 (Nominais + Legenda 45 = 2.038.674 em SP)
Votos PSDB 2018 = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[SG_PARTIDO] = "PSDB",
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}),
    Dim_Eleicao[NR_ANO] = 2018
)
```

```dax
// 8. Votos Totais da Federação PSDB/Cidadania em 2022 (Nominais + Legenda 23 e 45 = 2.552.319 em SP)
Votos Federacao 2022 = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[SG_FEDERACAO] = "PSDB/CIDADANIA",
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}),
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// 9. Votos Estritos Apenas do PSDB em 2022 (Nominais 45 + Legenda 45 = 1.997.660 em SP)
Votos PSDB Estrito 2022 = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[SG_PARTIDO] = "PSDB",
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}),
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// 10. Eleitores Aptos, Comparecimento e Abstenção (2022)
Eleitores Aptos 2022 = SUM(Fato_Comparecimento_Abstencao[QT_APTOS])
Eleitores Comparecimento 2022 = SUM(Fato_Comparecimento_Abstencao[QT_COMPARECIMENTO])
Eleitores Abstencao 2022 = SUM(Fato_Comparecimento_Abstencao[QT_ABSTENCAO])
```

---

### 📁 Pasta 01. Os 10 KPIs Oficiais da Matriz TSE

#### 🔹 KPI 1 — Variação Histórica do Market Share Partidário (`VHMS` em p.p.)
$$\Delta MS_{\text{Partidário (p.p.)}} = MS_{\text{Federação, 2022}} - MS_{\text{PSDB, 2018}}$$

```dax
MS PSDB 2018 (%) = 
DIVIDE([Votos PSDB 2018], [Votos Validos 2018], 0) * 100
```

```dax
MS Federacao 2022 (%) = 
DIVIDE([Votos Federacao 2022], [Votos Validos 2022], 0) * 100
```

```dax
MS PSDB Estrito 2022 (%) = 
DIVIDE([Votos PSDB Estrito 2022], [Votos Validos 2022], 0) * 100
```

```dax
// KPI 1 OFICIAL (Matriz TSE: Federação PSDB/Cidadania 2022 vs PSDB 2018) -> +1,24 p.p. em SP | +14,44 p.p. no ABC
KPI 01 - VHMS (p.p.) = 
VAR vValidos18 = [Votos Validos 2018]
VAR vValidos22 = [Votos Validos 2022]
RETURN
IF(
    vValidos18 > 0 && vValidos22 > 0,
    [MS Federacao 2022 (%)] - [MS PSDB 2018 (%)],
    BLANK()
)
```

```dax
// KPI 1 VARIANTE ESTRITA (Apenas PSDB 2022 vs PSDB 2018) -> -1,14 p.p. em SP
KPI 01b - VHMS PSDB Estrito (p.p.) = 
VAR vValidos18 = [Votos Validos 2018]
VAR vValidos22 = [Votos Validos 2022]
RETURN
IF(
    vValidos18 > 0 && vValidos22 > 0,
    [MS PSDB Estrito 2022 (%)] - [MS PSDB 2018 (%)],
    BLANK()
)
```

---

#### 🔹 KPI 2 — Taxa de Dominância por Local (`TDL%`) e Contagem de Redutos (> 25%)
$$TDL(\%) = \left(\frac{\text{Votos Nominais da Ana Carolina Serra no Local}}{\text{Votos Válidos para Deputado Estadual no Local em 2022}}\right) \times 100$$

```dax
// KPI 2 - Taxa de Dominância da Ana Carolina Serra (23023)
KPI 02 - TDL Ana Carolina (%) = 
DIVIDE([Votos Ana Carolina 2022], [Votos Validos 2022], 0) * 100
```

```dax
// Quantidade de Colégios Eleitorais com Dominância > 25% (Gabarito: 150 colégios em SP, todos em Santo André)
KPI 02 - Qtd Colegios Dominancia > 25% = 
COALESCE(
    COUNTROWS(
        FILTER(
            VALUES(Dim_Local_Votacao[SK_LOCAL_VOTACAO]),
            Dim_Local_Votacao[SK_LOCAL_VOTACAO] > 0 &&
            [KPI 02 - TDL Ana Carolina (%)] > 25
        )
    ),
    0
)
```

---

#### 🔹 KPI 3 — Margem de Disputa da Zona (`MDZ p.p.` — Swing Zones)
$$MDZ_{(p.p.)} = \left(\frac{\text{Votos da Ana Carolina na Zona} - \text{Votos do 1º Colocado Geral na Zona}}{\text{Total de Votos Válidos do Cargo na Zona}}\right) \times 100$$

```dax
// Votos do 1º Colocado Nominal Geral no contexto atual (Zona/Município)
Votos 1o Colocado Nominal 2022 = 
MAXX(
    FILTER(
        ALL(Dim_Candidato_Partido),
        NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}) &&
        NOT(LEFT(Dim_Candidato_Partido[NM_URNA_CANDIDATO], 15) = "VOTO DE LEGENDA")
    ),
    CALCULATE(
        SUM(Fato_Votacao[QT_VOTOS]),
        Dim_Eleicao[NR_ANO] = 2022
    )
)
```

```dax
// Votos do Maior Adversário Nominal (2º colocado quando Ana Carolina é 1ª; 1º colocado nas demais zonas)
Votos Principal Adversario Nominal 2022 = 
MAXX(
    FILTER(
        ALL(Dim_Candidato_Partido),
        NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}) &&
        Dim_Candidato_Partido[NR_CANDIDATO] <> "23023" &&
        NOT(LEFT(Dim_Candidato_Partido[NM_URNA_CANDIDATO], 15) = "VOTO DE LEGENDA")
    ),
    CALCULATE(
        SUM(Fato_Votacao[QT_VOTOS]),
        Dim_Eleicao[NR_ANO] = 2022
    )
)
```

```dax
// Nome do 1º Colocado Nominal na Zona/Município
Nome 1o Colocado Zona 2022 = 
VAR vTabela = 
    ADDCOLUMNS(
        FILTER(
            ALL(Dim_Candidato_Partido),
            NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}) &&
            NOT(LEFT(Dim_Candidato_Partido[NM_URNA_CANDIDATO], 15) = "VOTO DE LEGENDA")
        ),
        "@Votos", CALCULATE(SUM(Fato_Votacao[QT_VOTOS]), Dim_Eleicao[NR_ANO] = 2022)
    )
VAR vTop1 = TOPN(1, vTabela, [@Votos], DESC)
RETURN
MAXX(vTop1, Dim_Candidato_Partido[NM_URNA_CANDIDATO] & " (" & Dim_Candidato_Partido[SG_PARTIDO] & ")")
```

```dax
// KPI 3 OFICIAL (Matriz TSE): Margem de Disputa na Zona contra o 1º Colocado Geral (em p.p.)
KPI 03 - MDZ vs Lider (p.p.) = 
DIVIDE(
    [Votos Ana Carolina 2022] - [Votos 1o Colocado Nominal 2022],
    [Votos Validos 2022],
    0
) * 100
```

```dax
// KPI 3b COMPETITIVO: Positivo quando Ana lidera sobre o 2º colocado (+29,38 a +38,89 p.p. em Sto André); Negativo quando está atrás do líder
KPI 03b - MDZ Competitivo (p.p.) = 
DIVIDE(
    [Votos Ana Carolina 2022] - [Votos Principal Adversario Nominal 2022],
    [Votos Validos 2022],
    0
) * 100
```

---

#### 🔹 KPI 4 — Razão de Migração por Legenda Rival (`RML%`)
$$RML(\%) = \left(\frac{\text{Votos em Legenda do Partido no Local}}{\text{Votos Totais (Nominais + Legenda) do Partido no Local}}\right) \times 100$$

```dax
Votos de Legenda = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    LEFT(Dim_Candidato_Partido[NM_URNA_CANDIDATO], 15) = "VOTO DE LEGENDA"
)
```

```dax
Votos Nominais = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    NOT(Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96", "-1"}),
    NOT(LEFT(Dim_Candidato_Partido[NM_URNA_CANDIDATO], 15) = "VOTO DE LEGENDA")
)
```

```dax
// KPI 4 - Razão de Migração por Legenda (%) - Funciona por Partido, Ano ou Local!
KPI 04 - RML Legenda (%) = 
DIVIDE([Votos de Legenda], [Votos Validos Filtrados], 0) * 100
```

```dax
// Saldo de Crescimento de Votos Nominais (2022 vs 2018) -> +2.674.534 em SP
KPI 04 - Saldo Votos Nominais (22 vs 18) = 
CALCULATE([Votos Nominais], Dim_Eleicao[NR_ANO] = 2022) - 
CALCULATE([Votos Nominais], Dim_Eleicao[NR_ANO] = 2018)
```

```dax
// Saldo de Retração de Votos de Legenda (2022 vs 2018) -> -369.647 em SP
KPI 04 - Saldo Votos Legenda (22 vs 18) = 
CALCULATE([Votos de Legenda], Dim_Eleicao[NR_ANO] = 2022) - 
CALCULATE([Votos de Legenda], Dim_Eleicao[NR_ANO] = 2018)
```

---

#### 🔹 KPI 5 — Densidade de Eleitores no Local Vulnerável (`DELV`) & Índice de Vulnerabilidade do Município (`IVM`)
$$\text{IVM}_{\text{Município}} = \text{Verdadeiro se } MS_{\text{PSDB, 2018}} \ge 15\% \text{ e } \Delta MS_{\text{Município}} \le -5\text{ p.p.}$$

```dax
// Flag de Município Vulnerável (IVM = 1 se MS_2018 >= 15% e VHMS <= -5 p.p. avaliados no grão do Município)
KPI 05 - Flag Municipio Vulneravel (IVM) = 
VAR vMS2018_Mun = 
    CALCULATE(
        ROUND([MS PSDB 2018 (%)], 2),
        ALLEXCEPT(Dim_Local_Votacao, Dim_Local_Votacao[CD_MUNICIPIO])
    )
VAR vVHMS_Mun = 
    CALCULATE(
        ROUND([KPI 01 - VHMS (p.p.)], 2),
        ALLEXCEPT(Dim_Local_Votacao, Dim_Local_Votacao[CD_MUNICIPIO])
    )
RETURN
IF(vMS2018_Mun >= 15 && vVHMS_Mun <= -5, 1, 0)
```

```dax
// Quantidade de Municípios Vulneráveis (Gabarito: 98 municípios em SP -> 94 Interior + 4 RMSP)
KPI 05 - Qtd Municipios Vulneraveis (IVM) = 
COALESCE(
    COUNTROWS(
        FILTER(
            VALUES(Dim_Local_Votacao[CD_MUNICIPIO]),
            Dim_Local_Votacao[CD_MUNICIPIO] > 0 &&
            CALCULATE(
                ROUND([MS PSDB 2018 (%)], 2) >= 15 &&
                ROUND([KPI 01 - VHMS (p.p.)], 2) <= -5,
                ALLEXCEPT(Dim_Local_Votacao, Dim_Local_Votacao[CD_MUNICIPIO])
            )
        )
    ),
    0
)
```

```dax
// KPI 5 - DELV: Total de Eleitores Aptos nos Municípios Vulneráveis (Gabarito: 2.252.312 eleitores; funciona por Região, Município ou Local!)
KPI 05 - DELV Eleitores Vulneraveis = 
COALESCE(
    SUMX(
        FILTER(
            VALUES(Dim_Local_Votacao[CD_MUNICIPIO]),
            Dim_Local_Votacao[CD_MUNICIPIO] > 0 &&
            CALCULATE(
                ROUND([MS PSDB 2018 (%)], 2) >= 15 &&
                ROUND([KPI 01 - VHMS (p.p.)], 2) <= -5,
                ALLEXCEPT(Dim_Local_Votacao, Dim_Local_Votacao[CD_MUNICIPIO])
            )
        ),
        [Eleitores Aptos 2022]
    ),
    0
)
```

---

#### 🔹 KPI 6 — Taxa de Abstenção na Base Fiel (`TABF%` — Colégios com `TDL >= 20%`)
$$TABF(\%) = \left(\frac{\text{QT\_ABSTENCOES no Local}}{\text{QT\_APTOS no Local}}\right) \times 100 \quad \text{para locais com } TDL \ge 20\%$$

```dax
// Taxa de Abstenção Geral (Gabarito SP: 21,63%)
Taxa Abstencao Geral (%) = 
DIVIDE([Eleitores Abstencao 2022], [Eleitores Aptos 2022], 0) * 100
```

```dax
// KPI 6 - Taxa de Abstenção na Base Fiel (Locais com TDL >= 20% -> 152 colégios, TABF = 20,81%)
KPI 06 - TABF Abstencao Base Fiel (%) = 
VAR vLocaisFieis = 
    FILTER(
        VALUES(Dim_Local_Votacao[SK_LOCAL_VOTACAO]),
        Dim_Local_Votacao[SK_LOCAL_VOTACAO] > 0 &&
        [KPI 02 - TDL Ana Carolina (%)] >= 20
    )
VAR vAbstencaoFiel = CALCULATE([Eleitores Abstencao 2022], vLocaisFieis)
VAR vAptosFiel = CALCULATE([Eleitores Aptos 2022], vLocaisFieis)
RETURN
DIVIDE(vAbstencaoFiel, vAptosFiel, 0) * 100
```

---

#### 🔹 KPI 7 — Índice de Dependência da Federação (`IDF%`)
$$IDF(\%) = \left(\frac{\text{Votos Nominais da Candidata Ana Carolina no Município}}{\text{Votos Totais (Nominais + Legenda) da Federação PSDB/Cidadania no Município}}\right) \times 100$$

```dax
// KPI 7 - Índice de Dependência da Federação (Gabarito: Santo André = 93,23% | Grande ABC = 49,63% | SP = 7,79%)
KPI 07 - IDF Dependencia Federacao (%) = 
DIVIDE([Votos Ana Carolina 2022], [Votos Federacao 2022], 0) * 100
```

---

#### 🔹 KPI 8 — Perfil Demográfico Dominante do Local (`PDL` — 1º Quartil de Pior Desempenho)
$$\text{Moda de Faixa Etária e Escolaridade nos locais onde } TDL \le 1º \text{ Quartil}$$

```dax
// Total de Eleitores Mapeados no Perfil Demográfico
Eleitores Perfil 2022 = 
CALCULATE(
    SUM(Fato_Perfil_Eleitorado[QT_ELEITORES_PERFIL]),
    Dim_Perfil_Demografico[SK_PERFIL_DEMOGRAFICO] > 1
)
```

```dax
// KPI 8 - Combinação Modal (Faixa Etária + Escolaridade) do Contexto Atual
KPI 08 - PDL Perfil Modal Dominante = 
VAR vCombinacoes = 
    SUMMARIZE(
        FILTER(Dim_Perfil_Demografico, Dim_Perfil_Demografico[SK_PERFIL_DEMOGRAFICO] > 1),
        Dim_Perfil_Demografico[DS_FAIXA_ETARIA],
        Dim_Perfil_Demografico[DS_ESCOLARIDADE],
        "@QtdEleitores", SUM(Fato_Perfil_Eleitorado[QT_ELEITORES_PERFIL])
    )
VAR vTop1 = TOPN(1, vCombinacoes, [@QtdEleitores], DESC)
RETURN
MAXX(
    vTop1,
    Dim_Perfil_Demografico[DS_FAIXA_ETARIA] & " | " & Dim_Perfil_Demografico[DS_ESCOLARIDADE]
)
```

---

#### 🔹 KPI 9 — Variação de Votos Alienados no Reduto (`ΔIAR p.p.`)
$$\Delta IAR_{(p.p.)} = IAR_{2022,\text{Local}} - IAR_{2018,\text{Local}}, \quad \text{onde } IAR = \left(\frac{\text{Brancos [95]} + \text{Nulos [96]}}{\text{Votos Totais do Cargo no Local}}\right) \times 100$$

```dax
Votos Alienados (Brancos e Nulos) = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[NK_CANDIDATO] IN {"95", "96"}
)
```

```dax
Votos Totais Cargo Urna = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido)
)
```

```dax
IAR 2018 (%) = 
CALCULATE(
    DIVIDE([Votos Alienados (Brancos e Nulos)], [Votos Totais Cargo Urna], 0) * 100,
    Dim_Eleicao[NR_ANO] = 2018
)
```

```dax
IAR 2022 (%) = 
CALCULATE(
    DIVIDE([Votos Alienados (Brancos e Nulos)], [Votos Totais Cargo Urna], 0) * 100,
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// KPI 9 - Variação de Votos Alienados (Gabarito SP: -4,83 p.p. [de 18,98% em 2018 para 14,15% em 2022])
KPI 09 - Delta IAR (p.p.) = 
VAR vTot18 = CALCULATE([Votos Totais Cargo Urna], Dim_Eleicao[NR_ANO] = 2018)
VAR vTot22 = CALCULATE([Votos Totais Cargo Urna], Dim_Eleicao[NR_ANO] = 2022)
RETURN
IF(vTot18 > 0 && vTot22 > 0, [IAR 2022 (%)] - [IAR 2018 (%)], BLANK())
```

```dax
// Contagem de Locais que Dispararam o Gatilho de Educação Eleitoral (Delta IAR > +3,00 p.p. -> Gabarito: 46 locais)
KPI 09 - Qtd Locais Gatilho > 3 p.p. = 
COALESCE(
    COUNTROWS(
        FILTER(
            VALUES(Dim_Local_Votacao[SK_LOCAL_VOTACAO]),
            Dim_Local_Votacao[SK_LOCAL_VOTACAO] > 0 &&
            [KPI 09 - Delta IAR (p.p.)] > 3
        )
    ),
    0
)
```

---

#### 🔹 KPI 10 — Índice de Canibalização Regional na Federação (`ICF%`)
$$ICF(\%) = \left(\frac{\text{Votos de Outros Candidatos da Federação com Base no Grande ABC/RMSP no Local}}{\text{Votos Totais da Federação PSDB/Cidadania no Local}}\right) \times 100$$

```dax
// Votos de Concorrentes Internos da Federação PSDB/Cidadania com base na RMSP/ABC (Exceto Ana Carolina 23023)
// Nota: FL_CONCORRENTE_REGIONAL é do tipo BIT no SQL Server (True/False no Power BI)
Votos Outros Federacao Regional 2022 = 
CALCULATE(
    SUM(Fato_Votacao[QT_VOTOS]),
    REMOVEFILTERS(Dim_Candidato_Partido),
    Dim_Candidato_Partido[SG_FEDERACAO] = "PSDB/CIDADANIA",
    Dim_Candidato_Partido[NR_CANDIDATO] <> "23023",
    Dim_Candidato_Partido[FL_CONCORRENTE_REGIONAL] = TRUE(),
    Dim_Eleicao[NR_ANO] = 2022
)
```

```dax
// KPI 10 - Índice de Canibalização Regional na Federação (Gabarito: Santo André = 4,02% | Grande ABC = 45,13% | RMSP = 54,88% | SP = 24,14%)
KPI 10 - ICF Canibalizacao Regional (%) = 
DIVIDE([Votos Outros Federacao Regional 2022], [Votos Federacao 2022], 0) * 100
```

---

## ✅ SEÇÃO 4: Gabarito Oficial de Batimento (SQL vs. Power BI)

Use esta tabela para validar se cada Card, Gráfico de Pizza/Rosca e Mapa do Power BI está batendo **100% na vírgula** com o banco `InnovationLab_AppliedBI`:

### 4.1. Resumo Geral de Volumetria do Banco (`InnovationLab_AppliedBI`)

| Métrica de Controle | Pleito 2018 (`20181007`) | Pleito 2022 (`20221002`) | Variação / Observação |
|:---|---:|---:|:---|
| **Total de Votos Depositados na Urna (`QT_VOTOS`)** | `25.921.320` | `27.147.847` | Total na `Fato_Votacao`: `53.069.167` votos (`15.833.824` linhas) |
| **Total de Votos Válidos do Cargo (Nominais + Legenda)** | `21.000.593` | `23.305.480` | `+2.304.887` votos válidos (`+10,98%`) |
| **Votos Nominais Totais em SP** | `18.779.487` (`89,42%`) | `21.454.021` (`92,06%`) | Saldo Nominal: **`+2.674.534` votos** |
| **Votos de Legenda Totais em SP** | `2.221.106` (`10,58%`) | `1.851.459` (`7,94%`) | Saldo Legenda: **`-369.647` votos** |
| **Votos Alienados (Brancos `95` + Nulos `96`)** | `4.920.727` (`18,98%`) | `3.842.367` (`14,15%`) | Brancos 22: `2.244.465` \| Nulos 22: `1.597.902` (`-4,83 p.p.`) |
| **Eleitores Aptos / Comparecimento / Abstenção (2022)** | — | `34.639.761` aptos | Comparecimento: `27.147.847` (`78,37%`) \| Abstenção: `7.491.914` (`21,63%`) |
| **Votos Baseline PSDB (2018) vs Federação PSDB/Cidadania (2022)** | `2.038.674` (`9,71%`) | `2.552.319` (`10,95%`) | Em 2022: `1.997.660` PSDB (`8,57%`) + `554.659` Cidadania (`2,38%`) |
| **Votos da Deputada Ana Carolina Serra (`23023`) em 2022** | *(Não disputou)* | **`198.698` votos** | Votada em `372` municípios e `5.071` dos `11.164` colégios eleitorais |

---

### 4.2. Gabarito Detalhado dos 10 KPIs (Estado de SP, Grande ABC e Santo André)

| Nº | KPI | Recorte Estado de SP (645 mun.) | Recorte Grande ABC (7 mun.) | Recorte Santo André (Reduto Principal) | Detalhamento para Gráficos de Rosca / Barras |
|:--:|:---|:---|:---|:---|:---|
| **1** | **VHMS** *(Variação Histórica de Market Share)* | **`+1,24 p.p.`** *(Fed 22 `10,95%` vs PSDB 18 `9,71%`)*<br>*(Estrito PSDB: **`-1,14 p.p.`**)* | **`+14,44 p.p.`** *(Fed 22 `23,65%` vs PSDB 18 `9,21%`)*<br>*(Estrito PSDB: `+1,26 p.p.`)* | **`+32,54 p.p.`** na View (`40,70%` vs `8,15%` PSDB total 18; ou **`+34,25 p.p.`** vs `6,45%` nominal 18) | **Rosca dos 645 Municípios (Fed 22 vs PSDB 18):**<br>🟢 Crescimento (`> +0,5 p.p.`): **`347`** (`53,8%`)<br>⚪ Estável (`-0,5 a +0,5 p.p.`): **`37`** (`5,7%`)<br>🟠 Queda Moderada (`-0,5 a -5 p.p.`): **`132`** (`20,5%`)<br>🔴 Críticos (`<= -5 p.p.`): **`129`** (`20,0%`) |
| **2** | **TDL%** *(Taxa de Dominância por Local)* | **`0,85%`** geral em SP<br>**`150` colégios com `TDL > 25%`** | **`11,74%`** no Grande ABC (`174.842 / 1.489.819`) | **`37,94%`** em Santo André (`154.080 / 406.092`)<br>**`150` de `157` colégios com `TDL > 25%`** | **Top 3 Colégios de Maior Dominância (Santo André):**<br>1. Creche João de Deus (Z.383): **`47,19%`** (`587` votos)<br>2. E.E. 16 de Julho (Z.383): **`47,06%`** (`1.731` votos)<br>3. Creche Henfil (Z.383): **`47,04%`** (`715` votos) |
| **3** | **MDZ (p.p.)** *(Margem de Disputa por Zona / Swing Zones)* | **Líder (1º lugar) em `6` zonas** (todas de Santo André; `MDZ_OFICIAL = 0,00 p.p.`) | **Swing Zones ABC:**<br>• Z.382 Ribeirão Pires: **`-5,08 p.p.`** vs Carla Morando<br>• Z.183 Ribeirão Pires: **`-6,04 p.p.`** vs Thiago Auricchio<br>• Z.382 Rio Grande da Serra: **`-6,59 p.p.`** | **Vantagem sobre o 2º colocado nominal (`MDZ_COMPETITIVO_PP`):**<br>• Z.383 (`42,27%`): **`+38,89 p.p.`**<br>• Z.307 (`40,88%`): **`+37,30 p.p.`**<br>• Z.263 (`37,95%`): **`+33,82 p.p.`**<br>• Z.156 (`36,46%`): **`+32,16 p.p.`**<br>• Z.264 (`35,56%`): **`+30,40 p.p.`**<br>• Z.306 (`33,61%`): **`+29,38 p.p.`** | **Swing Zones Prioritárias no Interior (Menor Diferença para o 1º Colocado):**<br>• Z.034 Valinhos: **`-3,93 p.p.`** (`188` votos)<br>• Z.360 Cosmópolis: **`-4,49 p.p.`**<br>• Z.274 Campinas: **`-5,22 p.p.`**<br>• Z.275 Campinas: **`-5,27 p.p.`** |
| **4** | **RML%** *(Razão de Migração por Legenda Rival)* | **2018:** `89,42%` Nominal / `10,58%` Legenda<br>**2022:** `92,06%` Nominal / `7,94%` Legenda | **2022 ABC:** `91,09%` Nominal / `8,91%` Legenda | **2022 Santo André:** `92,89%` Nominal / `7,11%` Legenda | **RML% por Partido em 2022 (SP):**<br>• PT: **`12,85%`** (`478.268` leg / `3.720.558` tot)<br>• PL: **`9,99%`** (`345.987` leg / `3.462.660` tot)<br>• MDB: **`9,75%`** \| • PSDB: **`6,51%`** \| • Cidadania: **`2,76%`** |
| **5** | **DELV & IVM** *(Eleitores Aptos em Municípios Vulneráveis)* | **`98` municípios vulneráveis**<br>DELV Total = **`2.252.312` eleitores aptos** | **`0` municípios vulneráveis no ABC** *(pois o ABC cresceu `+14,44 p.p.`)* | **`0` vulneráveis** *(Santo André cresceu `+32,54 p.p.`)* | **Distribuição Regional do DELV (`2.252.312` aptos):**<br>• Interior/Litoral (`94` mun.): **`1.819.554` aptos (`80,79%`)**<br>• RMSP Exceto ABC (`4` mun.: Taboão da Serra `223.611`, Santana de Parnaíba `100.387`, Cajamar `67.967`, Vargem Grande Paulista `40.793`): **`432.758` aptos (`19,21%`)** |
| **6** | **TABF%** *(Taxa de Abstenção na Base Fiel `TDL >= 20%`)* | Abstenção Geral SP: **`21,63%`**<br>**TABF (`152` colégios fiéis): `20,81%`** (`118.891 / 571.218`) | Abstenção Geral ABC: **`19,85%`**<br>**TABF (`152` colégios): `20,81%`** | Abstenção Geral Sto André: **`20,87%`**<br>**TABF (`152` colégios): `20,81%`** | **Polos Fiéis (`TDL >= 20%`) com Maior Abstenção (Santo André):**<br>1. Conj. Educ. Dr. Theobaldo de Nigris SESI (Z.264): **`31,20%`** (`795` ausentes)<br>2. EMEIEF Prof. Nicolau Moraes Barros (Z.307): **`30,92%`** (`1.437` ausentes)<br>3. EMEIF. Odylo Costa Filho (Z.306): **`29,10%`** (`946` ausentes) |
| **7** | **IDF%** *(Índice de Dependência da Federação)* | **`7,79%`** da Federação no Estado (`198.698 / 2.552.319`) | **`49,63%`** da Federação no Grande ABC (`174.842 / 352.284`) | **`93,23%`** da Federação em Santo André (`154.080 / 165.261`) | **IDF% nos 7 Municípios do Grande ABC:**<br>1. Santo André: **`93,23%`** \| 2. Mauá: **`51,58%`**<br>3. Rio Grande da Serra: **`31,57%`** \| 4. São Caetano: **`30,52%`**<br>5. Ribeirão Pires: **`24,99%`** \| 6. Diadema: **`6,36%`** \| 7. SBC: **`5,93%`** |
| **8** | **PDL** *(Perfil Demográfico Dominante no 1º Quartil de TDL)* | **Moda Q1 SP:** `25 A 29 ANOS` + `ENSINO MÉDIO COMPLETO` (**`294.465` eleitores**) | **Moda Q1 Grande ABC:** `25 A 29 ANOS` + `ENSINO MÉDIO COMPLETO` (**`24.081` eleitores**) | **Moda Geral Santo André:** `35 A 39 ANOS` + `ENSINO MÉDIO COMPLETO` (`25.249` eleitores) | **Top 3 Perfis no 1º Quartil de TDL (Pior Desempenho):**<br>1. `25 A 29 ANOS` + `ENSINO MÉDIO COMPLETO` (`294.465`)<br>2. `35 A 39 ANOS` + `ENSINO MÉDIO COMPLETO` (`294.086`)<br>3. `30 A 34 ANOS` + `ENSINO MÉDIO COMPLETO` (`292.642`) |
| **9** | **ΔIAR (p.p.)** *(Variação de Votos Alienados 2022 vs 2018)* | **`-4,83 p.p.`** (`18,98%` em 2018 ➔ `14,15%` em 2022)<br>**`46` locais com gatilho `> +3,00 p.p.`** | **`-7,57 p.p.`** (`21,06%` em 2018 ➔ `13,50%` em 2022)<br>**`0` locais com gatilho `> +3 p.p.`** | **`-7,70 p.p.`** (`19,62%` em 2018 ➔ `11,92%` em 2022) | **Gatilho `ΔIAR > +3,00 p.p.` (`46` colégios no Estado):**<br>• Interior/Litoral: **`38` colégios**<br>• RMSP (Capital/Guarulhos/região): **`8` colégios** |
| **10** | **ICF%** *(Índice de Canibalização Regional na Federação)* | **`24,14%`** no Estado (`616.196 / 2.552.319`) \| **`54,88%`** na RMSP Completa (`517.349 / 942.692`) | **`45,13%`** no Grande ABC (`158.979 / 352.284`) | **`4,02%`** em Santo André (`6.646 / 165.261`) | **Divisão dos `352.284` votos da Federação no Grande ABC:**<br>• Ana Carolina Serra (`23023`): **`49,63%`** (`174.842`)<br>• Concorrentes Regionais da Federação (ex: Carla Morando em SBC): **`45,13%`** (`158.979`)<br>• Votos de Legenda (`23`+`45`) e Outros: **`5,24%`** (`18.463`) |

---

### 4.3. Script SQL de Conferência Rápida (Para Rodar no SSMS e Validar as 5 Views)

```sql
-- =====================================================================
-- SCRIPT DE AUDITORIA RAPIDA DOS 10 KPIS NAS VIEWS DO BANCO
-- =====================================================================
use InnovationLab_AppliedBI;
go

-- KPI 1: Distribuicao dos 645 Municipios no Mapa de SP (Rosca VHMS)
select STATUS_VHMS_MUNICIPIO, count(*) as QTD_MUNICIPIOS
from dbo.vw_KPI_Painel_Municipio_Mapa_SP
group by STATUS_VHMS_MUNICIPIO
order by QTD_MUNICIPIOS desc;

-- KPI 2, 6 e 9: Resumo dos Colegios Eleitorais
select
    sum(FL_DOMINANCIA_25_PCT) as KPI2_COLEGIOS_DOMINANCIA_25,
    sum(FL_BASE_FIEL_20_PCT) as KPI6_COLEGIOS_BASE_FIEL_20,
    cast(round(sum(case when FL_BASE_FIEL_20_PCT = 1 then QT_ABSTENCAO else 0 end) * 100.0 /
         sum(case when FL_BASE_FIEL_20_PCT = 1 then QT_APTOS else 0 end), 2) as decimal(5,2)) as KPI6_TABF_PCT,
    sum(FL_GATILHO_ALIENACAO_3PP) as KPI9_COLEGIOS_GATILHO_3PP
from dbo.vw_KPI_Painel_Local_Votacao;

-- KPI 3: Zonas de Lideranca e Swing Zones
select top 12 NR_ZONA, NM_MUNICIPIO, REGIAO, QT_VOTOS_ANA_CAROLINA, PCT_ANA_CAROLINA,
       PRIMEIRO_COLOCADO, SG_PARTIDO_PRIMEIRO, PCT_PRIMEIRO, MDZ_OFICIAL_VS_LIDER_PP, MDZ_COMPETITIVO_PP, STATUS_SWING_ZONE
from dbo.vw_KPI_Margem_Disputa_Zona
where QT_VOTOS_ANA_CAROLINA >= 500
order by MDZ_COMPETITIVO_PP desc;

-- KPI 5: Municipios Vulneraveis (IVM) e Densidade de Eleitores (DELV) por Regiao
select REGIAO, count(*) as QTD_MUN_VULNERAVEIS, sum(DELV_ELEITORES_VULNERAVEIS) as DELV_TOTAL_APTOS
from dbo.vw_KPI_Painel_Municipio_Mapa_SP
where FL_VULNERAVEL_IVM = 1
group by REGIAO;

-- KPI 7 e KPI 10: Dependencia (IDF%) e Canibalizacao (ICF%) no Grande ABC
select NM_MUNICIPIO, QT_VOTOS_ANA_CAROLINA_2022, QT_VOTOS_FEDERACAO_2022,
       IDF_DEPENDENCIA_FEDERACAO_PCT as KPI7_IDF_PCT, ICF_CANIBALIZACAO_REGIONAL_PCT as KPI10_ICF_PCT
from dbo.vw_KPI_Painel_Municipio_Mapa_SP
where FL_GRANDE_ABC = 1
order by IDF_DEPENDENCIA_FEDERACAO_PCT desc;
```

---

## 🗺️ SEÇÃO 5: Como Criar o Mapa Clicável do Estado de SP + Gráficos de Pizza/Rosca no Power BI

### 5.1. Opção A (Mais Rápida e Nativa): Mapa do Azure / Mapa de Bolhas Clicável de SP
1. Adicione o visual **Mapa do Azure** (ou **Mapa** / **Mapa Coroplético**) no centro do Dashboard.
2. Arraste a coluna `Localizacao_Mapa` (da `Dim_Local_Votacao` ou da view `vw_KPI_Painel_Municipio_Mapa_SP`) para o campo **Localização**.
3. Arraste a medida `[Votos Ana Carolina 2022]` (ou `[Eleitores Aptos 2022]`) para o campo **Tamanho** da bolha.
4. Para colorir os municípios pelo status estratégico (**Crescimento, Estável, Queda, Crítico**):
   - Use a coluna `STATUS_VHMS_MUNICIPIO` da view `vw_KPI_Painel_Municipio_Mapa_SP` no campo **Legenda**, **OU**
   - Em **Formatação da Cor** → clique em **`fx` (Formatação Condicional)** → Baseado no campo `[KPI 01 - VHMS (p.p.)]` com regras:
     - Se `> 0,5` ➔ Verde Neon (`#43A047`)
     - Se `>= -0,5` e `<= 0,5` ➔ Cinza Azulado (`#78909C`)
     - Se `> -5` e `< -0,5` ➔ Laranja Alerta (`#EF6C00`)
     - Se `<= -5` ➔ Vermelho Crítico (`#E53935`)
5. **Dica de Ouro (Tooltips Ricos ao Passar o Mouse no Município):**
   Arraste para o campo **Dicas de Ferramentas (Tooltips)** do Mapa:
   - `[Votos Ana Carolina 2022]`
   - `[KPI 01 - VHMS (p.p.)]`
   - `[KPI 02 - TDL Ana Carolina (%)]`
   - `[KPI 07 - IDF Dependencia Federacao (%)]`
   - `[KPI 10 - ICF Canibalizacao Regional (%)]`
   - `[Taxa Abstencao Geral (%)]`
   Assim, ao passar o mouse ou clicar em **qualquer um dos 645 municípios de SP**, o mapa filtra todos os cartões e gráficos de pizza do painel instantaneamente!

### 5.2. Opção B (Mapa de Polígonos Oficial IBGE): Mapa de Formas (*Shape Map*) com TopoJSON dos 645 Municípios de SP
Se o grupo quiser os polígonos perfeitos das fronteiras dos 645 municípios de São Paulo sem depender de geocodificação da internet:
1. No Power BI Desktop, vá em **Arquivo** → **Opções e Configurações** → **Opções** → **Recursos de Visualização** → marque **Visual do Mapa de Formas (Shape Map)**.
2. Insira o visual **Mapa de Formas**:
   - **Localização:** `CD_MUNICIPIO` (ou `NM_MUNICIPIO`).
   - **Saturação de Cor:** `[KPI 01 - VHMS (p.p.)]` ou `[KPI 02 - TDL Ana Carolina (%)]`.
3. Em **Formatar Visual** → **Configurações do Mapa** → **Tipo de Mapa** → escolha **Mapa Personalizado** e carregue o arquivo JSON/TopoJSON dos municípios de SP (padrão IBGE/TSE).

### 5.3. Configuração Exata dos 5 Gráficos de Pizza / Rosca + 3 Gráficos de Barras

| Visual | Tipo de Gráfico | Campo "Legenda / Eixo" | Campo "Valores" | O que Mostra no Centro da Rosca |
|:---|:---|:---|:---|:---|
| **Rosca 1 (KPI 1 — VHMS)** | Gráfico de Rosca | `vw_KPI_Painel_Municipio_Mapa_SP[STATUS_VHMS_MUNICIPIO]` | `Contagem de CD_MUNICIPIO` | **`645` municípios** (`347` Crescimento, `37` Estável, `132` Queda, `129` Críticos) |
| **Rosca 2 (KPI 7 & 10 — Federação no ABC)** | Gráfico de Rosca | Categorias da Federação (`Ana Carolina 49,6%`, `Concorrentes Regionais 45,1%`, `Legenda/Outros 5,2%`) | `QT_VOTOS` em 2022 | **`352.284` votos** da Federação no Grande ABC |
| **Rosca 3 (KPI 5 — DELV por Região)** | Gráfico de Rosca | `Dim_Local_Votacao[Regiao_Estrategica]` | `[KPI 05 - DELV Eleitores Vulneraveis]` | **`2,25M` eleitores** (`80,8%` Interior \| `19,2%` RMSP) |
| **Rosca 4 (KPI 2 — Votos de Ana Carolina por Região)** | Gráfico de Rosca | `Dim_Local_Votacao[Regiao_Estrategica]` (ou Município) | `[Votos Ana Carolina 2022]` | **`198.698` votos** (`77,5%` Santo André, `10,4%` demais ABC, `8,6%` RMSP, `3,4%` Interior) |
| **Rosca 5 (KPI 3 — Zonas por Status de Disputa)** | Gráfico de Rosca | `vw_KPI_Margem_Disputa_Zona[STATUS_SWING_ZONE]` | `Contagem de NR_ZONA` | **`6` zonas líderes** em Santo André + Swing Zones |
| **Barras 1 (KPI 4 — RML%)** | Barras Empilhadas 100% | Eixo X: `Dim_Eleicao[NR_ANO]` (ou `SG_PARTIDO`) | `[Votos Nominais]` e `[Votos de Legenda]` | Compara `89,4% vs 10,6%` (2018) e `92,1% vs 7,9%` (2022) |
| **Barras 2 (KPI 8 — PDL)** | Barras Horizontais Empilhadas | Eixo Y: `Dim_Perfil_Demografico[DS_FAIXA_ETARIA]` \| Legenda: `DS_ESCOLARIDADE` | `[Eleitores Perfil 2022]` (filtrado para Q1 de TDL) | Destaca a moda **`25 A 29 ANOS` + `ENSINO MÉDIO COMPLETO`** |
| **Barras 3 (KPI 9 — ΔIAR)** | Colunas Agrupadas c/ Linha de Referência | Eixo X: `Dim_Eleicao[NR_ANO]` (`2018` vs `2022`) | `[IAR 2018 (%)]` (`18,98%`) e `[IAR 2022 (%)]` (`14,15%`) | Queda estadual de **`-4,83 p.p.`** e alerta nos **`46` colégios `> +3 p.p.`** |

---

## 🤖 SEÇÃO 6: SUPER PROMPT MESTRE (Copiar e Colar para Qualquer IA)

> **Como usar:** Qualquer integrante do grupo pode copiar o bloco abaixo inteiro e colar no **ChatGPT, Claude, Gemini ou Microsoft Copilot** para tirar dúvidas de DAX, configurar o Mapa Clicável de SP e os gráficos de pizza/rosca no Power BI, ou validar medidas sem que a IA invente números ou erre as regras do TSE.

```markdown
# CONTEXTO OFICIAL DO PROJETO DE BI — START PHOENIX CONSULTORIA (FACULDADE IMPACTA)

Você é um Especialista Sênior em Business Intelligence, Modelagem Dimensional (Kimball Fact Constellation), SQL Server (T-SQL), DAX avançado para Power BI e Visualização de Dados Eleitorais (TSE).

## 1. IDENTIFICAÇÃO DO CLIENTE E OBJETIVO
- **Cliente:** Equipe de Inteligência de Campanha da **Deputada Estadual Ana Carolina Serra** (reeleição em 2026).
- **Dados Oficiais da Candidata no DW (`Dim_Candidato_Partido`):**
  - `SK_CANDIDATO_PARTIDO = 653`
  - `NK_CANDIDATO = '250001611505'`
  - `NR_CANDIDATO = '23023'`
  - `NM_URNA_CANDIDATO = 'ANA CAROLINA SERRA'`
  - `SG_PARTIDO = 'CIDADANIA'`
  - `SG_FEDERACAO = 'PSDB/CIDADANIA'`
  - `FL_CONCORRENTE_REGIONAL = 1`
- **Recorte Eleitoral:** Estado de São Paulo (645 municípios, 11.164 locais de votação), cargo de **Deputado Estadual** (1º Turno de 2018 [`SK_ELEICAO = 20181007`] vs 1º Turno de 2022 [`SK_ELEICAO = 20221002`]).

## 2. ARQUITETURA DO DATA WAREHOUSE (SQL SERVER `InnovationLab_AppliedBI`)
O modelo é um **Fact Constellation Schema** composto por **4 Dimensões e 3 Tabelas Fato** (além de 5 Views OLAP pré-calculadas):
1. `dbo.Dim_Eleicao` (`SK_ELEICAO` PK, `DT_ELEICAO`, `NR_ANO`, `NR_TURNO`, `DS_ELEICAO`) -> Filtrar `SK_ELEICAO IN (20181007, 20221002)`.
2. `dbo.Dim_Local_Votacao` (`SK_LOCAL_VOTACAO` PK, `NK_LOCAL_VOTACAO`, `CD_MUNICIPIO`, `NM_MUNICIPIO`, `NR_ZONA`, `NR_LOCAL_VOTACAO`, `NM_LOCAL_VOTACAO`, `SG_UF`, `FL_GRANDE_ABC`, `FL_RMSP`) -> Filtrar `SK_LOCAL_VOTACAO > 0` (remove apenas a linha `-1`).
3. `dbo.Dim_Candidato_Partido` (`SK_CANDIDATO_PARTIDO` PK, `NK_CANDIDATO`, `NR_CANDIDATO`, `NM_URNA_CANDIDATO`, `DS_CARGO`, `SG_PARTIDO`, `SG_FEDERACAO`, `FL_CONCORRENTE_REGIONAL`).
   - Códigos especiais: `'95'` = VOTO EM BRANCO, `'96'` = VOTO NULO, `'-1'` = NÃO IDENTIFICADO.
   - Votos de legenda têm 2 dígitos em `NR_CANDIDATO` e `NM_URNA_CANDIDATO LIKE 'VOTO DE LEGENDA%'`.
4. `dbo.Dim_Perfil_Demografico` (`SK_PERFIL_DEMOGRAFICO` PK, `NK_PERFIL_DEMOGRAFICO`, `CD_FAIXA_ETARIA`, `DS_FAIXA_ETARIA`, `CD_ESCOLARIDADE`, `DS_ESCOLARIDADE`, `CD_GENERO`, `DS_GENERO`) -> Filtrar `SK_PERFIL_DEMOGRAFICO > 1`.
5. `dbo.Fato_Votacao` (`SK_VOTACAO` PK, `SK_ELEICAO` FK, `SK_LOCAL_VOTACAO` FK, `SK_CANDIDATO_PARTIDO` FK, `NR_SECAO`, `QT_VOTOS`) -> 15.833.824 linhas / 53.069.167 votos.
6. `dbo.Fato_Comparecimento_Abstencao` (`SK_COMPARECIMENTO_ABSTENCAO` PK, `SK_ELEICAO` FK, `SK_LOCAL_VOTACAO` FK, `NR_SECAO`, `QT_APTOS`, `QT_COMPARECIMENTO`, `QT_ABSTENCAO`) -> 101.074 linhas (2022).
7. `dbo.Fato_Perfil_Eleitorado` (`SK_PERFIL_ELEITORADO` PK, `SK_ELEICAO` FK, `SK_LOCAL_VOTACAO` FK, `SK_PERFIL_DEMOGRAFICO` FK, `NR_SECAO`, `QT_ELEITORES_PERFIL`) -> 4.504.469 linhas (2022).
- **Views OLAP disponíveis no banco:** `vw_KPI_Painel_Local_Votacao` (11.164 linhas), `vw_KPI_Painel_Municipio_Mapa_SP` (645 linhas, 1 por município de SP), `vw_KPI_Margem_Disputa_Zona` (780 linhas), `vw_KPI_Canibalizacao_Federacao_Municipio`, `vw_KPI_Perfil_Demografico_Dominante`.

## 3. GABARITO AUDITADO DOS 10 KPIs OFICIAIS (NUNCA INVENTE NÚMEROS FORA DESTE GABARITO)
- **Volumetria Geral SP:**
  - Votos Depositados: 2018 = `25.921.320` | 2022 = `27.147.847`.
  - Votos Válidos (`NK_CANDIDATO NOT IN ('95','96','-1')`): 2018 = `21.000.593` (`18.779.487` nominais + `2.221.106` legenda) | 2022 = `23.305.480` (`21.454.021` nominais + `1.851.459` legenda).
  - Votos Alienados (`95`+`96`): 2018 = `4.920.727` (`18,98%`) | 2022 = `3.842.367` (`14,15%`).
  - Votos Ana Carolina Serra (`23023`) em 2022: **`198.698` votos** em 372 municípios e 5.071 locais (`154.080` em Santo André; `174.842` no Grande ABC; `17.159` no restante da RMSP; `6.697` no Interior/Litoral).
- **KPI 1 (VHMS - Variação Histórica de Market Share em p.p.):**
  - Fórmula Oficial: `MS_Federação_PSDB_Cidadania_2022 - MS_PSDB_2018`.
  - Estado de SP: `10,95% (2.552.319) - 9,71% (2.038.674) = +1,24 p.p.` (Variante estrita apenas PSDB 2022 vs PSDB 2018: `8,57% - 9,71% = -1,14 p.p.`).
  - Grande ABC: `23,65% - 9,21% = +14,44 p.p.` | Santo André: `+32,54 p.p.` (`40,70%` vs `8,15%` PSDB total 2018; ou `+34,25 p.p.` sobre base nominal `6,45%`).
  - Rosca dos 645 Municípios: Crescimento (`> +0,5 p.p.`): `347` (`53,8%`) | Estável (`-0,5 a +0,5 p.p.`): `37` (`5,7%`) | Queda Moderada (`-0,5 a -5 p.p.`): `132` (`20,5%`) | Críticos (`<= -5 p.p.`): `129` (`20,0%`).
- **KPI 2 (TDL% - Taxa de Dominância por Local):**
  - `(Votos Nominais 23023 no Local / Votos Válidos 2022 no Local) * 100`.
  - Estado SP: `0,85%` | Grande ABC: `11,74%` | Santo André: `37,94%`.
  - Total de colégios com `TDL > 25%`: **`150` colégios** (todos em Santo André, dentre os `157` locais do município; Top 3 na Zona 383: Creche João de Deus `47,19%` [`587` votos], E.E. 16 de Julho `47,06%` [`1.731` votos], Creche Henfil `47,04%` [`715` votos]).
- **KPI 3 (MDZ p.p. - Margem de Disputa da Zona / Swing Zones):**
  - `((Votos Ana Carolina na Zona - Votos 1º Colocado na Zona) / Votos Válidos na Zona) * 100`.
  - Ana Carolina Serra é **1ª colocada absoluta em todas as 6 Zonas de Santo André** (Z.156, Z.263, Z.264, Z.306, Z.307, Z.383), com vantagem competitiva de `+29,38 p.p.` a `+38,89 p.p.` sobre o 2º colocado.
  - Swing Zones no ABC: Z.382 Ribeirão Pires (`-5,08 p.p.` vs Carla Morando), Z.183 Ribeirão Pires (`-6,04 p.p.` vs Thiago Auricchio) e Z.382 Rio Grande da Serra (`-6,59 p.p.`).
  - Swing Zones no Interior: Z.034 Valinhos (`-3,93 p.p.`), Z.360 Cosmópolis (`-4,49 p.p.`), Z.274 Campinas (`-5,22 p.p.`).
- **KPI 4 (RML% - Razão de Migração por Legenda Rival):**
  - `(Votos de Legenda / Votos Válidos Totais) * 100`.
  - Geral SP: 2018 (`89,42%` nominal vs `10,58%` legenda) -> 2022 (`92,06%` nominal vs `7,94%` legenda).
  - Por partido em 2022: PT `12,85%`, PL `9,99%`, MDB `9,75%`, PSDB `6,51%`, Republicanos `4,06%`, PSOL `3,76%`, União `2,87%`, Cidadania `2,76%`.
- **KPI 5 (DELV & IVM - Densidade de Eleitores em Locais Vulneráveis):**
  - Município Vulnerável (`IVM = Verdadeiro`) quando `MS_PSDB_2018 >= 15%` e `VHMS <= -5 p.p.`.
  - Total: **`98` municípios vulneráveis** em SP, somando **`2.252.312` eleitores aptos (`DELV`)**, sendo `94` no Interior (`1.819.554` aptos / `80,79%`, maiores: Praia Grande `248.856`, Caraguatatuba `105.088`, Sertãozinho `96.924`) e `4` na RMSP (`432.758` aptos / `19,21%`: Taboão da Serra `223.611`, Santana de Parnaíba `100.387`, Cajamar `67.967`, Vargem Grande Paulista `40.793`).
- **KPI 6 (TABF% - Taxa de Abstenção na Base Fiel `TDL >= 20%`):**
  - Abstenção Geral SP = `21,63%` (`7.491.914 / 34.639.761`).
  - Nos **`152` colégios eleitorais fiéis (`TDL >= 20%`)**, `TABF% = 20,81%` (`118.891` abstenções em `571.218` aptos).
- **KPI 7 (IDF% - Índice de Dependência da Federação):**
  - `(Votos Ana Carolina no Município / Votos Totais da Federação PSDB/Cidadania no Município) * 100`.
  - Santo André: **`93,23%`** (`154.080 / 165.261`) | Mauá: **`51,58%`** | Rio Grande da Serra: **`31,57%`** | São Caetano do Sul: **`30,52%`** | Ribeirão Pires: **`24,99%`** | Diadema: **`6,36%`** | São Bernardo do Campo: **`5,93%`** | Consolidado Grande ABC: **`49,63%`** | Estado SP: **`7,79%`**.
- **KPI 8 (PDL - Perfil Demográfico Dominante no 1º Quartil de TDL):**
  - Combinação modal nos locais do 1º Quartil (pior desempenho proporcional da candidata): **`25 A 29 ANOS` + `ENSINO MÉDIO COMPLETO`** (`294.465` eleitores no Q1 de SP e `24.081` no Q1 do Grande ABC), seguido por `35 A 39 ANOS` + `ENSINO MÉDIO COMPLETO` (`294.086`) e `30 A 34 ANOS` + `ENSINO MÉDIO COMPLETO` (`292.642`).
- **KPI 9 (ΔIAR p.p. - Variação de Votos Alienados 2022 vs 2018):**
  - `IAR_2022 - IAR_2018` sobre o total de votos da urna.
  - Estado SP caiu **`-4,83 p.p.`** (`18,98%` para `14,15%`).
  - Dos `10.357` colégios comparáveis entre 2018 e 2022, **`46` colégios dispararam o gatilho `ΔIAR > +3,00 p.p.`** (`38` no Interior e `8` na RMSP).
- **KPI 10 (ICF% - Índice de Canibalização Regional na Federação):**
  - `(Votos de Outros Candidatos da Federação com FL_CONCORRENTE_REGIONAL = 1 / Votos Totais da Federação PSDB/Cidadania) * 100`.
  - Santo André: **`4,02%`** (`6.646 / 165.261`) | Grande ABC: **`45,13%`** (`158.979 / 352.284`, puxado por Carla Morando em SBC) | RMSP Completa: **`54,88%`** (`517.349 / 942.692`) | Estado SP: **`24,14%`** (`616.196 / 2.552.319`).

## 4. IDENTIDADE VISUAL (DARK MODE NEON)
- Fundo principal: `#07091A` | Fundo dos Cards: `#0C1028` | Borda dos Cards: `#1E2650`
- Cores Semânticas: Ciano Destaque `#00BCD4`, Azul PSDB/Cidadania `#1E88E5`, Verde Crescimento `#43A047`, Amarelo Alerta `#F9A825`, Vermelho Erosão/Crítico `#E53935`, Roxo Federação `#5C6BC0`, Texto `#E8EAF6`, Texto Secundário `#9FA8DA`.

Sempre que eu pedir ajuda com DAX, SQL, Mapa Clicável de SP ou construção de visuais no Power BI, utilize estritamente as tabelas, colunas e números auditados acima.
```
