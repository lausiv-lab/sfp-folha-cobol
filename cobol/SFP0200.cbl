      *================================================================*
      * PROGRAMA : SFP0200                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : CRITICA E VALIDACAO DO MOVIMENTO MENSAL             *
      *            EXECUTADO ANTES DO MOTOR DE CALCULO, SEPARA O       *
      *            MOVIMENTO EM ACEITO E REJEITADO, APLICANDO:         *
      *              - EXISTENCIA E SITUACAO DO EMPREGADO              *
      *              - EXISTENCIA E SITUACAO DA RUBRICA                *
      *              - ADERENCIA DA COMPETENCIA INFORMADA              *
      *              - COERENCIA ENTRE UNIDADE DA RUBRICA E OS         *
      *                CAMPOS REFERENCIA / VALOR PREENCHIDOS           *
      *              - DUPLICIDADE DE LANCAMENTO (MATRICULA+EVENTO)    *
      *              - TETO DE VALOR POR LANCAMENTO                    *
      * ENTRADA  : SFPMOV SFPEMP SFPEVE SYSIN                          *
      * SAIDA    : SFPMOVA (ACEITOS) SFPMOVR (REJEITADOS) SFPLOG       *
      * RETORNO  : 00 SEM REJEICOES / 04 COM REJEICOES / 08 ERRO       *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0200.
       AUTHOR. EQUIPE-SFP.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-MOVIMENTO ASSIGN TO SFPMOV
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-MOV.
           SELECT ARQ-EMPREGADO ASSIGN TO SFPEMP
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-EMP.
           SELECT ARQ-EVENTO    ASSIGN TO SFPEVE
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-EVE.
           SELECT ARQ-SYSIN     ASSIGN TO SYSIN
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-SYS.
           SELECT ARQ-ACEITOS   ASSIGN TO SFPMOVA
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-ACE.
           SELECT ARQ-REJEITAD  ASSIGN TO SFPMOVR
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-REJ.
           SELECT ARQ-LOG       ASSIGN TO SFPLOG
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS IS WS-FS-LOG.
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-MOVIMENTO RECORD CONTAINS 100 CHARACTERS.
       COPY SFPWMOV.
       FD  ARQ-EMPREGADO RECORD CONTAINS 500 CHARACTERS.
       COPY SFPWEMP.
       FD  ARQ-EVENTO    RECORD CONTAINS 80 CHARACTERS.
       COPY SFPWEVE.
       FD  ARQ-SYSIN     RECORD CONTAINS 80 CHARACTERS.
       01  REG-SYSIN                   PIC X(080).
       FD  ARQ-ACEITOS   RECORD CONTAINS 100 CHARACTERS.
       01  REG-ACEITO                  PIC X(100).
       FD  ARQ-REJEITAD  RECORD CONTAINS 100 CHARACTERS.
       01  REG-REJEITADO               PIC X(100).
       FD  ARQ-LOG       RECORD CONTAINS 132 CHARACTERS.
       01  REG-LOG                     PIC X(132).
      *
       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05  WS-FS-MOV               PIC X(002) VALUE '00'.
           05  WS-FS-EMP               PIC X(002) VALUE '00'.
           05  WS-FS-EVE               PIC X(002) VALUE '00'.
           05  WS-FS-SYS               PIC X(002) VALUE '00'.
           05  WS-FS-ACE               PIC X(002) VALUE '00'.
           05  WS-FS-REJ               PIC X(002) VALUE '00'.
           05  WS-FS-LOG               PIC X(002) VALUE '00'.
       01  WS-CONTROLE.
           05  WS-FIM-MOV              PIC X(001) VALUE 'N'.
           05  WS-FIM-EMP              PIC X(001) VALUE 'N'.
           05  WS-FIM-EVE              PIC X(001) VALUE 'N'.
           05  WS-REG-OK               PIC X(001) VALUE 'S'.
           05  WS-COMPETENCIA          PIC 9(006) VALUE ZEROS.
           05  WS-TETO-LANCAMENTO      PIC 9(009)V99 VALUE 500000,00.
           05  WS-COD-RETORNO          PIC 9(002) VALUE ZEROS.
       01  WS-CONTADORES.
           05  WS-LIDOS                PIC 9(007) VALUE ZEROS.
           05  WS-ACEITOS              PIC 9(007) VALUE ZEROS.
           05  WS-REJEITADOS           PIC 9(007) VALUE ZEROS.
           05  WS-QTD-EMP              PIC 9(005) VALUE ZEROS.
           05  WS-QTD-EVE              PIC 9(005) VALUE ZEROS.
           05  WS-VLR-ACEITO           PIC 9(013)V99 VALUE ZEROS.
           05  WS-VLR-REJEITAD         PIC 9(013)V99 VALUE ZEROS.
      *
      *--- TABELA RESIDENTE DE EMPREGADOS -----------------------------
       01  WS-TABELA-EMPREGADO.
           05  TB-EMP OCCURS 1 TO 5000 TIMES
                      DEPENDING ON WS-QTD-EMP
                      ASCENDING KEY IS TB-EMP-MATRICULA
                      INDEXED BY IX-EMP.
               10  TB-EMP-MATRICULA    PIC 9(008).
               10  TB-EMP-SITUACAO     PIC X(001).
               10  TB-EMP-NOME         PIC X(040).
      *--- TABELA RESIDENTE DE RUBRICAS -------------------------------
       01  WS-TABELA-RUBRICA.
           05  TB-RUB OCCURS 1 TO 500 TIMES
                      DEPENDING ON WS-QTD-EVE
                      ASCENDING KEY IS TB-RUB-CODIGO
                      INDEXED BY IX-RUB.
               10  TB-RUB-CODIGO       PIC 9(004).
               10  TB-RUB-DESCRICAO    PIC X(030).
               10  TB-RUB-UNIDADE      PIC X(002).
               10  TB-RUB-TIPO-CALC    PIC 9(003).
               10  TB-RUB-SITUACAO     PIC X(001).
      *--- CONTROLE DE DUPLICIDADE ------------------------------------
       01  WS-ULTIMA-CHAVE.
           05  WS-ULT-MATRICULA        PIC 9(008) VALUE ZEROS.
           05  WS-ULT-EVENTO           PIC 9(004) VALUE ZEROS.
      *
       01  WS-LINHA-LOG.
           05  FILLER                  PIC X(001) VALUE SPACES.
           05  WSL-MATRICULA           PIC 9(008).
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  WSL-EVENTO              PIC 9(004).
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  WSL-REFERENCIA          PIC ZZ.ZZ9,99.
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  WSL-VALOR               PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  WSL-SITUACAO            PIC X(009).
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  WSL-MOTIVO              PIC X(050).
           05  FILLER                  PIC X(035) VALUE SPACES.
       01  WS-MOTIVO                   PIC X(050) VALUE SPACES.
      *
       PROCEDURE DIVISION.
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-CRITICAR UNTIL WS-FIM-MOV = 'S'
           PERFORM 9000-FINALIZAR
           MOVE WS-COD-RETORNO         TO RETURN-CODE
           STOP RUN.
      *
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           OPEN INPUT  ARQ-MOVIMENTO ARQ-EMPREGADO ARQ-EVENTO
                       ARQ-SYSIN
           OPEN OUTPUT ARQ-ACEITOS ARQ-REJEITAD ARQ-LOG
           IF WS-FS-MOV NOT = '00' OR WS-FS-EMP NOT = '00'
              OR WS-FS-EVE NOT = '00'
               DISPLAY 'SFP0200 - ERRO DE ABERTURA DE ARQUIVOS'
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
      *
           READ ARQ-SYSIN
               AT END MOVE ZEROS       TO WS-COMPETENCIA
               NOT AT END
                   MOVE REG-SYSIN(01:06) TO WS-COMPETENCIA
           END-READ
      *
           PERFORM 1100-CARREGAR-EMPREGADOS
           PERFORM 1200-CARREGAR-RUBRICAS
           PERFORM 1300-CABECALHO-LOG
           PERFORM 8100-LER-MOVIMENTO.
       1000-FIM.
           EXIT.
      *
       1100-CARREGAR-EMPREGADOS SECTION.
       1100-INICIO.
           PERFORM UNTIL WS-FIM-EMP = 'S'
               READ ARQ-EMPREGADO
                   AT END MOVE 'S'     TO WS-FIM-EMP
                   NOT AT END
                       ADD 1           TO WS-QTD-EMP
                       MOVE EMP-MATRICULA
                                    TO TB-EMP-MATRICULA(WS-QTD-EMP)
                       MOVE EMP-SITUACAO
                                    TO TB-EMP-SITUACAO(WS-QTD-EMP)
                       MOVE EMP-NOME
                                    TO TB-EMP-NOME(WS-QTD-EMP)
               END-READ
           END-PERFORM
           CLOSE ARQ-EMPREGADO
           DISPLAY 'SFP0200 - EMPREGADOS CARREGADOS: ' WS-QTD-EMP.
       1100-FIM.
           EXIT.
      *
       1200-CARREGAR-RUBRICAS SECTION.
       1200-INICIO.
           PERFORM UNTIL WS-FIM-EVE = 'S'
               READ ARQ-EVENTO
                   AT END MOVE 'S'     TO WS-FIM-EVE
                   NOT AT END
                       ADD 1           TO WS-QTD-EVE
                       MOVE EVE-CODIGO
                                    TO TB-RUB-CODIGO(WS-QTD-EVE)
                       MOVE EVE-DESCRICAO
                                    TO TB-RUB-DESCRICAO(WS-QTD-EVE)
                       MOVE EVE-UNIDADE
                                    TO TB-RUB-UNIDADE(WS-QTD-EVE)
                       MOVE EVE-TIPO-CALCULO
                                    TO TB-RUB-TIPO-CALC(WS-QTD-EVE)
                       MOVE EVE-SITUACAO
                                    TO TB-RUB-SITUACAO(WS-QTD-EVE)
               END-READ
           END-PERFORM
           CLOSE ARQ-EVENTO
           DISPLAY 'SFP0200 - RUBRICAS CARREGADAS ..: ' WS-QTD-EVE.
       1200-FIM.
           EXIT.
      *
       1300-CABECALHO-LOG SECTION.
       1300-INICIO.
           MOVE ALL '='                TO REG-LOG
           WRITE REG-LOG
           MOVE SPACES                 TO REG-LOG
           STRING ' SFP0200 - CRITICA DO MOVIMENTO MENSAL'
                  '  -  COMPETENCIA ' WS-COMPETENCIA
               DELIMITED BY SIZE INTO REG-LOG
           WRITE REG-LOG
           MOVE ALL '='                TO REG-LOG
           WRITE REG-LOG
           MOVE SPACES                 TO REG-LOG
           MOVE ' MATRICULA  EVENT  REFERENCIA        VALOR  SITUACAO'
                                       TO REG-LOG
           MOVE '  MOTIVO' TO REG-LOG(54:8)
           WRITE REG-LOG
           MOVE ALL '-'                TO REG-LOG
           WRITE REG-LOG.
       1300-FIM.
           EXIT.
      *
      *================================================================*
       2000-CRITICAR SECTION.
       2000-INICIO.
           MOVE 'S'                    TO WS-REG-OK
           MOVE SPACES                 TO WS-MOTIVO
      *
           PERFORM 2100-VALIDAR-EMPREGADO
           IF WS-REG-OK = 'S'
               PERFORM 2200-VALIDAR-RUBRICA
           END-IF
           IF WS-REG-OK = 'S'
               PERFORM 2300-VALIDAR-COMPETENCIA
           END-IF
           IF WS-REG-OK = 'S'
               PERFORM 2400-VALIDAR-CONTEUDO
           END-IF
           IF WS-REG-OK = 'S'
               PERFORM 2500-VALIDAR-DUPLICIDADE
           END-IF
      *
           PERFORM 2900-DESTINAR-REGISTRO
           MOVE MOV-MATRICULA          TO WS-ULT-MATRICULA
           MOVE MOV-COD-EVENTO         TO WS-ULT-EVENTO
           PERFORM 8100-LER-MOVIMENTO.
       2000-FIM.
           EXIT.
      *
       2100-VALIDAR-EMPREGADO SECTION.
       2100-INICIO.
           SEARCH ALL TB-EMP
               AT END
                   MOVE 'N'            TO WS-REG-OK
                   MOVE 'MATRICULA INEXISTENTE NO CADASTRO'
                                       TO WS-MOTIVO
               WHEN TB-EMP-MATRICULA(IX-EMP) = MOV-MATRICULA
                   IF TB-EMP-SITUACAO(IX-EMP) = 'D'
                       MOVE 'N'        TO WS-REG-OK
                       MOVE 'EMPREGADO DEMITIDO - USAR FOLHA RESCISORIA'
                                       TO WS-MOTIVO
                   END-IF
           END-SEARCH.
       2100-FIM.
           EXIT.
      *
       2200-VALIDAR-RUBRICA SECTION.
       2200-INICIO.
           SEARCH ALL TB-RUB
               AT END
                   MOVE 'N'            TO WS-REG-OK
                   MOVE 'RUBRICA INEXISTENTE NO CADASTRO DE EVENTOS'
                                       TO WS-MOTIVO
               WHEN TB-RUB-CODIGO(IX-RUB) = MOV-COD-EVENTO
                   IF TB-RUB-SITUACAO(IX-RUB) NOT = 'A'
                       MOVE 'N'        TO WS-REG-OK
                       MOVE 'RUBRICA INATIVA NA COMPETENCIA'
                                       TO WS-MOTIVO
                   END-IF
           END-SEARCH.
       2200-FIM.
           EXIT.
      *
       2300-VALIDAR-COMPETENCIA SECTION.
       2300-INICIO.
           IF WS-COMPETENCIA NOT = ZEROS
              AND MOV-COMPETENCIA NOT = WS-COMPETENCIA
               MOVE 'N'                TO WS-REG-OK
               MOVE 'COMPETENCIA DIVERGENTE DA FOLHA EM PROCESSAMENTO'
                                       TO WS-MOTIVO
           END-IF.
       2300-FIM.
           EXIT.
      *
       2400-VALIDAR-CONTEUDO SECTION.
       2400-INICIO.
           IF MOV-VALOR = ZEROS AND MOV-REFERENCIA = ZEROS
               MOVE 'N'                TO WS-REG-OK
               MOVE 'REFERENCIA E VALOR SIMULTANEAMENTE ZERADOS'
                                       TO WS-MOTIVO
               GO TO 2400-FIM
           END-IF
      *
           IF MOV-VALOR > WS-TETO-LANCAMENTO
               MOVE 'N'                TO WS-REG-OK
               MOVE 'VALOR ACIMA DO TETO PERMITIDO POR LANCAMENTO'
                                       TO WS-MOTIVO
               GO TO 2400-FIM
           END-IF
      *
      *    RUBRICAS EXPRESSAS EM HORAS OU DIAS EXIGEM REFERENCIA
           IF TB-RUB-UNIDADE(IX-RUB) = 'HR'
              OR TB-RUB-UNIDADE(IX-RUB) = 'DI'
               IF MOV-REFERENCIA = ZEROS
                   MOVE 'N'            TO WS-REG-OK
                   MOVE 'RUBRICA EM HORAS/DIAS SEM QUANTIDADE INFORMADA'
                                       TO WS-MOTIVO
               END-IF
           END-IF
      *
      *    RUBRICAS DE VALOR FIXO NAO ADMITEM REFERENCIA ISOLADA
           IF TB-RUB-UNIDADE(IX-RUB) = 'VL'
               IF MOV-VALOR = ZEROS
                   MOVE 'N'            TO WS-REG-OK
                   MOVE 'RUBRICA DE VALOR SEM IMPORTANCIA INFORMADA'
                                       TO WS-MOTIVO
               END-IF
           END-IF
      *
           IF MOV-TIPO-LANC NOT = 'F' AND MOV-TIPO-LANC NOT = 'M'
              AND MOV-TIPO-LANC NOT = 'E'
               MOVE 'N'                TO WS-REG-OK
               MOVE 'TIPO DE LANCAMENTO INVALIDO (ESPERADO F, M OU E)'
                                       TO WS-MOTIVO
           END-IF.
       2400-FIM.
           EXIT.
      *
       2500-VALIDAR-DUPLICIDADE SECTION.
       2500-INICIO.
           IF MOV-MATRICULA = WS-ULT-MATRICULA
              AND MOV-COD-EVENTO = WS-ULT-EVENTO
               MOVE 'N'                TO WS-REG-OK
               MOVE 'LANCAMENTO DUPLICADO PARA A MESMA RUBRICA'
                                       TO WS-MOTIVO
           END-IF.
       2500-FIM.
           EXIT.
      *
       2900-DESTINAR-REGISTRO SECTION.
       2900-INICIO.
           MOVE MOV-MATRICULA          TO WSL-MATRICULA
           MOVE MOV-COD-EVENTO         TO WSL-EVENTO
           MOVE MOV-REFERENCIA         TO WSL-REFERENCIA
           MOVE MOV-VALOR              TO WSL-VALOR
           MOVE WS-MOTIVO              TO WSL-MOTIVO
      *
           IF WS-REG-OK = 'S'
               MOVE 'A'                TO MOV-SIT-CRITICA
               MOVE REG-MOVIMENTO      TO REG-ACEITO
               WRITE REG-ACEITO
               ADD 1                   TO WS-ACEITOS
               ADD MOV-VALOR           TO WS-VLR-ACEITO
               MOVE 'ACEITO   '        TO WSL-SITUACAO
           ELSE
               MOVE 'R'                TO MOV-SIT-CRITICA
               MOVE REG-MOVIMENTO      TO REG-REJEITADO
               WRITE REG-REJEITADO
               ADD 1                   TO WS-REJEITADOS
               ADD MOV-VALOR           TO WS-VLR-REJEITAD
               MOVE 'REJEITADO'        TO WSL-SITUACAO
               MOVE 04                 TO WS-COD-RETORNO
               MOVE WS-LINHA-LOG       TO REG-LOG
               WRITE REG-LOG
           END-IF.
       2900-FIM.
           EXIT.
      *
       8100-LER-MOVIMENTO SECTION.
       8100-INICIO.
           READ ARQ-MOVIMENTO
               AT END MOVE 'S'         TO WS-FIM-MOV
               NOT AT END ADD 1        TO WS-LIDOS
           END-READ.
       8100-FIM.
           EXIT.
      *
       9000-FINALIZAR SECTION.
       9000-INICIO.
           MOVE ALL '-'                TO REG-LOG
           WRITE REG-LOG
           MOVE SPACES                 TO REG-LOG
           STRING ' LIDOS: ' WS-LIDOS
                  '   ACEITOS: ' WS-ACEITOS
                  '   REJEITADOS: ' WS-REJEITADOS
               DELIMITED BY SIZE INTO REG-LOG
           WRITE REG-LOG
           CLOSE ARQ-MOVIMENTO ARQ-SYSIN ARQ-ACEITOS
                 ARQ-REJEITAD ARQ-LOG
           DISPLAY '=================================================='
           DISPLAY ' SFP0200 - CRITICA DO MOVIMENTO CONCLUIDA'
           DISPLAY '=================================================='
           DISPLAY ' REGISTROS LIDOS ....: ' WS-LIDOS
           DISPLAY ' ACEITOS ............: ' WS-ACEITOS
           DISPLAY ' REJEITADOS .........: ' WS-REJEITADOS
           DISPLAY ' VALOR ACEITO .......: ' WS-VLR-ACEITO
           DISPLAY ' VALOR REJEITADO ....: ' WS-VLR-REJEITAD
           DISPLAY ' RETURN CODE ........: ' WS-COD-RETORNO
           DISPLAY '=================================================='.
       9000-FIM.
           EXIT.
