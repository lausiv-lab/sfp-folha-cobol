      *================================================================*
      * COPYBOOK : SFPWPON  - APURACAO DO PONTO ELETRONICO             *
      * ORGANIZ. : SEQUENCIAL - LRECL 080                              *
      *================================================================*
       01  REG-PONTO.
           05  PON-MATRICULA               PIC 9(008).
           05  PON-COMPETENCIA             PIC 9(006).
           05  PON-DIAS-TRABALHADOS        PIC 9(003).
           05  PON-DIAS-UTEIS-MES          PIC 9(003).
           05  PON-HORAS-NORMAIS           PIC 9(005)V99.
           05  PON-HE-050                  PIC 9(005)V99.
           05  PON-HE-100                  PIC 9(005)V99.
           05  PON-HORAS-NOTURNAS          PIC 9(005)V99.
           05  PON-FALTAS-DIAS             PIC 9(003).
           05  PON-ATRASOS-MIN             PIC 9(005).
           05  PON-DSR-PERDIDOS            PIC 9(003).
           05  PON-DIAS-AFASTAM            PIC 9(003).
           05  PON-DIAS-FERIAS             PIC 9(003).
           05  PON-FILLER                  PIC X(015).
