# Documentação Técnica e Validação do Modelo Dimensional (Star Schema)
**Projeto:** Diagnóstico de Vulnerabilidade e Defesa Territorial de Redutos Históricos (PSDB-SP)
**Escopo:** Eleições Estaduais SP (2018 e 2022) - Deputado Estadual

---

## 1. O que foi feito?
Foi desenvolvido e implantado o Data Warehouse (Star Schema) no SQL Server local, focado exclusivamente no escopo do nosso cliente (PSDB-SP) para análise das eleições de 2018 e 2022. 

Entregamos **4 Dimensões e 3 Tabelas Fato**, populadas com os dados abertos do TSE que estavam na área de *Staging*. Todos os 7 scripts de criação e carga (ETL) foram padronizados (boas práticas de SQL) e versionados no repositório GitHub do projeto.

### Arquitetura Entregue:
*   **Dimensões (Contexto):** `Dim_Eleicao`, `Dim_Local_Votacao`, `Dim_Candidato_Partido`, `Dim_Perfil_Demografico`.
*   **Fatos (Métricas):** `Fato_Votacao` (com 15.8M de votos), `Fato_Perfil_Eleitorado`, `Fato_Comparecimento_Abstencao`.

---

## 2. Como foi feito? (Soluções Técnicas Aplicadas)
Durante a modelagem, os scripts foram construídos respeitando rigorosamente a padronização solicitada pela Engenharia de Dados: **palavras-chave do SQL em minúsculo** (`select`, `from`, etc.) e **identificadores/colunas em Maiúsculo/PascalCase** para perfeito funcionamento do *auto-complete* no SSMS/DBeaver.

Além da padronização de nomenclatura, implementamos correções avançadas de qualidade de dados (Data Quality):
1.  **Tratamento de Dados Corrompidos (Anomalias na Staging):** A tabela `Staging_Perfil_Eleitor_Secao_2022` apresentava inconsistências de carga (ex: colunas `NR_SECAO` e `CD_LOCAL_VOTACAO` invertidas e valores negativos). Nossa engenharia adaptou o algoritmo (`06_Fato_Perfil_Eleitorado.sql`) para cruzar os dados usando a chave primária geográfica do Local de Votação, resgatando a validade dos registros sem perder os 15 milhões de eleitores da base.
2.  **Otimização de Armazenamento:** Removemos a estratégia inicial de manter tabelas físicas de backup (`_bkp`) que estourariam o disco. Em substituição, entregamos um script profissional `backup_diario.sql` (formato `.bak`) para agendamento, permitindo descartar toda a camada de *Staging* para economizar espaço em disco.
3.  **Auditoria de Chaves de Controle:** Inserimos chaves artificiais de fallback: `-1` (Não Identificado), `95` (Voto Branco) e `96` (Voto Nulo).

---

## 3. Por que foi feito dessa forma? (Alinhamento de Negócio e KPIs)
Toda a arquitetura e a regra de negócio aplicada no SQL refletem diretamente o documento `Definição Cliente + Perguntas e KPIs.txt` e o `Star Schema.md`. A estrutura foi montada sob medida para responder as dores do Deputado e calcular os **8 KPIs** estratégicos da campanha:

*   **Defesa de Redutos (MDR e IET):** A Fato de Votação cruza o histórico de 2018 e 2022. Ao cruzar com a `Dim_Local_Votacao`, a campanha pode identificar instantaneamente a evasão de votos (Índice de Erosão Territorial - KPI 1) para os partidos rivais (PL, PSD).
*   **Controle de Regiões de Interesse:** Inserimos as *flags* `FL_GRANDE_ABC` e `FL_RMSP` (Região Metropolitana) na `Dim_Local_Votacao`. Isso permite isolar a análise nas regiões prioritárias do Deputado, respondendo à Pergunta 3 sobre as "Swing Zones" do interior vs RMSP.
*   **Identificação de Concorrentes Diretos (Market Share):** A `Dim_Candidato_Partido` possui a flag de negócio `FL_CONCORRENTE_REGIONAL`. O algoritmo calculou via SQL quais adversários detiveram $\ge 50\%$ de seus votos na RMSP/ABC, revelando as áreas de canibalização (KPI 6) para a Pergunta 10.
*   **Engajamento Demográfico e Abstenção (TAB):** Ao separar a `Fato_Comparecimento_Abstencao` e a `Fato_Perfil_Eleitorado`, a equipe tática consegue planejar logística de transporte no dia do pleito (Pergunta 6 / KPI 5) e adequar a linguagem de marketing digital (Pergunta 8) baseada na demografia exata do bairro/local de votação sob ataque.

**Conclusão:** 
A infraestrutura analítica atende a 100% dos requisitos mapeados nos PDFs e atas de Kickoff. O modelo relacional otimizado habilitará o time de BI a plugar o Power BI, focar no design visual e gerar insights acionáveis sem se preocupar com lentidão ou discrepância de métricas.
