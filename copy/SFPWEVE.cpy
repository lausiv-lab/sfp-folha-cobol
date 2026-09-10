      *================================================================*
      * COPYBOOK : SFPWEVE  - CADASTRO DE EVENTOS / RUBRICAS           *
      * ORGANIZ. : SEQUENCIAL (QSAM)  - LRECL 080                      *
      * O CAMPO EVE-TIPO-CALCULO E O SELETOR DO MOTOR DE CALCULO       *
      *================================================================*
       01  REG-EVENTO.
           05  EVE-CODIGO                  PIC 9(004).
           05  EVE-DESCRICAO               PIC X(030).
           05  EVE-NATUREZA                PIC X(001).
               88  EVE-PROVENTO                VALUE 'P'.
               88  EVE-DESCONTO                VALUE 'D'.
               88  EVE-INFORMATIVO             VALUE 'I'.
               88  EVE-BASE                    VALUE 'B'.
           05  EVE-TIPO-CALCULO            PIC 9(003).
           05  EVE-INCIDENCIAS.
               10  EVE-INC-INSS            PIC X(001).
               10  EVE-INC-IRRF            PIC X(001).
               10  EVE-INC-FGTS            PIC X(001).
               10  EVE-INC-DSR             PIC X(001).
               10  EVE-INC-13O             PIC X(001).
               10  EVE-INC-FERIAS          PIC X(001).
           05  EVE-UNIDADE                 PIC X(002).
               88  EVE-UNID-HORA               VALUE 'HR'.
               88  EVE-UNID-DIA                VALUE 'DI'.
               88  EVE-UNID-PERC               VALUE 'PC'.
               88  EVE-UNID-VALOR              VALUE 'VL'.
           05  EVE-PERCENTUAL              PIC 9(003)V99.
           05  EVE-CONTA-CONTABIL          PIC 9(008).
           05  EVE-SITUACAO                PIC X(001).
           05  EVE-FILLER                  PIC X(020).
