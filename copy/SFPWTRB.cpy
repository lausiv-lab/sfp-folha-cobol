      *================================================================*
      * COPYBOOK : SFPWTRB - AREA DE COMUNICACAO COM O PROGRAMA        *
      *            SFP0310 (CALCULO DE INSS / IRRF / FGTS)             *
      * USO      : CALL 'SFP0310' USING AREA-TRIBUTOS                  *
      *================================================================*
       01  AREA-TRIBUTOS.
           05  TRB-FUNCAO                  PIC X(004).
               88  TRB-CARREGA-TABELAS         VALUE 'LOAD'.
               88  TRB-CALCULA-INSS            VALUE 'INSS'.
               88  TRB-CALCULA-IRRF            VALUE 'IRRF'.
               88  TRB-CALCULA-FGTS            VALUE 'FGTS'.
               88  TRB-CALCULA-SALFAM          VALUE 'SFAM'.
               88  TRB-CALCULA-13O-INSS        VALUE 'I13O'.
           05  TRB-COMPETENCIA             PIC 9(006).
      *--- ENTRADA -----------------------------------------------------
           05  TRB-BASE-CALCULO            PIC 9(009)V99.
           05  TRB-QTD-DEPENDENTES         PIC 9(002).
           05  TRB-VLR-INSS-DEDUZIR        PIC 9(009)V99.
           05  TRB-VLR-PENSAO-DEDUZIR      PIC 9(009)V99.
           05  TRB-VLR-REMUN-SALFAM        PIC 9(009)V99.
           05  TRB-QTD-FILHOS-SALFAM       PIC 9(002).
      *--- SAIDA -------------------------------------------------------
           05  TRB-VLR-CALCULADO           PIC 9(009)V99.
           05  TRB-ALIQUOTA-NOMINAL        PIC 9(003)V99.
           05  TRB-ALIQUOTA-EFETIVA        PIC 9(003)V99.
           05  TRB-FAIXA-APLICADA          PIC 9(002).
           05  TRB-BASE-APURADA            PIC 9(009)V99.
           05  TRB-VLR-DEDUCOES            PIC 9(009)V99.
           05  TRB-METODO-IRRF             PIC X(001).
               88  TRB-IRRF-LEGAL              VALUE 'L'.
               88  TRB-IRRF-SIMPLIFICADO       VALUE 'S'.
               88  TRB-IRRF-ISENTO             VALUE 'I'.
      *--- CONTROLE ----------------------------------------------------
           05  TRB-COD-RETORNO             PIC 9(002).
               88  TRB-OK                      VALUE 00.
               88  TRB-ERRO-TABELA             VALUE 10.
               88  TRB-ERRO-FUNCAO             VALUE 20.
               88  TRB-ERRO-BASE               VALUE 30.
           05  TRB-MSG-RETORNO             PIC X(060).
