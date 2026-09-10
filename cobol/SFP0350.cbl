      *================================================================*
      * PROGRAMA : SFP0350                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : CALCULO DAS VERBAS RESCISORIAS (TRCT)               *
      *                                                                *
      *   SELECIONA OS EMPREGADOS DESLIGADOS NA COMPETENCIA E APURA:   *
      *     - SALDO DE SALARIO DO MES DA DEMISSAO                      *
      *     - AVISO PREVIO INDENIZADO (30 DIAS + 3 POR ANO, MAX 90)    *
      *     - 13o SALARIO PROPORCIONAL (AVOS SOBRE O ANO CIVIL)        *
      *     - FERIAS PROPORCIONAIS ACRESCIDAS DE 1/3                   *
      *     - MULTA RESCISORIA DE 40% SOBRE O SALDO DO FGTS            *
      *     - INSS SOBRE SALDO DE SALARIO E, EM SEPARADO, SOBRE 13o    *
      *     - IRRF SOBRE AS VERBAS TRIBUTAVEIS                         *
      *                                                                *
      *   VERBAS INDENIZATORIAS (AVISO PREVIO INDENIZADO E FERIAS      *
      *   INDENIZADAS) NAO SOFREM INCIDENCIA DE INSS E IRRF.           *
      *                                                                *
      * ENTRADA  : SFPEMP SFPTAB SYSIN                                 *
      * SAIDA    : SFPRSC (DETALHE) SFPTRC (TERMO IMPRESSO)            *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0350.
       AUTHOR. EQUIPE-SFP.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-EMPREGADO ASSIGN TO SFPEMP
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-EMP.
           SELECT ARQ-SYSIN     ASSIGN TO SYSIN
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-SYS.
           SELECT ARQ-RESCISAO  ASSIGN TO SFPRSC
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-RSC.
           SELECT ARQ-TERMO     ASSIGN TO SFPTRC
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-TRC.
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-EMPREGADO RECORD CONTAINS 500 CHARACTERS.
       COPY SFPWEMP.
       FD  ARQ-SYSIN     RECORD CONTAINS 80 CHARACTERS.
       01  REG-SYSIN                   PIC X(080).
       FD  ARQ-RESCISAO  RECORD CONTAINS 120 CHARACTERS.
       COPY SFPWFOL.
       FD  ARQ-TERMO     RECORD CONTAINS 132 CHARACTERS.
       01  REG-TERMO                   PIC X(132).
      *
       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-FS-EMP               PIC X(002) VALUE '00'.
           05  WS-FS-SYS               PIC X(002) VALUE '00'.
           05  WS-FS-RSC               PIC X(002) VALUE '00'.
           05  WS-FS-TRC               PIC X(002) VALUE '00'.
           05  WS-FIM-EMP              PIC X(001) VALUE 'N'.
       01  WS-PARM.
           05  WS-COMPETENCIA          PIC 9(006) VALUE ZEROS.
           05  WS-COMPET-R REDEFINES WS-COMPETENCIA.
               10  WS-PRM-ANO          PIC 9(004).
               10  WS-PRM-MES          PIC 9(002).
           05  WS-MOTIVO-RESC          PIC X(001) VALUE '1'.
               88  WS-SEM-JUSTA-CAUSA      VALUE '1'.
               88  WS-PEDIDO-DEMISSAO      VALUE '2'.
               88  WS-JUSTA-CAUSA          VALUE '3'.
               88  WS-TERMINO-CONTRATO     VALUE '4'.
           05  WS-DT-INI-COMPET        PIC 9(008) VALUE ZEROS.
           05  WS-DT-FIM-COMPET        PIC 9(008) VALUE ZEROS.
      *
       01  WS-CALCULO.
           05  WS-SEQ                  PIC 9(003) VALUE ZEROS.
           05  WS-VALOR-DIA            PIC 9(009)V9999 VALUE ZEROS.
           05  WS-SALARIO-MENSAL       PIC 9(009)V99 VALUE ZEROS.
           05  WS-DIAS-SALDO           PIC 9(003) VALUE ZEROS.
           05  WS-DIAS-AVISO           PIC 9(003) VALUE ZEROS.
           05  WS-ANOS-CASA            PIC 9(003) VALUE ZEROS.
           05  WS-AVOS-13              PIC 9(002) VALUE ZEROS.
           05  WS-AVOS-FERIAS          PIC 9(002) VALUE ZEROS.
           05  WS-SALDO-SALARIO        PIC 9(009)V99 VALUE ZEROS.
           05  WS-AVISO-PREVIO         PIC 9(009)V99 VALUE ZEROS.
           05  WS-DECIMO-PROP          PIC 9(009)V99 VALUE ZEROS.
           05  WS-FERIAS-PROP          PIC 9(009)V99 VALUE ZEROS.
           05  WS-TERCO-FERIAS         PIC 9(009)V99 VALUE ZEROS.
           05  WS-MULTA-FGTS           PIC 9(009)V99 VALUE ZEROS.
           05  WS-FGTS-RESCISAO        PIC 9(009)V99 VALUE ZEROS.
           05  WS-INSS-SALARIO         PIC 9(009)V99 VALUE ZEROS.
           05  WS-INSS-13O             PIC 9(009)V99 VALUE ZEROS.
           05  WS-IRRF-RESC            PIC 9(009)V99 VALUE ZEROS.
           05  WS-BASE-IRRF-RESC       PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-PROVENTOS        PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-DESCONTOS        PIC 9(009)V99 VALUE ZEROS.
           05  WS-LIQUIDO              PIC S9(009)V99 VALUE ZEROS.
           05  WS-DT-PROJETADA         PIC 9(008) VALUE ZEROS.
           05  WS-AUX                  PIC 9(009)V99 VALUE ZEROS.
       01  WS-TOTAIS.
           05  WS-LIDOS                PIC 9(007) VALUE ZEROS.
           05  WS-RESCINDIDOS          PIC 9(007) VALUE ZEROS.
           05  WS-TOT-GERAL            PIC 9(013)V99 VALUE ZEROS.
      *
       01  L-LINHA.
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  LL-DESCRICAO            PIC X(045).
           05  LL-REFER                PIC ZZ.ZZ9,99.
           05  FILLER                  PIC X(004) VALUE SPACES.
           05  LL-PROVENTO             PIC ZZZ.ZZZ.ZZ9,99
                                       BLANK WHEN ZERO.
           05  FILLER                  PIC X(004) VALUE SPACES.
           05  LL-DESCONTO             PIC ZZZ.ZZZ.ZZ9,99
                                       BLANK WHEN ZERO.
           05  FILLER                  PIC X(032) VALUE SPACES.
       01  L-CAB.
           05  FILLER                  PIC X(009) VALUE 'SFP0350  '.
           05  FILLER                  PIC X(048) VALUE
               'TERMO DE RESCISAO DO CONTRATO DE TRABALHO - TRCT'.
           05  FILLER                  PIC X(014) VALUE
               'COMPETENCIA: '.
           05  LC-COMPETENCIA          PIC 9(006).
           05  FILLER                  PIC X(055) VALUE SPACES.
       01  L-EMPREGADO.
           05  FILLER                  PIC X(011) VALUE 'MATRICULA: '.
           05  LE-MATRICULA            PIC 9(008).
           05  FILLER                  PIC X(003) VALUE '  '.
           05  LE-NOME                 PIC X(040).
           05  FILLER                  PIC X(011) VALUE ' ADMISSAO: '.
           05  LE-ADMISSAO             PIC 9(008).
           05  FILLER                  PIC X(011) VALUE ' DEMISSAO: '.
           05  LE-DEMISSAO             PIC 9(008).
           05  FILLER                  PIC X(032) VALUE SPACES.
       01  L-TOTAL.
           05  FILLER                  PIC X(047) VALUE SPACES.
           05  FILLER                  PIC X(011) VALUE 'TOTAIS -> '.
           05  LT-PROV                 PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(004) VALUE SPACES.
           05  LT-DESC                 PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(028) VALUE SPACES.
       01  L-LIQUIDO.
           05  FILLER                  PIC X(068) VALUE SPACES.
           05  FILLER                  PIC X(024) VALUE
               'LIQUIDO DA RESCISAO ->  '.
           05  LQ-LIQUIDO              PIC ZZZ.ZZZ.ZZ9,99-.
           05  FILLER                  PIC X(025) VALUE SPACES.
      *
       COPY SFPWCON.
       COPY SFPWTRB.
       COPY SFPWUTL.
      *
       PROCEDURE DIVISION.
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR UNTIL WS-FIM-EMP = 'S'
           PERFORM 9000-FINALIZAR
           STOP RUN.
      *
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           OPEN INPUT  ARQ-EMPREGADO ARQ-SYSIN
           OPEN OUTPUT ARQ-RESCISAO ARQ-TERMO
           IF WS-FS-EMP NOT = '00'
               DISPLAY 'SFP0350 - ERRO ABERTURA SFPEMP: ' WS-FS-EMP
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
           READ ARQ-SYSIN
               AT END CONTINUE
               NOT AT END
                   MOVE REG-SYSIN(01:06) TO WS-COMPETENCIA
                   IF REG-SYSIN(35:1) NOT = SPACE
                       MOVE REG-SYSIN(35:1) TO WS-MOTIVO-RESC
                   END-IF
           END-READ
           COMPUTE WS-DT-INI-COMPET =
                   (WS-PRM-ANO * 10000) + (WS-PRM-MES * 100) + 1
           COMPUTE WS-DT-FIM-COMPET =
                   (WS-PRM-ANO * 10000) + (WS-PRM-MES * 100) + 31
      *
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CARREGA-TABELAS     TO TRUE
           MOVE WS-COMPETENCIA         TO TRB-COMPETENCIA
           CALL 'SFP0310' USING AREA-TRIBUTOS
           IF TRB-COD-RETORNO NOT = ZEROS
               DISPLAY 'SFP0350 - ' TRB-MSG-RETORNO
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           MOVE WS-COMPETENCIA         TO LC-COMPETENCIA
           MOVE L-CAB                  TO REG-TERMO
           WRITE REG-TERMO
           MOVE ALL '='                TO REG-TERMO
           WRITE REG-TERMO
           PERFORM 8100-LER-EMPREGADO.
       1000-FIM.
           EXIT.
      *
       2000-PROCESSAR SECTION.
       2000-INICIO.
           IF EMP-SITUACAO = 'D'
              AND EMP-DT-DEMISSAO >= WS-DT-INI-COMPET
              AND EMP-DT-DEMISSAO <= WS-DT-FIM-COMPET
               PERFORM 2100-CALCULAR-RESCISAO
               ADD 1                   TO WS-RESCINDIDOS
           END-IF
           PERFORM 8100-LER-EMPREGADO.
       2000-FIM.
           EXIT.
      *
       2100-CALCULAR-RESCISAO SECTION.
       2100-INICIO.
           PERFORM 2110-INICIAR
           PERFORM 2120-SALDO-SALARIO
           PERFORM 2130-AVISO-PREVIO
           PERFORM 2140-DECIMO-PROPORCIONAL
           PERFORM 2150-FERIAS-PROPORCIONAIS
           PERFORM 2160-MULTA-FGTS
           PERFORM 2200-ENCARGOS
           PERFORM 2300-IMPRIMIR-TERMO.
       2100-FIM.
           EXIT.
      *
       2110-INICIAR SECTION.
       2110-INICIO.
           MOVE ZEROS TO WS-SEQ WS-SALDO-SALARIO WS-AVISO-PREVIO
                         WS-DECIMO-PROP WS-FERIAS-PROP
                         WS-TERCO-FERIAS WS-MULTA-FGTS
                         WS-INSS-SALARIO WS-INSS-13O WS-IRRF-RESC
                         WS-TOT-PROVENTOS WS-TOT-DESCONTOS
                         WS-LIQUIDO WS-BASE-IRRF-RESC
                         WS-FGTS-RESCISAO
           IF EMP-CARGA-HOR-MES = ZEROS
               MOVE 220                TO EMP-CARGA-HOR-MES
           END-IF
           IF EMP-MENSALISTA
               COMPUTE WS-VALOR-DIA ROUNDED = EMP-SALARIO-BASE / 30
           ELSE
               COMPUTE WS-VALOR-DIA ROUNDED =
                       EMP-SALARIO-BASE * EMP-CARGA-HOR-MES / 30
           END-IF
      *    REMUNERACAO MENSAL EQUIVALENTE - BASE DAS VERBAS QUE SAO
      *    APURADAS EM AVOS (13O E FERIAS). PARA O HORISTA E O
      *    DIARISTA O SALARIO CADASTRAL E UNITARIO E NAO PODE SER
      *    USADO DIRETAMENTE COMO SALARIO DO MES.
           COMPUTE WS-SALARIO-MENSAL ROUNDED = WS-VALOR-DIA * 30
      *    TEMPO DE CASA EM ANOS COMPLETOS
           INITIALIZE AREA-UTILITARIOS
           SET UTL-DIFERENCA-DIAS      TO TRUE
           MOVE EMP-DT-ADMISSAO        TO UTL-DATA-INI
           MOVE EMP-DT-DEMISSAO        TO UTL-DATA-FIM
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           COMPUTE WS-ANOS-CASA = UTL-QTD-DIAS / 365.
       2110-FIM.
           EXIT.
      *
       2120-SALDO-SALARIO SECTION.
       2120-INICIO.
           COMPUTE WS-DIAS-SALDO =
                   FUNCTION MOD (EMP-DT-DEMISSAO, 100)
           COMPUTE WS-SALDO-SALARIO ROUNDED =
                   WS-VALOR-DIA * WS-DIAS-SALDO
           MOVE 0001                   TO FOL-COD-EVENTO
           MOVE 'SALDO DE SALARIO'     TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE WS-DIAS-SALDO          TO FOL-REFERENCIA
           MOVE WS-SALDO-SALARIO       TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA.
       2120-FIM.
           EXIT.
      *
       2130-AVISO-PREVIO SECTION.
       2130-INICIO.
      *    O AVISO PREVIO INDENIZADO E DEVIDO NA DISPENSA SEM JUSTA
      *    CAUSA. SAO 30 DIAS ACRESCIDOS DE 3 DIAS POR ANO COMPLETO
      *    DE SERVICO, OBSERVADO O LIMITE MAXIMO DE 90 DIAS.
           IF NOT WS-SEM-JUSTA-CAUSA
               MOVE ZEROS              TO WS-DIAS-AVISO
               GO TO 2130-FIM
           END-IF
           COMPUTE WS-DIAS-AVISO = 30 + (WS-ANOS-CASA * 3)
           IF WS-DIAS-AVISO > 90
               MOVE 90                 TO WS-DIAS-AVISO
           END-IF
           COMPUTE WS-AVISO-PREVIO ROUNDED =
                   WS-VALOR-DIA * WS-DIAS-AVISO
           MOVE 0070                   TO FOL-COD-EVENTO
           MOVE 'AVISO PREVIO INDENIZADO'  TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE WS-DIAS-AVISO          TO FOL-REFERENCIA
           MOVE WS-AVISO-PREVIO        TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA.
       2130-FIM.
           EXIT.
      *
       2140-DECIMO-PROPORCIONAL SECTION.
       2140-INICIO.
      *    OS AVOS DO 13o SAO CONTADOS DE JANEIRO ATE O MES DA
      *    DEMISSAO, PROJETADO PELO AVISO PREVIO INDENIZADO
           IF WS-JUSTA-CAUSA
               GO TO 2140-FIM
           END-IF
           COMPUTE WS-AVOS-13 = WS-PRM-MES
           IF WS-DIAS-AVISO > ZEROS
               COMPUTE WS-AVOS-13 = WS-AVOS-13 + (WS-DIAS-AVISO / 30)
           END-IF
           IF WS-AVOS-13 > 12
               MOVE 12                 TO WS-AVOS-13
           END-IF
           IF EMP-DT-ADMISSAO > WS-DT-INI-COMPET
               MOVE 1                  TO WS-AVOS-13
           END-IF
           COMPUTE WS-DECIMO-PROP ROUNDED =
                   WS-SALARIO-MENSAL * WS-AVOS-13 / 12
           MOVE 0050                   TO FOL-COD-EVENTO
           MOVE '13o SALARIO PROPORCIONAL'  TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE WS-AVOS-13             TO FOL-REFERENCIA
           MOVE WS-DECIMO-PROP         TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA.
       2140-FIM.
           EXIT.
      *
       2150-FERIAS-PROPORCIONAIS SECTION.
       2150-INICIO.
           IF WS-JUSTA-CAUSA
               GO TO 2150-FIM
           END-IF
      *    AVOS DE FERIAS APURADOS SOBRE O PERIODO AQUISITIVO EM
      *    CURSO, CONTADO A PARTIR DO ULTIMO ANIVERSARIO DE ADMISSAO
           INITIALIZE AREA-UTILITARIOS
           SET UTL-CALCULA-AVOS        TO TRUE
           MOVE EMP-DT-ADMISSAO        TO UTL-DATA-INI
           MOVE EMP-DT-DEMISSAO        TO UTL-DATA-FIM
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           MOVE UTL-QTD-AVOS           TO WS-AVOS-FERIAS
           IF WS-AVOS-FERIAS = ZEROS
               MOVE 1                  TO WS-AVOS-FERIAS
           END-IF
      *
           COMPUTE WS-FERIAS-PROP ROUNDED =
                   WS-SALARIO-MENSAL * WS-AVOS-FERIAS / 12
           MOVE 0062                   TO FOL-COD-EVENTO
           MOVE 'FERIAS PROPORCIONAIS INDENIZ'  TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE WS-AVOS-FERIAS         TO FOL-REFERENCIA
           MOVE WS-FERIAS-PROP         TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA
      *
           COMPUTE WS-TERCO-FERIAS ROUNDED = WS-FERIAS-PROP / 3
           MOVE 0061                   TO FOL-COD-EVENTO
           MOVE '1/3 CONSTITUCIONAL S/ FERIAS'  TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE 33                     TO FOL-REFERENCIA
           MOVE WS-TERCO-FERIAS        TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA.
       2150-FIM.
           EXIT.
      *
       2160-MULTA-FGTS SECTION.
       2160-INICIO.
           IF NOT WS-SEM-JUSTA-CAUSA
               GO TO 2160-FIM
           END-IF
      *    FGTS INCIDENTE SOBRE AS VERBAS DA RESCISAO
           COMPUTE WS-AUX = WS-SALDO-SALARIO + WS-DECIMO-PROP
                          + WS-AVISO-PREVIO
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CALCULA-FGTS        TO TRUE
           MOVE WS-AUX                 TO TRB-BASE-CALCULO
           CALL 'SFP0310' USING AREA-TRIBUTOS
           MOVE TRB-VLR-CALCULADO      TO WS-FGTS-RESCISAO
      *
           COMPUTE WS-MULTA-FGTS ROUNDED =
                   (EMP-SALDO-FGTS + WS-FGTS-RESCISAO) * 40 / 100
           MOVE 0080                   TO FOL-COD-EVENTO
           MOVE 'MULTA RESCISORIA 40% FGTS'  TO FOL-DESCRICAO
           MOVE 'P'                    TO FOL-NATUREZA
           MOVE 40                     TO FOL-REFERENCIA
           MOVE WS-MULTA-FGTS          TO FOL-VALOR
           PERFORM 8500-GRAVAR-VERBA.
       2160-FIM.
           EXIT.
      *
       2200-ENCARGOS SECTION.
       2200-INICIO.
      *--- INSS SOBRE O SALDO DE SALARIO ------------------------------
           IF WS-SALDO-SALARIO > ZEROS
               INITIALIZE AREA-TRIBUTOS
               SET TRB-CALCULA-INSS    TO TRUE
               MOVE WS-SALDO-SALARIO   TO TRB-BASE-CALCULO
               CALL 'SFP0310' USING AREA-TRIBUTOS
               MOVE TRB-VLR-CALCULADO  TO WS-INSS-SALARIO
               MOVE 0510               TO FOL-COD-EVENTO
               MOVE 'INSS S/ SALDO DE SALARIO'  TO FOL-DESCRICAO
               MOVE 'D'                TO FOL-NATUREZA
               MOVE TRB-ALIQUOTA-EFETIVA TO FOL-REFERENCIA
               MOVE WS-INSS-SALARIO    TO FOL-VALOR
               PERFORM 8500-GRAVAR-VERBA
           END-IF
      *
      *--- INSS SOBRE O 13o (TRIBUTACAO EXCLUSIVA E SEPARADA) ---------
           IF WS-DECIMO-PROP > ZEROS
               INITIALIZE AREA-TRIBUTOS
               SET TRB-CALCULA-13O-INSS TO TRUE
               MOVE WS-DECIMO-PROP     TO TRB-BASE-CALCULO
               CALL 'SFP0310' USING AREA-TRIBUTOS
               MOVE TRB-VLR-CALCULADO  TO WS-INSS-13O
               MOVE 0512               TO FOL-COD-EVENTO
               MOVE 'INSS S/ 13o SALARIO'  TO FOL-DESCRICAO
               MOVE 'D'                TO FOL-NATUREZA
               MOVE TRB-ALIQUOTA-EFETIVA TO FOL-REFERENCIA
               MOVE WS-INSS-13O        TO FOL-VALOR
               PERFORM 8500-GRAVAR-VERBA
           END-IF
      *
      *--- IRRF: AS VERBAS INDENIZATORIAS SAO EXCLUIDAS DA BASE -------
           COMPUTE WS-BASE-IRRF-RESC = WS-SALDO-SALARIO
           IF WS-BASE-IRRF-RESC > ZEROS
               INITIALIZE AREA-TRIBUTOS
               SET TRB-CALCULA-IRRF    TO TRUE
               MOVE WS-BASE-IRRF-RESC  TO TRB-BASE-CALCULO
               MOVE EMP-QTD-DEP-IRRF   TO TRB-QTD-DEPENDENTES
               MOVE WS-INSS-SALARIO    TO TRB-VLR-INSS-DEDUZIR
               CALL 'SFP0310' USING AREA-TRIBUTOS
               MOVE TRB-VLR-CALCULADO  TO WS-IRRF-RESC
               IF WS-IRRF-RESC > ZEROS
                   MOVE 0511           TO FOL-COD-EVENTO
                   MOVE 'IRRF S/ VERBAS RESCISORIAS'
                                       TO FOL-DESCRICAO
                   MOVE 'D'            TO FOL-NATUREZA
                   MOVE TRB-ALIQUOTA-NOMINAL TO FOL-REFERENCIA
                   MOVE WS-IRRF-RESC   TO FOL-VALOR
                   PERFORM 8500-GRAVAR-VERBA
               END-IF
           END-IF
      *
           COMPUTE WS-LIQUIDO = WS-TOT-PROVENTOS - WS-TOT-DESCONTOS
           ADD WS-LIQUIDO              TO WS-TOT-GERAL.
       2200-FIM.
           EXIT.
      *
       2300-IMPRIMIR-TERMO SECTION.
       2300-INICIO.
           MOVE SPACES                 TO REG-TERMO
           WRITE REG-TERMO
           MOVE EMP-MATRICULA          TO LE-MATRICULA
           MOVE EMP-NOME               TO LE-NOME
           MOVE EMP-DT-ADMISSAO        TO LE-ADMISSAO
           MOVE EMP-DT-DEMISSAO        TO LE-DEMISSAO
           MOVE L-EMPREGADO            TO REG-TERMO
           WRITE REG-TERMO
           MOVE ALL '-'                TO REG-TERMO
           WRITE REG-TERMO
      *
           MOVE 'SALDO DE SALARIO'     TO LL-DESCRICAO
           MOVE WS-DIAS-SALDO          TO LL-REFER
           MOVE WS-SALDO-SALARIO       TO LL-PROVENTO
           MOVE ZEROS                  TO LL-DESCONTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE 'AVISO PREVIO INDENIZADO'  TO LL-DESCRICAO
           MOVE WS-DIAS-AVISO          TO LL-REFER
           MOVE WS-AVISO-PREVIO        TO LL-PROVENTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE '13o SALARIO PROPORCIONAL'  TO LL-DESCRICAO
           MOVE WS-AVOS-13             TO LL-REFER
           MOVE WS-DECIMO-PROP         TO LL-PROVENTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE 'FERIAS PROPORCIONAIS INDENIZADAS' TO LL-DESCRICAO
           MOVE WS-AVOS-FERIAS         TO LL-REFER
           MOVE WS-FERIAS-PROP         TO LL-PROVENTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE '1/3 CONSTITUCIONAL SOBRE FERIAS'  TO LL-DESCRICAO
           MOVE 33                     TO LL-REFER
           MOVE WS-TERCO-FERIAS        TO LL-PROVENTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE 'MULTA RESCISORIA DE 40% SOBRE O FGTS'  TO LL-DESCRICAO
           MOVE 40                     TO LL-REFER
           MOVE WS-MULTA-FGTS          TO LL-PROVENTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
      *
           MOVE ZEROS                  TO LL-PROVENTO
           MOVE 'INSS SOBRE SALDO DE SALARIO'  TO LL-DESCRICAO
           MOVE ZEROS                  TO LL-REFER
           MOVE WS-INSS-SALARIO        TO LL-DESCONTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE 'INSS SOBRE 13o SALARIO'  TO LL-DESCRICAO
           MOVE WS-INSS-13O            TO LL-DESCONTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
           MOVE 'IRRF SOBRE VERBAS RESCISORIAS'  TO LL-DESCRICAO
           MOVE WS-IRRF-RESC           TO LL-DESCONTO
           MOVE L-LINHA                TO REG-TERMO
           WRITE REG-TERMO
      *
           MOVE ALL '-'                TO REG-TERMO
           WRITE REG-TERMO
           MOVE WS-TOT-PROVENTOS       TO LT-PROV
           MOVE WS-TOT-DESCONTOS       TO LT-DESC
           MOVE L-TOTAL                TO REG-TERMO
           WRITE REG-TERMO
           MOVE WS-LIQUIDO             TO LQ-LIQUIDO
           MOVE L-LIQUIDO              TO REG-TERMO
           WRITE REG-TERMO
           MOVE ALL '='                TO REG-TERMO
           WRITE REG-TERMO.
       2300-FIM.
           EXIT.
      *
       8500-GRAVAR-VERBA SECTION.
       8500-INICIO.
           IF FOL-VALOR = ZEROS
               GO TO 8500-FIM
           END-IF
           ADD 1                       TO WS-SEQ
           MOVE WS-COMPETENCIA         TO FOL-COMPETENCIA
           MOVE '6'                    TO FOL-TIPO-FOLHA
           MOVE EMP-MATRICULA          TO FOL-MATRICULA
           MOVE WS-SEQ                 TO FOL-SEQUENCIA
           MOVE EMP-CENTRO-CUSTO       TO FOL-CENTRO-CUSTO
           MOVE 31119999               TO FOL-CONTA-CONTABIL
           MOVE SPACES                 TO FOL-FILLER
           IF FOL-NATUREZA = 'P'
               ADD FOL-VALOR           TO WS-TOT-PROVENTOS
           ELSE
               ADD FOL-VALOR           TO WS-TOT-DESCONTOS
           END-IF
           WRITE REG-FOLHA.
       8500-FIM.
           EXIT.
      *
       8100-LER-EMPREGADO SECTION.
       8100-INICIO.
           READ ARQ-EMPREGADO
               AT END MOVE 'S'         TO WS-FIM-EMP
               NOT AT END ADD 1        TO WS-LIDOS
           END-READ.
       8100-FIM.
           EXIT.
      *
       9000-FINALIZAR SECTION.
       9000-INICIO.
           CLOSE ARQ-EMPREGADO ARQ-SYSIN ARQ-RESCISAO ARQ-TERMO
           DISPLAY '=================================================='
           DISPLAY ' SFP0350 - CALCULO DE RESCISOES CONCLUIDO'
           DISPLAY '=================================================='
           DISPLAY ' EMPREGADOS LIDOS ....: ' WS-LIDOS
           DISPLAY ' RESCISOES CALCULADAS : ' WS-RESCINDIDOS
           DISPLAY ' VALOR TOTAL LIQUIDO .: ' WS-TOT-GERAL
           DISPLAY '=================================================='.
       9000-FIM.
           EXIT.
