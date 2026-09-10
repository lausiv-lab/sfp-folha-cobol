//SFPPCICS PROC MEMBRO=,
//             ALTA='SFP.PROD',
//             LOADLIB='SFP.PROD.LOADLIB',
//             COPYLIB='SFP.PROD.COPYLIB',
//             DBRMLIB='SFP.PROD.DBRMLIB',
//             SYSOUT='*'
//*=================================================================*
//* PROC   : SFPPCICS                                               *
//* FUNCAO : COMPILACAO DE MODULO COBOL CICS COM DB2                *
//*          PASSOS: TRADUTOR CICS, PRECOMPILADOR DB2, COMPILADOR,  *
//*                  LINKEDIT COM O STUB DFHECI                     *
//*=================================================================*
//*----------------------------------------------------------------*
//* PASSO 1 - TRADUTOR DE COMANDOS CICS                             *
//*----------------------------------------------------------------*
//TRN      EXEC PGM=DFHECP1$,
//             PARM='COBOL3,APOST,SP'
//STEPLIB  DD DSN=CICSTS.V6R1.SDFHLOAD,DISP=SHR
//SYSIN    DD DSN=&ALTA..COBOL(&MEMBRO),DISP=SHR
//SYSPUNCH DD DSN=&&TRNOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSPRINT DD SYSOUT=&SYSOUT
//*----------------------------------------------------------------*
//* PASSO 2 - PRECOMPILADOR DB2                                     *
//*----------------------------------------------------------------*
//PC       EXEC PGM=DSNHPC,COND=(4,LT,TRN),
//             PARM='HOST(COB2),SOURCE,XREF,APOST'
//STEPLIB  DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//DBRMLIB  DD DSN=&DBRMLIB.(&MEMBRO),DISP=SHR
//SYSIN    DD DSN=&&TRNOUT,DISP=(OLD,DELETE)
//SYSCIN   DD DSN=&&SRCOUT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSLIB   DD DSN=&COPYLIB,DISP=SHR
//         DD DSN=&ALTA..DCLGEN,DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSTERM  DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT2   DD UNIT=SYSDA,SPACE=(800,(500,500))
//*----------------------------------------------------------------*
//* PASSO 3 - COMPILADOR COBOL                                      *
//*----------------------------------------------------------------*
//COB      EXEC PGM=IGYCRCTL,COND=((4,LT,TRN),(4,LT,PC)),
//             PARM=('LIB,APOST,RENT,MAP,XREF,NODYNAM',
//             'NOSEQ,TRUNC(BIN),OPT(2)')
//STEPLIB  DD DSN=IGY.V6R4M0.SIGYCOMP,DISP=SHR
//SYSIN    DD DSN=&&SRCOUT,DISP=(OLD,DELETE)
//SYSLIB   DD DSN=&COPYLIB,DISP=SHR
//         DD DSN=&ALTA..DCLGEN,DISP=SHR
//         DD DSN=CICSTS.V6R1.SDFHCOB,DISP=SHR
//         DD DSN=CICSTS.V6R1.SDFHMAC,DISP=SHR
//SYSLIN   DD DSN=&&OBJ,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT2   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT3   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT4   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT5   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT6   DD UNIT=SYSDA,SPACE=(800,(500,500))
//SYSUT7   DD UNIT=SYSDA,SPACE=(800,(500,500))
//*----------------------------------------------------------------*
//* PASSO 4 - LINKAGE EDITOR COM O STUB DO CICS                     *
//*----------------------------------------------------------------*
//LKED     EXEC PGM=IEWL,COND=((4,LT,TRN),(4,LT,PC),(4,LT,COB)),
//             PARM='LIST,XREF,LET,MAP,RENT'
//SYSLIN   DD DSN=CICSTS.V6R1.SDFHCOB(DFHECI),DISP=SHR
//         DD DSN=&&OBJ,DISP=(OLD,DELETE)
//         DD DDNAME=SYSIN
//SYSLMOD  DD DSN=&LOADLIB.(&MEMBRO),DISP=SHR
//SYSLIB   DD DSN=CICSTS.V6R1.SDFHLOAD,DISP=SHR
//         DD DSN=CEE.SCEELKED,DISP=SHR
//         DD DSN=DSN.V13.SDSNLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(1024,(200,20))
//         PEND
