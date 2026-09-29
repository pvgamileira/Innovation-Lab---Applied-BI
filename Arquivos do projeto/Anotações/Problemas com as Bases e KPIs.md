# 1. Resposta Direta às Perguntas Principais
- **É possível responder a todos os KPIs usando essas colunas?** **Não totalmente.** É possível calcular 8 dos 10 KPIs propostos, mas **2 KPIs (KPI 7 e KPI 10) não podem ser calculados com confiabilidade** mantendo apenas os arquivos atuais.
- **As bases usadas são suficientes?** **Não são 100% suficientes.** Faltam metadados essenciais (como a base de cadastro de candidatos `consulta_cand_2022` para regionalização e partidos) e há uma falha crítica de granularidade na base de abstenção.
- **Os dados se conectam?** **Conectam-se parcialmente.** As tabelas se conectam bem no nível geográfico (`CD_MUNICIPIO` + `NR_ZONA` + `NR_SECAO` / `NR_LOCAL_VOTACAO`), mas não possuem chaves diretas para Sigla de Partido ou Federação.
- **Temos informações suficientes para calcular os KPIs de maneira confiável?** **Apenas com ressalvas e ajustes de escopo.** A maioria dos KPIs exigirá regras de ETL customizadas (como extração de _substrings_ em números de candidatos) e 2 KPIs precisarão de revisão.


# 2. Análise Crítica dos Gargalos e Riscos Identificados
### A. Falha Crítica de Granularidade no KPI 7 (Taxa de Abstenção na Base Fiel)
- **O Problema:** O KPI 7 exige calcular a taxa de abstenção por **Local de Votação** (`NM_LOCAL_VOTACAO`). Contudo, a base selecionada `perfil_comparecimento_abstencao_2022_SP` possui granularidade apenas até o nível de **Zona Eleitoral** (`NR_ZONA`). Ela **não contém as colunas `NR_SECAO` nem `NR_LOCAL_VOTACAO`**.
- **Consequência:** A outra base de perfil (`perfil_eleitor_secao_2022_SP`) possui a coluna `NR_LOCAL_VOTACAO` e a contagem de aptos (`QT_ELEITORES_PERFIL`), mas **não traz a contagem de abstenções**.
- **Impacto:** O KPI 7 é **INSUFICIENTE** com os arquivos selecionados.

### B. Ausência de Cadastro de Candidatos para o KPI 10 (Canibalização Regional)
- **O Problema:** O KPI 10 exige identificar o voto em "outros candidatos da Federação com base no Grande ABC e Região Metropolitana (RMSP)".
- **Consequência:** Os arquivos de votação (`votacao_secao_2022_SP`) contêm apenas `NR_VOTAVEL`, `NM_VOTAVEL` e `SQ_CANDIDATO`. Eles **não trazem o município de origem, domicílio eleitoral ou região do candidato**.
- **Impacto:** O KPI 10 é **INSUFICIENTE**. O grupo precisará incluir a base oficial `consulta_cand_2022_SP` ou mapear manualmente (_hardcoded_) os números dos candidatos concorrentes da região.

### C. Ausência das Colunas `SG_PARTIDO` / `NR_PARTIDO` nas Bases de Votação
- **O Problema:** Nenhum dos dois arquivos de votação por seção (`votacao_secao_2018` e `2022`) possui uma coluna explícita indicando a sigla ou o número do partido. Existe apenas a coluna `NR_VOTAVEL`.
- **Condição / Solução Técnica (ETL):** O grupo precisará criar uma regra de negócio na carga de dados baseada em tratamento de texto (`SUBSTRING` / `LEN`):
	- **Votos Nominais:** Quando `LEN(NR_VOTAVEL) = 5` (para Deputado Estadual), os dois primeiros dígitos representam o partido. (Exemplo: `NR_VOTAVEL` iniciando com `45` = PSDB; `23` = Cidadania).
	- **Votos de Legenda:** Quando `LEN(NR_VOTAVEL) = 2` e `NR_VOTAVEL` for `45`, `22`, `55`, etc.
	- **Votos Alienados:** `NR_VOTAVEL = 95` (Branco) e `96` (Nulo).

### D. Instabilidade das Chaves de Locais de Votação entre 2018 e 2022 (KPI 1 e KPI 9)
- **O Problema:** O cruzamento temporal de locais de votação entre 2018 e 2022 depende das chaves `CD_MUNICIPIO` + `NR_ZONA` + `NR_LOCAL_VOTACAO`.
- **Risco de Negócio:** Entre pleitos, locais de votação passam por reestruturação (fechamento de escolas, mudança de endereço ou renumeração). Fazer um `JOIN` estrito entre 2018 e 2022 pode gerar divergências ou perder locais históricos se o número do local tiver mudado na Justiça Eleitoral.

