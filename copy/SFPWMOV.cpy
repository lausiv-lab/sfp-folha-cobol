      *================================================================*
      * COPYBOOK : SFPWMOV  - MOVIMENTO MENSAL DE FOLHA                *
      * ORGANIZ. : SEQUENCIAL CLASSIFICADO POR MATRICULA + EVENTO      *
      * LRECL    : 100                                                 *
      *================================================================*
       01  REG-MOVIMENTO.
           05  MOV-CHAVE.
               10  MOV-MATRICULA           PIC 9(008).
               10  MOV-COMPETENCIA         PIC 9(006).
               10  MOV-COD-EVENTO          PIC 9(004).
           05  MOV-REFERENCIA              PIC 9(005)V99.
           05  MOV-VALOR                   PIC 9(009)V99.
           05  MOV-TIPO-LANC               PIC X(001).
               88  MOV-FIXO                    VALUE 'F'.
               88  MOV-MENSAL                  VALUE 'M'.
               88  MOV-EVENTUAL                VALUE 'E'.
           05  MOV-ORIGEM                  PIC X(003).
           05  MOV-DATA-LANC               PIC 9(008).
           05  MOV-USUARIO                 PIC X(008).
           05  MOV-SIT-CRITICA             PIC X(001).
           05  MOV-FILLER                  PIC X(043).
