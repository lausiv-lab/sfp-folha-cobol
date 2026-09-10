      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_EVENTO)                                 *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDEVE))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-EVENTO) APOST             *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_EVENTO TABLE
           ( COD_EVENTO                     SMALLINT NOT NULL,
             DESCRICAO                      CHAR(30) NOT NULL,
             NATUREZA                       CHAR(1) NOT NULL,
             TIPO_CALCULO                   SMALLINT NOT NULL,
             INC_INSS                       CHAR(1) NOT NULL,
             INC_IRRF                       CHAR(1) NOT NULL,
             INC_FGTS                       CHAR(1) NOT NULL,
             INC_DSR                        CHAR(1) NOT NULL,
             INC_13O                        CHAR(1) NOT NULL,
             INC_FERIAS                     CHAR(1) NOT NULL,
             UNIDADE                        CHAR(2) NOT NULL,
             PERCENTUAL                     DECIMAL(5, 2) NOT NULL,
             CONTA_CONTABIL                 DECIMAL(8, 0) NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-EVENTO.
           10 DCLEV-COD-EVENTO     PIC S9(4) USAGE COMP.
           10 DCLEV-DESCRICAO      PIC X(30).
           10 DCLEV-NATUREZA       PIC X(1).
           10 DCLEV-TIPO-CALCULO   PIC S9(4) USAGE COMP.
           10 DCLEV-INC-INSS       PIC X(1).
           10 DCLEV-INC-IRRF       PIC X(1).
           10 DCLEV-INC-FGTS       PIC X(1).
           10 DCLEV-INC-DSR        PIC X(1).
           10 DCLEV-INC-13O        PIC X(1).
           10 DCLEV-INC-FERIAS     PIC X(1).
           10 DCLEV-UNIDADE        PIC X(2).
           10 DCLEV-PERCENTUAL     PIC S9(3)V9(2) USAGE COMP-3.
           10 DCLEV-CONTA-CONTABIL PIC S9(8)V USAGE COMP-3.
           10 DCLEV-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 14      *
      ******************************************************************
