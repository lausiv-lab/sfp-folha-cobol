      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_DEPARTAMENTO)                           *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDDPT))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-DEPARTAMENTO) APOST       *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_DEPARTAMENTO TABLE
           ( COD_DEPTO                      SMALLINT NOT NULL,
             DESCRICAO                      CHAR(35) NOT NULL,
             CENTRO_CUSTO                   DECIMAL(6, 0) NOT NULL,
             COD_ESTABELEC                  SMALLINT NOT NULL,
             MATR_RESPONSAVEL               DECIMAL(8, 0) NOT NULL,
             DPT_SUPERIOR                   SMALLINT NOT NULL,
             CONTA_CONTABIL                 DECIMAL(8, 0) NOT NULL,
             IND_RATEIO                     CHAR(1) NOT NULL,
             DT_CRIACAO                     DATE NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-DEPARTAMENTO.
           10 DCLDP-COD-DEPTO      PIC S9(4) USAGE COMP.
           10 DCLDP-DESCRICAO      PIC X(35).
           10 DCLDP-CENTRO-CUSTO   PIC S9(6)V USAGE COMP-3.
           10 DCLDP-COD-ESTABELEC  PIC S9(4) USAGE COMP.
           10 DCLDP-MATR-RESPONSAVEL PIC S9(8)V USAGE COMP-3.
           10 DCLDP-DPT-SUPERIOR   PIC S9(4) USAGE COMP.
           10 DCLDP-CONTA-CONTABIL PIC S9(8)V USAGE COMP-3.
           10 DCLDP-IND-RATEIO     PIC X(1).
           10 DCLDP-DT-CRIACAO     PIC X(10).
           10 DCLDP-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10      *
      ******************************************************************
