      *================================================================*
      * PROGRAMA : SFPUTIL                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : ROTINAS UTILITARIAS CORPORATIVAS                    *
      *            - VALIDACAO DE CPF (MODULO 11)                      *
      *            - VALIDACAO DE DATA COM ANO BISSEXTO                *
      *            - DIFERENCA DE DIAS (DIA JULIANO - ALGORITMO        *
      *              FLIEGEL / VAN FLANDERN)                           *
      *            - CALCULO DE AVOS PARA 13O E FERIAS (REGRA DOS      *
      *              15 DIAS - ART.146 CLT)                            *
      *            - VALOR POR EXTENSO                                 *
      *            - DIGITO VERIFICADOR MODULO 11                      *
      * TIPO     : SUBPROGRAMA CHAMADO VIA CALL ESTATICO/DINAMICO      *
      * AUTOR    : EQUIPE DE DESENVOLVIMENTO SFP                       *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFPUTIL.
       AUTHOR. EQUIPE-SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       77  WS-PROGRAMA                 PIC X(008) VALUE 'SFPUTIL '.
      *
       01  WS-CPF-TRAB.
           05  WS-CPF-DIG              PIC 9(001) OCCURS 11 TIMES.
       01  WS-CALC-CPF.
           05  WS-SOMA                 PIC S9(007) VALUE ZEROS.
           05  WS-RESTO                PIC S9(007) VALUE ZEROS.
           05  WS-DV1                  PIC 9(001)  VALUE ZEROS.
           05  WS-DV2                  PIC 9(001)  VALUE ZEROS.
           05  WS-PESO                 PIC S9(003) VALUE ZEROS.
           05  WS-IDX                  PIC S9(003) VALUE ZEROS.
           05  WS-IGUAIS               PIC 9(003)  VALUE ZEROS.
      *
       01  WS-DATA-DEC.
           05  WS-DT-ANO               PIC 9(004).
           05  WS-DT-MES               PIC 9(002).
           05  WS-DT-DIA               PIC 9(002).
      *
       01  WS-JULIANO.
           05  WS-JD-A                 PIC S9(009) VALUE ZEROS.
           05  WS-JD-Y                 PIC S9(009) VALUE ZEROS.
           05  WS-JD-M                 PIC S9(009) VALUE ZEROS.
           05  WS-JD-T1                PIC S9(009) VALUE ZEROS.
           05  WS-JD-T2                PIC S9(009) VALUE ZEROS.
           05  WS-JD-T3                PIC S9(009) VALUE ZEROS.
           05  WS-JD-T4                PIC S9(009) VALUE ZEROS.
           05  WS-JD-T5                PIC S9(009) VALUE ZEROS.
           05  WS-JD-INI               PIC S9(009) VALUE ZEROS.
           05  WS-JD-FIM               PIC S9(009) VALUE ZEROS.
      *
       01  WS-TAB-DIAS-MES.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 28.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 30.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 30.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 30.
           05  FILLER                  PIC 9(002) VALUE 31.
           05  FILLER                  PIC 9(002) VALUE 30.
           05  FILLER                  PIC 9(002) VALUE 31.
       01  FILLER REDEFINES WS-TAB-DIAS-MES.
           05  WS-DIAS-MES             PIC 9(002) OCCURS 12 TIMES.
       77  WS-LIMITE-DIA               PIC 9(002) VALUE ZEROS.
       77  WS-RESTO-BIS                PIC 9(004) VALUE ZEROS.
      *
      *--- AREA PARA VALOR POR EXTENSO --------------------------------
       01  WS-TAB-UNIDADES.
           05  FILLER PIC X(012) VALUE 'UM          '.
           05  FILLER PIC X(012) VALUE 'DOIS        '.
           05  FILLER PIC X(012) VALUE 'TRES        '.
           05  FILLER PIC X(012) VALUE 'QUATRO      '.
           05  FILLER PIC X(012) VALUE 'CINCO       '.
           05  FILLER PIC X(012) VALUE 'SEIS        '.
           05  FILLER PIC X(012) VALUE 'SETE        '.
           05  FILLER PIC X(012) VALUE 'OITO        '.
           05  FILLER PIC X(012) VALUE 'NOVE        '.
           05  FILLER PIC X(012) VALUE 'DEZ         '.
           05  FILLER PIC X(012) VALUE 'ONZE        '.
           05  FILLER PIC X(012) VALUE 'DOZE        '.
           05  FILLER PIC X(012) VALUE 'TREZE       '.
           05  FILLER PIC X(012) VALUE 'QUATORZE    '.
           05  FILLER PIC X(012) VALUE 'QUINZE      '.
           05  FILLER PIC X(012) VALUE 'DEZESSEIS   '.
           05  FILLER PIC X(012) VALUE 'DEZESSETE   '.
           05  FILLER PIC X(012) VALUE 'DEZOITO     '.
           05  FILLER PIC X(012) VALUE 'DEZENOVE    '.
       01  FILLER REDEFINES WS-TAB-UNIDADES.
           05  WS-UNIDADE              PIC X(012) OCCURS 19 TIMES.
      *
       01  WS-TAB-DEZENAS.
           05  FILLER PIC X(012) VALUE 'VINTE       '.
           05  FILLER PIC X(012) VALUE 'TRINTA      '.
           05  FILLER PIC X(012) VALUE 'QUARENTA    '.
           05  FILLER PIC X(012) VALUE 'CINQUENTA   '.
           05  FILLER PIC X(012) VALUE 'SESSENTA    '.
           05  FILLER PIC X(012) VALUE 'SETENTA     '.
           05  FILLER PIC X(012) VALUE 'OITENTA     '.
           05  FILLER PIC X(012) VALUE 'NOVENTA     '.
       01  FILLER REDEFINES WS-TAB-DEZENAS.
           05  WS-DEZENA               PIC X(012) OCCURS 8 TIMES.
      *
       01  WS-TAB-CENTENAS.
           05  FILLER PIC X(013) VALUE 'CENTO        '.
           05  FILLER PIC X(013) VALUE 'DUZENTOS     '.
           05  FILLER PIC X(013) VALUE 'TREZENTOS    '.
           05  FILLER PIC X(013) VALUE 'QUATROCENTOS '.
           05  FILLER PIC X(013) VALUE 'QUINHENTOS   '.
           05  FILLER PIC X(013) VALUE 'SEISCENTOS   '.
           05  FILLER PIC X(013) VALUE 'SETECENTOS   '.
           05  FILLER PIC X(013) VALUE 'OITOCENTOS   '.
           05  FILLER PIC X(013) VALUE 'NOVECENTOS   '.
       01  FILLER REDEFINES WS-TAB-CENTENAS.
           05  WS-CENTENA              PIC X(013) OCCURS 9 TIMES.
      *
       01  WS-EXT-AREA.
           05  WS-EXT-TEXTO            PIC X(180) VALUE SPACES.
           05  WS-EXT-POS              PIC S9(004) VALUE 1.
           05  WS-EXT-VALOR            PIC 9(009)V99 VALUE ZEROS.
           05  WS-EXT-INTEIRO          PIC 9(009) VALUE ZEROS.
           05  WS-EXT-CENTAVOS         PIC 9(002) VALUE ZEROS.
           05  WS-EXT-GRUPO            PIC 9(003) VALUE ZEROS.
           05  WS-EXT-C                PIC 9(001) VALUE ZEROS.
           05  WS-EXT-D                PIC 9(001) VALUE ZEROS.
           05  WS-EXT-U                PIC 9(001) VALUE ZEROS.
           05  WS-EXT-DU               PIC 9(002) VALUE ZEROS.
           05  WS-EXT-MILHAR           PIC 9(003) VALUE ZEROS.
           05  WS-EXT-MILHAO           PIC 9(003) VALUE ZEROS.
           05  WS-EXT-TMP              PIC X(030) VALUE SPACES.
           05  WS-EXT-TAM              PIC S9(004) VALUE ZEROS.
      *
      *--- AREA PARA DIGITO VERIFICADOR -------------------------------
       01  WS-DV-AREA.
           05  WS-DV-NUM               PIC 9(012) VALUE ZEROS.
           05  WS-DV-NUM-R REDEFINES WS-DV-NUM.
               10  WS-DV-DIG           PIC 9(001) OCCURS 12 TIMES.
           05  WS-DV-SOMA              PIC S9(009) VALUE ZEROS.
           05  WS-DV-PESO              PIC S9(003) VALUE ZEROS.
           05  WS-DV-RESTO             PIC S9(003) VALUE ZEROS.
      *
       LINKAGE SECTION.
       COPY SFPWUTL.
      *
       PROCEDURE DIVISION USING AREA-UTILITARIOS.
      *================================================================*
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           MOVE ZEROS                  TO UTL-COD-RETORNO
           MOVE SPACES                 TO UTL-MENSAGEM
      *
           EVALUATE TRUE
               WHEN UTL-VALIDA-CPF
                    PERFORM 1000-VALIDAR-CPF
               WHEN UTL-VALIDA-DATA
                    PERFORM 2000-VALIDAR-DATA
               WHEN UTL-DIFERENCA-DIAS
                    PERFORM 3000-DIFERENCA-DIAS
               WHEN UTL-CALCULA-AVOS
                    PERFORM 4000-CALCULAR-AVOS
               WHEN UTL-FORMATA-DATA
                    PERFORM 5000-FORMATAR-DATA
               WHEN UTL-VALOR-EXTENSO
                    PERFORM 6000-VALOR-EXTENSO
               WHEN UTL-DIGITO-MOD11
                    PERFORM 7000-DIGITO-MOD11
               WHEN OTHER
                    MOVE 20             TO UTL-COD-RETORNO
                    STRING 'FUNCAO INVALIDA INFORMADA: '
                           UTL-FUNCAO
                           DELIMITED BY SIZE INTO UTL-MENSAGEM
           END-EVALUATE
      *
           GOBACK.
      *
      *================================================================*
      * 1000 - VALIDACAO DE CPF PELO ALGORITMO DO MODULO 11            *
      *================================================================*
       1000-VALIDAR-CPF SECTION.
       1000-INICIO.
           MOVE UTL-CPF                TO WS-CPF-TRAB
      *
      *    REJEITA SEQUENCIAS COM TODOS OS DIGITOS IGUAIS
           MOVE ZEROS                  TO WS-IGUAIS
           PERFORM VARYING WS-IDX FROM 2 BY 1 UNTIL WS-IDX > 11
               IF WS-CPF-DIG(WS-IDX) = WS-CPF-DIG(1)
                   ADD 1               TO WS-IGUAIS
               END-IF
           END-PERFORM
           IF WS-IGUAIS = 10
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'CPF INVALIDO - DIGITOS REPETIDOS'
                                       TO UTL-MENSAGEM
               GO TO 1000-FIM
           END-IF
      *
      *    PRIMEIRO DIGITO VERIFICADOR
           MOVE ZEROS                  TO WS-SOMA
           MOVE 10                     TO WS-PESO
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 9
               COMPUTE WS-SOMA = WS-SOMA
                     + (WS-CPF-DIG(WS-IDX) * WS-PESO)
               SUBTRACT 1              FROM WS-PESO
           END-PERFORM
           COMPUTE WS-RESTO = FUNCTION MOD (WS-SOMA * 10, 11)
           IF WS-RESTO > 9
               MOVE ZERO               TO WS-DV1
           ELSE
               MOVE WS-RESTO           TO WS-DV1
           END-IF
      *
      *    SEGUNDO DIGITO VERIFICADOR
           MOVE ZEROS                  TO WS-SOMA
           MOVE 11                     TO WS-PESO
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 10
               COMPUTE WS-SOMA = WS-SOMA
                     + (WS-CPF-DIG(WS-IDX) * WS-PESO)
               SUBTRACT 1              FROM WS-PESO
           END-PERFORM
           COMPUTE WS-RESTO = FUNCTION MOD (WS-SOMA * 10, 11)
           IF WS-RESTO > 9
               MOVE ZERO               TO WS-DV2
           ELSE
               MOVE WS-RESTO           TO WS-DV2
           END-IF
      *
           IF WS-DV1 = WS-CPF-DIG(10) AND WS-DV2 = WS-CPF-DIG(11)
               MOVE ZEROS              TO UTL-COD-RETORNO
               MOVE 'CPF VALIDO'       TO UTL-MENSAGEM
           ELSE
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'CPF INVALIDO - DIGITO VERIFICADOR INCORRETO'
                                       TO UTL-MENSAGEM
           END-IF.
       1000-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - VALIDACAO DE DATA NO FORMATO AAAAMMDD                   *
      *================================================================*
       2000-VALIDAR-DATA SECTION.
       2000-INICIO.
           MOVE UTL-DATA-INI           TO WS-DATA-DEC
      *
           IF WS-DT-ANO < 1900 OR WS-DT-ANO > 2199
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'ANO FORA DO INTERVALO PERMITIDO (1900-2199)'
                                       TO UTL-MENSAGEM
               GO TO 2000-FIM
           END-IF
           IF WS-DT-MES < 1 OR WS-DT-MES > 12
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'MES INVALIDO'     TO UTL-MENSAGEM
               GO TO 2000-FIM
           END-IF
      *
           MOVE WS-DIAS-MES(WS-DT-MES) TO WS-LIMITE-DIA
           IF WS-DT-MES = 2
               PERFORM 2100-VERIFICA-BISSEXTO
           END-IF
      *
           IF WS-DT-DIA < 1 OR WS-DT-DIA > WS-LIMITE-DIA
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'DIA INVALIDO PARA O MES INFORMADO'
                                       TO UTL-MENSAGEM
           ELSE
               MOVE ZEROS              TO UTL-COD-RETORNO
               MOVE 'DATA VALIDA'      TO UTL-MENSAGEM
           END-IF.
       2000-FIM.
           EXIT.
      *
       2100-VERIFICA-BISSEXTO SECTION.
       2100-INICIO.
           COMPUTE WS-RESTO-BIS = FUNCTION MOD (WS-DT-ANO, 4)
           IF WS-RESTO-BIS = ZERO
               COMPUTE WS-RESTO-BIS = FUNCTION MOD (WS-DT-ANO, 100)
               IF WS-RESTO-BIS NOT = ZERO
                   MOVE 29             TO WS-LIMITE-DIA
               ELSE
                   COMPUTE WS-RESTO-BIS = FUNCTION MOD
                                          (WS-DT-ANO, 400)
                   IF WS-RESTO-BIS = ZERO
                       MOVE 29         TO WS-LIMITE-DIA
                   END-IF
               END-IF
           END-IF.
       2100-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - DIFERENCA EM DIAS ENTRE DUAS DATAS                      *
      *        ALGORITMO DO DIA JULIANO (FLIEGEL / VAN FLANDERN)       *
      *================================================================*
       3000-DIFERENCA-DIAS SECTION.
       3000-INICIO.
           MOVE UTL-DATA-INI           TO WS-DATA-DEC
           PERFORM 3100-CALCULA-JULIANO
           MOVE WS-JD-T1               TO WS-JD-INI
      *
           MOVE UTL-DATA-FIM           TO WS-DATA-DEC
           PERFORM 3100-CALCULA-JULIANO
           MOVE WS-JD-T1               TO WS-JD-FIM
      *
           COMPUTE UTL-QTD-DIAS = WS-JD-FIM - WS-JD-INI
           MOVE ZEROS                  TO UTL-COD-RETORNO.
       3000-FIM.
           EXIT.
      *
       3100-CALCULA-JULIANO SECTION.
       3100-INICIO.
           COMPUTE WS-JD-A = (14 - WS-DT-MES) / 12
           COMPUTE WS-JD-Y = WS-DT-ANO + 4800 - WS-JD-A
           COMPUTE WS-JD-M = WS-DT-MES + (12 * WS-JD-A) - 3
           COMPUTE WS-JD-T2 = ((153 * WS-JD-M) + 2) / 5
           COMPUTE WS-JD-T3 = WS-JD-Y / 4
           COMPUTE WS-JD-T4 = WS-JD-Y / 100
           COMPUTE WS-JD-T5 = WS-JD-Y / 400
           COMPUTE WS-JD-T1 = WS-DT-DIA + WS-JD-T2
                            + (365 * WS-JD-Y)
                            + WS-JD-T3 - WS-JD-T4 + WS-JD-T5
                            - 32045.
       3100-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 - CALCULO DE AVOS (13O SALARIO / FERIAS)                  *
      *        REGRA: FRACAO IGUAL OU SUPERIOR A 15 DIAS TRABALHADOS   *
      *        DENTRO DO MES CONTA COMO AVO INTEIRO (ART.146 CLT)      *
      *================================================================*
       4000-CALCULAR-AVOS SECTION.
       4000-INICIO.
           PERFORM 3000-DIFERENCA-DIAS
           IF UTL-QTD-DIAS < ZERO
               MOVE 10                 TO UTL-COD-RETORNO
               MOVE 'DATA FINAL ANTERIOR A DATA INICIAL'
                                       TO UTL-MENSAGEM
               MOVE ZEROS              TO UTL-QTD-AVOS
               GO TO 4000-FIM
           END-IF
      *
           COMPUTE WS-JD-T2 = UTL-QTD-DIAS / 30
           COMPUTE WS-JD-T3 = UTL-QTD-DIAS - (WS-JD-T2 * 30)
           IF WS-JD-T3 >= 15
               ADD 1                   TO WS-JD-T2
           END-IF
           IF WS-JD-T2 > 12
               MOVE 12                 TO WS-JD-T2
           END-IF
           IF WS-JD-T2 < ZERO
               MOVE ZEROS              TO WS-JD-T2
           END-IF
           MOVE WS-JD-T2               TO UTL-QTD-AVOS
           MOVE ZEROS                  TO UTL-COD-RETORNO.
       4000-FIM.
           EXIT.
      *
      *================================================================*
      * 5000 - FORMATACAO DE DATA AAAAMMDD PARA DD/MM/AAAA             *
      *================================================================*
       5000-FORMATAR-DATA SECTION.
       5000-INICIO.
           MOVE UTL-DATA-INI           TO WS-DATA-DEC
           MOVE SPACES                 TO UTL-DATA-FORMATADA
           STRING WS-DT-DIA '/' WS-DT-MES '/' WS-DT-ANO
               DELIMITED BY SIZE INTO UTL-DATA-FORMATADA
           MOVE ZEROS                  TO UTL-COD-RETORNO.
       5000-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 - VALOR POR EXTENSO (ATE 999.999.999,99)                  *
      *================================================================*
       6000-VALOR-EXTENSO SECTION.
       6000-INICIO.
           MOVE SPACES                 TO WS-EXT-TEXTO
           MOVE 1                      TO WS-EXT-POS
           MOVE UTL-VALOR              TO WS-EXT-VALOR
           COMPUTE WS-EXT-INTEIRO = FUNCTION INTEGER-PART
                                    (WS-EXT-VALOR)
           COMPUTE WS-EXT-CENTAVOS =
                   (WS-EXT-VALOR - WS-EXT-INTEIRO) * 100
      *
           IF WS-EXT-INTEIRO = ZEROS AND WS-EXT-CENTAVOS = ZEROS
               MOVE 'ZERO'             TO UTL-EXTENSO
               GO TO 6000-FIM
           END-IF
      *
           COMPUTE WS-EXT-MILHAO = WS-EXT-INTEIRO / 1000000
           COMPUTE WS-EXT-MILHAR = (WS-EXT-INTEIRO
                                 - (WS-EXT-MILHAO * 1000000)) / 1000
           COMPUTE WS-EXT-GRUPO  = WS-EXT-INTEIRO
                                 - (WS-EXT-MILHAO * 1000000)
                                 - (WS-EXT-MILHAR * 1000)
      *
           IF WS-EXT-MILHAO > ZEROS
               MOVE WS-EXT-MILHAO      TO WS-EXT-GRUPO
               PERFORM 6100-EXTENSO-GRUPO
               IF WS-EXT-MILHAO = 1
                   PERFORM 6200-CONCATENA-MILHAO-SING
               ELSE
                   PERFORM 6210-CONCATENA-MILHAO-PLUR
               END-IF
               COMPUTE WS-EXT-GRUPO = WS-EXT-INTEIRO
                                    - (WS-EXT-MILHAO * 1000000)
                                    - (WS-EXT-MILHAR * 1000)
           END-IF
      *
           IF WS-EXT-MILHAR > ZEROS
               MOVE WS-EXT-MILHAR      TO WS-EXT-GRUPO
               PERFORM 6100-EXTENSO-GRUPO
               PERFORM 6220-CONCATENA-MIL
               COMPUTE WS-EXT-GRUPO = WS-EXT-INTEIRO
                                    - (WS-EXT-MILHAO * 1000000)
                                    - (WS-EXT-MILHAR * 1000)
           END-IF
      *
           IF WS-EXT-GRUPO > ZEROS
               PERFORM 6100-EXTENSO-GRUPO
           END-IF
      *
           IF WS-EXT-INTEIRO = 1
               PERFORM 6230-CONCATENA-REAL
           ELSE
               IF WS-EXT-INTEIRO > 1
                   PERFORM 6240-CONCATENA-REAIS
               END-IF
           END-IF
      *
           IF WS-EXT-CENTAVOS > ZEROS
               IF WS-EXT-INTEIRO > ZEROS
                   PERFORM 6250-CONCATENA-E
               END-IF
               MOVE WS-EXT-CENTAVOS    TO WS-EXT-GRUPO
               PERFORM 6100-EXTENSO-GRUPO
               IF WS-EXT-CENTAVOS = 1
                   PERFORM 6260-CONCATENA-CENTAVO
               ELSE
                   PERFORM 6270-CONCATENA-CENTAVOS
               END-IF
           END-IF
      *
           MOVE WS-EXT-TEXTO           TO UTL-EXTENSO
           MOVE ZEROS                  TO UTL-COD-RETORNO.
       6000-FIM.
           EXIT.
      *
       6100-EXTENSO-GRUPO SECTION.
       6100-INICIO.
           COMPUTE WS-EXT-C = WS-EXT-GRUPO / 100
           COMPUTE WS-EXT-DU = WS-EXT-GRUPO - (WS-EXT-C * 100)
           COMPUTE WS-EXT-D = WS-EXT-DU / 10
           COMPUTE WS-EXT-U = WS-EXT-DU - (WS-EXT-D * 10)
      *
           IF WS-EXT-C = 1 AND WS-EXT-DU = ZEROS
               MOVE 'CEM'              TO WS-EXT-TMP
               PERFORM 6300-ANEXAR-TEXTO
           ELSE
               IF WS-EXT-C > ZEROS
                   MOVE WS-CENTENA(WS-EXT-C) TO WS-EXT-TMP
                   PERFORM 6300-ANEXAR-TEXTO
                   IF WS-EXT-DU > ZEROS
                       PERFORM 6250-CONCATENA-E
                   END-IF
               END-IF
           END-IF
      *
           IF WS-EXT-DU > ZEROS AND WS-EXT-DU < 20
               MOVE WS-UNIDADE(WS-EXT-DU) TO WS-EXT-TMP
               PERFORM 6300-ANEXAR-TEXTO
           ELSE
               IF WS-EXT-DU >= 20
                   COMPUTE WS-EXT-D = WS-EXT-D - 1
                   MOVE WS-DEZENA(WS-EXT-D) TO WS-EXT-TMP
                   PERFORM 6300-ANEXAR-TEXTO
                   IF WS-EXT-U > ZEROS
                       PERFORM 6250-CONCATENA-E
                       MOVE WS-UNIDADE(WS-EXT-U) TO WS-EXT-TMP
                       PERFORM 6300-ANEXAR-TEXTO
                   END-IF
               END-IF
           END-IF.
       6100-FIM.
           EXIT.
      *
       6200-CONCATENA-MILHAO-SING SECTION.
       6200-INICIO.
           MOVE 'MILHAO'               TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6200-FIM.
           EXIT.
       6210-CONCATENA-MILHAO-PLUR SECTION.
       6210-INICIO.
           MOVE 'MILHOES'              TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6210-FIM.
           EXIT.
       6220-CONCATENA-MIL SECTION.
       6220-INICIO.
           MOVE 'MIL'                  TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6220-FIM.
           EXIT.
       6230-CONCATENA-REAL SECTION.
       6230-INICIO.
           MOVE 'REAL'                 TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6230-FIM.
           EXIT.
       6240-CONCATENA-REAIS SECTION.
       6240-INICIO.
           MOVE 'REAIS'                TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6240-FIM.
           EXIT.
       6250-CONCATENA-E SECTION.
       6250-INICIO.
           MOVE 'E'                    TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6250-FIM.
           EXIT.
       6260-CONCATENA-CENTAVO SECTION.
       6260-INICIO.
           MOVE 'CENTAVO'              TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6260-FIM.
           EXIT.
       6270-CONCATENA-CENTAVOS SECTION.
       6270-INICIO.
           MOVE 'CENTAVOS'             TO WS-EXT-TMP
           PERFORM 6300-ANEXAR-TEXTO.
       6270-FIM.
           EXIT.
      *
       6300-ANEXAR-TEXTO SECTION.
       6300-INICIO.
           MOVE ZEROS                  TO WS-EXT-TAM
           INSPECT FUNCTION REVERSE (WS-EXT-TMP)
               TALLYING WS-EXT-TAM FOR LEADING SPACE
           COMPUTE WS-EXT-TAM = 30 - WS-EXT-TAM
           IF WS-EXT-TAM > ZEROS
               IF WS-EXT-POS > 1
                   MOVE ' '            TO WS-EXT-TEXTO(WS-EXT-POS:1)
                   ADD 1               TO WS-EXT-POS
               END-IF
               MOVE WS-EXT-TMP(1:WS-EXT-TAM)
                                  TO WS-EXT-TEXTO(WS-EXT-POS:WS-EXT-TAM)
               ADD WS-EXT-TAM          TO WS-EXT-POS
           END-IF.
       6300-FIM.
           EXIT.
      *
      *================================================================*
      * 7000 - DIGITO VERIFICADOR MODULO 11 (CONTA BANCARIA)           *
      *================================================================*
       7000-DIGITO-MOD11 SECTION.
       7000-INICIO.
           MOVE UTL-NUMERO-DV          TO WS-DV-NUM
           MOVE ZEROS                  TO WS-DV-SOMA
           MOVE 2                      TO WS-DV-PESO
           PERFORM VARYING WS-IDX FROM 12 BY -1 UNTIL WS-IDX < 1
               COMPUTE WS-DV-SOMA = WS-DV-SOMA
                     + (WS-DV-DIG(WS-IDX) * WS-DV-PESO)
               ADD 1                   TO WS-DV-PESO
               IF WS-DV-PESO > 9
                   MOVE 2              TO WS-DV-PESO
               END-IF
           END-PERFORM
           COMPUTE WS-DV-RESTO = FUNCTION MOD (WS-DV-SOMA, 11)
           COMPUTE WS-DV-RESTO = 11 - WS-DV-RESTO
           IF WS-DV-RESTO > 9
               MOVE ZERO               TO UTL-DIGITO
           ELSE
               MOVE WS-DV-RESTO        TO UTL-DIGITO
           END-IF
           MOVE ZEROS                  TO UTL-COD-RETORNO.
       7000-FIM.
           EXIT.
