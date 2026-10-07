# Spec-Driven Development: Pipeline Star Schema

**Missão:** Você é um Agente de Engenharia de Dados atuando via Antigravity 2.0. Seu objetivo é estruturar e popular o modelo dimensional no SQL Server, salvar os scripts .sql gerados e realizar o commit no Git.

## 1. Regras Inegociáveis de Sintaxe e Escopo
*   **SINTAXE CRÍTICA:** TODOS os comandos SQL, nomes de tabelas, funções (ex: concat_ws) e variáveis criadas por você devem ser escritos em letras **minúsculas**.
*   **ESCOPO DE TRABALHO:** Leia o arquivo `(IMPACTA) Innovation Lab BI - Star Schema.md` localmente para entender a arquitetura. Nós cuidaremos APENAS das tabelas centrais: `dim_eleicao`, `dim_local_votacao`, `dim_candidato_partido` e `fato_votacao`.
*   **PROIBIÇÃO:** Não crie, não toque e não referencie as tabelas de Demografia/Perfil ou Abstenção (o Dev João fará isso em outro branch).

## 2. Conexão e Descoberta (Staging)
*   As tabelas brutas já existem no banco (ex: `dbo.staging_votacaosecao_2022_sp`, `dbo.staging_consulta_cand_2022_sp` e versões 2018).
*   Leia as credenciais do arquivo `.env` local.
*   Conecte-se ao banco e execute uma query em `INFORMATION_SCHEMA.COLUMNS` para descobrir as colunas reais dessas tabelas de staging ANTES de tentar gerar os inserts.

## 3. Ordem Exata de Execução (DDL e DML)
Efetue a criação (CREATE) e a carga (INSERT) diretamente no banco, uma a uma:
1.  **`dim_eleicao`**: Insira os dados de 2018 e 2022 de forma estática (conforme documentação).
2.  **`dim_local_votacao`**: Use um `union` das stagings 18 e 22 para deduplicar escolas. A chave (nk) deve ser criada com `concat_ws('_', cd_municipio, nr_zona, nr_local_votacao)`. Calcule as flags `fl_grande_abc` e `fl_rmsp` lendo o nome do município.
3.  **`dim_candidato_partido`**: Insira os controles (95, 96 e -1). Depois, um `union` das stagings de candidatos (cargo 'DEPUTADO ESTADUAL'). Para 2018, insira estaticamente 'SEM FEDERAÇÃO' para alinhar as colunas com 2022. Calcule a flag de Market Share (`fl_concorrente_regional`) para >= 50% na região metropolitana/abc.
4.  **`fato_votacao`**: Empilhe os votos usando `union all` e aplique os `joins` com as dimensões acima para resgatar os IDs (sk).

## 4. Gestão de Artefatos e Git
*   Após rodar as querys com sucesso no banco, crie um diretório chamado `entregas_dimensionais` na raiz deste projeto.
*   Salve os 4 scripts consolidados nela (ex: `01_dim_eleicao.sql`, `02_dim_local_votacao.sql`, etc).
*   Execute `git add .`, `git commit -m "feat: finaliza estrutura core do star schema minúsculo"` e `git push`.