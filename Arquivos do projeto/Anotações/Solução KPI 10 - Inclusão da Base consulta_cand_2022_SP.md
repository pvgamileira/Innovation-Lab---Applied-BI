# O que a base `consulta_cand_2022_SP` RESOLVE no KPI 10
1. **Relacionamento Direto com a Votação:**
    - Contém a coluna `SQ_CANDIDATO` (chave sequencial única), permitindo o `JOIN` exato com a base `votacao_secao_2022_SP` sem depender de _substrings_.
2. **Identificação Exata da Federação e Partidos:**
    - Os campos `SG_FEDERACAO`, `NM_FEDERACAO`, `SG_PARTIDO` e `DS_COMPOSICAO_FEDERACAO` isolam com precisão os candidatos pertencentes à Federação PSDB-Cidadania (partidos 45 e 23).
3. **Filtro dos Concorrentes Internos:**
    - Utilizando `NR_CANDIDATO` ou `SQ_CANDIDATO`, é possível subtrair a própria candidata Ana Carolina Serra do numerador, deixando apenas os "outros candidatos".
4. **Integridade das Candidaturas:**
    - O campo `DS_SITUACAO_CANDIDATURA` permite filtrar apenas candidaturas válidas/deferidas no pleito de 2022.
>Link para o download da base (pegar apenas a de SP): https://dadosabertos.tse.jus.br/dataset/candidatos-2022/resource/435145fd-bc9d-446a-ac9d-273f585a0bb9

# O que a base AINDA NÃO RESOLVE (Limitação de Dado)
Para o cargo de Deputado Estadual (`DS_CARGO`), a circunscrição é estadual:
- As colunas `SG_UE` e `NM_UE` contêm apenas a sigla/nome do Estado (**"SP" / "SÃO PAULO"**).
- O único dado de município referente ao candidato é o `NM_MUNICIPIO_NASCIMENTO`. O local de nascimento **não é um indicativo confiável** do reduto ou base política do candidato.
- A base **não possui** uma coluna que indique o "domicílio eleitoral" ou a "região de atuação política" (Grande ABC / RMSP).


# Solução Prática para Finalizar o KPI 10 no Projeto
Com a base `consulta_cand_2022_SP` integrada, o grupo deve filtrar quais candidatos da federação pertencem ao Grande ABC / RMSP:
- Classificar automaticamente como candidato do Grande ABC / RMSP aquele candidato da federação que obteve mais de $50\%$ dos seus votos totais nos municípios dessas duas regiões.
- Esta abordagem (conhecida como _proxy de concentração eleitoral_) é amplamente utilizada em ciência de dados e análise política: se um candidato obtém a maioria absoluta ou expressiva dos seus votos numa determinada região, essa região é formalmente a sua base eleitoral.

### Como aplicar esta solução (Passo a Passo)
A aplicação faz-se diretamente na camada de transformação de dados (SQL / ETL) combinando a base `votacao_secao_2022_SP` com a `consulta_cand_2022_SP`.

#### Passo 1: Mapear os Códigos dos Municípios do Grande ABC / RMSP
Primeiro, identifica-se a lista de códigos de município do TSE (`CD_MUNICIPIO`) que pertencem ao Grande ABC (Santo André, São Bernardo do Campo, São Caetano do Sul, Diadema, Mauá, Ribeirão Pires e Rio Grande da Serra) e à RMSP.

#### Passo 2: Calcular a Concentração de Votos por Candidato da Federação
Para cada candidato a Deputado Estadual pertencente à Federação PSDB-Cidadania (`SG_FEDERACAO` ou `NR_FEDERACAO`), calcula-se:
1. **Votos Totais no Estado ($V_{\text{estado}}$):** Soma de votos do candidato em todos os municípios de São Paulo.
2. **Votos na Região ($V_{\text{regiao}}$):** Soma de votos do candidato apenas nos municípios do Grande ABC / RMSP.
3. **Taxa de Concentração Regional:** $\text{Concentração} = \frac{V_{\text{regiao}}}{V_{\text{estado}}}$.

#### Passo 3: Classificar os Concorrentes Regionais
Filtram-se os candidatos que cumprem a regra:
- $\text{Concentração} \ge 0.50$ ($50\%$ ou mais dos seus votos vieram da RMSP/Grande ABC).
- Exclui-se o `SQ_CANDIDATO` / `NR_CANDIDATO` da própria deputada Ana Carolina Serra.
Os candidatos restantes constituem o grupo oficial de **Concorrentes Internos Regionais**.

