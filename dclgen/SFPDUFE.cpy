      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_UF)                                     *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDUFE))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-UF) APOST                 *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_UF TABLE
           ( UF                             CHAR(2) NOT NULL,
             NOME                           CHAR(25) NOT NULL,
             COD_IBGE                       SMALLINT NOT NULL,
             REGIAO                         CHAR(12) NOT NULL,
             CAPITAL                        CHAR(25) NOT NULL,
             ALIQ_ICMS                      DECIMAL(4, 2) NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-UF.
           10 DCLUF-UF             PIC X(2).
           10 DCLUF-NOME           PIC X(25).
           10 DCLUF-COD-IBGE       PIC S9(4) USAGE COMP.
           10 DCLUF-REGIAO         PIC X(12).
           10 DCLUF-CAPITAL        PIC X(25).
           10 DCLUF-ALIQ-ICMS      PIC S9(2)V9(2) USAGE COMP-3.
           10 DCLUF-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 7       *
      ******************************************************************
