      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_ESTABELEC)                              *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDEST))                       *
      *        LANGUAGE(COBOL)                                         *
      *        STRUCTURE(DCL-ESTABELEC)                                *
      *        APOST                                                   *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_ESTABELEC TABLE
           ( COD_ESTABELEC                  SMALLINT NOT NULL,
             TIPO_ESTABELEC                 CHAR(1) NOT NULL,
             CNPJ                           DECIMAL(14, 0) NOT NULL,
             RAZAO_SOCIAL                   CHAR(60) NOT NULL,
             NOME_FANTASIA                  CHAR(40) NOT NULL,
             INSC_ESTADUAL                  CHAR(15) NOT NULL,
             INSC_MUNICIPAL                 CHAR(15) NOT NULL,
             TIPO_LOGRADOURO                CHAR(3) NOT NULL,
             LOGRADOURO                     CHAR(40) NOT NULL,
             NUMERO                         CHAR(8) NOT NULL,
             COMPLEMENTO                    CHAR(15) NOT NULL,
             BAIRRO                         CHAR(25) NOT NULL,
             COD_MUNICIPIO                  DECIMAL(7, 0) NOT NULL,
             UF                             CHAR(2) NOT NULL,
             CEP                            DECIMAL(8, 0) NOT NULL,
             TELEFONE                       CHAR(14) NOT NULL,
             EMAIL                          CHAR(40) NOT NULL,
             CNAE                           DECIMAL(7, 0) NOT NULL,
             COD_FPAS                       SMALLINT NOT NULL,
             COD_TERCEIROS                  SMALLINT NOT NULL,
             ALIQ_RAT                       DECIMAL(4, 2) NOT NULL,
             FAP                            DECIMAL(5, 4) NOT NULL,
             ALIQ_TERCEIROS                 DECIMAL(4, 2) NOT NULL,
             IND_SIMPLES                    CHAR(1) NOT NULL,
             IND_DESONERACAO                CHAR(1) NOT NULL,
             CNPJ_SINDICATO                 DECIMAL(14, 0) NOT NULL,
             NOME_SINDICATO                 CHAR(40) NOT NULL,
             MES_DATA_BASE                  SMALLINT NOT NULL,
             PERC_CONTR_SIND                DECIMAL(5, 2) NOT NULL,
             DIA_PAGAMENTO                  SMALLINT NOT NULL,
             DIA_ADIANTAMENTO               SMALLINT NOT NULL,
             BANCO_PAGADOR                  SMALLINT NOT NULL,
             AGENCIA_PAGADORA               DECIMAL(5, 0) NOT NULL,
             CONTA_PAGADORA                 DECIMAL(12, 0) NOT NULL,
             DIG_CONTA                      CHAR(1) NOT NULL,
             COD_CONVENIO                   CHAR(20) NOT NULL,
             DT_INICIO_ATIV                 DATE,
             SITUACAO                       CHAR(1) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE SFPADM.TB_ESTABELEC                *
      ******************************************************************
       01  DCL-ESTABELEC.
           10 DCLES-COD-ESTABELEC  PIC S9(4) USAGE COMP.
           10 DCLES-TIPO-ESTABELEC PIC X(1).
           10 DCLES-CNPJ           PIC S9(14)V USAGE COMP-3.
           10 DCLES-RAZAO-SOCIAL   PIC X(60).
           10 DCLES-NOME-FANTASIA  PIC X(40).
           10 DCLES-INSC-ESTADUAL  PIC X(15).
           10 DCLES-INSC-MUNICIPAL PIC X(15).
           10 DCLES-TIPO-LOGRADOURO PIC X(3).
           10 DCLES-LOGRADOURO     PIC X(40).
           10 DCLES-NUMERO         PIC X(8).
           10 DCLES-COMPLEMENTO    PIC X(15).
           10 DCLES-BAIRRO         PIC X(25).
           10 DCLES-COD-MUNICIPIO  PIC S9(7)V USAGE COMP-3.
           10 DCLES-UF             PIC X(2).
           10 DCLES-CEP            PIC S9(8)V USAGE COMP-3.
           10 DCLES-TELEFONE       PIC X(14).
           10 DCLES-EMAIL          PIC X(40).
           10 DCLES-CNAE           PIC S9(7)V USAGE COMP-3.
           10 DCLES-COD-FPAS       PIC S9(4) USAGE COMP.
           10 DCLES-COD-TERCEIROS  PIC S9(4) USAGE COMP.
           10 DCLES-ALIQ-RAT       PIC S9(2)V9(2) USAGE COMP-3.
           10 DCLES-FAP            PIC S9(1)V9(4) USAGE COMP-3.
           10 DCLES-ALIQ-TERCEIROS PIC S9(2)V9(2) USAGE COMP-3.
           10 DCLES-IND-SIMPLES    PIC X(1).
           10 DCLES-IND-DESONERACAO PIC X(1).
           10 DCLES-CNPJ-SINDICATO PIC S9(14)V USAGE COMP-3.
           10 DCLES-NOME-SINDICATO PIC X(40).
           10 DCLES-MES-DATA-BASE  PIC S9(4) USAGE COMP.
           10 DCLES-PERC-CONTR-SIND PIC S9(3)V9(2) USAGE COMP-3.
           10 DCLES-DIA-PAGAMENTO  PIC S9(4) USAGE COMP.
           10 DCLES-DIA-ADIANTAMENTO PIC S9(4) USAGE COMP.
           10 DCLES-BANCO-PAGADOR  PIC S9(4) USAGE COMP.
           10 DCLES-AGENCIA-PAGADORA PIC S9(5)V USAGE COMP-3.
           10 DCLES-CONTA-PAGADORA PIC S9(12)V USAGE COMP-3.
           10 DCLES-DIG-CONTA      PIC X(1).
           10 DCLES-COD-CONVENIO   PIC X(20).
           10 DCLES-DT-INICIO-ATIV PIC X(10).
           10 DCLES-SITUACAO       PIC X(1).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 38      *
      ******************************************************************
