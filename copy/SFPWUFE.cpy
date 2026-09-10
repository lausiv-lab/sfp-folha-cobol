      *================================================================*
      * COPYBOOK : SFPWUFE  - UNIDADES DA FEDERACAO                    *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: UFE-SIGLA             *
      * LRECL    : 080                                                 *
      *================================================================*
       01  REG-UF.
           05  UFE-CHAVE.
               10  UFE-SIGLA               PIC X(002).
           05  UFE-NOME                    PIC X(025).
           05  UFE-COD-IBGE                PIC 9(002).
           05  UFE-REGIAO                  PIC X(012).
           05  UFE-CAPITAL                 PIC X(025).
           05  UFE-ALIQ-ICMS               PIC 9(002)V99.
           05  UFE-SITUACAO                PIC X(001).
           05  UFE-FILLER                  PIC X(009).
