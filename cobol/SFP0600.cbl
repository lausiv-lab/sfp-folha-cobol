      *================================================================*
      * PROGRAMA : SFP0600                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : GERACAO DO ARQUIVO DE PAGAMENTO ELETRONICO NO       *
      *            PADRAO FEBRABAN CNAB 240 - SERVICO 30 (PAGAMENTO    *
      *            DE SALARIOS) / FORMA 01 (CREDITO EM CONTA CORRENTE) *
      *                                                                *
      *            ESTRUTURA GERADA:                                   *
      *              REG 0 - HEADER DE ARQUIVO                         *
      *              REG 1 - HEADER DE LOTE                            *
      *              REG 3 - SEGMENTO A (CREDITO EM CONTA)             *
      *              REG 5 - TRAILER DE LOTE  (TOTALIZACAO)            *
      *              REG 9 - TRAILER DE ARQUIVO                        *
      *                                                                *
      *            EMPREGADOS COM LIQUIDO NULO OU NEGATIVO SAO         *
      *            EXCLUIDOS DA REMESSA E RELACIONADOS NO LOG.         *
      * ENTRADA  : SFPRES                                              *
      * SAIDA    : SFPCNAB (240 BYTES)                                 *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0600.
       AUTHOR. EQUIPE-SFP.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-RESUMO ASSIGN TO SFPRES
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-RES.
           SELECT ARQ-CNAB   ASSIGN TO SFPCNAB
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-CNA.
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-RESUMO RECORD CONTAINS 250 CHARACTERS.
       COPY SFPWRES.
       FD  ARQ-CNAB   RECORD CONTAINS 240 CHARACTERS.
       01  REG-CNAB                    PIC X(240).
      *
       WORKING-STORAGE SECTION.
       77  WS-FS-RES                   PIC X(002) VALUE '00'.
       77  WS-FS-CNA                   PIC X(002) VALUE '00'.
       77  WS-FIM-RES                  PIC X(001) VALUE 'N'.
       77  WS-SEQ-LOTE                 PIC 9(005) VALUE ZEROS.
       77  WS-QTD-REG-ARQ              PIC 9(006) VALUE ZEROS.
       77  WS-QTD-CREDITOS             PIC 9(006) VALUE ZEROS.
       77  WS-EXCLUIDOS                PIC 9(006) VALUE ZEROS.
       77  WS-SOMA-VALORES             PIC 9(016)V99 VALUE ZEROS.
       77  WS-DATA-SIS                 PIC 9(008) VALUE ZEROS.
       77  WS-HORA-SIS                 PIC 9(008) VALUE ZEROS.
       77  WS-DATA-PGTO                PIC 9(008) VALUE ZEROS.
       77  WS-NSA                      PIC 9(006) VALUE 000417.
      *
       01  WS-DT-AAAAMMDD.
           05  WS-DT-ANO               PIC X(004).
           05  WS-DT-MES               PIC X(002).
           05  WS-DT-DIA               PIC X(002).
       01  WS-DT-DDMMAAAA.
           05  WS-DD-DIA               PIC X(002).
           05  WS-DD-MES               PIC X(002).
           05  WS-DD-ANO               PIC X(004).
       01  WS-HR-AUX.
           05  WS-HR-HHMMSS            PIC X(006).
           05  FILLER                  PIC X(002).
      *
      *--- DADOS DA EMPRESA PAGADORA ----------------------------------
       01  WS-EMPRESA.
           05  WS-EMP-BANCO            PIC 9(003) VALUE 341.
           05  WS-EMP-CNPJ             PIC 9(014)
                                       VALUE 74829163000178.
           05  WS-EMP-CONVENIO         PIC X(020)
                                       VALUE '0004178300000000000 '.
           05  WS-EMP-AGENCIA          PIC 9(005) VALUE 04178.
           05  WS-EMP-DV-AG            PIC X(001) VALUE '3'.
           05  WS-EMP-CONTA            PIC 9(012) VALUE 000000091475.
           05  WS-EMP-DV-CT            PIC X(001) VALUE '2'.
           05  WS-EMP-DV-AGCT          PIC X(001) VALUE '9'.
           05  WS-EMP-NOME             PIC X(030) VALUE
               'INDUSTRIA MERIDIONAL COMPON SA'.
           05  WS-EMP-NOME-BCO         PIC X(030) VALUE
               'BANCO ITAU UNIBANCO S/A'.
      *
      *--- REGISTRO TIPO 0 - HEADER DE ARQUIVO ------------------------
       01  R000-HEADER-ARQUIVO.
           05  R000-BANCO              PIC 9(003).
           05  R000-LOTE               PIC 9(004) VALUE 0000.
           05  R000-TIPO-REGISTRO      PIC 9(001) VALUE 0.
           05  FILLER                  PIC X(009) VALUE SPACES.
           05  R000-TIPO-INSCRICAO     PIC 9(001) VALUE 2.
           05  R000-CNPJ               PIC 9(014).
           05  R000-CONVENIO           PIC X(020).
           05  R000-AGENCIA            PIC 9(005).
           05  R000-DV-AGENCIA         PIC X(001).
           05  R000-CONTA              PIC 9(012).
           05  R000-DV-CONTA           PIC X(001).
           05  R000-DV-AG-CONTA        PIC X(001).
           05  R000-NOME-EMPRESA       PIC X(030).
           05  R000-NOME-BANCO         PIC X(030).
           05  FILLER                  PIC X(010) VALUE SPACES.
           05  R000-COD-REMESSA        PIC 9(001) VALUE 1.
           05  R000-DATA-GERACAO       PIC 9(008).
           05  R000-HORA-GERACAO       PIC 9(006).
           05  R000-NSA                PIC 9(006).
           05  R000-VERSAO-LAYOUT      PIC 9(003) VALUE 103.
           05  R000-DENSIDADE          PIC 9(005) VALUE 01600.
           05  FILLER                  PIC X(020) VALUE SPACES.
           05  FILLER                  PIC X(020) VALUE SPACES.
           05  FILLER                  PIC X(029) VALUE SPACES.
      *
      *--- REGISTRO TIPO 1 - HEADER DE LOTE ---------------------------
       01  R001-HEADER-LOTE.
           05  R001-BANCO              PIC 9(003).
           05  R001-LOTE               PIC 9(004) VALUE 0001.
           05  R001-TIPO-REGISTRO      PIC 9(001) VALUE 1.
           05  R001-OPERACAO           PIC X(001) VALUE 'C'.
           05  R001-SERVICO            PIC 9(002) VALUE 30.
           05  R001-FORMA-LANCAMENTO   PIC 9(002) VALUE 01.
           05  R001-VERSAO-LOTE        PIC 9(003) VALUE 046.
           05  FILLER                  PIC X(001) VALUE SPACES.
           05  R001-TIPO-INSCRICAO     PIC 9(001) VALUE 2.
           05  R001-CNPJ               PIC 9(014).
           05  R001-CONVENIO           PIC X(020).
           05  R001-AGENCIA            PIC 9(005).
           05  R001-DV-AGENCIA         PIC X(001).
           05  R001-CONTA              PIC 9(012).
           05  R001-DV-CONTA           PIC X(001).
           05  R001-DV-AG-CONTA        PIC X(001).
           05  R001-NOME-EMPRESA       PIC X(030).
           05  R001-FINALIDADE         PIC X(040) VALUE
               'FOLHA DE PAGAMENTO MENSAL'.
           05  R001-HIST-CC            PIC X(030) VALUE SPACES.
           05  R001-ENDERECO           PIC X(030) VALUE
               'AV DAS INDUSTRIAS 1450'.
           05  R001-NUMERO             PIC 9(005) VALUE 01450.
           05  R001-COMPLEMENTO        PIC X(015) VALUE 'BLOCO C'.
           05  R001-CIDADE             PIC X(020) VALUE 'JOINVILLE'.
           05  R001-CEP                PIC 9(008) VALUE 89230000.
           05  R001-ESTADO             PIC X(002) VALUE 'SC'.
           05  FILLER                  PIC X(008) VALUE SPACES.
      *
      *--- REGISTRO TIPO 3 - SEGMENTO A -------------------------------
       01  R003-SEGMENTO-A.
           05  R003-BANCO              PIC 9(003).
           05  R003-LOTE               PIC 9(004) VALUE 0001.
           05  R003-TIPO-REGISTRO      PIC 9(001) VALUE 3.
           05  R003-NR-REGISTRO        PIC 9(005).
           05  R003-SEGMENTO           PIC X(001) VALUE 'A'.
           05  R003-TIPO-MOVIMENTO     PIC 9(001) VALUE 0.
           05  R003-COD-INSTRUCAO      PIC 9(002) VALUE 00.
           05  R003-CAMARA             PIC 9(003) VALUE 000.
           05  R003-BANCO-FAVOR        PIC 9(003).
           05  R003-AGENCIA-FAVOR      PIC 9(005).
           05  R003-DV-AG-FAVOR        PIC X(001) VALUE SPACES.
           05  R003-CONTA-FAVOR        PIC 9(012).
           05  R003-DV-CT-FAVOR        PIC X(001).
           05  R003-DV-AGCT-FAVOR      PIC X(001) VALUE SPACES.
           05  R003-NOME-FAVORECIDO    PIC X(030).
           05  R003-SEU-NUMERO         PIC X(020).
           05  R003-DATA-PAGAMENTO     PIC 9(008).
           05  R003-MOEDA              PIC X(003) VALUE 'BRL'.
           05  R003-QTD-MOEDA          PIC 9(010)V99999 VALUE ZEROS.
           05  R003-VALOR-PAGAMENTO    PIC 9(013)V99.
           05  R003-NOSSO-NUMERO       PIC X(020) VALUE SPACES.
           05  R003-DATA-EFETIVA       PIC 9(008) VALUE ZEROS.
           05  R003-VALOR-EFETIVO      PIC 9(013)V99 VALUE ZEROS.
           05  R003-OUTRAS-INFORM      PIC X(018) VALUE SPACES.
           05  R003-TIPO-CTA-FAVOR     PIC X(002) VALUE '01'.
           05  R003-IDENT-CONTRATO     PIC X(004) VALUE SPACES.
           05  R003-TIPO-INSC-FAVOR    PIC 9(001) VALUE 1.
           05  R003-CPF-FAVORECIDO     PIC 9(014).
           05  R003-COD-DOC-FAVOR      PIC X(006) VALUE SPACES.
           05  R003-AVISO              PIC 9(001) VALUE 0.
           05  R003-OCORRENCIAS        PIC X(010) VALUE SPACES.
      *
      *--- REGISTRO TIPO 5 - TRAILER DE LOTE --------------------------
       01  R005-TRAILER-LOTE.
           05  R005-BANCO              PIC 9(003).
           05  R005-LOTE               PIC 9(004) VALUE 0001.
           05  R005-TIPO-REGISTRO      PIC 9(001) VALUE 5.
           05  FILLER                  PIC X(009) VALUE SPACES.
           05  R005-QTD-REGISTROS      PIC 9(006).
           05  R005-SOMA-VALORES       PIC 9(016)V99.
           05  R005-SOMA-QTD-MOEDA     PIC 9(013)V99999 VALUE ZEROS.
           05  R005-NR-AVISO           PIC 9(006) VALUE ZEROS.
           05  FILLER                  PIC X(165) VALUE SPACES.
           05  R005-OCORRENCIAS        PIC X(010) VALUE SPACES.
      *
      *--- REGISTRO TIPO 9 - TRAILER DE ARQUIVO -----------------------
       01  R009-TRAILER-ARQUIVO.
           05  R009-BANCO              PIC 9(003).
           05  R009-LOTE               PIC 9(004) VALUE 9999.
           05  R009-TIPO-REGISTRO      PIC 9(001) VALUE 9.
           05  FILLER                  PIC X(009) VALUE SPACES.
           05  R009-QTD-LOTES          PIC 9(006) VALUE 000001.
           05  R009-QTD-REGISTROS      PIC 9(006).
           05  R009-QTD-CONTAS         PIC 9(006) VALUE ZEROS.
           05  FILLER                  PIC X(205) VALUE SPACES.
      *
       PROCEDURE DIVISION.
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR UNTIL WS-FIM-RES = 'S'
           PERFORM 3000-GERAR-TRAILERS
           PERFORM 9000-FINALIZAR
           STOP RUN.
      *
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           ACCEPT WS-DATA-SIS FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SIS FROM TIME
           MOVE WS-DATA-SIS            TO WS-DT-AAAAMMDD
           MOVE WS-DT-DIA              TO WS-DD-DIA
           MOVE WS-DT-MES              TO WS-DD-MES
           MOVE WS-DT-ANO              TO WS-DD-ANO
           MOVE WS-HORA-SIS            TO WS-HR-AUX
      *
           OPEN INPUT ARQ-RESUMO
           OPEN OUTPUT ARQ-CNAB
           IF WS-FS-RES NOT = '00'
               DISPLAY 'SFP0600 - ERRO ABERTURA SFPRES: ' WS-FS-RES
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           PERFORM 8100-LER-RESUMO
           IF WS-FIM-RES = 'S'
               DISPLAY 'SFP0600 - ARQUIVO DE RESUMO VAZIO'
               MOVE 04                 TO RETURN-CODE
           END-IF
      *
      *    A DATA DE CREDITO E O QUINTO DIA UTIL SIMPLIFICADO PARA
      *    O DIA 05 DO MES SEGUINTE A COMPETENCIA PROCESSADA
           COMPUTE WS-DATA-PGTO =
                   (RES-COMPETENCIA * 100) + 5
      *
           PERFORM 1100-GERAR-HEADER-ARQUIVO
           PERFORM 1200-GERAR-HEADER-LOTE.
       1000-FIM.
           EXIT.
      *
       1100-GERAR-HEADER-ARQUIVO SECTION.
       1100-INICIO.
           MOVE WS-EMP-BANCO           TO R000-BANCO
           MOVE WS-EMP-CNPJ            TO R000-CNPJ
           MOVE WS-EMP-CONVENIO        TO R000-CONVENIO
           MOVE WS-EMP-AGENCIA         TO R000-AGENCIA
           MOVE WS-EMP-DV-AG           TO R000-DV-AGENCIA
           MOVE WS-EMP-CONTA           TO R000-CONTA
           MOVE WS-EMP-DV-CT           TO R000-DV-CONTA
           MOVE WS-EMP-DV-AGCT         TO R000-DV-AG-CONTA
           MOVE WS-EMP-NOME            TO R000-NOME-EMPRESA
           MOVE WS-EMP-NOME-BCO        TO R000-NOME-BANCO
           MOVE WS-DT-DDMMAAAA         TO R000-DATA-GERACAO
           MOVE WS-HR-HHMMSS           TO R000-HORA-GERACAO
           MOVE WS-NSA                 TO R000-NSA
           MOVE R000-HEADER-ARQUIVO    TO REG-CNAB
           WRITE REG-CNAB
           ADD 1                       TO WS-QTD-REG-ARQ.
       1100-FIM.
           EXIT.
      *
       1200-GERAR-HEADER-LOTE SECTION.
       1200-INICIO.
           MOVE WS-EMP-BANCO           TO R001-BANCO
           MOVE WS-EMP-CNPJ            TO R001-CNPJ
           MOVE WS-EMP-CONVENIO        TO R001-CONVENIO
           MOVE WS-EMP-AGENCIA         TO R001-AGENCIA
           MOVE WS-EMP-DV-AG           TO R001-DV-AGENCIA
           MOVE WS-EMP-CONTA           TO R001-CONTA
           MOVE WS-EMP-DV-CT           TO R001-DV-CONTA
           MOVE WS-EMP-DV-AGCT         TO R001-DV-AG-CONTA
           MOVE WS-EMP-NOME            TO R001-NOME-EMPRESA
           MOVE R001-HEADER-LOTE       TO REG-CNAB
           WRITE REG-CNAB
           ADD 1                       TO WS-QTD-REG-ARQ
           ADD 1                       TO WS-SEQ-LOTE.
       1200-FIM.
           EXIT.
      *
       2000-PROCESSAR SECTION.
       2000-INICIO.
           IF RES-LIQUIDO <= ZEROS
               ADD 1                   TO WS-EXCLUIDOS
               DISPLAY 'SFP0600 - EXCLUIDO DA REMESSA - MATRICULA '
                       RES-MATRICULA ' LIQUIDO NAO POSITIVO'
               GO TO 2000-LER
           END-IF
      *
           ADD 1                       TO WS-SEQ-LOTE
           MOVE WS-EMP-BANCO           TO R003-BANCO
           MOVE WS-SEQ-LOTE            TO R003-NR-REGISTRO
           MOVE RES-BANCO              TO R003-BANCO-FAVOR
           MOVE RES-AGENCIA            TO R003-AGENCIA-FAVOR
           MOVE RES-CONTA              TO R003-CONTA-FAVOR
           MOVE RES-DIG-CONTA          TO R003-DV-CT-FAVOR
           MOVE RES-NOME               TO R003-NOME-FAVORECIDO
           MOVE SPACES                 TO R003-SEU-NUMERO
           STRING 'FOLHA' RES-COMPETENCIA RES-MATRICULA
               DELIMITED BY SIZE INTO R003-SEU-NUMERO
           MOVE WS-DATA-PGTO           TO R003-DATA-PAGAMENTO
           MOVE RES-LIQUIDO            TO R003-VALOR-PAGAMENTO
           MOVE RES-CPF                TO R003-CPF-FAVORECIDO
           MOVE R003-SEGMENTO-A        TO REG-CNAB
           WRITE REG-CNAB
      *
           ADD 1                       TO WS-QTD-REG-ARQ
           ADD 1                       TO WS-QTD-CREDITOS
           ADD RES-LIQUIDO             TO WS-SOMA-VALORES.
       2000-LER.
           PERFORM 8100-LER-RESUMO.
       2000-FIM.
           EXIT.
      *
       3000-GERAR-TRAILERS SECTION.
       3000-INICIO.
           MOVE WS-EMP-BANCO           TO R005-BANCO
           COMPUTE R005-QTD-REGISTROS = WS-QTD-CREDITOS + 2
           MOVE WS-SOMA-VALORES        TO R005-SOMA-VALORES
           MOVE R005-TRAILER-LOTE      TO REG-CNAB
           WRITE REG-CNAB
           ADD 1                       TO WS-QTD-REG-ARQ
      *
           MOVE WS-EMP-BANCO           TO R009-BANCO
           ADD 1                       TO WS-QTD-REG-ARQ
           MOVE WS-QTD-REG-ARQ         TO R009-QTD-REGISTROS
           MOVE R009-TRAILER-ARQUIVO   TO REG-CNAB
           WRITE REG-CNAB.
       3000-FIM.
           EXIT.
      *
       8100-LER-RESUMO SECTION.
       8100-INICIO.
           READ ARQ-RESUMO
               AT END
                   MOVE 'S'            TO WS-FIM-RES
           END-READ.
       8100-FIM.
           EXIT.
      *
       9000-FINALIZAR SECTION.
       9000-INICIO.
           CLOSE ARQ-RESUMO ARQ-CNAB
           DISPLAY '=================================================='
           DISPLAY ' SFP0600 - REMESSA BANCARIA CNAB240 GERADA'
           DISPLAY '=================================================='
           DISPLAY ' CREDITOS GERADOS .......: ' WS-QTD-CREDITOS
           DISPLAY ' EXCLUIDOS DA REMESSA ...: ' WS-EXCLUIDOS
           DISPLAY ' REGISTROS NO ARQUIVO ...: ' WS-QTD-REG-ARQ
           DISPLAY ' VALOR TOTAL DA REMESSA .: ' WS-SOMA-VALORES
           DISPLAY ' DATA DE CREDITO ........: ' WS-DATA-PGTO
           DISPLAY '=================================================='.
       9000-FIM.
           EXIT.
