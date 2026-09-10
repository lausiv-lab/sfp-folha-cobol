      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_FOLHA_RESUMO)                           *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDRES))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-RESUMO) APOST             *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_FOLHA_RESUMO TABLE
           ( COMPETENCIA                    DECIMAL(6, 0) NOT NULL,
             TIPO_FOLHA                     CHAR(1) NOT NULL,
             MATRICULA                      DECIMAL(8, 0) NOT NULL,
             NOME                           CHAR(40) NOT NULL,
             CENTRO_CUSTO                   DECIMAL(6, 0) NOT NULL,
             SALARIO_BASE                   DECIMAL(11, 2) NOT NULL,
             TOT_PROVENTOS                  DECIMAL(11, 2) NOT NULL,
             TOT_DESCONTOS                  DECIMAL(11, 2) NOT NULL,
             LIQUIDO                        DECIMAL(11, 2) NOT NULL,
             BASE_INSS                      DECIMAL(11, 2) NOT NULL,
             BASE_IRRF                      DECIMAL(11, 2) NOT NULL,
             BASE_FGTS                      DECIMAL(11, 2) NOT NULL,
             VLR_INSS                       DECIMAL(11, 2) NOT NULL,
             VLR_IRRF                       DECIMAL(11, 2) NOT NULL,
             VLR_FGTS                       DECIMAL(11, 2) NOT NULL,
             VLR_SAL_FAMILIA                DECIMAL(9, 2) NOT NULL,
             ALIQ_INSS_EFET                 DECIMAL(5, 2) NOT NULL,
             ALIQ_IRRF                      DECIMAL(5, 2) NOT NULL,
             QTD_EVENTOS                    SMALLINT NOT NULL,
             BANCO                          SMALLINT NOT NULL,
             AGENCIA                        DECIMAL(5, 0) NOT NULL,
             CONTA                          DECIMAL(12, 0) NOT NULL,
             DIG_CONTA                      CHAR(1) NOT NULL,
             CPF                            DECIMAL(11, 0) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-RESUMO.
           10 DCLR-COMPETENCIA     PIC S9(6)V USAGE COMP-3.
           10 DCLR-TIPO-FOLHA      PIC X(1).
           10 DCLR-MATRICULA       PIC S9(8)V USAGE COMP-3.
           10 DCLR-NOME            PIC X(40).
           10 DCLR-CENTRO-CUSTO    PIC S9(6)V USAGE COMP-3.
           10 DCLR-SALARIO-BASE    PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-TOT-PROVENTOS   PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-TOT-DESCONTOS   PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-LIQUIDO         PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-BASE-INSS       PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-BASE-IRRF       PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-BASE-FGTS       PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-VLR-INSS        PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-VLR-IRRF        PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-VLR-FGTS        PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLR-VLR-SAL-FAMIL   PIC S9(7)V9(2) USAGE COMP-3.
           10 DCLR-ALIQ-INSS-EFE   PIC S9(3)V9(2) USAGE COMP-3.
           10 DCLR-ALIQ-IRRF       PIC S9(3)V9(2) USAGE COMP-3.
           10 DCLR-QTD-EVENTOS     PIC S9(4) USAGE COMP.
           10 DCLR-BANCO           PIC S9(4) USAGE COMP.
           10 DCLR-AGENCIA         PIC S9(5)V USAGE COMP-3.
           10 DCLR-CONTA           PIC S9(12)V USAGE COMP-3.
           10 DCLR-DIG-CONTA       PIC X(1).
           10 DCLR-CPF             PIC S9(11)V USAGE COMP-3.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 24      *
      ******************************************************************
