import pandas as pd

# Coloque o caminho do seu arquivo de 4GB aqui
arquivo = r"C:\Impacta\Innovation Lab\Innovation Lab Applied BI\CSV - TSE\votacao_secao_2022_SP_FiltroCargo7_DeputadoEstadual.csv"

# nrows=0 faz o Pandas ler APENAS o cabeçalho (a linha 1), ignorando os 4GB de dados. É instantâneo!
df = pd.read_csv(arquivo, sep=";", encoding="latin1", nrows=0)

print("\n--- COPIE E COLE ISSO NO SEU SQL SERVER ---\n")
print("CREATE TABLE dbo.Sua_Tabela_Bruta (")

# O laço for passa por todas as colunas do CSV e monta a linha do SQL
for coluna in df.columns:
    print(f"    {coluna} VARCHAR(100),")

print(");")
print("\n-------------------------------------------\n")
