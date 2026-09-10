//SFPPCOMP PROC MEMBRO=,
//             ALTA='SFP.PROD',
//             LOADLIB='SFP.PROD.LOADLIB',
//             COPYLIB='SFP.PROD.COPYLIB',
//             DBRMLIB='SFP.PROD.DBRMLIB',
//             SYSOUT='*'
//*=================================================================*
//* PROC   : SFPPCOMP                                               *
//* FUNCAO : COMPILACAO DE MODULO COBOL BATCH COM DB2               *
//*          PASSOS: PRECOMPILADOR DB2, COMPILADOR, LINKEDIT        *
//*=================================================================*
//*----------------------------------------------------------------*
//* PASSO 1 - PRECOMPILADOR DB2                                     *
//*----------------------------------------------------------------*
//PC       EXEC PGM=DSNHPC,
//             PARM='HOST(COB2),SOURCE,XREF,APOST'
//STEPLIB  DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=&DBRMLIB.(&MEMBRO),DISP=SHR
//SYSCIN   DD DSN=&&SRCOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSLIB   DD DSN=&COPYLIB,DISP=SHR
//         DD DSN=&ALTA..DCLGEN,DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSTERM  DD SYSOUT=&SYSOUT
//SYSUDUMP DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT2   DD UNIT=SYSDA,SPACE=(800,(500,500))
//*----------------------------------------------------------------*
//* PASSO 2 - COMPILADOR COBOL                                      *
//*----------------------------------------------------------------*
//COB      EXEC PGM=IGYCRCTL,COND=(4,LT,PC),
//             PARM=('LIB,APOST,RENT,MAP,XREF,LIST,OFFSET',
//             'NOSEQ,TRUNC(BIN),SSRANGE,OPT(2)')
//STEPLIB  DD DSN=IGY.V6R4M0.SIGYCOMP,DISP=SHR
//SYSIN    DD DSN=&&SRCOUT,DISP=(OLD,DELETE)
//SYSLIB   DD DSN=&COPYLIB,DISP=SHR
//         DD DSN=&ALTA..DCLGEN,DISP=SHR
//SYSLIN   DD DSN=&&OBJ,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUDUMP DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT2   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT3   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT4   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT5   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT6   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT7   DD UNIT=SYSDA,SPACE=(800,(500,500))
//*----------------------------------------------------------------*
//* PASSO 3 - LINKAGE EDITOR                                        *
//*----------------------------------------------------------------*
//LKED     EXEC PGM=IEWL,COND=((4,LT,PC),(4,LT,COB)),
//             PARM='LIST,XREF,LET,MAP,RENT'
//SYSLIN   DD DSN=&&OBJ,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=&LOADLIB.(&MEMBRO),DISP=SHR
//SYSLIB   DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//         DD DSN=&LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(1024,(200,20))
//         PEND
