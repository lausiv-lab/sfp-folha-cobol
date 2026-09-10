      *================================================================*
      * COPYBOOK : SFPWUTL - AREA DE COMUNICACAO COM SFPUTIL           *
      *================================================================*
       01  AREA-UTILITARIOS.
           05  UTL-FUNCAO                  PIC X(004).
               88  UTL-VALIDA-CPF              VALUE 'VCPF'.
               88  UTL-VALIDA-DATA             VALUE 'VDAT'.
               88  UTL-DIFERENCA-DIAS          VALUE 'DDIA'.
               88  UTL-CALCULA-AVOS            VALUE 'AVOS'.
               88  UTL-FORMATA-DATA            VALUE 'FDAT'.
               88  UTL-VALOR-EXTENSO           VALUE 'EXTV'.
               88  UTL-DIGITO-MOD11            VALUE 'DV11'.
           05  UTL-CPF                     PIC 9(011).
           05  UTL-DATA-INI                PIC 9(008).
           05  UTL-DATA-FIM                PIC 9(008).
           05  UTL-QTD-DIAS                PIC S9(007).
           05  UTL-QTD-AVOS                PIC 9(002).
           05  UTL-VALOR                   PIC 9(009)V99.
           05  UTL-DATA-FORMATADA          PIC X(010).
           05  UTL-EXTENSO                 PIC X(180).
           05  UTL-NUMERO-DV               PIC 9(012).
           05  UTL-DIGITO                  PIC 9(001).
           05  UTL-COD-RETORNO             PIC 9(002).
               88  UTL-OK                      VALUE 00.
               88  UTL-INVALIDO                VALUE 10.
               88  UTL-FUNCAO-INVALIDA         VALUE 20.
           05  UTL-MENSAGEM                PIC X(060).
