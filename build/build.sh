#!/bin/bash
#=================================================================#
# SFP - SISTEMA DE FOLHA DE PAGAMENTO                             #
# SCRIPT DE COMPILACAO DOS MODULOS BATCH COM GNUCOBOL             #
#                                                                 #
# EQUIVALENTE LOCAL DO JOB SFPJ0100 (JCL DE COMPILACAO).          #
# OS MODULOS CICS (SFP0000, SFP0100, SFP0120, SFP0140, SFP0160    #
# E SFP0900) NAO SAO COMPILADOS AQUI: EXIGEM O TRADUTOR CICS E,   #
# EM ALGUNS CASOS, O PRECOMPILADOR DB2 DO MAINFRAME.              #
#=================================================================#
set -e
cd "$(dirname "$0")/.."
RAIZ=$(pwd)

echo "================================================="
echo " SFP - COMPILACAO DOS MODULOS BATCH"
echo " Raiz do projeto: $RAIZ"
echo "================================================="

if ! command -v cobc >/dev/null 2>&1; then
    echo "ERRO: GnuCOBOL nao encontrado."
    echo "Instale com: sudo apt-get install -y gnucobol"
    exit 1
fi
cobc --version | head -1

mkdir -p build saidas

echo ""
echo "--- Subrotinas (modulos chamados) --------------"
cobc -m -I copy -o build/SFPUTIL.so cobol/SFPUTIL.cbl
echo "  SFPUTIL  ... utilitarios (CPF, datas, avos, extenso)"
cobc -m -I copy -o build/SFP0310.so cobol/SFP0310.cbl
echo "  SFP0310  ... motor tributario (INSS, IRRF, FGTS, SF)"

echo ""
echo "--- Programas principais -----------------------"
cobc -x -I copy -o build/SFP0200 cobol/SFP0200.cbl
echo "  SFP0200  ... critica do movimento mensal"

cobc -x -I copy -o build/SFP0300 \
     cobol/SFP0300.cbl cobol/SFP0310.cbl cobol/SFPUTIL.cbl
echo "  SFP0300  ... motor de calculo da folha"

cobc -x -I copy -o build/SFP0350 \
     cobol/SFP0350.cbl cobol/SFP0310.cbl cobol/SFPUTIL.cbl
echo "  SFP0350  ... rescisao contratual (TRCT)"

cobc -x -I copy -o build/SFP0400 cobol/SFP0400.cbl
echo "  SFP0400  ... fechamento contabil"

cobc -x -I copy -o build/SFP0500 cobol/SFP0500.cbl cobol/SFPUTIL.cbl
echo "  SFP0500  ... contracheque / espelho de pagamento"

cobc -x -I copy -o build/SFP0600 cobol/SFP0600.cbl
echo "  SFP0600  ... remessa bancaria CNAB240"

echo ""
echo "================================================="
echo " COMPILACAO CONCLUIDA COM SUCESSO"
echo " Execute ./build/run.sh para rodar a cadeia."
echo "================================================="
