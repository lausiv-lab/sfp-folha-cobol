      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_MOVIMENTO)                              *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDMOV))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-MOVIMENTO) APOST          *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_MOVIMENTO TABLE
           ( MATRICULA                      DECIMAL(8, 0) NOT NULL,
             COMPETENCIA                    DECIMAL(6, 0) NOT NULL,
             COD_EVENTO                     SMALLINT NOT NULL,
             REFERENCIA                     DECIMAL(7, 2) NOT NULL,
             VALOR                          DECIMAL(11, 2) NOT NULL,
             TIPO_LANC                      CHAR(1) NOT NULL,
             ORIGEM                         CHAR(3) NOT NULL,
             DT_LANCAMENTO                  DATE NOT NULL,
             USUARIO                        CHAR(8) NOT NULL,
             SIT_CRITICA                    CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-MOVIMENTO.
           10 DCLM-MATRICULA       PIC S9(8)V USAGE COMP-3.
           10 DCLM-COMPETENCIA     PIC S9(6)V USAGE COMP-3.
           10 DCLM-COD-EVENTO      PIC S9(4) USAGE COMP.
           10 DCLM-REFERENCIA      PIC S9(5)V9(2) USAGE COMP-3.
           10 DCLM-VALOR           PIC S9(9)V9(2) USAGE COMP-3.
           10 DCLM-TIPO-LANC       PIC X(1).
           10 DCLM-ORIGEM          PIC X(3).
           10 DCLM-DT-LANCAMENTO   PIC X(10).
           10 DCLM-USUARIO         PIC X(8).
           10 DCLM-SIT-CRITICA     PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 10      *
      ******************************************************************
