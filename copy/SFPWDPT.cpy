      *================================================================*
      * COPYBOOK : SFPWDPT  - CADASTRO DE DEPARTAMENTOS                *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: DPT-CODIGO            *
      * LRECL    : 120                                                 *
      *================================================================*
       01  REG-DEPARTAMENTO.
           05  DPT-CHAVE.
               10  DPT-CODIGO              PIC 9(004).
           05  DPT-DESCRICAO               PIC X(035).
           05  DPT-CENTRO-CUSTO            PIC 9(006).
           05  DPT-COD-ESTABELEC           PIC 9(004).
           05  DPT-MATR-RESPONSAVEL        PIC 9(008).
           05  DPT-DPT-SUPERIOR            PIC 9(004).
           05  DPT-CONTA-CONTABIL          PIC 9(008).
           05  DPT-IND-RATEIO              PIC X(001).
           05  DPT-DT-CRIACAO              PIC 9(008).
           05  DPT-SITUACAO                PIC X(001).
           05  DPT-FILLER                  PIC X(041).
