      *================================================================*
      * COPYBOOK : SFPWRES  - RESUMO DA FOLHA POR EMPREGADO            *
      * ORGANIZ. : SEQUENCIAL - LRECL 250                              *
      *================================================================*
       01  REG-RESUMO.
           05  RES-COMPETENCIA             PIC 9(006).
           05  RES-TIPO-FOLHA              PIC X(001).
           05  RES-MATRICULA               PIC 9(008).
           05  RES-NOME                    PIC X(040).
           05  RES-CENTRO-CUSTO            PIC 9(006).
           05  RES-SALARIO-BASE            PIC 9(009)V99.
           05  RES-TOT-PROVENTOS           PIC 9(009)V99.
           05  RES-TOT-DESCONTOS           PIC 9(009)V99.
           05  RES-LIQUIDO                 PIC S9(009)V99.
           05  RES-BASE-INSS               PIC 9(009)V99.
           05  RES-BASE-IRRF               PIC 9(009)V99.
           05  RES-BASE-FGTS               PIC 9(009)V99.
           05  RES-VLR-INSS                PIC 9(009)V99.
           05  RES-VLR-IRRF                PIC 9(009)V99.
           05  RES-VLR-FGTS                PIC 9(009)V99.
           05  RES-VLR-SAL-FAMILIA         PIC 9(007)V99.
           05  RES-ALIQ-INSS-EFET          PIC 9(003)V99.
           05  RES-ALIQ-IRRF               PIC 9(003)V99.
           05  RES-QTD-EVENTOS             PIC 9(003).
           05  RES-BANCO                   PIC 9(003).
           05  RES-AGENCIA                 PIC 9(005).
           05  RES-CONTA                   PIC 9(012).
           05  RES-DIG-CONTA               PIC X(001).
           05  RES-CPF                     PIC 9(011).
           05  RES-FILLER                  PIC X(025).
