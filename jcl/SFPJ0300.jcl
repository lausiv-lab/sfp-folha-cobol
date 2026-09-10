//SFPJ0300 JOB (SFP,FOLHA),'CALCULO DA FOLHA',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,REGION=0M
//*=================================================================*
//* JOB    : SFPJ0300                                               *
//* FUNCAO : CALCULO MENSAL DA FOLHA DE PAGAMENTO                   *
//* PGM    : SFP0300 (CHAMA SFP0310 E SFPUTIL)                      *
//* ENTRADA: CADASTRO, DEPENDENTES, EVENTOS, MOVIMENTO ACEITO,      *
//*          PONTO APURADO E TABELAS LEGAIS                         *
//* SAIDA  : FOLHA CALCULADA, RESUMO E RELATORIO DE CRITICAS        *
//*=================================================================*
//*----------------------------------------------------------------*
//* PASSO 005 - BACKUP DA FOLHA DA COMPETENCIA ANTERIOR             *
//*----------------------------------------------------------------*
//P005BKP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  REPRO INDATASET(SFP.PROD.FOLHA.CALCULADA)  -
        OUTDATASET(SFP.PROD.FOLHA.CALCULADA.BKP)
  IF LASTCC = 12 THEN SET MAXCC = 0
/*
//*----------------------------------------------------------------*
//* PASSO 010 - CALCULO DA FOLHA                                    *
//*----------------------------------------------------------------*
//P010CALC EXEC PGM=SFP0300,REGION=0M
//STEPLIB  DD DSN=SFP.PROD.LOADLIB,DISP=SHR
//SFPEMP   DD DSN=SFP.PROD.CADASTRO.EMPREGADO,DISP=SHR
//SFPDEP   DD DSN=SFP.PROD.CADASTRO.DEPENDENTE,DISP=SHR
//SFPEVE   DD DSN=SFP.PROD.TABELA.EVENTO,DISP=SHR
//SFPMOV   DD DSN=SFP.PROD.MOVIMENTO.ACEITO,DISP=SHR
//SFPPON   DD DSN=SFP.PROD.PONTO.APURADO,DISP=SHR
//SFPTAB   DD DSN=SFP.PROD.TABELA.LEGAL,DISP=SHR
//SFPFOL   DD DSN=SFP.PROD.FOLHA.CALCULADA,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(200,50),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=27960)
//SFPRES   DD DSN=SFP.PROD.FOLHA.RESUMO,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(50,10),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=27750)
//SFPCRI   DD DSN=SFP.PROD.FOLHA.CRITICAS,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=27930)
//SYSIN    DD *
2026081
/*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*----------------------------------------------------------------*
//* PASSO 020 - LISTAGEM DAS CRITICAS DO CALCULO                    *
//*----------------------------------------------------------------*
//P020LIST EXEC PGM=IEBGENER,COND=(8,LE,P010CALC)
//SYSUT1   DD DSN=SFP.PROD.FOLHA.CRITICAS,DISP=SHR
//SYSUT2   DD SYSOUT=*,DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930)
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//*----------------------------------------------------------------*
//* PASSO 030 - CARGA DA FOLHA NO DB2                               *
//*----------------------------------------------------------------*
//P030LOAD EXEC PGM=DSNUTILB,REGION=0M,COND=(4,LT,P010CALC),
//             PARM='DB2P,SFPLFOL'
//STEPLIB  DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//UTPRINT  DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SFPFOL   DD DSN=SFP.PROD.FOLHA.CALCULADA,DISP=SHR
//SYSDISC  DD DSN=SFP.PROD.LOAD.DISCARD,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(10,5),RLSE)
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(100,50))
//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(100,50))
//SYSIN    DD DSN=SFP.PROD.CNTLLIB(SFPLFOL),DISP=SHR
//*----------------------------------------------------------------*
//* PASSO 040 - CARGA DO RESUMO NO DB2                              *
//*----------------------------------------------------------------*
//P040LRES EXEC PGM=DSNUTILB,REGION=0M,COND=(4,LT,P030LOAD),
//             PARM='DB2P,SFPLRES'
//STEPLIB  DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=*
//UTPRINT  DD SYSOUT=*
//SFPRES   DD DSN=SFP.PROD.FOLHA.RESUMO,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(50,20))
//SORTOUT  DD UNIT=SYSDA,SPACE=(CYL,(50,20))
//SYSIN    DD DSN=SFP.PROD.CNTLLIB(SFPLRES),DISP=SHR
//