#### Passo 4: Calcular o KPI 10
Com a lista de concorrentes isolada, calcula-se a taxa de canibalização nos locais/zonas de interesse:
$$\text{KPI 10 (ICF\%)} = \frac{\text{Votos nos Outros Candidatos da Federação Classificados como Regionais}}{\text{Votos Totais da Federação (Candidatos + Legenda)}}$$

### Exemplo de Aplicação em SQL
Eis uma estrutura de consulta SQL que executa todo o processo (adapte de acordo com seu banco e suas bases):

```
WITH Municipios_Alvo AS (
    -- 1. Mapeamento dos códigos TSE dos municípios do Grande ABC / RMSP
    SELECT CD_MUNICIPIO 
    FROM tabela_municipios
    WHERE NM_MUNICIPIO IN (
        'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL',
        'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA'
        -- Incluir os demais municípios da RMSP pretendidos
    )
),

Votacao_Candidatos_Federacao AS (
    -- 2. Cruzamento da votação com o cadastro de candidatos da Federação
    SELECT 
        c.SQ_CANDIDATO,
        c.NR_CANDIDATO,
        c.NM_URNA_CANDIDATO,
        v.CD_MUNICIPIO,
        v.QT_VOTOS
    FROM votacao_secao_2022_SP v
    INNER JOIN consulta_cand_2022_SP c 
        ON v.SQ_CANDIDATO = c.SQ_CANDIDATO
    WHERE c.DS_CARGO = 'DEPUTADO ESTADUAL'
      AND c.SG_FEDERACAO = 'PSDB CIDADANIA' -- Filtra a Federação
      AND c.DS_SITUACAO_CANDIDATURA = 'DEFERIDO'
),

Concentracao_Candidato AS (
    -- 3. Cálculo do total no Estado vs. total no Grande ABC / RMSP
    SELECT 
        SQ_CANDIDATO,
        NR_CANDIDATO,
        NM_URNA_CANDIDATO,
        SUM(QT_VOTOS) AS Votos_Totais_Estado,
        SUM(CASE WHEN CD_MUNICIPIO IN (SELECT CD_MUNICIPIO FROM Municipios_Alvo) THEN QT_VOTOS ELSE 0 END) AS Votos_Regiao,
        SUM(CASE WHEN CD_MUNICIPIO IN (SELECT CD_MUNICIPIO FROM Municipios_Alvo) THEN QT_VOTOS ELSE 0 END) * 1.0 / NULLIF(SUM(QT_VOTOS), 0) AS Taxa_Concentracao
    FROM Votacao_Candidatos_Federacao
    GROUP BY SQ_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO
),

Candidatos_Concorrentes_Regionais AS (
    -- 4. Isolamento dos rivais com >= 50% de votos na região (excluindo a deputada)
    SELECT SQ_CANDIDATO, NR_CANDIDATO, NM_URNA_CANDIDATO
    FROM Concentracao_Candidato
    WHERE Taxa_Concentracao >= 0.50
      AND NR_CANDIDATO <> '45XXX' -- Inserir o número da deputada Ana Carolina Serra para excluí-la
)

-- 5. Consulta Final do KPI 10 por Local de Votação / Zona
SELECT 
    v.NR_ZONA,
    v.NR_LOCAL_VOTACAO,
    SUM(CASE WHEN v.SQ_CANDIDATO IN (SELECT SQ_CANDIDATO FROM Candidatos_Concorrentes_Regionais) THEN v.QT_VOTOS ELSE 0 END) AS Votos_Concorrentes_Regionais,
    SUM(v.QT_VOTOS) AS Votos_Totais_Federacao_Local,
    ROUND(
        SUM(CASE WHEN v.SQ_CANDIDATO IN (SELECT SQ_CANDIDATO FROM Candidatos_Concorrentes_Regionais) THEN v.QT_VOTOS ELSE 0 END) * 100.0 / 
        NULLIF(SUM(v.QT_VOTOS), 0), 2
    ) AS KPI_10_Canibalizacao_Percentual
FROM votacao_secao_2022_SP v
WHERE v.NR_VOTAVEL IN (SELECT CAST(NR_CANDIDATO AS VARCHAR) FROM Candidatos_Concorrentes_Regionais)
   OR v.NR_VOTAVEL IN ('45', '23') -- Inclui votos de legenda para o total da federação
GROUP BY v.NR_ZONA, v.NR_LOCAL_VOTACAO;
```

### Vantagens de adotar essa solução
1. **Sem esforço manual de manutenção:** Não é necessário pesquisar manualmente a biografia de centenas de candidatos.
2. **Reprodutível:** A regra pode ser replicada para outros anos eleitorais ou para outras regiões sem alterar o código.
3. **Defensável auditavelmente:** Garante um critério quantitativo transparente para a equipa de campanha e para os decisores.