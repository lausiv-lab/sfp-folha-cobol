      *================================================================*
      * COPYBOOK : SFPWCON - CONSTANTES CORPORATIVAS DO SISTEMA SFP    *
      *================================================================*
       01  CONSTANTES-SFP.
           05  CTE-EMPRESA-NOME            PIC X(040) VALUE
               'INDUSTRIA MERIDIONAL DE COMPONENTES S/A '.
           05  CTE-EMPRESA-CNPJ            PIC 9(014)
                                           VALUE 74829163000178.
           05  CTE-SISTEMA                 PIC X(003) VALUE 'SFP'.
           05  CTE-VERSAO                  PIC X(008) VALUE 'V04.R02 '.
      *--- CODIGOS DE EVENTO UTILIZADOS PELO MOTOR --------------------
           05  CTE-EVENTOS.
               10  CTE-EV-SAL-MENSAL       PIC 9(004) VALUE 0001.
               10  CTE-EV-SAL-HORISTA      PIC 9(004) VALUE 0002.
               10  CTE-EV-DIAS-TRAB        PIC 9(004) VALUE 0003.
               10  CTE-EV-HE-050           PIC 9(004) VALUE 0010.
               10  CTE-EV-HE-100           PIC 9(004) VALUE 0011.
               10  CTE-EV-DSR-HE           PIC 9(004) VALUE 0012.
               10  CTE-EV-AD-NOTURNO       PIC 9(004) VALUE 0013.
               10  CTE-EV-DSR-NOTURNO      PIC 9(004) VALUE 0014.
               10  CTE-EV-INSALUBRID       PIC 9(004) VALUE 0020.
               10  CTE-EV-PERICULOSID      PIC 9(004) VALUE 0021.
               10  CTE-EV-QUINQUENIO       PIC 9(004) VALUE 0022.
               10  CTE-EV-SAL-FAMILIA      PIC 9(004) VALUE 0030.
               10  CTE-EV-COMISSAO         PIC 9(004) VALUE 0040.
               10  CTE-EV-GRATIFICACAO     PIC 9(004) VALUE 0041.
               10  CTE-EV-13O-INTEGRAL     PIC 9(004) VALUE 0050.
               10  CTE-EV-FERIAS-GOZO      PIC 9(004) VALUE 0060.
               10  CTE-EV-TERCO-FERIAS     PIC 9(004) VALUE 0061.
               10  CTE-EV-FALTAS           PIC 9(004) VALUE 0500.
               10  CTE-EV-DSR-FALTAS       PIC 9(004) VALUE 0501.
               10  CTE-EV-ATRASOS          PIC 9(004) VALUE 0502.
               10  CTE-EV-INSS             PIC 9(004) VALUE 0510.
               10  CTE-EV-IRRF             PIC 9(004) VALUE 0511.
               10  CTE-EV-VALE-TRANSP      PIC 9(004) VALUE 0520.
               10  CTE-EV-VALE-REFEIC      PIC 9(004) VALUE 0521.
               10  CTE-EV-PLANO-SAUDE      PIC 9(004) VALUE 0522.
               10  CTE-EV-PENSAO-ALIM      PIC 9(004) VALUE 0530.
               10  CTE-EV-CONSIGNADO       PIC 9(004) VALUE 0531.
               10  CTE-EV-ADIANTAMENTO     PIC 9(004) VALUE 0532.
               10  CTE-EV-CONTR-SINDIC     PIC 9(004) VALUE 0540.
               10  CTE-EV-ARRED-ANTER      PIC 9(004) VALUE 0550.
               10  CTE-EV-SALDO-DEVEDOR    PIC 9(004) VALUE 0551.
               10  CTE-EV-BASE-INSS        PIC 9(004) VALUE 0900.
               10  CTE-EV-BASE-IRRF        PIC 9(004) VALUE 0901.
               10  CTE-EV-BASE-FGTS        PIC 9(004) VALUE 0902.
               10  CTE-EV-FGTS-MES         PIC 9(004) VALUE 0903.
               10  CTE-EV-LIQUIDO          PIC 9(004) VALUE 0999.
      *--- OS MESMOS CODIGOS VISTOS COMO TABELA -----------------------
      * O SFP0110 PERCORRE ESTA REDEFINICAO PARA RECUSAR A EXCLUSAO E
      * A INATIVACAO DE RUBRICA CITADA PELO MOTOR DE CALCULO. QUEM
      * ACRESCENTAR UM CTE-EV- ACIMA TEM DE AJUSTAR O OCCURS E O
      * CTE-QTD-EV-MOTOR ABAIXO.
           05  CTE-EVENTOS-TAB REDEFINES CTE-EVENTOS.
               10  CTE-EV-MOTOR OCCURS 36 TIMES PIC 9(004).
           05  CTE-QTD-EV-MOTOR            PIC 9(002) VALUE 36.
