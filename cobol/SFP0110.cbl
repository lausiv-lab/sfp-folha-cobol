      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0110                                             *
      * TRANSACAO: SF04                                                *
      * MAPSET   : SFPM03   MAPA: MAPEVEN                              *
      * FUNCAO   : CADASTRO DE RUBRICAS / EVENTOS DA FOLHA             *
      *            FORMULARIO COM ACAO I, A, C E E                     *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE O TRADUTOR CICS ANTES DO COMPILADOR COBOL.   *
      * NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME. NAO USA DB2: A    *
      * RUBRICA MORA NO ARQUIVO VSAM SFPEVE, LIDO PELOS COMANDOS DE    *
      * ARQUIVO DO CICS, COMO NO SFP0140 E NO SFP0160.                 *
      *----------------------------------------------------------------*
      * A RUBRICA E O SELETOR DO MOTOR DE CALCULO: EVE-TIPO-CALCULO    *
      * ESCOLHE A FORMULA NO SFP0300 (SECAO 2220) E AS SEIS            *
      * INCIDENCIAS DIZEM EM QUE BASES O VALOR ENTRA. ERRAR AQUI       *
      * ERRA A FOLHA INTEIRA, POR ISSO A CRITICA E LONGA.              *
      *----------------------------------------------------------------*
      * O MAPA USA CTRL=(FREEKB,FRSET): NO RECEIVE SO VOLTAM OS        *
      * CAMPOS QUE O USUARIO DIGITOU. UM FORMULARIO QUE LESSE A TELA   *
      * INTEIRA APAGARIA O QUE NAO FOI REDIGITADO. POR ISSO A RUBRICA  *
      * EM EDICAO VIVE NA COMMAREA (WS-ESTADO) E CADA CAMPO SO E       *
      * SUBSTITUIDO QUANDO O COMPRIMENTO RECEBIDO (MxxxL) E MAIOR QUE  *
      * ZERO. CONSEQUENCIA ACEITA: A TELA NAO APAGA CONTEUDO, SO       *
      * SUBSTITUI. DIGITAR UM CODIGO DIFERENTE LIMPA O ESTADO, PARA    *
      * NAO SE ALTERAR UMA RUBRICA COM OS DADOS DA ANTERIOR.           *
      *----------------------------------------------------------------*
      * O PERCENTUAL CHEGA DO BMS EM CAMPO NUMERICO-EDITADO ZZ9,99     *
      * ALINHADO A ESQUERDA: MOVE DIRETO PARA 9(003)V99 DARIA VALOR    *
      * ERRADO. VER 7400-DE-EDITAR.                                    *
      *----------------------------------------------------------------*
      * A TECLA F4 ATENDE OS CAMPOS NATUREZA E UNIDADE. QUAL DELES     *
      * DECIDE-SE PELA LINHA DO CURSOR (EIBCPOSN): LINHA 5 E A         *
      * NATUREZA, LINHA 7 E A UNIDADE. A JANELA E O SFP0900.           *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO                                              *
      *  RN01 - CODIGO DA RUBRICA DE 0001 A 9999                       *
      *  RN02 - DESCRICAO OBRIGATORIA                                  *
      *  RN03 - NATUREZA CADASTRADA NO DOMINIO NAT (P, D, I, B)        *
      *  RN04 - TIPO DE CALCULO IMPLEMENTADO NO MOTOR                  *
      *  RN05 - UNIDADE CADASTRADA NO DOMINIO UNI                      *
      *  RN06 - TIPOS 002 E 005 EXIGEM PERCENTUAL MAIOR QUE ZERO       *
      *  RN07 - CONTA CONTABIL OBRIGATORIA EM PROVENTO E DESCONTO      *
      *  RN08 - DESCONTO EXIGE AS SEIS INCIDENCIAS EM N                *
      *  RN09 - INCIDENCIAS EM S OU N                                  *
      *  RN10 - SITUACAO EM A OU I                                     *
      *  RN11 - INCLUSAO NAO PODE DUPLICAR CODIGO                      *
      *  RN12 - CONSULTA, ALTERACAO E EXCLUSAO EXIGEM RUBRICA JA       *
      *         CADASTRADA                                             *
      *  RN13 - RUBRICA CITADA PELO MOTOR NAO PODE SER EXCLUIDA NEM    *
      *         INATIVADA                                              *
      *----------------------------------------------------------------*
      * A RN08 EXISTE PORQUE O INSS E A PENSAO ALIMENTICIA JA ENTRAM   *
      * NA BASE DO IRRF POR DENTRO DO SFP0310, VIA AREA-TRIBUTOS.      *
      * LIGAR AS FLAGS DE UM DESCONTO CAUSARIA DEDUCAO EM DOBRO.       *
      *                                                                *
      * A RN13 PERCORRE CTE-EVENTOS-TAB (COPYBOOK SFPWCON), QUE E A    *
      * LISTA DOS CODIGOS QUE O SFP0300 E O SFP0350 GERAM POR CONTA    *
      * PROPRIA. EXCLUIR OU INATIVAR UM DELES DERRUBARIA O CALCULO.    *
      * ALTERAR DESCRICAO, CONTA E PERCENTUAL CONTINUA PERMITIDO: E    *
      * ASSIM QUE SE REPARAMETRIZA HORA EXTRA E VALE-TRANSPORTE.       *
      *                                                                *
      * A RN04 ACEITA SO O QUE O MOTOR IMPLEMENTA (001 A 007 E 010).   *
      * A FAIXA 100 A 199 FICA RESERVADA AO CALCULO AUTOMATICO, COMO   *
      * AVISA A LINHA 21 DO MAPA.                                      *
      *                                                                *
      * A RN05 CRITICA CONTRA O DOMINIO UNI, NAO CONTRA OS NOMES DE    *
      * CONDICAO DO SFPWEVE: O DOMINIO TEM QT (QUANTIDADE), QUE NAO    *
      * TEM 88 NO COPYBOOK. QUEM MANDA E O CADASTRO.                   *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0110.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF04'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0110 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM03 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPEVEN'.
           05  WS-ARQUIVO          PIC X(008) VALUE 'SFPEVE  '.
           05  WS-ARQ-DOMINIO      PIC X(008) VALUE 'SFPDOM  '.
           05  WS-IDENTIFICACAO    PIC X(050) VALUE
               'SFP0110 - CADASTRO DE RUBRICAS - FIM DA SESSAO'.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM03.
      *
       COPY SFPWEVE.
      *
       COPY SFPWDOM.
      *
       COPY SFPWCON.
      *
      *--- RUBRICA EM EDICAO - VIVE NA COMMAREA DO BYTE 121 ------------
      * OS CAMPOS SEGUEM A ORDEM DO SFPWEVE PARA QUE WS-ES-INCID SEJA  *
      * MOVIDO DE UMA VEZ PARA EVE-INCIDENCIAS. A ORDEM DA TELA E      *
      * OUTRA (INSS, DSR, IRRF, 13o, FGTS, FERIAS) E NAO SERVE AQUI.   *
       01  WS-ESTADO.
           05  WS-ES-ACAO          PIC X(001) VALUE SPACES.
           05  WS-ES-CODIGO        PIC 9(004) VALUE ZEROS.
           05  WS-ES-DESCR         PIC X(030) VALUE SPACES.
           05  WS-ES-NATUR         PIC X(001) VALUE SPACES.
           05  WS-ES-TIPCAL        PIC 9(003) VALUE ZEROS.
           05  WS-ES-INCID.
               10  WS-ES-INC-INSS  PIC X(001) VALUE SPACES.
               10  WS-ES-INC-IRRF  PIC X(001) VALUE SPACES.
               10  WS-ES-INC-FGTS  PIC X(001) VALUE SPACES.
               10  WS-ES-INC-DSR   PIC X(001) VALUE SPACES.
               10  WS-ES-INC-13O   PIC X(001) VALUE SPACES.
               10  WS-ES-INC-FER   PIC X(001) VALUE SPACES.
           05  WS-ES-UNIDAD        PIC X(002) VALUE SPACES.
           05  WS-ES-PERCEN        PIC 9(003)V99 VALUE ZEROS.
           05  WS-ES-CONTA         PIC 9(008) VALUE ZEROS.
           05  WS-ES-SITUAC        PIC X(001) VALUE SPACES.
           05  WS-ES-LIDA          PIC X(001) VALUE SPACES.
               88  WS-ES-VEIO-DO-ARQUIVO       VALUE 'S'.
      *
      *--- AREA DE TRABALHO --------------------------------------------
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-LINHA-CURSOR     PIC S9(004) COMP VALUE ZEROS.
           05  WS-CODIGO-TELA      PIC 9(004) VALUE ZEROS.
           05  WS-ACAO-SALVA       PIC X(001) VALUE SPACES.
           05  WS-INT-OK           PIC X(001) VALUE 'N'.
           05  WS-DO-MOTOR         PIC X(001) VALUE 'N'.
               88  RUBRICA-DO-MOTOR    VALUE 'S'.
           05  WS-DESC-TIPO        PIC X(034) VALUE SPACES.
           05  WS-TIPO-OK          PIC X(001) VALUE 'N'.
           05  WS-DOM-TIPO         PIC X(003) VALUE SPACES.
           05  WS-DOM-CODIGO       PIC X(006) VALUE SPACES.
           05  WS-DOM-DESCR        PIC X(035) VALUE SPACES.
           05  WS-DOM-OK           PIC X(001) VALUE 'N'.
      *
      *--- DES-EDICAO DO PERCENTUAL (VER 7400) -------------------------
       01  WS-EDIT.
           05  WS-ED-CAMPO         PIC X(013) VALUE SPACES.
           05  WS-ED-COMPACTO      PIC X(013) VALUE SPACES.
           05  WS-ED-TAM           PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VIRGULA       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-INVALIDOS     PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-OK            PIC X(001) VALUE 'S'.
           05  WS-ED-INT-X         PIC X(009) VALUE SPACES.
           05  WS-ED-INT           PIC 9(009) VALUE ZEROS.
           05  WS-ED-CENT-X        PIC X(002) VALUE SPACES.
           05  WS-ED-CENT          PIC 9(002) VALUE ZEROS.
           05  WS-ED-TAM-INT       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-TAM-DEC       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VALOR         PIC 9(009)V99 VALUE ZEROS.
           05  WS-ED-LIMITE        PIC 9(009) VALUE ZEROS.
      *
       COPY SFPWCOM.
      *
       COPY SFPWLOK.
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
               MOVE COM-AREA-TRABALHO
                    (121:LENGTH OF WS-ESTADO) TO WS-ESTADO
               MOVE COM-AREA-TRABALHO
                    (1:LENGTH OF AREA-LOOKUP) TO AREA-LOOKUP
      *
               IF LOK-PGM-CHAMADOR = WS-PROGRAMA
                  AND NOT LOK-EM-CURSO
                   PERFORM 1100-VOLTA-DO-LOOKUP
               ELSE
                   PERFORM 2000-PROCESSAR-TECLA
               END-IF
           END-IF
      *
           PERFORM 8000-RETORNAR.
       0000-FIM.
           EXIT.
      *
      *================================================================*
      * 1000 - PRIMEIRO ACIONAMENTO                                    *
      *================================================================*
       1000-PRIMEIRA-VEZ SECTION.
       1000-INICIO.
           INITIALIZE COMMAREA-SFP
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE EIBTRMID               TO COM-TERMINAL
           SET COM-PRIMEIRA-VEZ        TO TRUE
      *
           INITIALIZE WS-ESTADO
           PERFORM 6000-LIMPAR-MAPA
           MOVE 'INFORME O CODIGO DA RUBRICA E A ACAO DESEJADA'
                                       TO MMENSAGO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - RETORNO DA JANELA F4 (SFP0900)                          *
      *                                                                *
      * O SFP0900 DEVOLVE O CONTROLE POR XCTL: ESTA E UMA NOVA ENTRADA *
      * NO PROGRAMA E A TELA PRECISA SER REMONTADA DO WS-ESTADO.       *
      * LOK-CAMPO-ORIGEM DIZ QUAL CAMPO PEDIU A JANELA.                *
      *----------------------------------------------------------------*
       1100-VOLTA-DO-LOOKUP SECTION.
       1100-INICIO.
           IF LOK-SELECIONOU
               EVALUATE LOK-CAMPO-ORIGEM
                   WHEN 'MNATUR'
                        MOVE LOK-COD-SELECIONADO(1:1)
                                       TO WS-ES-NATUR
                   WHEN 'MUNIDAD'
                        MOVE LOK-COD-SELECIONADO(1:2)
                                       TO WS-ES-UNIDAD
                   WHEN OTHER
                        CONTINUE
               END-EVALUATE
           END-IF
      *
           MOVE SPACES                 TO LOK-PGM-CHAMADOR
           SET LOK-EM-CURSO            TO TRUE
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
      *
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       1100-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - TRATAMENTO DA TECLA ACIONADA                            *
      *================================================================*
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           EVALUATE EIBAID
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR-TRANSACAO
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
               WHEN DFHPF4
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4700-CHAMAR-LOOKUP
               WHEN DFHPF5
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3100-CONSULTAR
               WHEN DFHPF6
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-GRAVAR
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 2100-EXECUTAR-ACAO
               WHEN OTHER
                    MOVE 'TECLA INVALIDA PARA ESTA TRANSACAO'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
       2100-EXECUTAR-ACAO SECTION.
       2100-INICIO.
           EVALUATE WS-ES-ACAO
               WHEN 'C' PERFORM 3100-CONSULTAR
               WHEN 'I' PERFORM 4000-GRAVAR
               WHEN 'A' PERFORM 4000-GRAVAR
               WHEN 'E' PERFORM 4500-EXCLUIR
               WHEN OTHER
                    MOVE 'ACAO INVALIDA. USE C, I, A OU E'
                                       TO MMENSAGO
                    MOVE DFHBMBRY      TO MACAOA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2100-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - RECEPCAO DA TELA                                        *
      *                                                                *
      * CADA CAMPO SO SUBSTITUI O ESTADO SE VOLTOU DIGITADO (MxxxL     *
      * MAIOR QUE ZERO). CODIGO DIFERENTE DO QUE ESTAVA EM EDICAO      *
      * LIMPA O RESTO DO ESTADO: OS DADOS NA TELA SAO DE OUTRA         *
      * RUBRICA E NAO PODEM SER GRAVADOS NESTA.                        *
      *================================================================*
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPEVENI)
                RESP(WS-RESP)
           END-EXEC
      *
      *
      *--- ENTER SEM NADA DIGITADO DA MAPFAIL: A AREA DE ENTRADA
      *--- NAO E PREENCHIDA E OS COMPRIMENTOS FICAM COM LIXO ------
           IF WS-RESP = DFHRESP(MAPFAIL)
               MOVE LOW-VALUES         TO MAPEVENI
           END-IF
      *
           MOVE 'N'                    TO WS-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
      *
           IF MACAOL > ZEROS
               MOVE FUNCTION UPPER-CASE(MACAOI)
                                       TO WS-ES-ACAO
           END-IF
      *
      *
           IF MCODIGOL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCODIGOI           TO WS-ED-CAMPO(1:4)
               MOVE 9999               TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S' AND WS-ED-VALOR > ZEROS
                   MOVE WS-ED-VALOR    TO WS-CODIGO-TELA
                   IF WS-CODIGO-TELA NOT = WS-ES-CODIGO
                       PERFORM 3050-TROCAR-RUBRICA
                   END-IF
               ELSE
                   SET TEM-ERRO        TO TRUE
                   MOVE 'RN01 - CODIGO DA RUBRICA DE 0001 A 9999'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCODIGOA
               END-IF
           END-IF
      *
           IF MDESCRL > ZEROS
               MOVE FUNCTION UPPER-CASE(MDESCRI)
                                       TO WS-ES-DESCR
           END-IF
           IF MNATURL > ZEROS
               MOVE FUNCTION UPPER-CASE(MNATURI)
                                       TO WS-ES-NATUR
           END-IF
           IF MTIPCALL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MTIPCALI           TO WS-ED-CAMPO(1:3)
               MOVE 999                TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-TIPCAL
               ELSE
                   SET TEM-ERRO        TO TRUE
                   MOVE 'TIPO DE CALCULO INVALIDO - USE ATE 3 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MTIPCALA
               END-IF
           END-IF
           IF MUNIDADL > ZEROS
               MOVE FUNCTION UPPER-CASE(MUNIDADI)
                                       TO WS-ES-UNIDAD
           END-IF
           IF MCONTAL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCONTAI            TO WS-ED-CAMPO(1:8)
               MOVE 99999999           TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CONTA
               ELSE
                   SET TEM-ERRO        TO TRUE
                   MOVE 'CONTA CONTABIL INVALIDA - ATE 8 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCONTAA
               END-IF
           END-IF
           IF MSITUACL > ZEROS
               MOVE FUNCTION UPPER-CASE(MSITUACI)
                                       TO WS-ES-SITUAC
           END-IF
      *
           PERFORM 3020-RECEBER-INCIDENCIAS
           PERFORM 3040-RECEBER-PERCENTUAL
           PERFORM 3080-CRITICAR-RECEBIMENTO.
       3000-FIM.
           EXIT.
      *
       3020-RECEBER-INCIDENCIAS SECTION.
       3020-INICIO.
           IF MINCINSL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINCINSI)
                                       TO WS-ES-INC-INSS
           END-IF
           IF MINCIRRL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINCIRRI)
                                       TO WS-ES-INC-IRRF
           END-IF
           IF MINCFGTL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINCFGTI)
                                       TO WS-ES-INC-FGTS
           END-IF
           IF MINCDSRL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINCDSRI)
                                       TO WS-ES-INC-DSR
           END-IF
           IF MINC13OL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINC13OI)
                                       TO WS-ES-INC-13O
           END-IF
           IF MINCFERL > ZEROS
               MOVE FUNCTION UPPER-CASE(MINCFERI)
                                       TO WS-ES-INC-FER
           END-IF.
       3020-FIM.
           EXIT.
      *
       3040-RECEBER-PERCENTUAL SECTION.
       3040-INICIO.
           IF MPERCENL = ZEROS
               GO TO 3040-FIM
           END-IF
      *
           MOVE SPACES                 TO WS-ED-CAMPO
           MOVE MPERCENI               TO WS-ED-CAMPO(1:6)
           PERFORM 7400-DE-EDITAR
      *
           IF WS-ED-OK = 'S' AND WS-ED-VALOR <= 999,99
               MOVE WS-ED-VALOR        TO WS-ES-PERCEN
           ELSE
               SET TEM-ERRO            TO TRUE
               MOVE 'PERCENTUAL INVALIDO - USE ATE 999,99'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MPERCENA
           END-IF.
       3040-FIM.
           EXIT.
      *
       3050-TROCAR-RUBRICA SECTION.
       3050-INICIO.
           MOVE WS-ES-ACAO             TO WS-ACAO-SALVA
           INITIALIZE WS-ESTADO
           MOVE WS-ACAO-SALVA          TO WS-ES-ACAO
           MOVE WS-CODIGO-TELA         TO WS-ES-CODIGO
           MOVE ZEROS                  TO MPERCENO
           MOVE SPACES                 TO MDESNATO
                                          MDESTIPO
                                          MDESUNIO.
       3050-FIM.
           EXIT.
      *
       3060-INTEIRO-DA-TELA SECTION.
       3060-INICIO.
           MOVE 'N'                    TO WS-INT-OK
           PERFORM 7400-DE-EDITAR
           IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
              AND WS-ED-VALOR <= WS-ED-LIMITE
               MOVE 'S'                TO WS-INT-OK
           END-IF.
       3060-FIM.
           EXIT.
      *
       3080-CRITICAR-RECEBIMENTO SECTION.
       3080-INICIO.
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       3080-FIM.
           EXIT.
      *
      *================================================================*
      * 3100 - CONSULTA DA RUBRICA                                     *
      *================================================================*
       3100-CONSULTAR SECTION.
       3100-INICIO.
           IF WS-ES-CODIGO = ZEROS
               MOVE 'RN01 - CODIGO DA RUBRICA OBRIGATORIO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-ES-CODIGO           TO EVE-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-EVENTO)
                RIDFLD(EVE-CODIGO) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NOTFND)
               PERFORM 6000-LIMPAR-MAPA
               MOVE WS-ES-ACAO         TO MACAOO
               MOVE WS-ES-CODIGO       TO MCODIGOO
               MOVE 'RN12 - RUBRICA NAO CADASTRADA'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE LEITURA NO SFPEVE - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 3150-ARQUIVO-PARA-ESTADO
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
           PERFORM 4600-EVENTO-DO-MOTOR
      *
           IF RUBRICA-DO-MOTOR
               MOVE 'RUBRICA USADA PELO MOTOR: NAO PODE SER'
                                       TO WS-MENSAGEM
               MOVE ' EXCLUIDA NEM INATIVADA (RN13)'
                                       TO WS-MENSAGEM(39:30)
               MOVE WS-MENSAGEM        TO MMENSAGO
           ELSE
               MOVE 'RUBRICA EXIBIDA. ALTERE E TECLE F6 PARA GRAVAR'
                                       TO MMENSAGO
           END-IF
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       3100-FIM.
           EXIT.
      *
       3150-ARQUIVO-PARA-ESTADO SECTION.
       3150-INICIO.
           MOVE EVE-CODIGO             TO WS-ES-CODIGO
           MOVE EVE-DESCRICAO          TO WS-ES-DESCR
           MOVE EVE-NATUREZA           TO WS-ES-NATUR
           MOVE EVE-TIPO-CALCULO       TO WS-ES-TIPCAL
           MOVE EVE-INCIDENCIAS        TO WS-ES-INCID
           MOVE EVE-UNIDADE            TO WS-ES-UNIDAD
           MOVE EVE-PERCENTUAL         TO WS-ES-PERCEN
           MOVE EVE-CONTA-CONTABIL     TO WS-ES-CONTA
           MOVE EVE-SITUACAO           TO WS-ES-SITUAC
           MOVE 'S'                    TO WS-ES-LIDA.
       3150-FIM.
           EXIT.
      *
       3200-MOVER-PARA-TELA SECTION.
       3200-INICIO.
           MOVE WS-ES-ACAO             TO MACAOO
           MOVE WS-ES-CODIGO           TO MCODIGOO
           MOVE WS-ES-DESCR            TO MDESCRO
           MOVE WS-ES-NATUR            TO MNATURO
           MOVE WS-ES-TIPCAL           TO MTIPCALO
           MOVE WS-ES-UNIDAD           TO MUNIDADO
           MOVE WS-ES-PERCEN           TO MPERCENO
           MOVE WS-ES-CONTA            TO MCONTAO
           MOVE WS-ES-SITUAC           TO MSITUACO
           MOVE WS-ES-INC-INSS         TO MINCINSO
           MOVE WS-ES-INC-IRRF         TO MINCIRRO
           MOVE WS-ES-INC-FGTS         TO MINCFGTO
           MOVE WS-ES-INC-DSR          TO MINCDSRO
           MOVE WS-ES-INC-13O          TO MINC13OO
           MOVE WS-ES-INC-FER          TO MINCFERO
           MOVE -1                     TO MCODIGOL.
       3200-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3300 - DESCRICOES DOS CODIGOS DIGITADOS                        *
      *                                                                *
      * NATUREZA E UNIDADE VEM DOS DOMINIOS NAT E UNI, NO SFPDOM. O    *
      * TIPO DE CALCULO VEM DE UMA LISTA INTERNA (3400), PORQUE ELE    *
      * NAO E DOMINIO: E O SELETOR DO EVALUATE DA SECAO 2220 DO        *
      * SFP0300. LISTA NOVA AQUI SEM CODIGO NOVO LA MENTIRIA AO        *
      * USUARIO.                                                       *
      *----------------------------------------------------------------*
       3300-DESCREVER-CODIGOS SECTION.
       3300-INICIO.
           IF WS-ES-NATUR NOT = SPACES
               MOVE 'NAT'              TO WS-DOM-TIPO
               MOVE WS-ES-NATUR        TO WS-DOM-CODIGO
               PERFORM 3350-LER-DOMINIO
               MOVE WS-DOM-DESCR(1:20) TO MDESNATO
           END-IF
      *
           IF WS-ES-UNIDAD NOT = SPACES
               MOVE 'UNI'              TO WS-DOM-TIPO
               MOVE WS-ES-UNIDAD       TO WS-DOM-CODIGO
               PERFORM 3350-LER-DOMINIO
               MOVE WS-DOM-DESCR(1:20) TO MDESUNIO
           END-IF
      *
           IF WS-ES-TIPCAL NOT = ZEROS
               PERFORM 3400-DESCREVER-TIPO
               MOVE WS-DESC-TIPO       TO MDESTIPO
           END-IF.
       3300-FIM.
           EXIT.
      *
       3350-LER-DOMINIO SECTION.
       3350-INICIO.
           MOVE 'N'                    TO WS-DOM-OK
           MOVE SPACES                 TO WS-DOM-DESCR
      *
           MOVE WS-DOM-TIPO            TO DOM-TIPO
           MOVE WS-DOM-CODIGO          TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQ-DOMINIO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL) AND DOM-ATIVO
               MOVE 'S'                TO WS-DOM-OK
               MOVE DOM-DESCRICAO      TO WS-DOM-DESCR
           END-IF.
       3350-FIM.
           EXIT.
      *
       3400-DESCREVER-TIPO SECTION.
       3400-INICIO.
           MOVE 'S'                    TO WS-TIPO-OK
           EVALUATE WS-ES-TIPCAL
               WHEN 001
                    MOVE 'VALOR INFORMADO NO MOVIMENTO'
                                       TO WS-DESC-TIPO
               WHEN 002
                    MOVE 'HORAS X VALOR HORA X PERCENTUAL'
                                       TO WS-DESC-TIPO
               WHEN 003
                    MOVE 'DIAS X VALOR DIA'
                                       TO WS-DESC-TIPO
               WHEN 004
                    MOVE 'PERC. DO MOVIMENTO SOBRE SALARIO'
                                       TO WS-DESC-TIPO
               WHEN 005
                    MOVE 'PERC. DO CADASTRO SOBRE O MINIMO'
                                       TO WS-DESC-TIPO
               WHEN 006
                    MOVE 'PERC. DO MOVIMENTO SOBRE PROVENTO'
                                       TO WS-DESC-TIPO
               WHEN 007
                    MOVE 'MEDIA DE VARIAVEIS DA FICHA'
                                       TO WS-DESC-TIPO
               WHEN 010
                    MOVE 'QUANTIDADE X VALOR UNITARIO'
                                       TO WS-DESC-TIPO
               WHEN OTHER
                    MOVE 'N'           TO WS-TIPO-OK
                    MOVE 'TIPO NAO IMPLEMENTADO NO MOTOR'
                                       TO WS-DESC-TIPO
           END-EVALUATE.
       3400-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 - GRAVACAO                                                *
      *                                                                *
      * A INCLUSAO EXIGE A TELA TODA. A ALTERACAO PARTE DO REGISTRO    *
      * QUE ESTAVA EM EDICAO (WS-ES-LIDA IGUAL A S, POSTO PELA         *
      * CONSULTA): SEM CONSULTA PREVIA NAO SE SABE O QUE NAO FOI       *
      * REDIGITADO, ENTAO A ALTERACAO E RECUSADA.                      *
      *================================================================*
       4000-GRAVAR SECTION.
       4000-INICIO.
           IF WS-ES-ACAO NOT = 'I' AND 'A'
               MOVE 'ACAO INVALIDA PARA GRAVAR. USE I OU A'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MACAOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-ES-ACAO = 'A' AND NOT WS-ES-VEIO-DO-ARQUIVO
               MOVE 'CONSULTE A RUBRICA (F5) ANTES DE ALTERAR'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 4100-VALIDAR-CAMPOS
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-ES-ACAO = 'I'
               PERFORM 4200-INCLUIR
           ELSE
               PERFORM 4300-ALTERAR
           END-IF.
       4000-FIM.
           EXIT.
      *
       4100-VALIDAR-CAMPOS SECTION.
       4100-INICIO.
           IF WS-ES-CODIGO = ZEROS
               MOVE 'RN01 - CODIGO DA RUBRICA DE 0001 A 9999'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCODIGOA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           IF WS-ES-DESCR = SPACES
               MOVE 'RN02 - DESCRICAO DA RUBRICA OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MDESCRA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           MOVE 'NAT'                  TO WS-DOM-TIPO
           MOVE WS-ES-NATUR            TO WS-DOM-CODIGO
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN03 - NATUREZA INVALIDA (P, D, I OU B)'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MNATURA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           PERFORM 3400-DESCREVER-TIPO
           IF WS-TIPO-OK NOT = 'S'
               MOVE 'RN04 - TIPO DE CALCULO NAO IMPLEMENTADO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MTIPCALA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           MOVE 'UNI'                  TO WS-DOM-TIPO
           MOVE WS-ES-UNIDAD           TO WS-DOM-CODIGO
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN05 - UNIDADE INVALIDA (VER F4=LISTA)'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MUNIDADA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           IF (WS-ES-TIPCAL = 002 OR WS-ES-TIPCAL = 005)
              AND WS-ES-PERCEN = ZEROS
               MOVE 'RN06 - ESTE TIPO EXIGE PERCENTUAL NO CADASTRO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MPERCENA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           IF (WS-ES-NATUR = 'P' OR WS-ES-NATUR = 'D')
              AND WS-ES-CONTA = ZEROS
               MOVE 'RN07 - CONTA CONTABIL OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCONTAA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           PERFORM 4110-VALIDAR-INCIDENCIAS
           IF TEM-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-ES-SITUAC = SPACES
               MOVE 'A'                TO WS-ES-SITUAC
           END-IF
           IF WS-ES-SITUAC NOT = 'A' AND 'I'
               MOVE 'RN10 - SITUACAO DEVE SER A OU I'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MSITUACA
               SET TEM-ERRO            TO TRUE
               GO TO 4100-FIM
           END-IF
      *
           PERFORM 4600-EVENTO-DO-MOTOR
           IF RUBRICA-DO-MOTOR AND WS-ES-SITUAC = 'I'
               MOVE 'RN13 - RUBRICA DO MOTOR NAO PODE SER'
                                       TO WS-MENSAGEM
               MOVE ' INATIVADA'       TO WS-MENSAGEM(37:10)
               MOVE DFHBMBRY           TO MSITUACA
               SET TEM-ERRO            TO TRUE
           END-IF.
       4100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4110 - INCIDENCIAS (RN08 E RN09)                               *
      *                                                                *
      * BRANCO VIRA N: O USUARIO SO PRECISA MARCAR O QUE INCIDE. O     *
      * DESCONTO NAO PODE TER NENHUMA LIGADA, SENAO O INSS E A PENSAO  *
      * SERIAM DEDUZIDOS DUAS VEZES NA BASE DO IRRF.                   *
      *----------------------------------------------------------------*
       4110-VALIDAR-INCIDENCIAS SECTION.
       4110-INICIO.
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 6
               IF WS-ES-INCID(WS-IX:1) = SPACE
                  OR WS-ES-INCID(WS-IX:1) = LOW-VALUE
                   MOVE 'N'            TO WS-ES-INCID(WS-IX:1)
               END-IF
               IF WS-ES-INCID(WS-IX:1) NOT = 'S' AND 'N'
                   MOVE 'RN09 - INCIDENCIA DEVE SER S OU N'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MINCINSA
                   SET TEM-ERRO        TO TRUE
                   EXIT PERFORM
               END-IF
           END-PERFORM
      *
           IF TEM-ERRO
               GO TO 4110-FIM
           END-IF
      *
           IF WS-ES-NATUR = 'D'
              AND WS-ES-INCID NOT = ALL 'N'
               MOVE 'RN08 - DESCONTO EXIGE AS SEIS INCIDENCIAS'
                                       TO WS-MENSAGEM
               MOVE ' EM N'            TO WS-MENSAGEM(42:5)
               MOVE DFHBMBRY           TO MINCINSA
               SET TEM-ERRO            TO TRUE
           END-IF.
       4110-FIM.
           EXIT.
      *
       4150-MONTAR-REGISTRO SECTION.
       4150-INICIO.
           MOVE WS-ES-CODIGO           TO EVE-CODIGO
           MOVE WS-ES-DESCR            TO EVE-DESCRICAO
           MOVE WS-ES-NATUR            TO EVE-NATUREZA
           MOVE WS-ES-TIPCAL           TO EVE-TIPO-CALCULO
           MOVE WS-ES-INCID            TO EVE-INCIDENCIAS
           MOVE WS-ES-UNIDAD           TO EVE-UNIDADE
           MOVE WS-ES-PERCEN           TO EVE-PERCENTUAL
           MOVE WS-ES-CONTA            TO EVE-CONTA-CONTABIL
           MOVE WS-ES-SITUAC           TO EVE-SITUACAO
           MOVE SPACES                 TO EVE-FILLER
           .
       4150-FIM.
           EXIT.
      *
       4200-INCLUIR SECTION.
       4200-INICIO.
           INITIALIZE REG-EVENTO
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS WRITE
                FILE(WS-ARQUIVO) FROM(REG-EVENTO)
                RIDFLD(EVE-CODIGO) RESP(WS-RESP)
           END-EXEC
      *
           EVALUATE WS-RESP
               WHEN DFHRESP(NORMAL)
                    MOVE 'S'           TO WS-ES-LIDA
                    PERFORM 6000-LIMPAR-MAPA
                    PERFORM 3200-MOVER-PARA-TELA
                    PERFORM 3300-DESCREVER-CODIGOS
                    MOVE 'RUBRICA INCLUIDA COM SUCESSO'
                                       TO MMENSAGO
                    PERFORM 6100-ENVIAR-MAPA-ERASE
               WHEN DFHRESP(DUPREC)
                    MOVE 'RN11 - RUBRICA JA CADASTRADA'
                                       TO MMENSAGO
                    MOVE DFHBMBRY      TO MCODIGOA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
               WHEN OTHER
                    MOVE 'FALHA AO INCLUIR A RUBRICA NO SFPEVE'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       4200-FIM.
           EXIT.
      *
       4300-ALTERAR SECTION.
       4300-INICIO.
           MOVE WS-ES-CODIGO           TO EVE-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-EVENTO)
                RIDFLD(EVE-CODIGO) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'RN12 - RUBRICA NAO CADASTRADA'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS REWRITE
                FILE(WS-ARQUIVO) FROM(REG-EVENTO)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               PERFORM 6000-LIMPAR-MAPA
               PERFORM 3200-MOVER-PARA-TELA
               PERFORM 3300-DESCREVER-CODIGOS
               MOVE 'RUBRICA ALTERADA COM SUCESSO'
                                       TO MMENSAGO
               PERFORM 6100-ENVIAR-MAPA-ERASE
           ELSE
               MOVE 'FALHA AO ALTERAR A RUBRICA NO SFPEVE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       4300-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4500 - EXCLUSAO                                                *
      *                                                                *
      * EXCLUSAO FISICA: O MAPA NAO TEM COMO EXIBIR UM ESTADO          *
      * INTERMEDIARIO E A SITUACAO I JA SERVE PARA APOSENTAR A         *
      * RUBRICA SEM PERDER O HISTORICO. A RN13 PROTEGE AS RUBRICAS DO  *
      * MOTOR NOS DOIS CAMINHOS.                                       *
      *----------------------------------------------------------------*
       4500-EXCLUIR SECTION.
       4500-INICIO.
           IF WS-ES-CODIGO = ZEROS
               MOVE 'RN01 - CODIGO DA RUBRICA OBRIGATORIO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 4600-EVENTO-DO-MOTOR
           IF RUBRICA-DO-MOTOR
               MOVE 'RN13 - RUBRICA USADA PELO MOTOR NAO PODE'
                                       TO WS-MENSAGEM
               MOVE ' SER EXCLUIDA'    TO WS-MENSAGEM(41:13)
               MOVE WS-MENSAGEM        TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-ES-CODIGO           TO EVE-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-EVENTO)
                RIDFLD(EVE-CODIGO) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'RN12 - RUBRICA NAO CADASTRADA'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           EXEC CICS DELETE
                FILE(WS-ARQUIVO) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               INITIALIZE WS-ESTADO
               PERFORM 6000-LIMPAR-MAPA
               MOVE 'RUBRICA EXCLUIDA COM SUCESSO'
                                       TO MMENSAGO
               PERFORM 6100-ENVIAR-MAPA-ERASE
           ELSE
               MOVE 'FALHA AO EXCLUIR A RUBRICA NO SFPEVE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       4500-FIM.
           EXIT.
      *
       4600-EVENTO-DO-MOTOR SECTION.
       4600-INICIO.
           MOVE 'N'                    TO WS-DO-MOTOR
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > CTE-QTD-EV-MOTOR
               IF CTE-EV-MOTOR(WS-IX) = WS-ES-CODIGO
                   SET RUBRICA-DO-MOTOR TO TRUE
                   EXIT PERFORM
               END-IF
           END-PERFORM.
       4600-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4700 - CHAMADA DA JANELA F4                                    *
      *                                                                *
      * A LINHA DO CURSOR DIZ QUAL CAMPO PEDIU A LISTA. EIBCPOSN E O   *
      * DESLOCAMENTO NA TELA CONTADO DE ZERO, ENTAO A LINHA E O        *
      * QUOCIENTE POR 80 MAIS UM.                                      *
      *----------------------------------------------------------------*
       4700-CHAMAR-LOOKUP SECTION.
       4700-INICIO.
           COMPUTE WS-LINHA-CURSOR = EIBCPOSN / 80 + 1
      *
           INITIALIZE AREA-LOOKUP
           EVALUATE WS-LINHA-CURSOR
               WHEN 5
                    MOVE 'NAT'         TO LOK-TIPO-DOMINIO
                    MOVE 'MNATUR'      TO LOK-CAMPO-ORIGEM
               WHEN 7
                    MOVE 'UNI'         TO LOK-TIPO-DOMINIO
                    MOVE 'MUNIDAD'     TO LOK-CAMPO-ORIGEM
               WHEN OTHER
                    MOVE 'F4 SO ATENDE NATUREZA E UNIDADE.'
                                       TO WS-MENSAGEM
                    MOVE ' POSICIONE O CURSOR NO CAMPO'
                                       TO WS-MENSAGEM(33:28)
                    MOVE WS-MENSAGEM   TO MMENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE
      *
           MOVE WS-PROGRAMA            TO LOK-PGM-CHAMADOR
           MOVE 1                      TO LOK-PAGINA
           SET LOK-EM-CURSO            TO TRUE
      *
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
           MOVE WS-ESTADO              TO COM-AREA-TRABALHO
                                          (121:LENGTH OF WS-ESTADO)
      *
           EXEC CICS XCTL PROGRAM('SFP0900')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       4700-FIM.
           EXIT.
      *
      *================================================================*
      * 5900 A 6200 - ENCERRAMENTO E ROTINAS DE TELA                   *
      *================================================================*
       5900-ENCERRAR-TRANSACAO SECTION.
       5900-INICIO.
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           EXEC CICS XCTL PROGRAM('SFP0000')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       5900-FIM.
           EXIT.
      *
       6000-LIMPAR-MAPA SECTION.
       6000-INICIO.
           MOVE LOW-VALUES             TO MAPEVENO
           MOVE ZEROS                  TO MPERCENO
           .
       6000-FIM.
           EXIT.
      *
       6100-ENVIAR-MAPA-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPEVENO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-MAPA-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPEVENO)
                DATAONLY CURSOR FREEKB ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
      *================================================================*
      * 7400 - DES-EDICAO DO PERCENTUAL                                *
      *                                                                *
      * O CAMPO CHEGA DO BMS COMO ZZ9,99 ALINHADO A ESQUERDA: MOVE     *
      * DIRETO PARA 9(003)V99 DARIA VALOR ERRADO. O TEXTO E VALIDADO   *
      * CARACTERE A CARACTERE, COMPACTADO E REMONTADO EM WS-ED-VALOR.  *
      *================================================================*
       7400-DE-EDITAR SECTION.
       7400-INICIO.
           MOVE 'S'                    TO WS-ED-OK
           MOVE ZEROS                  TO WS-ED-TAM
                                          WS-ED-VIRGULA
                                          WS-ED-INVALIDOS
                                          WS-ED-TAM-INT
                                          WS-ED-TAM-DEC
                                          WS-ED-INT
                                          WS-ED-CENT
                                          WS-ED-VALOR
           MOVE SPACES                 TO WS-ED-COMPACTO
      *
           IF WS-ED-CAMPO = SPACES
               GO TO 7400-FIM
           END-IF
      *
      *--- TIRA ESPACOS, CONTA VIRGULAS E RECUSA O RESTO --------------
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 13
               EVALUATE WS-ED-CAMPO(WS-IX:1)
                   WHEN SPACE
                        CONTINUE
                   WHEN LOW-VALUE
                        CONTINUE
                   WHEN ','
                        ADD 1           TO WS-ED-VIRGULA
                        ADD 1           TO WS-ED-TAM
                        MOVE ','        TO WS-ED-COMPACTO
                                           (WS-ED-TAM:1)
                   WHEN '0' THRU '9'
                        ADD 1           TO WS-ED-TAM
                        MOVE WS-ED-CAMPO(WS-IX:1)
                                        TO WS-ED-COMPACTO
                                           (WS-ED-TAM:1)
                   WHEN OTHER
                        ADD 1           TO WS-ED-INVALIDOS
               END-EVALUATE
           END-PERFORM
      *
           IF WS-ED-INVALIDOS > ZEROS OR WS-ED-VIRGULA > 1
               MOVE 'N'                TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
           IF WS-ED-TAM = ZEROS
               GO TO 7400-FIM
           END-IF
      *
      *--- SEPARA A PARTE INTEIRA DOS CENTAVOS ------------------------
           MOVE WS-ED-TAM              TO WS-ED-TAM-INT
           IF WS-ED-VIRGULA = 1
               PERFORM VARYING WS-IX FROM 1 BY 1
                       UNTIL WS-IX > WS-ED-TAM
                   IF WS-ED-COMPACTO(WS-IX:1) = ','
                       COMPUTE WS-ED-TAM-INT = WS-IX - 1
                       COMPUTE WS-ED-TAM-DEC = WS-ED-TAM - WS-IX
                       EXIT PERFORM
                   END-IF
               END-PERFORM
           END-IF
      *
           IF WS-ED-TAM-INT > 9 OR WS-ED-TAM-DEC > 2
               MOVE 'N'                TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
      *--- INTEIRO A DIREITA, CENTAVOS A ESQUERDA ---------------------
           MOVE ZEROS                  TO WS-ED-INT-X
           IF WS-ED-TAM-INT > ZEROS
               COMPUTE WS-IX = 10 - WS-ED-TAM-INT
               MOVE WS-ED-COMPACTO(1:WS-ED-TAM-INT)
                                       TO WS-ED-INT-X
                                          (WS-IX:WS-ED-TAM-INT)
           END-IF
           MOVE WS-ED-INT-X            TO WS-ED-INT
      *
           MOVE ZEROS                  TO WS-ED-CENT-X
           IF WS-ED-TAM-DEC > ZEROS
               COMPUTE WS-IX = WS-ED-TAM-INT + 2
               MOVE WS-ED-COMPACTO(WS-IX:WS-ED-TAM-DEC)
                                       TO WS-ED-CENT-X
                                          (1:WS-ED-TAM-DEC)
           END-IF
           MOVE WS-ED-CENT-X           TO WS-ED-CENT
      *
           COMPUTE WS-ED-VALOR = WS-ED-INT + WS-ED-CENT / 100.
       7400-FIM.
           EXIT.
      *
       8000-RETORNAR SECTION.
       8000-INICIO.
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-ESTADO              TO COM-AREA-TRABALHO
                                          (121:LENGTH OF WS-ESTADO)
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
                FROM(WS-IDENTIFICACAO)
                LENGTH(LENGTH OF WS-IDENTIFICACAO)
                ERASE FREEKB
           END-EXEC
           EXEC CICS RETURN END-EXEC.
       9999-FIM.
           EXIT.
