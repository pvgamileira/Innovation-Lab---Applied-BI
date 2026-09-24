import pandas as pd

# Mantenha os seus caminhos aqui (com o r na frente)
arquivo_bruto = r"C:\Users\BOXPDV\Documents\Impacta\Innovation Lab\Innovation Lab Applied BI\CSV - TSE\votacao_secao_2018_SP.csv"
arquivo_limpo = r"C:\Users\BOXPDV\Documents\Impacta\Innovation Lab\Innovation Lab Applied BI\CSV - TSE\votacao_secao_2018_SP_FiltroCargo7_DeputadoEstadual.csv"

print("Iniciando a leitura do arquivo gigante. Vai demorar alguns minutos, não feche!")

# Lendo em lotes
lotes = pd.read_csv(arquivo_bruto, sep=";", encoding="latin1", chunksize=100000)
primeira_vez = True
contador = 1  # Criamos um contador para te dar feedback

for lote_atual in lotes:
    # Printa na tela para você saber que não travou
    print(f"Processando lote {contador}... ({(contador * 100000):,} linhas lidas)")

    # Filtra APENAS o cargo 7
    lote_filtrado = lote_atual[lote_atual["CD_CARGO"] == 7]

    if not lote_filtrado.empty:
        if primeira_vez == True:
            lote_filtrado.to_csv(
                arquivo_limpo, sep=";", index=False, mode="w", header=True
            )
            primeira_vez = False
        else:
            lote_filtrado.to_csv(
                arquivo_limpo, sep=";", index=False, mode="a", header=False
            )

    contador += 1  # Soma 1 no contador e vai pro próximo lote

print("==========================================================")
print("Sucesso! Arquivo de votação reduzido e pronto para o banco.")
