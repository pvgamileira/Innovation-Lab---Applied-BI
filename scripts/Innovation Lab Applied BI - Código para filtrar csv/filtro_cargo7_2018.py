"""
Filtro do arquivo votacao_secao_2018_SP.csv -> apenas CD_CARGO = 7 (Deputado Estadual).

Segue a mesma ideia do filtro.py do time, com duas diferencas importantes:
  1. Mantem o encoding original do TSE (latin-1) e o separador ';' com aspas,
     para que o BULK INSERT use exatamente o mesmo formato do CSV original.
     (o pandas.to_csv padrao regrava em UTF-8, o que mudava o CODEPAGE da carga).
  2. Le em streaming (csv.reader), sem carregar o arquivo de 5 GB em memoria,
     e imprime contagens para auditoria (linhas lidas, linhas gravadas, votos).
"""
import csv
import sys
from pathlib import Path

PASTA = Path(r"C:\Innovation-Lab---Applied-BI\CSV - TSE")
ARQ_BRUTO = PASTA / "votacao_secao_2018_SP.csv"
ARQ_LIMPO = PASTA / "votacao_secao_2018_SP_FiltroCargo7_DeputadoEstadual.csv"

lidas = gravadas = votos = 0
with open(ARQ_BRUTO, encoding="latin-1", newline="") as fin, \
     open(ARQ_LIMPO, "w", encoding="latin-1", newline="") as fout:
    leitor = csv.reader(fin, delimiter=";", quotechar='"')
    escritor = csv.writer(fout, delimiter=";", quotechar='"',
                          quoting=csv.QUOTE_ALL, lineterminator="\r\n")
    cabecalho = next(leitor)
    i_cargo = cabecalho.index("CD_CARGO")
    i_votos = cabecalho.index("QT_VOTOS")
    escritor.writerow(cabecalho)
    for linha in leitor:
        lidas += 1
        if linha[i_cargo] == "7":
            escritor.writerow(linha)
            gravadas += 1
            votos += int(linha[i_votos])
        if lidas % 5_000_000 == 0:
            print(f"{lidas:,} linhas lidas...", flush=True)

print(f"colunas={len(cabecalho)} linhas_lidas={lidas} linhas_cargo7={gravadas} votos_cargo7={votos}")