### E. Divergência de Nomenclatura entre Bases
- **Inconsistência:** No arquivo `perfil_eleitor_secao_2022_SP`, a coluna de instrução chama-se `DS_GRAU_ESCOLARIDADE`. No arquivo `perfil_comparecimento_abstencao_2022_SP`, a coluna equivalente chama-se `DS_GRAU_INSTRUCAO`. Essa divergência exige atenção na padronização dos scripts de carga.


# 3. Matriz de Suficiência e Diagnóstico por KPI

| Nº  | KPI                                               | Status de Suficiência    | Limitação / Condição Identificada                                                                                                                                  |
| --- | ------------------------------------------------- | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Variação de Market Share Partidário (VHMS)        | Suficiente com Ressalvas | Exige extração do partido via `SUBSTRING(NR_VOTAVEL,1,2)`. Risco de descontinuidade de `NR_LOCAL_VOTACAO` entre 2018 e 2022.                                       |
| 2   | Taxa de Dominância por Local (TDL%)               | Suficiente               | Calculável agrupando `votacao_secao_2022` por `NR_LOCAL_VOTACAO` e filtrando `NM_VOTAVEL` ou número da candidata.                                                  |
| 3   | Margem de Disputa da Zona (MDZ p.p.)              | Suficiente               | Calculável agrupando `votacao_secao_2022` por `NR_ZONA`.                                                                                                           |
| 4   | Razão de Migração por Legenda Rival (RML%)        | Suficiente com Ressalvas | Exige filtrar `LEN(NR_VOTAVEL) = 2` no numerador (legenda) e prefixo de 2 dígitos no denominador (total do partido).                                               |
| 5   | Densidade de Eleitores em Local Vulnerável (DELV) | Suficiente               | `QT_APTOS` é obtido somando `QT_ELEITORES_PERFIL` na base `perfil_eleitor_secao_2022_SP` para os municípios onde $IVM = \text{Verdadeiro}$.                        |
| 6   | Índice de Vulnerabilidade do Município (IVM)      | Suficiente               | Agrupamento direto de `votacao_secao_2018` e `2022` no nível de `CD_MUNICIPIO`.                                                                                    |
| 7   | Taxa de Abstenção na Base Fiel (TABF%)            | INSUFICIENTE             | **Gargalo:** `perfil_comparecimento_abstencao_2022_SP` **não possui** `NR_LOCAL_VOTACAO`. Não há dado de abstenção por local nos arquivos.                         |
| 8   | Perfil Demográfico Dominante do Local (PDL)       | Suficiente               | Obtenção do valor modal agrupando `DS_FAIXA_ETARIA` e `DS_GRAU_ESCOLARIDADE` em `perfil_eleitor_secao_2022_SP` para o $1º\text{ Quartil}$ do TDL.                  |
| 9   | Variação de Votos Alienados ($\Delta IAR$ p.p.)   | Suficiente com Ressalvas | Calculável filtrando `NR_VOTAVEL IN (95, 96)` em 2018 e 2022. Sujeito aos riscos de descontinuidade do local de votação entre anos.                                |
| 10  | Índice de Canibalização Regional (ICF%)           | INSUFICIENTE             | **Gargalo:** Os arquivos não informam o domicílio/região eleitoral dos demais candidatos da federação. Exige a inclusão de base externa (`consulta_cand_2022_SP`). |


# 4. Recomendações e Próximos Passos Obrigatórios
### 1. Ajuste no Escopo do KPI 7:
- _Opção A:_ Alterar a granularidade do KPI 7 para o nível de **Zona Eleitoral** (`NR_ZONA`), onde a base de abstenção está disponível.
- _Opção B:_ Adicionar a base oficial do TSE de _Detalhe da Votação por Seção_ que contenha a contagem de abstenções por seção/local.

### 2. Inclusão da Base `consulta_cand_2022_SP`:
- Adicionar essa base ao projeto para relacionar `SQ_CANDIDATO` aos dados de partido, coligação/federação e município de atuação, resolvendo o **KPI 10** e dispensando gambiarras de _substring_ para identificar partidos.

### 3. Construção de Regras de ETL para Identificação de Partidos:
- Caso não adicionem a base de candidatos, documentar a regra de negócio SQL que utiliza `SUBSTRING(NR_VOTAVEL, 1, 2)` para mapear a votação nominal e de legenda do PSDB (45), Cidadania (23) e concorrentes.