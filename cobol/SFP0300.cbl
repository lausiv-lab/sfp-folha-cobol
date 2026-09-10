      *================================================================*
      * PROGRAMA : SFP0300                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      *----------------------------------------------------------------*
      * FUNCAO   : MOTOR DE CALCULO DA FOLHA DE PAGAMENTO              *
      *                                                                *
      *  PROCESSA O CASAMENTO (MATCHING) DE QUATRO ARQUIVOS            *
      *  CLASSIFICADOS PELA MATRICULA:                                 *
      *      SFPEMP - CADASTRO DE EMPREGADOS  (ARQUIVO MESTRE)         *
      *      SFPPON - APURACAO DO PONTO                                *
      *      SFPDEP - DEPENDENTES                                      *
      *      SFPMOV - MOVIMENTO MENSAL DE EVENTOS                      *
      *                                                                *
      *  PARA CADA EMPREGADO ELEGIVEL O MOTOR EXECUTA A SEGUINTE       *
      *  SEQUENCIA DE APURACAO:                                        *
      *      1. PROVENTOS AUTOMATICOS (SALARIO, ADICIONAIS, HORAS)     *
      *      2. EVENTOS INFORMADOS NO MOVIMENTO                        *
      *      3. DESCONTOS DE FREQUENCIA (FALTAS / ATRASOS / DSR)       *
      *      4. APURACAO DAS BASES DE INCIDENCIA                       *
      *      5. INSS  (VIA SFP0310)                                    *
      *      6. SALARIO FAMILIA (VIA SFP0310)                          *
      *      7. IRRF  (VIA SFP0310)                                    *
      *      8. DESCONTOS POS-TRIBUTOS E MARGEM CONSIGNAVEL            *
      *      9. FGTS  (INFORMATIVO)                                    *
      *     10. CRITICA DE LIQUIDO NEGATIVO / SALDO DEVEDOR            *
      *                                                                *
      * ENTRADA  : SFPEMP SFPPON SFPDEP SFPMOV SFPEVE SFPTAB SYSIN     *
      * SAIDA    : SFPFOL SFPRES SFPCRI                                *
      * RETORNO  : 00-OK  04-CRITICAS  08-ERRO GRAVE  12-ABEND         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0300.
       AUTHOR. EQUIPE-SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
      *
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-EMPREGADO ASSIGN TO SFPEMP
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-EMP.
           SELECT ARQ-PONTO     ASSIGN TO SFPPON
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-PON.
           SELECT ARQ-DEPEND    ASSIGN TO SFPDEP
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-DEP.
           SELECT ARQ-MOVIMENTO ASSIGN TO SFPMOV
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-MOV.
           SELECT ARQ-EVENTO    ASSIGN TO SFPEVE
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-EVE.
           SELECT ARQ-PARAMETRO ASSIGN TO SFPTAB
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-PAR.
           SELECT ARQ-SYSIN     ASSIGN TO SYSIN
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-SYS.
           SELECT ARQ-FOLHA     ASSIGN TO SFPFOL
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-FOL.
           SELECT ARQ-RESUMO    ASSIGN TO SFPRES
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-RES.
           SELECT ARQ-CRITICA   ASSIGN TO SFPCRI
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-CRI.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-EMPREGADO RECORD CONTAINS 500 CHARACTERS.
       COPY SFPWEMP.
      *
       FD  ARQ-PONTO     RECORD CONTAINS 80 CHARACTERS.
      *    REGISTRO DE ENTRADA COM LEITURA ANTECIPADA. O CONTEUDO E
      *    TRANSFERIDO PARA A AREA DE TRABALHO REG-PONTO ANTES DE
      *    AVANCAR PARA O PROXIMO REGISTRO DO ARQUIVO.
       01  REG-PONTO-E.
           05  PONE-MATRICULA          PIC 9(008).
           05  PONE-CONTEUDO           PIC X(072).
      *
       FD  ARQ-DEPEND    RECORD CONTAINS 80 CHARACTERS.
       COPY SFPWDEP.
      *
       FD  ARQ-MOVIMENTO RECORD CONTAINS 100 CHARACTERS.
       COPY SFPWMOV.
      *
       FD  ARQ-EVENTO    RECORD CONTAINS 80 CHARACTERS.
       COPY SFPWEVE.
      *
       FD  ARQ-PARAMETRO RECORD CONTAINS 80 CHARACTERS.
       COPY SFPWTAB.
      *
       FD  ARQ-SYSIN     RECORD CONTAINS 80 CHARACTERS.
       01  REG-SYSIN                   PIC X(080).
      *
       FD  ARQ-FOLHA     RECORD CONTAINS 120 CHARACTERS.
       COPY SFPWFOL.
      *
       FD  ARQ-RESUMO    RECORD CONTAINS 250 CHARACTERS.
       COPY SFPWRES.
      *
       FD  ARQ-CRITICA   RECORD CONTAINS 132 CHARACTERS.
       01  REG-CRITICA                 PIC X(132).
      *
       WORKING-STORAGE SECTION.
       77  WS-PROGRAMA                 PIC X(008) VALUE 'SFP0300 '.
      *
      *--- FILE STATUS ------------------------------------------------
       01  WS-FILE-STATUS.
           05  WS-FS-EMP               PIC X(002) VALUE '00'.
           05  WS-FS-PON               PIC X(002) VALUE '00'.
           05  WS-FS-DEP               PIC X(002) VALUE '00'.
           05  WS-FS-MOV               PIC X(002) VALUE '00'.
           05  WS-FS-EVE               PIC X(002) VALUE '00'.
           05  WS-FS-PAR               PIC X(002) VALUE '00'.
           05  WS-FS-SYS               PIC X(002) VALUE '00'.
           05  WS-FS-FOL               PIC X(002) VALUE '00'.
           05  WS-FS-RES               PIC X(002) VALUE '00'.
           05  WS-FS-CRI               PIC X(002) VALUE '00'.
      *
      *--- CHAVES DE CONTROLE DE FIM DE ARQUIVO -----------------------
       01  WS-FLAGS.
           05  WS-FIM-EMP              PIC X(001) VALUE 'N'.
           05  WS-FIM-PON              PIC X(001) VALUE 'N'.
           05  WS-FIM-DEP              PIC X(001) VALUE 'N'.
           05  WS-FIM-MOV              PIC X(001) VALUE 'N'.
           05  WS-FIM-EVE              PIC X(001) VALUE 'N'.
           05  WS-FIM-PAR              PIC X(001) VALUE 'N'.
           05  WS-EMP-ELEGIVEL         PIC X(001) VALUE 'N'.
           05  WS-ACHOU-EVENTO         PIC X(001) VALUE 'N'.
      *
      *--- CARTAO DE PARAMETRO (SYSIN) --------------------------------
       01  WS-PARM-EXECUCAO.
           05  WS-PRM-COMPETENCIA      PIC 9(006) VALUE ZEROS.
           05  WS-PRM-COMPET-R REDEFINES WS-PRM-COMPETENCIA.
               10  WS-PRM-ANO          PIC 9(004).
               10  WS-PRM-MES          PIC 9(002).
           05  WS-PRM-TIPO-FOLHA       PIC X(001) VALUE '1'.
           05  WS-PRM-CC-INICIAL       PIC 9(006) VALUE ZEROS.
           05  WS-PRM-CC-FINAL         PIC 9(006) VALUE 999999.
           05  WS-PRM-SIMULACAO        PIC X(001) VALUE 'N'.
           05  WS-PRM-DT-PAGAMENTO     PIC 9(008) VALUE ZEROS.
      *
      *--- TABELA RESIDENTE DE EVENTOS --------------------------------
       01  WS-QTD-EVENTOS              PIC 9(004) VALUE ZEROS.
       01  WS-TABELA-EVENTOS.
           05  TB-EVENTO OCCURS 1 TO 500 TIMES
                         DEPENDING ON WS-QTD-EVENTOS
                         ASCENDING KEY IS TB-EVE-CODIGO
                         INDEXED BY IX-EVE.
               10  TB-EVE-CODIGO       PIC 9(004).
               10  TB-EVE-DESCRICAO    PIC X(030).
               10  TB-EVE-NATUREZA     PIC X(001).
               10  TB-EVE-TIPO-CALC    PIC 9(003).
               10  TB-EVE-INC-INSS     PIC X(001).
               10  TB-EVE-INC-IRRF     PIC X(001).
               10  TB-EVE-INC-FGTS     PIC X(001).
               10  TB-EVE-INC-DSR      PIC X(001).
               10  TB-EVE-INC-13O      PIC X(001).
               10  TB-EVE-INC-FERIAS   PIC X(001).
               10  TB-EVE-UNIDADE      PIC X(002).
               10  TB-EVE-PERCENTUAL   PIC 9(003)V99.
               10  TB-EVE-CONTA        PIC 9(008).
      *
      *--- PARAMETROS GERAIS DO SISTEMA -------------------------------
       01  WS-PARAMETROS.
           05  WS-SALARIO-MINIMO       PIC 9(009)V99 VALUE ZEROS.
           05  WS-PERC-VT              PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-ADIANT          PIC 9(003)V99 VALUE ZEROS.
           05  WS-MARGEM-CONSIG        PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-HE-050          PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-HE-100          PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-NOTURNO         PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-PERICULOSID     PIC 9(003)V99 VALUE ZEROS.
           05  WS-PERC-QUINQUENIO      PIC 9(003)V99 VALUE ZEROS.
           05  WS-MAX-QUINQUENIOS      PIC 9(003)    VALUE ZEROS.
           05  WS-VLR-CONTR-SINDIC     PIC 9(003)V99 VALUE ZEROS.
           05  WS-DIAS-MES-COMERC      PIC 9(003)    VALUE 30.
      *
      *--- AREA DE CALCULO DO EMPREGADO CORRENTE ----------------------
       01  WS-CALC-EMPREGADO.
           05  WS-MATRIC-CORRENTE      PIC 9(008) VALUE ZEROS.
           05  WS-VALOR-HORA           PIC 9(009)V9999 VALUE ZEROS.
           05  WS-VALOR-DIA            PIC 9(009)V9999 VALUE ZEROS.
           05  WS-SALARIO-CALC         PIC 9(009)V99 VALUE ZEROS.
      *    SALARIO MENSAL EQUIVALENTE - BASE DOS EVENTOS PERCENTUAIS.
      *    PARA HORISTAS E DIARISTAS O SALARIO CONTRATUAL NAO E
      *    MENSAL, LOGO NAO PODE SER USADO DIRETAMENTE COMO BASE.
           05  WS-SALARIO-REFER        PIC 9(009)V99 VALUE ZEROS.
           05  WS-DIAS-PAGAR           PIC 9(003) VALUE ZEROS.
           05  WS-DIAS-DSR             PIC 9(003) VALUE ZEROS.
           05  WS-TOT-PROVENTOS        PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-DESCONTOS        PIC 9(009)V99 VALUE ZEROS.
           05  WS-LIQUIDO              PIC S9(009)V99 VALUE ZEROS.
           05  WS-BASE-INSS            PIC 9(009)V99 VALUE ZEROS.
           05  WS-BASE-IRRF            PIC 9(009)V99 VALUE ZEROS.
           05  WS-BASE-FGTS            PIC 9(009)V99 VALUE ZEROS.
           05  WS-BASE-DSR             PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-INSS             PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-IRRF             PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-FGTS             PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-SALFAM           PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-PENSAO           PIC 9(009)V99 VALUE ZEROS.
           05  WS-ALIQ-INSS            PIC 9(003)V99 VALUE ZEROS.
           05  WS-ALIQ-IRRF            PIC 9(003)V99 VALUE ZEROS.
           05  WS-QTD-DEP-IRRF         PIC 9(002) VALUE ZEROS.
           05  WS-QTD-DEP-SALFAM       PIC 9(002) VALUE ZEROS.
           05  WS-VLR-PLANO-DEP        PIC 9(009)V99 VALUE ZEROS.
           05  WS-TEMPO-CASA-DIAS      PIC S9(007) VALUE ZEROS.
           05  WS-QTD-QUINQUENIOS      PIC 9(003) VALUE ZEROS.
           05  WS-MARGEM-DISPONIVEL    PIC 9(009)V99 VALUE ZEROS.
           05  WS-TOT-HORAS-EXTRAS     PIC 9(009)V99 VALUE ZEROS.
           05  WS-VLR-NOTURNO          PIC 9(009)V99 VALUE ZEROS.
      *
      *--- TABELA DE EVENTOS CALCULADOS DO EMPREGADO ------------------
       01  WS-QTD-CALC                 PIC 9(003) VALUE ZEROS.
       01  WS-TABELA-CALCULO.
           05  TB-CALC OCCURS 150 TIMES INDEXED BY IX-CAL.
               10  TB-CAL-CODIGO       PIC 9(004).
               10  TB-CAL-DESCRICAO    PIC X(030).
               10  TB-CAL-NATUREZA     PIC X(001).
               10  TB-CAL-REFERENCIA   PIC 9(005)V99.
               10  TB-CAL-VALOR        PIC 9(009)V99.
               10  TB-CAL-CONTA        PIC 9(008).
               10  TB-CAL-INC-INSS     PIC X(001).
               10  TB-CAL-INC-IRRF     PIC X(001).
               10  TB-CAL-INC-FGTS     PIC X(001).
      *
      *--- AREA DE TRABALHO PARA INCLUSAO DE EVENTO -------------------
       01  WS-EVENTO-NOVO.
           05  WS-NOV-CODIGO           PIC 9(004) VALUE ZEROS.
           05  WS-NOV-REFERENCIA       PIC 9(005)V99 VALUE ZEROS.
           05  WS-NOV-VALOR            PIC 9(009)V99 VALUE ZEROS.
      *
      *--- ACUMULADORES GERAIS ----------------------------------------
       01  WS-TOTAIS-GERAIS.
           05  WS-LIDOS-EMP            PIC 9(007) VALUE ZEROS.
           05  WS-LIDOS-MOV            PIC 9(007) VALUE ZEROS.
           05  WS-LIDOS-PON            PIC 9(007) VALUE ZEROS.
           05  WS-LIDOS-DEP            PIC 9(007) VALUE ZEROS.
           05  WS-CALCULADOS           PIC 9(007) VALUE ZEROS.
           05  WS-REJEITADOS           PIC 9(007) VALUE ZEROS.
           05  WS-GRAV-FOL             PIC 9(007) VALUE ZEROS.
           05  WS-GRAV-RES             PIC 9(007) VALUE ZEROS.
           05  WS-QTD-CRITICAS         PIC 9(007) VALUE ZEROS.
           05  WS-TOT-GER-PROVENTOS    PIC 9(013)V99 VALUE ZEROS.
           05  WS-TOT-GER-DESCONTOS    PIC 9(013)V99 VALUE ZEROS.
           05  WS-TOT-GER-LIQUIDO      PIC S9(013)V99 VALUE ZEROS.
           05  WS-TOT-GER-INSS         PIC 9(013)V99 VALUE ZEROS.
           05  WS-TOT-GER-IRRF         PIC 9(013)V99 VALUE ZEROS.
           05  WS-TOT-GER-FGTS         PIC 9(013)V99 VALUE ZEROS.
      *
      *--- AUXILIARES -------------------------------------------------
       01  WS-AUXILIARES.
           05  WS-IDX                  PIC S9(004) VALUE ZEROS.
           05  WS-COD-RETORNO          PIC 9(002) VALUE ZEROS.
           05  WS-AUX-VALOR            PIC 9(009)V99 VALUE ZEROS.
           05  WS-AUX-VALOR2           PIC S9(011)V99 VALUE ZEROS.
           05  WS-AUX-REFER            PIC 9(005)V99 VALUE ZEROS.
           05  WS-DATA-COMPET-INI      PIC 9(008) VALUE ZEROS.
           05  WS-DATA-COMPET-FIM      PIC 9(008) VALUE ZEROS.
           05  WS-DATA-SISTEMA         PIC 9(008) VALUE ZEROS.
           05  WS-HORA-SISTEMA         PIC 9(008) VALUE ZEROS.
      *
       01  WS-LINHA-CRITICA.
           05  FILLER                  PIC X(005) VALUE 'SFP-'.
           05  WSC-CODIGO              PIC 9(004).
           05  FILLER                  PIC X(002) VALUE ' '.
           05  WSC-SEVERIDADE          PIC X(001).
           05  FILLER                  PIC X(002) VALUE ' '.
           05  FILLER                  PIC X(005) VALUE 'MATR:'.
           05  WSC-MATRICULA           PIC 9(008).
           05  FILLER                  PIC X(002) VALUE ' '.
           05  WSC-MENSAGEM            PIC X(070).
           05  FILLER                  PIC X(033) VALUE SPACES.
      *
       01  WS-LINHA-TOTAL.
           05  FILLER                  PIC X(030).
           05  WST-DESCRICAO           PIC X(040).
           05  WST-VALOR               PIC ZZZ.ZZZ.ZZZ.ZZ9,99-.
           05  FILLER                  PIC X(044) VALUE SPACES.
      *
      *--- AREA DE TRABALHO DO PONTO DO EMPREGADO CORRENTE ------------
       COPY SFPWPON.
      *
       COPY SFPWCON.
       COPY SFPWTRB.
       COPY SFPWUTL.
      *
       PROCEDURE DIVISION.
      *================================================================*
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR-EMPREGADO
               UNTIL WS-FIM-EMP = 'S'
           PERFORM 9000-FINALIZAR
           MOVE WS-COD-RETORNO         TO RETURN-CODE
           STOP RUN.
      *
      *================================================================*
      * 1000 - INICIALIZACAO                                           *
      *================================================================*
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           ACCEPT WS-DATA-SISTEMA FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SISTEMA FROM TIME
      *
           OPEN INPUT  ARQ-EMPREGADO
                       ARQ-PONTO
                       ARQ-DEPEND
                       ARQ-MOVIMENTO
                       ARQ-EVENTO
                       ARQ-PARAMETRO
                       ARQ-SYSIN
           OPEN OUTPUT ARQ-FOLHA
                       ARQ-RESUMO
                       ARQ-CRITICA
      *
           PERFORM 1010-VALIDAR-ABERTURA
           PERFORM 1100-LER-CARTAO-PARM
           PERFORM 1200-CARREGAR-EVENTOS
           PERFORM 1300-CARREGAR-PARAMETROS
           PERFORM 1400-INICIAR-TRIBUTOS
           PERFORM 1500-MONTAR-CABEC-CRITICA
      *
           PERFORM 8100-LER-EMPREGADO
           PERFORM 8200-LER-PONTO
           PERFORM 8300-LER-DEPENDENTE
           PERFORM 8400-LER-MOVIMENTO.
       1000-FIM.
           EXIT.
      *
       1010-VALIDAR-ABERTURA SECTION.
       1010-INICIO.
           IF WS-FS-EMP NOT = '00' OR WS-FS-MOV NOT = '00'
              OR WS-FS-EVE NOT = '00' OR WS-FS-PAR NOT = '00'
               MOVE 12                 TO WS-COD-RETORNO
               DISPLAY 'SFP0300 - ERRO NA ABERTURA DOS ARQUIVOS'
               DISPLAY '  SFPEMP=' WS-FS-EMP ' SFPMOV=' WS-FS-MOV
               DISPLAY '  SFPEVE=' WS-FS-EVE ' SFPTAB=' WS-FS-PAR
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF.
       1010-FIM.
           EXIT.
      *
       1100-LER-CARTAO-PARM SECTION.
       1100-INICIO.
           READ ARQ-SYSIN
               AT END
                   DISPLAY 'SFP0300 - SYSIN VAZIO. ABORTANDO.'
                   MOVE 12             TO RETURN-CODE
                   STOP RUN
               NOT AT END
                   CONTINUE
           END-READ
      *
           MOVE REG-SYSIN(01:06)       TO WS-PRM-COMPETENCIA
           MOVE REG-SYSIN(08:01)       TO WS-PRM-TIPO-FOLHA
           MOVE REG-SYSIN(10:06)       TO WS-PRM-CC-INICIAL
           MOVE REG-SYSIN(17:06)       TO WS-PRM-CC-FINAL
           MOVE REG-SYSIN(24:01)       TO WS-PRM-SIMULACAO
           MOVE REG-SYSIN(26:08)       TO WS-PRM-DT-PAGAMENTO
      *
           IF WS-PRM-MES < 01 OR WS-PRM-MES > 12
               DISPLAY 'SFP0300 - COMPETENCIA INVALIDA: '
                       WS-PRM-COMPETENCIA
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           COMPUTE WS-DATA-COMPET-INI =
                   (WS-PRM-ANO * 10000) + (WS-PRM-MES * 100) + 1
           COMPUTE WS-DATA-COMPET-FIM =
                   (WS-PRM-ANO * 10000) + (WS-PRM-MES * 100) + 30
      *
           DISPLAY '=================================================='
           DISPLAY ' SFP0300 - MOTOR DE CALCULO DA FOLHA DE PAGAMENTO '
           DISPLAY '=================================================='
           DISPLAY ' COMPETENCIA .....: ' WS-PRM-COMPETENCIA
           DISPLAY ' TIPO DE FOLHA ...: ' WS-PRM-TIPO-FOLHA
           DISPLAY ' CENTRO DE CUSTO .: ' WS-PRM-CC-INICIAL
                   ' ATE ' WS-PRM-CC-FINAL
           DISPLAY ' SIMULACAO .......: ' WS-PRM-SIMULACAO
           DISPLAY ' DATA PAGAMENTO ..: ' WS-PRM-DT-PAGAMENTO
           DISPLAY '=================================================='.
       1100-FIM.
           EXIT.
      *
       1200-CARREGAR-EVENTOS SECTION.
       1200-INICIO.
           MOVE ZEROS                  TO WS-QTD-EVENTOS
           MOVE 'N'                    TO WS-FIM-EVE
           PERFORM UNTIL WS-FIM-EVE = 'S'
               READ ARQ-EVENTO
                   AT END
                       MOVE 'S'        TO WS-FIM-EVE
                   NOT AT END
                       IF EVE-SITUACAO = 'A'
                           ADD 1       TO WS-QTD-EVENTOS
                           PERFORM 1210-MOVER-EVENTO
                       END-IF
               END-READ
           END-PERFORM
           DISPLAY ' EVENTOS CARREGADOS: ' WS-QTD-EVENTOS.
       1200-FIM.
           EXIT.
      *
       1210-MOVER-EVENTO SECTION.
       1210-INICIO.
           MOVE EVE-CODIGO        TO TB-EVE-CODIGO(WS-QTD-EVENTOS)
           MOVE EVE-DESCRICAO     TO TB-EVE-DESCRICAO(WS-QTD-EVENTOS)
           MOVE EVE-NATUREZA      TO TB-EVE-NATUREZA(WS-QTD-EVENTOS)
           MOVE EVE-TIPO-CALCULO  TO TB-EVE-TIPO-CALC(WS-QTD-EVENTOS)
           MOVE EVE-INC-INSS      TO TB-EVE-INC-INSS(WS-QTD-EVENTOS)
           MOVE EVE-INC-IRRF      TO TB-EVE-INC-IRRF(WS-QTD-EVENTOS)
           MOVE EVE-INC-FGTS      TO TB-EVE-INC-FGTS(WS-QTD-EVENTOS)
           MOVE EVE-INC-DSR       TO TB-EVE-INC-DSR(WS-QTD-EVENTOS)
           MOVE EVE-INC-13O       TO TB-EVE-INC-13O(WS-QTD-EVENTOS)
           MOVE EVE-INC-FERIAS    TO TB-EVE-INC-FERIAS(WS-QTD-EVENTOS)
           MOVE EVE-UNIDADE       TO TB-EVE-UNIDADE(WS-QTD-EVENTOS)
           MOVE EVE-PERCENTUAL    TO TB-EVE-PERCENTUAL(WS-QTD-EVENTOS)
           MOVE EVE-CONTA-CONTABIL TO TB-EVE-CONTA(WS-QTD-EVENTOS).
       1210-FIM.
           EXIT.
      *
       1300-CARREGAR-PARAMETROS SECTION.
       1300-INICIO.
           MOVE 'N'                    TO WS-FIM-PAR
           PERFORM UNTIL WS-FIM-PAR = 'S'
               READ ARQ-PARAMETRO
                   AT END
                       MOVE 'S'        TO WS-FIM-PAR
                   NOT AT END
                       IF TAB-PARAMETRO
                           PERFORM 1310-ATRIBUIR-PARAMETRO
                       END-IF
               END-READ
           END-PERFORM
           CLOSE ARQ-PARAMETRO.
       1300-FIM.
           EXIT.
      *
       1310-ATRIBUIR-PARAMETRO SECTION.
       1310-INICIO.
           EVALUATE TAB-CHAVE
               WHEN 'SALARIO-MINIMO'
                    MOVE TAB-LIMITE    TO WS-SALARIO-MINIMO
               WHEN 'PERC-VALE-TRAN'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-VT
               WHEN 'PERC-ADIANTAME'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-ADIANT
               WHEN 'MARGEM-CONSIGN'
                    MOVE TAB-ALIQUOTA  TO WS-MARGEM-CONSIG
               WHEN 'PERC-HORA-EX50'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-HE-050
               WHEN 'PERC-HORA-E100'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-HE-100
               WHEN 'PERC-AD-NOTURN'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-NOTURNO
               WHEN 'PERC-PERICULOS'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-PERICULOSID
               WHEN 'PERC-QUINQUENI'
                    MOVE TAB-ALIQUOTA  TO WS-PERC-QUINQUENIO
               WHEN 'MAX-QUINQUENIO'
                    MOVE TAB-LIMITE    TO WS-MAX-QUINQUENIOS
               WHEN 'CONTRIB-SINDIC'
                    MOVE TAB-ALIQUOTA  TO WS-VLR-CONTR-SINDIC
           END-EVALUATE.
       1310-FIM.
           EXIT.
      *
       1400-INICIAR-TRIBUTOS SECTION.
       1400-INICIO.
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CARREGA-TABELAS     TO TRUE
           MOVE WS-PRM-COMPETENCIA     TO TRB-COMPETENCIA
           CALL 'SFP0310' USING AREA-TRIBUTOS
           IF TRB-COD-RETORNO NOT = ZEROS
               DISPLAY 'SFP0300 - FALHA NA CARGA DAS TABELAS LEGAIS'
               DISPLAY '  ' TRB-MSG-RETORNO
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
           DISPLAY ' TABELAS LEGAIS...: CARREGADAS'.
       1400-FIM.
           EXIT.
      *
       1500-MONTAR-CABEC-CRITICA SECTION.
       1500-INICIO.
           MOVE ALL '='                TO REG-CRITICA
           WRITE REG-CRITICA
           MOVE SPACES                 TO REG-CRITICA
           STRING 'SFP0300 - RELATORIO DE CRITICAS DA FOLHA'
                  '   COMPETENCIA: ' WS-PRM-COMPETENCIA
               DELIMITED BY SIZE INTO REG-CRITICA
           WRITE REG-CRITICA
           MOVE ALL '='                TO REG-CRITICA
           WRITE REG-CRITICA.
       1500-FIM.
           EXIT.
      *
      *================================================================*
      * 2000 - PROCESSAMENTO DE UM EMPREGADO                           *
      *================================================================*
       2000-PROCESSAR-EMPREGADO SECTION.
       2000-INICIO.
           MOVE EMP-MATRICULA          TO WS-MATRIC-CORRENTE
           PERFORM 2010-INICIAR-ACUMULADORES
           PERFORM 2020-SINCRONIZAR-PONTO
           PERFORM 2030-SINCRONIZAR-DEPENDENTES
           PERFORM 2040-VERIFICAR-ELEGIBILIDADE
      *
           IF WS-EMP-ELEGIVEL = 'S'
               PERFORM 2100-CALCULAR-PROVENTOS
               PERFORM 2200-APLICAR-MOVIMENTOS
               PERFORM 2300-DESCONTOS-FREQUENCIA
               PERFORM 2400-APURAR-BASES
               PERFORM 2500-CALCULAR-INSS
               PERFORM 2550-CALCULAR-SALARIO-FAM
               PERFORM 2600-CALCULAR-IRRF
               PERFORM 2700-DESCONTOS-DIVERSOS
               PERFORM 2800-CALCULAR-FGTS
               PERFORM 2850-APURAR-LIQUIDO
               PERFORM 2900-GRAVAR-RESULTADOS
               ADD 1                   TO WS-CALCULADOS
           ELSE
               ADD 1                   TO WS-REJEITADOS
               PERFORM 2050-DESPREZAR-MOVIMENTOS
           END-IF
      *
           PERFORM 8100-LER-EMPREGADO.
       2000-FIM.
           EXIT.
      *
       2010-INICIAR-ACUMULADORES SECTION.
       2010-INICIO.
           MOVE ZEROS TO WS-TOT-PROVENTOS WS-TOT-DESCONTOS
                         WS-LIQUIDO      WS-BASE-INSS
                         WS-BASE-IRRF    WS-BASE-FGTS
                         WS-BASE-DSR     WS-VLR-INSS
                         WS-VLR-IRRF     WS-VLR-FGTS
                         WS-VLR-SALFAM   WS-VLR-PENSAO
                         WS-ALIQ-INSS    WS-ALIQ-IRRF
                         WS-QTD-DEP-IRRF WS-QTD-DEP-SALFAM
                         WS-VLR-PLANO-DEP WS-QTD-CALC
                         WS-TOT-HORAS-EXTRAS WS-VLR-NOTURNO
                         WS-QTD-QUINQUENIOS
           INITIALIZE WS-TABELA-CALCULO
           MOVE ZEROS                  TO REG-PONTO
           MOVE ZEROS                  TO PON-MATRICULA
           MOVE 30                     TO WS-DIAS-PAGAR
           MOVE 25                     TO PON-DIAS-UTEIS-MES
           MOVE 05                     TO WS-DIAS-DSR.
       2010-FIM.
           EXIT.
      *
       2020-SINCRONIZAR-PONTO SECTION.
       2020-INICIO.
      *    DESPREZA REGISTROS ORFAOS DE PONTO
           PERFORM UNTIL WS-FIM-PON = 'S'
                      OR PONE-MATRICULA >= WS-MATRIC-CORRENTE
               MOVE 0210               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE PONE-MATRICULA     TO WSC-MATRICULA
               MOVE 'PONTO SEM CADASTRO CORRESPONDENTE - DESPREZADO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               PERFORM 8200-LER-PONTO
           END-PERFORM
      *
      *    HAVENDO CASAMENTO, O REGISTRO E TRANSFERIDO PARA A AREA
      *    DE TRABALHO E O ARQUIVO AVANCA UMA POSICAO
           IF WS-FIM-PON = 'N'
              AND PONE-MATRICULA = WS-MATRIC-CORRENTE
               MOVE REG-PONTO-E        TO REG-PONTO
               PERFORM 8200-LER-PONTO
           END-IF
      *
           IF PON-DIAS-UTEIS-MES = ZEROS
               MOVE 25                 TO PON-DIAS-UTEIS-MES
           END-IF
           COMPUTE WS-DIAS-DSR =
                   WS-DIAS-MES-COMERC - PON-DIAS-UTEIS-MES
           IF WS-DIAS-DSR < ZEROS
               MOVE ZEROS              TO WS-DIAS-DSR
           END-IF.
       2020-FIM.
           EXIT.
      *
       2030-SINCRONIZAR-DEPENDENTES SECTION.
       2030-INICIO.
           PERFORM UNTIL WS-FIM-DEP = 'S'
                      OR DEP-MATRICULA >= WS-MATRIC-CORRENTE
               PERFORM 8300-LER-DEPENDENTE
           END-PERFORM
      *
           PERFORM UNTIL WS-FIM-DEP = 'S'
                      OR DEP-MATRICULA NOT = WS-MATRIC-CORRENTE
               IF DEP-IND-IRRF = 'S'
                   ADD 1               TO WS-QTD-DEP-IRRF
               END-IF
               IF DEP-IND-SALARIO-FAM = 'S'
                   ADD 1               TO WS-QTD-DEP-SALFAM
               END-IF
               IF DEP-IND-PLANO-SAUDE = 'S'
                   ADD DEP-VLR-PLANO-SAUDE TO WS-VLR-PLANO-DEP
               END-IF
               PERFORM 8300-LER-DEPENDENTE
           END-PERFORM.
       2030-FIM.
           EXIT.
      *
       2040-VERIFICAR-ELEGIBILIDADE SECTION.
       2040-INICIO.
           MOVE 'S'                    TO WS-EMP-ELEGIVEL
      *
           IF NOT EMP-SIT-VALIDA
               MOVE 'N'                TO WS-EMP-ELEGIVEL
               MOVE 0101               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'SITUACAO CADASTRAL INVALIDA - FORA DA FOLHA'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               GO TO 2040-FIM
           END-IF
      *
           IF EMP-DEMITIDO
               IF EMP-DT-DEMISSAO < WS-DATA-COMPET-INI
                   MOVE 'N'            TO WS-EMP-ELEGIVEL
                   GO TO 2040-FIM
               END-IF
           END-IF
      *
           IF EMP-DT-ADMISSAO > WS-DATA-COMPET-FIM
               MOVE 'N'                TO WS-EMP-ELEGIVEL
               MOVE 0102               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'ADMISSAO POSTERIOR A COMPETENCIA PROCESSADA'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               GO TO 2040-FIM
           END-IF
      *
           IF EMP-CENTRO-CUSTO < WS-PRM-CC-INICIAL
              OR EMP-CENTRO-CUSTO > WS-PRM-CC-FINAL
               MOVE 'N'                TO WS-EMP-ELEGIVEL
               GO TO 2040-FIM
           END-IF
      *
           IF EMP-SALARIO-BASE = ZEROS
               MOVE 'N'                TO WS-EMP-ELEGIVEL
               MOVE 0103               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'SALARIO BASE ZERADO - EMPREGADO NAO CALCULADO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
               GO TO 2040-FIM
           END-IF
      *
           IF EMP-SALARIO-BASE < WS-SALARIO-MINIMO
              AND EMP-MENSALISTA
               MOVE 0104               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'SALARIO BASE INFERIOR AO MINIMO LEGAL VIGENTE'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
           END-IF.
       2040-FIM.
           EXIT.
      *
       2050-DESPREZAR-MOVIMENTOS SECTION.
       2050-INICIO.
           PERFORM UNTIL WS-FIM-MOV = 'S'
                      OR MOV-MATRICULA NOT = WS-MATRIC-CORRENTE
               PERFORM 8400-LER-MOVIMENTO
           END-PERFORM.
       2050-FIM.
           EXIT.
      *
      *================================================================*
      * 2100 - PROVENTOS AUTOMATICOS                                   *
      *================================================================*
       2100-CALCULAR-PROVENTOS SECTION.
       2100-INICIO.
           PERFORM 2110-CALCULAR-VALOR-HORA
           PERFORM 2120-SALARIO-DO-MES
           PERFORM 2130-HORAS-EXTRAS
           PERFORM 2140-ADICIONAL-NOTURNO
           PERFORM 2150-INSALUBRIDADE
           PERFORM 2160-PERICULOSIDADE
           PERFORM 2170-QUINQUENIO.
       2100-FIM.
           EXIT.
      *
       2110-CALCULAR-VALOR-HORA SECTION.
       2110-INICIO.
           IF EMP-CARGA-HOR-MES = ZEROS
               MOVE 220                TO EMP-CARGA-HOR-MES
           END-IF
      *
           EVALUATE TRUE
               WHEN EMP-MENSALISTA
                    COMPUTE WS-VALOR-HORA ROUNDED =
                            EMP-SALARIO-BASE / EMP-CARGA-HOR-MES
                    COMPUTE WS-VALOR-DIA ROUNDED =
                            EMP-SALARIO-BASE / WS-DIAS-MES-COMERC
               WHEN EMP-HORISTA
                    MOVE EMP-SALARIO-BASE TO WS-VALOR-HORA
                    COMPUTE WS-VALOR-DIA ROUNDED =
                            WS-VALOR-HORA * EMP-CARGA-HOR-MES
                          / WS-DIAS-MES-COMERC
               WHEN EMP-DIARISTA
                    MOVE EMP-SALARIO-BASE TO WS-VALOR-DIA
                    COMPUTE WS-VALOR-HORA ROUNDED =
                            WS-VALOR-DIA * WS-DIAS-MES-COMERC
                          / EMP-CARGA-HOR-MES
           END-EVALUATE
      *
           IF EMP-MENSALISTA
               MOVE EMP-SALARIO-BASE   TO WS-SALARIO-REFER
           ELSE
               COMPUTE WS-SALARIO-REFER ROUNDED =
                       WS-VALOR-HORA * EMP-CARGA-HOR-MES
           END-IF.
       2110-FIM.
           EXIT.
      *
       2120-SALARIO-DO-MES SECTION.
       2120-INICIO.
      *    APURA OS DIAS A PAGAR CONSIDERANDO ADMISSAO E DEMISSAO
      *    OCORRIDAS DENTRO DA COMPETENCIA PROCESSADA
           MOVE WS-DIAS-MES-COMERC     TO WS-DIAS-PAGAR
      *
           IF EMP-DT-ADMISSAO >= WS-DATA-COMPET-INI
              AND EMP-DT-ADMISSAO <= WS-DATA-COMPET-FIM
               COMPUTE WS-DIAS-PAGAR =
                       WS-DIAS-MES-COMERC
                     - FUNCTION MOD (EMP-DT-ADMISSAO, 100) + 1
               MOVE 0110               TO WSC-CODIGO
               MOVE 'I'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'ADMITIDO NO MES - SALARIO PROPORCIONALIZADO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
           END-IF
      *
           IF EMP-DEMITIDO AND EMP-DT-DEMISSAO NOT = ZEROS
              AND EMP-DT-DEMISSAO >= WS-DATA-COMPET-INI
              AND EMP-DT-DEMISSAO <= WS-DATA-COMPET-FIM
               COMPUTE WS-DIAS-PAGAR =
                       FUNCTION MOD (EMP-DT-DEMISSAO, 100)
           END-IF
      *
      *    DESCONTA DIAS DE AFASTAMENTO PREVIDENCIARIO
           IF PON-DIAS-AFASTAM > ZEROS
               SUBTRACT PON-DIAS-AFASTAM FROM WS-DIAS-PAGAR
           END-IF
           IF WS-DIAS-PAGAR < ZEROS
               MOVE ZEROS              TO WS-DIAS-PAGAR
           END-IF
           IF WS-DIAS-PAGAR > WS-DIAS-MES-COMERC
               MOVE WS-DIAS-MES-COMERC TO WS-DIAS-PAGAR
           END-IF
      *
           IF EMP-HORISTA
               COMPUTE WS-SALARIO-CALC ROUNDED =
                       WS-VALOR-HORA * PON-HORAS-NORMAIS
               MOVE CTE-EV-SAL-HORISTA TO WS-NOV-CODIGO
               MOVE PON-HORAS-NORMAIS  TO WS-NOV-REFERENCIA
           ELSE
               COMPUTE WS-SALARIO-CALC ROUNDED =
                       WS-VALOR-DIA * WS-DIAS-PAGAR
               MOVE CTE-EV-SAL-MENSAL  TO WS-NOV-CODIGO
               MOVE WS-DIAS-PAGAR      TO WS-NOV-REFERENCIA
           END-IF
      *
           MOVE WS-SALARIO-CALC        TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2120-FIM.
           EXIT.
      *
       2130-HORAS-EXTRAS SECTION.
       2130-INICIO.
           MOVE ZEROS                  TO WS-TOT-HORAS-EXTRAS
      *
           IF PON-HE-050 > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       PON-HE-050 * WS-VALOR-HORA
                     * (100 + WS-PERC-HE-050) / 100
               MOVE CTE-EV-HE-050      TO WS-NOV-CODIGO
               MOVE PON-HE-050         TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
               ADD WS-AUX-VALOR        TO WS-TOT-HORAS-EXTRAS
           END-IF
      *
           IF PON-HE-100 > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       PON-HE-100 * WS-VALOR-HORA
                     * (100 + WS-PERC-HE-100) / 100
               MOVE CTE-EV-HE-100      TO WS-NOV-CODIGO
               MOVE PON-HE-100         TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
               ADD WS-AUX-VALOR        TO WS-TOT-HORAS-EXTRAS
           END-IF
      *
      *    REFLEXO DAS HORAS EXTRAS NO DESCANSO SEMANAL REMUNERADO
      *    DSR = (TOTAL HE / DIAS UTEIS) X DIAS DE REPOUSO
           IF WS-TOT-HORAS-EXTRAS > ZEROS
              AND PON-DIAS-UTEIS-MES > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       WS-TOT-HORAS-EXTRAS
                     / PON-DIAS-UTEIS-MES * WS-DIAS-DSR
               IF WS-AUX-VALOR > ZEROS
                   MOVE CTE-EV-DSR-HE  TO WS-NOV-CODIGO
                   MOVE WS-DIAS-DSR    TO WS-NOV-REFERENCIA
                   MOVE WS-AUX-VALOR   TO WS-NOV-VALOR
                   PERFORM 8500-INCLUIR-EVENTO
               END-IF
           END-IF.
       2130-FIM.
           EXIT.
      *
       2140-ADICIONAL-NOTURNO SECTION.
       2140-INICIO.
           MOVE ZEROS                  TO WS-VLR-NOTURNO
           IF PON-HORAS-NOTURNAS = ZEROS
               GO TO 2140-FIM
           END-IF
      *
      *    A HORA NOTURNA E REDUZIDA (52 MIN 30 SEG). O FATOR DE
      *    CONVERSAO 120/105 TRANSFORMA A HORA RELOGIO EM HORA
      *    NOTURNA LEGAL. SOBRE ELA INCIDE O ADICIONAL PERCENTUAL.
           COMPUTE WS-AUX-REFER ROUNDED =
                   PON-HORAS-NOTURNAS * 120 / 105
      *
           COMPUTE WS-VLR-NOTURNO ROUNDED =
                   WS-AUX-REFER * WS-VALOR-HORA
                 * WS-PERC-NOTURNO / 100
      *
           MOVE CTE-EV-AD-NOTURNO      TO WS-NOV-CODIGO
           MOVE WS-AUX-REFER           TO WS-NOV-REFERENCIA
           MOVE WS-VLR-NOTURNO         TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO
      *
           IF PON-DIAS-UTEIS-MES > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       WS-VLR-NOTURNO
                     / PON-DIAS-UTEIS-MES * WS-DIAS-DSR
               IF WS-AUX-VALOR > ZEROS
                   MOVE CTE-EV-DSR-NOTURNO TO WS-NOV-CODIGO
                   MOVE WS-DIAS-DSR    TO WS-NOV-REFERENCIA
                   MOVE WS-AUX-VALOR   TO WS-NOV-VALOR
                   PERFORM 8500-INCLUIR-EVENTO
               END-IF
           END-IF.
       2140-FIM.
           EXIT.
      *
       2150-INSALUBRIDADE SECTION.
       2150-INICIO.
      *    ADICIONAL DE INSALUBRIDADE CALCULADO SOBRE O SALARIO
      *    MINIMO NACIONAL, CONFORME GRAU REGISTRADO NO CADASTRO
           IF EMP-PERC-INSALUBRID = ZEROS
               GO TO 2150-FIM
           END-IF
           COMPUTE WS-AUX-VALOR ROUNDED =
                   WS-SALARIO-MINIMO * EMP-PERC-INSALUBRID / 100
           MOVE CTE-EV-INSALUBRID      TO WS-NOV-CODIGO
           MOVE EMP-PERC-INSALUBRID    TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2150-FIM.
           EXIT.
      *
       2160-PERICULOSIDADE SECTION.
       2160-INICIO.
      *    ADICIONAL DE PERICULOSIDADE SOBRE O SALARIO CONTRATUAL.
      *    A LEGISLACAO VEDA A CUMULACAO COM A INSALUBRIDADE,
      *    PREVALECENDO A CONDICAO MAIS BENEFICA AO EMPREGADO.
           IF EMP-IND-PERICULOSID NOT = 'S'
               GO TO 2160-FIM
           END-IF
      *
           IF EMP-PERC-INSALUBRID > ZEROS
               MOVE 0120               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'ACUMULO INSALUBRIDADE/PERICULOSIDADE - VERIFICAR'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
           END-IF
      *
           COMPUTE WS-AUX-VALOR ROUNDED =
                   WS-SALARIO-REFER * WS-PERC-PERICULOSID / 100
           MOVE CTE-EV-PERICULOSID     TO WS-NOV-CODIGO
           MOVE WS-PERC-PERICULOSID    TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2160-FIM.
           EXIT.
      *
       2170-QUINQUENIO SECTION.
       2170-INICIO.
      *    ADICIONAL POR TEMPO DE SERVICO CONCEDIDO POR ACORDO
      *    COLETIVO: PERCENTUAL POR QUINQUENIO COMPLETO, LIMITADO
      *    AO NUMERO MAXIMO PARAMETRIZADO.
           IF WS-PERC-QUINQUENIO = ZEROS
               GO TO 2170-FIM
           END-IF
      *
           INITIALIZE AREA-UTILITARIOS
           SET UTL-DIFERENCA-DIAS      TO TRUE
           MOVE EMP-DT-ADMISSAO        TO UTL-DATA-INI
           MOVE WS-DATA-COMPET-FIM     TO UTL-DATA-FIM
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           MOVE UTL-QTD-DIAS           TO WS-TEMPO-CASA-DIAS
      *
           IF WS-TEMPO-CASA-DIAS < 1826
               GO TO 2170-FIM
           END-IF
      *
           COMPUTE WS-QTD-QUINQUENIOS = WS-TEMPO-CASA-DIAS / 1826
           IF WS-QTD-QUINQUENIOS > WS-MAX-QUINQUENIOS
               MOVE WS-MAX-QUINQUENIOS TO WS-QTD-QUINQUENIOS
           END-IF
      *
           COMPUTE WS-AUX-VALOR ROUNDED =
                   WS-SALARIO-REFER * WS-QTD-QUINQUENIOS
                 * WS-PERC-QUINQUENIO / 100
           MOVE CTE-EV-QUINQUENIO      TO WS-NOV-CODIGO
           MOVE WS-QTD-QUINQUENIOS     TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2170-FIM.
           EXIT.
      *
      *================================================================*
      * 2200 - APLICACAO DOS EVENTOS INFORMADOS NO MOVIMENTO           *
      *        O METODO DE APURACAO E DEFINIDO PELO TIPO DE CALCULO    *
      *        REGISTRADO NO CADASTRO DE EVENTOS (SFPEVE)              *
      *================================================================*
       2200-APLICAR-MOVIMENTOS SECTION.
       2200-INICIO.
      *    DESPREZA MOVIMENTOS ORFAOS
           PERFORM UNTIL WS-FIM-MOV = 'S'
                      OR MOV-MATRICULA >= WS-MATRIC-CORRENTE
               MOVE 0220               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE MOV-MATRICULA      TO WSC-MATRICULA
               MOVE 'MOVIMENTO SEM CADASTRO DE EMPREGADO - REJEITADO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
               PERFORM 8400-LER-MOVIMENTO
           END-PERFORM
      *
           PERFORM UNTIL WS-FIM-MOV = 'S'
                      OR MOV-MATRICULA NOT = WS-MATRIC-CORRENTE
               PERFORM 2210-PROCESSAR-MOVIMENTO
               PERFORM 8400-LER-MOVIMENTO
           END-PERFORM.
       2200-FIM.
           EXIT.
      *
       2210-PROCESSAR-MOVIMENTO SECTION.
       2210-INICIO.
           IF MOV-COMPETENCIA NOT = WS-PRM-COMPETENCIA
               MOVE 0221               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE MOV-MATRICULA      TO WSC-MATRICULA
               MOVE 'MOVIMENTO DE OUTRA COMPETENCIA - DESPREZADO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               GO TO 2210-FIM
           END-IF
      *
           SEARCH ALL TB-EVENTO
               AT END
                   MOVE 0222           TO WSC-CODIGO
                   MOVE 'E'            TO WSC-SEVERIDADE
                   MOVE MOV-MATRICULA  TO WSC-MATRICULA
                   MOVE SPACES         TO WSC-MENSAGEM
                   STRING 'EVENTO ' MOV-COD-EVENTO
                          ' INEXISTENTE NO CADASTRO - REJEITADO'
                       DELIMITED BY SIZE INTO WSC-MENSAGEM
                   PERFORM 8900-GRAVAR-CRITICA
                   MOVE 04             TO WS-COD-RETORNO
                   GO TO 2210-FIM
               WHEN TB-EVE-CODIGO(IX-EVE) = MOV-COD-EVENTO
                   PERFORM 2220-CALCULAR-POR-TIPO
           END-SEARCH.
       2210-FIM.
           EXIT.
      *
       2220-CALCULAR-POR-TIPO SECTION.
       2220-INICIO.
           MOVE ZEROS                  TO WS-AUX-VALOR
           MOVE MOV-REFERENCIA         TO WS-AUX-REFER
      *
           EVALUATE TB-EVE-TIPO-CALC(IX-EVE)
      *
      *        001 - VALOR INFORMADO DIRETAMENTE NO MOVIMENTO
               WHEN 001
                    MOVE MOV-VALOR     TO WS-AUX-VALOR
      *
      *        002 - QUANTIDADE DE HORAS X VALOR HORA X PERCENTUAL
               WHEN 002
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            MOV-REFERENCIA * WS-VALOR-HORA
                          * TB-EVE-PERCENTUAL(IX-EVE) / 100
      *
      *        003 - QUANTIDADE DE DIAS X VALOR DIA
               WHEN 003
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            MOV-REFERENCIA * WS-VALOR-DIA
      *
      *        004 - PERCENTUAL INFORMADO SOBRE O SALARIO BASE
               WHEN 004
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            WS-SALARIO-REFER * MOV-REFERENCIA / 100
      *
      *        005 - PERCENTUAL DO CADASTRO SOBRE O SALARIO MINIMO
               WHEN 005
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            WS-SALARIO-MINIMO
                          * TB-EVE-PERCENTUAL(IX-EVE) / 100
      *
      *        006 - PERCENTUAL SOBRE O TOTAL DE PROVENTOS APURADO
               WHEN 006
                    PERFORM 2400-APURAR-BASES
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            WS-TOT-PROVENTOS * MOV-REFERENCIA / 100
      *
      *        007 - VALOR CADASTRADO NA FICHA DO EMPREGADO
               WHEN 007
                    MOVE EMP-MEDIA-VARIAVEIS TO WS-AUX-VALOR
      *
      *        010 - QUANTIDADE X VALOR UNITARIO INFORMADO
               WHEN 010
                    COMPUTE WS-AUX-VALOR ROUNDED =
                            MOV-REFERENCIA * MOV-VALOR
      *
               WHEN OTHER
                    MOVE MOV-VALOR     TO WS-AUX-VALOR
                    MOVE 0223          TO WSC-CODIGO
                    MOVE 'W'           TO WSC-SEVERIDADE
                    MOVE MOV-MATRICULA TO WSC-MATRICULA
                    MOVE 'TIPO DE CALCULO NAO IMPLEMENTADO NO MOTOR'
                                       TO WSC-MENSAGEM
                    PERFORM 8900-GRAVAR-CRITICA
           END-EVALUATE
      *
           IF WS-AUX-VALOR > ZEROS
               MOVE MOV-COD-EVENTO     TO WS-NOV-CODIGO
               MOVE WS-AUX-REFER       TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2220-FIM.
           EXIT.
      *
      *================================================================*
      * 2300 - DESCONTOS DE FREQUENCIA                                 *
      *================================================================*
       2300-DESCONTOS-FREQUENCIA SECTION.
       2300-INICIO.
           IF PON-FALTAS-DIAS > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       PON-FALTAS-DIAS * WS-VALOR-DIA
               MOVE CTE-EV-FALTAS      TO WS-NOV-CODIGO
               MOVE PON-FALTAS-DIAS    TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF
      *
      *    A FALTA INJUSTIFICADA ACARRETA A PERDA DO DESCANSO
      *    SEMANAL REMUNERADO DA RESPECTIVA SEMANA
           IF PON-DSR-PERDIDOS > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       PON-DSR-PERDIDOS * WS-VALOR-DIA
               MOVE CTE-EV-DSR-FALTAS  TO WS-NOV-CODIGO
               MOVE PON-DSR-PERDIDOS   TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF
      *
           IF PON-ATRASOS-MIN > ZEROS
               COMPUTE WS-AUX-REFER ROUNDED =
                       PON-ATRASOS-MIN / 60
               COMPUTE WS-AUX-VALOR ROUNDED =
                       WS-AUX-REFER * WS-VALOR-HORA
               MOVE CTE-EV-ATRASOS     TO WS-NOV-CODIGO
               MOVE WS-AUX-REFER       TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2300-FIM.
           EXIT.
      *
      *================================================================*
      * 2400 - APURACAO DAS BASES DE INCIDENCIA                        *
      *        PERCORRE OS EVENTOS JA CALCULADOS SOMANDO OU            *
      *        SUBTRAINDO CONFORME A NATUREZA E AS MARCAS DE           *
      *        INCIDENCIA CADASTRADAS PARA CADA RUBRICA                *
      *================================================================*
       2400-APURAR-BASES SECTION.
       2400-INICIO.
           MOVE ZEROS TO WS-TOT-PROVENTOS WS-TOT-DESCONTOS
                         WS-BASE-INSS WS-BASE-IRRF WS-BASE-FGTS
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-QTD-CALC
      *
               EVALUATE TB-CAL-NATUREZA(WS-IDX)
                   WHEN 'P'
                        ADD TB-CAL-VALOR(WS-IDX) TO WS-TOT-PROVENTOS
                        IF TB-CAL-INC-INSS(WS-IDX) = 'S'
                            ADD TB-CAL-VALOR(WS-IDX) TO WS-BASE-INSS
                        END-IF
                        IF TB-CAL-INC-IRRF(WS-IDX) = 'S'
                            ADD TB-CAL-VALOR(WS-IDX) TO WS-BASE-IRRF
                        END-IF
                        IF TB-CAL-INC-FGTS(WS-IDX) = 'S'
                            ADD TB-CAL-VALOR(WS-IDX) TO WS-BASE-FGTS
                        END-IF
      *
                   WHEN 'D'
                        ADD TB-CAL-VALOR(WS-IDX) TO WS-TOT-DESCONTOS
                        IF TB-CAL-INC-INSS(WS-IDX) = 'S'
                            SUBTRACT TB-CAL-VALOR(WS-IDX)
                                FROM WS-BASE-INSS
                        END-IF
                        IF TB-CAL-INC-IRRF(WS-IDX) = 'S'
                            SUBTRACT TB-CAL-VALOR(WS-IDX)
                                FROM WS-BASE-IRRF
                        END-IF
                        IF TB-CAL-INC-FGTS(WS-IDX) = 'S'
                            SUBTRACT TB-CAL-VALOR(WS-IDX)
                                FROM WS-BASE-FGTS
                        END-IF
               END-EVALUATE
           END-PERFORM.
       2400-FIM.
           EXIT.
      *
      *================================================================*
      * 2500 - CONTRIBUICAO PREVIDENCIARIA DO SEGURADO                 *
      *================================================================*
       2500-CALCULAR-INSS SECTION.
       2500-INICIO.
           IF WS-BASE-INSS = ZEROS
               GO TO 2500-FIM
           END-IF
      *
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CALCULA-INSS        TO TRUE
           MOVE WS-PRM-COMPETENCIA     TO TRB-COMPETENCIA
           MOVE WS-BASE-INSS           TO TRB-BASE-CALCULO
           CALL 'SFP0310' USING AREA-TRIBUTOS
      *
           IF TRB-COD-RETORNO NOT = ZEROS
               MOVE 0250               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE TRB-MSG-RETORNO    TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 08                 TO WS-COD-RETORNO
               GO TO 2500-FIM
           END-IF
      *
           MOVE TRB-VLR-CALCULADO      TO WS-VLR-INSS
           MOVE TRB-ALIQUOTA-EFETIVA   TO WS-ALIQ-INSS
      *
           MOVE CTE-EV-INSS            TO WS-NOV-CODIGO
           MOVE TRB-ALIQUOTA-EFETIVA   TO WS-NOV-REFERENCIA
           MOVE WS-VLR-INSS            TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2500-FIM.
           EXIT.
      *
      *================================================================*
      * 2550 - SALARIO FAMILIA                                         *
      *================================================================*
       2550-CALCULAR-SALARIO-FAM SECTION.
       2550-INICIO.
           IF WS-QTD-DEP-SALFAM = ZEROS
               GO TO 2550-FIM
           END-IF
      *
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CALCULA-SALFAM      TO TRUE
           MOVE WS-PRM-COMPETENCIA     TO TRB-COMPETENCIA
           MOVE WS-BASE-INSS           TO TRB-VLR-REMUN-SALFAM
           MOVE WS-QTD-DEP-SALFAM      TO TRB-QTD-FILHOS-SALFAM
           CALL 'SFP0310' USING AREA-TRIBUTOS
      *
           IF TRB-VLR-CALCULADO > ZEROS
               MOVE TRB-VLR-CALCULADO  TO WS-VLR-SALFAM
               MOVE CTE-EV-SAL-FAMILIA TO WS-NOV-CODIGO
               MOVE WS-QTD-DEP-SALFAM  TO WS-NOV-REFERENCIA
               MOVE WS-VLR-SALFAM      TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2550-FIM.
           EXIT.
      *
      *================================================================*
      * 2600 - IMPOSTO DE RENDA RETIDO NA FONTE                        *
      *================================================================*
       2600-CALCULAR-IRRF SECTION.
       2600-INICIO.
           PERFORM 2610-APURAR-PENSAO
      *
           IF WS-BASE-IRRF = ZEROS
               GO TO 2600-FIM
           END-IF
      *
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CALCULA-IRRF        TO TRUE
           MOVE WS-PRM-COMPETENCIA     TO TRB-COMPETENCIA
           MOVE WS-BASE-IRRF           TO TRB-BASE-CALCULO
           MOVE WS-QTD-DEP-IRRF        TO TRB-QTD-DEPENDENTES
           MOVE WS-VLR-INSS            TO TRB-VLR-INSS-DEDUZIR
           MOVE WS-VLR-PENSAO          TO TRB-VLR-PENSAO-DEDUZIR
           CALL 'SFP0310' USING AREA-TRIBUTOS
      *
           IF TRB-COD-RETORNO NOT = ZEROS
               MOVE 0260               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE TRB-MSG-RETORNO    TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 08                 TO WS-COD-RETORNO
               GO TO 2600-FIM
           END-IF
      *
           MOVE TRB-VLR-CALCULADO      TO WS-VLR-IRRF
           MOVE TRB-ALIQUOTA-NOMINAL   TO WS-ALIQ-IRRF
      *
           IF WS-VLR-IRRF > ZEROS
               MOVE CTE-EV-IRRF        TO WS-NOV-CODIGO
               MOVE TRB-ALIQUOTA-NOMINAL TO WS-NOV-REFERENCIA
               MOVE WS-VLR-IRRF        TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2600-FIM.
           EXIT.
      *
       2610-APURAR-PENSAO SECTION.
       2610-INICIO.
      *    A PENSAO ALIMENTICIA PODE SER FIXADA EM VALOR OU EM
      *    PERCENTUAL SOBRE A REMUNERACAO LIQUIDA PARCIAL
           MOVE ZEROS                  TO WS-VLR-PENSAO
      *
           IF EMP-VLR-PENSAO-FIXO > ZEROS
               MOVE EMP-VLR-PENSAO-FIXO TO WS-VLR-PENSAO
           ELSE
               IF EMP-PERC-PENSAO > ZEROS
                   COMPUTE WS-AUX-VALOR2 =
                           WS-TOT-PROVENTOS - WS-VLR-INSS
                   IF WS-AUX-VALOR2 < ZEROS
                       MOVE ZEROS      TO WS-AUX-VALOR2
                   END-IF
                   COMPUTE WS-VLR-PENSAO ROUNDED =
                           WS-AUX-VALOR2 * EMP-PERC-PENSAO / 100
               END-IF
           END-IF
      *
           IF WS-VLR-PENSAO > ZEROS
               MOVE CTE-EV-PENSAO-ALIM TO WS-NOV-CODIGO
               MOVE EMP-PERC-PENSAO    TO WS-NOV-REFERENCIA
               MOVE WS-VLR-PENSAO      TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2610-FIM.
           EXIT.
      *
      *================================================================*
      * 2700 - DESCONTOS DIVERSOS POSTERIORES AOS TRIBUTOS             *
      *================================================================*
       2700-DESCONTOS-DIVERSOS SECTION.
       2700-INICIO.
           PERFORM 2710-VALE-TRANSPORTE
           PERFORM 2720-VALE-REFEICAO
           PERFORM 2730-PLANO-SAUDE
           PERFORM 2740-CONSIGNADO
           PERFORM 2750-ADIANTAMENTO
           PERFORM 2760-CONTRIB-SINDICAL.
       2700-FIM.
           EXIT.
      *
       2710-VALE-TRANSPORTE SECTION.
       2710-INICIO.
      *    O DESCONTO DO VALE TRANSPORTE E LIMITADO AO MENOR VALOR
      *    ENTRE O PERCENTUAL LEGAL SOBRE O SALARIO BASE E O CUSTO
      *    EFETIVO DO BENEFICIO CONCEDIDO
           IF EMP-IND-VALE-TRANSP NOT = 'S'
               GO TO 2710-FIM
           END-IF
      *
           COMPUTE WS-AUX-VALOR ROUNDED =
                   WS-SALARIO-REFER * WS-PERC-VT / 100
      *
           IF EMP-VLR-VALE-TRANSP < WS-AUX-VALOR
               MOVE EMP-VLR-VALE-TRANSP TO WS-AUX-VALOR
           END-IF
      *
           IF WS-AUX-VALOR > ZEROS
               MOVE CTE-EV-VALE-TRANSP TO WS-NOV-CODIGO
               MOVE WS-PERC-VT         TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2710-FIM.
           EXIT.
      *
       2720-VALE-REFEICAO SECTION.
       2720-INICIO.
           IF EMP-IND-VALE-REFEIC NOT = 'S'
               GO TO 2720-FIM
           END-IF
           IF EMP-VLR-VALE-REFEIC = ZEROS
               GO TO 2720-FIM
           END-IF
      *    COPARTICIPACAO PROPORCIONAL AOS DIAS EFETIVAMENTE
      *    TRABALHADOS NA COMPETENCIA
           COMPUTE WS-AUX-VALOR ROUNDED =
                   EMP-VLR-VALE-REFEIC * WS-DIAS-PAGAR
                 / WS-DIAS-MES-COMERC
           MOVE CTE-EV-VALE-REFEIC     TO WS-NOV-CODIGO
           MOVE WS-DIAS-PAGAR          TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2720-FIM.
           EXIT.
      *
       2730-PLANO-SAUDE SECTION.
       2730-INICIO.
           IF EMP-IND-PLANO-SAUDE NOT = 'S'
               GO TO 2730-FIM
           END-IF
           COMPUTE WS-AUX-VALOR =
                   EMP-VLR-PLANO-SAUDE + WS-VLR-PLANO-DEP
           IF WS-AUX-VALOR = ZEROS
               GO TO 2730-FIM
           END-IF
           MOVE CTE-EV-PLANO-SAUDE     TO WS-NOV-CODIGO
           MOVE WS-QTD-DEP-IRRF        TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2730-FIM.
           EXIT.
      *
       2740-CONSIGNADO SECTION.
       2740-INICIO.
      *    O DESCONTO DE EMPRESTIMO CONSIGNADO OBSERVA A MARGEM
      *    MAXIMA CONSIGNAVEL SOBRE A REMUNERACAO LIQUIDA
           IF EMP-VLR-CONSIGNADO = ZEROS
               GO TO 2740-FIM
           END-IF
           IF EMP-QTD-PARC-CONSIG = ZEROS
               GO TO 2740-FIM
           END-IF
      *
           COMPUTE WS-MARGEM-DISPONIVEL ROUNDED =
                   (WS-TOT-PROVENTOS - WS-VLR-INSS - WS-VLR-IRRF)
                 * WS-MARGEM-CONSIG / 100
      *
           MOVE EMP-VLR-CONSIGNADO     TO WS-AUX-VALOR
      *
           IF WS-AUX-VALOR > WS-MARGEM-DISPONIVEL
               MOVE WS-MARGEM-DISPONIVEL TO WS-AUX-VALOR
               MOVE 0274               TO WSC-CODIGO
               MOVE 'W'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'CONSIGNADO LIMITADO A MARGEM CONSIGNAVEL LEGAL'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
           END-IF
      *
           IF WS-AUX-VALOR > ZEROS
               MOVE CTE-EV-CONSIGNADO  TO WS-NOV-CODIGO
               MOVE EMP-QTD-PARC-CONSIG TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
           END-IF.
       2740-FIM.
           EXIT.
      *
       2750-ADIANTAMENTO SECTION.
       2750-INICIO.
      *    QUITACAO DO ADIANTAMENTO QUINZENAL CONCEDIDO
           IF EMP-IND-ADIANTAMENTO NOT = 'S'
               GO TO 2750-FIM
           END-IF
           IF WS-PRM-TIPO-FOLHA NOT = '1'
               GO TO 2750-FIM
           END-IF
      *
           IF EMP-PERC-ADIANTAMENTO > ZEROS
               COMPUTE WS-AUX-VALOR ROUNDED =
                       WS-SALARIO-REFER * EMP-PERC-ADIANTAMENTO / 100
           ELSE
               COMPUTE WS-AUX-VALOR ROUNDED =
                       WS-SALARIO-REFER * WS-PERC-ADIANT / 100
           END-IF
      *
           MOVE CTE-EV-ADIANTAMENTO    TO WS-NOV-CODIGO
           MOVE EMP-PERC-ADIANTAMENTO  TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2750-FIM.
           EXIT.
      *
       2760-CONTRIB-SINDICAL SECTION.
       2760-INICIO.
           IF EMP-IND-SINDICALIZADO NOT = 'S'
               GO TO 2760-FIM
           END-IF
           IF WS-VLR-CONTR-SINDIC = ZEROS
               GO TO 2760-FIM
           END-IF
           COMPUTE WS-AUX-VALOR ROUNDED =
                   WS-SALARIO-REFER * WS-VLR-CONTR-SINDIC / 100
           MOVE CTE-EV-CONTR-SINDIC    TO WS-NOV-CODIGO
           MOVE WS-VLR-CONTR-SINDIC    TO WS-NOV-REFERENCIA
           MOVE WS-AUX-VALOR           TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2760-FIM.
           EXIT.
      *
      *================================================================*
      * 2800 - FGTS (ENCARGO DO EMPREGADOR - EVENTO INFORMATIVO)       *
      *================================================================*
       2800-CALCULAR-FGTS SECTION.
       2800-INICIO.
           IF WS-BASE-FGTS = ZEROS
               GO TO 2800-FIM
           END-IF
      *
           INITIALIZE AREA-TRIBUTOS
           SET TRB-CALCULA-FGTS        TO TRUE
           MOVE WS-PRM-COMPETENCIA     TO TRB-COMPETENCIA
           MOVE WS-BASE-FGTS           TO TRB-BASE-CALCULO
           CALL 'SFP0310' USING AREA-TRIBUTOS
      *
           MOVE TRB-VLR-CALCULADO      TO WS-VLR-FGTS
           MOVE CTE-EV-FGTS-MES        TO WS-NOV-CODIGO
           MOVE TRB-ALIQUOTA-NOMINAL   TO WS-NOV-REFERENCIA
           MOVE WS-VLR-FGTS            TO WS-NOV-VALOR
           PERFORM 8500-INCLUIR-EVENTO.
       2800-FIM.
           EXIT.
      *
      *================================================================*
      * 2850 - APURACAO DO LIQUIDO E CRITICA DE SALDO DEVEDOR          *
      *================================================================*
       2850-APURAR-LIQUIDO SECTION.
       2850-INICIO.
           PERFORM 2400-APURAR-BASES
           COMPUTE WS-LIQUIDO = WS-TOT-PROVENTOS - WS-TOT-DESCONTOS
      *
           IF WS-LIQUIDO < ZEROS
               MOVE 0285               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'LIQUIDO NEGATIVO - GERADO SALDO DEVEDOR'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
      *
               COMPUTE WS-AUX-VALOR = WS-LIQUIDO * -1
               MOVE CTE-EV-SALDO-DEVEDOR TO WS-NOV-CODIGO
               MOVE ZEROS              TO WS-NOV-REFERENCIA
               MOVE WS-AUX-VALOR       TO WS-NOV-VALOR
               PERFORM 8500-INCLUIR-EVENTO
               PERFORM 2400-APURAR-BASES
               COMPUTE WS-LIQUIDO =
                       WS-TOT-PROVENTOS - WS-TOT-DESCONTOS
           END-IF
      *
           ADD WS-TOT-PROVENTOS        TO WS-TOT-GER-PROVENTOS
           ADD WS-TOT-DESCONTOS        TO WS-TOT-GER-DESCONTOS
           ADD WS-LIQUIDO              TO WS-TOT-GER-LIQUIDO
           ADD WS-VLR-INSS             TO WS-TOT-GER-INSS
           ADD WS-VLR-IRRF             TO WS-TOT-GER-IRRF
           ADD WS-VLR-FGTS             TO WS-TOT-GER-FGTS.
       2850-FIM.
           EXIT.
      *
      *================================================================*
      * 2900 - GRAVACAO DOS RESULTADOS                                 *
      *================================================================*
       2900-GRAVAR-RESULTADOS SECTION.
       2900-INICIO.
           IF WS-PRM-SIMULACAO = 'S'
               GO TO 2900-FIM
           END-IF
      *
           PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-QTD-CALC
               INITIALIZE REG-FOLHA
               MOVE WS-PRM-COMPETENCIA TO FOL-COMPETENCIA
               MOVE WS-PRM-TIPO-FOLHA  TO FOL-TIPO-FOLHA
               MOVE EMP-MATRICULA      TO FOL-MATRICULA
               MOVE WS-IDX             TO FOL-SEQUENCIA
               MOVE TB-CAL-CODIGO(WS-IDX)     TO FOL-COD-EVENTO
               MOVE TB-CAL-DESCRICAO(WS-IDX)  TO FOL-DESCRICAO
               MOVE TB-CAL-NATUREZA(WS-IDX)   TO FOL-NATUREZA
               MOVE TB-CAL-REFERENCIA(WS-IDX) TO FOL-REFERENCIA
               MOVE TB-CAL-VALOR(WS-IDX)      TO FOL-VALOR
               MOVE EMP-CENTRO-CUSTO   TO FOL-CENTRO-CUSTO
               MOVE TB-CAL-CONTA(WS-IDX)      TO FOL-CONTA-CONTABIL
               MOVE SPACES             TO FOL-FILLER
               WRITE REG-FOLHA
               ADD 1                   TO WS-GRAV-FOL
           END-PERFORM
      *
           INITIALIZE REG-RESUMO
           MOVE WS-PRM-COMPETENCIA     TO RES-COMPETENCIA
           MOVE WS-PRM-TIPO-FOLHA      TO RES-TIPO-FOLHA
           MOVE EMP-MATRICULA          TO RES-MATRICULA
           MOVE EMP-NOME               TO RES-NOME
           MOVE EMP-CENTRO-CUSTO       TO RES-CENTRO-CUSTO
           MOVE EMP-SALARIO-BASE       TO RES-SALARIO-BASE
           MOVE WS-TOT-PROVENTOS       TO RES-TOT-PROVENTOS
           MOVE WS-TOT-DESCONTOS       TO RES-TOT-DESCONTOS
           MOVE WS-LIQUIDO             TO RES-LIQUIDO
           MOVE WS-BASE-INSS           TO RES-BASE-INSS
           MOVE WS-BASE-IRRF           TO RES-BASE-IRRF
           MOVE WS-BASE-FGTS           TO RES-BASE-FGTS
           MOVE WS-VLR-INSS            TO RES-VLR-INSS
           MOVE WS-VLR-IRRF            TO RES-VLR-IRRF
           MOVE WS-VLR-FGTS            TO RES-VLR-FGTS
           MOVE WS-VLR-SALFAM          TO RES-VLR-SAL-FAMILIA
           MOVE WS-ALIQ-INSS           TO RES-ALIQ-INSS-EFET
           MOVE WS-ALIQ-IRRF           TO RES-ALIQ-IRRF
           MOVE WS-QTD-CALC            TO RES-QTD-EVENTOS
           MOVE EMP-BANCO              TO RES-BANCO
           MOVE EMP-AGENCIA            TO RES-AGENCIA
           MOVE EMP-CONTA              TO RES-CONTA
           MOVE EMP-DIG-CONTA          TO RES-DIG-CONTA
           MOVE EMP-CPF                TO RES-CPF
           MOVE SPACES                 TO RES-FILLER
           WRITE REG-RESUMO
           ADD 1                       TO WS-GRAV-RES.
       2900-FIM.
           EXIT.
      *
      *================================================================*
      * 8000 - ROTINAS DE SERVICO                                      *
      *================================================================*
       8100-LER-EMPREGADO SECTION.
       8100-INICIO.
           READ ARQ-EMPREGADO
               AT END
                   MOVE 'S'            TO WS-FIM-EMP
                   MOVE HIGH-VALUES    TO EMP-NOME
                   MOVE 99999999       TO EMP-MATRICULA
               NOT AT END
                   ADD 1               TO WS-LIDOS-EMP
           END-READ.
       8100-FIM.
           EXIT.
      *
       8200-LER-PONTO SECTION.
       8200-INICIO.
           READ ARQ-PONTO
               AT END
                   MOVE 'S'            TO WS-FIM-PON
                   MOVE 99999999       TO PONE-MATRICULA
               NOT AT END
                   ADD 1               TO WS-LIDOS-PON
           END-READ.
       8200-FIM.
           EXIT.
      *
       8300-LER-DEPENDENTE SECTION.
       8300-INICIO.
           READ ARQ-DEPEND
               AT END
                   MOVE 'S'            TO WS-FIM-DEP
                   MOVE 99999999       TO DEP-MATRICULA
               NOT AT END
                   ADD 1               TO WS-LIDOS-DEP
           END-READ.
       8300-FIM.
           EXIT.
      *
       8400-LER-MOVIMENTO SECTION.
       8400-INICIO.
           READ ARQ-MOVIMENTO
               AT END
                   MOVE 'S'            TO WS-FIM-MOV
                   MOVE 99999999       TO MOV-MATRICULA
               NOT AT END
                   ADD 1               TO WS-LIDOS-MOV
           END-READ.
       8400-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 8500 - INCLUSAO DE UM EVENTO NA TABELA DE CALCULO              *
      *        LOCALIZA A RUBRICA NO CADASTRO PARA HERDAR DESCRICAO,   *
      *        NATUREZA, INCIDENCIAS E CONTA CONTABIL                  *
      *----------------------------------------------------------------*
       8500-INCLUIR-EVENTO SECTION.
       8500-INICIO.
           IF WS-NOV-VALOR = ZEROS
               GO TO 8500-FIM
           END-IF
      *
           IF WS-QTD-CALC >= 150
               MOVE 0850               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE 'LIMITE DE EVENTOS POR EMPREGADO EXCEDIDO'
                                       TO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 08                 TO WS-COD-RETORNO
               GO TO 8500-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-ACHOU-EVENTO
           SET IX-EVE                  TO 1
           SEARCH ALL TB-EVENTO
               AT END
                   CONTINUE
               WHEN TB-EVE-CODIGO(IX-EVE) = WS-NOV-CODIGO
                   MOVE 'S'            TO WS-ACHOU-EVENTO
           END-SEARCH
      *
           ADD 1                       TO WS-QTD-CALC
           MOVE WS-NOV-CODIGO          TO TB-CAL-CODIGO(WS-QTD-CALC)
           MOVE WS-NOV-REFERENCIA  TO TB-CAL-REFERENCIA(WS-QTD-CALC)
           MOVE WS-NOV-VALOR           TO TB-CAL-VALOR(WS-QTD-CALC)
      *
           IF WS-ACHOU-EVENTO = 'S'
               MOVE TB-EVE-DESCRICAO(IX-EVE)
                                   TO TB-CAL-DESCRICAO(WS-QTD-CALC)
               MOVE TB-EVE-NATUREZA(IX-EVE)
                                   TO TB-CAL-NATUREZA(WS-QTD-CALC)
               MOVE TB-EVE-CONTA(IX-EVE)
                                   TO TB-CAL-CONTA(WS-QTD-CALC)
               MOVE TB-EVE-INC-INSS(IX-EVE)
                                   TO TB-CAL-INC-INSS(WS-QTD-CALC)
               MOVE TB-EVE-INC-IRRF(IX-EVE)
                                   TO TB-CAL-INC-IRRF(WS-QTD-CALC)
               MOVE TB-EVE-INC-FGTS(IX-EVE)
                                   TO TB-CAL-INC-FGTS(WS-QTD-CALC)
           ELSE
               MOVE 'EVENTO NAO CADASTRADO'
                                   TO TB-CAL-DESCRICAO(WS-QTD-CALC)
               MOVE 'I'            TO TB-CAL-NATUREZA(WS-QTD-CALC)
               MOVE ZEROS          TO TB-CAL-CONTA(WS-QTD-CALC)
               MOVE 'N'            TO TB-CAL-INC-INSS(WS-QTD-CALC)
                                      TB-CAL-INC-IRRF(WS-QTD-CALC)
                                      TB-CAL-INC-FGTS(WS-QTD-CALC)
               MOVE 0851               TO WSC-CODIGO
               MOVE 'E'                TO WSC-SEVERIDADE
               MOVE EMP-MATRICULA      TO WSC-MATRICULA
               MOVE SPACES             TO WSC-MENSAGEM
               STRING 'RUBRICA ' WS-NOV-CODIGO
                      ' AUSENTE NO CADASTRO DE EVENTOS'
                   DELIMITED BY SIZE INTO WSC-MENSAGEM
               PERFORM 8900-GRAVAR-CRITICA
               MOVE 04                 TO WS-COD-RETORNO
           END-IF.
       8500-FIM.
           EXIT.
      *
       8900-GRAVAR-CRITICA SECTION.
       8900-INICIO.
           MOVE WS-LINHA-CRITICA       TO REG-CRITICA
           WRITE REG-CRITICA
           ADD 1                       TO WS-QTD-CRITICAS.
       8900-FIM.
           EXIT.
      *
      *================================================================*
      * 9000 - ENCERRAMENTO E ESTATISTICAS DE PROCESSAMENTO            *
      *================================================================*
       9000-FINALIZAR SECTION.
       9000-INICIO.
           MOVE ALL '-'                TO REG-CRITICA
           WRITE REG-CRITICA
           MOVE SPACES                 TO REG-CRITICA
           STRING 'TOTAL DE OCORRENCIAS REGISTRADAS: ' WS-QTD-CRITICAS
               DELIMITED BY SIZE INTO REG-CRITICA
           WRITE REG-CRITICA
      *
           CLOSE ARQ-EMPREGADO ARQ-PONTO ARQ-DEPEND
                 ARQ-MOVIMENTO ARQ-EVENTO ARQ-SYSIN
                 ARQ-FOLHA ARQ-RESUMO ARQ-CRITICA
      *
           DISPLAY ' '
           DISPLAY '=================================================='
           DISPLAY ' SFP0300 - ESTATISTICAS DE PROCESSAMENTO'
           DISPLAY '=================================================='
           DISPLAY ' EMPREGADOS LIDOS .......: ' WS-LIDOS-EMP
           DISPLAY ' EMPREGADOS CALCULADOS ..: ' WS-CALCULADOS
           DISPLAY ' EMPREGADOS REJEITADOS ..: ' WS-REJEITADOS
           DISPLAY ' MOVIMENTOS LIDOS .......: ' WS-LIDOS-MOV
           DISPLAY ' REGISTROS DE PONTO .....: ' WS-LIDOS-PON
           DISPLAY ' DEPENDENTES LIDOS ......: ' WS-LIDOS-DEP
           DISPLAY ' EVENTOS GRAVADOS .......: ' WS-GRAV-FOL
           DISPLAY ' RESUMOS GRAVADOS .......: ' WS-GRAV-RES
           DISPLAY ' CRITICAS EMITIDAS ......: ' WS-QTD-CRITICAS
           DISPLAY '--------------------------------------------------'
           MOVE 'TOTAL DE PROVENTOS'    TO WST-DESCRICAO
           MOVE WS-TOT-GER-PROVENTOS    TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           MOVE 'TOTAL DE DESCONTOS'    TO WST-DESCRICAO
           MOVE WS-TOT-GER-DESCONTOS    TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           MOVE 'LIQUIDO A PAGAR'       TO WST-DESCRICAO
           MOVE WS-TOT-GER-LIQUIDO      TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           MOVE 'INSS RETIDO'           TO WST-DESCRICAO
           MOVE WS-TOT-GER-INSS         TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           MOVE 'IRRF RETIDO'           TO WST-DESCRICAO
           MOVE WS-TOT-GER-IRRF         TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           MOVE 'FGTS DEPOSITADO'       TO WST-DESCRICAO
           MOVE WS-TOT-GER-FGTS         TO WST-VALOR
           DISPLAY WS-LINHA-TOTAL(31:62)
           DISPLAY '=================================================='
           DISPLAY ' RETURN CODE: ' WS-COD-RETORNO
           DISPLAY '=================================================='.
       9000-FIM.
           EXIT.
