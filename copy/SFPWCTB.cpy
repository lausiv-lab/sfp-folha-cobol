      *================================================================*
      * COPYBOOK : SFPWCTB  - INTERFACE CONTABIL (PARTIDAS DOBRADAS)   *
      * ORGANIZ. : SEQUENCIAL - LRECL 150                              *
      * REGRA    : CADA REGISTRO E UM PAR DEBITO/CREDITO EQUILIBRADO.  *
      *            A SOMA DOS DEBITOS DEVE IGUALAR A DOS CREDITOS.     *
      *================================================================*
       01  REG-CONTABIL.
           05  CTB-COMPETENCIA             PIC 9(006).
           05  CTB-DATA-LANCAMENTO         PIC 9(008).
           05  CTB-LOTE                    PIC 9(006).
           05  CTB-SEQUENCIA               PIC 9(006).
           05  CTB-CONTA-DEBITO            PIC 9(008).
           05  CTB-CONTA-CREDITO           PIC 9(008).
           05  CTB-CENTRO-CUSTO            PIC 9(006).
           05  CTB-VALOR                   PIC 9(013)V99.
           05  CTB-HISTORICO               PIC X(060).
           05  CTB-ORIGEM                  PIC X(003).
           05  CTB-TIPO-LANCAMENTO         PIC X(001).
               88  CTB-PROVENTO                VALUE 'P'.
               88  CTB-DESCONTO                VALUE 'D'.
               88  CTB-ENCARGO                 VALUE 'E'.
               88  CTB-PROVISAO                VALUE 'V'.
           05  CTB-FILLER                  PIC X(023).
