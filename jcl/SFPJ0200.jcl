//SFPJ0200 JOB (SFP,FOLHA),'CRITICA MOVIMENTO',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,REGION=0M,
//             RESTART=*
//*=================================================================*
//* JOB    : SFPJ0200                                               *
//* FUNCAO : CRITICA E VALIDACAO DO MOVIMENTO MENSAL                *
//* PGM    : SFP0200                                                *
//* RC     : 00 SEM REJEICAO / 04 COM REJEICAO / 08 ERRO            *
//* NOTA   : RC 04 NAO INTERROMPE A CADEIA. O ANALISTA DEVE         *
//*          AVALIAR O RELATORIO ANTES DE LIBERAR O CALCULO.        *
//*=================================================================*
//*----------------------------------------------------------------*
//* PASSO 010 - ORDENA O MOVIMENTO POR MATRICULA E EVENTO           *
//*----------------------------------------------------------------*
//P010SORT EXEC PGM=SORT,REGION=64M
//SORTIN   DD DSN=SFP.PROD.MOVIMENTO.BRUTO,DISP=SHR
//SORTOUT  DD DSN=SFP.PROD.MOVIMENTO.ORDENADO,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(50,10),RLSE),
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=27900)
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=(1,8,ZD,A,15,4,ZD,A)
  SUM FIELDS=NONE
/*
//*----------------------------------------------------------------*
//* PASSO 020 - CRITICA DO MOVIMENTO                                *
//*----------------------------------------------------------------*
//P020CRIT EXEC PGM=SFP0200,REGION=0M,COND=(4,LT,P010SORT)
//STEPLIB  DD DSN=SFP.PROD.LOADLIB,DISP=SHR
//SFPEMP   DD DSN=SFP.PROD.CADASTRO.EMPREGADO,DISP=SHR
//SFPEVE   DD DSN=SFP.PROD.TABELA.EVENTO,DISP=SHR
//SFPMOV   DD DSN=SFP.PROD.MOVIMENTO.ORDENADO,DISP=SHR
//SFPPON   DD DSN=SFP.PROD.PONTO.APURADO,DISP=SHR
//SFPMOK   DD DSN=SFP.PROD.MOVIMENTO.ACEITO,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(50,10),RLSE),
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=27900)
//SFPMRJ   DD DSN=SFP.PROD.MOVIMENTO.REJEITADO,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=100,BLKSIZE=27900)
//SFPREL   DD SYSOUT=*,DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930)
//SYSIN    DD *
2026081000000010000000
/*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*----------------------------------------------------------------*
//* PASSO 030 - AVISO QUANDO EXISTEM REJEICOES                      *
//*----------------------------------------------------------------*
//P030AVIS EXEC PGM=IEBGENER,COND=(4,GT,P020CRIT)
//SYSUT1   DD *
ATENCAO: EXISTEM MOVIMENTOS REJEITADOS NA CRITICA.
CONSULTE O RELATORIO DO PASSO P020CRIT ANTES DE
LIBERAR A EXECUCAO DO JOB SFPJ0300 (CALCULO DA FOLHA).
/*
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//
