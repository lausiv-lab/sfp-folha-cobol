//SFPJ0500 JOB (SFP,FOLHA),'CONTRACHEQUE E BANCO',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,REGION=0M
//*=================================================================*
//* JOB    : SFPJ0500                                               *
//* FUNCAO : EMISSAO DOS CONTRACHEQUES E GERACAO DA REMESSA CNAB240 *
//* PGMS   : SFP0500 (DEMONSTRATIVO) E SFP0600 (REMESSA BANCARIA)   *
//*=================================================================*
//*----------------------------------------------------------------*
//* PASSO 010 - ORDENA O RESUMO POR CENTRO DE CUSTO E NOME          *
//*----------------------------------------------------------------*
//P010SORT EXEC PGM=SORT,REGION=64M
//SORTIN   DD DSN=SFP.PROD.FOLHA.RESUMO,DISP=SHR
//SORTOUT  DD DSN=SFP.PROD.FOLHA.RESUMO.ORD,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(50,10),RLSE),
//            DCB=(RECFM=FB,LRECL=250,BLKSIZE=27750)
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=(56,6,ZD,A,16,40,CH,A)
/*
//*----------------------------------------------------------------*
//* PASSO 020 - EMISSAO DOS CONTRACHEQUES                           *
//*----------------------------------------------------------------*
//P020CONT EXEC PGM=SFP0500,REGION=0M,COND=(4,LT,P010SORT)
//STEPLIB  DD DSN=SFP.PROD.LOADLIB,DISP=SHR
//SFPRES   DD DSN=SFP.PROD.FOLHA.RESUMO.ORD,DISP=SHR
//SFPFOL   DD DSN=SFP.PROD.FOLHA.CALCULADA,DISP=SHR
//SFPREL   DD SYSOUT=A,DCB=(RECFM=FBA,LRECL=133,BLKSIZE=27930),
//            OUTLIM=500000
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*----------------------------------------------------------------*
//* PASSO 030 - GERACAO DA REMESSA BANCARIA CNAB240                 *
//*----------------------------------------------------------------*
//P030CNAB EXEC PGM=SFP0600,REGION=0M,COND=(4,LT,P010SORT)
//STEPLIB  DD DSN=SFP.PROD.LOADLIB,DISP=SHR
//SFPRES   DD DSN=SFP.PROD.FOLHA.RESUMO.ORD,DISP=SHR
//SFPCNAB  DD DSN=SFP.PROD.REMESSA.CNAB240,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=240,BLKSIZE=27840)
//SYSIN    DD *
20260805341
/*
//SYSOUT   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*----------------------------------------------------------------*
//* PASSO 040 - TRANSMISSAO DA REMESSA AO BANCO                     *
//*----------------------------------------------------------------*
//P040FTP  EXEC PGM=FTP,PARM='(EXIT',COND=(4,LT,P030CNAB)
//SYSPRINT DD SYSOUT=*
//OUTPUT   DD SYSOUT=*
//INPUT    DD DSN=SFP.PROD.CNTLLIB(FTPBANCO),DISP=SHR
//
