# 📊 Engenharia de Dados para BI: Análise Eleitoral TSE (Start Phoenix Consultoria)

Este repositório documenta a esteira de Engenharia de Dados desenvolvida para o Projeto Integrador de Business Intelligence (Faculdade Impacta). Atuando como a equipe de inteligência da campanha da deputada estadual Ana Carolina Serra (PSDB-SP), o objetivo é processar bases massivas do Tribunal Superior Eleitoral (TSE) para viabilizar cálculos avançados de KPIs no Power BI.

## 📁 Estrutura de Entrega (Dia 30/09)
Os artefatos técnicos desta fase estão localizados na pasta `/entregas`:
* `01_ETL_DataMart_Fato_Votacao.sql`: Script consolidado do Data Mart (UNION, JOIN, CASE WHEN e Window Functions).
* `Scripts_Staging/`: Códigos de limpeza (CTEs) e padronização.
* `Prints_Execucao/`: Evidências da materialização da tabela Fato no SQL Server.

## ⚙️ Arquitetura e Soluções Técnicas (SQL Server)

A arquitetura foi desenhada no modelo **ETL (Extract, Transform, Load)**, materializando os dados em uma Tabela Fato para garantir alta performance de leitura pelo Power BI e isolar a complexidade do cálculo das métricas de negócio.

### 1. Camada Landing e Tratamento de Encoding
Os arquivos abertos do TSE apresentaram inconsistências de formatação entre pleitos:
* **Conflito de Codepage:** Os dados de 2018 vieram em UTF-8 (`CODEPAGE = '65001'`), enquanto algumas bases de 2022 exigiram Latin-1 (`CODEPAGE = 'ACP'`). O mapeamento rigoroso no `BULK INSERT` evitou a corrupção de milhares de registros e caracteres especiais ("SÃO PAULO" ao invés de "S?O PAULO").
* **Truncamento de Dados:** Utilização de `VARCHAR(MAX)` e `VARCHAR(8000)` nas tabelas brutas para suportar colunas de texto com tamanhos anômalos (como a composição gigantesca de coligações partidárias).

### 2. Camada Staging (Limpeza)
Aplicação de regras de higienização utilizando **CTEs (Common Table Expressions)**:
* Remoção de aspas duplas (qualificadores de texto) soltas nos arquivos com a combinação `UPPER(TRIM(REPLACE()))`.
* Conversão segura de tipos de dados numéricos (`TRY_CAST` para `INT`).
* Tratamento de valores espúrios nativos do TSE, convertendo strings `'#NULO'` para buracos relacionais válidos tratáveis via `COALESCE`.

### 3. Camada Semântica / Data Mart (A Entrega de Valor)
Construção do script final (`Fato_Votacao_Historica`) consolidando 5 exigências técnicas em uma única execução performática:
* **Série Histórica (UNION ALL):** Empilhamento das votações de 2018 e 2022, garantindo o filtro rigoroso (`CD_CARGO = '7'`) na base mais recente para isolar o escopo de Deputado Estadual e permitir cálculos de variação de *Market Share*.
* **Relacionamento Dimensional (LEFT JOIN):** Cruzamento da Fato de Votação com a base de Candidatos (`consulta_cand_2022_SP`) via `NR_CANDIDATO`, enriquecendo o modelo com as colunas oficiais de Partido e Federação, fundamentais para a análise de Canibalização Regional.
* **Feature Engineering (CASE WHEN):** Classificação derivativa dos votos (Branco, Nulo, Legenda e Nominal) a partir do comprimento (`LEN`) e da numeração (`95`/`96`) da coluna `NR_VOTAVEL`.
* **Subqueries Avançadas (Window Functions):** Implementação de `SUM() OVER (PARTITION BY ANO_ELEICAO, CD_MUNICIPIO, NR_ZONA)` para calcular dinamicamente o Total de Votos da Zona Eleitoral por linha, viabilizando o cálculo direto dos KPIs de Dominância Local no BI.