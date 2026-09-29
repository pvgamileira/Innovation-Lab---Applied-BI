# Opção A: Redefinição da Granularidade para Zona Eleitoral (`NR_ZONA`)
### Funcionamento Técnico
O arquivo `perfil_comparecimento_abstencao_2022_SP` possui o dado absoluto de abstenção, porém compilado no nível de **Zona Eleitoral** (`NR_ZONA`), sem detalhar as seções ou os locais de votação.
Na Opção A, o indicador deixa de olhar para colégios eleitorais específicos e passa a medir a taxa de abstenção da Zona Eleitoral como um todo:
$$\text{TABF\%}_{\text{Zona}} = \left( \frac{\sum \text{QT\_ABSTENCAO}_{\text{Zona}}}{\sum \text{QT\_APTOS}_{\text{Zona}}} \right) \times 100$$

### Como ela torna o KPI 7 suficiente?
- **Elimina a dependência de chaves ausentes:** Descarta a necessidade das colunas `NR_SECAO` e `NR_LOCAL_VOTACAO` na tabela de abstenções.
- **Consistência de Dados Nativa:** A base `perfil_comparecimento_abstencao_2022_SP` já possui o somatório exato por `NR_ZONA`, tornando o KPI viável sem adicionar novos arquivos ou fazer junções complexas.

### Impacto Estratégico e Trade-offs
- **Vantagem:** Esforço de ETL nulo; implementação imediata no pipeline.
- **Desvantagem:** Perda de sensibilidade geográfica. Uma Zona Eleitoral pode cobrir dezenas de bairros e perfis socioeconômicos heterogêneos. Impede identificar, por exemplo, se uma escola específica teve 30% de abstenção enquanto outra ao lado teve 15%.


# Opção B: Inclusão do Arquivo Oficial `detalhe_votacao_secao_2022_SP`
### Funcionamento Técnico
O TSE disponibiliza no Portal de Dados Abertos o repositório **Detalhe da Votação por Seção** (`detalhe_votacao_secao_2022_SP`). Este arquivo contém o registro contábil oficial de cada seção eleitoral individual (`NR_SECAO`), apresentando explicitamente as colunas:
- `QT_APTOS` (Eleitores aptos a votar na seção)
- `QT_COMPARECIMENTO` (Eleitores que compareceram)
- `QT_ABSTENCAO` (Eleitores que abstiveram-se)
Ao cruzar o `detalhe_votacao_secao_2022_SP` com a tabela de cadastro de eleitores (`perfil_eleitor_secao_2022_SP`) utilizando a chave composta (`CD_MUNICIPIO` + `NR_ZONA` + `NR_SECAO`), associa-se cada seção ao seu respectivo `NR_LOCAL_VOTACAO`. A agregação do KPI passa a ser realizada no nível de Local de Votação:
$$\text{TABF\%}_{\text{Local}} = \left( \frac{\sum \text{QT\_ABSTENCAO}_{\text{Local}}}{\sum \text{QT\_APTOS}_{\text{Local}}} \right) \times 100$$
>Link para o download da base: https://dadosabertos.tse.jus.br/dataset/resultados-2022/resource/9f042e8b-ed41-4b18-a01b-e0613a68d90c

### Como ela torna o KPI 7 suficiente?
- **Restabelece a Granularidade Original:** Preenche a lacuna de dados permitindo mapear a abstenção exata até o nível de prédio/escola eleitoral.
- **Precisão Matemática Total:** Elimina estimativas ou agrupamentos genéricos, garantindo dados oficiais e auditáveis por local.

### Impacto Estratégico e Trade-offs
- **Vantagem:** Valor estratégico alto para a campanha. Permite cruzamentos cirúrgicos no Dashboard (ex: identificar locais onde a candidata teve alta dominância no KPI 2, mas que registraram abstenção alta no KPI 7, indicando locais prioritários para ações de mobilização no dia da eleição).
- **Desvantagem:** Exige o download e a ingestão de um arquivo adicional no processo de carga de dados.

### Comparativo Direto entre as Opções

| Critério               | Opção A (Zona Eleitoral)               | Opção B (Detalhe por Seção)                    |
| ---------------------- | -------------------------------------- | ---------------------------------------------- |
| Arquivos Necessários   | Apenas os atuais (sem novos downloads) | Adiciona `detalhe_votacao_secao_2022_SP`       |
| Nível de Análise       | Macro (Zona Eleitoral)                 | Micro (Local de Votação / Escola)              |
| Complexidade de ETL    | Baixa                                  | Média (exige `JOIN` de 3 campos entre tabelas) |
| Precisão de Mapeamento | Genérica por região da cidade          | Cirúrgica por colégio eleitoral                |
| Status do KPI 7        | Suficiente (com mudança de escopo)     | Suficiente (mantendo escopo original)          |
