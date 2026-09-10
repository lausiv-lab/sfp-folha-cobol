#!/bin/bash
#=================================================================#
# SFP - SISTEMA DE FOLHA DE PAGAMENTO                             #
# EXECUCAO COMPLETA DA CADEIA BATCH MENSAL                        #
#                                                                 #
# EQUIVALENTE LOCAL DOS JOBS SFPJ0200, SFPJ0300, SFPJ0400,        #
# SFPJ0500 E SFPJ0600. AS VARIAVEIS DD_* SUBSTITUEM AS DD CARDS   #
# DO JCL: O GNUCOBOL RESOLVE 'ASSIGN TO SFPEMP' LENDO DD_SFPEMP.  #
#=================================================================#
cd "$(dirname "$0")/.."

export COB_LS_FIXED=1

mkdir -p saidas

#--- Entradas ----------------------------------------------------#
export DD_SFPEMP=dados/SFPEMP.DAT
export DD_SFPDEP=dados/SFPDEP.DAT
export DD_SFPEVE=dados/SFPEVE.DAT
export DD_SFPPON=dados/SFPPON.DAT
export DD_SFPTAB=dados/SFPTAB.DAT

RC_GERAL=0

banner () {
    echo ""
    echo "================================================="
    echo " $1"
    echo "================================================="
}

avalia () {
    local rc=$1 nome=$2
    if   [ "$rc" -eq 0 ]; then echo ">> $nome terminou com RC=00 (OK)"
    elif [ "$rc" -eq 4 ]; then echo ">> $nome terminou com RC=04 (com criticas)"
    else echo ">> $nome terminou com RC=$rc (ERRO)"; RC_GERAL=$rc
    fi
}

#-----------------------------------------------------------------#
banner "PASSO 1 - SFP0200 CRITICA DO MOVIMENTO (job SFPJ0200)"
export DD_SFPMOV=dados/SFPMOV.DAT
export DD_SFPMOVA=saidas/SFPMOVA.DAT
export DD_SFPMOVR=saidas/SFPMOVR.DAT
export DD_SFPLOG=saidas/SFPLOG.TXT
export DD_SYSIN=dados/SYSIN.DAT
./build/SFP0200
avalia $? SFP0200

#-----------------------------------------------------------------#
banner "PASSO 2 - SFP0300 CALCULO DA FOLHA (job SFPJ0300)"
export DD_SFPMOV=saidas/SFPMOVA.DAT
export DD_SFPFOL=saidas/SFPFOL.DAT
export DD_SFPRES=saidas/SFPRES.DAT
export DD_SFPCRI=saidas/SFPCRI.TXT
export DD_SYSIN=dados/SYSIN.DAT
./build/SFP0300
avalia $? SFP0300

#-----------------------------------------------------------------#
banner "PASSO 3 - SFP0350 RESCISOES DO PERIODO (job SFPJ0400)"
export DD_SFPMOV=dados/SFPMOV.DAT
export DD_SFPRSC=saidas/SFPRSC.DAT
export DD_SFPTRC=saidas/SFPTRC.TXT
export DD_SYSIN=dados/SYSIN.DAT
./build/SFP0350
avalia $? SFP0350

#-----------------------------------------------------------------#
banner "PASSO 4 - SFP0400 FECHAMENTO CONTABIL (job SFPJ0400)"
export DD_SFPFOL=saidas/SFPFOL.DAT
export DD_SFPRES=saidas/SFPRES.DAT
export DD_SFPCTB=saidas/SFPCTB.DAT
export DD_SFPRCT=saidas/SFPRCT.TXT
export DD_SYSIN=dados/SYSIN400.DAT
./build/SFP0400
avalia $? SFP0400

#-----------------------------------------------------------------#
banner "PASSO 5 - SFP0500 CONTRACHEQUES (job SFPJ0500)"
export DD_SFPREL=saidas/SFPREL.TXT
./build/SFP0500
avalia $? SFP0500

#-----------------------------------------------------------------#
banner "PASSO 6 - SFP0600 REMESSA CNAB240 (job SFPJ0500)"
export DD_SFPCNAB=saidas/SFPCNAB.REM
./build/SFP0600
avalia $? SFP0600

#-----------------------------------------------------------------#
banner "RESUMO DAS SAIDAS GERADAS EM ./saidas"
ls -1 saidas | while read a; do
    printf "  %-16s %8s bytes  %6s registros\n" \
           "$a" "$(stat -c%s saidas/$a)" "$(wc -l < saidas/$a)"
done

echo ""
echo "RETURN CODE GERAL DA CADEIA: $RC_GERAL"
exit $RC_GERAL
