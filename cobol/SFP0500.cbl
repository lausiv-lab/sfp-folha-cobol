      *================================================================*
      * PROGRAMA : SFP0500                                             *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * FUNCAO   : EMISSAO DO ESPELHO DE PAGAMENTO (CONTRACHEQUE)      *
      *            CASA O ARQUIVO DE RESUMO COM O DETALHE DE EVENTOS   *
      *            E IMPRIME UM DEMONSTRATIVO POR EMPREGADO, COM       *
      *            QUEBRA DE PAGINA, TOTALIZACAO DE PROVENTOS E        *
      *            DESCONTOS, BASES DE INCIDENCIA E LIQUIDO POR        *
      *            EXTENSO (OBTIDO VIA SFPUTIL)                        *
      * ENTRADA  : SFPRES SFPFOL                                       *
      * SAIDA    : SFPREL (RELATORIO 132 COLUNAS)                      *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0500.
       AUTHOR. EQUIPE-SFP.
      *
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ARQ-RESUMO ASSIGN TO SFPRES
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-RES.
           SELECT ARQ-FOLHA  ASSIGN TO SFPFOL
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-FOL.
           SELECT ARQ-RELAT  ASSIGN TO SFPREL
                  ORGANIZATION IS LINE SEQUENTIAL
                  FILE STATUS  IS WS-FS-REL.
      *
       DATA DIVISION.
       FILE SECTION.
       FD  ARQ-RESUMO RECORD CONTAINS 250 CHARACTERS.
       COPY SFPWRES.
       FD  ARQ-FOLHA  RECORD CONTAINS 120 CHARACTERS.
       COPY SFPWFOL.
       FD  ARQ-RELAT  RECORD CONTAINS 132 CHARACTERS.
       01  REG-RELAT                   PIC X(132).
      *
       WORKING-STORAGE SECTION.
       77  WS-FS-RES                   PIC X(002) VALUE '00'.
       77  WS-FS-FOL                   PIC X(002) VALUE '00'.
       77  WS-FS-REL                   PIC X(002) VALUE '00'.
       77  WS-FIM-RES                  PIC X(001) VALUE 'N'.
       77  WS-FIM-FOL                  PIC X(001) VALUE 'N'.
       77  WS-LINHAS                   PIC 9(003) VALUE 99.
       77  WS-PAGINA                   PIC 9(005) VALUE ZEROS.
       77  WS-IMPRESSOS                PIC 9(007) VALUE ZEROS.
       77  WS-MAX-LINHAS               PIC 9(003) VALUE 60.
       77  WS-DATA-SIS                 PIC 9(008) VALUE ZEROS.
       77  WS-HORA-SIS                 PIC 9(008) VALUE ZEROS.
       77  WS-TOT-PROV                 PIC 9(009)V99 VALUE ZEROS.
       77  WS-TOT-DESC                 PIC 9(009)V99 VALUE ZEROS.
      *
       01  WS-DATA-EDIT.
           05  WS-DE-DIA               PIC X(002).
           05  FILLER                  PIC X(001) VALUE '/'.
           05  WS-DE-MES               PIC X(002).
           05  FILLER                  PIC X(001) VALUE '/'.
           05  WS-DE-ANO               PIC X(004).
       01  WS-HORA-EDIT.
           05  WS-HE-HH                PIC X(002).
           05  FILLER                  PIC X(001) VALUE ':'.
           05  WS-HE-MM                PIC X(002).
           05  FILLER                  PIC X(001) VALUE ':'.
           05  WS-HE-SS                PIC X(002).
       01  WS-COMPET-EDIT.
           05  WS-CE-MES               PIC X(002).
           05  FILLER                  PIC X(001) VALUE '/'.
           05  WS-CE-ANO               PIC X(004).
       01  WS-AUX-DATA.
           05  WS-AD-ANO               PIC X(004).
           05  WS-AD-MES               PIC X(002).
           05  WS-AD-DIA               PIC X(002).
       01  WS-AUX-HORA.
           05  WS-AH-HH                PIC X(002).
           05  WS-AH-MM                PIC X(002).
           05  WS-AH-SS                PIC X(002).
           05  WS-AH-CC                PIC X(002).
      *
      *--- LINHAS DO RELATORIO ----------------------------------------
       01  L-MOLDURA                   PIC X(132) VALUE ALL '='.
       01  L-DIVISOR                   PIC X(132) VALUE ALL '-'.
       01  L-BRANCO                    PIC X(132) VALUE SPACES.
      *
       01  L-CAB1.
           05  FILLER                  PIC X(012) VALUE 'SFP0500'.
           05  FILLER                  PIC X(042) VALUE
               'INDUSTRIA MERIDIONAL DE COMPONENTES S/A'.
           05  FILLER                  PIC X(023) VALUE
               'CNPJ 74.829.163/0001-78'.
           05  FILLER                  PIC X(010) VALUE '  EMISSAO '.
           05  L1-DATA                 PIC X(010).
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  L1-HORA                 PIC X(008).
           05  FILLER                  PIC X(008) VALUE '   PAG. '.
           05  L1-PAGINA               PIC ZZ.ZZ9.
           05  FILLER                  PIC X(011) VALUE SPACES.
      *
       01  L-CAB2.
           05  FILLER                  PIC X(038) VALUE SPACES.
           05  FILLER                  PIC X(050) VALUE
               'DEMONSTRATIVO DE PAGAMENTO DE SALARIOS'.
           05  FILLER                  PIC X(013) VALUE
               'COMPETENCIA: '.
           05  L2-COMPETENCIA          PIC X(007).
           05  FILLER                  PIC X(024) VALUE SPACES.
      *
       01  L-EMPREG1.
           05  FILLER                  PIC X(011) VALUE 'MATRICULA: '.
           05  LE1-MATRICULA           PIC 9(008).
           05  FILLER                  PIC X(008) VALUE '  NOME: '.
           05  LE1-NOME                PIC X(040).
           05  FILLER                  PIC X(007) VALUE '  CPF: '.
           05  LE1-CPF                 PIC 999.999.999B99.
           05  FILLER                  PIC X(043) VALUE SPACES.
      *
       01  L-EMPREG2.
           05  FILLER                  PIC X(017) VALUE
               'CENTRO DE CUSTO: '.
           05  LE2-CENTRO-CUSTO        PIC 9(006).
           05  FILLER                  PIC X(017) VALUE
               '   SALARIO BASE: '.
           05  LE2-SALARIO             PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(011) VALUE '   BANCO/AG'.
           05  FILLER                  PIC X(002) VALUE ': '.
           05  LE2-BANCO               PIC 9(003).
           05  FILLER                  PIC X(001) VALUE '/'.
           05  LE2-AGENCIA             PIC 9(005).
           05  FILLER                  PIC X(009) VALUE '   CONTA:'.
           05  LE2-CONTA               PIC 9(012).
           05  FILLER                  PIC X(001) VALUE '-'.
           05  LE2-DIGITO              PIC X(001).
           05  FILLER                  PIC X(033) VALUE SPACES.
      *
       01  L-TITULO-EV.
           05  FILLER                  PIC X(006) VALUE 'CODIGO'.
           05  FILLER                  PIC X(032) VALUE
               ' DESCRICAO DO EVENTO'.
           05  FILLER                  PIC X(014) VALUE
               '   REFERENCIA'.
           05  FILLER                  PIC X(020) VALUE
               '        PROVENTOS'.
           05  FILLER                  PIC X(020) VALUE
               '        DESCONTOS'.
           05  FILLER                  PIC X(040) VALUE SPACES.
      *
       01  L-EVENTO.
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  LEV-CODIGO              PIC 9(004).
           05  FILLER                  PIC X(002) VALUE SPACES.
           05  LEV-DESCRICAO           PIC X(030).
           05  FILLER                  PIC X(003) VALUE SPACES.
           05  LEV-REFERENCIA          PIC ZZ.ZZ9,99.
           05  FILLER                  PIC X(005) VALUE SPACES.
           05  LEV-PROVENTO            PIC ZZZ.ZZZ.ZZ9,99
                                       BLANK WHEN ZERO.
           05  FILLER                  PIC X(005) VALUE SPACES.
           05  LEV-DESCONTO            PIC ZZZ.ZZZ.ZZ9,99
                                       BLANK WHEN ZERO.
           05  FILLER                  PIC X(050) VALUE SPACES.
      *
       01  L-TOTAIS.
           05  FILLER                  PIC X(041) VALUE SPACES.
           05  FILLER                  PIC X(011) VALUE
               'TOTAIS ->  '.
           05  FILLER                  PIC X(003) VALUE SPACES.
           05  LT-PROVENTOS            PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(005) VALUE SPACES.
           05  LT-DESCONTOS            PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(050) VALUE SPACES.
      *
       01  L-BASES.
           05  FILLER                  PIC X(013) VALUE 'BASE INSS: '.
           05  LB-BASE-INSS            PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(013) VALUE
               '  BASE IRRF: '.
           05  LB-BASE-IRRF            PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(013) VALUE
               '  BASE FGTS: '.
           05  LB-BASE-FGTS            PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(013) VALUE
               '  FGTS MES : '.
           05  LB-FGTS                 PIC ZZZ.ZZZ.ZZ9,99.
           05  FILLER                  PIC X(020) VALUE SPACES.
      *
       01  L-LIQUIDO.
           05  FILLER                  PIC X(070) VALUE SPACES.
           05  FILLER                  PIC X(022) VALUE
               'LIQUIDO A RECEBER ->  '.
           05  LL-LIQUIDO              PIC ZZZ.ZZZ.ZZ9,99-.
           05  FILLER                  PIC X(025) VALUE SPACES.
      *
       01  L-EXTENSO.
           05  FILLER                  PIC X(011) VALUE 'POR EXTENSO'.
           05  FILLER                  PIC X(002) VALUE ': '.
           05  LX-EXTENSO              PIC X(119).
      *
       01  L-RODAPE.
           05  FILLER                  PIC X(008) VALUE SPACES.
           05  FILLER                  PIC X(030) VALUE
               'DECLARO TER RECEBIDO A QUANTIA'.
           05  FILLER                  PIC X(026) VALUE
               ' LIQUIDA AQUI DISCRIMINADA'.
           05  FILLER                  PIC X(022) VALUE
               '     ____/____/______ '.
           05  FILLER                  PIC X(046) VALUE
               '   ___________________________________________'.
      *
       COPY SFPWUTL.
      *
       PROCEDURE DIVISION.
       0000-PRINCIPAL SECTION.
       0000-INICIO.
           PERFORM 1000-INICIALIZAR
           PERFORM 2000-PROCESSAR UNTIL WS-FIM-RES = 'S'
           PERFORM 9000-FINALIZAR
           STOP RUN.
      *
       1000-INICIALIZAR SECTION.
       1000-INICIO.
           ACCEPT WS-DATA-SIS FROM DATE YYYYMMDD
           ACCEPT WS-HORA-SIS FROM TIME
           MOVE WS-DATA-SIS            TO WS-AUX-DATA
           MOVE WS-AD-DIA              TO WS-DE-DIA
           MOVE WS-AD-MES              TO WS-DE-MES
           MOVE WS-AD-ANO              TO WS-DE-ANO
           MOVE WS-HORA-SIS            TO WS-AUX-HORA
           MOVE WS-AH-HH               TO WS-HE-HH
           MOVE WS-AH-MM               TO WS-HE-MM
           MOVE WS-AH-SS               TO WS-HE-SS
      *
           OPEN INPUT  ARQ-RESUMO ARQ-FOLHA
           OPEN OUTPUT ARQ-RELAT
           IF WS-FS-RES NOT = '00' OR WS-FS-FOL NOT = '00'
               DISPLAY 'SFP0500 - ERRO ABERTURA. RES=' WS-FS-RES
                       ' FOL=' WS-FS-FOL
               MOVE 12                 TO RETURN-CODE
               STOP RUN
           END-IF
           PERFORM 8100-LER-RESUMO
           PERFORM 8200-LER-FOLHA.
       1000-FIM.
           EXIT.
      *
       2000-PROCESSAR SECTION.
       2000-INICIO.
           PERFORM 2100-CABECALHO-EMPREGADO
           MOVE ZEROS                  TO WS-TOT-PROV WS-TOT-DESC
      *
      *    DESPREZA EVENTOS ANTERIORES SEM RESUMO CORRESPONDENTE
           PERFORM UNTIL WS-FIM-FOL = 'S'
                      OR FOL-MATRICULA >= RES-MATRICULA
               PERFORM 8200-LER-FOLHA
           END-PERFORM
      *
           PERFORM UNTIL WS-FIM-FOL = 'S'
                      OR FOL-MATRICULA NOT = RES-MATRICULA
               PERFORM 2200-IMPRIMIR-EVENTO
               PERFORM 8200-LER-FOLHA
           END-PERFORM
      *
           PERFORM 2300-RODAPE-EMPREGADO
           ADD 1                       TO WS-IMPRESSOS
           PERFORM 8100-LER-RESUMO.
       2000-FIM.
           EXIT.
      *
       2100-CABECALHO-EMPREGADO SECTION.
       2100-INICIO.
           IF WS-LINHAS > WS-MAX-LINHAS
               PERFORM 8500-QUEBRA-PAGINA
           END-IF
           MOVE L-BRANCO               TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-MOLDURA              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE RES-MATRICULA          TO LE1-MATRICULA
           MOVE RES-NOME               TO LE1-NOME
           MOVE RES-CPF                TO LE1-CPF
           MOVE L-EMPREG1              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE RES-CENTRO-CUSTO       TO LE2-CENTRO-CUSTO
           MOVE RES-SALARIO-BASE       TO LE2-SALARIO
           MOVE RES-BANCO              TO LE2-BANCO
           MOVE RES-AGENCIA            TO LE2-AGENCIA
           MOVE RES-CONTA              TO LE2-CONTA
           MOVE RES-DIG-CONTA          TO LE2-DIGITO
           MOVE L-EMPREG2              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-DIVISOR              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-TITULO-EV            TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-DIVISOR              TO REG-RELAT
           PERFORM 8600-ESCREVER.
       2100-FIM.
           EXIT.
      *
       2200-IMPRIMIR-EVENTO SECTION.
       2200-INICIO.
           MOVE FOL-COD-EVENTO         TO LEV-CODIGO
           MOVE FOL-DESCRICAO          TO LEV-DESCRICAO
           MOVE FOL-REFERENCIA         TO LEV-REFERENCIA
           MOVE ZEROS                  TO LEV-PROVENTO LEV-DESCONTO
      *
           EVALUATE FOL-NATUREZA
               WHEN 'P'
                    MOVE FOL-VALOR     TO LEV-PROVENTO
                    ADD  FOL-VALOR     TO WS-TOT-PROV
               WHEN 'D'
                    MOVE FOL-VALOR     TO LEV-DESCONTO
                    ADD  FOL-VALOR     TO WS-TOT-DESC
               WHEN OTHER
                    CONTINUE
           END-EVALUATE
      *
           IF FOL-NATUREZA NOT = 'I'
               MOVE L-EVENTO           TO REG-RELAT
               PERFORM 8600-ESCREVER
           END-IF.
       2200-FIM.
           EXIT.
      *
       2300-RODAPE-EMPREGADO SECTION.
       2300-INICIO.
           MOVE L-DIVISOR              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE WS-TOT-PROV            TO LT-PROVENTOS
           MOVE WS-TOT-DESC            TO LT-DESCONTOS
           MOVE L-TOTAIS               TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE RES-BASE-INSS          TO LB-BASE-INSS
           MOVE RES-BASE-IRRF          TO LB-BASE-IRRF
           MOVE RES-BASE-FGTS          TO LB-BASE-FGTS
           MOVE RES-VLR-FGTS           TO LB-FGTS
           MOVE L-BASES                TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE RES-LIQUIDO            TO LL-LIQUIDO
           MOVE L-LIQUIDO              TO REG-RELAT
           PERFORM 8600-ESCREVER
      *
           INITIALIZE AREA-UTILITARIOS
           SET UTL-VALOR-EXTENSO       TO TRUE
           IF RES-LIQUIDO > ZEROS
               MOVE RES-LIQUIDO        TO UTL-VALOR
           ELSE
               MOVE ZEROS              TO UTL-VALOR
           END-IF
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           MOVE UTL-EXTENSO            TO LX-EXTENSO
           MOVE L-EXTENSO              TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-BRANCO               TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-RODAPE               TO REG-RELAT
           PERFORM 8600-ESCREVER
           MOVE L-MOLDURA              TO REG-RELAT
           PERFORM 8600-ESCREVER.
       2300-FIM.
           EXIT.
      *
       8100-LER-RESUMO SECTION.
       8100-INICIO.
           READ ARQ-RESUMO
               AT END
                   MOVE 'S'            TO WS-FIM-RES
                   MOVE 99999999       TO RES-MATRICULA
           END-READ.
       8100-FIM.
           EXIT.
      *
       8200-LER-FOLHA SECTION.
       8200-INICIO.
           READ ARQ-FOLHA
               AT END
                   MOVE 'S'            TO WS-FIM-FOL
                   MOVE 99999999       TO FOL-MATRICULA
           END-READ.
       8200-FIM.
           EXIT.
      *
       8500-QUEBRA-PAGINA SECTION.
       8500-INICIO.
           ADD 1                       TO WS-PAGINA
           MOVE WS-PAGINA              TO L1-PAGINA
           MOVE WS-DATA-EDIT           TO L1-DATA
           MOVE WS-HORA-EDIT           TO L1-HORA
           MOVE RES-COMPETENCIA(5:2)   TO WS-CE-MES
           MOVE RES-COMPETENCIA(1:4)   TO WS-CE-ANO
           MOVE WS-COMPET-EDIT         TO L2-COMPETENCIA
           MOVE L-CAB1                 TO REG-RELAT
           WRITE REG-RELAT
           MOVE L-CAB2                 TO REG-RELAT
           WRITE REG-RELAT
           MOVE L-MOLDURA              TO REG-RELAT
           WRITE REG-RELAT
           MOVE 4                      TO WS-LINHAS.
       8500-FIM.
           EXIT.
      *
       8600-ESCREVER SECTION.
       8600-INICIO.
           IF WS-LINHAS > WS-MAX-LINHAS
               PERFORM 8500-QUEBRA-PAGINA
           END-IF
           WRITE REG-RELAT
           ADD 1                       TO WS-LINHAS.
       8600-FIM.
           EXIT.
      *
       9000-FINALIZAR SECTION.
       9000-INICIO.
           CLOSE ARQ-RESUMO ARQ-FOLHA ARQ-RELAT
           DISPLAY 'SFP0500 - CONTRACHEQUES EMITIDOS: ' WS-IMPRESSOS
           DISPLAY 'SFP0500 - PAGINAS GERADAS ......: ' WS-PAGINA.
       9000-FIM.
           EXIT.
