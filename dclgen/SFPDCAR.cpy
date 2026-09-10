      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_CARGO)                                  *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDCAR))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-CARGO) APOST              *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_CARGO TABLE
           ( COD_CARGO                      SMALLINT NOT NULL,
             DESCRICAO                      CHAR(35) NOT NULL,
             CBO                            DECIMAL(6, 0) NOT NULL,
             NIVEL                          CHAR(1) NOT NULL,
             PISO_SALARIAL                  DECIMAL(11, 2) NOT NULL,
             TETO_SALARIAL                  DECIMAL(11, 2) NOT NULL,
             CARGA_HOR_MES                  SMALLINT NOT NULL,
             IND_INSALUBRID                 CHAR(1) NOT NULL,
             PERC_INSALUBRID                SMALLINT NOT NULL,
             IND_PERICULOSID                CHAR(1) NOT NULL,
             IND_CONFIANCA                  CHAR(1) NOT NULL,
             COD_CBO_FAMILIA                SMALLINT NOT NULL,
             DT_CRIACAO                     DATE NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-CARGO.
           10 DCLCA-COD-CARGO      PIC S9(4) USAGE COMP.
           10 DCLCA-DESCRICAO      PIC X(35).
           10 DCLCA-CBO            PIC S9(6)V USAGE COMP-3.
           10 DCLCA-NIVEL          PIC X(1).
           10 DCLCA-PISO-SALARIAL  PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLCA-TETO-SALARIAL  PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLCA-CARGA-HOR-MES  PIC S9(4) USAGE COMP.
           10 DCLCA-IND-INSALUBRID PIC X(1).
           10 DCLCA-PERC-INSALUBRID PIC S9(4) USAGE COMP.
           10 DCLCA-IND-PERICULOSID PIC X(1).
           10 DCLCA-IND-CONFIANCA  PIC X(1).
           10 DCLCA-COD-CBO-FAMILIA PIC S9(4) USAGE COMP.
           10 DCLCA-DT-CRIACAO     PIC X(10).
           10 DCLCA-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 14      *
      ******************************************************************
