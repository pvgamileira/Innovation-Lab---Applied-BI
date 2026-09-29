# 1. O Problema em Detalhes
O código do local de votação (`NR_LOCAL_VOTACAO`) **não é um identificador único universal e imutável do prédio físico**. Ele é apenas um número sequencial administrativo atribuído pela Justiça Eleitoral dentro de cada Zona Eleitoral (`NR_ZONA`).
Entre uma eleição e outra (2018 a 2022), acontecem três eventos frequentes nos Tribunais Regionais Eleitorais (TREs):
1. **Reforma ou Fechamento de Escolas:** Uma escola entra em obras e os eleitores são transferidos temporária ou definitivamente para outro prédio.
2. **Rezonamento Eleitoral:** Zonas eleitorais são fundidas ou reestruturadas, alterando o código da zona e, consequentemente, a numeração dos locais.
3. **Renumeração de Locais:** O TRE reordena os códigos dos colégios dentro da mesma zona.

### O que acontece se fizer um `JOIN` simples?
Se você cruzar os dados de 2018 e 2022 usando a chave seca `CD_MUNICIPIO + NR_ZONA + NR_LOCAL_VOTACAO`:
- **Anomalia de "Votos Fantasma":** Uma escola que era código `1012` em 2018 e virou `1050` em 2022 parecerá ter tido **$-100\%$ de queda** no código antigo e ter nascido com $+100\%$ de crescimento no código novo.
- **Distorção no KPI 1 e KPI 9:** O cálculo da variação ($\Delta$) resultará em valores absurdos (ex: $-100\text{ p.p.}$ ou $+100\text{ p.p.}$) que não refletem a migração real do eleitorado, mas sim uma mudança de cadastro no banco do TSE.

# 2. A Solução Simples e Prática (Como Resolver)
A forma mais simples, rápida e comum em BI/Analytics para resolver esse problema sem precisar de ferramentas complexas de geolocalização é a **Estratégia de Interseção e Classificação de Status**.

### Como aplicar via SQL:
Em vez de forçar a comparação de tudo, você classifica os locais de votação em três categorias ao relacionar 2018 e 2022:
1. **Locais Mantidos (Interseção):** Locais que possuem exatamente a mesma chave (`CD_MUNICIPIO` + `NR_ZONA` + `NR_LOCAL_VOTACAO`) em 2018 e 2022. **Estes são os únicos utilizados no cálculo direto do KPI 1 e KPI 9.**
2. **Locais Novamente Criados em 2022:** Existem em 2022, mas não em 2018.
3. **Locais Desativados em 2018:** Existiam em 2018, mas foram desativados em 2022.

### Lógica SQL da Solução Simples:

```
WITH Votacao_2018 AS (
    SELECT CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, SUM(QT_VOTOS) AS Votos_2018
    FROM votacao_secao_2018_SP
    GROUP BY CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO
),
Votacao_2022 AS (
    SELECT CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO, SUM(QT_VOTOS) AS Votos_2022
    FROM votacao_secao_2022_SP
    GROUP BY CD_MUNICIPIO, NR_ZONA, NR_LOCAL_VOTACAO
)
SELECT 
    COALESCE(v18.CD_MUNICIPIO, v22.CD_MUNICIPIO) AS CD_MUNICIPIO,
    COALESCE(v18.NR_ZONA, v22.NR_ZONA) AS NR_ZONA,
    COALESCE(v18.NR_LOCAL_VOTACAO, v22.NR_LOCAL_VOTACAO) AS NR_LOCAL_VOTACAO,
    
    ISNULL(v18.Votos_2018, 0) AS Votos_2018,
    ISNULL(v22.Votos_2022, 0) AS Votos_2022,
    
    -- Classificação do Status do Local
    CASE 
        WHEN v18.NR_LOCAL_VOTACAO IS NOT NULL AND v22.NR_LOCAL_VOTACAO IS NOT NULL THEN 'COMPARÁVEL (MANTIDO)'
        WHEN v18.NR_LOCAL_VOTACAO IS NULL THEN 'NOVO EM 2022'
        ELSE 'EXTINTO/ALTERADO APÓS 2018'
    END AS STATUS_LOCAL,

    -- O KPI só calcula a variação se o local for 'COMPARÁVEL'
    CASE 
        WHEN v18.NR_LOCAL_VOTACAO IS NOT NULL AND v22.NR_LOCAL_VOTACAO IS NOT NULL 
        THEN (v22.Votos_2022 - v18.Votos_2018) -- Exemplo de variação simples
        ELSE NULL 
    END AS Variacao_Valida

FROM Votacao_2018 v18
FULL OUTER JOIN Votacao_2022 v22
    ON v18.CD_MUNICIPIO = v22.CD_MUNICIPIO
   AND v18.NR_ZONA = v22.NR_ZONA
   AND v18.NR_LOCAL_VOTACAO = v22.NR_LOCAL_VOTACAO;
```

# 3. Solução Avançada (Caso queira recuperar os locais alterados)
Se o grupo quiser ir além e recuperar os locais que apenas mudaram de código numérico, pode-se criar um **`JOIN` secundário por Nome do Local (`NM_LOCAL_VOTACAO`)**:
1. Tenta o match inicial por Código (`CD_MUNICIPIO` + `NR_ZONA` + `NR_LOCAL_VOTACAO`).
2. Para os locais que sobraram sem par (os "Novos" e "Extintos"), faz-se uma busca combinando `CD_MUNICIPIO` + `NM_LOCAL_VOTACAO` (ou endereço).
3. Se o nome do colégio ("Escola Estadual EE João XXIII") for exatamente igual, o sistema entende que é o mesmo prédio físico e faz a ponte (De-Para) entre o código de 2018 e o código de 2022.

# Recomendação para o Dashboard
1. Aplicar a **Solução Simples (Filtro de Interseção)** no SQL.
2. No Dashboard (Power BI / Looker), adicionar um filtro ou aviso simples informando que o indicador de variação 2018–2022 compara os locais com manutenção de cadastro ativo.
3. Para análises onde a variação local for crítica e a chave tiver mudado, a visão consolidada por **Zona Eleitoral (`NR_ZONA`)** serve como camada de suporte $100\%$ estável.