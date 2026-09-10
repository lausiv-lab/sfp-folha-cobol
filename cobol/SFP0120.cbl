      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0120                                             *
      * TRANSACAO: SF03                                                *
      * MAPSET   : SFPM02   MAPA: MAPMOV                               *
      * FUNCAO   : LANCAMENTO ONLINE DO MOVIMENTO MENSAL DA FOLHA      *
      *            GRADE DE 10 LINHAS COM PAGINACAO POR CURSOR DB2     *
      * TIPO     : CICS / DB2 - PSEUDOCONVERSACIONAL                   *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE OS TRADUTORES CICS E DB2 ANTES DO COMPILADOR *
      * COBOL. NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME.            *
      *----------------------------------------------------------------*
      * ACOES ACEITAS EM CADA LINHA DA GRADE                           *
      *   BRANCO - LINHA INALTERADA                                    *
      *   I      - INCLUIR O LANCAMENTO                                *
      *   A      - ALTERAR REFERENCIA E VALOR                          *
      *   E      - EXCLUIR O LANCAMENTO                                *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO                                              *
      *  RN01 - COMPETENCIA DEVE ESTAR ABERTA PARA LANCAMENTO          *
      *  RN02 - MATRICULA DEVE EXISTIR E NAO ESTAR DEMITIDA            *
      *  RN03 - EVENTO DEVE EXISTIR E ESTAR ATIVO                      *
      *  RN04 - EVENTO DE CALCULO AUTOMATICO NAO ACEITA LANCAMENTO     *
      *  RN05 - EVENTO EM VALOR EXIGE VALOR; EM HORA EXIGE REFERENCIA  *
      *  RN06 - NAO SE DUPLICA O MESMO EVENTO NA MESMA COMPETENCIA     *
      *  RN07 - HORAS EXTRAS LIMITADAS A 44 HORAS NO MES              *
      *  RN08 - TOTAL DE DESCONTOS NAO PODE ULTRAPASSAR 70% DO BRUTO   *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0120.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF03'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0120 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM02 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPMOV '.
           05  WS-TITULO           PIC X(050) VALUE
               'SFP0120 - LANCAMENTO DE MOVIMENTO - FIM DA SESSAO'.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM02.
      *
       EXEC SQL INCLUDE SFPDMOV END-EXEC.
       EXEC SQL INCLUDE SQLCA   END-EXEC.
      *
      *--- TABELA INTERNA DA GRADE (ESPELHO DA TELA) ------------------
       01  WS-GRADE.
           05  WS-LINHA OCCURS 10 TIMES INDEXED BY WS-IL.
               10  WS-LN-ACAO      PIC X(001).
               10  WS-LN-EVENTO    PIC 9(004).
               10  WS-LN-DESCRICAO PIC X(026).
               10  WS-LN-REFEREN   PIC 9(005)V99.
               10  WS-LN-VALOR     PIC 9(009)V99.
               10  WS-LN-TIPO      PIC X(001).
               10  WS-LN-ORIGEM    PIC X(003).
               10  WS-LN-NATUREZA  PIC X(001).
               10  WS-LN-UNIDADE   PIC X(002).
               10  WS-LN-EXISTE    PIC X(001).
      *
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-MATRICULA        PIC 9(008) VALUE ZEROS.
           05  WS-COMPETENCIA      PIC 9(006) VALUE ZEROS.
           05  WS-NOME-EMP         PIC X(040) VALUE SPACES.
           05  WS-SALARIO-EMP      PIC 9(009)V99 VALUE ZEROS.
           05  WS-SITUACAO-EMP     PIC X(001) VALUE SPACES.
           05  WS-SIT-COMPET       PIC X(001) VALUE SPACES.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-QTD-LINHAS       PIC 9(003) VALUE ZEROS.
           05  WS-TOTAL-GRADE      PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-PROVENTOS    PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-DESCONTOS    PIC 9(009)V99 VALUE ZEROS.
           05  WS-LIMITE-DESCONTO  PIC 9(009)V99 VALUE ZEROS.
           05  WS-HORAS-EXTRAS     PIC 9(005)V99 VALUE ZEROS.
           05  WS-QTD-DUPLIC       PIC S9(009) COMP VALUE ZEROS.
           05  WS-GRAVADOS         PIC 9(003) VALUE ZEROS.
           05  WS-EXCLUIDOS        PIC 9(003) VALUE ZEROS.
           05  WS-FIM-CURSOR       PIC X(001) VALUE 'N'.
           05  WS-HORA-ABS         PIC S9(015) COMP-3 VALUE ZEROS.
           05  WS-DATA-HOJE        PIC 9(008) VALUE ZEROS.
      *
      *--- DADOS AUXILIARES DO EVENTO CONSULTADO ----------------------
       01  WS-EVENTO.
           05  WS-EV-DESCRICAO     PIC X(030) VALUE SPACES.
           05  WS-EV-NATUREZA      PIC X(001) VALUE SPACES.
           05  WS-EV-TIPO-CALC     PIC S9(004) COMP VALUE ZEROS.
           05  WS-EV-UNIDADE       PIC X(002) VALUE SPACES.
           05  WS-EV-SITUACAO      PIC X(001) VALUE SPACES.
      *
       COPY SFPWCOM.
      *
       01  AREA-CONSTANTES.
           COPY SFPWCON.
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
               MOVE COM-MATRICULA      TO WS-MATRICULA
               MOVE COM-COMPETENCIA    TO WS-COMPETENCIA
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
           SET COM-PRIMEIRA-VEZ        TO TRUE
      *
           PERFORM 7000-OBTER-DATA
           MOVE LOW-VALUES             TO MAPMOVO
           MOVE WS-DATA-HOJE           TO MDATAO
           COMPUTE WS-COMPETENCIA = WS-DATA-HOJE / 100
           MOVE WS-COMPETENCIA         TO MCOMPETO
           MOVE 'INFORME A MATRICULA E TECLE F5 PARA CARREGAR'
                                       TO MMENSAGO
      *
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPMOVO)
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
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
               WHEN DFHPF5
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3500-CARREGAR-GRADE
               WHEN DFHPF6
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-GRAVAR-GRADE
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3600-DESCREVER-EVENTOS
               WHEN OTHER
                    MOVE 'TECLA INVALIDA PARA ESTA TRANSACAO'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - RECEPCAO DO MAPA E CARGA DA TABELA INTERNA              *
      *================================================================*
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPMOVI)
                RESP(WS-RESP)
           END-EXEC
      *
           IF MMATRICI NUMERIC
               MOVE MMATRICI           TO WS-MATRICULA
           END-IF
           IF MCOMPETI NUMERIC
               MOVE MCOMPETI           TO WS-COMPETENCIA
           END-IF
      *
           MOVE WS-MATRICULA           TO COM-MATRICULA
           MOVE WS-COMPETENCIA         TO COM-COMPETENCIA
      *
           PERFORM 3100-MAPA-PARA-TABELA.
       3000-FIM.
           EXIT.
      *
       3100-MAPA-PARA-TABELA SECTION.
       3100-INICIO.
           INITIALIZE WS-GRADE
      *
           PERFORM 3110-CARREGAR-LINHA-01
           PERFORM 3111-CARREGAR-LINHA-02
           PERFORM 3112-CARREGAR-LINHA-03
           PERFORM 3113-CARREGAR-LINHA-04
           PERFORM 3114-CARREGAR-LINHA-05
           PERFORM 3115-CARREGAR-LINHA-06
           PERFORM 3116-CARREGAR-LINHA-07
           PERFORM 3117-CARREGAR-LINHA-08
           PERFORM 3118-CARREGAR-LINHA-09
           PERFORM 3119-CARREGAR-LINHA-10.
       3100-FIM.
           EXIT.
      *
       3110-CARREGAR-LINHA-01 SECTION.
       3110-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO1I) TO WS-LN-ACAO(1)
           IF EVEN1I NUMERIC MOVE EVEN1I TO WS-LN-EVENTO(1) END-IF
           MOVE REFE1I                 TO WS-LN-REFEREN(1)
           MOVE VALO1I                 TO WS-LN-VALOR(1)
           MOVE TIPO1I                 TO WS-LN-TIPO(1).
       3110-FIM.
           EXIT.
      *
       3111-CARREGAR-LINHA-02 SECTION.
       3111-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO2I) TO WS-LN-ACAO(2)
           IF EVEN2I NUMERIC MOVE EVEN2I TO WS-LN-EVENTO(2) END-IF
           MOVE REFE2I                 TO WS-LN-REFEREN(2)
           MOVE VALO2I                 TO WS-LN-VALOR(2)
           MOVE TIPO2I                 TO WS-LN-TIPO(2).
       3111-FIM.
           EXIT.
      *
       3112-CARREGAR-LINHA-03 SECTION.
       3112-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO3I) TO WS-LN-ACAO(3)
           IF EVEN3I NUMERIC MOVE EVEN3I TO WS-LN-EVENTO(3) END-IF
           MOVE REFE3I                 TO WS-LN-REFEREN(3)
           MOVE VALO3I                 TO WS-LN-VALOR(3)
           MOVE TIPO3I                 TO WS-LN-TIPO(3).
       3112-FIM.
           EXIT.
      *
       3113-CARREGAR-LINHA-04 SECTION.
       3113-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO4I) TO WS-LN-ACAO(4)
           IF EVEN4I NUMERIC MOVE EVEN4I TO WS-LN-EVENTO(4) END-IF
           MOVE REFE4I                 TO WS-LN-REFEREN(4)
           MOVE VALO4I                 TO WS-LN-VALOR(4)
           MOVE TIPO4I                 TO WS-LN-TIPO(4).
       3113-FIM.
           EXIT.
      *
       3114-CARREGAR-LINHA-05 SECTION.
       3114-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO5I) TO WS-LN-ACAO(5)
           IF EVEN5I NUMERIC MOVE EVEN5I TO WS-LN-EVENTO(5) END-IF
           MOVE REFE5I                 TO WS-LN-REFEREN(5)
           MOVE VALO5I                 TO WS-LN-VALOR(5)
           MOVE TIPO5I                 TO WS-LN-TIPO(5).
       3114-FIM.
           EXIT.
      *
       3115-CARREGAR-LINHA-06 SECTION.
       3115-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO6I) TO WS-LN-ACAO(6)
           IF EVEN6I NUMERIC MOVE EVEN6I TO WS-LN-EVENTO(6) END-IF
           MOVE REFE6I                 TO WS-LN-REFEREN(6)
           MOVE VALO6I                 TO WS-LN-VALOR(6)
           MOVE TIPO6I                 TO WS-LN-TIPO(6).
       3115-FIM.
           EXIT.
      *
       3116-CARREGAR-LINHA-07 SECTION.
       3116-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO7I) TO WS-LN-ACAO(7)
           IF EVEN7I NUMERIC MOVE EVEN7I TO WS-LN-EVENTO(7) END-IF
           MOVE REFE7I                 TO WS-LN-REFEREN(7)
           MOVE VALO7I                 TO WS-LN-VALOR(7)
           MOVE TIPO7I                 TO WS-LN-TIPO(7).
       3116-FIM.
           EXIT.
      *
       3117-CARREGAR-LINHA-08 SECTION.
       3117-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO8I) TO WS-LN-ACAO(8)
           IF EVEN8I NUMERIC MOVE EVEN8I TO WS-LN-EVENTO(8) END-IF
           MOVE REFE8I                 TO WS-LN-REFEREN(8)
           MOVE VALO8I                 TO WS-LN-VALOR(8)
           MOVE TIPO8I                 TO WS-LN-TIPO(8).
       3117-FIM.
           EXIT.
      *
       3118-CARREGAR-LINHA-09 SECTION.
       3118-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAO9I) TO WS-LN-ACAO(9)
           IF EVEN9I NUMERIC MOVE EVEN9I TO WS-LN-EVENTO(9) END-IF
           MOVE REFE9I                 TO WS-LN-REFEREN(9)
           MOVE VALO9I                 TO WS-LN-VALOR(9)
           MOVE TIPO9I                 TO WS-LN-TIPO(9).
       3118-FIM.
           EXIT.
      *
       3119-CARREGAR-LINHA-10 SECTION.
       3119-INICIO.
           MOVE FUNCTION UPPER-CASE(ACAOAI) TO WS-LN-ACAO(10)
           IF EVENAI NUMERIC MOVE EVENAI TO WS-LN-EVENTO(10) END-IF
           MOVE REFEAI                 TO WS-LN-REFEREN(10)
           MOVE VALOAI                 TO WS-LN-VALOR(10)
           MOVE TIPOAI                 TO WS-LN-TIPO(10).
       3119-FIM.
           EXIT.
      *
      *================================================================*
      * 3200 - VALIDACAO DO CABECALHO (RN01 E RN02)                    *
      *================================================================*
       3200-VALIDAR-CABECALHO SECTION.
       3200-INICIO.
           MOVE 'N'                    TO WS-ERRO
      *
           IF WS-MATRICULA = ZEROS
               MOVE 'RN02 - MATRICULA OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MMATRICA
               MOVE 'S'                TO WS-ERRO
               GO TO 3200-FIM
           END-IF
      *
           IF WS-COMPETENCIA = ZEROS
               MOVE 'RN01 - COMPETENCIA OBRIGATORIA NO FORMATO AAAAMM'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCOMPETA
               MOVE 'S'                TO WS-ERRO
               GO TO 3200-FIM
           END-IF
      *
      *--- RN02 - EMPREGADO ATIVO -------------------------------------
           MOVE WS-MATRICULA           TO DCLM-MATRICULA
           EXEC SQL
                SELECT NOME
                     , SALARIO_BASE
                     , SITUACAO
                  INTO :WS-NOME-EMP
                     , :WS-SALARIO-EMP
                     , :WS-SITUACAO-EMP
                  FROM SFPADM.TB_EMPREGADO
                 WHERE MATRICULA = :DCLM-MATRICULA
                  WITH CS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN +100
                    MOVE 'RN02 - MATRICULA NAO CADASTRADA'
                                       TO WS-MENSAGEM
                    MOVE DFHBMBRY      TO MMATRICA
                    MOVE 'S'           TO WS-ERRO
                    GO TO 3200-FIM
               WHEN OTHER
                    PERFORM 9000-ERRO-SQL
           END-EVALUATE
      *
           IF WS-SITUACAO-EMP = 'D'
               MOVE 'RN02 - EMPREGADO DEMITIDO NAO ACEITA LANCAMENTO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MMATRICA
               MOVE 'S'                TO WS-ERRO
               GO TO 3200-FIM
           END-IF
      *
      *--- RN01 - COMPETENCIA ABERTA ----------------------------------
           MOVE WS-COMPETENCIA         TO DCLM-COMPETENCIA
           EXEC SQL
                SELECT COALESCE(MAX(DESCRICAO),'ABERTA')
                  INTO :WS-SIT-COMPET
                  FROM SFPADM.TB_TABELA_LEGAL
                 WHERE TIPO_TABELA = 'PAR'
                   AND CHAVE       = 'STATUS-COMPETEN'
                   AND COMPETENCIA = :DCLM-COMPETENCIA
                  WITH UR
           END-EXEC
      *
           IF WS-SIT-COMPET = 'F'
               MOVE 'RN01 - COMPETENCIA JA FECHADA PARA LANCAMENTO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCOMPETA
               MOVE 'S'                TO WS-ERRO
           END-IF.
       3200-FIM.
           EXIT.
      *
      *================================================================*
      * 3500 - CARGA DA GRADE A PARTIR DO DB2                          *
      *================================================================*
       3500-CARREGAR-GRADE SECTION.
       3500-INICIO.
           PERFORM 3200-VALIDAR-CABECALHO
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           INITIALIZE WS-GRADE
           MOVE ZEROS                  TO WS-QTD-LINHAS
                                          WS-TOTAL-GRADE
           MOVE 'N'                    TO WS-FIM-CURSOR
      *
           MOVE WS-MATRICULA           TO DCLM-MATRICULA
           MOVE WS-COMPETENCIA         TO DCLM-COMPETENCIA
      *
           EXEC SQL
                DECLARE CURMOV CURSOR FOR
                SELECT M.COD_EVENTO
                     , E.DESCRICAO
                     , M.REFERENCIA
                     , M.VALOR
                     , M.TIPO_LANC
                     , M.ORIGEM
                     , E.NATUREZA
                     , E.UNIDADE
                  FROM SFPADM.TB_MOVIMENTO M
                  JOIN SFPADM.TB_EVENTO    E
                    ON E.COD_EVENTO = M.COD_EVENTO
                 WHERE M.MATRICULA   = :DCLM-MATRICULA
                   AND M.COMPETENCIA = :DCLM-COMPETENCIA
                 ORDER BY M.COD_EVENTO
                  FOR FETCH ONLY
           END-EXEC
      *
           EXEC SQL OPEN CURMOV END-EXEC
           IF SQLCODE NOT = 0
               PERFORM 9000-ERRO-SQL
           END-IF
      *
           PERFORM UNTIL WS-FIM-CURSOR = 'S'
                      OR WS-QTD-LINHAS >= 10
      *
               EXEC SQL
                    FETCH CURMOV
                     INTO :DCLM-COD-EVENTO
                        , :WS-EV-DESCRICAO
                        , :DCLM-REFERENCIA
                        , :DCLM-VALOR
                        , :DCLM-TIPO-LANC
                        , :DCLM-ORIGEM
                        , :WS-EV-NATUREZA
                        , :WS-EV-UNIDADE
               END-EXEC
      *
               EVALUATE SQLCODE
                   WHEN 0
                        ADD 1          TO WS-QTD-LINHAS
                        MOVE SPACES    TO WS-LN-ACAO(WS-QTD-LINHAS)
                        MOVE DCLM-COD-EVENTO
                                       TO WS-LN-EVENTO(WS-QTD-LINHAS)
                        MOVE WS-EV-DESCRICAO
                                       TO WS-LN-DESCRICAO(WS-QTD-LINHAS)
                        MOVE DCLM-REFERENCIA
                                       TO WS-LN-REFEREN(WS-QTD-LINHAS)
                        MOVE DCLM-VALOR
                                       TO WS-LN-VALOR(WS-QTD-LINHAS)
                        MOVE DCLM-TIPO-LANC
                                       TO WS-LN-TIPO(WS-QTD-LINHAS)
                        MOVE DCLM-ORIGEM
                                       TO WS-LN-ORIGEM(WS-QTD-LINHAS)
                        MOVE WS-EV-NATUREZA
                                       TO WS-LN-NATUREZA(WS-QTD-LINHAS)
                        MOVE WS-EV-UNIDADE
                                       TO WS-LN-UNIDADE(WS-QTD-LINHAS)
                        MOVE 'S'       TO WS-LN-EXISTE(WS-QTD-LINHAS)
                        ADD DCLM-VALOR TO WS-TOTAL-GRADE
      *
                   WHEN +100
                        MOVE 'S'       TO WS-FIM-CURSOR
      *
                   WHEN OTHER
                        PERFORM 9000-ERRO-SQL
               END-EVALUATE
           END-PERFORM
      *
           EXEC SQL CLOSE CURMOV END-EXEC
      *
           PERFORM 6000-TABELA-PARA-MAPA
      *
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'NENHUM LANCAMENTO NA COMPETENCIA - USE ACAO I'
                                       TO MMENSAGO
           ELSE
               MOVE 'LANCAMENTOS CARREGADOS. F6 PARA GRAVAR'
                                       TO MMENSAGO
           END-IF
      *
           PERFORM 6100-ENVIAR-ERASE.
       3500-FIM.
           EXIT.
      *
      *================================================================*
      * 3600 - PREENCHIMENTO AUTOMATICO DA DESCRICAO DOS EVENTOS       *
      *================================================================*
       3600-DESCREVER-EVENTOS SECTION.
       3600-INICIO.
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 10
               IF WS-LN-EVENTO(WS-IX) > ZEROS
                   MOVE WS-LN-EVENTO(WS-IX) TO DCLM-COD-EVENTO
                   PERFORM 3700-LER-EVENTO
                   IF SQLCODE = 0
                       MOVE WS-EV-DESCRICAO
                                       TO WS-LN-DESCRICAO(WS-IX)
                       MOVE WS-EV-NATUREZA
                                       TO WS-LN-NATUREZA(WS-IX)
                       MOVE WS-EV-UNIDADE
                                       TO WS-LN-UNIDADE(WS-IX)
                   ELSE
                       MOVE '*** EVENTO INEXISTENTE ***'
                                       TO WS-LN-DESCRICAO(WS-IX)
                   END-IF
               END-IF
           END-PERFORM
      *
           PERFORM 6000-TABELA-PARA-MAPA
           MOVE 'DESCRICOES ATUALIZADAS. CONFIRA E TECLE F6'
                                       TO MMENSAGO
           PERFORM 6200-ENVIAR-DATAONLY.
       3600-FIM.
           EXIT.
      *
       3700-LER-EVENTO SECTION.
       3700-INICIO.
           EXEC SQL
                SELECT DESCRICAO
                     , NATUREZA
                     , TIPO_CALCULO
                     , UNIDADE
                     , SITUACAO
                  INTO :WS-EV-DESCRICAO
                     , :WS-EV-NATUREZA
                     , :WS-EV-TIPO-CALC
                     , :WS-EV-UNIDADE
                     , :WS-EV-SITUACAO
                  FROM SFPADM.TB_EVENTO
                 WHERE COD_EVENTO = :DCLM-COD-EVENTO
                  WITH CS
           END-EXEC.
       3700-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 - GRAVACAO DA GRADE                                       *
      *================================================================*
       4000-GRAVAR-GRADE SECTION.
       4000-INICIO.
           PERFORM 3200-VALIDAR-CABECALHO
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           PERFORM 4100-VALIDAR-GRADE
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-DATAONLY
           END-IF
      *
           MOVE ZEROS                  TO WS-GRAVADOS WS-EXCLUIDOS
      *
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 10
               EVALUATE WS-LN-ACAO(WS-IX)
                   WHEN 'I' PERFORM 4200-INSERIR-LINHA
                   WHEN 'A' PERFORM 4300-ALTERAR-LINHA
                   WHEN 'E' PERFORM 4400-EXCLUIR-LINHA
                   WHEN OTHER CONTINUE
               END-EVALUATE
           END-PERFORM
      *
           EXEC CICS SYNCPOINT END-EXEC
      *
           MOVE SPACES                 TO WS-MENSAGEM
           STRING 'GRAVACAO CONCLUIDA. INCLUIDOS/ALTERADOS: '
                  WS-GRAVADOS
                  '   EXCLUIDOS: ' WS-EXCLUIDOS
                  DELIMITED BY SIZE INTO WS-MENSAGEM
           MOVE WS-MENSAGEM            TO MMENSAGO
      *
           PERFORM 3500-CARREGAR-GRADE.
       4000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4100 - VALIDACAO LINHA A LINHA (RN03 A RN08)                   *
      *----------------------------------------------------------------*
       4100-VALIDAR-GRADE SECTION.
       4100-INICIO.
           MOVE 'N'                    TO WS-ERRO
           MOVE ZEROS                  TO WS-TOT-PROVENTOS
                                          WS-TOT-DESCONTOS
                                          WS-HORAS-EXTRAS
      *
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > 10 OR TEM-ERRO
      *
               IF WS-LN-ACAO(WS-IX) = SPACES OR LOW-VALUES
                   EXIT PERFORM CYCLE
               END-IF
      *
               IF WS-LN-ACAO(WS-IX) NOT = 'I' AND 'A' AND 'E'
                   MOVE 'ACAO INVALIDA NA GRADE. USE I, A OU E'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
      *
               IF WS-LN-EVENTO(WS-IX) = ZEROS
                   MOVE 'RN03 - CODIGO DE EVENTO OBRIGATORIO'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
      *
               IF WS-LN-ACAO(WS-IX) = 'E'
                   EXIT PERFORM CYCLE
               END-IF
      *
      *--- RN03 - EVENTO EXISTENTE E ATIVO ----------------------------
               MOVE WS-LN-EVENTO(WS-IX) TO DCLM-COD-EVENTO
               PERFORM 3700-LER-EVENTO
      *
               IF SQLCODE = +100
                   MOVE 'RN03 - EVENTO INEXISTENTE NA TABELA'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
               IF SQLCODE NOT = 0
                   PERFORM 9000-ERRO-SQL
               END-IF
      *
               IF WS-EV-SITUACAO NOT = 'A'
                   MOVE 'RN03 - EVENTO INATIVO NA TABELA DE RUBRICAS'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
      *
      *--- RN04 - EVENTO DE CALCULO AUTOMATICO ------------------------
               IF WS-EV-TIPO-CALC > 099 AND WS-EV-TIPO-CALC < 200
                   MOVE 'RN04 - EVENTO CALCULADO PELO MOTOR DA FOLHA'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
      *
      *--- RN05 - COERENCIA ENTRE UNIDADE E CONTEUDO ------------------
               IF WS-EV-UNIDADE = 'VL' AND WS-LN-VALOR(WS-IX) = ZEROS
                   MOVE 'RN05 - EVENTO EM VALOR EXIGE VALOR INFORMADO'
                                       TO WS-MENSAGEM
                   MOVE 'S'            TO WS-ERRO
                   EXIT PERFORM
               END-IF
      *
               IF WS-EV-UNIDADE = 'HR' OR 'DI' OR 'PC'
                   IF WS-LN-REFEREN(WS-IX) = ZEROS
                       MOVE 'RN05 - EVENTO EM HORA/DIA EXIGE REFERENCIA'
                                       TO WS-MENSAGEM
                       MOVE 'S'        TO WS-ERRO
                       EXIT PERFORM
                   END-IF
               END-IF
      *
      *--- RN07 - TETO DE HORAS EXTRAS --------------------------------
               IF WS-LN-EVENTO(WS-IX) = CTE-EV-HE-050
               OR WS-LN-EVENTO(WS-IX) = CTE-EV-HE-100
                   ADD WS-LN-REFEREN(WS-IX) TO WS-HORAS-EXTRAS
               END-IF
      *
      *--- ACUMULA PARA A RN08 ----------------------------------------
               IF WS-EV-NATUREZA = 'P'
                   ADD WS-LN-VALOR(WS-IX) TO WS-TOT-PROVENTOS
               END-IF
               IF WS-EV-NATUREZA = 'D'
                   ADD WS-LN-VALOR(WS-IX) TO WS-TOT-DESCONTOS
               END-IF
      *
      *--- RN06 - DUPLICIDADE NA INCLUSAO -----------------------------
               IF WS-LN-ACAO(WS-IX) = 'I'
                   MOVE WS-MATRICULA   TO DCLM-MATRICULA
                   MOVE WS-COMPETENCIA TO DCLM-COMPETENCIA
                   EXEC SQL
                        SELECT COUNT(*)
                          INTO :WS-QTD-DUPLIC
                          FROM SFPADM.TB_MOVIMENTO
                         WHERE MATRICULA   = :DCLM-MATRICULA
                           AND COMPETENCIA = :DCLM-COMPETENCIA
                           AND COD_EVENTO  = :DCLM-COD-EVENTO
                          WITH CS
                   END-EXEC
      *
                   IF WS-QTD-DUPLIC > ZEROS
                       MOVE 'RN06 - EVENTO JA LANCADO. USE A ACAO A'
                                       TO WS-MENSAGEM
                       MOVE 'S'        TO WS-ERRO
                       EXIT PERFORM
                   END-IF
               END-IF
           END-PERFORM
      *
           IF TEM-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN07 - TETO MENSAL DE HORAS EXTRAS -------------------------
           IF WS-HORAS-EXTRAS > 44
               MOVE 'RN07 - HORAS EXTRAS ACIMA DO LIMITE MENSAL DE 44'
                                       TO WS-MENSAGEM
               MOVE 'S'                TO WS-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN08 - COMPROMETIMENTO DA REMUNERACAO ----------------------
           COMPUTE WS-LIMITE-DESCONTO ROUNDED =
                   (WS-SALARIO-EMP + WS-TOT-PROVENTOS) * 70 / 100
      *
           IF WS-TOT-DESCONTOS > WS-LIMITE-DESCONTO
               MOVE 'RN08 - DESCONTOS ACIMA DE 70% DA REMUNERACAO'
                                       TO WS-MENSAGEM
               MOVE 'S'                TO WS-ERRO
           END-IF.
       4100-FIM.
           EXIT.
      *
       4200-INSERIR-LINHA SECTION.
       4200-INICIO.
           MOVE WS-MATRICULA           TO DCLM-MATRICULA
           MOVE WS-COMPETENCIA         TO DCLM-COMPETENCIA
           MOVE WS-LN-EVENTO(WS-IX)    TO DCLM-COD-EVENTO
           MOVE WS-LN-REFEREN(WS-IX)   TO DCLM-REFERENCIA
           MOVE WS-LN-VALOR(WS-IX)     TO DCLM-VALOR
           MOVE EIBTRMID               TO DCLM-USUARIO
      *
           IF WS-LN-TIPO(WS-IX) = SPACES OR LOW-VALUES
               MOVE 'M'                TO DCLM-TIPO-LANC
           ELSE
               MOVE WS-LN-TIPO(WS-IX)  TO DCLM-TIPO-LANC
           END-IF
      *
           EXEC SQL
                INSERT INTO SFPADM.TB_MOVIMENTO
                     ( MATRICULA, COMPETENCIA, COD_EVENTO
                     , REFERENCIA, VALOR, TIPO_LANC
                     , ORIGEM, DT_LANCAMENTO, USUARIO, SIT_CRITICA )
                VALUES
                     ( :DCLM-MATRICULA, :DCLM-COMPETENCIA
                     , :DCLM-COD-EVENTO, :DCLM-REFERENCIA
                     , :DCLM-VALOR, :DCLM-TIPO-LANC
                     , 'ONL', CURRENT DATE, :DCLM-USUARIO, 'A' )
           END-EXEC
      *
           IF SQLCODE = 0
               ADD 1                   TO WS-GRAVADOS
           ELSE
               PERFORM 9000-ERRO-SQL
           END-IF.
       4200-FIM.
           EXIT.
      *
       4300-ALTERAR-LINHA SECTION.
       4300-INICIO.
           MOVE WS-MATRICULA           TO DCLM-MATRICULA
           MOVE WS-COMPETENCIA         TO DCLM-COMPETENCIA
           MOVE WS-LN-EVENTO(WS-IX)    TO DCLM-COD-EVENTO
           MOVE WS-LN-REFEREN(WS-IX)   TO DCLM-REFERENCIA
           MOVE WS-LN-VALOR(WS-IX)     TO DCLM-VALOR
           MOVE EIBTRMID               TO DCLM-USUARIO
      *
           EXEC SQL
                UPDATE SFPADM.TB_MOVIMENTO
                   SET REFERENCIA    = :DCLM-REFERENCIA
                     , VALOR         = :DCLM-VALOR
                     , DT_LANCAMENTO = CURRENT DATE
                     , USUARIO       = :DCLM-USUARIO
                     , SIT_CRITICA   = 'A'
                 WHERE MATRICULA     = :DCLM-MATRICULA
                   AND COMPETENCIA   = :DCLM-COMPETENCIA
                   AND COD_EVENTO    = :DCLM-COD-EVENTO
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0    ADD 1         TO WS-GRAVADOS
               WHEN +100 CONTINUE
               WHEN OTHER PERFORM 9000-ERRO-SQL
           END-EVALUATE.
       4300-FIM.
           EXIT.
      *
       4400-EXCLUIR-LINHA SECTION.
       4400-INICIO.
           MOVE WS-MATRICULA           TO DCLM-MATRICULA
           MOVE WS-COMPETENCIA         TO DCLM-COMPETENCIA
           MOVE WS-LN-EVENTO(WS-IX)    TO DCLM-COD-EVENTO
      *
           EXEC SQL
                DELETE FROM SFPADM.TB_MOVIMENTO
                 WHERE MATRICULA   = :DCLM-MATRICULA
                   AND COMPETENCIA = :DCLM-COMPETENCIA
                   AND COD_EVENTO  = :DCLM-COD-EVENTO
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0    ADD 1         TO WS-EXCLUIDOS
               WHEN +100 CONTINUE
               WHEN OTHER PERFORM 9000-ERRO-SQL
           END-EVALUATE.
       4400-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 - MONTAGEM DO MAPA A PARTIR DA TABELA INTERNA             *
      *================================================================*
       6000-TABELA-PARA-MAPA SECTION.
       6000-INICIO.
           MOVE WS-MATRICULA           TO MMATRICO
           MOVE WS-COMPETENCIA         TO MCOMPETO
           MOVE WS-NOME-EMP            TO MNOMEO
           MOVE ZEROS                  TO WS-TOTAL-GRADE
                                          WS-QTD-LINHAS
      *
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 10
               IF WS-LN-EVENTO(WS-IX) > ZEROS
                   ADD 1               TO WS-QTD-LINHAS
                   ADD WS-LN-VALOR(WS-IX) TO WS-TOTAL-GRADE
               END-IF
           END-PERFORM
      *
           MOVE WS-LN-ACAO(1)      TO ACAO1O
           MOVE WS-LN-EVENTO(1)    TO EVEN1O
           MOVE WS-LN-DESCRICAO(1) TO DESC1O
           MOVE WS-LN-REFEREN(1)   TO REFE1O
           MOVE WS-LN-VALOR(1)     TO VALO1O
           MOVE WS-LN-TIPO(1)      TO TIPO1O
           MOVE WS-LN-ORIGEM(1)    TO ORIG1O
      *
           MOVE WS-LN-ACAO(2)      TO ACAO2O
           MOVE WS-LN-EVENTO(2)    TO EVEN2O
           MOVE WS-LN-DESCRICAO(2) TO DESC2O
           MOVE WS-LN-REFEREN(2)   TO REFE2O
           MOVE WS-LN-VALOR(2)     TO VALO2O
           MOVE WS-LN-TIPO(2)      TO TIPO2O
           MOVE WS-LN-ORIGEM(2)    TO ORIG2O
      *
           MOVE WS-LN-ACAO(3)      TO ACAO3O
           MOVE WS-LN-EVENTO(3)    TO EVEN3O
           MOVE WS-LN-DESCRICAO(3) TO DESC3O
           MOVE WS-LN-REFEREN(3)   TO REFE3O
           MOVE WS-LN-VALOR(3)     TO VALO3O
           MOVE WS-LN-TIPO(3)      TO TIPO3O
           MOVE WS-LN-ORIGEM(3)    TO ORIG3O
      *
           MOVE WS-LN-ACAO(4)      TO ACAO4O
           MOVE WS-LN-EVENTO(4)    TO EVEN4O
           MOVE WS-LN-DESCRICAO(4) TO DESC4O
           MOVE WS-LN-REFEREN(4)   TO REFE4O
           MOVE WS-LN-VALOR(4)     TO VALO4O
           MOVE WS-LN-TIPO(4)      TO TIPO4O
           MOVE WS-LN-ORIGEM(4)    TO ORIG4O
      *
           MOVE WS-LN-ACAO(5)      TO ACAO5O
           MOVE WS-LN-EVENTO(5)    TO EVEN5O
           MOVE WS-LN-DESCRICAO(5) TO DESC5O
           MOVE WS-LN-REFEREN(5)   TO REFE5O
           MOVE WS-LN-VALOR(5)     TO VALO5O
           MOVE WS-LN-TIPO(5)      TO TIPO5O
           MOVE WS-LN-ORIGEM(5)    TO ORIG5O
      *
           MOVE WS-LN-ACAO(6)      TO ACAO6O
           MOVE WS-LN-EVENTO(6)    TO EVEN6O
           MOVE WS-LN-DESCRICAO(6) TO DESC6O
           MOVE WS-LN-REFEREN(6)   TO REFE6O
           MOVE WS-LN-VALOR(6)     TO VALO6O
           MOVE WS-LN-TIPO(6)      TO TIPO6O
           MOVE WS-LN-ORIGEM(6)    TO ORIG6O
      *
           MOVE WS-LN-ACAO(7)      TO ACAO7O
           MOVE WS-LN-EVENTO(7)    TO EVEN7O
           MOVE WS-LN-DESCRICAO(7) TO DESC7O
           MOVE WS-LN-REFEREN(7)   TO REFE7O
           MOVE WS-LN-VALOR(7)     TO VALO7O
           MOVE WS-LN-TIPO(7)      TO TIPO7O
           MOVE WS-LN-ORIGEM(7)    TO ORIG7O
      *
           MOVE WS-LN-ACAO(8)      TO ACAO8O
           MOVE WS-LN-EVENTO(8)    TO EVEN8O
           MOVE WS-LN-DESCRICAO(8) TO DESC8O
           MOVE WS-LN-REFEREN(8)   TO REFE8O
           MOVE WS-LN-VALOR(8)     TO VALO8O
           MOVE WS-LN-TIPO(8)      TO TIPO8O
           MOVE WS-LN-ORIGEM(8)    TO ORIG8O
      *
           MOVE WS-LN-ACAO(9)      TO ACAO9O
           MOVE WS-LN-EVENTO(9)    TO EVEN9O
           MOVE WS-LN-DESCRICAO(9) TO DESC9O
           MOVE WS-LN-REFEREN(9)   TO REFE9O
           MOVE WS-LN-VALOR(9)     TO VALO9O
           MOVE WS-LN-TIPO(9)      TO TIPO9O
           MOVE WS-LN-ORIGEM(9)    TO ORIG9O
      *
           MOVE WS-LN-ACAO(10)     TO ACAOAO
           MOVE WS-LN-EVENTO(10)   TO EVENAO
           MOVE WS-LN-DESCRICAO(10) TO DESCAO
           MOVE WS-LN-REFEREN(10)  TO REFEAO
           MOVE WS-LN-VALOR(10)    TO VALOAO
           MOVE WS-LN-TIPO(10)     TO TIPOAO
           MOVE WS-LN-ORIGEM(10)   TO ORIGAO
      *
           MOVE WS-TOTAL-GRADE         TO MTOTALO
           MOVE WS-QTD-LINHAS          TO MQTDO.
       6000-FIM.
           EXIT.
      *
       6100-ENVIAR-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPMOVO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPMOVO)
                DATAONLY CURSOR FREEKB ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
       7000-OBTER-DATA SECTION.
       7000-INICIO.
           EXEC CICS ASKTIME ABSTIME(WS-HORA-ABS) END-EXEC
           EXEC CICS FORMATTIME
                ABSTIME(WS-HORA-ABS)
                YYYYMMDD(WS-DATA-HOJE)
           END-EXEC.
       7000-FIM.
           EXIT.
      *
       5900-ENCERRAR SECTION.
       5900-INICIO.
           EXEC CICS SEND TEXT
                FROM(WS-TITULO) LENGTH(LENGTH OF WS-TITULO)
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
       9000-ERRO-SQL SECTION.
       9000-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
           MOVE SPACES                 TO WS-MENSAGEM
           STRING 'ERRO DB2 SQLCODE ' SQLCODE
                  ' EM TB_MOVIMENTO - ACIONE O SUPORTE TECNICO'
                  DELIMITED BY SIZE INTO WS-MENSAGEM
           MOVE WS-MENSAGEM            TO MMENSAGO
           PERFORM 6200-ENVIAR-DATAONLY.
       9000-FIM.
           EXIT.
      *
       9999-ABEND SECTION.
       9999-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
           EXEC CICS SEND TEXT
                FROM(WS-TITULO) LENGTH(LENGTH OF WS-TITULO)
                ERASE FREEKB
           END-EXEC
           EXEC CICS RETURN END-EXEC.
       9999-FIM.
           EXIT.
