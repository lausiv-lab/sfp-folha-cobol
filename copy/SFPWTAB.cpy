      *================================================================*
      * COPYBOOK : SFPWTAB  - TABELAS LEGAIS E PARAMETROS DO SISTEMA   *
      * ORGANIZ. : SEQUENCIAL - LRECL 080                              *
      * TIPOS    : PAR=PARAMETRO INS=INSS IRF=IRRF SFA=SALARIO FAMILIA *
      *================================================================*
       01  REG-TABELA.
           05  TAB-TIPO                    PIC X(003).
               88  TAB-PARAMETRO               VALUE 'PAR'.
               88  TAB-INSS                    VALUE 'INS'.
               88  TAB-IRRF                    VALUE 'IRF'.
               88  TAB-SAL-FAMILIA             VALUE 'SFA'.
           05  TAB-COMPETENCIA             PIC 9(006).
           05  TAB-SEQUENCIA               PIC 9(002).
           05  TAB-CHAVE                   PIC X(015).
           05  TAB-LIMITE                  PIC 9(009)V99.
           05  TAB-ALIQUOTA                PIC 9(003)V99.
           05  TAB-DEDUCAO                 PIC 9(009)V99.
           05  TAB-DESCRICAO               PIC X(027).
