      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0400                                             *
      * FUNCAO   : FECHAMENTO CONTABIL DA COMPETENCIA                  *
      *            APURA ENCARGOS PATRONAIS, CONSTITUI PROVISOES E     *
      *            GERA A INTERFACE DE PARTIDAS DOBRADAS PARA O RAZAO  *
      *----------------------------------------------------------------*
      * ENTRADAS                                                       *
      *   SFPFOL - FOLHA CALCULADA, DETALHE POR EVENTO      LRECL 120  *
      *   SFPRES - RESUMO POR EMPREGADO                     LRECL 250  *
      *   SFPTAB - TABELAS LEGAIS E PARAMETROS              LRECL 080  *
      *   SYSIN  - CARTAO DE CONTROLE                       LRECL 080  *
      * SAIDAS                                                         *
      *   SFPCTB - INTERFACE CONTABIL                       LRECL 150  *
      *   SFPRCT - RAZAO ANALITICO IMPRESSO                 LRECL 133  *
      *----------------------------------------------------------------*
      * MODELO CONTABIL ADOTADO                                        *
      *   1. PROVENTO ....: D DESPESA DO EVENTO / C FOLHA A PAGAR      *
      *   2. DESCONTO ....: D FOLHA A PAGAR     / C PASSIVO DO EVENTO  *
      *      OBSERVACAO: DESCONTOS COM CONTA DO GRUPO 3 (FALTAS, DSR   *
      *      E ATRASOS) CREDITAM A PROPRIA DESPESA, REDUZINDO-A.       *
      *   3. FGTS .......: D DESPESA FGTS       / C FGTS A RECOLHER    *
      *   4. INSS PATRON.: D DESPESA CPP/RAT/TERCEIROS / C A RECOLHER  *
      *   5. PROVISOES ..: D DESPESA PROVISAO   / C PROVISAO A PAGAR   *
      *   AO FINAL O SALDO DA CONTA FOLHA A PAGAR DEVE SER IGUAL AO    *
      *   LIQUIDO DA FOLHA, E OS DEBITOS DEVEM FECHAR COM OS CREDITOS. *
      *----------------------------------------------------------------*
      * CARTAO SYSIN (POSICIONAL)                                      *
      *   001-006 COMPETENCIA AAAAMM                                   *
      *   008-008 TIPO DE FOLHA                                        *
      *   010-017 DATA DO LANCAMENTO AAAAMMDD                          *
      *   019-024 NUMERO DO LOTE CONTABIL                              *
      *   026-026 GERAR PROVISOES (S/N)                                *
      *----------------------------------------------------------------*
      * CODIGOS DE RETORNO                                             *
      *   00 - FECHAMENTO CONTABIL EQUILIBRADO                         *
      *   04 - FECHAMENTO GERADO COM DIVERGENCIAS DE CONFERENCIA       *
      *   08 - ERRO DE PARAMETRO OU ARQUIVO VAZIO                      *
      *   12 - PARTIDAS DESBALANCEADAS - INTERFACE NAO CONFIAVEL       *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0400.
       AUTHOR. EQUIPE SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-FOLHA    ASSIGN TO SFPFOL
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-FOL.
           SELECT ARQ-RESUMO   ASSIGN TO SFPRES
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-RES.
           SELECT ARQ-TABELA   ASSIGN TO SFPTAB
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-TAB.
           SELECT ARQ-PARAM    ASSIGN TO SYSIN
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-PAR.
           SELECT ARQ-CONTAB   ASSIGN TO SFPCTB
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-CTB.
           SELECT ARQ-RAZAO    ASSIGN TO SFPRCT
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-ST-RCT.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-FOLHA
           RECORD CONTAINS 120 CHARACTERS.
       01  REG-FOLHA-E                     PIC X(120).
      *
       FD  ARQ-RESUMO
           RECORD CONTAINS 250 CHARACTERS.
       01  REG-RESUMO-E                    PIC X(250).
      *
       FD  ARQ-TABELA
           RECORD CONTAINS 80 CHARACTERS.
       01  REG-TABELA-E                    PIC X(080).
      *
       FD  ARQ-PARAM
           RECORD CONTAINS 80 CHARACTERS.
       01  REG-PARAM-E                     PIC X(080).
      *
       FD  ARQ-CONTAB
           RECORD CONTAINS 150 CHARACTERS.
       01  REG-CONTAB-S                    PIC X(150).
      *
       FD  ARQ-RAZAO
           RECORD CONTAINS 133 CHARACTERS.
       01  REG-RAZAO-S                     PIC X(133).
      *
       WORKING-STORAGE SECTION.
      *
       01  WS-STATUS.
           05  WS-ST-FOL       PIC X(002) VALUE '00'.
           05  WS-ST-RES       PIC X(002) VALUE '00'.
           05  WS-ST-TAB       PIC X(002) VALUE '00'.
           05  WS-ST-PAR       PIC X(002) VALUE '00'.
           05  WS-ST-CTB       PIC X(002) VALUE '00'.
           05  WS-ST-RCT       PIC X(002) VALUE '00'.
      *
       01  WS-FLAGS.
           05  WS-FIM-FOL      PIC X(001) VALUE 'N'.
               88  FIM-FOLHA       VALUE 'S'.
           05  WS-FIM-RES      PIC X(001) VALUE 'N'.
               88  FIM-RESUMO      VALUE 'S'.
           05  WS-FIM-TAB      PIC X(001) VALUE 'N'.
               88  FIM-TABELA      VALUE 'S'.
           05  WS-ACHOU        PIC X(001) VALUE 'N'.
           05  WS-RETORNO      PIC 9(002) VALUE ZEROS.
      *
       COPY SFPWFOL.
       COPY SFPWRES.
       COPY SFPWTAB.
       COPY SFPWCTB.
      *
       COPY SFPWCON.
      *
      *--- CARTAO DE CONTROLE -----------------------------------------
       01  WS-CARTAO.
           05  WS-CT-COMPETENCIA   PIC 9(006).
           05  FILLER              PIC X(001).
           05  WS-CT-TIPO-FOLHA    PIC X(001).
           05  FILLER              PIC X(001).
           05  WS-CT-DATA-LANC     PIC 9(008).
           05  FILLER              PIC X(001).
           05  WS-CT-LOTE          PIC 9(006).
           05  FILLER              PIC X(001).
           05  WS-CT-PROVISAO      PIC X(001).
           05  FILLER              PIC X(054).
      *
      *--- PLANO DE CONTAS CORPORATIVO --------------------------------
       01  WS-PLANO-CONTAS.
           05  WS-CT-FOLHA-PAGAR   PIC 9(008) VALUE 21110001.
           05  WS-CT-FGTS-REC      PIC 9(008) VALUE 21380001.
           05  WS-CT-CPP-DESP      PIC 9(008) VALUE 31210002.
           05  WS-CT-CPP-REC       PIC 9(008) VALUE 21310002.
           05  WS-CT-RAT-DESP      PIC 9(008) VALUE 31210003.
           05  WS-CT-RAT-REC       PIC 9(008) VALUE 21310003.
           05  WS-CT-TER-DESP      PIC 9(008) VALUE 31210004.
           05  WS-CT-TER-REC       PIC 9(008) VALUE 21310004.
           05  WS-CT-P13-DESP      PIC 9(008) VALUE 31310001.
           05  WS-CT-P13-PASS      PIC 9(008) VALUE 21410001.
           05  WS-CT-E13-DESP      PIC 9(008) VALUE 31310002.
           05  WS-CT-E13-PASS      PIC 9(008) VALUE 21410002.
           05  WS-CT-PFE-DESP      PIC 9(008) VALUE 31320001.
           05  WS-CT-PFE-PASS      PIC 9(008) VALUE 21420001.
           05  WS-CT-EFE-DESP      PIC 9(008) VALUE 31320002.
           05  WS-CT-EFE-PASS      PIC 9(008) VALUE 21420002.
      *
      *--- ALIQUOTAS PATRONAIS (EM MILESIMOS DE PONTO PERCENTUAL) -----
       01  WS-ALIQUOTAS.
           05  WS-AL-CPP           PIC 9(005) VALUE 20000.
           05  WS-AL-RAT           PIC 9(005) VALUE 02000.
           05  WS-AL-TERCEIROS     PIC 9(005) VALUE 05800.
           05  WS-AL-FGTS          PIC 9(005) VALUE 08000.
      *
      *--- ACUMULADOR DE PARTIDAS POR CONTA E CENTRO DE CUSTO ---------
       01  WS-TABELA-ACUMULO.
           05  WS-QTD-ACUM         PIC S9(004) COMP VALUE ZEROS.
           05  WS-ACUM OCCURS 800 TIMES INDEXED BY WS-IA.
               10  WS-AC-TIPO      PIC X(001).
               10  WS-AC-CONTA     PIC 9(008).
               10  WS-AC-CENTRO    PIC 9(006).
               10  WS-AC-DESCRICAO PIC X(030).
               10  WS-AC-VALOR     PIC S9(013)V99.
      *
      *--- ACUMULADOR POR CENTRO DE CUSTO -----------------------------
       01  WS-TABELA-CENTRO.
           05  WS-QTD-CENTRO       PIC S9(004) COMP VALUE ZEROS.
           05  WS-CC OCCURS 100 TIMES INDEXED BY WS-IC.
               10  WS-CC-CODIGO    PIC 9(006).
               10  WS-CC-BASE-INSS PIC S9(013)V99.
               10  WS-CC-BASE-FGTS PIC S9(013)V99.
               10  WS-CC-PROVENTOS PIC S9(013)V99.
               10  WS-CC-DESCONTOS PIC S9(013)V99.
               10  WS-CC-LIQUIDO   PIC S9(013)V99.
               10  WS-CC-QTD-EMPR  PIC S9(007) COMP-3.
      *
      *--- TOTALIZADORES ----------------------------------------------
       01  WS-TOTAIS.
           05  WS-TOT-DEBITO       PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-CREDITO      PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-PROVENTOS    PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-DESCONTOS    PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-LIQUIDO      PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-BASE-INSS    PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-BASE-FGTS    PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-FGTS-MES     PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-ENCARGOS     PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-PROVISAO     PIC S9(013)V99 VALUE ZEROS.
           05  WS-CUSTO-TOTAL      PIC S9(013)V99 VALUE ZEROS.
           05  WS-SALDO-FOLHA      PIC S9(013)V99 VALUE ZEROS.
           05  WS-DIFERENCA        PIC S9(013)V99 VALUE ZEROS.
      *
       01  WS-CONTADORES.
           05  WS-LIDOS-FOL        PIC 9(007) VALUE ZEROS.
           05  WS-LIDOS-RES        PIC 9(007) VALUE ZEROS.
           05  WS-LIDOS-TAB        PIC 9(007) VALUE ZEROS.
           05  WS-GRAVADOS         PIC 9(007) VALUE ZEROS.
           05  WS-SEQ-LANC         PIC 9(006) VALUE ZEROS.
           05  WS-PAGINA           PIC 9(004) VALUE ZEROS.
           05  WS-LINHA            PIC 9(003) VALUE 99.
      *
       01  WS-CALCULO.
           05  WS-VLR-CPP          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-RAT          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-TER          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-P13          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-E13          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-PFE          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-EFE          PIC S9(013)V99 VALUE ZEROS.
           05  WS-VLR-FGTS         PIC S9(013)V99 VALUE ZEROS.
           05  WS-AUX-VALOR        PIC S9(013)V99 VALUE ZEROS.
           05  WS-CHAVE-TIPO       PIC X(001) VALUE SPACES.
           05  WS-CHAVE-CONTA      PIC 9(008) VALUE ZEROS.
           05  WS-CHAVE-CENTRO     PIC 9(006) VALUE ZEROS.
           05  WS-CHAVE-DESCR      PIC X(030) VALUE SPACES.
      *
      *--- LINHAS DE RELATORIO ----------------------------------------
       01  WS-CAB-01.
           05  FILLER          PIC X(001) VALUE SPACES.
           05  FILLER          PIC X(008) VALUE 'SFP0400 '.
           05  FILLER          PIC X(035) VALUE
               'INDUSTRIA MERIDIONAL DE COMPONENTES'.
           05  FILLER          PIC X(033) VALUE
               '   RAZAO ANALITICO DA FOLHA      '.
           05  FILLER          PIC X(011) VALUE 'COMPETENCIA'.
           05  FILLER          PIC X(001) VALUE SPACES.
           05  CAB-MES         PIC X(002).
           05  FILLER          PIC X(001) VALUE '/'.
           05  CAB-ANO         PIC X(004).
           05  FILLER          PIC X(009) VALUE '   PAGINA'.
           05  CAB-PAGINA      PIC ZZZ9.
           05  FILLER          PIC X(024) VALUE SPACES.
      *
       01  WS-CAB-02.
           05  FILLER          PIC X(133) VALUE ALL '='.
      *
       01  WS-CAB-03.
           05  FILLER          PIC X(002) VALUE SPACES.
           05  FILLER          PIC X(009) VALUE 'CONTA'.
           05  FILLER          PIC X(032) VALUE 'HISTORICO'.
           05  FILLER          PIC X(009) VALUE 'C.CUSTO'.
           05  FILLER          PIC X(019) VALUE
               '           DEBITO  '.
           05  FILLER          PIC X(019) VALUE
               '          CREDITO  '.
           05  FILLER          PIC X(043) VALUE SPACES.
      *
       01  WS-LIN-DET.
           05  FILLER          PIC X(002) VALUE SPACES.
           05  DET-CONTA       PIC 9(008).
           05  FILLER          PIC X(001) VALUE SPACES.
           05  DET-HISTORICO   PIC X(032).
           05  DET-CENTRO      PIC 9(006).
           05  FILLER          PIC X(003) VALUE SPACES.
           05  DET-DEBITO      PIC ZZZ.ZZZ.ZZ9,99  BLANK WHEN ZERO.
           05  FILLER          PIC X(004) VALUE SPACES.
           05  DET-CREDITO     PIC ZZZ.ZZZ.ZZ9,99  BLANK WHEN ZERO.
           05  FILLER          PIC X(043) VALUE SPACES.
      *
       01  WS-LIN-TOT.
           05  FILLER          PIC X(002) VALUE SPACES.
           05  TOT-TEXTO       PIC X(050).
           05  TOT-VALOR       PIC ZZZ.ZZZ.ZZ9,99-.
           05  FILLER          PIC X(066) VALUE SPACES.
      *
       01  WS-LIN-BRANCO       PIC X(133) VALUE SPACES.
      *
      *================================================================*
       PROCEDURE DIVISION.
      *================================================================*
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR
           PERFORM 3000-FINALIZAR
           MOVE WS-RETORNO TO RETURN-CODE
           STOP RUN.
       0000-FIM.
           EXIT.
      *
      *================================================================*
      * 1000 - ABERTURA E LEITURA DOS PARAMETROS                       *
      *================================================================*
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           OPEN INPUT  ARQ-PARAM
           IF WS-ST-PAR NOT = '00'
               DISPLAY 'SFP0400 - ERRO NA ABERTURA DO SYSIN: '
                       WS-ST-PAR
               MOVE 08 TO WS-RETORNO
               MOVE 08 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           READ ARQ-PARAM INTO WS-CARTAO
               AT END
                  DISPLAY 'SFP0400 - CARTAO DE CONTROLE AUSENTE'
                  MOVE 08 TO WS-RETORNO
                  MOVE 08 TO RETURN-CODE
                  STOP RUN
           END-READ
           CLOSE ARQ-PARAM
      *
           IF WS-CT-COMPETENCIA = ZEROS
               DISPLAY 'SFP0400 - COMPETENCIA INVALIDA NO CARTAO'
               MOVE 08 TO WS-RETORNO
               MOVE 08 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           DISPLAY '========================================='
           DISPLAY 'SFP0400 - FECHAMENTO CONTABIL DA FOLHA'
           DISPLAY '  COMPETENCIA...: ' WS-CT-COMPETENCIA
           DISPLAY '  TIPO DE FOLHA.: ' WS-CT-TIPO-FOLHA
           DISPLAY '  DATA DO LANC..: ' WS-CT-DATA-LANC
           DISPLAY '  LOTE CONTABIL.: ' WS-CT-LOTE
           DISPLAY '  GERA PROVISOES: ' WS-CT-PROVISAO
           DISPLAY '========================================='
      *
           OPEN INPUT  ARQ-FOLHA
                       ARQ-RESUMO
                       ARQ-TABELA
                OUTPUT ARQ-CONTAB
                       ARQ-RAZAO
      *
           IF WS-ST-FOL NOT = '00' OR WS-ST-RES NOT = '00'
               DISPLAY 'SFP0400 - ERRO DE ABERTURA FOL/RES: '
                       WS-ST-FOL ' ' WS-ST-RES
               MOVE 08 TO WS-RETORNO
               MOVE 08 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           PERFORM 1100-CARREGAR-PARAMETROS
      *
           MOVE WS-CT-COMPETENCIA(1:4) TO CAB-ANO
           MOVE WS-CT-COMPETENCIA(5:2) TO CAB-MES.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - ALIQUOTAS PATRONAIS PARAMETRIZADAS NA TABELA LEGAL      *
      *----------------------------------------------------------------*
       1100-CARREGAR-PARAMETROS SECTION.
       1100-INICIO.
           PERFORM UNTIL FIM-TABELA
               READ ARQ-TABELA INTO REG-TABELA
                   AT END SET FIM-TABELA TO TRUE
                   NOT AT END
                       ADD 1 TO WS-LIDOS-TAB
                       IF TAB-PARAMETRO
                           EVALUATE TAB-CHAVE
                               WHEN 'ALIQ-FGTS      '
                                    COMPUTE WS-AL-FGTS =
                                            TAB-ALIQUOTA * 1000
                               WHEN OTHER
                                    CONTINUE
                           END-EVALUATE
                       END-IF
               END-READ
           END-PERFORM
           CLOSE ARQ-TABELA
      *
           DISPLAY 'SFP0400 - PARAMETROS LIDOS: ' WS-LIDOS-TAB
           DISPLAY '  CPP ' WS-AL-CPP ' RAT ' WS-AL-RAT
                   ' TERCEIROS ' WS-AL-TERCEIROS
                   ' FGTS ' WS-AL-FGTS.
       1100-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - PROCESSAMENTO                                           *
      *================================================================*
       2000-PROCESSAR SECTION.
       2000-INICIO.
           PERFORM 2100-ACUMULAR-FOLHA
           PERFORM 2200-ACUMULAR-RESUMO
      *
           IF WS-LIDOS-FOL = ZEROS
               DISPLAY 'SFP0400 - FOLHA CALCULADA VAZIA'
               MOVE 08 TO WS-RETORNO
               GO TO 2000-FIM
           END-IF
      *
           PERFORM 2300-APURAR-ENCARGOS
      *
           IF WS-CT-PROVISAO = 'S'
               PERFORM 2400-APURAR-PROVISOES
           END-IF
      *
           PERFORM 2500-GERAR-PARTIDAS
           PERFORM 2600-CONFERIR-FECHAMENTO.
       2000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2100 - ACUMULA A FOLHA POR CONTA CONTABIL E CENTRO DE CUSTO    *
      *----------------------------------------------------------------*
       2100-ACUMULAR-FOLHA SECTION.
       2100-INICIO.
           PERFORM UNTIL FIM-FOLHA
               READ ARQ-FOLHA INTO REG-FOLHA
                   AT END SET FIM-FOLHA TO TRUE
                   NOT AT END
                       PERFORM 2110-TRATAR-EVENTO
               END-READ
           END-PERFORM
           CLOSE ARQ-FOLHA
           DISPLAY 'SFP0400 - EVENTOS LIDOS DA FOLHA: ' WS-LIDOS-FOL.
       2100-FIM.
           EXIT.
      *
       2110-TRATAR-EVENTO SECTION.
       2110-INICIO.
           IF FOL-COMPETENCIA NOT = WS-CT-COMPETENCIA
               GO TO 2110-FIM
           END-IF
           IF FOL-TIPO-FOLHA NOT = WS-CT-TIPO-FOLHA
               GO TO 2110-FIM
           END-IF
      *
           ADD 1 TO WS-LIDOS-FOL
      *
           MOVE FOL-CONTA-CONTABIL     TO WS-CHAVE-CONTA
           MOVE FOL-CENTRO-CUSTO       TO WS-CHAVE-CENTRO
           MOVE FOL-DESCRICAO          TO WS-CHAVE-DESCR
           MOVE FOL-VALOR              TO WS-AUX-VALOR
      *
           EVALUATE FOL-NATUREZA
               WHEN 'P'
      *--- PROVENTO GERA DESPESA (DEBITO) -----------------------------
                    MOVE 'P'           TO WS-CHAVE-TIPO
                    PERFORM 2900-ACUMULAR
                    ADD FOL-VALOR      TO WS-TOT-PROVENTOS
      *
               WHEN 'D'
      *--- DESCONTO GERA PASSIVO OU ESTORNO DE DESPESA (CREDITO) ------
                    MOVE 'D'           TO WS-CHAVE-TIPO
                    PERFORM 2900-ACUMULAR
                    ADD FOL-VALOR      TO WS-TOT-DESCONTOS
      *
               WHEN 'I'
      *--- INFORMATIVO: SOMENTE O FGTS DO MES GERA CONTABILIZACAO -----
                    IF FOL-COD-EVENTO = CTE-EV-FGTS-MES
                        ADD FOL-VALOR  TO WS-TOT-FGTS-MES
                    END-IF
      *
               WHEN OTHER
                    CONTINUE
           END-EVALUATE.
       2110-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2200 - ACUMULA O RESUMO POR CENTRO DE CUSTO                    *
      *----------------------------------------------------------------*
       2200-ACUMULAR-RESUMO SECTION.
       2200-INICIO.
           PERFORM UNTIL FIM-RESUMO
               READ ARQ-RESUMO INTO REG-RESUMO
                   AT END SET FIM-RESUMO TO TRUE
                   NOT AT END
                       IF RES-COMPETENCIA = WS-CT-COMPETENCIA
                       AND RES-TIPO-FOLHA = WS-CT-TIPO-FOLHA
                           ADD 1 TO WS-LIDOS-RES
                           PERFORM 2210-ACUMULAR-CENTRO
                       END-IF
               END-READ
           END-PERFORM
           CLOSE ARQ-RESUMO
           DISPLAY 'SFP0400 - EMPREGADOS NO RESUMO..: ' WS-LIDOS-RES.
       2200-FIM.
           EXIT.
      *
       2210-ACUMULAR-CENTRO SECTION.
       2210-INICIO.
           MOVE 'N' TO WS-ACHOU
      *
           PERFORM VARYING WS-IC FROM 1 BY 1
                   UNTIL WS-IC > WS-QTD-CENTRO OR WS-ACHOU = 'S'
               IF WS-CC-CODIGO(WS-IC) = RES-CENTRO-CUSTO
                   MOVE 'S' TO WS-ACHOU
                   PERFORM 2220-SOMAR-CENTRO
               END-IF
           END-PERFORM
      *
           IF WS-ACHOU = 'N'
               IF WS-QTD-CENTRO >= 100
                   DISPLAY 'SFP0400 - ESTOURO DA TABELA DE CENTROS'
                   MOVE 12 TO WS-RETORNO
                   MOVE 12 TO RETURN-CODE
                   STOP RUN
               END-IF
               ADD 1 TO WS-QTD-CENTRO
               SET WS-IC TO WS-QTD-CENTRO
               MOVE RES-CENTRO-CUSTO TO WS-CC-CODIGO(WS-IC)
               MOVE ZEROS            TO WS-CC-BASE-INSS(WS-IC)
                                        WS-CC-BASE-FGTS(WS-IC)
                                        WS-CC-PROVENTOS(WS-IC)
                                        WS-CC-DESCONTOS(WS-IC)
                                        WS-CC-LIQUIDO(WS-IC)
                                        WS-CC-QTD-EMPR(WS-IC)
               PERFORM 2220-SOMAR-CENTRO
           END-IF
      *
           ADD RES-BASE-INSS     TO WS-TOT-BASE-INSS
           ADD RES-BASE-FGTS     TO WS-TOT-BASE-FGTS
           ADD RES-LIQUIDO       TO WS-TOT-LIQUIDO.
       2210-FIM.
           EXIT.
      *
       2220-SOMAR-CENTRO SECTION.
       2220-INICIO.
           ADD RES-BASE-INSS     TO WS-CC-BASE-INSS(WS-IC)
           ADD RES-BASE-FGTS     TO WS-CC-BASE-FGTS(WS-IC)
           ADD RES-TOT-PROVENTOS TO WS-CC-PROVENTOS(WS-IC)
           ADD RES-TOT-DESCONTOS TO WS-CC-DESCONTOS(WS-IC)
           ADD RES-LIQUIDO       TO WS-CC-LIQUIDO(WS-IC)
           ADD 1                 TO WS-CC-QTD-EMPR(WS-IC).
       2220-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2300 - ENCARGOS PATRONAIS POR CENTRO DE CUSTO                  *
      *        CPP 20%, RAT 2% E TERCEIROS 5,8% SOBRE A BASE INSS      *
      *        FGTS 8% SOBRE A BASE FGTS                               *
      *----------------------------------------------------------------*
       2300-APURAR-ENCARGOS SECTION.
       2300-INICIO.
           PERFORM VARYING WS-IC FROM 1 BY 1
                   UNTIL WS-IC > WS-QTD-CENTRO
      *
               MOVE WS-CC-CODIGO(WS-IC) TO WS-CHAVE-CENTRO
               MOVE 'E'                 TO WS-CHAVE-TIPO
      *
      *--- CONTRIBUICAO PREVIDENCIARIA PATRONAL -----------------------
               COMPUTE WS-VLR-CPP ROUNDED =
                       WS-CC-BASE-INSS(WS-IC) * WS-AL-CPP / 100000
               IF WS-VLR-CPP > ZEROS
                   MOVE WS-CT-CPP-DESP  TO WS-CHAVE-CONTA
                   MOVE 'INSS PATRONAL 20%'
                                        TO WS-CHAVE-DESCR
                   MOVE WS-VLR-CPP      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-CPP       TO WS-TOT-ENCARGOS
               END-IF
      *
      *--- RISCO AMBIENTAL DO TRABALHO --------------------------------
               COMPUTE WS-VLR-RAT ROUNDED =
                       WS-CC-BASE-INSS(WS-IC) * WS-AL-RAT / 100000
               IF WS-VLR-RAT > ZEROS
                   MOVE WS-CT-RAT-DESP  TO WS-CHAVE-CONTA
                   MOVE 'RAT / SAT 2%'  TO WS-CHAVE-DESCR
                   MOVE WS-VLR-RAT      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-RAT       TO WS-TOT-ENCARGOS
               END-IF
      *
      *--- TERCEIROS (SISTEMA S, SALARIO EDUCACAO, INCRA) -------------
               COMPUTE WS-VLR-TER ROUNDED =
                       WS-CC-BASE-INSS(WS-IC) * WS-AL-TERCEIROS
                       / 100000
               IF WS-VLR-TER > ZEROS
                   MOVE WS-CT-TER-DESP  TO WS-CHAVE-CONTA
                   MOVE 'TERCEIROS 5,8%' TO WS-CHAVE-DESCR
                   MOVE WS-VLR-TER      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-TER       TO WS-TOT-ENCARGOS
               END-IF
           END-PERFORM
      *
           DISPLAY 'SFP0400 - ENCARGOS PATRONAIS....: '
                   WS-TOT-ENCARGOS.
       2300-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2400 - PROVISOES DE 13O SALARIO E FERIAS                       *
      *        13O    : 1/12 DA REMUNERACAO                            *
      *        FERIAS : 1/12 DA REMUNERACAO ACRESCIDO DE 1/3           *
      *        ENCARGOS SOBRE PROVISAO: CPP+RAT+TERCEIROS+FGTS         *
      *----------------------------------------------------------------*
       2400-APURAR-PROVISOES SECTION.
       2400-INICIO.
           PERFORM VARYING WS-IC FROM 1 BY 1
                   UNTIL WS-IC > WS-QTD-CENTRO
      *
               MOVE WS-CC-CODIGO(WS-IC) TO WS-CHAVE-CENTRO
               MOVE 'V'                 TO WS-CHAVE-TIPO
      *
      *--- PROVISAO DE 13O SALARIO ------------------------------------
               COMPUTE WS-VLR-P13 ROUNDED =
                       WS-CC-PROVENTOS(WS-IC) / 12
               IF WS-VLR-P13 > ZEROS
                   MOVE WS-CT-P13-DESP  TO WS-CHAVE-CONTA
                   MOVE 'PROVISAO DE 13O SALARIO'
                                        TO WS-CHAVE-DESCR
                   MOVE WS-VLR-P13      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-P13       TO WS-TOT-PROVISAO
               END-IF
      *
      *--- ENCARGOS SOBRE A PROVISAO DE 13O ---------------------------
               COMPUTE WS-VLR-E13 ROUNDED =
                       WS-VLR-P13
                       * (WS-AL-CPP + WS-AL-RAT + WS-AL-TERCEIROS
                          + WS-AL-FGTS) / 100000
               IF WS-VLR-E13 > ZEROS
                   MOVE WS-CT-E13-DESP  TO WS-CHAVE-CONTA
                   MOVE 'ENCARGOS SOBRE PROVISAO 13O'
                                        TO WS-CHAVE-DESCR
                   MOVE WS-VLR-E13      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-E13       TO WS-TOT-PROVISAO
               END-IF
      *
      *--- PROVISAO DE FERIAS COM O TERCO CONSTITUCIONAL --------------
               COMPUTE WS-VLR-PFE ROUNDED =
                       WS-CC-PROVENTOS(WS-IC) / 12
                       + (WS-CC-PROVENTOS(WS-IC) / 12 / 3)
               IF WS-VLR-PFE > ZEROS
                   MOVE WS-CT-PFE-DESP  TO WS-CHAVE-CONTA
                   MOVE 'PROVISAO DE FERIAS + 1/3'
                                        TO WS-CHAVE-DESCR
                   MOVE WS-VLR-PFE      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-PFE       TO WS-TOT-PROVISAO
               END-IF
      *
      *--- ENCARGOS SOBRE A PROVISAO DE FERIAS ------------------------
               COMPUTE WS-VLR-EFE ROUNDED =
                       WS-VLR-PFE
                       * (WS-AL-CPP + WS-AL-RAT + WS-AL-TERCEIROS
                          + WS-AL-FGTS) / 100000
               IF WS-VLR-EFE > ZEROS
                   MOVE WS-CT-EFE-DESP  TO WS-CHAVE-CONTA
                   MOVE 'ENCARGOS SOBRE PROVISAO FERIAS'
                                        TO WS-CHAVE-DESCR
                   MOVE WS-VLR-EFE      TO WS-AUX-VALOR
                   PERFORM 2900-ACUMULAR
                   ADD WS-VLR-EFE       TO WS-TOT-PROVISAO
               END-IF
           END-PERFORM
      *
           DISPLAY 'SFP0400 - PROVISOES DO PERIODO..: '
                   WS-TOT-PROVISAO.
       2400-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2500 - GERACAO DAS PARTIDAS DOBRADAS                           *
      *----------------------------------------------------------------*
       2500-GERAR-PARTIDAS SECTION.
       2500-INICIO.
           PERFORM 5000-CABECALHO
      *
           PERFORM VARYING WS-IA FROM 1 BY 1
                   UNTIL WS-IA > WS-QTD-ACUM
      *
               IF WS-AC-VALOR(WS-IA) = ZEROS
                   EXIT PERFORM CYCLE
               END-IF
      *
               MOVE WS-CT-COMPETENCIA   TO CTB-COMPETENCIA
               MOVE WS-CT-DATA-LANC     TO CTB-DATA-LANCAMENTO
               MOVE WS-CT-LOTE          TO CTB-LOTE
               MOVE WS-AC-CENTRO(WS-IA) TO CTB-CENTRO-CUSTO
               MOVE WS-AC-VALOR(WS-IA)  TO CTB-VALOR
               MOVE WS-AC-DESCRICAO(WS-IA) TO CTB-HISTORICO
               MOVE 'SFP'               TO CTB-ORIGEM
               MOVE WS-AC-TIPO(WS-IA)   TO CTB-TIPO-LANCAMENTO
               MOVE SPACES              TO CTB-FILLER
      *
               EVALUATE WS-AC-TIPO(WS-IA)
      *
                   WHEN 'P'
      *--- DESPESA DE PESSOAL CONTRA FOLHA A PAGAR --------------------
                        MOVE WS-AC-CONTA(WS-IA) TO CTB-CONTA-DEBITO
                        MOVE WS-CT-FOLHA-PAGAR  TO CTB-CONTA-CREDITO
      *
                   WHEN 'D'
      *--- FOLHA A PAGAR CONTRA O PASSIVO DO DESCONTO -----------------
                        MOVE WS-CT-FOLHA-PAGAR  TO CTB-CONTA-DEBITO
                        MOVE WS-AC-CONTA(WS-IA) TO CTB-CONTA-CREDITO
      *
                   WHEN 'E'
      *--- ENCARGO PATRONAL: DESPESA CONTRA O RECOLHIMENTO ------------
                        MOVE WS-AC-CONTA(WS-IA) TO CTB-CONTA-DEBITO
                        EVALUATE WS-AC-CONTA(WS-IA)
                            WHEN WS-CT-CPP-DESP
                                 MOVE WS-CT-CPP-REC
                                                TO CTB-CONTA-CREDITO
                            WHEN WS-CT-RAT-DESP
                                 MOVE WS-CT-RAT-REC
                                                TO CTB-CONTA-CREDITO
                            WHEN WS-CT-TER-DESP
                                 MOVE WS-CT-TER-REC
                                                TO CTB-CONTA-CREDITO
                            WHEN OTHER
                                 MOVE WS-CT-FGTS-REC
                                                TO CTB-CONTA-CREDITO
                        END-EVALUATE
      *
                   WHEN 'V'
      *--- PROVISAO: DESPESA CONTRA O PASSIVO PROVISIONADO ------------
                        MOVE WS-AC-CONTA(WS-IA) TO CTB-CONTA-DEBITO
                        EVALUATE WS-AC-CONTA(WS-IA)
                            WHEN WS-CT-P13-DESP
                                 MOVE WS-CT-P13-PASS
                                                TO CTB-CONTA-CREDITO
                            WHEN WS-CT-E13-DESP
                                 MOVE WS-CT-E13-PASS
                                                TO CTB-CONTA-CREDITO
                            WHEN WS-CT-PFE-DESP
                                 MOVE WS-CT-PFE-PASS
                                                TO CTB-CONTA-CREDITO
                            WHEN OTHER
                                 MOVE WS-CT-EFE-PASS
                                                TO CTB-CONTA-CREDITO
                        END-EVALUATE
      *
                   WHEN OTHER
                        EXIT PERFORM CYCLE
               END-EVALUATE
      *
               ADD 1 TO WS-SEQ-LANC
               MOVE WS-SEQ-LANC         TO CTB-SEQUENCIA
      *
               WRITE REG-CONTAB-S FROM REG-CONTABIL
               ADD 1 TO WS-GRAVADOS
      *
               ADD WS-AC-VALOR(WS-IA)   TO WS-TOT-DEBITO
               ADD WS-AC-VALOR(WS-IA)   TO WS-TOT-CREDITO
      *
               PERFORM 5100-IMPRIMIR-PARTIDA
           END-PERFORM
      *
      *--- LANCAMENTO DO FGTS DO MES (VALOR JA CALCULADO PELO MOTOR) --
           IF WS-TOT-FGTS-MES > ZEROS
               PERFORM 2550-LANCAR-FGTS
           END-IF
      *
           DISPLAY 'SFP0400 - PARTIDAS GERADAS......: ' WS-GRAVADOS.
       2500-FIM.
           EXIT.
      *
       2550-LANCAR-FGTS SECTION.
       2550-INICIO.
           MOVE WS-CT-COMPETENCIA   TO CTB-COMPETENCIA
           MOVE WS-CT-DATA-LANC     TO CTB-DATA-LANCAMENTO
           MOVE WS-CT-LOTE          TO CTB-LOTE
           MOVE ZEROS               TO CTB-CENTRO-CUSTO
           MOVE WS-TOT-FGTS-MES     TO CTB-VALOR
           MOVE 'FGTS DO MES 8% - DEPOSITO'
                                    TO CTB-HISTORICO
           MOVE 'SFP'               TO CTB-ORIGEM
           MOVE 'E'                 TO CTB-TIPO-LANCAMENTO
           MOVE SPACES              TO CTB-FILLER
           MOVE 31210001            TO CTB-CONTA-DEBITO
           MOVE WS-CT-FGTS-REC      TO CTB-CONTA-CREDITO
      *
           ADD 1 TO WS-SEQ-LANC
           MOVE WS-SEQ-LANC         TO CTB-SEQUENCIA
      *
           WRITE REG-CONTAB-S FROM REG-CONTABIL
           ADD 1 TO WS-GRAVADOS
      *
           ADD WS-TOT-FGTS-MES      TO WS-TOT-DEBITO
           ADD WS-TOT-FGTS-MES      TO WS-TOT-CREDITO
           ADD WS-TOT-FGTS-MES      TO WS-TOT-ENCARGOS
      *
           PERFORM 5100-IMPRIMIR-PARTIDA.
       2550-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2600 - CONFERENCIA DO FECHAMENTO                               *
      *----------------------------------------------------------------*
       2600-CONFERIR-FECHAMENTO SECTION.
       2600-INICIO.
      *--- O SALDO DA CONTA FOLHA A PAGAR DEVE SER O LIQUIDO ----------
           COMPUTE WS-SALDO-FOLHA =
                   WS-TOT-PROVENTOS - WS-TOT-DESCONTOS
      *
           COMPUTE WS-DIFERENCA = WS-SALDO-FOLHA - WS-TOT-LIQUIDO
      *
           COMPUTE WS-CUSTO-TOTAL =
                   WS-TOT-PROVENTOS + WS-TOT-ENCARGOS
                   + WS-TOT-PROVISAO
      *
           PERFORM 5300-IMPRIMIR-TOTAIS
      *
           DISPLAY ' '
           DISPLAY '--- CONFERENCIA DO FECHAMENTO CONTABIL ---'
           DISPLAY '  TOTAL DE DEBITOS.......: ' WS-TOT-DEBITO
           DISPLAY '  TOTAL DE CREDITOS......: ' WS-TOT-CREDITO
           DISPLAY '  SALDO FOLHA A PAGAR....: ' WS-SALDO-FOLHA
           DISPLAY '  LIQUIDO DO RESUMO......: ' WS-TOT-LIQUIDO
           DISPLAY '  DIFERENCA..............: ' WS-DIFERENCA
           DISPLAY '  CUSTO TOTAL DE PESSOAL.: ' WS-CUSTO-TOTAL
           DISPLAY '------------------------------------------'
      *
           IF WS-TOT-DEBITO NOT = WS-TOT-CREDITO
               DISPLAY 'SFP0400 - PARTIDAS DESBALANCEADAS'
               MOVE 12 TO WS-RETORNO
               GO TO 2600-FIM
           END-IF
      *
           IF WS-DIFERENCA NOT = ZEROS
               DISPLAY 'SFP0400 - DIVERGENCIA ENTRE FOLHA E RESUMO'
               MOVE 04 TO WS-RETORNO
           END-IF.
       2600-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2900 - ACUMULACAO NA TABELA DE PARTIDAS                        *
      *----------------------------------------------------------------*
       2900-ACUMULAR SECTION.
       2900-INICIO.
           MOVE 'N' TO WS-ACHOU
      *
           PERFORM VARYING WS-IA FROM 1 BY 1
                   UNTIL WS-IA > WS-QTD-ACUM OR WS-ACHOU = 'S'
               IF WS-AC-TIPO(WS-IA)   = WS-CHAVE-TIPO
              AND WS-AC-CONTA(WS-IA)  = WS-CHAVE-CONTA
              AND WS-AC-CENTRO(WS-IA) = WS-CHAVE-CENTRO
                   MOVE 'S' TO WS-ACHOU
                   ADD WS-AUX-VALOR TO WS-AC-VALOR(WS-IA)
               END-IF
           END-PERFORM
      *
           IF WS-ACHOU = 'N'
               IF WS-QTD-ACUM >= 800
                   DISPLAY 'SFP0400 - ESTOURO DA TABELA DE PARTIDAS'
                   MOVE 12 TO WS-RETORNO
                   MOVE 12 TO RETURN-CODE
                   STOP RUN
               END-IF
               ADD 1 TO WS-QTD-ACUM
               SET WS-IA TO WS-QTD-ACUM
               MOVE WS-CHAVE-TIPO   TO WS-AC-TIPO(WS-IA)
               MOVE WS-CHAVE-CONTA  TO WS-AC-CONTA(WS-IA)
               MOVE WS-CHAVE-CENTRO TO WS-AC-CENTRO(WS-IA)
               MOVE WS-CHAVE-DESCR  TO WS-AC-DESCRICAO(WS-IA)
               MOVE WS-AUX-VALOR    TO WS-AC-VALOR(WS-IA)
           END-IF.
       2900-FIM.
           EXIT.
      *
      *================================================================*
      * 5000 - ROTINAS DE IMPRESSAO                                    *
      *================================================================*
       5000-CABECALHO SECTION.
       5000-INICIO.
           ADD 1 TO WS-PAGINA
           MOVE WS-PAGINA TO CAB-PAGINA
           WRITE REG-RAZAO-S FROM WS-CAB-01
           WRITE REG-RAZAO-S FROM WS-CAB-02
           WRITE REG-RAZAO-S FROM WS-CAB-03
           WRITE REG-RAZAO-S FROM WS-CAB-02
           MOVE 4 TO WS-LINHA.
       5000-FIM.
           EXIT.
      *
       5100-IMPRIMIR-PARTIDA SECTION.
       5100-INICIO.
           MOVE CTB-CONTA-DEBITO  TO DET-CONTA
           MOVE CTB-HISTORICO     TO DET-HISTORICO
           MOVE CTB-CENTRO-CUSTO  TO DET-CENTRO
           MOVE CTB-VALOR         TO DET-DEBITO
           MOVE ZEROS             TO DET-CREDITO
           PERFORM 5200-ESCREVER-LINHA
      *
           MOVE CTB-CONTA-CREDITO TO DET-CONTA
           MOVE SPACES            TO DET-HISTORICO
           MOVE CTB-CENTRO-CUSTO  TO DET-CENTRO
           MOVE ZEROS             TO DET-DEBITO
           MOVE CTB-VALOR         TO DET-CREDITO
           PERFORM 5200-ESCREVER-LINHA.
       5100-FIM.
           EXIT.
      *
       5200-ESCREVER-LINHA SECTION.
       5200-INICIO.
           IF WS-LINHA > 58
               PERFORM 5000-CABECALHO
           END-IF
           WRITE REG-RAZAO-S FROM WS-LIN-DET
           ADD 1 TO WS-LINHA.
       5200-FIM.
           EXIT.
      *
       5300-IMPRIMIR-TOTAIS SECTION.
       5300-INICIO.
           WRITE REG-RAZAO-S FROM WS-LIN-BRANCO
           WRITE REG-RAZAO-S FROM WS-CAB-02
      *
           MOVE 'TOTAL DE DEBITOS'          TO TOT-TEXTO
           MOVE WS-TOT-DEBITO               TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'TOTAL DE CREDITOS'         TO TOT-TEXTO
           MOVE WS-TOT-CREDITO              TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'PROVENTOS DA FOLHA'        TO TOT-TEXTO
           MOVE WS-TOT-PROVENTOS            TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'DESCONTOS DA FOLHA'        TO TOT-TEXTO
           MOVE WS-TOT-DESCONTOS            TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'LIQUIDO A PAGAR'           TO TOT-TEXTO
           MOVE WS-TOT-LIQUIDO              TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'ENCARGOS PATRONAIS'        TO TOT-TEXTO
           MOVE WS-TOT-ENCARGOS             TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE 'PROVISOES CONSTITUIDAS'    TO TOT-TEXTO
           MOVE WS-TOT-PROVISAO             TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
      *
           MOVE WS-CAB-02 TO REG-RAZAO-S
           WRITE REG-RAZAO-S
      *
           MOVE 'CUSTO TOTAL DE PESSOAL DA COMPETENCIA'
                                            TO TOT-TEXTO
           MOVE WS-CUSTO-TOTAL              TO TOT-VALOR
           WRITE REG-RAZAO-S FROM WS-LIN-TOT
           WRITE REG-RAZAO-S FROM WS-CAB-02.
       5300-FIM.
           EXIT.
      *
      *================================================================*
       3000-FINALIZAR SECTION.
       3000-INICIO.
           CLOSE ARQ-CONTAB
                 ARQ-RAZAO
      *
           DISPLAY ' '
           DISPLAY 'SFP0400 - ENCERRADO COM RETURN-CODE ' WS-RETORNO.
       3000-FIM.
           EXIT.
