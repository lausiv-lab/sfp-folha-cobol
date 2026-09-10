      ******************************************************************
      * DCLGEN TABLE(SFPADM.TB_EMPREGADO)                              *
      *        LIBRARY(SFP.PROD.DCLGEN(SFPDEMP))                       *
      *        LANGUAGE(COBOL)                                         *
      *        STRUCTURE(DCL-EMPREGADO)                                *
      *        APOST                                                   *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE SFPADM.TB_EMPREGADO TABLE
           ( MATRICULA                      DECIMAL(8, 0) NOT NULL,
             NOME                           CHAR(40) NOT NULL,
             CPF                            DECIMAL(11, 0) NOT NULL,
             PIS                            DECIMAL(11, 0) NOT NULL,
             DT_ADMISSAO                    DATE NOT NULL,
             DT_DEMISSAO                    DATE,
             DT_NASCIMENTO                  DATE NOT NULL,
             SITUACAO                       CHAR(1) NOT NULL,
             COD_CARGO                      SMALLINT NOT NULL,
             COD_DEPTO                      SMALLINT NOT NULL,
             CENTRO_CUSTO                   DECIMAL(6, 0) NOT NULL,
             SALARIO_BASE                   DECIMAL(11, 2) NOT NULL,
             TIPO_SALARIO                   CHAR(1) NOT NULL,
             CARGA_HOR_MES                  SMALLINT NOT NULL,
             QTD_DEP_IRRF                   SMALLINT NOT NULL,
             QTD_DEP_SALFAM                 SMALLINT NOT NULL,
             PERC_INSALUBRID                SMALLINT NOT NULL,
             IND_PERICULOSID                CHAR(1) NOT NULL,
             IND_VALE_TRANSP                CHAR(1) NOT NULL,
             VLR_VALE_TRANSP                DECIMAL(9, 2) NOT NULL,
             IND_VALE_REFEIC                CHAR(1) NOT NULL,
             VLR_VALE_REFEIC                DECIMAL(9, 2) NOT NULL,
             IND_PLANO_SAUDE                CHAR(1) NOT NULL,
             VLR_PLANO_SAUDE                DECIMAL(9, 2) NOT NULL,
             PERC_PENSAO                    DECIMAL(5, 2) NOT NULL,
             VLR_PENSAO_FIXO                DECIMAL(9, 2) NOT NULL,
             VLR_CONSIGNADO                 DECIMAL(9, 2) NOT NULL,
             QTD_PARC_CONSIG                SMALLINT NOT NULL,
             IND_ADIANTAMENTO               CHAR(1) NOT NULL,
             PERC_ADIANTAMENTO              SMALLINT NOT NULL,
             IND_SINDICALIZADO              CHAR(1) NOT NULL,
             BANCO                          SMALLINT NOT NULL,
             AGENCIA                        DECIMAL(5, 0) NOT NULL,
             CONTA                          DECIMAL(12, 0) NOT NULL,
             DIG_CONTA                      CHAR(1) NOT NULL,
             TIPO_CONTA                     CHAR(1) NOT NULL,
             CATEG_ESOCIAL                  SMALLINT NOT NULL,
             SEXO                           CHAR(1) NOT NULL,
             GRAU_INSTRUCAO                 SMALLINT NOT NULL,
             MEDIA_VARIAVEIS                DECIMAL(11, 2) NOT NULL,
             SALDO_FGTS                     DECIMAL(11, 2) NOT NULL,
             TS_ATUALIZACAO                 TIMESTAMP NOT NULL,
             USUARIO_ATUALIZ                CHAR(8) NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE SFPADM.TB_EMPREGADO                *
      ******************************************************************
       01  DCL-EMPREGADO.
           10 DCL-MATRICULA        PIC S9(8)V USAGE COMP-3.
           10 DCL-NOME             PIC X(40).
           10 DCL-CPF              PIC S9(11)V USAGE COMP-3.
           10 DCL-PIS              PIC S9(11)V USAGE COMP-3.
           10 DCL-DT-ADMISSAO      PIC X(10).
           10 DCL-DT-DEMISSAO      PIC X(10).
           10 DCL-DT-NASCIMENTO    PIC X(10).
           10 DCL-SITUACAO         PIC X(1).
           10 DCL-COD-CARGO        PIC S9(4) USAGE COMP.
           10 DCL-COD-DEPTO        PIC S9(4) USAGE COMP.
           10 DCL-CENTRO-CUSTO     PIC S9(6)V USAGE COMP-3.
           10 DCL-SALARIO-BASE     PIC S9(9)V9(2) USAGE COMP-3.
           10 DCL-TIPO-SALARIO     PIC X(1).
           10 DCL-CARGA-HOR-MES    PIC S9(4) USAGE COMP.
           10 DCL-QTD-DEP-IRRF     PIC S9(4) USAGE COMP.
           10 DCL-QTD-DEP-SALFAM   PIC S9(4) USAGE COMP.
           10 DCL-PERC-INSALUBRID  PIC S9(4) USAGE COMP.
           10 DCL-IND-PERICULOSID  PIC X(1).
           10 DCL-IND-VALE-TRANSP  PIC X(1).
           10 DCL-VLR-VALE-TRANSP  PIC S9(7)V9(2) USAGE COMP-3.
           10 DCL-IND-VALE-REFEIC  PIC X(1).
           10 DCL-VLR-VALE-REFEIC  PIC S9(7)V9(2) USAGE COMP-3.
           10 DCL-IND-PLANO-SAUDE  PIC X(1).
           10 DCL-VLR-PLANO-SAUDE  PIC S9(7)V9(2) USAGE COMP-3.
           10 DCL-PERC-PENSAO      PIC S9(3)V9(2) USAGE COMP-3.
           10 DCL-VLR-PENSAO-FIXO  PIC S9(7)V9(2) USAGE COMP-3.
           10 DCL-VLR-CONSIGNADO   PIC S9(7)V9(2) USAGE COMP-3.
           10 DCL-QTD-PARC-CONSIG  PIC S9(4) USAGE COMP.
           10 DCL-IND-ADIANTAMENTO PIC X(1).
           10 DCL-PERC-ADIANTAMEN  PIC S9(4) USAGE COMP.
           10 DCL-IND-SINDICALIZA  PIC X(1).
           10 DCL-BANCO            PIC S9(4) USAGE COMP.
           10 DCL-AGENCIA          PIC S9(5)V USAGE COMP-3.
           10 DCL-CONTA            PIC S9(12)V USAGE COMP-3.
           10 DCL-DIG-CONTA        PIC X(1).
           10 DCL-TIPO-CONTA       PIC X(1).
           10 DCL-CATEG-ESOCIAL    PIC S9(4) USAGE COMP.
           10 DCL-SEXO             PIC X(1).
           10 DCL-GRAU-INSTRUCAO   PIC S9(4) USAGE COMP.
           10 DCL-MEDIA-VARIAVEIS  PIC S9(9)V9(2) USAGE COMP-3.
           10 DCL-SALDO-FGTS       PIC S9(9)V9(2) USAGE COMP-3.
           10 DCL-TS-ATUALIZACAO   PIC X(26).
           10 DCL-USUARIO-ATUALIZ  PIC X(8).
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 43      *
      ******************************************************************
