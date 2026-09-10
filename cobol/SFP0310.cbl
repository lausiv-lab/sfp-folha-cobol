      *================================================================*
      * PROGRAMA : SFP0310                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : MODULO DE APURACAO DE ENCARGOS E TRIBUTOS           *
      *            (1) INSS - TABELA PROGRESSIVA POR FAIXAS COM        *
      *                APLICACAO DE ALIQUOTA MARGINAL E TETO           *
      *            (2) IRRF - COMPARACAO AUTOMATICA ENTRE O MODELO     *
      *                DE DEDUCOES LEGAIS E O DESCONTO SIMPLIFICADO,   *
      *                PREVALECENDO O MAIS FAVORAVEL AO CONTRIBUINTE   *
      *            (3) FGTS - DEPOSITO MENSAL SOBRE BASE INCIDENTE     *
      *            (4) SALARIO FAMILIA - COTA POR FILHO ATE 14 ANOS    *
      *            (5) INSS SOBRE 13O SALARIO (CALCULO EXCLUSIVO)      *
      * TIPO     : SUBPROGRAMA - MANTEM TABELAS RESIDENTES EM MEMORIA  *
      *            ENTRE AS CHAMADAS (SEM CLAUSULA INITIAL)            *
      * CHAMADA  : CALL 'SFP0310' USING AREA-TRIBUTOS                  *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0310.
       AUTHOR. EQUIPE-SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-TABELA ASSIGN TO SFPTAB
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-TAB.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-TABELA
           RECORD CONTAINS 80 CHARACTERS.
       COPY SFPWTAB.
      *
       WORKING-STORAGE SECTION.
       77  WS-PROGRAMA                 PIC X(008) VALUE 'SFP0310 '.
       77  WS-FS-TAB                   PIC X(002) VALUE '00'.
       77  WS-FIM-TAB                  PIC X(001) VALUE 'N'.
       77  WS-TABELAS-CARREGADAS       PIC X(001) VALUE 'N'.
       77  WS-LIDOS                    PIC 9(005) VALUE ZEROS.
      *
      *--- TABELA PROGRESSIVA DO INSS ---------------------------------
       01  WS-TAB-INSS.
           05  WS-QTD-INSS             PIC 9(002) VALUE ZEROS.
           05  WS-TETO-INSS-VLR        PIC 9(009)V99 VALUE ZEROS.
           05  WS-INSS-FAIXA OCCURS 10 TIMES.
               10  WS-INS-LIMITE       PIC 9(009)V99.
               10  WS-INS-ALIQUOTA     PIC 9(003)V99.
               10  WS-INS-DESCRICAO    PIC X(027).
      *
      *--- TABELA PROGRESSIVA DO IRRF ---------------------------------
       01  WS-TAB-IRRF.
           05  WS-QTD-IRRF             PIC 9(002) VALUE ZEROS.
           05  WS-IRRF-FAIXA OCCURS 10 TIMES.
               10  WS-IRF-LIMITE       PIC 9(009)V99.
               10  WS-IRF-ALIQUOTA     PIC 9(003)V99.
               10  WS-IRF-PARC-DEDUZ   PIC 9(009)V99.
               10  WS-IRF-DESCRICAO    PIC X(027).
      *
      *--- TABELA DO SALARIO FAMILIA ----------------------------------
       01  WS-TAB-SALFAM.
           05  WS-QTD-SALFAM           PIC 9(002) VALUE ZEROS.
           05  WS-SFA-FAIXA OCCURS 05 TIMES.
               10  WS-SFA-LIMITE       PIC 9(009)V99.
               10  WS-SFA-COTA         PIC 9(009)V99.
      *
      *--- PARAMETROS GERAIS ------------------------------------------
       01  WS-PARAMETROS.
           05  WS-PAR-DED-DEPENDENTE   PIC 9(009)V99 VALUE ZEROS.
           05  WS-PAR-DESC-SIMPLIF     PIC 9(009)V99 VALUE ZEROS.
           05  WS-PAR-PERC-FGTS        PIC 9(003)V99 VALUE ZEROS.
           05  WS-PAR-SAL-MINIMO       PIC 9(009)V99 VALUE ZEROS.
      *
      *--- AREA DE CALCULO --------------------------------------------
       01  WS-CALCULO.
           05  WS-IDX                  PIC S9(004) VALUE ZEROS.
           05  WS-BASE                 PIC 9(009)V99 VALUE ZEROS.
           05  WS-LIM-ANTERIOR         PIC 9(009)V99 VALUE ZEROS.
           05  WS-PARCELA              PIC 9(009)V99 VALUE ZEROS.
           05  WS-ACUMULADO            PIC 9(009)V99 VALUE ZEROS.
           05  WS-SAI-LOOP             PIC X(001) VALUE 'N'.
      *
       01  WS-IRRF-COMPARA.
           05  WS-BASE-LEGAL           PIC S9(009)V99 VALUE ZEROS.
           05  WS-BASE-SIMPLIF         PIC S9(009)V99 VALUE ZEROS.
           05  WS-IMPOSTO-LEGAL        PIC S9(009)V99 VALUE ZEROS.
           05  WS-IMPOSTO-SIMPLIF      PIC S9(009)V99 VALUE ZEROS.
           05  WS-ALIQ-LEGAL           PIC 9(003)V99 VALUE ZEROS.
           05  WS-ALIQ-SIMPLIF         PIC 9(003)V99 VALUE ZEROS.
           05  WS-FAIXA-LEGAL          PIC 9(002) VALUE ZEROS.
           05  WS-FAIXA-SIMPLIF        PIC 9(002) VALUE ZEROS.
           05  WS-DEDUCOES-LEGAIS      PIC 9(009)V99 VALUE ZEROS.
           05  WS-IMPOSTO-TMP          PIC S9(009)V99 VALUE ZEROS.
           05  WS-ALIQ-TMP             PIC 9(003)V99 VALUE ZEROS.
           05  WS-FAIXA-TMP            PIC 9(002) VALUE ZEROS.
           05  WS-BASE-TMP             PIC S9(009)V99 VALUE ZEROS.
      *
       LINKAGE SECTION.
       COPY SFPWTRB.
      *
       PROCEDURE DIVISION USING AREA-TRIBUTOS.
      *================================================================*
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           MOVE ZEROS                  TO TRB-COD-RETORNO
                                          TRB-VLR-CALCULADO
                                          TRB-ALIQUOTA-NOMINAL
                                          TRB-ALIQUOTA-EFETIVA
                                          TRB-FAIXA-APLICADA
                                          TRB-BASE-APURADA
                                          TRB-VLR-DEDUCOES
           MOVE SPACES                 TO TRB-MSG-RETORNO
           MOVE SPACE                  TO TRB-METODO-IRRF
      *
           IF WS-TABELAS-CARREGADAS = 'N'
               PERFORM 1000-CARREGAR-TABELAS
           END-IF
      *
           IF TRB-COD-RETORNO NOT = ZEROS
               GOBACK
           END-IF
      *
           EVALUATE TRUE
               WHEN TRB-CARREGA-TABELAS
                    MOVE 'TABELAS CARREGADAS COM SUCESSO'
                                       TO TRB-MSG-RETORNO
               WHEN TRB-CALCULA-INSS
                    PERFORM 2000-CALCULAR-INSS
               WHEN TRB-CALCULA-13O-INSS
                    PERFORM 2000-CALCULAR-INSS
               WHEN TRB-CALCULA-IRRF
                    PERFORM 3000-CALCULAR-IRRF
               WHEN TRB-CALCULA-FGTS
                    PERFORM 4000-CALCULAR-FGTS
               WHEN TRB-CALCULA-SALFAM
                    PERFORM 5000-CALCULAR-SALFAMILIA
               WHEN OTHER
                    MOVE 20            TO TRB-COD-RETORNO
                    STRING 'FUNCAO NAO RECONHECIDA: ' TRB-FUNCAO
                        DELIMITED BY SIZE INTO TRB-MSG-RETORNO
           END-EVALUATE
      *
           GOBACK.
      *
      *================================================================*
      * 1000 - CARGA DAS TABELAS LEGAIS A PARTIR DO ARQUIVO SFPTAB     *
      *================================================================*
       1000-CARREGAR-TABELAS SECTION.
       1000-INICIO.
           OPEN INPUT ARQ-TABELA
           IF WS-FS-TAB NOT = '00'
               MOVE 10                 TO TRB-COD-RETORNO
               STRING 'ERRO ABERTURA SFPTAB - FILE STATUS: '
                      WS-FS-TAB
                   DELIMITED BY SIZE INTO TRB-MSG-RETORNO
               GO TO 1000-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-FIM-TAB
           PERFORM UNTIL WS-FIM-TAB = 'S'
               READ ARQ-TABELA
                   AT END
                       MOVE 'S'        TO WS-FIM-TAB
                   NOT AT END
                       ADD 1           TO WS-LIDOS
                       PERFORM 1100-DISTRIBUIR-REGISTRO
               END-READ
           END-PERFORM
      *
           CLOSE ARQ-TABELA
      *
           IF WS-QTD-INSS = ZEROS OR WS-QTD-IRRF = ZEROS
               MOVE 10                 TO TRB-COD-RETORNO
               MOVE 'TABELAS INSS/IRRF NAO ENCONTRADAS EM SFPTAB'
                                       TO TRB-MSG-RETORNO
           ELSE
               MOVE 'S'                TO WS-TABELAS-CARREGADAS
           END-IF.
       1000-FIM.
           EXIT.
      *
       1100-DISTRIBUIR-REGISTRO SECTION.
       1100-INICIO.
           EVALUATE TRUE
               WHEN TAB-INSS
                    ADD 1                   TO WS-QTD-INSS
                    MOVE TAB-LIMITE   TO WS-INS-LIMITE(WS-QTD-INSS)
                    MOVE TAB-ALIQUOTA TO WS-INS-ALIQUOTA(WS-QTD-INSS)
                    MOVE TAB-DESCRICAO
                                    TO WS-INS-DESCRICAO(WS-QTD-INSS)
                    IF TAB-DEDUCAO > ZEROS
                        MOVE TAB-DEDUCAO TO WS-TETO-INSS-VLR
                    END-IF
      *
               WHEN TAB-IRRF
                    ADD 1                   TO WS-QTD-IRRF
                    MOVE TAB-LIMITE   TO WS-IRF-LIMITE(WS-QTD-IRRF)
                    MOVE TAB-ALIQUOTA TO WS-IRF-ALIQUOTA(WS-QTD-IRRF)
                    MOVE TAB-DEDUCAO  TO WS-IRF-PARC-DEDUZ(WS-QTD-IRRF)
                    MOVE TAB-DESCRICAO
                                    TO WS-IRF-DESCRICAO(WS-QTD-IRRF)
      *
               WHEN TAB-SAL-FAMILIA
                    ADD 1                   TO WS-QTD-SALFAM
                    MOVE TAB-LIMITE   TO WS-SFA-LIMITE(WS-QTD-SALFAM)
                    MOVE TAB-DEDUCAO  TO WS-SFA-COTA(WS-QTD-SALFAM)
      *
               WHEN TAB-PARAMETRO
                    PERFORM 1200-TRATAR-PARAMETRO
           END-EVALUATE.
       1100-FIM.
           EXIT.
      *
       1200-TRATAR-PARAMETRO SECTION.
       1200-INICIO.
           EVALUATE TAB-CHAVE
               WHEN 'DEDUCAO-DEP-IR'
                    MOVE TAB-DEDUCAO   TO WS-PAR-DED-DEPENDENTE
               WHEN 'DESC-SIMPLIFIC'
                    MOVE TAB-DEDUCAO   TO WS-PAR-DESC-SIMPLIF
               WHEN 'PERC-FGTS'
                    MOVE TAB-ALIQUOTA  TO WS-PAR-PERC-FGTS
               WHEN 'SALARIO-MINIMO'
                    MOVE TAB-LIMITE    TO WS-PAR-SAL-MINIMO
           END-EVALUATE.
       1200-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - CALCULO DO INSS PELA TABELA PROGRESSIVA                 *
      *        A CONTRIBUICAO E APURADA POR FAIXA, APLICANDO-SE A      *
      *        ALIQUOTA DE CADA FAIXA APENAS SOBRE A PARCELA DA        *
      *        REMUNERACAO NELA COMPREENDIDA (ALIQUOTA MARGINAL)       *
      *================================================================*
       2000-CALCULAR-INSS SECTION.
       2000-INICIO.
           MOVE TRB-BASE-CALCULO       TO WS-BASE
           MOVE ZEROS                  TO WS-ACUMULADO
                                          WS-LIM-ANTERIOR
                                          WS-PARCELA
           MOVE 'N'                    TO WS-SAI-LOOP
      *
           IF WS-BASE = ZEROS
               MOVE ZEROS              TO TRB-VLR-CALCULADO
               GO TO 2000-FIM
           END-IF
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-QTD-INSS
                      OR WS-SAI-LOOP = 'S'
      *
               IF WS-BASE > WS-INS-LIMITE(WS-IDX)
                   COMPUTE WS-PARCELA =
                           WS-INS-LIMITE(WS-IDX) - WS-LIM-ANTERIOR
               ELSE
                   COMPUTE WS-PARCELA = WS-BASE - WS-LIM-ANTERIOR
                   MOVE 'S'            TO WS-SAI-LOOP
               END-IF
      *
               IF WS-PARCELA > ZEROS
                   COMPUTE WS-ACUMULADO ROUNDED = WS-ACUMULADO
                         + (WS-PARCELA * WS-INS-ALIQUOTA(WS-IDX) / 100)
                   MOVE WS-IDX         TO TRB-FAIXA-APLICADA
                   MOVE WS-INS-ALIQUOTA(WS-IDX)
                                       TO TRB-ALIQUOTA-NOMINAL
               END-IF
      *
               MOVE WS-INS-LIMITE(WS-IDX) TO WS-LIM-ANTERIOR
           END-PERFORM
      *
      *    APLICACAO DO TETO DE CONTRIBUICAO PREVIDENCIARIA
           IF WS-TETO-INSS-VLR > ZEROS
               IF WS-ACUMULADO > WS-TETO-INSS-VLR
                   MOVE WS-TETO-INSS-VLR TO WS-ACUMULADO
                   MOVE 'CONTRIBUICAO LIMITADA AO TETO DO INSS'
                                       TO TRB-MSG-RETORNO
               END-IF
           END-IF
      *
           MOVE WS-ACUMULADO           TO TRB-VLR-CALCULADO
           MOVE WS-BASE                TO TRB-BASE-APURADA
           COMPUTE TRB-ALIQUOTA-EFETIVA ROUNDED =
                   (WS-ACUMULADO / WS-BASE) * 100.
       2000-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - CALCULO DO IRRF                                         *
      *        APURA O IMPOSTO PELOS DOIS REGIMES E ADOTA O QUE        *
      *        RESULTAR EM MENOR RETENCAO PARA O CONTRIBUINTE          *
      *        REGIME LEGAL       : BASE - INSS - PENSAO - DEPENDENTES *
      *        REGIME SIMPLIFICADO: BASE - DESCONTO SIMPLIFICADO       *
      *================================================================*
       3000-CALCULAR-IRRF SECTION.
       3000-INICIO.
           IF TRB-BASE-CALCULO = ZEROS
               MOVE ZEROS              TO TRB-VLR-CALCULADO
               SET TRB-IRRF-ISENTO     TO TRUE
               GO TO 3000-FIM
           END-IF
      *
      *--- REGIME DE DEDUCOES LEGAIS ----------------------------------
           COMPUTE WS-DEDUCOES-LEGAIS =
                   TRB-VLR-INSS-DEDUZIR
                 + TRB-VLR-PENSAO-DEDUZIR
                 + (TRB-QTD-DEPENDENTES * WS-PAR-DED-DEPENDENTE)
      *
           COMPUTE WS-BASE-LEGAL =
                   TRB-BASE-CALCULO - WS-DEDUCOES-LEGAIS
           IF WS-BASE-LEGAL < ZEROS
               MOVE ZEROS              TO WS-BASE-LEGAL
           END-IF
      *
           MOVE WS-BASE-LEGAL          TO WS-BASE-TMP
           PERFORM 3100-APLICAR-TABELA-IRRF
           MOVE WS-IMPOSTO-TMP         TO WS-IMPOSTO-LEGAL
           MOVE WS-ALIQ-TMP            TO WS-ALIQ-LEGAL
           MOVE WS-FAIXA-TMP           TO WS-FAIXA-LEGAL
      *
      *--- REGIME DE DESCONTO SIMPLIFICADO ----------------------------
           COMPUTE WS-BASE-SIMPLIF =
                   TRB-BASE-CALCULO - WS-PAR-DESC-SIMPLIF
                 - TRB-VLR-PENSAO-DEDUZIR
           IF WS-BASE-SIMPLIF < ZEROS
               MOVE ZEROS              TO WS-BASE-SIMPLIF
           END-IF
      *
           MOVE WS-BASE-SIMPLIF        TO WS-BASE-TMP
           PERFORM 3100-APLICAR-TABELA-IRRF
           MOVE WS-IMPOSTO-TMP         TO WS-IMPOSTO-SIMPLIF
           MOVE WS-ALIQ-TMP            TO WS-ALIQ-SIMPLIF
           MOVE WS-FAIXA-TMP           TO WS-FAIXA-SIMPLIF
      *
      *--- ESCOLHA DO REGIME MAIS FAVORAVEL ---------------------------
           IF WS-IMPOSTO-SIMPLIF < WS-IMPOSTO-LEGAL
               MOVE WS-IMPOSTO-SIMPLIF TO TRB-VLR-CALCULADO
               MOVE WS-ALIQ-SIMPLIF    TO TRB-ALIQUOTA-NOMINAL
               MOVE WS-FAIXA-SIMPLIF   TO TRB-FAIXA-APLICADA
               MOVE WS-BASE-SIMPLIF    TO TRB-BASE-APURADA
               MOVE WS-PAR-DESC-SIMPLIF TO TRB-VLR-DEDUCOES
               SET TRB-IRRF-SIMPLIFICADO TO TRUE
               MOVE 'IRRF APURADO PELO DESCONTO SIMPLIFICADO'
                                       TO TRB-MSG-RETORNO
           ELSE
               MOVE WS-IMPOSTO-LEGAL   TO TRB-VLR-CALCULADO
               MOVE WS-ALIQ-LEGAL      TO TRB-ALIQUOTA-NOMINAL
               MOVE WS-FAIXA-LEGAL     TO TRB-FAIXA-APLICADA
               MOVE WS-BASE-LEGAL      TO TRB-BASE-APURADA
               MOVE WS-DEDUCOES-LEGAIS TO TRB-VLR-DEDUCOES
               SET TRB-IRRF-LEGAL      TO TRUE
               MOVE 'IRRF APURADO PELAS DEDUCOES LEGAIS'
                                       TO TRB-MSG-RETORNO
           END-IF
      *
           IF TRB-VLR-CALCULADO = ZEROS
               SET TRB-IRRF-ISENTO     TO TRUE
               MOVE 'CONTRIBUINTE ISENTO NA COMPETENCIA'
                                       TO TRB-MSG-RETORNO
           END-IF
      *
           IF TRB-BASE-CALCULO > ZEROS
               COMPUTE TRB-ALIQUOTA-EFETIVA ROUNDED =
                       (TRB-VLR-CALCULADO / TRB-BASE-CALCULO) * 100
           END-IF.
       3000-FIM.
           EXIT.
      *
       3100-APLICAR-TABELA-IRRF SECTION.
       3100-INICIO.
           MOVE ZEROS                  TO WS-IMPOSTO-TMP
                                          WS-ALIQ-TMP
                                          WS-FAIXA-TMP
           MOVE 'N'                    TO WS-SAI-LOOP
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-QTD-IRRF
                      OR WS-SAI-LOOP = 'S'
      *
               IF WS-BASE-TMP <= WS-IRF-LIMITE(WS-IDX)
                   COMPUTE WS-IMPOSTO-TMP ROUNDED =
                          (WS-BASE-TMP * WS-IRF-ALIQUOTA(WS-IDX) / 100)
                         - WS-IRF-PARC-DEDUZ(WS-IDX)
                   MOVE WS-IRF-ALIQUOTA(WS-IDX) TO WS-ALIQ-TMP
                   MOVE WS-IDX         TO WS-FAIXA-TMP
                   MOVE 'S'            TO WS-SAI-LOOP
               END-IF
           END-PERFORM
      *
      *    BASE ACIMA DO ULTIMO LIMITE: APLICA A MAIOR ALIQUOTA
           IF WS-SAI-LOOP = 'N'
               COMPUTE WS-IMPOSTO-TMP ROUNDED =
                      (WS-BASE-TMP * WS-IRF-ALIQUOTA(WS-QTD-IRRF) / 100)
                     - WS-IRF-PARC-DEDUZ(WS-QTD-IRRF)
               MOVE WS-IRF-ALIQUOTA(WS-QTD-IRRF) TO WS-ALIQ-TMP
               MOVE WS-QTD-IRRF        TO WS-FAIXA-TMP
           END-IF
      *
           IF WS-IMPOSTO-TMP < ZEROS
               MOVE ZEROS              TO WS-IMPOSTO-TMP
           END-IF.
       3100-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 - CALCULO DO FGTS (DEPOSITO MENSAL DO EMPREGADOR)         *
      *================================================================*
       4000-CALCULAR-FGTS SECTION.
       4000-INICIO.
           COMPUTE TRB-VLR-CALCULADO ROUNDED =
                   TRB-BASE-CALCULO * WS-PAR-PERC-FGTS / 100
           MOVE WS-PAR-PERC-FGTS       TO TRB-ALIQUOTA-NOMINAL
                                          TRB-ALIQUOTA-EFETIVA
           MOVE TRB-BASE-CALCULO       TO TRB-BASE-APURADA
           MOVE 'DEPOSITO FGTS APURADO SOBRE BASE INCIDENTE'
                                       TO TRB-MSG-RETORNO.
       4000-FIM.
           EXIT.
      *
      *================================================================*
      * 5000 - SALARIO FAMILIA                                         *
      *        COTA POR FILHO ATE 14 ANOS, DEVIDA APENAS QUANDO A      *
      *        REMUNERACAO MENSAL NAO SUPERAR O LIMITE LEGAL           *
      *================================================================*
       5000-CALCULAR-SALFAMILIA SECTION.
       5000-INICIO.
           MOVE ZEROS                  TO TRB-VLR-CALCULADO
      *
           IF TRB-QTD-FILHOS-SALFAM = ZEROS
               MOVE 'SEM FILHOS ELEGIVEIS AO SALARIO FAMILIA'
                                       TO TRB-MSG-RETORNO
               GO TO 5000-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-SAI-LOOP
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-QTD-SALFAM
                      OR WS-SAI-LOOP = 'S'
               IF TRB-VLR-REMUN-SALFAM <= WS-SFA-LIMITE(WS-IDX)
                   COMPUTE TRB-VLR-CALCULADO ROUNDED =
                           TRB-QTD-FILHOS-SALFAM * WS-SFA-COTA(WS-IDX)
                   MOVE WS-IDX         TO TRB-FAIXA-APLICADA
                   MOVE 'S'            TO WS-SAI-LOOP
               END-IF
           END-PERFORM
      *
           IF WS-SAI-LOOP = 'N'
               MOVE 'REMUNERACAO ACIMA DO LIMITE - SEM DIREITO'
                                       TO TRB-MSG-RETORNO
           END-IF.
       5000-FIM.
           EXIT.
