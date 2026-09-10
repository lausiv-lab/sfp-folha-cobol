      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_EMPREGADO_COMPL)                        *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDEMC))                       *
      *        LANGUAGE(COBOL)                                         *
      *        STRUCTURE(DCL-EMPREGADO-COMPL)                          *
      *        APOST                                                   *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_EMPREGADO_COMPL TABLE
           ( MATRICULA                      DECIMAL(8, 0) NOT NULL,
             ESTADO_CIVIL                   CHAR(1) NOT NULL,
             RACA_COR                       SMALLINT NOT NULL,
             NACIONALIDADE                  SMALLINT NOT NULL,
             UF_NASCIMENTO                  CHAR(2) NOT NULL,
             MUN_NASCIMENTO                 DECIMAL(7, 0) NOT NULL,
             NOME_MAE                       CHAR(40) NOT NULL,
             IND_DEFICIENCIA                CHAR(1) NOT NULL,
             TIPO_DEFICIENCIA               SMALLINT NOT NULL,
             CTPS_NUMERO                    DECIMAL(8, 0) NOT NULL,
             CTPS_SERIE                     DECIMAL(5, 0) NOT NULL,
             CTPS_UF                        CHAR(2) NOT NULL,
             RG_NUMERO                      CHAR(15) NOT NULL,
             RG_ORGAO                       CHAR(8) NOT NULL,
             TITULO_ELEITOR                 DECIMAL(12, 0) NOT NULL,
             TIPO_LOGRADOURO                CHAR(3) NOT NULL,
             LOGRADOURO                     CHAR(40) NOT NULL,
             NUMERO                         CHAR(8) NOT NULL,
             COMPLEMENTO                    CHAR(15) NOT NULL,
             BAIRRO                         CHAR(25) NOT NULL,
             COD_MUNICIPIO                  DECIMAL(7, 0) NOT NULL,
             UF                             CHAR(2) NOT NULL,
             CEP                            DECIMAL(8, 0) NOT NULL,
             TELEFONE                       CHAR(14) NOT NULL,
             COD_ESTABELEC                  SMALLINT NOT NULL,
             TIPO_VINCULO                   SMALLINT NOT NULL,
             TIPO_JORNADA                   SMALLINT NOT NULL,
             COD_HORARIO                    SMALLINT NOT NULL,
             TS_ATUALIZACAO                 TIMESTAMP NOT NULL,
             USUARIO_ATUALIZ                CHAR(8) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE SFPADM.TB_EMPREGADO_COMPL          *
      ******************************************************************
       01  DCL-EMPREGADO-COMPL.
           10 DCL-C-MATRICULA      PIC S9(8)V USAGE COMP-3.
           10 DCL-C-ESTADO-CIVIL   PIC X(1).
           10 DCL-C-RACA-COR       PIC S9(4) USAGE COMP.
           10 DCL-C-NACIONALIDADE  PIC S9(4) USAGE COMP.
           10 DCL-C-UF-NASCIMENTO  PIC X(2).
           10 DCL-C-MUN-NASCIMENTO PIC S9(7)V USAGE COMP-3.
           10 DCL-C-NOME-MAE       PIC X(40).
           10 DCL-C-IND-DEFICIENCIA PIC X(1).
           10 DCL-C-TIPO-DEFICIENCIA PIC S9(4) USAGE COMP.
           10 DCL-C-CTPS-NUMERO    PIC S9(8)V USAGE COMP-3.
           10 DCL-C-CTPS-SERIE     PIC S9(5)V USAGE COMP-3.
           10 DCL-C-CTPS-UF        PIC X(2).
           10 DCL-C-RG-NUMERO      PIC X(15).
           10 DCL-C-RG-ORGAO       PIC X(8).
           10 DCL-C-TITULO-ELEITOR PIC S9(12)V USAGE COMP-3.
           10 DCL-C-TIPO-LOGRADOURO PIC X(3).
           10 DCL-C-LOGRADOURO     PIC X(40).
           10 DCL-C-NUMERO         PIC X(8).
           10 DCL-C-COMPLEMENTO    PIC X(15).
           10 DCL-C-BAIRRO         PIC X(25).
           10 DCL-C-COD-MUNICIPIO  PIC S9(7)V USAGE COMP-3.
           10 DCL-C-UF             PIC X(2).
           10 DCL-C-CEP            PIC S9(8)V USAGE COMP-3.
           10 DCL-C-TELEFONE       PIC X(14).
           10 DCL-C-COD-ESTABELEC  PIC S9(4) USAGE COMP.
           10 DCL-C-TIPO-VINCULO   PIC S9(4) USAGE COMP.
           10 DCL-C-TIPO-JORNADA   PIC S9(4) USAGE COMP.
           10 DCL-C-COD-HORARIO    PIC S9(4) USAGE COMP.
           10 DCL-C-TS-ATUALIZACAO PIC X(26).
           10 DCL-C-USUARIO-ATUALI PIC X(8).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 30      *
      ******************************************************************
