      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0900                                             *
      * TRANSACAO: SF99 (NAO E INVOCADA DIRETAMENTE PELO USUARIO)      *
      * MAPSET   : SFPM09   MAPA: MAPLOOK                              *
      * FUNCAO   : JANELA GENERICA DE CONSULTA E SELECAO DE DOMINIOS   *
      *            ACIONADA PELA TECLA F4 EM QUALQUER CAMPO DE CODIGO  *
      * TIPO     : CICS / VSAM - PSEUDOCONVERSACIONAL                  *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE O TRADUTOR CICS ANTES DO COMPILADOR COBOL.   *
      * NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME.                   *
      *----------------------------------------------------------------*
      * UM UNICO PROGRAMA ATENDE TODAS AS LISTAS DE SELECAO DO         *
      * SISTEMA. O TIPO PEDIDO CHEGA EM LOK-TIPO-DOMINIO E DETERMINA   *
      * QUAL ARQUIVO SERA PERCORRIDO:                                  *
      *                                                                *
      *   TIPO NA TABELA SFPDOM ...: SEX ECI INS RAC NAC PAR TCO TLG   *
      *                              CAT MRE SIT TSA TLA UNI NAT TFO   *
      *                              VIN JOR BAN DEF AFA HOR           *
      *   CADASTROS PROPRIOS ......: CAR (cargos)                      *
      *                              DPT (departamentos)               *
      *                              MUN (municipios, filtrado por UF) *
      *                              UFE (unidades da federacao)       *
      *                              EST (estabelecimentos)            *
      *                              EVE (rubricas)                    *
      *                                                                *
      * A NORMALIZACAO NUM UNICO FORMATO CODIGO/DESCRICAO PERMITE QUE  *
      * A JANELA, A PAGINACAO E O FILTRO SEJAM ESCRITOS UMA SO VEZ.    *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0900.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF99'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0900 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM09 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPLOOK'.
           05  WS-LINHAS-PAGINA    PIC S9(004) COMP VALUE 10.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM09.
      *
       COPY SFPWDOM.
       COPY SFPWCAR.
       COPY SFPWDPT.
       COPY SFPWMUN.
       COPY SFPWUFE.
       COPY SFPWEVE.
       COPY SFPWEST.
      *
      *--- GRADE EXIBIDA (FORMATO NORMALIZADO) ------------------------
       01  WS-GRADE.
           05  WS-QTD-GRADE        PIC S9(004) COMP VALUE ZEROS.
           05  WS-LINHA OCCURS 10 TIMES INDEXED BY WS-IL.
               10  WS-LN-SEL       PIC X(001).
               10  WS-LN-CODIGO    PIC X(007).
               10  WS-LN-DESCR     PIC X(041).
               10  WS-LN-AUX       PIC X(010).
      *
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-SELECIONADAS     PIC S9(004) COMP VALUE ZEROS.
           05  WS-FIM-BROWSE       PIC X(001) VALUE 'N'.
               88  FIM-BROWSE          VALUE 'S'.
           05  WS-ARQUIVO          PIC X(008) VALUE SPACES.
           05  WS-CHAVE-VSAM       PIC X(009) VALUE SPACES.
           05  WS-CHAVE-INICIAL    PIC X(009) VALUE SPACES.
           05  WS-DESCR-TABELA     PIC X(035) VALUE SPACES.
           05  WS-FILTRO           PIC X(020) VALUE SPACES.
           05  WS-FILTRO-TAM       PIC S9(004) COMP VALUE ZEROS.
           05  WS-DESCR-MAIUSC     PIC X(041) VALUE SPACES.
           05  WS-ACEITA           PIC X(001) VALUE 'N'.
           05  WS-PAGINA-EXIB      PIC ZZ9 VALUE ZEROS.
           05  WS-LIN-PAGINA       PIC X(030) VALUE SPACES.
      *
       COPY SFPWCOM.
      *
       01  WS-AREA-LOOKUP.
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
               PERFORM 5900-ENCERRAR
           END-IF
      *
           MOVE DFHCOMMAREA            TO COMMAREA-SFP
           MOVE COM-AREA-TRABALHO(1:LENGTH OF AREA-LOOKUP)
                                       TO AREA-LOOKUP
      *
           IF LOK-EM-CURSO
               PERFORM 1000-ABRIR-JANELA
           ELSE
               PERFORM 2000-PROCESSAR-TECLA
           END-IF
      *
           PERFORM 8000-RETORNAR.
       0000-FIM.
           EXIT.
      *
      *================================================================*
      * 1000 - PRIMEIRA EXIBICAO DA JANELA                             *
      *================================================================*
       1000-ABRIR-JANELA SECTION.
       1000-INICIO.
           MOVE LOW-VALUES             TO MAPLOOKO
           MOVE SPACES                 TO WS-CHAVE-INICIAL
                                          WS-FILTRO
           MOVE 1                      TO LOK-PAGINA
      *
           PERFORM 3000-DESCREVER-TABELA
           PERFORM 3100-MONTAR-GRADE
           PERFORM 6000-GRADE-PARA-MAPA
      *
           MOVE 'POSICIONE O CURSOR E TECLE ENTER PARA SELECIONAR'
                                       TO LMENSAGO
      *
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPLOOKO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       1000-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - TRATAMENTO DAS TECLAS                                   *
      *================================================================*
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           EVALUATE EIBAID
               WHEN DFHPF3
               WHEN DFHCLEAR
                    PERFORM 4900-CANCELAR
               WHEN DFHPF7
                    PERFORM 2100-RECEBER
                    PERFORM 2200-PAGINA-ANTERIOR
               WHEN DFHPF8
                    PERFORM 2100-RECEBER
                    PERFORM 2300-PAGINA-SEGUINTE
               WHEN DFHENTER
                    PERFORM 2100-RECEBER
                    PERFORM 2400-AVALIAR-SELECAO
               WHEN OTHER
                    MOVE 'TECLA INVALIDA NESTA JANELA'
                                       TO LMENSAGO
                    PERFORM 6200-ENVIAR-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
       2100-RECEBER SECTION.
       2100-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPLOOKI)
                RESP(WS-RESP)
           END-EXEC
      *
           IF LFILTROI NOT = LOW-VALUES AND SPACES
               MOVE FUNCTION UPPER-CASE(LFILTROI) TO WS-FILTRO
           ELSE
               MOVE SPACES             TO WS-FILTRO
           END-IF
      *
           MOVE LSEL1I TO WS-LN-SEL(1)
           MOVE LSEL2I TO WS-LN-SEL(2)
           MOVE LSEL3I TO WS-LN-SEL(3)
           MOVE LSEL4I TO WS-LN-SEL(4)
           MOVE LSEL5I TO WS-LN-SEL(5)
           MOVE LSEL6I TO WS-LN-SEL(6)
           MOVE LSEL7I TO WS-LN-SEL(7)
           MOVE LSEL8I TO WS-LN-SEL(8)
           MOVE LSEL9I TO WS-LN-SEL(9)
           MOVE LSELAI TO WS-LN-SEL(10)
      *
           MOVE LCOD1I TO WS-LN-CODIGO(1)
           MOVE LCOD2I TO WS-LN-CODIGO(2)
           MOVE LCOD3I TO WS-LN-CODIGO(3)
           MOVE LCOD4I TO WS-LN-CODIGO(4)
           MOVE LCOD5I TO WS-LN-CODIGO(5)
           MOVE LCOD6I TO WS-LN-CODIGO(6)
           MOVE LCOD7I TO WS-LN-CODIGO(7)
           MOVE LCOD8I TO WS-LN-CODIGO(8)
           MOVE LCOD9I TO WS-LN-CODIGO(9)
           MOVE LCODAI TO WS-LN-CODIGO(10)
      *
           MOVE LDES1I TO WS-LN-DESCR(1)
           MOVE LDES2I TO WS-LN-DESCR(2)
           MOVE LDES3I TO WS-LN-DESCR(3)
           MOVE LDES4I TO WS-LN-DESCR(4)
           MOVE LDES5I TO WS-LN-DESCR(5)
           MOVE LDES6I TO WS-LN-DESCR(6)
           MOVE LDES7I TO WS-LN-DESCR(7)
           MOVE LDES8I TO WS-LN-DESCR(8)
           MOVE LDES9I TO WS-LN-DESCR(9)
           MOVE LDESAI TO WS-LN-DESCR(10)
      *
           MOVE 10                     TO WS-QTD-GRADE.
       2100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2200 / 2300 - PAGINACAO                                        *
      *----------------------------------------------------------------*
       2200-PAGINA-ANTERIOR SECTION.
       2200-INICIO.
           IF LOK-PAGINA <= 1
               MOVE 'JA ESTA NA PRIMEIRA PAGINA'
                                       TO LMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
      *--- REPOSICIONA NA PRIMEIRA CHAVE DA PAGINA ANTERIOR -----------
           SUBTRACT 1 FROM LOK-PAGINA
           MOVE SPACES                 TO WS-CHAVE-INICIAL
           PERFORM 3100-MONTAR-GRADE
      *
      *--- AVANCA ATE A PAGINA DESEJADA -------------------------------
           MOVE ZEROS                  TO WS-IX
           PERFORM UNTIL WS-IX >= LOK-PAGINA OR FIM-BROWSE
               ADD 1 TO WS-IX
               IF WS-IX < LOK-PAGINA
                   IF LOK-TIPO-DOMINIO = 'MUN'
                       MOVE WS-LN-DESCR(WS-QTD-GRADE)(1:9)
                                       TO WS-CHAVE-INICIAL
                   ELSE
                       MOVE WS-LN-CODIGO(WS-QTD-GRADE)
                                       TO WS-CHAVE-INICIAL
                   END-IF
                   PERFORM 3100-MONTAR-GRADE
               END-IF
           END-PERFORM
      *
           PERFORM 6000-GRADE-PARA-MAPA
           MOVE SPACES                 TO LMENSAGO
           PERFORM 6100-ENVIAR-ERASE.
       2200-FIM.
           EXIT.
      *
       2300-PAGINA-SEGUINTE SECTION.
       2300-INICIO.
           IF WS-QTD-GRADE < WS-LINHAS-PAGINA
               MOVE 'JA ESTA NA ULTIMA PAGINA'
                                       TO LMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           IF LOK-TIPO-DOMINIO = 'MUN'
               MOVE WS-LN-DESCR(WS-QTD-GRADE)(1:9)
                                       TO WS-CHAVE-INICIAL
           ELSE
               MOVE WS-LN-CODIGO(WS-QTD-GRADE)
                                       TO WS-CHAVE-INICIAL
           END-IF
           ADD 1                       TO LOK-PAGINA
      *
           PERFORM 3100-MONTAR-GRADE
      *
           IF WS-QTD-GRADE = ZEROS
               SUBTRACT 1 FROM LOK-PAGINA
               MOVE 'NAO HA MAIS REGISTROS'
                                       TO LMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           PERFORM 6000-GRADE-PARA-MAPA
           MOVE SPACES                 TO LMENSAGO
           PERFORM 6100-ENVIAR-ERASE.
       2300-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2400 - AVALIA A LINHA MARCADA PELO USUARIO                     *
      *----------------------------------------------------------------*
       2400-AVALIAR-SELECAO SECTION.
       2400-INICIO.
           MOVE ZEROS                  TO WS-SELECIONADAS
      *
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 10
               IF WS-LN-SEL(WS-IX) NOT = SPACES AND LOW-VALUES
                   ADD 1               TO WS-SELECIONADAS
                   MOVE WS-LN-CODIGO(WS-IX) TO LOK-COD-SELECIONADO
                   MOVE WS-LN-DESCR(WS-IX)  TO LOK-DES-SELECIONADA
               END-IF
           END-PERFORM
      *
           EVALUATE WS-SELECIONADAS
               WHEN ZEROS
      *--- ENTER SEM MARCA REAPLICA O FILTRO --------------------------
                    MOVE SPACES        TO WS-CHAVE-INICIAL
                    MOVE 1             TO LOK-PAGINA
                    PERFORM 3100-MONTAR-GRADE
                    PERFORM 6000-GRADE-PARA-MAPA
                    IF WS-QTD-GRADE = ZEROS
                        MOVE 'NENHUM REGISTRO ATENDE AO FILTRO'
                                       TO LMENSAGO
                    ELSE
                        MOVE 'MARQUE UMA LINHA COM X E TECLE ENTER'
                                       TO LMENSAGO
                    END-IF
                    PERFORM 6100-ENVIAR-ERASE
      *
               WHEN 1
                    SET LOK-SELECIONOU TO TRUE
                    PERFORM 4800-DEVOLVER-CONTROLE
      *
               WHEN OTHER
                    MOVE 'MARQUE APENAS UMA LINHA'
                                       TO LMENSAGO
                    PERFORM 6200-ENVIAR-DATAONLY
           END-EVALUATE.
       2400-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - TITULO DA TABELA CONSULTADA                             *
      *================================================================*
       3000-DESCREVER-TABELA SECTION.
       3000-INICIO.
           EVALUATE LOK-TIPO-DOMINIO
               WHEN 'SEX' MOVE 'SEXO' TO WS-DESCR-TABELA
               WHEN 'ECI' MOVE 'ESTADO CIVIL' TO WS-DESCR-TABELA
               WHEN 'INS' MOVE 'GRAU DE INSTRUCAO' TO WS-DESCR-TABELA
               WHEN 'RAC' MOVE 'RACA / COR' TO WS-DESCR-TABELA
               WHEN 'NAC' MOVE 'NACIONALIDADE' TO WS-DESCR-TABELA
               WHEN 'PAR' MOVE 'GRAU DE PARENTESCO' TO WS-DESCR-TABELA
               WHEN 'TCO' MOVE 'TIPO DE CONTA BANCARIA'
                                       TO WS-DESCR-TABELA
               WHEN 'TLG' MOVE 'TIPO DE LOGRADOURO' TO WS-DESCR-TABELA
               WHEN 'CAT' MOVE 'CATEGORIA ESOCIAL' TO WS-DESCR-TABELA
               WHEN 'MRE' MOVE 'MOTIVO DE RESCISAO' TO WS-DESCR-TABELA
               WHEN 'SIT' MOVE 'SITUACAO DO EMPREGADO'
                                       TO WS-DESCR-TABELA
               WHEN 'TSA' MOVE 'TIPO DE SALARIO' TO WS-DESCR-TABELA
               WHEN 'TLA' MOVE 'TIPO DE LANCAMENTO' TO WS-DESCR-TABELA
               WHEN 'UNI' MOVE 'UNIDADE DA RUBRICA' TO WS-DESCR-TABELA
               WHEN 'NAT' MOVE 'NATUREZA DA RUBRICA'
                                       TO WS-DESCR-TABELA
               WHEN 'TFO' MOVE 'TIPO DE FOLHA' TO WS-DESCR-TABELA
               WHEN 'VIN' MOVE 'TIPO DE VINCULO' TO WS-DESCR-TABELA
               WHEN 'JOR' MOVE 'TIPO DE JORNADA' TO WS-DESCR-TABELA
               WHEN 'BAN' MOVE 'BANCOS' TO WS-DESCR-TABELA
               WHEN 'DEF' MOVE 'TIPO DE DEFICIENCIA' TO WS-DESCR-TABELA
               WHEN 'AFA' MOVE 'MOTIVO DE AFASTAMENTO'
                                       TO WS-DESCR-TABELA
               WHEN 'HOR' MOVE 'HORARIO DE TRABALHO'
                                       TO WS-DESCR-TABELA
               WHEN 'TIP' MOVE 'TIPOS DE DOMINIO' TO WS-DESCR-TABELA
               WHEN 'CAR' MOVE 'CARGOS' TO WS-DESCR-TABELA
               WHEN 'DPT' MOVE 'DEPARTAMENTOS' TO WS-DESCR-TABELA
               WHEN 'MUN' MOVE 'MUNICIPIOS' TO WS-DESCR-TABELA
               WHEN 'UFE' MOVE 'UNIDADES DA FEDERACAO'
                                       TO WS-DESCR-TABELA
               WHEN 'EST' MOVE 'ESTABELECIMENTOS' TO WS-DESCR-TABELA
               WHEN 'EVE' MOVE 'RUBRICAS / EVENTOS' TO WS-DESCR-TABELA
               WHEN OTHER MOVE 'TABELA NAO CATALOGADA'
                                       TO WS-DESCR-TABELA
           END-EVALUATE
      *
           MOVE WS-DESCR-TABELA        TO LTIPOO.
       3000-FIM.
           EXIT.
      *
      *================================================================*
      * 3100 - MONTAGEM DA GRADE (ROTEAMENTO POR TIPO)                 *
      *================================================================*
       3100-MONTAR-GRADE SECTION.
       3100-INICIO.
           INITIALIZE WS-GRADE
           MOVE ZEROS                  TO WS-QTD-GRADE
           MOVE 'N'                    TO WS-FIM-BROWSE
      *
           EVALUATE LOK-TIPO-DOMINIO
               WHEN 'CAR' PERFORM 3300-BROWSE-CARGO
               WHEN 'DPT' PERFORM 3400-BROWSE-DEPTO
               WHEN 'MUN' PERFORM 3500-BROWSE-MUNICIPIO
               WHEN 'UFE' PERFORM 3600-BROWSE-UF
               WHEN 'EVE' PERFORM 3700-BROWSE-EVENTO
               WHEN 'EST' PERFORM 3800-BROWSE-ESTAB
               WHEN OTHER PERFORM 3200-BROWSE-DOMINIO
           END-EVALUATE.
       3100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3200 - TABELA GENERICA DE DOMINIOS                             *
      *----------------------------------------------------------------*
       3200-BROWSE-DOMINIO SECTION.
       3200-INICIO.
           MOVE SPACES                 TO WS-CHAVE-VSAM
           MOVE LOK-TIPO-DOMINIO       TO WS-CHAVE-VSAM(1:3)
           IF WS-CHAVE-INICIAL NOT = SPACES
               MOVE WS-CHAVE-INICIAL(1:6) TO WS-CHAVE-VSAM(4:6)
           END-IF
           MOVE WS-CHAVE-VSAM(1:9)     TO DOM-CHAVE
      *
           EXEC CICS STARTBR
                FILE('SFPDOM') RIDFLD(DOM-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3200-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPDOM') INTO(REG-DOMINIO)
                    RIDFLD(DOM-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
      *--- O BROWSE PARA AO MUDAR O TIPO ------------------------------
               IF DOM-TIPO NOT = LOK-TIPO-DOMINIO
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
      *--- PULA O REGISTRO DE PARTIDA E OS INATIVOS -------------------
               IF DOM-CODIGO = WS-CHAVE-INICIAL(1:6)
                  OR DOM-INATIVO
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE DOM-DESCRICAO      TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE DOM-CODIGO         TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE DOM-DESCRICAO      TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE DOM-VALOR-AUX      TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPDOM') END-EXEC.
       3200-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3300 - CARGOS                                                  *
      *----------------------------------------------------------------*
       3300-BROWSE-CARGO SECTION.
       3300-INICIO.
           IF WS-CHAVE-INICIAL = SPACES
               MOVE ZEROS              TO CAR-CODIGO
           ELSE
               MOVE WS-CHAVE-INICIAL(1:4) TO CAR-CODIGO
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPCAR') RIDFLD(CAR-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3300-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPCAR') INTO(REG-CARGO)
                    RIDFLD(CAR-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF CAR-CODIGO = WS-CHAVE-INICIAL(1:4)
                  OR CAR-EXTINTO
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE CAR-DESCRICAO      TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE CAR-CODIGO         TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE CAR-DESCRICAO      TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE CAR-CBO            TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPCAR') END-EXEC.
       3300-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3400 - DEPARTAMENTOS                                           *
      *----------------------------------------------------------------*
       3400-BROWSE-DEPTO SECTION.
       3400-INICIO.
           IF WS-CHAVE-INICIAL = SPACES
               MOVE ZEROS              TO DPT-CODIGO
           ELSE
               MOVE WS-CHAVE-INICIAL(1:4) TO DPT-CODIGO
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPDPT') RIDFLD(DPT-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3400-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPDPT') INTO(REG-DEPARTAMENTO)
                    RIDFLD(DPT-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF DPT-CODIGO = WS-CHAVE-INICIAL(1:4)
                  OR DPT-SITUACAO NOT = 'A'
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE DPT-DESCRICAO      TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE DPT-CODIGO         TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE DPT-DESCRICAO      TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE DPT-CENTRO-CUSTO   TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPDPT') END-EXEC.
       3400-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3500 - MUNICIPIOS (BROWSE PELA CHAVE ALTERNATIVA UF + NOME)    *
      *----------------------------------------------------------------*
       3500-BROWSE-MUNICIPIO SECTION.
       3500-INICIO.
           MOVE SPACES                 TO MUN-UF-NOME
           MOVE LOK-UF-FILTRO          TO MUN-UF
           IF WS-CHAVE-INICIAL NOT = SPACES
               MOVE WS-CHAVE-INICIAL   TO MUN-NOME(1:9)
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPMUNA') RIDFLD(MUN-UF-NOME)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3500-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPMUNA') INTO(REG-MUNICIPIO)
                    RIDFLD(MUN-UF-NOME) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
      *--- SO INTERESSAM OS MUNICIPIOS DA UF PEDIDA -------------------
               IF LOK-UF-FILTRO NOT = SPACES
               AND MUN-UF NOT = LOK-UF-FILTRO
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF WS-CHAVE-INICIAL NOT = SPACES
               AND MUN-NOME(1:9) = WS-CHAVE-INICIAL
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE MUN-NOME           TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE MUN-COD-IBGE       TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE MUN-NOME           TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE MUN-UF             TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPMUNA') END-EXEC.
       3500-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3600 - UNIDADES DA FEDERACAO                                   *
      *----------------------------------------------------------------*
       3600-BROWSE-UF SECTION.
       3600-INICIO.
           IF WS-CHAVE-INICIAL = SPACES
               MOVE SPACES             TO UFE-SIGLA
           ELSE
               MOVE WS-CHAVE-INICIAL(1:2) TO UFE-SIGLA
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPUFE') RIDFLD(UFE-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3600-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPUFE') INTO(REG-UF)
                    RIDFLD(UFE-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF UFE-SIGLA = WS-CHAVE-INICIAL(1:2)
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE UFE-NOME           TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE UFE-SIGLA          TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE UFE-NOME           TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE UFE-REGIAO         TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPUFE') END-EXEC.
       3600-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3700 - RUBRICAS / EVENTOS                                      *
      *----------------------------------------------------------------*
       3700-BROWSE-EVENTO SECTION.
       3700-INICIO.
           IF WS-CHAVE-INICIAL = SPACES
               MOVE ZEROS              TO EVE-CODIGO
           ELSE
               MOVE WS-CHAVE-INICIAL(1:4) TO EVE-CODIGO
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPEVE') RIDFLD(EVE-CODIGO)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3700-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPEVE') INTO(REG-EVENTO)
                    RIDFLD(EVE-CODIGO) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF EVE-CODIGO = WS-CHAVE-INICIAL(1:4)
                  OR EVE-SITUACAO NOT = 'A'
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE EVE-DESCRICAO      TO WS-DESCR-MAIUSC
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE EVE-CODIGO         TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE EVE-DESCRICAO      TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE EVE-NATUREZA       TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPEVE') END-EXEC.
       3700-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3800 - ESTABELECIMENTOS                                        *
      *----------------------------------------------------------------*
       3800-BROWSE-ESTAB SECTION.
       3800-INICIO.
           IF WS-CHAVE-INICIAL = SPACES
               MOVE ZEROS              TO EST-CODIGO
           ELSE
               MOVE WS-CHAVE-INICIAL(1:4) TO EST-CODIGO
           END-IF
      *
           EXEC CICS STARTBR
                FILE('SFPEST') RIDFLD(EST-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE TO TRUE
               GO TO 3800-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-GRADE >= WS-LINHAS-PAGINA
      *
               EXEC CICS READNEXT
                    FILE('SFPEST') INTO(REG-ESTABELEC)
                    RIDFLD(EST-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF EST-CODIGO = WS-CHAVE-INICIAL(1:4)
                  OR EST-SITUACAO NOT = 'A'
                   EXIT PERFORM CYCLE
               END-IF
      *
      *--- O NOME FANTASIA E OPCIONAL NA MASSA ------------------------
               IF EST-NOME-FANTASIA = SPACES
                   MOVE EST-RAZAO-SOCIAL TO WS-DESCR-MAIUSC
               ELSE
                   MOVE EST-NOME-FANTASIA TO WS-DESCR-MAIUSC
               END-IF
               PERFORM 3900-APLICAR-FILTRO
               IF WS-ACEITA = 'N'
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-GRADE
               MOVE SPACES             TO WS-LN-SEL(WS-QTD-GRADE)
               MOVE EST-CODIGO         TO WS-LN-CODIGO(WS-QTD-GRADE)
               MOVE WS-DESCR-MAIUSC    TO WS-LN-DESCR(WS-QTD-GRADE)
               MOVE EST-TIPO           TO WS-LN-AUX(WS-QTD-GRADE)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE('SFPEST') END-EXEC.
       3800-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3900 - FILTRO POR CONTEUDO DA DESCRICAO                        *
      *----------------------------------------------------------------*
       3900-APLICAR-FILTRO SECTION.
       3900-INICIO.
           MOVE 'S'                    TO WS-ACEITA
      *
           IF WS-FILTRO = SPACES
               GO TO 3900-FIM
           END-IF
      *
           MOVE ZEROS                  TO WS-FILTRO-TAM
           INSPECT FUNCTION REVERSE(WS-FILTRO)
                   TALLYING WS-FILTRO-TAM
                   FOR LEADING SPACES
           COMPUTE WS-FILTRO-TAM = LENGTH OF WS-FILTRO - WS-FILTRO-TAM
      *
           IF WS-FILTRO-TAM <= ZEROS
               GO TO 3900-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-ACEITA
           MOVE FUNCTION UPPER-CASE(WS-DESCR-MAIUSC)
                                       TO WS-DESCR-MAIUSC
      *
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > (LENGTH OF WS-DESCR-MAIUSC
                                  - WS-FILTRO-TAM + 1)
                      OR WS-ACEITA = 'S'
               IF WS-DESCR-MAIUSC(WS-IX:WS-FILTRO-TAM)
                  = WS-FILTRO(1:WS-FILTRO-TAM)
                   MOVE 'S'            TO WS-ACEITA
               END-IF
           END-PERFORM.
       3900-FIM.
           EXIT.
      *
      *================================================================*
      * 4800 / 4900 - DEVOLUCAO DO CONTROLE AO PROGRAMA CHAMADOR       *
      *================================================================*
       4800-DEVOLVER-CONTROLE SECTION.
       4800-INICIO.
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
      *
           EXEC CICS XCTL
                PROGRAM(LOK-PGM-CHAMADOR)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       4800-FIM.
           EXIT.
      *
       4900-CANCELAR SECTION.
       4900-INICIO.
           SET LOK-CANCELOU            TO TRUE
           MOVE SPACES                 TO LOK-COD-SELECIONADO
                                          LOK-DES-SELECIONADA
           PERFORM 4800-DEVOLVER-CONTROLE.
       4900-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 - MONTAGEM DO MAPA                                        *
      *================================================================*
       6000-GRADE-PARA-MAPA SECTION.
       6000-INICIO.
           MOVE WS-FILTRO              TO LFILTROO
      *
           MOVE WS-LN-SEL(1)   TO LSEL1O
           MOVE WS-LN-CODIGO(1) TO LCOD1O
           MOVE WS-LN-DESCR(1) TO LDES1O
           MOVE WS-LN-SEL(2)   TO LSEL2O
           MOVE WS-LN-CODIGO(2) TO LCOD2O
           MOVE WS-LN-DESCR(2) TO LDES2O
           MOVE WS-LN-SEL(3)   TO LSEL3O
           MOVE WS-LN-CODIGO(3) TO LCOD3O
           MOVE WS-LN-DESCR(3) TO LDES3O
           MOVE WS-LN-SEL(4)   TO LSEL4O
           MOVE WS-LN-CODIGO(4) TO LCOD4O
           MOVE WS-LN-DESCR(4) TO LDES4O
           MOVE WS-LN-SEL(5)   TO LSEL5O
           MOVE WS-LN-CODIGO(5) TO LCOD5O
           MOVE WS-LN-DESCR(5) TO LDES5O
           MOVE WS-LN-SEL(6)   TO LSEL6O
           MOVE WS-LN-CODIGO(6) TO LCOD6O
           MOVE WS-LN-DESCR(6) TO LDES6O
           MOVE WS-LN-SEL(7)   TO LSEL7O
           MOVE WS-LN-CODIGO(7) TO LCOD7O
           MOVE WS-LN-DESCR(7) TO LDES7O
           MOVE WS-LN-SEL(8)   TO LSEL8O
           MOVE WS-LN-CODIGO(8) TO LCOD8O
           MOVE WS-LN-DESCR(8) TO LDES8O
           MOVE WS-LN-SEL(9)   TO LSEL9O
           MOVE WS-LN-CODIGO(9) TO LCOD9O
           MOVE WS-LN-DESCR(9) TO LDES9O
           MOVE WS-LN-SEL(10)  TO LSELAO
           MOVE WS-LN-CODIGO(10) TO LCODAO
           MOVE WS-LN-DESCR(10) TO LDESAO
      *
           MOVE LOK-PAGINA             TO WS-PAGINA-EXIB
           MOVE SPACES                 TO WS-LIN-PAGINA
           STRING 'PAGINA ' WS-PAGINA-EXIB
                  DELIMITED BY SIZE INTO WS-LIN-PAGINA
           MOVE WS-LIN-PAGINA          TO LPAGINAO.
       6000-FIM.
           EXIT.
      *
       6100-ENVIAR-ERASE SECTION.
       6100-INICIO.
           PERFORM 3000-DESCREVER-TABELA
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPLOOKO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPLOOKO)
                DATAONLY CURSOR FREEKB ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
       5900-ENCERRAR SECTION.
       5900-INICIO.
           EXEC CICS SEND CONTROL ERASE FREEKB END-EXEC
           EXEC CICS RETURN END-EXEC.
       5900-FIM.
           EXIT.
      *
       8000-RETORNAR SECTION.
       8000-INICIO.
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
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
           SET LOK-CANCELOU            TO TRUE
           PERFORM 4800-DEVOLVER-CONTROLE.
       9999-FIM.
           EXIT.
