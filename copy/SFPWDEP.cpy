      *================================================================*
      * COPYBOOK : SFPWDEP  - DEPENDENTES DO EMPREGADO                 *
      * ORGANIZ. : SEQUENCIAL - LRECL 080                              *
      *================================================================*
       01  REG-DEPENDENTE.
           05  DEP-MATRICULA               PIC 9(008).
           05  DEP-SEQUENCIA               PIC 9(002).
           05  DEP-NOME                    PIC X(035).
           05  DEP-DT-NASCIMENTO           PIC 9(008).
           05  DEP-GRAU-PARENTESCO         PIC 9(002).
           05  DEP-IND-IRRF                PIC X(001).
           05  DEP-IND-SALARIO-FAM         PIC X(001).
           05  DEP-IND-PLANO-SAUDE         PIC X(001).
           05  DEP-VLR-PLANO-SAUDE         PIC 9(007)V99.
           05  DEP-FILLER                  PIC X(013).
