      *================================================================*
      * COPYBOOK : SFPWFOL  - FOLHA CALCULADA (DETALHE POR EVENTO)     *
      * ORGANIZ. : SEQUENCIAL - LRECL 120                              *
      *================================================================*
       01  REG-FOLHA.
           05  FOL-COMPETENCIA             PIC 9(006).
           05  FOL-TIPO-FOLHA              PIC X(001).
               88  FOL-MENSAL                  VALUE '1'.
               88  FOL-ADIANTAMENTO            VALUE '2'.
               88  FOL-13O-PRIMEIRA            VALUE '3'.
               88  FOL-13O-SEGUNDA             VALUE '4'.
               88  FOL-FER                     VALUE '5'.
               88  FOL-RESCISAO                VALUE '6'.
           05  FOL-MATRICULA               PIC 9(008).
           05  FOL-SEQUENCIA               PIC 9(003).
           05  FOL-COD-EVENTO              PIC 9(004).
           05  FOL-DESCRICAO               PIC X(030).
           05  FOL-NATUREZA                PIC X(001).
           05  FOL-REFERENCIA              PIC 9(005)V99.
           05  FOL-VALOR                   PIC 9(009)V99.
           05  FOL-CENTRO-CUSTO            PIC 9(006).
           05  FOL-CONTA-CONTABIL          PIC 9(008).
           05  FOL-FILLER                  PIC X(035).
