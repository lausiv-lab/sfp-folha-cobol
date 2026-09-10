      *================================================================*
      * COPYBOOK : SFPWRSC  - SOLICITACAO DE RESCISAO CONTRATUAL       *
      * ORGANIZ. : SEQUENCIAL CLASSIFICADO POR MATRICULA               *
      * LRECL    : 080                                                 *
      *================================================================*
       01  REG-RESCISAO.
           05  RSC-MATRICULA               PIC 9(008).
           05  RSC-DT-DESLIGAMENTO         PIC 9(008).
           05  RSC-COD-MOTIVO              PIC 9(002).
               88  RSC-SEM-JUSTA-CAUSA         VALUE 01.
               88  RSC-PEDIDO-DEMISSAO         VALUE 02.
               88  RSC-JUSTA-CAUSA             VALUE 03.
               88  RSC-TERMINO-EXPERIEN        VALUE 04.
               88  RSC-ACORDO-484A             VALUE 05.
               88  RSC-APOSENTADORIA           VALUE 06.
               88  RSC-MOTIVO-VALIDO           VALUE 01 THRU 06.
           05  RSC-IND-AVISO               PIC X(001).
               88  RSC-AVISO-TRABALHADO        VALUE 'T'.
               88  RSC-AVISO-INDENIZADO        VALUE 'I'.
               88  RSC-AVISO-DISPENSADO        VALUE 'D'.
               88  RSC-AVISO-DESCONTADO        VALUE 'X'.
           05  RSC-IND-FER-VENCIDAS        PIC X(001).
           05  RSC-DIAS-FER-VENCIDAS       PIC 9(002).
           05  RSC-DT-BASE-FERIAS          PIC 9(008).
           05  RSC-SALDO-FGTS-INFO         PIC 9(009)V99.
           05  RSC-USUARIO                 PIC X(008).
           05  RSC-FILLER                  PIC X(031).
