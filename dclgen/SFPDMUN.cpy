      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_MUNICIPIO)                              *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDMUN))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-MUNICIPIO) APOST          *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_MUNICIPIO TABLE
           ( COD_IBGE                       DECIMAL(7, 0) NOT NULL,
             UF                             CHAR(2) NOT NULL,
             NOME                           CHAR(40) NOT NULL,
             COD_SIAFI                      SMALLINT NOT NULL,
             IND_CAPITAL                    CHAR(1) NOT NULL,
             CEP_INICIAL                    DECIMAL(8, 0) NOT NULL,
             CEP_FINAL                      DECIMAL(8, 0) NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-MUNICIPIO.
           10 DCLMU-COD-IBGE       PIC S9(7)V USAGE COMP-3.
           10 DCLMU-UF             PIC X(2).
           10 DCLMU-NOME           PIC X(40).
           10 DCLMU-COD-SIAFI      PIC S9(4) USAGE COMP.
           10 DCLMU-IND-CAPITAL    PIC X(1).
           10 DCLMU-CEP-INICIAL    PIC S9(8)V USAGE COMP-3.
           10 DCLMU-CEP-FINAL      PIC S9(8)V USAGE COMP-3.
           10 DCLMU-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 8       *
      ******************************************************************
