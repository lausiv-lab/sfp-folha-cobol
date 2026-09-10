//SFPPBMS  PROC MAPSET=,
//             ALTA='SFP.PROD',
//             LOADLIB='SFP.PROD.LOADLIB',
//             COPYLIB='SFP.PROD.COPYLIB',
//             SYSOUT='*'
//*=================================================================*
//* PROC   : SFPPBMS                                                *
//* FUNCAO : GERACAO DO MAPSET BMS EM DUAS PASSAGENS                *
//*          PASSO 1: DSECT  - COPYBOOK SIMBOLICO PARA O COBOL      *
//*          PASSO 2: MAP    - MODULO DE CARGA DO MAPA FISICO       *
//*=================================================================*
//ASMDSECT EXEC PGM=ASMA90,
//             PARM='SYSPARM(DSECT),DECK,NOOBJECT'
//SYSLIB   DD DSN=CICSTS.V6R1.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//SYSIN    DD DSN=&ALTA..BMS(&MAPSET),DISP=SHR
//SYSPUNCH DD DSN=&COPYLIB.(&MAPSET),DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(1700,(600,100))
//*----------------------------------------------------------------*
//ASMMAP   EXEC PGM=ASMA90,COND=(4,LT,ASMDSECT),
//             PARM='SYSPARM(MAP),DECK,NOOBJECT'
//SYSLIB   DD DSN=CICSTS.V6R1.SDFHMAC,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//SYSIN    DD DSN=&ALTA..BMS(&MAPSET),DISP=SHR
//SYSPUNCH DD DSN=&&MAPOBJ,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(800,(500,500)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=8000)
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(1700,(600,100))
//*----------------------------------------------------------------*
//LKED     EXEC PGM=IEWL,COND=((4,LT,ASMDSECT),(4,LT,ASMMAP)),
//             PARM='LIST,XREF,LET,MAP,RENT'
//SYSLIN   DD DSN=&&MAPOBJ,DISP=(OLD,DELETE)
//SYSLMOD  DD DSN=&LOADLIB.(&MAPSET),DISP=SHR
//SYSLIB   DD DSN=CICSTS.V6R1.SDFHLOAD,DISP=SHR
//SYSPRINT DD SYSOUT=&SYSOUT
//SYSUT1   DD UNIT=SYSDA,SPACE=(1024,(200,20))
//         PEND
