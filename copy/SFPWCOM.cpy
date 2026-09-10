      *================================================================*
      * COPYBOOK : SFPWCOM - COMMAREA DAS TRANSACOES CICS DO SFP       *
      * TAMANHO  : 512 BYTES                                           *
      *================================================================*
       01  COMMAREA-SFP.
           05  COM-TRANSACAO               PIC X(004).
           05  COM-PROGRAMA-ANTERIOR       PIC X(008).
           05  COM-USUARIO                 PIC X(008).
           05  COM-TERMINAL                PIC X(004).
           05  COM-FUNCAO                  PIC X(001).
               88  COM-INCLUSAO                VALUE 'I'.
               88  COM-ALTERACAO               VALUE 'A'.
               88  COM-CONSULTA                VALUE 'C'.
               88  COM-EXCLUSAO                VALUE 'E'.
               88  COM-FUNCAO-VALIDA           VALUE 'I' 'A' 'C' 'E'.
           05  COM-STATUS-TELA             PIC 9(002).
               88  COM-PRIMEIRA-VEZ            VALUE 00.
               88  COM-AGUARDA-DADOS           VALUE 10.
               88  COM-CONFIRMACAO             VALUE 20.
           05  COM-MATRICULA               PIC 9(008).
           05  COM-COMPETENCIA             PIC 9(006).
           05  COM-CHAVE-BROWSE            PIC 9(008).
           05  COM-CONTADOR-ERROS          PIC 9(003).
           05  COM-DATA-SESSAO             PIC 9(008).
           05  COM-HORA-SESSAO             PIC 9(006).
           05  COM-AREA-TRABALHO           PIC X(446).
