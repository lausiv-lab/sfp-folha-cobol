      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_DOMINIO)                                *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDDOM))                       *
      *        LANGUAGE(COBOL) STRUCTURE(DCL-DOMINIO) APOST            *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_DOMINIO TABLE
           ( TIPO_DOMINIO                   CHAR(3) NOT NULL,
             COD_DOMINIO                    CHAR(6) NOT NULL,
             DESCRICAO                      CHAR(35) NOT NULL,
             DESCR_REDUZ                    CHAR(12) NOT NULL,
             ORDEM                          SMALLINT NOT NULL,
             VALOR_AUX                      CHAR(10) NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL,
             IND_SISTEMA                    CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
       01  DCL-DOMINIO.
           10 DCLDO-TIPO-DOMINIO   PIC X(3).
           10 DCLDO-COD-DOMINIO    PIC X(6).
           10 DCLDO-DESCRICAO      PIC X(35).
           10 DCLDO-DESCR-REDUZ    PIC X(12).
           10 DCLDO-ORDEM          PIC S9(4) USAGE COMP.
           10 DCLDO-VALOR-AUX      PIC X(10).
           10 DCLDO-SITUACAO       PIC X(1).
           10 DCLDO-IND-SISTEMA    PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 8       *
      ******************************************************************
