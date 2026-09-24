# 📊 Engenharia de Dados para BI: Análise Eleitoral TSE (Start Phoenix Consultoria)

Este repositório documenta a esteira de Engenharia de Dados desenvolvida para o Projeto Integrador de Business Intelligence (Faculdade Impacta). Atuando como a equipe de inteligência da campanha da deputada estadual Ana Carolina Serra (PSDB-SP), nosso objetivo foi processar bases massivas do Tribunal Superior Eleitoral (TSE) para viabilizar decisões estratégicas de campanha.

## 🎯 O Desafio
A equipe de Negócios (PM e Analistas) definiu um catálogo com mais de 10 KPIs estratégicos e regras de negócio complexas. O desafio técnico era: os dados abertos do TSE não vêm com essas regras prontas. Minha responsabilidade como Engenheiro de Dados foi construir a ponte entre os arquivos brutos do governo e o painel final no Power BI, garantindo performance, integridade e precisão matemática.

## ⚙️ Arquitetura e Soluções Técnicas (SQL Server)

A arquitetura foi desenhada no modelo **ETL (Extract, Transform, Load)**, materializando os dados em tabelas físicas para poupar processamento em tempo real do Power BI.

### 1. Camada Landing e Tratamento de Encoding
Os arquivos governamentais apresentavam sérias inconsistências estruturais de um ciclo eleitoral para outro:
* **Conflito de Codepage:** Os dados de 2018 vieram codificados em UTF-8 (`CODEPAGE = '65001'`), enquanto os de 2022 vieram em Latin-1 (`CODEPAGE = 'ACP'`). Identificar e mapear isso no `BULK INSERT` evitou a corrupção de milhares de registros textuais.

### 2. Camada Staging (Limpeza)
Aplicação de rotinas pesadas de padronização usando **CTEs (Common Table Expressions)**:
* Remoção de aspas duplas (qualificadores de texto) soltas nos arquivos com a combinação `UPPER(TRIM(REPLACE()))`.
* Conversão segura de tipos de dados (`TRY_CAST`).
* Deduplicação cirúrgica de registros utilizando `ROW_NUMBER() OVER (PARTITION BY ...)` para isolar a granularidade correta sem perder informações por erros de digitação.

### 3. Camada Semântica / Data Mart (A Entrega de Valor)
Onde as regras de negócios saíram do papel e viraram código:
* **UNION ALL:** Empilhamento histórico das votações de 2018 e 2022 para permitir cálculos de variação de *Market Share* na mesma linha do tempo.
* **Feature Engineering com CASE WHEN:** Derivação de colunas inexistentes na fonte original (ex: agrupamento dos códigos 95 e 96 para criar a métrica de "Votos Alienados", e agrupamento dos códigos de partido para mapear a "Federação PSDB/Cidadania").
* **Window Functions:** Cálculo de totais e agregações no próprio banco (`SUM() OVER()`) para entregar métricas regionais mastigadas ao painel de BI.

## 🧠 Metodologia de Aprendizado
O desenvolvimento deste projeto envolveu uma curva de aprendizado acelerada, mesclando conhecimentos acadêmicos com o uso estratégico de Inteligência Artificial atuando como uma "mentoria sênior". A IA não foi utilizada para gerar código pronto, mas para validar lógicas de negócio, desafiar a aplicação de conceitos (como a transição do uso exclusivo de CTEs para integrações complexas com UNION ALL e JOINs) e diagnosticar falhas de arquitetura (como os gargalos de performance entre abordagens ETL e ELT/Views).
