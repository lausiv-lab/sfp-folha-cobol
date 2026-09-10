      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0000                                             *
      * TRANSACAO: SFPM                                                *
      * MAPSET   : SFPM00   MAPA: MAPMENU                              *
      * FUNCAO   : MENU PRINCIPAL E ROTEADOR DAS TRANSACOES DO SFP     *
      * TIPO     : CICS - PSEUDOCONVERSACIONAL                         *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE O TRADUTOR CICS ANTES DO COMPILADOR COBOL.   *
      *----------------------------------------------------------------*
      * O USUARIO PODE INFORMAR O NUMERO DA OPCAO OU DIGITAR DIRETO O  *
      * CODIGO DA TRANSACAO. AS DUAS FORMAS CONVERGEM PARA O MESMO     *
      * EXEC CICS XCTL, PASSANDO A COMMAREA PADRAO DO SISTEMA PARA     *
      * QUE O PROGRAMA CHAMADO SAIBA COMO VOLTAR AO MENU.              *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0000.
       AUTHOR. EQUIPE SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *
       01  WS-CONSTANTES.
           05  WS-TRANSACAO        PIC X(004) VALUE 'SFPM'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0000 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM00 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPMENU'.
           05  WS-DESPEDIDA        PIC X(050) VALUE
               'SFP0000 - SESSAO ENCERRADA. ATE A PROXIMA.'.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM00.
      *
      *--- TABELA DE ROTEAMENTO ---------------------------------------
      * CADA ENTRADA LIGA A OPCAO DO MENU AO PROGRAMA E A TRANSACAO.
      * INCLUIR UMA FUNCAO NOVA NO SISTEMA E ACRESCENTAR UMA LINHA
      * AQUI E OUTRA NO MAPA, SEM MEXER NA LOGICA DO ROTEADOR.
      *----------------------------------------------------------------
       01  WS-TABELA-OPCOES.
           05  FILLER PIC X(020) VALUE '11SF05SFP0130 EMPRE'.
           05  FILLER PIC X(020) VALUE '12SF06SFP0140 CARGO'.
           05  FILLER PIC X(020) VALUE '13SF07SFP0145 DEPTO'.
           05  FILLER PIC X(020) VALUE '14SF08SFP0160 DOMIN'.
           05  FILLER PIC X(020) VALUE '21SF01SFP0100 EMPRE'.
           05  FILLER PIC X(020) VALUE '22SF02SFP0150 DEPEN'.
           05  FILLER PIC X(020) VALUE '23SF09SFP0170 CARGO'.
           05  FILLER PIC X(020) VALUE '24SF10SFP0180 DESLI'.
           05  FILLER PIC X(020) VALUE '31SF04SFP0110 RUBRI'.
           05  FILLER PIC X(020) VALUE '32SF03SFP0120 MOVIM'.
           05  FILLER PIC X(020) VALUE '33SF11SFP0190 TABLE'.
           05  FILLER PIC X(020) VALUE '34SF12SFP0195 COMPE'.
           05  FILLER PIC X(020) VALUE '41SF13SFP0200 FICHA'.
           05  FILLER PIC X(020) VALUE '42SF14SFP0210 ESPEL'.
           05  FILLER PIC X(020) VALUE '43SF15SFP0220 CRITI'.
      *
       01  FILLER REDEFINES WS-TABELA-OPCOES.
           05  WS-OPCAO OCCURS 15 TIMES INDEXED BY WS-IO.
               10  WS-OP-CODIGO    PIC X(002).
               10  WS-OP-TRANSACAO PIC X(004).
               10  WS-OP-PROGRAMA  PIC X(008).
               10  WS-OP-APELIDO   PIC X(006).
      *
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ACHOU            PIC X(001) VALUE 'N'.
           05  WS-PGM-DESTINO      PIC X(008) VALUE SPACES.
           05  WS-OPCAO-INF        PIC X(002) VALUE SPACES.
           05  WS-TRANS-INF        PIC X(004) VALUE SPACES.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-HORA-ABS         PIC S9(015) COMP-3 VALUE ZEROS.
           05  WS-DATA-FORM        PIC X(010) VALUE SPACES.
           05  WS-HORA-FORM        PIC X(008) VALUE SPACES.
      *
       COPY SFPWCOM.
      *
       LINKAGE SECTION.
       01  DFHCOMMAREA             PIC X(512).
      *
      *================================================================*
       PROCEDURE DIVISION.
      *================================================================*
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           EXEC CICS HANDLE ABEND LABEL(9999-ABEND) END-EXEC
      *
           IF EIBCALEN = ZEROS
               PERFORM 1000-PRIMEIRA-VEZ
           ELSE
               MOVE DFHCOMMAREA        TO COMMAREA-SFP
               PERFORM 2000-PROCESSAR-TECLA
           END-IF
      *
           PERFORM 8000-RETORNAR.
       0000-FIM.
           EXIT.
      *
       1000-PRIMEIRA-VEZ SECTION.
       1000-INICIO.
           INITIALIZE COMMAREA-SFP
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE EIBTRMID               TO COM-TERMINAL
           MOVE EIBTRMID               TO COM-USUARIO
           SET COM-PRIMEIRA-VEZ        TO TRUE
      *
           PERFORM 7000-OBTER-DATA-HORA
      *
           MOVE LOW-VALUES             TO MAPMENUO
           MOVE WS-DATA-FORM           TO MDATAO
           MOVE WS-HORA-FORM           TO MHORAO
           MOVE EIBTRMID               TO MUSERO
           MOVE 'INFORME A OPCAO OU A TRANSACAO E TECLE ENTER'
                                       TO MMENSAGO
      *
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPMENUO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       1000-FIM.
           EXIT.
      *
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           EVALUATE EIBAID
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR
               WHEN DFHCLEAR
                    PERFORM 1000-PRIMEIRA-VEZ
               WHEN DFHPF1
                    MOVE 'DIGITE O NUMERO DA OPCAO OU O CODIGO DA TRANS
      -             'ACAO DESEJADA'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-DATAONLY
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-ROTEAR
               WHEN OTHER
                    MOVE 'TECLA INVALIDA NESTE MENU'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPMENUI)
                RESP(WS-RESP)
           END-EXEC
      *
           MOVE SPACES                 TO WS-OPCAO-INF WS-TRANS-INF
      *
           IF MOPCAOI NOT = LOW-VALUES AND SPACES
               MOVE MOPCAOI            TO WS-OPCAO-INF
           END-IF
      *
           IF MTRANSI NOT = LOW-VALUES AND SPACES
               MOVE FUNCTION UPPER-CASE(MTRANSI) TO WS-TRANS-INF
           END-IF.
       3000-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 - ROTEAMENTO                                              *
      *================================================================*
       4000-ROTEAR SECTION.
       4000-INICIO.
           MOVE 'N'                    TO WS-ACHOU
           MOVE SPACES                 TO WS-PGM-DESTINO
      *
           IF WS-OPCAO-INF = SPACES AND WS-TRANS-INF = SPACES
               MOVE 'INFORME UMA OPCAO OU UMA TRANSACAO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MOPCAOA
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           PERFORM VARYING WS-IO FROM 1 BY 1
                   UNTIL WS-IO > 15 OR WS-ACHOU = 'S'
      *
               IF WS-OPCAO-INF NOT = SPACES
                   IF WS-OP-CODIGO(WS-IO) = WS-OPCAO-INF
                       MOVE 'S'        TO WS-ACHOU
                       MOVE WS-OP-PROGRAMA(WS-IO) TO WS-PGM-DESTINO
                   END-IF
               ELSE
                   IF WS-OP-TRANSACAO(WS-IO) = WS-TRANS-INF
                       MOVE 'S'        TO WS-ACHOU
                       MOVE WS-OP-PROGRAMA(WS-IO) TO WS-PGM-DESTINO
                   END-IF
               END-IF
           END-PERFORM
      *
           IF WS-ACHOU = 'N'
               MOVE 'OPCAO OU TRANSACAO INEXISTENTE NESTE MENU'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MOPCAOA
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           PERFORM 4100-TRANSFERIR.
       4000-FIM.
           EXIT.
      *
       4100-TRANSFERIR SECTION.
       4100-INICIO.
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE ZEROS                  TO COM-CONTADOR-ERROS
           SET COM-PRIMEIRA-VEZ        TO TRUE
           MOVE SPACES                 TO COM-AREA-TRABALHO
      *
           EXEC CICS XCTL
                PROGRAM(WS-PGM-DESTINO)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
                RESP(WS-RESP)
           END-EXEC
      *
      *--- SO CHEGA AQUI SE O XCTL FALHOU -----------------------------
           IF WS-RESP = DFHRESP(PGMIDERR)
               MOVE SPACES             TO WS-MENSAGEM
               STRING 'FUNCAO AINDA NAO IMPLANTADA NESTE AMBIENTE: '
                      WS-PGM-DESTINO
                      DELIMITED BY SIZE INTO WS-MENSAGEM
               MOVE WS-MENSAGEM        TO MMENSAGO
           ELSE
               MOVE 'FALHA AO TRANSFERIR O CONTROLE. AVISE O SUPORTE.'
                                       TO MMENSAGO
           END-IF
      *
           PERFORM 6200-ENVIAR-DATAONLY.
       4100-FIM.
           EXIT.
      *
       7000-OBTER-DATA-HORA SECTION.
       7000-INICIO.
           EXEC CICS ASKTIME ABSTIME(WS-HORA-ABS) END-EXEC
           EXEC CICS FORMATTIME
                ABSTIME(WS-HORA-ABS)
                DDMMYYYY(WS-DATA-FORM)
                DATESEP('/')
                TIME(WS-HORA-FORM)
                TIMESEP(':')
           END-EXEC.
       7000-FIM.
           EXIT.
      *
       6200-ENVIAR-DATAONLY SECTION.
       6200-INICIO.
           PERFORM 7000-OBTER-DATA-HORA
           MOVE WS-DATA-FORM           TO MDATAO
           MOVE WS-HORA-FORM           TO MHORAO
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPMENUO)
                DATAONLY CURSOR FREEKB ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
       5900-ENCERRAR SECTION.
       5900-INICIO.
           EXEC CICS SEND TEXT
                FROM(WS-DESPEDIDA) LENGTH(LENGTH OF WS-DESPEDIDA)
                ERASE FREEKB
           END-EXEC
           EXEC CICS RETURN END-EXEC.
       5900-FIM.
           EXIT.
      *
       8000-RETORNAR SECTION.
       8000-INICIO.
           EXEC CICS RETURN
                TRANSID(WS-TRANSACAO)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       8000-FIM.
           EXIT.
      *
       9999-ABEND SECTION.
       9999-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
           EXEC CICS SEND TEXT
                FROM(WS-DESPEDIDA) LENGTH(LENGTH OF WS-DESPEDIDA)
                ERASE FREEKB
           END-EXEC
           EXEC CICS RETURN END-EXEC.
       9999-FIM.
           EXIT.
