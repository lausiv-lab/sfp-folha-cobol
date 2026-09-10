      *================================================================*
      * COPYBOOK : SFPWCAR  - CADASTRO DE CARGOS                       *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: CAR-CODIGO            *
      * LRECL    : 120                                                 *
      *----------------------------------------------------------------*
      * O PISO E O TETO SAO USADOS PELA TELA SFP0100 PARA CRITICAR O   *
      * SALARIO INFORMADO NA ADMISSAO E NA ALTERACAO DE CARGO.         *
      *================================================================*
       01  REG-CARGO.
           05  CAR-CHAVE.
               10  CAR-CODIGO              PIC 9(004).
           05  CAR-DESCRICAO               PIC X(035).
           05  CAR-CBO                     PIC 9(006).
           05  CAR-NIVEL                   PIC X(001).
               88  CAR-OPERACIONAL             VALUE 'O'.
               88  CAR-TECNICO                 VALUE 'T'.
               88  CAR-ESPECIALISTA            VALUE 'E'.
               88  CAR-GERENCIAL               VALUE 'G'.
               88  CAR-DIRETIVO                VALUE 'D'.
           05  CAR-PISO-SALARIAL           PIC 9(009)V99.
           05  CAR-TETO-SALARIAL           PIC 9(009)V99.
           05  CAR-CARGA-HOR-MES           PIC 9(003).
           05  CAR-IND-INSALUBRID          PIC X(001).
           05  CAR-PERC-INSALUBRID         PIC 9(002).
           05  CAR-IND-PERICULOSID         PIC X(001).
           05  CAR-IND-CONFIANCA           PIC X(001).
           05  CAR-COD-CBO-FAMILIA         PIC 9(004).
           05  CAR-DT-CRIACAO              PIC 9(008).
           05  CAR-SITUACAO                PIC X(001).
               88  CAR-ATIVO                   VALUE 'A'.
               88  CAR-EXTINTO                 VALUE 'E'.
           05  CAR-FILLER                  PIC X(031).
