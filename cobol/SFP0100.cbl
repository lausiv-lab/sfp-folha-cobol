      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0100                                             *
      * TRANSACAO: SF01                                                *
      * MAPSET   : SFPM01   MAPA: MAPEMP                               *
      * FUNCAO   : MANUTENCAO ONLINE DO CADASTRO DE EMPREGADOS         *
      *            CONSULTA, INCLUSAO, ALTERACAO E EXCLUSAO LOGICA     *
      * TIPO     : CICS / DB2 - PSEUDOCONVERSACIONAL                   *
      *----------------------------------------------------------------*
      * IMPORTANTE                                                     *
      * O CADASTRO OCUPA DUAS TELAS DO MAPSET SFPM01. A TECLA F9       *
      * ALTERNA ENTRE MAPEMP (VINCULO E PAGAMENTO, GRAVADO EM          *
      * TB_EMPREGADO) E MAPEMP2 (DADOS PESSOAIS, DOCUMENTOS E          *
      * ENDERECO, GRAVADOS EM TB_EMPREGADO_COMPL, MAIS SEXO E          *
      * GRAU_INSTRUCAO, QUE FICAM EM TB_EMPREGADO). A SEGUNDA TELA     *
      * EXIGE MATRICULA JA CADASTRADA: E ELA QUE DA A CHAVE DAS        *
      * DUAS TABELAS.                                                  *
      *                                                                *
      * O ESTADO DAS DUAS TELAS SOMA 500 BYTES E NAO CABE NA           *
      * COM-AREA-TRABALHO, QUE OFERECE 326 BYTES DEPOIS DO SFPWLOK.    *
      * POR ISSO ELE VIVE EM UMA FILA TEMPORARIA DO CICS               *
      * (WRITEQ TS ... MAIN, NOME 'S01' MAIS EIBTRMID), COMO NO        *
      * SFP0130. FILA EM MAIN NAO E RECUPERAVEL: O ROLLBACK DO         *
      * TRATADOR DE ABEND NAO A DESFAZ, O QUE E ACEITAVEL PORQUE       *
      * ELA GUARDA DIGITACAO, NAO DADO CONFIRMADO.                     *
      *                                                                *
      * COM CTRL=(FREEKB,FRSET) SO VOLTAM DO RECEIVE OS CAMPOS         *
      * DIGITADOS. A SECAO 3020 MESCLA A DIGITACAO NOVA COM A COPIA    *
      * GUARDADA DA PRIMEIRA TELA, DE MODO QUE A ALTERACAO DE UM       *
      * CAMPO SO NAO APAGUE OS DEMAIS E O IDA-E-VOLTA DO F4 NAO        *
      * PERCA O QUE JA ESTAVA NA TELA.                                 *
      *----------------------------------------------------------------*
      * ESTE MODULO CONTEM EXEC CICS E EXEC SQL. EXIGE OS              *
      * TRADUTORES DFHECP1$ E DSNHPC ANTES DA COMPILACAO COBOL.        *
      * NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME.                   *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO DO CADASTRAMENTO                             *
      *  RN01 - MATRICULA OBRIGATORIA E NUMERICA                       *
      *  RN02 - NOME OBRIGATORIO COM NO MINIMO 10 CARACTERES           *
      *  RN03 - CPF VALIDADO PELO ALGORITMO DE MODULO 11               *
      *  RN04 - CPF NAO PODE ESTAR CADASTRADO EM OUTRA MATRICULA       *
      *  RN05 - DATAS VALIDADAS COM TRATAMENTO DE ANO BISSEXTO         *
      *  RN06 - ADMISSAO NAO PODE SER ANTERIOR AO 14O ANIVERSARIO      *
      *  RN07 - DEMISSAO NAO PODE SER ANTERIOR A ADMISSAO              *
      *  RN08 - SITUACAO D EXIGE DATA DE DEMISSAO PREENCHIDA           *
      *  RN09 - SALARIO NAO PODE SER INFERIOR AO MINIMO LEGAL          *
      *         (MENSALISTA COMPARA COM O SALARIO MINIMO,              *
      *          HORISTA COMPARA COM O MINIMO / CARGA HORARIA)         *
      *  RN10 - INSALUBRIDADE ACEITA APENAS 0, 10, 20 OU 40 POR CENTO  *
      *  RN11 - INSALUBRIDADE E PERICULOSIDADE NAO SE ACUMULAM         *
      *  RN12 - PENSAO EM PERCENTUAL E EM VALOR SAO EXCLUDENTES        *
      *  RN13 - CONSIGNADO LIMITADO A 35 POR CENTO DO SALARIO          *
      *  RN14 - BENEFICIO COM INDICADOR S EXIGE VALOR MAIOR QUE ZERO   *
      *  RN15 - CONTA BANCARIA EXIGE BANCO, AGENCIA E CONTA JUNTOS     *
      *  RN16 - EXCLUSAO E LOGICA: NAO SE APAGA HISTORICO DE FOLHA     *
      *  RN17 - NAO SE EXCLUI EMPREGADO COM MOVIMENTO NA COMPETENCIA   *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0100.
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
       01  WS-IDENTIFICACAO.
           05  FILLER              PIC X(032) VALUE
               'SFP0100 - CADASTRO DE EMPREGADOS'.
           05  FILLER              PIC X(020) VALUE
               ' VERSAO 04 RELEASE 2'.
      *
      *--- CONSTANTES DE CONTROLE DA TRANSACAO ------------------------
       01  WS-CONSTANTES.
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF01'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0100 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM01 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPEMP '.
           05  WS-PGM-DEPEND       PIC X(008) VALUE 'SFP0110 '.
           05  WS-MAPA2            PIC X(007) VALUE 'MAPEMP2'.
           05  WS-PGM-LOOKUP       PIC X(008) VALUE 'SFP0900 '.
           05  WS-ARQ-DOMINIO      PIC X(008) VALUE 'SFPDOM  '.
           05  WS-ARQ-UF           PIC X(008) VALUE 'SFPUFE  '.
           05  WS-ARQ-MUNICIPIO    PIC X(008) VALUE 'SFPMUN  '.
           05  WS-ARQ-ESTABELEC    PIC X(008) VALUE 'SFPEST  '.
      *
      *--- CODIGOS DE TECLA DE FUNCAO (DFHAID) ------------------------
       COPY DFHAID.
       COPY DFHBMSCA.
      *
      *--- MAPA SIMBOLICO ---------------------------------------------
       COPY SFPM01.
      *
      *--- CADASTROS DE APOIO LIDOS PELO CICS -------------------------
       COPY SFPWDOM.
      *
       COPY SFPWUFE.
      *
       COPY SFPWMUN.
      *
       COPY SFPWEST.
      *
      *--- DCLGEN DA TABELA DE EMPREGADOS -----------------------------
       EXEC SQL INCLUDE SFPDEMP END-EXEC.
      *
      *--- DCLGEN DA TABELA COMPLEMENTAR (SEGUNDA TELA) ---------------
       EXEC SQL INCLUDE SFPDEMC END-EXEC.
      *
      *--- AREA DE COMUNICACAO SQL ------------------------------------
       EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *--- INDICADORES DE NULO ----------------------------------------
       01  WS-INDICADORES.
           05  WS-IND-DT-DEMISSAO  PIC S9(004) COMP VALUE ZEROS.
      *
      *--- AREA DE TRABALHO -------------------------------------------
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-RESP2            PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-CAMPO-ERRO       PIC X(010) VALUE SPACES.
           05  WS-ACAO             PIC X(001) VALUE SPACES.
           05  WS-MATRICULA        PIC 9(008) VALUE ZEROS.
           05  WS-SALARIO-MINIMO   PIC 9(007)V99 VALUE ZEROS.
           05  WS-SAL-HORA-MINIMO  PIC 9(007)V99 VALUE ZEROS.
           05  WS-MARGEM-CONSIG    PIC 9(007)V99 VALUE ZEROS.
           05  WS-COMPET-ATUAL     PIC 9(006) VALUE ZEROS.
           05  WS-QTD-MOVIMENTO    PIC S9(009) COMP VALUE ZEROS.
           05  WS-QTD-CPF          PIC S9(009) COMP VALUE ZEROS.
           05  WS-IDADE-ADMISSAO   PIC S9(007) VALUE ZEROS.
           05  WS-DATA-HOJE        PIC 9(008) VALUE ZEROS.
           05  WS-HORA-ABS         PIC S9(015) COMP-3 VALUE ZEROS.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-LINHA-CURSOR     PIC S9(004) COMP VALUE ZEROS.
           05  WS-COL-CURSOR       PIC S9(004) COMP VALUE ZEROS.
           05  WS-INT-OK           PIC X(001) VALUE 'N'.
           05  WS-DOM-TIPO         PIC X(003) VALUE SPACES.
           05  WS-DOM-CODIGO       PIC X(006) VALUE SPACES.
           05  WS-DOM-DESCR        PIC X(035) VALUE SPACES.
           05  WS-DOM-OK           PIC X(001) VALUE 'N'.
           05  WS-UF-CONS          PIC X(002) VALUE SPACES.
           05  WS-UF-OK            PIC X(001) VALUE 'N'.
           05  WS-UF-NOME          PIC X(025) VALUE SPACES.
           05  WS-MUN-CONS         PIC 9(007) VALUE ZEROS.
           05  WS-MUN-OK           PIC X(001) VALUE 'N'.
           05  WS-MUN-NOME         PIC X(040) VALUE SPACES.
           05  WS-MUN-UF           PIC X(002) VALUE SPACES.
           05  WS-EST-CONS         PIC 9(004) VALUE ZEROS.
           05  WS-EST-OK           PIC X(001) VALUE 'N'.
           05  WS-EST-NOME         PIC X(040) VALUE SPACES.
           05  WS-TS-FILA          PIC X(008) VALUE SPACES.
           05  WS-TS-TAM           PIC S9(004) COMP VALUE ZEROS.
           05  WS-CAMPO-ERRO       PIC X(008) VALUE SPACES.
      *
      *--- CAMPOS NUMERICOS CONVERTIDOS DA TELA -----------------------
       01  WS-CAMPOS-EDIT.
           05  WS-EDT-MATRICULA    PIC 9(008) VALUE ZEROS.
           05  WS-EDT-CPF          PIC 9(011) VALUE ZEROS.
           05  WS-EDT-PIS          PIC 9(011) VALUE ZEROS.
           05  WS-EDT-DT-NASC      PIC 9(008) VALUE ZEROS.
           05  WS-EDT-DT-ADM       PIC 9(008) VALUE ZEROS.
           05  WS-EDT-DT-DEM       PIC 9(008) VALUE ZEROS.
           05  WS-EDT-CARGO        PIC 9(004) VALUE ZEROS.
           05  WS-EDT-DEPTO        PIC 9(004) VALUE ZEROS.
           05  WS-EDT-CCUSTO       PIC 9(006) VALUE ZEROS.
           05  WS-EDT-CARGA-HOR    PIC 9(003) VALUE ZEROS.
           05  WS-EDT-DEP-IRRF     PIC 9(002) VALUE ZEROS.
           05  WS-EDT-DEP-SFAM     PIC 9(002) VALUE ZEROS.
           05  WS-EDT-INSALUBRID   PIC 9(002) VALUE ZEROS.
           05  WS-EDT-BANCO        PIC 9(003) VALUE ZEROS.
           05  WS-EDT-AGENCIA      PIC 9(005) VALUE ZEROS.
           05  WS-EDT-CONTA        PIC 9(012) VALUE ZEROS.
      *
      *--- DES-EDICAO DOS CAMPOS DIGITADOS NA SEGUNDA TELA (VER 7400) -
       01  WS-EDIT.
           05  WS-ED-CAMPO         PIC X(020) VALUE SPACES.
           05  WS-ED-COMPACTO      PIC X(020) VALUE SPACES.
           05  WS-ED-TAM           PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VIRGULA       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-INVALIDOS     PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-OK            PIC X(001) VALUE 'S'.
           05  WS-ED-INT-X         PIC X(014) VALUE SPACES.
           05  WS-ED-INT           PIC 9(014) VALUE ZEROS.
           05  WS-ED-CENT-X        PIC X(004) VALUE SPACES.
           05  WS-ED-CENT          PIC 9(004) VALUE ZEROS.
           05  WS-ED-TAM-INT       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-TAM-DEC       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VALOR         PIC 9(014)V9999 VALUE ZEROS.
           05  WS-ED-LIMITE        PIC 9(014) VALUE ZEROS.
      *
      *--- ESTADO DAS DUAS TELAS - VIVE NA FILA TEMPORARIA -----------
      * 500 BYTES: NAO CABEM NOS 326 QUE RESTAM DA COM-AREA-TRABALHO  *
      * DEPOIS DO SFPWLOK. MESMA SOLUCAO DO SFP0130.                  *
       01  WS-ESTADO.
           05  WS-ES-TELA          PIC X(001) VALUE '1'.
               88  WS-NA-TELA-1        VALUE '1'.
               88  WS-NA-TELA-2        VALUE '2'.
           05  WS-ES-COMPL-NOVO    PIC X(001) VALUE 'S'.
           05  WS-ES-MATRIC        PIC 9(008) VALUE ZEROS.
           05  WS-ES-NOME          PIC X(040) VALUE SPACES.
      *--- COPIA CRUA DOS CAMPOS DA PRIMEIRA TELA (206 BYTES) --------
           05  WS-ES-T1.
               10  WS-T1-MATRIC    PIC X(008).
               10  WS-T1-ACAO      PIC X(001).
               10  WS-T1-NOME      PIC X(040).
               10  WS-T1-CPF       PIC X(011).
               10  WS-T1-PIS       PIC X(011).
               10  WS-T1-DTNASC    PIC X(008).
               10  WS-T1-DTADM     PIC X(008).
               10  WS-T1-DTDEM     PIC X(008).
               10  WS-T1-SITUAC    PIC X(001).
               10  WS-T1-CARGO     PIC X(004).
               10  WS-T1-DEPTO     PIC X(004).
               10  WS-T1-CCUSTO    PIC X(006).
               10  WS-T1-SALARIO   PIC 9(009)V99.
               10  WS-T1-TPSAL     PIC X(001).
               10  WS-T1-CARGAH    PIC X(003).
               10  WS-T1-DEPIRF    PIC X(002).
               10  WS-T1-DEPSFA    PIC X(002).
               10  WS-T1-INSALU    PIC X(002).
               10  WS-T1-PERICU    PIC X(001).
               10  WS-T1-INDVT     PIC X(001).
               10  WS-T1-VLRVT     PIC 9(007)V99.
               10  WS-T1-INDVR     PIC X(001).
               10  WS-T1-VLRVR     PIC 9(007)V99.
               10  WS-T1-INDPS     PIC X(001).
               10  WS-T1-VLRPS     PIC 9(007)V99.
               10  WS-T1-PERPEN    PIC 9(003)V99.
               10  WS-T1-VLRPEN    PIC 9(007)V99.
               10  WS-T1-VLRCON    PIC 9(007)V99.
               10  WS-T1-BANCO     PIC X(003).
               10  WS-T1-AGENCIA   PIC X(005).
               10  WS-T1-CONTA     PIC X(012).
               10  WS-T1-DIGCTA    PIC X(001).
      *--- CAMPOS DA SEGUNDA TELA, JA CRITICADOS (244 BYTES) ---------
           05  WS-ES-T2.
               10  WS-T2-SEXO      PIC X(001).
               10  WS-T2-ECIV      PIC X(001).
               10  WS-T2-RACA      PIC 9(002).
               10  WS-T2-NACION    PIC 9(003).
               10  WS-T2-INSTRU    PIC 9(002).
               10  WS-T2-UFNASC    PIC X(002).
               10  WS-T2-MUNNAS    PIC 9(007).
               10  WS-T2-NOMEMA    PIC X(040).
               10  WS-T2-DEFIC     PIC X(001).
               10  WS-T2-TPDEF     PIC 9(002).
               10  WS-T2-CTPSNR    PIC 9(008).
               10  WS-T2-CTPSSE    PIC 9(005).
               10  WS-T2-CTPSUF    PIC X(002).
               10  WS-T2-RGNUM     PIC X(015).
               10  WS-T2-RGORG     PIC X(008).
               10  WS-T2-TITELE    PIC 9(012).
               10  WS-T2-TPLOGR    PIC X(003).
               10  WS-T2-LOGRAD    PIC X(040).
               10  WS-T2-NUMERO    PIC X(008).
               10  WS-T2-COMPLE    PIC X(015).
               10  WS-T2-BAIRRO    PIC X(025).
               10  WS-T2-CEP       PIC 9(008).
               10  WS-T2-MUNIC     PIC 9(007).
               10  WS-T2-UF        PIC X(002).
               10  WS-T2-TELEF     PIC X(014).
               10  WS-T2-ESTAB     PIC 9(004).
               10  WS-T2-VINCUL    PIC 9(002).
               10  WS-T2-JORNAD    PIC 9(002).
               10  WS-T2-HORARI    PIC 9(003).
      *
      *--- AREA DE COMUNICACAO COM O UTILITARIO -----------------------
       01  AREA-UTILITARIOS-WS.
           COPY SFPWUTL.
      *
      *--- DATAS FORMATADAS PARA O DB2 --------------------------------
       01  WS-DATA-DB2.
           05  WS-DB2-ANO          PIC 9(004).
           05  FILLER              PIC X(001) VALUE '-'.
           05  WS-DB2-MES          PIC 9(002).
           05  FILLER              PIC X(001) VALUE '-'.
           05  WS-DB2-DIA          PIC 9(002).
      *
       01  WS-DATA-8.
           05  WS-D8-ANO           PIC 9(004).
           05  WS-D8-MES           PIC 9(002).
           05  WS-D8-DIA           PIC 9(002).
      *
      *--- COMMAREA DA TRANSACAO --------------------------------------
       COPY SFPWCOM.
      *
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
      *
           EXEC CICS HANDLE ABEND
                LABEL(9999-ABEND)
           END-EXEC
      *
      *    NOME DA FILA TEMPORARIA QUE GUARDA O ESTADO DAS DUAS TELAS
           MOVE SPACES                 TO WS-TS-FILA
           MOVE 'S01'                  TO WS-TS-FILA(1:3)
           MOVE EIBTRMID               TO WS-TS-FILA(4:4)
      *
      *    PRIMEIRO ACIONAMENTO DA TRANSACAO: APRESENTA A TELA LIMPA
           IF EIBCALEN = ZEROS
               PERFORM 1000-PRIMEIRA-VEZ
           ELSE
               MOVE DFHCOMMAREA        TO COMMAREA-SFP
               MOVE COM-AREA-TRABALHO
                    (1:LENGTH OF AREA-LOOKUP) TO AREA-LOOKUP
               PERFORM 1200-LER-ESTADO
      *
      *        RETORNO DA JANELA DE CONSULTA (SFP0900)
               IF LOK-PGM-CHAMADOR = WS-PROGRAMA
                  AND NOT LOK-EM-CURSO
                   PERFORM 1100-VOLTA-DO-LOOKUP
               ELSE
                   PERFORM 2000-PROCESSAR-TECLA
               END-IF
           END-IF
      *
           PERFORM 8000-RETORNAR.
       0000-FIM.
           EXIT.
      *
      *================================================================*
      * 1000 - PRIMEIRO ACIONAMENTO                                    *
      *================================================================*
       1000-PRIMEIRA-VEZ SECTION.
       1000-INICIO.
           INITIALIZE COMMAREA-SFP
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE EIBTRMID               TO COM-TERMINAL
           SET COM-PRIMEIRA-VEZ        TO TRUE
           INITIALIZE AREA-LOOKUP
           INITIALIZE WS-ESTADO
           MOVE '1'                    TO WS-ES-TELA
           MOVE 'S'                    TO WS-ES-COMPL-NOVO
           PERFORM 1400-APAGAR-ESTADO
           PERFORM 7100-CARREGAR-PARAMETROS
           PERFORM 6000-LIMPAR-MAPA
           MOVE 'INFORME A MATRICULA E A ACAO DESEJADA'
                                       TO MENSAGO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - RETORNO DA JANELA F4 (SFP0900)                          *
      *                                                                *
      * O SFP0900 DEVOLVE O CONTROLE POR XCTL: E UMA NOVA ENTRADA NO   *
      * PROGRAMA, LOGO A TELA E REMONTADA A PARTIR DO WS-ESTADO.       *
      * LOK-CAMPO-ORIGEM DIZ QUAL CAMPO PEDIU A JANELA.                *
      *----------------------------------------------------------------*
       1100-VOLTA-DO-LOOKUP SECTION.
       1100-INICIO.
           IF LOK-SELECIONOU
               PERFORM 1150-APLICAR-SELECAO
           END-IF
      *
           MOVE SPACES                 TO LOK-PGM-CHAMADOR
           SET LOK-EM-CURSO            TO TRUE
      *
           IF WS-NA-TELA-2
               PERFORM 6300-LIMPAR-MAPA-2
               PERFORM 3400-MOVER-PARA-TELA-2
               PERFORM 3450-DESCREVER-TELA-2
               MOVE 'SELECAO APLICADA - CONFIRME COM ENTER'
                                       TO MENSA2O
               PERFORM 6400-ENVIAR-MAPA-2
           ELSE
               PERFORM 6000-LIMPAR-MAPA
               PERFORM 3040-MAPA-DO-SNAPSHOT
               MOVE 'SELECAO APLICADA - CONFIRME COM ENTER'
                                       TO MENSAGO
               PERFORM 6100-ENVIAR-MAPA-ERASE
           END-IF.
       1100-FIM.
           EXIT.
      *
      *--- APLICACAO DO CODIGO ESCOLHIDO NO CAMPO DE ORIGEM -----------
       1150-APLICAR-SELECAO SECTION.
       1150-INICIO.
           EVALUATE LOK-CAMPO-ORIGEM
               WHEN 'SITUAC'
                    MOVE LOK-COD-SELECIONADO(1:1)
                                       TO WS-T1-SITUAC
               WHEN 'CARGO'
                    MOVE LOK-COD-SELECIONADO(1:4)
                                       TO WS-T1-CARGO
               WHEN 'DEPTO'
                    MOVE LOK-COD-SELECIONADO(1:4)
                                       TO WS-T1-DEPTO
               WHEN 'TPSAL'
                    MOVE LOK-COD-SELECIONADO(1:1)
                                       TO WS-T1-TPSAL
               WHEN 'BANCO'
                    MOVE LOK-COD-SELECIONADO(1:3)
                                       TO WS-T1-BANCO
               WHEN 'SEXO'
                    MOVE LOK-COD-SELECIONADO(1:1)
                                       TO WS-T2-SEXO
               WHEN 'ECIV'
                    MOVE LOK-COD-SELECIONADO(1:1)
                                       TO WS-T2-ECIV
               WHEN 'RACA'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 99 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-RACA
                    END-IF
               WHEN 'NACION'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 999 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-NACION
                    END-IF
               WHEN 'INSTRU'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 99 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-INSTRU
                    END-IF
               WHEN 'UFNASC'
                    MOVE LOK-COD-SELECIONADO(1:2)
                                       TO WS-T2-UFNASC
               WHEN 'MUNNAS'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 9999999 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-MUNNAS
                    END-IF
               WHEN 'TPDEF'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 99 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-TPDEF
                    END-IF
               WHEN 'CTPSUF'
                    MOVE LOK-COD-SELECIONADO(1:2)
                                       TO WS-T2-CTPSUF
               WHEN 'TPLOGR'
                    MOVE LOK-COD-SELECIONADO(1:3)
                                       TO WS-T2-TPLOGR
               WHEN 'MUNIC'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 9999999 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-MUNIC
                    END-IF
               WHEN 'UF'
                    MOVE LOK-COD-SELECIONADO(1:2)
                                       TO WS-T2-UF
               WHEN 'ESTAB'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 9999 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-ESTAB
                    END-IF
               WHEN 'VINCUL'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 99 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-VINCUL
                    END-IF
               WHEN 'JORNAD'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 99 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-JORNAD
                    END-IF
               WHEN 'HORARI'
                    MOVE SPACES        TO WS-ED-CAMPO
                    MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                    MOVE 999 TO WS-ED-LIMITE
                    PERFORM 3060-INTEIRO-DA-TELA
                    IF WS-INT-OK = 'S'
                        MOVE WS-ED-VALOR
                                       TO WS-T2-HORARI
                    END-IF
               WHEN OTHER
                    CONTINUE
           END-EVALUATE.
       1150-FIM.
           EXIT.
      *
      *--- ESTADO DAS DUAS TELAS EM FILA TEMPORARIA (VER SFP0130) -----
       1200-LER-ESTADO SECTION.
       1200-INICIO.
           INITIALIZE WS-ESTADO
           MOVE LENGTH OF WS-ESTADO    TO WS-TS-TAM
      *
           EXEC CICS READQ TS
                QUEUE(WS-TS-FILA) INTO(WS-ESTADO)
                LENGTH(WS-TS-TAM) ITEM(1) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               INITIALIZE WS-ESTADO
               MOVE '1'                TO WS-ES-TELA
           END-IF.
       1200-FIM.
           EXIT.
      *
       1300-GRAVAR-ESTADO SECTION.
       1300-INICIO.
           EXEC CICS DELETEQ TS
                QUEUE(WS-TS-FILA) RESP(WS-RESP)
           END-EXEC
      *
           EXEC CICS WRITEQ TS
                QUEUE(WS-TS-FILA) FROM(WS-ESTADO)
                LENGTH(LENGTH OF WS-ESTADO) MAIN
                RESP(WS-RESP)
           END-EXEC.
       1300-FIM.
           EXIT.
      *
       1400-APAGAR-ESTADO SECTION.
       1400-INICIO.
           EXEC CICS DELETEQ TS
                QUEUE(WS-TS-FILA) RESP(WS-RESP)
           END-EXEC.
       1400-FIM.
           EXIT.
      *================================================================*
      * 2000 - TRATAMENTO DA TECLA ACIONADA                            *
      *================================================================*
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           IF WS-NA-TELA-2
               PERFORM 2200-TECLA-TELA-2
               GO TO 2000-FIM
           END-IF
      *
           EVALUATE EIBAID
      *
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR-TRANSACAO
      *
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
      *
               WHEN DFHPF5
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3100-CONSULTAR
      *
               WHEN DFHPF6
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-GRAVAR
      *
               WHEN DFHPF4
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4900-CHAMAR-LOOKUP
      *
               WHEN DFHPF8
                    PERFORM 5800-CHAMAR-DEPENDENTES
      *
               WHEN DFHPF9
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 5700-IR-TELA-2
      *
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 2100-EXECUTAR-ACAO
      *
               WHEN OTHER
                    MOVE 'TECLA INVALIDA PARA ESTA TRANSACAO'
                                       TO MENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
       2100-EXECUTAR-ACAO SECTION.
       2100-INICIO.
           EVALUATE WS-ACAO
               WHEN 'C' PERFORM 3100-CONSULTAR
               WHEN 'I' PERFORM 4000-GRAVAR
               WHEN 'A' PERFORM 4000-GRAVAR
               WHEN 'E' PERFORM 5000-EXCLUIR
               WHEN OTHER
                    MOVE 'ACAO INVALIDA. USE C, I, A OU E'
                                       TO MENSAGO
                    MOVE DFHBMBRY      TO ACAOA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 2200 - TECLAS DA SEGUNDA TELA (DADOS PESSOAIS)                 *
      *----------------------------------------------------------------*
       2200-TECLA-TELA-2 SECTION.
       2200-INICIO.
           EVALUATE EIBAID
      *
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR-TRANSACAO
      *
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
      *
               WHEN DFHPF4
                    PERFORM 3300-RECEBER-MAPA-2
                    PERFORM 4900-CHAMAR-LOOKUP
      *
               WHEN DFHPF6
                    PERFORM 3300-RECEBER-MAPA-2
                    PERFORM 4700-GRAVAR-COMPL
      *
               WHEN DFHPF9
                    PERFORM 3300-RECEBER-MAPA-2
                    PERFORM 5750-VOLTAR-TELA-1
      *
               WHEN DFHENTER
                    PERFORM 3300-RECEBER-MAPA-2
                    PERFORM 4600-VALIDAR-TELA-2
                    PERFORM 6300-LIMPAR-MAPA-2
                    PERFORM 3400-MOVER-PARA-TELA-2
                    PERFORM 3450-DESCREVER-TELA-2
                    IF TEM-ERRO
                        PERFORM 6350-MARCAR-CAMPO-ERRO
                        MOVE WS-MENSAGEM
                                       TO MENSA2O
                    ELSE
                        MOVE 'DADOS CONFERIDOS - F6 GRAVA OS PESSOAIS'
                                       TO MENSA2O
                    END-IF
                    PERFORM 6400-ENVIAR-MAPA-2
      *
               WHEN OTHER
                    MOVE 'TECLA INVALIDA NOS DADOS PESSOAIS'
                                       TO MENSA2O
                    PERFORM 6400-ENVIAR-MAPA-2
           END-EVALUATE.
       2200-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - RECEPCAO E CONVERSAO DOS CAMPOS DA TELA                 *
      *================================================================*
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                INTO(MAPEMPI)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO NA RECEPCAO DO MAPA'
                                       TO MENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE 'N'                    TO WS-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
      *
           MOVE SPACES                 TO WS-CAMPO-ERRO
      *
      *    O FRSET SO DEVOLVE OS CAMPOS DIGITADOS: A MESCLA REPOE OS
      *    DEMAIS A PARTIR DA COPIA GUARDADA NA FILA TEMPORARIA
           PERFORM 3020-MESCLAR-TELA-1
      *
           MOVE FUNCTION UPPER-CASE(WS-T1-ACAO)
                                       TO WS-ACAO
      *
           PERFORM 3010-CONVERTER-NUMERICOS.
       3000-FIM.
           EXIT.
      *
      *--- CONVERSAO SEGURA DE CAMPOS ALFANUMERICOS PARA NUMERICOS ----
       3010-CONVERTER-NUMERICOS SECTION.
       3010-INICIO.
           INITIALIZE WS-CAMPOS-EDIT
      *
           IF MATRICI NUMERIC
               MOVE MATRICI            TO WS-EDT-MATRICULA
                                          WS-MATRICULA
           END-IF
           IF CPFI     NUMERIC MOVE CPFI     TO WS-EDT-CPF       END-IF
           IF PISI     NUMERIC MOVE PISI     TO WS-EDT-PIS       END-IF
           IF DTNASCI  NUMERIC MOVE DTNASCI  TO WS-EDT-DT-NASC   END-IF
           IF DTADMI   NUMERIC MOVE DTADMI   TO WS-EDT-DT-ADM    END-IF
           IF DTDEMI   NUMERIC MOVE DTDEMI   TO WS-EDT-DT-DEM    END-IF
           IF CARGOI   NUMERIC MOVE CARGOI   TO WS-EDT-CARGO     END-IF
           IF DEPTOI   NUMERIC MOVE DEPTOI   TO WS-EDT-DEPTO     END-IF
           IF CCUSTOI  NUMERIC MOVE CCUSTOI  TO WS-EDT-CCUSTO    END-IF
           IF CARGAHI  NUMERIC MOVE CARGAHI  TO WS-EDT-CARGA-HOR END-IF
           IF DEPIRFI  NUMERIC MOVE DEPIRFI  TO WS-EDT-DEP-IRRF  END-IF
           IF DEPSFAI  NUMERIC MOVE DEPSFAI  TO WS-EDT-DEP-SFAM  END-IF
           IF INSALUI  NUMERIC MOVE INSALUI  TO WS-EDT-INSALUBRID
           END-IF
           IF BANCOI   NUMERIC MOVE BANCOI   TO WS-EDT-BANCO     END-IF
           IF AGENCIAI NUMERIC MOVE AGENCIAI TO WS-EDT-AGENCIA   END-IF
           IF CONTAI   NUMERIC MOVE CONTAI   TO WS-EDT-CONTA     END-IF.
       3010-FIM.
           EXIT.
      *
      *
      *--- MESCLA DA DIGITACAO NOVA COM A COPIA GUARDADA DA TELA 1 ----
      * COM CTRL=(FREEKB,FRSET) SO VOLTAM DO RECEIVE OS CAMPOS QUE O   *
      * USUARIO TOCOU. SEM ESTA MESCLA, ALTERAR UM CAMPO APAGARIA OS   *
      * DEMAIS E O IDA-E-VOLTA DO F4 PERDERIA A TELA INTEIRA.          *
       3020-MESCLAR-TELA-1 SECTION.
       3020-INICIO.
           IF MATRICL > ZEROS     MOVE MATRICI TO WS-T1-MATRIC
           ELSE                   MOVE WS-T1-MATRIC TO MATRICI
           END-IF
           IF ACAOL > ZEROS       MOVE ACAOI TO WS-T1-ACAO
           ELSE                   MOVE WS-T1-ACAO TO ACAOI
           END-IF
           IF NOMEL > ZEROS       MOVE NOMEI TO WS-T1-NOME
           ELSE                   MOVE WS-T1-NOME TO NOMEI
           END-IF
           IF CPFL > ZEROS        MOVE CPFI TO WS-T1-CPF
           ELSE                   MOVE WS-T1-CPF TO CPFI
           END-IF
           IF PISL > ZEROS        MOVE PISI TO WS-T1-PIS
           ELSE                   MOVE WS-T1-PIS TO PISI
           END-IF
           IF DTNASCL > ZEROS     MOVE DTNASCI TO WS-T1-DTNASC
           ELSE                   MOVE WS-T1-DTNASC TO DTNASCI
           END-IF
           IF DTADML > ZEROS      MOVE DTADMI TO WS-T1-DTADM
           ELSE                   MOVE WS-T1-DTADM TO DTADMI
           END-IF
           IF DTDEML > ZEROS      MOVE DTDEMI TO WS-T1-DTDEM
           ELSE                   MOVE WS-T1-DTDEM TO DTDEMI
           END-IF
           IF SITUACL > ZEROS     MOVE SITUACI TO WS-T1-SITUAC
           ELSE                   MOVE WS-T1-SITUAC TO SITUACI
           END-IF
           IF CARGOL > ZEROS      MOVE CARGOI TO WS-T1-CARGO
           ELSE                   MOVE WS-T1-CARGO TO CARGOI
           END-IF
           IF DEPTOL > ZEROS      MOVE DEPTOI TO WS-T1-DEPTO
           ELSE                   MOVE WS-T1-DEPTO TO DEPTOI
           END-IF
           IF CCUSTOL > ZEROS     MOVE CCUSTOI TO WS-T1-CCUSTO
           ELSE                   MOVE WS-T1-CCUSTO TO CCUSTOI
           END-IF
           IF SALARIOL > ZEROS    MOVE SALARIOI TO WS-T1-SALARIO
           ELSE                   MOVE WS-T1-SALARIO TO SALARIOI
           END-IF
           IF TPSALL > ZEROS      MOVE TPSALI TO WS-T1-TPSAL
           ELSE                   MOVE WS-T1-TPSAL TO TPSALI
           END-IF
           IF CARGAHL > ZEROS     MOVE CARGAHI TO WS-T1-CARGAH
           ELSE                   MOVE WS-T1-CARGAH TO CARGAHI
           END-IF
           IF DEPIRFL > ZEROS     MOVE DEPIRFI TO WS-T1-DEPIRF
           ELSE                   MOVE WS-T1-DEPIRF TO DEPIRFI
           END-IF
           IF DEPSFAL > ZEROS     MOVE DEPSFAI TO WS-T1-DEPSFA
           ELSE                   MOVE WS-T1-DEPSFA TO DEPSFAI
           END-IF
           IF INSALUL > ZEROS     MOVE INSALUI TO WS-T1-INSALU
           ELSE                   MOVE WS-T1-INSALU TO INSALUI
           END-IF
           IF PERICUL > ZEROS     MOVE PERICUI TO WS-T1-PERICU
           ELSE                   MOVE WS-T1-PERICU TO PERICUI
           END-IF
           IF INDVTL > ZEROS      MOVE INDVTI TO WS-T1-INDVT
           ELSE                   MOVE WS-T1-INDVT TO INDVTI
           END-IF
           IF VLRVTL > ZEROS      MOVE VLRVTI TO WS-T1-VLRVT
           ELSE                   MOVE WS-T1-VLRVT TO VLRVTI
           END-IF
           IF INDVRL > ZEROS      MOVE INDVRI TO WS-T1-INDVR
           ELSE                   MOVE WS-T1-INDVR TO INDVRI
           END-IF
           IF VLRVRL > ZEROS      MOVE VLRVRI TO WS-T1-VLRVR
           ELSE                   MOVE WS-T1-VLRVR TO VLRVRI
           END-IF
           IF INDPSL > ZEROS      MOVE INDPSI TO WS-T1-INDPS
           ELSE                   MOVE WS-T1-INDPS TO INDPSI
           END-IF
           IF VLRPSL > ZEROS      MOVE VLRPSI TO WS-T1-VLRPS
           ELSE                   MOVE WS-T1-VLRPS TO VLRPSI
           END-IF
           IF PERPENL > ZEROS     MOVE PERPENI TO WS-T1-PERPEN
           ELSE                   MOVE WS-T1-PERPEN TO PERPENI
           END-IF
           IF VLRPENL > ZEROS     MOVE VLRPENI TO WS-T1-VLRPEN
           ELSE                   MOVE WS-T1-VLRPEN TO VLRPENI
           END-IF
           IF VLRCONL > ZEROS     MOVE VLRCONI TO WS-T1-VLRCON
           ELSE                   MOVE WS-T1-VLRCON TO VLRCONI
           END-IF
           IF BANCOL > ZEROS      MOVE BANCOI TO WS-T1-BANCO
           ELSE                   MOVE WS-T1-BANCO TO BANCOI
           END-IF
           IF AGENCIAL > ZEROS    MOVE AGENCIAI TO WS-T1-AGENCIA
           ELSE                   MOVE WS-T1-AGENCIA TO AGENCIAI
           END-IF
           IF CONTAL > ZEROS      MOVE CONTAI TO WS-T1-CONTA
           ELSE                   MOVE WS-T1-CONTA TO CONTAI
           END-IF
           IF DIGCTAL > ZEROS     MOVE DIGCTAI TO WS-T1-DIGCTA
           ELSE                   MOVE WS-T1-DIGCTA TO DIGCTAI
           END-IF
           CONTINUE.
       3020-FIM.
           EXIT.
      *
      *--- REMONTAGEM DA TELA 1 A PARTIR DA COPIA GUARDADA -------------
      * MAPEMPI E MAPEMPO NAO COMPARTILHAM BYTES (OS CAMPOS DE VALOR   *
      * TEM PICOUT MAIOR QUE O LENGTH), LOGO A VOLTA E CAMPO A CAMPO.  *
       3040-MAPA-DO-SNAPSHOT SECTION.
       3040-INICIO.
           MOVE WS-T1-MATRIC           TO MATRICO
           MOVE WS-T1-ACAO             TO ACAOO
           MOVE WS-T1-NOME             TO NOMEO
           MOVE WS-T1-CPF              TO CPFO
           MOVE WS-T1-PIS              TO PISO
           MOVE WS-T1-DTNASC           TO DTNASCO
           MOVE WS-T1-DTADM            TO DTADMO
           MOVE WS-T1-DTDEM            TO DTDEMO
           MOVE WS-T1-SITUAC           TO SITUACO
           MOVE WS-T1-CARGO            TO CARGOO
           MOVE WS-T1-DEPTO            TO DEPTOO
           MOVE WS-T1-CCUSTO           TO CCUSTOO
           MOVE WS-T1-SALARIO          TO SALARIOO
           MOVE WS-T1-TPSAL            TO TPSALO
           MOVE WS-T1-CARGAH           TO CARGAHO
           MOVE WS-T1-DEPIRF           TO DEPIRFO
           MOVE WS-T1-DEPSFA           TO DEPSFAO
           MOVE WS-T1-INSALU           TO INSALUO
           MOVE WS-T1-PERICU           TO PERICUO
           MOVE WS-T1-INDVT            TO INDVTO
           MOVE WS-T1-VLRVT            TO VLRVTO
           MOVE WS-T1-INDVR            TO INDVRO
           MOVE WS-T1-VLRVR            TO VLRVRO
           MOVE WS-T1-INDPS            TO INDPSO
           MOVE WS-T1-VLRPS            TO VLRPSO
           MOVE WS-T1-PERPEN           TO PERPENO
           MOVE WS-T1-VLRPEN           TO VLRPENO
           MOVE WS-T1-VLRCON           TO VLRCONO
           MOVE WS-T1-BANCO            TO BANCOO
           MOVE WS-T1-AGENCIA          TO AGENCIAO
           MOVE WS-T1-CONTA            TO CONTAO
           MOVE WS-T1-DIGCTA           TO DIGCTAO
           CONTINUE.
       3040-FIM.
           EXIT.
      *
      *--- CAMPO INTEIRO DIGITADO NA TELA (VER 7400-DE-EDITAR) ---------
       3060-INTEIRO-DA-TELA SECTION.
       3060-INICIO.
           MOVE 'N'                    TO WS-INT-OK
           PERFORM 7400-DE-EDITAR
           IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
              AND WS-ED-VALOR <= WS-ED-LIMITE
               MOVE 'S'                TO WS-INT-OK
           END-IF.
       3060-FIM.
           EXIT.
      *

      *--- COPIA DA TELA RECEM-MONTADA PARA A AREA DE ESTADO --------
      * DEPOIS DE UMA CONSULTA A COPIA GUARDADA TEM DE REFLETIR O    *
      * QUE FOI APRESENTADO, SENAO O F4 OU O F9 SEGUINTE DEVOLVERIA  *
      * A TELA EM BRANCO. OS CAMPOS DE VALOR SAO NUMERICO-EDITADOS   *
      * NA SAIDA, LOGO O MOVE PARA ITEM NUMERICO OS DES-EDITA.       *
       3030-SNAPSHOT-DA-CONSULTA SECTION.
       3030-INICIO.
           MOVE WS-ACAO                TO WS-T1-ACAO
           MOVE MATRICO                TO WS-T1-MATRIC
           MOVE NOMEO                  TO WS-T1-NOME
           MOVE CPFO                   TO WS-T1-CPF
           MOVE PISO                   TO WS-T1-PIS
           MOVE DTNASCO                TO WS-T1-DTNASC
           MOVE DTADMO                 TO WS-T1-DTADM
           MOVE DTDEMO                 TO WS-T1-DTDEM
           MOVE SITUACO                TO WS-T1-SITUAC
           MOVE CARGOO                 TO WS-T1-CARGO
           MOVE DEPTOO                 TO WS-T1-DEPTO
           MOVE CCUSTOO                TO WS-T1-CCUSTO
           MOVE SALARIOO               TO WS-T1-SALARIO
           MOVE TPSALO                 TO WS-T1-TPSAL
           MOVE CARGAHO                TO WS-T1-CARGAH
           MOVE DEPIRFO                TO WS-T1-DEPIRF
           MOVE DEPSFAO                TO WS-T1-DEPSFA
           MOVE INSALUO                TO WS-T1-INSALU
           MOVE PERICUO                TO WS-T1-PERICU
           MOVE INDVTO                 TO WS-T1-INDVT
           MOVE VLRVTO                 TO WS-T1-VLRVT
           MOVE INDVRO                 TO WS-T1-INDVR
           MOVE VLRVRO                 TO WS-T1-VLRVR
           MOVE INDPSO                 TO WS-T1-INDPS
           MOVE VLRPSO                 TO WS-T1-VLRPS
           MOVE PERPENO                TO WS-T1-PERPEN
           MOVE VLRPENO                TO WS-T1-VLRPEN
           MOVE VLRCONO                TO WS-T1-VLRCON
           MOVE BANCOO                 TO WS-T1-BANCO
           MOVE AGENCIAO               TO WS-T1-AGENCIA
           MOVE CONTAO                 TO WS-T1-CONTA
           MOVE DIGCTAO                TO WS-T1-DIGCTA.
       3030-FIM.
           EXIT.
      *
      *================================================================*
      * 3100 - CONSULTA DE EMPREGADO                                   *
      *================================================================*
       3100-CONSULTAR SECTION.
       3100-INICIO.
           IF WS-MATRICULA = ZEROS
               MOVE 'MATRICULA OBRIGATORIA PARA A CONSULTA'
                                       TO MENSAGO
               MOVE DFHBMBRY           TO MATRICA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-MATRICULA           TO DCL-MATRICULA
      *
           EXEC SQL
                SELECT MATRICULA
                     , NOME
                     , CPF
                     , PIS
                     , CHAR(DT_ADMISSAO,ISO)
                     , CHAR(DT_DEMISSAO,ISO)
                     , CHAR(DT_NASCIMENTO,ISO)
                     , SITUACAO
                     , COD_CARGO
                     , COD_DEPTO
                     , CENTRO_CUSTO
                     , SALARIO_BASE
                     , TIPO_SALARIO
                     , CARGA_HOR_MES
                     , QTD_DEP_IRRF
                     , QTD_DEP_SALFAM
                     , PERC_INSALUBRID
                     , IND_PERICULOSID
                     , IND_VALE_TRANSP
                     , VLR_VALE_TRANSP
                     , IND_VALE_REFEIC
                     , VLR_VALE_REFEIC
                     , IND_PLANO_SAUDE
                     , VLR_PLANO_SAUDE
                     , PERC_PENSAO
                     , VLR_PENSAO_FIXO
                     , VLR_CONSIGNADO
                     , BANCO
                     , AGENCIA
                     , CONTA
                     , DIG_CONTA
                  INTO :DCL-MATRICULA
                     , :DCL-NOME
                     , :DCL-CPF
                     , :DCL-PIS
                     , :DCL-DT-ADMISSAO
                     , :DCL-DT-DEMISSAO :WS-IND-DT-DEMISSAO
                     , :DCL-DT-NASCIMENTO
                     , :DCL-SITUACAO
                     , :DCL-COD-CARGO
                     , :DCL-COD-DEPTO
                     , :DCL-CENTRO-CUSTO
                     , :DCL-SALARIO-BASE
                     , :DCL-TIPO-SALARIO
                     , :DCL-CARGA-HOR-MES
                     , :DCL-QTD-DEP-IRRF
                     , :DCL-QTD-DEP-SALFAM
                     , :DCL-PERC-INSALUBRID
                     , :DCL-IND-PERICULOSID
                     , :DCL-IND-VALE-TRANSP
                     , :DCL-VLR-VALE-TRANSP
                     , :DCL-IND-VALE-REFEIC
                     , :DCL-VLR-VALE-REFEIC
                     , :DCL-IND-PLANO-SAUDE
                     , :DCL-VLR-PLANO-SAUDE
                     , :DCL-PERC-PENSAO
                     , :DCL-VLR-PENSAO-FIXO
                     , :DCL-VLR-CONSIGNADO
                     , :DCL-BANCO
                     , :DCL-AGENCIA
                     , :DCL-CONTA
                     , :DCL-DIG-CONTA
                  FROM SFPADM.TB_EMPREGADO
                 WHERE MATRICULA = :DCL-MATRICULA
                  WITH CS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    PERFORM 3200-MOVER-PARA-TELA
                    MOVE 'CONSULTA EFETUADA COM SUCESSO'
                                       TO MENSAGO
                    PERFORM 6100-ENVIAR-MAPA-ERASE
      *
               WHEN +100
                    PERFORM 6000-LIMPAR-MAPA
                    INITIALIZE WS-ES-T1
                    MOVE WS-MATRICULA  TO MATRICO
                                          WS-T1-MATRIC
                    MOVE 'I'           TO ACAOO
                                          WS-T1-ACAO
                    MOVE 'MATRICULA NAO CADASTRADA - USE ACAO I'
                                       TO MENSAGO
                    PERFORM 6100-ENVIAR-MAPA-ERASE
      *
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       3100-FIM.
           EXIT.
      *
       3200-MOVER-PARA-TELA SECTION.
       3200-INICIO.
           MOVE DCL-MATRICULA          TO MATRICO
           MOVE DCL-NOME               TO NOMEO
           MOVE DCL-CPF                TO CPFO
           MOVE DCL-PIS                TO PISO
      *
           MOVE DCL-DT-ADMISSAO        TO WS-DATA-DB2
           PERFORM 7200-DB2-PARA-8
           MOVE WS-DATA-8              TO DTADMO
      *
           IF WS-IND-DT-DEMISSAO < ZEROS
               MOVE ZEROS              TO DTDEMO
           ELSE
               MOVE DCL-DT-DEMISSAO    TO WS-DATA-DB2
               PERFORM 7200-DB2-PARA-8
               MOVE WS-DATA-8          TO DTDEMO
           END-IF
      *
           MOVE DCL-DT-NASCIMENTO      TO WS-DATA-DB2
           PERFORM 7200-DB2-PARA-8
           MOVE WS-DATA-8              TO DTNASCO
      *
           MOVE DCL-SITUACAO           TO SITUACO
           MOVE DCL-COD-CARGO          TO CARGOO
           MOVE DCL-COD-DEPTO          TO DEPTOO
           MOVE DCL-CENTRO-CUSTO       TO CCUSTOO
           MOVE DCL-SALARIO-BASE       TO SALARIOO
           MOVE DCL-TIPO-SALARIO       TO TPSALO
           MOVE DCL-CARGA-HOR-MES      TO CARGAHO
           MOVE DCL-QTD-DEP-IRRF       TO DEPIRFO
           MOVE DCL-QTD-DEP-SALFAM     TO DEPSFAO
           MOVE DCL-PERC-INSALUBRID    TO INSALUO
           MOVE DCL-IND-PERICULOSID    TO PERICUO
           MOVE DCL-IND-VALE-TRANSP    TO INDVTO
           MOVE DCL-VLR-VALE-TRANSP    TO VLRVTO
           MOVE DCL-IND-VALE-REFEIC    TO INDVRO
           MOVE DCL-VLR-VALE-REFEIC    TO VLRVRO
           MOVE DCL-IND-PLANO-SAUDE    TO INDPSO
           MOVE DCL-VLR-PLANO-SAUDE    TO VLRPSO
           MOVE DCL-PERC-PENSAO        TO PERPENO
           MOVE DCL-VLR-PENSAO-FIXO    TO VLRPENO
           MOVE DCL-VLR-CONSIGNADO     TO VLRCONO
           MOVE DCL-BANCO              TO BANCOO
           MOVE DCL-AGENCIA            TO AGENCIAO
           MOVE DCL-CONTA              TO CONTAO
           MOVE DCL-DIG-CONTA          TO DIGCTAO
           PERFORM 3030-SNAPSHOT-DA-CONSULTA.
       3200-FIM.
           EXIT.
      *
      *================================================================*
      * 3300 - RECEPCAO DA SEGUNDA TELA                                *
      *================================================================*
       3300-RECEBER-MAPA-2 SECTION.
       3300-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA2)
                MAPSET(WS-MAPSET)
                INTO(MAPEMP2I)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO NA RECEPCAO DA SEGUNDA TELA'
                                       TO MENSA2O
               PERFORM 6400-ENVIAR-MAPA-2
           END-IF
      *
           MOVE 'N'                    TO WS-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
                                          WS-CAMPO-ERRO
      *
           PERFORM 3310-MESCLAR-TELA-2.
       3300-FIM.
           EXIT.
      *
      *--- SO OS CAMPOS DIGITADOS VOLTAM: OS DEMAIS FICAM COMO ESTAO --
       3310-MESCLAR-TELA-2 SECTION.
       3310-INICIO.
           IF SEXOL > ZEROS
               MOVE FUNCTION UPPER-CASE(SEXOI)
                                       TO WS-T2-SEXO
           END-IF
           IF ECIVL > ZEROS
               MOVE FUNCTION UPPER-CASE(ECIVI)
                                       TO WS-T2-ECIV
           END-IF
           IF RACAL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE RACAI
                                   TO WS-ED-CAMPO(1:2)
               MOVE 99              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-RACA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-RACA
               END-IF
           END-IF
           IF NACIONL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE NACIONI
                                   TO WS-ED-CAMPO(1:3)
               MOVE 999             TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-NACION
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-NACION
               END-IF
           END-IF
           IF INSTRUL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE INSTRUI
                                   TO WS-ED-CAMPO(1:2)
               MOVE 99              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-INSTRU
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-INSTRU
               END-IF
           END-IF
           IF UFNASCL > ZEROS
               MOVE FUNCTION UPPER-CASE(UFNASCI)
                                       TO WS-T2-UFNASC
           END-IF
           IF MUNNASL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE MUNNASI
                                   TO WS-ED-CAMPO(1:7)
               MOVE 9999999         TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-MUNNAS
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-MUNNAS
               END-IF
           END-IF
           IF NOMEMAL > ZEROS
               MOVE FUNCTION UPPER-CASE(NOMEMAI)
                                       TO WS-T2-NOMEMA
           END-IF
           IF DEFICL > ZEROS
               MOVE FUNCTION UPPER-CASE(DEFICI)
                                       TO WS-T2-DEFIC
           END-IF
           IF TPDEFL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE TPDEFI
                                   TO WS-ED-CAMPO(1:2)
               MOVE 99              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-TPDEF
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-TPDEF
               END-IF
           END-IF
           IF CTPSNRL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE CTPSNRI
                                   TO WS-ED-CAMPO(1:8)
               MOVE 99999999        TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-CTPSNR
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-CTPSNR
               END-IF
           END-IF
           IF CTPSSEL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE CTPSSEI
                                   TO WS-ED-CAMPO(1:5)
               MOVE 99999           TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-CTPSSE
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-CTPSSE
               END-IF
           END-IF
           IF CTPSUFL > ZEROS
               MOVE FUNCTION UPPER-CASE(CTPSUFI)
                                       TO WS-T2-CTPSUF
           END-IF
           IF RGNUML > ZEROS
               MOVE FUNCTION UPPER-CASE(RGNUMI)
                                       TO WS-T2-RGNUM
           END-IF
           IF RGORGL > ZEROS
               MOVE FUNCTION UPPER-CASE(RGORGI)
                                       TO WS-T2-RGORG
           END-IF
           IF TITELEL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE TITELEI
                                   TO WS-ED-CAMPO(1:12)
               MOVE 999999999999    TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-TITELE
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-TITELE
               END-IF
           END-IF
           IF TPLOGRL > ZEROS
               MOVE FUNCTION UPPER-CASE(TPLOGRI)
                                       TO WS-T2-TPLOGR
           END-IF
           IF LOGRADL > ZEROS
               MOVE FUNCTION UPPER-CASE(LOGRADI)
                                       TO WS-T2-LOGRAD
           END-IF
           IF NUMEROL > ZEROS
               MOVE FUNCTION UPPER-CASE(NUMEROI)
                                       TO WS-T2-NUMERO
           END-IF
           IF COMPLEL > ZEROS
               MOVE FUNCTION UPPER-CASE(COMPLEI)
                                       TO WS-T2-COMPLE
           END-IF
           IF BAIRROL > ZEROS
               MOVE FUNCTION UPPER-CASE(BAIRROI)
                                       TO WS-T2-BAIRRO
           END-IF
           IF CEPL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE CEPI
                                   TO WS-ED-CAMPO(1:8)
               MOVE 99999999        TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-CEP
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-CEP
               END-IF
           END-IF
           IF MUNICL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE MUNICI
                                   TO WS-ED-CAMPO(1:7)
               MOVE 9999999         TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-MUNIC
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-MUNIC
               END-IF
           END-IF
           IF UFL > ZEROS
               MOVE FUNCTION UPPER-CASE(UFI)
                                       TO WS-T2-UF
           END-IF
           IF TELEFL > ZEROS
               MOVE FUNCTION UPPER-CASE(TELEFI)
                                       TO WS-T2-TELEF
           END-IF
           IF ESTABL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE ESTABI
                                   TO WS-ED-CAMPO(1:4)
               MOVE 9999            TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-ESTAB
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-ESTAB
               END-IF
           END-IF
           IF VINCULL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE VINCULI
                                   TO WS-ED-CAMPO(1:2)
               MOVE 99              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-VINCUL
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-VINCUL
               END-IF
           END-IF
           IF JORNADL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE JORNADI
                                   TO WS-ED-CAMPO(1:2)
               MOVE 99              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-JORNAD
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-JORNAD
               END-IF
           END-IF
           IF HORARIL > ZEROS
               MOVE SPACES         TO WS-ED-CAMPO
               MOVE HORARII
                                   TO WS-ED-CAMPO(1:3)
               MOVE 999             TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               MOVE ZEROS          TO WS-T2-HORARI
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR
                                   TO WS-T2-HORARI
               END-IF
           END-IF
           CONTINUE.
       3310-FIM.
           EXIT.
      *
      *--- LEITURAS DOS CADASTROS DE APOIO PELO CICS -------------------
       3350-LER-DOMINIO SECTION.
       3350-INICIO.
           MOVE 'N'                    TO WS-DOM-OK
           MOVE SPACES                 TO WS-DOM-DESCR
      *
           MOVE WS-DOM-TIPO            TO DOM-TIPO
           MOVE WS-DOM-CODIGO          TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQ-DOMINIO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL) AND DOM-ATIVO
               MOVE 'S'                TO WS-DOM-OK
               MOVE DOM-DESCRICAO      TO WS-DOM-DESCR
           END-IF.
       3350-FIM.
           EXIT.
      *
       3360-LER-UF SECTION.
       3360-INICIO.
           MOVE 'N'                    TO WS-UF-OK
           MOVE SPACES                 TO WS-UF-NOME
           MOVE WS-UF-CONS             TO UFE-SIGLA
           EXEC CICS READ
                FILE(WS-ARQ-UF) INTO(REG-UF)
                RIDFLD(UFE-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL) AND UFE-SITUACAO = 'A'
               MOVE 'S'                TO WS-UF-OK
               MOVE UFE-NOME           TO WS-UF-NOME
           END-IF.
       3360-FIM.
           EXIT.
      *
       3370-LER-MUNICIPIO SECTION.
       3370-INICIO.
           MOVE 'N'                    TO WS-MUN-OK
           MOVE SPACES                 TO WS-MUN-NOME
                                          WS-MUN-UF
           MOVE WS-MUN-CONS            TO MUN-COD-IBGE
           EXEC CICS READ
                FILE(WS-ARQ-MUNICIPIO) INTO(REG-MUNICIPIO)
                RIDFLD(MUN-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               MOVE 'S'                TO WS-MUN-OK
               MOVE MUN-NOME           TO WS-MUN-NOME
               MOVE MUN-UF             TO WS-MUN-UF
           END-IF.
       3370-FIM.
           EXIT.
      *
       3380-LER-ESTABELEC SECTION.
       3380-INICIO.
           MOVE 'N'                    TO WS-EST-OK
           MOVE SPACES                 TO WS-EST-NOME
           MOVE WS-EST-CONS            TO EST-CODIGO
           EXEC CICS READ
                FILE(WS-ARQ-ESTABELEC) INTO(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL) AND EST-SITUACAO = 'A'
               MOVE 'S'                TO WS-EST-OK
               MOVE EST-NOME-FANTASIA  TO WS-EST-NOME
           END-IF.
       3380-FIM.
           EXIT.
      *
      *--- MONTAGEM DA SEGUNDA TELA A PARTIR DO ESTADO -----------------
       3400-MOVER-PARA-TELA-2 SECTION.
       3400-INICIO.
           MOVE WS-DATA-HOJE           TO DATA2O
           MOVE WS-ES-MATRIC           TO MATRI2O
           MOVE WS-ES-NOME             TO NOME2O
           MOVE WS-T2-SEXO             TO SEXOO
           MOVE WS-T2-ECIV             TO ECIVO
           MOVE WS-T2-RACA             TO RACAO
           MOVE WS-T2-NACION           TO NACIONO
           MOVE WS-T2-INSTRU           TO INSTRUO
           MOVE WS-T2-UFNASC           TO UFNASCO
           MOVE WS-T2-MUNNAS           TO MUNNASO
           MOVE WS-T2-NOMEMA           TO NOMEMAO
           MOVE WS-T2-DEFIC            TO DEFICO
           MOVE WS-T2-TPDEF            TO TPDEFO
           MOVE WS-T2-CTPSNR           TO CTPSNRO
           MOVE WS-T2-CTPSSE           TO CTPSSEO
           MOVE WS-T2-CTPSUF           TO CTPSUFO
           MOVE WS-T2-RGNUM            TO RGNUMO
           MOVE WS-T2-RGORG            TO RGORGO
           MOVE WS-T2-TITELE           TO TITELEO
           MOVE WS-T2-TPLOGR           TO TPLOGRO
           MOVE WS-T2-LOGRAD           TO LOGRADO
           MOVE WS-T2-NUMERO           TO NUMEROO
           MOVE WS-T2-COMPLE           TO COMPLEO
           MOVE WS-T2-BAIRRO           TO BAIRROO
           MOVE WS-T2-CEP              TO CEPO
           MOVE WS-T2-MUNIC            TO MUNICO
           MOVE WS-T2-UF               TO UFO
           MOVE WS-T2-TELEF            TO TELEFO
           MOVE WS-T2-ESTAB            TO ESTABO
           MOVE WS-T2-VINCUL           TO VINCULO
           MOVE WS-T2-JORNAD           TO JORNADO
           MOVE WS-T2-HORARI           TO HORARIO
           CONTINUE.
       3400-FIM.
           EXIT.
      *
      *--- DESCRICOES DOS CODIGOS DA SEGUNDA TELA ---------------------
       3450-DESCREVER-TELA-2 SECTION.
       3450-INICIO.
           MOVE 'SEX'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-SEXO             TO WS-DOM-CODIGO(1:1)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DSEXOO
      *
           MOVE 'ECI'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-ECIV             TO WS-DOM-CODIGO(1:1)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DECIVO
      *
           MOVE 'RAC'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-RACA             TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DRACAO
      *
           MOVE 'NAC'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-NACION           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DNACIOO
      *
           MOVE 'INS'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-INSTRU           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DINSTRO
      *
           MOVE WS-T2-UFNASC           TO WS-UF-CONS
           PERFORM 3360-LER-UF
           MOVE WS-UF-NOME             TO DUFNASO
      *
           MOVE WS-T2-MUNNAS           TO WS-MUN-CONS
           PERFORM 3370-LER-MUNICIPIO
           MOVE WS-MUN-NOME            TO DMUNNAO
      *
           MOVE 'DEF'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-TPDEF            TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DTPDEFO
      *
           MOVE 'TLG'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-TPLOGR           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DTPLOGO
      *
           MOVE WS-T2-MUNIC            TO WS-MUN-CONS
           PERFORM 3370-LER-MUNICIPIO
           MOVE WS-MUN-NOME            TO DMUNICO
      *
           MOVE WS-T2-UF               TO WS-UF-CONS
           PERFORM 3360-LER-UF
           MOVE WS-UF-NOME             TO DUFO
      *
           MOVE WS-T2-ESTAB            TO WS-EST-CONS
           PERFORM 3380-LER-ESTABELEC
           MOVE WS-EST-NOME            TO DESTABO
      *
           MOVE 'VIN'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-VINCUL           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DVINCO
      *
           MOVE 'JOR'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-JORNAD           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DJORNO
      *
           MOVE 'HOR'                 TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-HORARI           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           MOVE WS-DOM-DESCR           TO DHORARO
      *
           CONTINUE.
       3450-FIM.
           EXIT.
      *
      *================================================================*
      * 3500 - CARGA DOS DADOS PESSOAIS DE UMA MATRICULA               *
      *                                                                *
      * SEXO E GRAU_INSTRUCAO FICAM EM TB_EMPREGADO DESDE A PRIMEIRA   *
      * VERSAO DO CADASTRO; OS DEMAIS CAMPOS VIVEM NA TABELA           *
      * COMPLEMENTAR 1:1, QUE PODE AINDA NAO TER LINHA PARA A          *
      * MATRICULA. NESSE CASO O ESTADO NASCE ZERADO E A GRAVACAO SERA  *
      * UM INSERT (WS-ES-COMPL-NOVO).                                  *
      *================================================================*
       3500-CONSULTAR-COMPL SECTION.
       3500-INICIO.
           MOVE WS-ES-MATRIC           TO DCL-MATRICULA
      *
           EXEC SQL
                SELECT NOME
                     , SEXO
                     , GRAU_INSTRUCAO
                  INTO :DCL-NOME
                     , :DCL-SEXO
                     , :DCL-GRAU-INSTRUCAO
                  FROM SFPADM.TB_EMPREGADO
                 WHERE MATRICULA = :DCL-MATRICULA
                  WITH CS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    CONTINUE
               WHEN +100
                    MOVE 'S'           TO WS-ERRO
                    MOVE 'MATRICULA NAO CADASTRADA NA PRIMEIRA TELA'
                                       TO WS-MENSAGEM
                    GO TO 3500-FIM
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE
      *
           MOVE DCL-NOME               TO WS-ES-NOME
           MOVE DCL-SEXO               TO WS-T2-SEXO
           MOVE DCL-GRAU-INSTRUCAO     TO WS-T2-INSTRU
      *
           EXEC SQL
                SELECT ESTADO_CIVIL
                     , RACA_COR
                     , NACIONALIDADE
                     , UF_NASCIMENTO
                     , MUN_NASCIMENTO
                     , NOME_MAE
                     , IND_DEFICIENCIA
                     , TIPO_DEFICIENCIA
                     , CTPS_NUMERO
                     , CTPS_SERIE
                     , CTPS_UF
                     , RG_NUMERO
                     , RG_ORGAO
                     , TITULO_ELEITOR
                     , TIPO_LOGRADOURO
                     , LOGRADOURO
                     , NUMERO
                     , COMPLEMENTO
                     , BAIRRO
                     , CEP
                     , COD_MUNICIPIO
                     , UF
                     , TELEFONE
                     , COD_ESTABELEC
                     , TIPO_VINCULO
                     , TIPO_JORNADA
                     , COD_HORARIO
                  INTO :DCL-C-ESTADO-CIVIL
                     , :DCL-C-RACA-COR
                     , :DCL-C-NACIONALIDADE
                     , :DCL-C-UF-NASCIMENTO
                     , :DCL-C-MUN-NASCIMENTO
                     , :DCL-C-NOME-MAE
                     , :DCL-C-IND-DEFICIENCIA
                     , :DCL-C-TIPO-DEFICIENCIA
                     , :DCL-C-CTPS-NUMERO
                     , :DCL-C-CTPS-SERIE
                     , :DCL-C-CTPS-UF
                     , :DCL-C-RG-NUMERO
                     , :DCL-C-RG-ORGAO
                     , :DCL-C-TITULO-ELEITOR
                     , :DCL-C-TIPO-LOGRADOURO
                     , :DCL-C-LOGRADOURO
                     , :DCL-C-NUMERO
                     , :DCL-C-COMPLEMENTO
                     , :DCL-C-BAIRRO
                     , :DCL-C-CEP
                     , :DCL-C-COD-MUNICIPIO
                     , :DCL-C-UF
                     , :DCL-C-TELEFONE
                     , :DCL-C-COD-ESTABELEC
                     , :DCL-C-TIPO-VINCULO
                     , :DCL-C-TIPO-JORNADA
                     , :DCL-C-COD-HORARIO
                  FROM SFPADM.TB_EMPREGADO_COMPL
                 WHERE MATRICULA = :DCL-MATRICULA
                  WITH CS
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    MOVE 'N'           TO WS-ES-COMPL-NOVO
                    PERFORM 3550-DCLGEN-PARA-ESTADO
               WHEN +100
                    MOVE 'S'           TO WS-ES-COMPL-NOVO
                    PERFORM 3580-ESTADO-INICIAL
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       3500-FIM.
           EXIT.
      *
       3550-DCLGEN-PARA-ESTADO SECTION.
       3550-INICIO.
           MOVE DCL-C-ESTADO-CIVIL     TO WS-T2-ECIV
           MOVE DCL-C-RACA-COR         TO WS-T2-RACA
           MOVE DCL-C-NACIONALIDADE    TO WS-T2-NACION
           MOVE DCL-C-UF-NASCIMENTO    TO WS-T2-UFNASC
           MOVE DCL-C-MUN-NASCIMENTO   TO WS-T2-MUNNAS
           MOVE DCL-C-NOME-MAE         TO WS-T2-NOMEMA
           MOVE DCL-C-IND-DEFICIENCIA  TO WS-T2-DEFIC
           MOVE DCL-C-TIPO-DEFICIENCIA TO WS-T2-TPDEF
           MOVE DCL-C-CTPS-NUMERO      TO WS-T2-CTPSNR
           MOVE DCL-C-CTPS-SERIE       TO WS-T2-CTPSSE
           MOVE DCL-C-CTPS-UF          TO WS-T2-CTPSUF
           MOVE DCL-C-RG-NUMERO        TO WS-T2-RGNUM
           MOVE DCL-C-RG-ORGAO         TO WS-T2-RGORG
           MOVE DCL-C-TITULO-ELEITOR   TO WS-T2-TITELE
           MOVE DCL-C-TIPO-LOGRADOURO  TO WS-T2-TPLOGR
           MOVE DCL-C-LOGRADOURO       TO WS-T2-LOGRAD
           MOVE DCL-C-NUMERO           TO WS-T2-NUMERO
           MOVE DCL-C-COMPLEMENTO      TO WS-T2-COMPLE
           MOVE DCL-C-BAIRRO           TO WS-T2-BAIRRO
           MOVE DCL-C-CEP              TO WS-T2-CEP
           MOVE DCL-C-COD-MUNICIPIO    TO WS-T2-MUNIC
           MOVE DCL-C-UF               TO WS-T2-UF
           MOVE DCL-C-TELEFONE         TO WS-T2-TELEF
           MOVE DCL-C-COD-ESTABELEC    TO WS-T2-ESTAB
           MOVE DCL-C-TIPO-VINCULO     TO WS-T2-VINCUL
           MOVE DCL-C-TIPO-JORNADA     TO WS-T2-JORNAD
           MOVE DCL-C-COD-HORARIO      TO WS-T2-HORARI
           CONTINUE.
       3550-FIM.
           EXIT.
      *
      *--- MATRICULA SEM LINHA NA COMPLEMENTAR: VALORES DE PARTIDA ----
       3580-ESTADO-INICIAL SECTION.
       3580-INICIO.
           INITIALIZE WS-ES-T2
           MOVE DCL-SEXO               TO WS-T2-SEXO
           MOVE DCL-GRAU-INSTRUCAO     TO WS-T2-INSTRU
           MOVE 'S'                    TO WS-T2-ECIV
           MOVE 'N'                    TO WS-T2-DEFIC.
       3580-FIM.
           EXIT.
      *

      *================================================================*
      * 4000 - INCLUSAO E ALTERACAO                                    *
      *================================================================*
       4000-GRAVAR SECTION.
       4000-INICIO.
           PERFORM 7100-CARREGAR-PARAMETROS
           PERFORM 4100-VALIDAR-CAMPOS
      *
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 4200-MOVER-PARA-DCLGEN
      *
           IF WS-ACAO = 'I'
               PERFORM 4300-INSERIR
           ELSE
               PERFORM 4400-ATUALIZAR
           END-IF.
       4000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4100 - BATERIA COMPLETA DE VALIDACOES DE NEGOCIO               *
      *----------------------------------------------------------------*
       4100-VALIDAR-CAMPOS SECTION.
       4100-INICIO.
      *--- RN01 - MATRICULA -------------------------------------------
           IF WS-MATRICULA = ZEROS
               MOVE 'RN01 - MATRICULA OBRIGATORIA E NUMERICA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MATRICA
               MOVE 'S'                TO WS-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN02 - NOME ------------------------------------------------
           IF NOMEI = SPACES OR NOMEI(1:10) = SPACES
               MOVE 'RN02 - NOME OBRIGATORIO COM AO MENOS 10 LETRAS'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO NOMEA
               MOVE 'S'                TO WS-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN03 - CPF VALIDO ------------------------------------------
           INITIALIZE AREA-UTILITARIOS
           SET UTL-VALIDA-CPF          TO TRUE
           MOVE WS-EDT-CPF             TO UTL-CPF
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           IF UTL-COD-RETORNO NOT = ZEROS
               MOVE 'RN03 - CPF INVALIDO PELO DIGITO VERIFICADOR'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO CPFA
               MOVE 'S'                TO WS-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN04 - CPF UNICO -------------------------------------------
           MOVE WS-EDT-CPF             TO DCL-CPF
           MOVE WS-MATRICULA           TO DCL-MATRICULA
           EXEC SQL
                SELECT COUNT(*)
                  INTO :WS-QTD-CPF
                  FROM SFPADM.TB_EMPREGADO
                 WHERE CPF       =  :DCL-CPF
                   AND MATRICULA <> :DCL-MATRICULA
                  WITH CS
           END-EXEC
      *
           IF SQLCODE NOT = 0
               PERFORM 9000-TRATAR-ERRO-SQL
           END-IF
      *
           IF WS-QTD-CPF > ZEROS
               MOVE 'RN04 - CPF JA CADASTRADO EM OUTRA MATRICULA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO CPFA
               MOVE 'S'                TO WS-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN05 - DATAS VALIDAS ---------------------------------------
           PERFORM 4110-VALIDAR-DATAS
           IF TEM-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN09 - PISO SALARIAL ---------------------------------------
           PERFORM 4120-VALIDAR-SALARIO
           IF TEM-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN10 E RN11 - ADICIONAIS DE RISCO --------------------------
           PERFORM 4130-VALIDAR-ADICIONAIS
           IF TEM-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN12 A RN15 - DESCONTOS E BENEFICIOS -----------------------
           PERFORM 4140-VALIDAR-DESCONTOS.
       4100-FIM.
           EXIT.
      *
       4110-VALIDAR-DATAS SECTION.
       4110-INICIO.
      *    NASCIMENTO
           INITIALIZE AREA-UTILITARIOS
           SET UTL-VALIDA-DATA         TO TRUE
           MOVE WS-EDT-DT-NASC         TO UTL-DATA-INI
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           IF UTL-COD-RETORNO NOT = ZEROS
               MOVE 'RN05 - DATA DE NASCIMENTO INVALIDA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO DTNASCA
               MOVE 'S'                TO WS-ERRO
               GO TO 4110-FIM
           END-IF
      *
      *    ADMISSAO
           INITIALIZE AREA-UTILITARIOS
           SET UTL-VALIDA-DATA         TO TRUE
           MOVE WS-EDT-DT-ADM          TO UTL-DATA-INI
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           IF UTL-COD-RETORNO NOT = ZEROS
               MOVE 'RN05 - DATA DE ADMISSAO INVALIDA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO DTADMA
               MOVE 'S'                TO WS-ERRO
               GO TO 4110-FIM
           END-IF
      *
      *--- RN06 - IDADE MINIMA NA ADMISSAO ----------------------------
           INITIALIZE AREA-UTILITARIOS
           SET UTL-DIFERENCA-DIAS      TO TRUE
           MOVE WS-EDT-DT-NASC         TO UTL-DATA-INI
           MOVE WS-EDT-DT-ADM          TO UTL-DATA-FIM
           CALL 'SFPUTIL' USING AREA-UTILITARIOS
           MOVE UTL-QTD-DIAS           TO WS-IDADE-ADMISSAO
      *
           IF WS-IDADE-ADMISSAO < 5113
               MOVE 'RN06 - ADMISSAO ANTES DA IDADE MINIMA LEGAL'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO DTADMA
               MOVE 'S'                TO WS-ERRO
               GO TO 4110-FIM
           END-IF
      *
      *--- RN07 E RN08 - DESLIGAMENTO ---------------------------------
           IF WS-EDT-DT-DEM > ZEROS
               INITIALIZE AREA-UTILITARIOS
               SET UTL-VALIDA-DATA     TO TRUE
               MOVE WS-EDT-DT-DEM      TO UTL-DATA-INI
               CALL 'SFPUTIL' USING AREA-UTILITARIOS
               IF UTL-COD-RETORNO NOT = ZEROS
                   MOVE 'RN05 - DATA DE DEMISSAO INVALIDA'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO DTDEMA
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4110-FIM
               END-IF
      *
               IF WS-EDT-DT-DEM < WS-EDT-DT-ADM
                   MOVE 'RN07 - DEMISSAO ANTERIOR A ADMISSAO'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO DTDEMA
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4110-FIM
               END-IF
           END-IF
      *
           IF SITUACI = 'D' AND WS-EDT-DT-DEM = ZEROS
               MOVE 'RN08 - SITUACAO D EXIGE DATA DE DEMISSAO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO DTDEMA
               MOVE 'S'                TO WS-ERRO
               GO TO 4110-FIM
           END-IF
      *
           IF SITUACI NOT = 'A' AND 'F' AND 'L' AND 'D'
               MOVE 'SITUACAO INVALIDA. USE A, F, L OU D'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO SITUACA
               MOVE 'S'                TO WS-ERRO
           END-IF.
       4110-FIM.
           EXIT.
      *
       4120-VALIDAR-SALARIO SECTION.
       4120-INICIO.
           IF SALARIOI = ZEROS
               MOVE 'RN09 - SALARIO OBRIGATORIO E MAIOR QUE ZERO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO SALARIOA
               MOVE 'S'                TO WS-ERRO
               GO TO 4120-FIM
           END-IF
      *
           IF TPSALI NOT = 'M' AND 'H' AND 'D'
               MOVE 'TIPO DE SALARIO INVALIDO. USE M, H OU D'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO TPSALA
               MOVE 'S'                TO WS-ERRO
               GO TO 4120-FIM
           END-IF
      *
           IF WS-EDT-CARGA-HOR = ZEROS
               MOVE 220                TO WS-EDT-CARGA-HOR
           END-IF
      *
           EVALUATE TPSALI
               WHEN 'M'
      *             MENSALISTA COMPARA DIRETAMENTE COM O MINIMO
                    IF SALARIOI < WS-SALARIO-MINIMO
                        MOVE 'RN09 - SALARIO ABAIXO DO MINIMO LEGAL'
                                       TO WS-MENSAGEM
                        MOVE DFHBMBRY  TO SALARIOA
                        MOVE 'S'       TO WS-ERRO
                    END-IF
      *
               WHEN 'H'
      *             HORISTA COMPARA O VALOR HORA COM O MINIMO HORA
                    COMPUTE WS-SAL-HORA-MINIMO ROUNDED =
                            WS-SALARIO-MINIMO / WS-EDT-CARGA-HOR
                    IF SALARIOI < WS-SAL-HORA-MINIMO
                        MOVE 'RN09 - VALOR HORA ABAIXO DO MINIMO LEGAL'
                                       TO WS-MENSAGEM
                        MOVE DFHBMBRY  TO SALARIOA
                        MOVE 'S'       TO WS-ERRO
                    END-IF
      *
               WHEN 'D'
      *             DIARISTA COMPARA O VALOR DIA COM O MINIMO DIA
                    COMPUTE WS-SAL-HORA-MINIMO ROUNDED =
                            WS-SALARIO-MINIMO / 30
                    IF SALARIOI < WS-SAL-HORA-MINIMO
                        MOVE 'RN09 - DIARIA ABAIXO DO MINIMO LEGAL'
                                       TO WS-MENSAGEM
                        MOVE DFHBMBRY  TO SALARIOA
                        MOVE 'S'       TO WS-ERRO
                    END-IF
           END-EVALUATE.
       4120-FIM.
           EXIT.
      *
       4130-VALIDAR-ADICIONAIS SECTION.
       4130-INICIO.
      *--- RN10 - GRAUS LEGAIS DE INSALUBRIDADE -----------------------
           IF WS-EDT-INSALUBRID NOT = 00 AND 10 AND 20 AND 40
               MOVE 'RN10 - INSALUBRIDADE ACEITA 0, 10, 20 OU 40'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO INSALUA
               MOVE 'S'                TO WS-ERRO
               GO TO 4130-FIM
           END-IF
      *
           IF PERICUI NOT = 'S' AND 'N'
               MOVE 'PERICULOSIDADE ACEITA APENAS S OU N'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO PERICUA
               MOVE 'S'                TO WS-ERRO
               GO TO 4130-FIM
           END-IF
      *
      *--- RN11 - NAO ACUMULACAO (ART. 193 PARAGRAFO 2 DA CLT) --------
           IF WS-EDT-INSALUBRID > ZEROS AND PERICUI = 'S'
               MOVE 'RN11 - INSALUBRIDADE E PERICULOSIDADE NAO ACUMULAM'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO PERICUA
               MOVE 'S'                TO WS-ERRO
           END-IF.
       4130-FIM.
           EXIT.
      *
       4140-VALIDAR-DESCONTOS SECTION.
       4140-INICIO.
      *--- RN12 - PENSAO EXCLUDENTE -----------------------------------
           IF PERPENI > ZEROS AND VLRPENI > ZEROS
               MOVE 'RN12 - INFORME A PENSAO EM PERCENTUAL OU EM VALOR'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO PERPENA
               MOVE 'S'                TO WS-ERRO
               GO TO 4140-FIM
           END-IF
      *
           IF PERPENI > 70
               MOVE 'RN12 - PERCENTUAL DE PENSAO ACIMA DO RAZOAVEL'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO PERPENA
               MOVE 'S'                TO WS-ERRO
               GO TO 4140-FIM
           END-IF
      *
      *--- RN13 - MARGEM CONSIGNAVEL ----------------------------------
           IF VLRCONI > ZEROS
               IF TPSALI = 'M'
                   COMPUTE WS-MARGEM-CONSIG ROUNDED =
                           SALARIOI * 35 / 100
               ELSE
                   COMPUTE WS-MARGEM-CONSIG ROUNDED =
                           SALARIOI * WS-EDT-CARGA-HOR * 35 / 100
               END-IF
      *
               IF VLRCONI > WS-MARGEM-CONSIG
                   MOVE 'RN13 - CONSIGNADO ACIMA DA MARGEM DE 35%'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO VLRCONA
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4140-FIM
               END-IF
           END-IF
      *
      *--- RN14 - COERENCIA ENTRE INDICADOR E VALOR -------------------
           IF INDVTI = 'S' AND VLRVTI = ZEROS
               MOVE 'RN14 - VALE TRANSPORTE MARCADO SEM VALOR'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO VLRVTA
               MOVE 'S'                TO WS-ERRO
               GO TO 4140-FIM
           END-IF
      *
           IF INDVRI = 'S' AND VLRVRI = ZEROS
               MOVE 'RN14 - VALE REFEICAO MARCADO SEM VALOR'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO VLRVRA
               MOVE 'S'                TO WS-ERRO
               GO TO 4140-FIM
           END-IF
      *
           IF INDPSI = 'S' AND VLRPSI = ZEROS
               MOVE 'RN14 - PLANO DE SAUDE MARCADO SEM VALOR'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO VLRPSA
               MOVE 'S'                TO WS-ERRO
               GO TO 4140-FIM
           END-IF
      *
      *--- RN15 - DADOS BANCARIOS COMPLETOS ---------------------------
           IF WS-EDT-BANCO   > ZEROS
           OR WS-EDT-AGENCIA > ZEROS
           OR WS-EDT-CONTA   > ZEROS
               IF WS-EDT-BANCO   = ZEROS
               OR WS-EDT-AGENCIA = ZEROS
               OR WS-EDT-CONTA   = ZEROS
                   MOVE 'RN15 - INFORME BANCO, AGENCIA E CONTA'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO BANCOA
                   MOVE 'S'            TO WS-ERRO
               END-IF
           END-IF.
       4140-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4200 - CARGA DA ESTRUTURA DO DCLGEN                            *
      *----------------------------------------------------------------*
       4200-MOVER-PARA-DCLGEN SECTION.
       4200-INICIO.
           MOVE WS-MATRICULA           TO DCL-MATRICULA
           MOVE NOMEI                  TO DCL-NOME
           MOVE WS-EDT-CPF             TO DCL-CPF
           MOVE WS-EDT-PIS             TO DCL-PIS
      *
           MOVE WS-EDT-DT-ADM          TO WS-DATA-8
           PERFORM 7300-8-PARA-DB2
           MOVE WS-DATA-DB2            TO DCL-DT-ADMISSAO
      *
           IF WS-EDT-DT-DEM > ZEROS
               MOVE WS-EDT-DT-DEM      TO WS-DATA-8
               PERFORM 7300-8-PARA-DB2
               MOVE WS-DATA-DB2        TO DCL-DT-DEMISSAO
               MOVE ZEROS              TO WS-IND-DT-DEMISSAO
           ELSE
               MOVE -1                 TO WS-IND-DT-DEMISSAO
           END-IF
      *
           MOVE WS-EDT-DT-NASC         TO WS-DATA-8
           PERFORM 7300-8-PARA-DB2
           MOVE WS-DATA-DB2            TO DCL-DT-NASCIMENTO
      *
           MOVE SITUACI                TO DCL-SITUACAO
           MOVE WS-EDT-CARGO           TO DCL-COD-CARGO
           MOVE WS-EDT-DEPTO           TO DCL-COD-DEPTO
           MOVE WS-EDT-CCUSTO          TO DCL-CENTRO-CUSTO
           MOVE SALARIOI               TO DCL-SALARIO-BASE
           MOVE TPSALI                 TO DCL-TIPO-SALARIO
           MOVE WS-EDT-CARGA-HOR       TO DCL-CARGA-HOR-MES
           MOVE WS-EDT-DEP-IRRF        TO DCL-QTD-DEP-IRRF
           MOVE WS-EDT-DEP-SFAM        TO DCL-QTD-DEP-SALFAM
           MOVE WS-EDT-INSALUBRID      TO DCL-PERC-INSALUBRID
           MOVE PERICUI                TO DCL-IND-PERICULOSID
           MOVE INDVTI                 TO DCL-IND-VALE-TRANSP
           MOVE VLRVTI                 TO DCL-VLR-VALE-TRANSP
           MOVE INDVRI                 TO DCL-IND-VALE-REFEIC
           MOVE VLRVRI                 TO DCL-VLR-VALE-REFEIC
           MOVE INDPSI                 TO DCL-IND-PLANO-SAUDE
           MOVE VLRPSI                 TO DCL-VLR-PLANO-SAUDE
           MOVE PERPENI                TO DCL-PERC-PENSAO
           MOVE VLRPENI                TO DCL-VLR-PENSAO-FIXO
           MOVE VLRCONI                TO DCL-VLR-CONSIGNADO
           MOVE WS-EDT-BANCO           TO DCL-BANCO
           MOVE WS-EDT-AGENCIA         TO DCL-AGENCIA
           MOVE WS-EDT-CONTA           TO DCL-CONTA
           MOVE DIGCTAI                TO DCL-DIG-CONTA
           MOVE EIBTRMID               TO DCL-USUARIO-ATUALIZ.
       4200-FIM.
           EXIT.
      *
       4300-INSERIR SECTION.
       4300-INICIO.
           EXEC SQL
                INSERT INTO SFPADM.TB_EMPREGADO
                     ( MATRICULA
                     , NOME
                     , CPF
                     , PIS
                     , DT_ADMISSAO
                     , DT_DEMISSAO
                     , DT_NASCIMENTO
                     , SITUACAO
                     , COD_CARGO
                     , COD_DEPTO
                     , CENTRO_CUSTO
                     , SALARIO_BASE
                     , TIPO_SALARIO
                     , CARGA_HOR_MES
                     , QTD_DEP_IRRF
                     , QTD_DEP_SALFAM
                     , PERC_INSALUBRID
                     , IND_PERICULOSID
                     , IND_VALE_TRANSP
                     , VLR_VALE_TRANSP
                     , IND_VALE_REFEIC
                     , VLR_VALE_REFEIC
                     , IND_PLANO_SAUDE
                     , VLR_PLANO_SAUDE
                     , PERC_PENSAO
                     , VLR_PENSAO_FIXO
                     , VLR_CONSIGNADO
                     , BANCO
                     , AGENCIA
                     , CONTA
                     , DIG_CONTA
                     , TS_ATUALIZACAO
                     , USUARIO_ATUALIZ )
                VALUES
                     ( :DCL-MATRICULA
                     , :DCL-NOME
                     , :DCL-CPF
                     , :DCL-PIS
                     , DATE(:DCL-DT-ADMISSAO)
                     , DATE(:DCL-DT-DEMISSAO) :WS-IND-DT-DEMISSAO
                     , DATE(:DCL-DT-NASCIMENTO)
                     , :DCL-SITUACAO
                     , :DCL-COD-CARGO
                     , :DCL-COD-DEPTO
                     , :DCL-CENTRO-CUSTO
                     , :DCL-SALARIO-BASE
                     , :DCL-TIPO-SALARIO
                     , :DCL-CARGA-HOR-MES
                     , :DCL-QTD-DEP-IRRF
                     , :DCL-QTD-DEP-SALFAM
                     , :DCL-PERC-INSALUBRID
                     , :DCL-IND-PERICULOSID
                     , :DCL-IND-VALE-TRANSP
                     , :DCL-VLR-VALE-TRANSP
                     , :DCL-IND-VALE-REFEIC
                     , :DCL-VLR-VALE-REFEIC
                     , :DCL-IND-PLANO-SAUDE
                     , :DCL-VLR-PLANO-SAUDE
                     , :DCL-PERC-PENSAO
                     , :DCL-VLR-PENSAO-FIXO
                     , :DCL-VLR-CONSIGNADO
                     , :DCL-BANCO
                     , :DCL-AGENCIA
                     , :DCL-CONTA
                     , :DCL-DIG-CONTA
                     , CURRENT TIMESTAMP
                     , :DCL-USUARIO-ATUALIZ )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    EXEC CICS SYNCPOINT END-EXEC
                    MOVE 'EMPREGADO INCLUIDO COM SUCESSO'
                                       TO MENSAGO
                    MOVE 'C'           TO ACAOO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN -803
                    MOVE 'MATRICULA JA CADASTRADA - USE A ACAO A'
                                       TO MENSAGO
                    MOVE DFHBMBRY      TO MATRICA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN -530
                    MOVE 'CARGO, DEPTO OU CENTRO DE CUSTO INEXISTENTE'
                                       TO MENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       4300-FIM.
           EXIT.
      *
       4400-ATUALIZAR SECTION.
       4400-INICIO.
           EXEC SQL
                UPDATE SFPADM.TB_EMPREGADO
                   SET NOME            = :DCL-NOME
                     , CPF             = :DCL-CPF
                     , PIS             = :DCL-PIS
                     , DT_ADMISSAO     = DATE(:DCL-DT-ADMISSAO)
                     , DT_DEMISSAO     = DATE(:DCL-DT-DEMISSAO)
                                         :WS-IND-DT-DEMISSAO
                     , DT_NASCIMENTO   = DATE(:DCL-DT-NASCIMENTO)
                     , SITUACAO        = :DCL-SITUACAO
                     , COD_CARGO       = :DCL-COD-CARGO
                     , COD_DEPTO       = :DCL-COD-DEPTO
                     , CENTRO_CUSTO    = :DCL-CENTRO-CUSTO
                     , SALARIO_BASE    = :DCL-SALARIO-BASE
                     , TIPO_SALARIO    = :DCL-TIPO-SALARIO
                     , CARGA_HOR_MES   = :DCL-CARGA-HOR-MES
                     , QTD_DEP_IRRF    = :DCL-QTD-DEP-IRRF
                     , QTD_DEP_SALFAM  = :DCL-QTD-DEP-SALFAM
                     , PERC_INSALUBRID = :DCL-PERC-INSALUBRID
                     , IND_PERICULOSID = :DCL-IND-PERICULOSID
                     , IND_VALE_TRANSP = :DCL-IND-VALE-TRANSP
                     , VLR_VALE_TRANSP = :DCL-VLR-VALE-TRANSP
                     , IND_VALE_REFEIC = :DCL-IND-VALE-REFEIC
                     , VLR_VALE_REFEIC = :DCL-VLR-VALE-REFEIC
                     , IND_PLANO_SAUDE = :DCL-IND-PLANO-SAUDE
                     , VLR_PLANO_SAUDE = :DCL-VLR-PLANO-SAUDE
                     , PERC_PENSAO     = :DCL-PERC-PENSAO
                     , VLR_PENSAO_FIXO = :DCL-VLR-PENSAO-FIXO
                     , VLR_CONSIGNADO  = :DCL-VLR-CONSIGNADO
                     , BANCO           = :DCL-BANCO
                     , AGENCIA         = :DCL-AGENCIA
                     , CONTA           = :DCL-CONTA
                     , DIG_CONTA       = :DCL-DIG-CONTA
                     , TS_ATUALIZACAO  = CURRENT TIMESTAMP
                     , USUARIO_ATUALIZ = :DCL-USUARIO-ATUALIZ
                 WHERE MATRICULA       = :DCL-MATRICULA
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    EXEC CICS SYNCPOINT END-EXEC
                    MOVE 'EMPREGADO ALTERADO COM SUCESSO'
                                       TO MENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN +100
                    MOVE 'MATRICULA NAO ENCONTRADA PARA ALTERACAO'
                                       TO MENSAGO
                    MOVE DFHBMBRY      TO MATRICA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       4400-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4600 - VALIDACOES DA SEGUNDA TELA (RN23 A RN35)                *
      *----------------------------------------------------------------*
       4600-VALIDAR-TELA-2 SECTION.
       4600-INICIO.
      *--- RN23 - SEXO ------------------------------------------------
           IF WS-T2-SEXO NOT = 'M' AND WS-T2-SEXO NOT = 'F'
               MOVE 'RN23 - SEXO DEVE SER M OU F'
                                       TO WS-MENSAGEM
               MOVE 'SEXO'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN24 - ESTADO CIVIL NO DOMINIO ECI -------------------------
           MOVE 'ECI'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-ECIV             TO WS-DOM-CODIGO(1:1)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN24 - ESTADO CIVIL INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'ECIV'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN25 - RACA OU COR NO DOMINIO RAC --------------------------
           IF WS-T2-RACA = ZEROS
               MOVE 'RN25 - RACA OU COR OBRIGATORIA - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'RACA'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE 'RAC'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-RACA             TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN25 - RACA OU COR INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'RACA'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN26 - NACIONALIDADE NO DOMINIO NAC ------------------------
           IF WS-T2-NACION = ZEROS
               MOVE 'RN26 - NACIONALIDADE OBRIGATORIA - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'NACION'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE 'NAC'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-NACION           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN26 - NACIONALIDADE INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'NACION'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN27 - GRAU DE INSTRUCAO NO DOMINIO INS --------------------
           IF WS-T2-INSTRU = ZEROS
               MOVE 'RN27 - GRAU DE INSTRUCAO OBRIGATORIO - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'INSTRU'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE 'INS'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-INSTRU           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN27 - GRAU DE INSTRUCAO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'INSTRU'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN28 - NATURALIDADE: UF E MUNICIPIO COERENTES --------------
           MOVE WS-T2-UFNASC           TO WS-UF-CONS
           PERFORM 3360-LER-UF
           IF WS-UF-OK NOT = 'S'
               MOVE 'RN28 - UF DE NASCIMENTO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'UFNASC'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE WS-T2-MUNNAS           TO WS-MUN-CONS
           PERFORM 3370-LER-MUNICIPIO
           IF WS-MUN-OK NOT = 'S'
               MOVE 'RN28 - MUNICIPIO DE NASCIMENTO INEXISTENTE'
                                       TO WS-MENSAGEM
               MOVE 'MUNNAS'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-MUN-UF NOT = WS-T2-UFNASC
               MOVE 'RN28 - MUNICIPIO DE NASCIMENTO NAO PERTENCE A UF'
                                       TO WS-MENSAGEM
               MOVE 'MUNNAS'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN29 - NOME DA MAE ----------------------------------------
           IF WS-T2-NOMEMA = SPACES
              OR WS-T2-NOMEMA(1:10) = SPACES
               MOVE 'RN29 - NOME DA MAE COM AO MENOS 10 LETRAS'
                                       TO WS-MENSAGEM
               MOVE 'NOMEMA'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN30 - DEFICIENCIA: INDICADOR E TIPO COERENTES -------------
           IF WS-T2-DEFIC NOT = 'S' AND WS-T2-DEFIC NOT = 'N'
               MOVE 'RN30 - INDICADOR DE DEFICIENCIA DEVE SER S OU N'
                                       TO WS-MENSAGEM
               MOVE 'DEFIC'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-T2-DEFIC = 'S'
               IF WS-T2-TPDEF = ZEROS
                   MOVE 'RN30 - TIPO DE DEFICIENCIA OBRIGATORIO'
                                       TO WS-MENSAGEM
                   MOVE 'TPDEF'        TO WS-CAMPO-ERRO
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4600-FIM
               END-IF
               MOVE 'DEF'              TO WS-DOM-TIPO
               MOVE SPACES             TO WS-DOM-CODIGO
               MOVE WS-T2-TPDEF        TO WS-DOM-CODIGO(1:2)
               PERFORM 3350-LER-DOMINIO
               IF WS-DOM-OK NOT = 'S'
                   MOVE 'RN30 - TIPO DE DEFICIENCIA INEXISTENTE'
                                       TO WS-MENSAGEM
                   MOVE 'TPDEF'        TO WS-CAMPO-ERRO
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4600-FIM
               END-IF
           ELSE
               IF WS-T2-TPDEF NOT = ZEROS
                   MOVE 'RN30 - TIPO DE DEFICIENCIA EXIGE INDICADOR S'
                                       TO WS-MENSAGEM
                   MOVE 'TPDEF'        TO WS-CAMPO-ERRO
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4600-FIM
               END-IF
           END-IF
      *
      *--- RN31 - CTPS: NUMERO EXIGE SERIE E UF -----------------------
           IF WS-T2-CTPSNR NOT = ZEROS
               IF WS-T2-CTPSSE = ZEROS
                   MOVE 'RN31 - SERIE DA CTPS OBRIGATORIA'
                                       TO WS-MENSAGEM
                   MOVE 'CTPSSE'       TO WS-CAMPO-ERRO
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4600-FIM
               END-IF
               MOVE WS-T2-CTPSUF       TO WS-UF-CONS
               PERFORM 3360-LER-UF
               IF WS-UF-OK NOT = 'S'
                   MOVE 'RN31 - UF DA CTPS INEXISTENTE'
                                       TO WS-MENSAGEM
                   MOVE 'CTPSUF'       TO WS-CAMPO-ERRO
                   MOVE 'S'            TO WS-ERRO
                   GO TO 4600-FIM
               END-IF
           END-IF
      *
      *--- RN32 - ENDERECO: TIPO DE LOGRADOURO E CAMPOS OBRIGATORIOS -
           MOVE 'TLG'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-TPLOGR           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN32 - TIPO DE LOGRADOURO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'TPLOGR'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-T2-LOGRAD = SPACES
               MOVE 'RN32 - LOGRADOURO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE 'LOGRAD'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-T2-NUMERO = SPACES
               MOVE 'RN32 - NUMERO DO ENDERECO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE 'NUMERO'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-T2-BAIRRO = SPACES
               MOVE 'RN32 - BAIRRO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE 'BAIRRO'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-T2-CEP = ZEROS
               MOVE 'RN32 - CEP OBRIGATORIO COM OITO DIGITOS'
                                       TO WS-MENSAGEM
               MOVE 'CEP'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN33 - UF E MUNICIPIO DO ENDERECO COERENTES ----------------
           MOVE WS-T2-UF               TO WS-UF-CONS
           PERFORM 3360-LER-UF
           IF WS-UF-OK NOT = 'S'
               MOVE 'RN33 - UF DO ENDERECO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'UF'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE WS-T2-MUNIC            TO WS-MUN-CONS
           PERFORM 3370-LER-MUNICIPIO
           IF WS-MUN-OK NOT = 'S'
               MOVE 'RN33 - MUNICIPIO DO ENDERECO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'MUNIC'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           IF WS-MUN-UF NOT = WS-T2-UF
               MOVE 'RN33 - MUNICIPIO DO ENDERECO NAO PERTENCE A UF'
                                       TO WS-MENSAGEM
               MOVE 'MUNIC'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN34 - ESTABELECIMENTO CADASTRADO E ATIVO ------------------
           MOVE WS-T2-ESTAB            TO WS-EST-CONS
           PERFORM 3380-LER-ESTABELEC
           IF WS-EST-OK NOT = 'S'
               MOVE 'RN34 - ESTABELECIMENTO INEXISTENTE OU INATIVO'
                                       TO WS-MENSAGEM
               MOVE 'ESTAB'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
      *
      *--- RN35 - VINCULO, JORNADA E HORARIO NOS DOMINIOS -------------
           MOVE 'VIN'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-VINCUL           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN35 - TIPO DE VINCULO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'VINCUL'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE 'JOR'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-JORNAD           TO WS-DOM-CODIGO(1:2)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN35 - TIPO DE JORNADA INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'JORNAD'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           MOVE 'HOR'                  TO WS-DOM-TIPO
           MOVE SPACES                 TO WS-DOM-CODIGO
           MOVE WS-T2-HORARI           TO WS-DOM-CODIGO(1:3)
           PERFORM 3350-LER-DOMINIO
           IF WS-DOM-OK NOT = 'S'
               MOVE 'RN35 - HORARIO DE TRABALHO INEXISTENTE - USE F4'
                                       TO WS-MENSAGEM
               MOVE 'HORARI'
                                       TO WS-CAMPO-ERRO
               MOVE 'S'                TO WS-ERRO
               GO TO 4600-FIM
           END-IF
           CONTINUE.
       4600-FIM.
           EXIT.
      *
       4650-MOVER-COMPL-DCLGEN SECTION.
       4650-INICIO.
           MOVE WS-ES-MATRIC           TO DCL-MATRICULA
                                          DCL-C-MATRICULA
           MOVE WS-T2-SEXO             TO DCL-SEXO
           MOVE WS-T2-INSTRU           TO DCL-GRAU-INSTRUCAO
           MOVE WS-T2-ECIV             TO DCL-C-ESTADO-CIVIL
           MOVE WS-T2-RACA             TO DCL-C-RACA-COR
           MOVE WS-T2-NACION           TO DCL-C-NACIONALIDADE
           MOVE WS-T2-UFNASC           TO DCL-C-UF-NASCIMENTO
           MOVE WS-T2-MUNNAS           TO DCL-C-MUN-NASCIMENTO
           MOVE WS-T2-NOMEMA           TO DCL-C-NOME-MAE
           MOVE WS-T2-DEFIC            TO DCL-C-IND-DEFICIENCIA
           MOVE WS-T2-TPDEF            TO DCL-C-TIPO-DEFICIENCIA
           MOVE WS-T2-CTPSNR           TO DCL-C-CTPS-NUMERO
           MOVE WS-T2-CTPSSE           TO DCL-C-CTPS-SERIE
           MOVE WS-T2-CTPSUF           TO DCL-C-CTPS-UF
           MOVE WS-T2-RGNUM            TO DCL-C-RG-NUMERO
           MOVE WS-T2-RGORG            TO DCL-C-RG-ORGAO
           MOVE WS-T2-TITELE           TO DCL-C-TITULO-ELEITOR
           MOVE WS-T2-TPLOGR           TO DCL-C-TIPO-LOGRADOURO
           MOVE WS-T2-LOGRAD           TO DCL-C-LOGRADOURO
           MOVE WS-T2-NUMERO           TO DCL-C-NUMERO
           MOVE WS-T2-COMPLE           TO DCL-C-COMPLEMENTO
           MOVE WS-T2-BAIRRO           TO DCL-C-BAIRRO
           MOVE WS-T2-CEP              TO DCL-C-CEP
           MOVE WS-T2-MUNIC            TO DCL-C-COD-MUNICIPIO
           MOVE WS-T2-UF               TO DCL-C-UF
           MOVE WS-T2-TELEF            TO DCL-C-TELEFONE
           MOVE WS-T2-ESTAB            TO DCL-C-COD-ESTABELEC
           MOVE WS-T2-VINCUL           TO DCL-C-TIPO-VINCULO
           MOVE WS-T2-JORNAD           TO DCL-C-TIPO-JORNADA
           MOVE WS-T2-HORARI           TO DCL-C-COD-HORARIO
           MOVE COM-USUARIO            TO DCL-C-USUARIO-ATUALI.
       4650-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4700 - GRAVACAO DOS DADOS PESSOAIS                             *
      *                                                                *
      * SEXO E GRAU_INSTRUCAO SAO COLUNAS DE TB_EMPREGADO: VAO EM UM   *
      * UPDATE PROPRIO, DE DUAS COLUNAS, QUE NAO TOCA NO RESTO DA      *
      * LINHA E POR ISSO NAO INTERFERE NA PRIMEIRA TELA. OS DEMAIS     *
      * CAMPOS VAO PARA TB_EMPREGADO_COMPL, NA MESMA UNIDADE DE        *
      * TRABALHO: O SYNCPOINT SO VEM DEPOIS DOS DOIS COMANDOS.         *
      *----------------------------------------------------------------*
       4700-GRAVAR-COMPL SECTION.
       4700-INICIO.
           PERFORM 4600-VALIDAR-TELA-2
      *
           IF TEM-ERRO
               PERFORM 6300-LIMPAR-MAPA-2
               PERFORM 3400-MOVER-PARA-TELA-2
               PERFORM 3450-DESCREVER-TELA-2
               PERFORM 6350-MARCAR-CAMPO-ERRO
               MOVE WS-MENSAGEM        TO MENSA2O
               PERFORM 6400-ENVIAR-MAPA-2
           END-IF
      *
           PERFORM 4650-MOVER-COMPL-DCLGEN
      *
           EXEC SQL
                UPDATE SFPADM.TB_EMPREGADO
                   SET SEXO            = :DCL-SEXO
                     , GRAU_INSTRUCAO  = :DCL-GRAU-INSTRUCAO
                 WHERE MATRICULA       = :DCL-MATRICULA
           END-EXEC
      *
           IF SQLCODE NOT = 0
               PERFORM 9000-TRATAR-ERRO-SQL
           END-IF
      *
           IF WS-ES-COMPL-NOVO = 'S'
               PERFORM 4750-INSERIR-COMPL
           ELSE
               PERFORM 4800-ATUALIZAR-COMPL
           END-IF.
       4700-FIM.
           EXIT.
      *
       4750-INSERIR-COMPL SECTION.
       4750-INICIO.
           EXEC SQL
                INSERT INTO SFPADM.TB_EMPREGADO_COMPL
                     ( MATRICULA
                     , ESTADO_CIVIL
                     , RACA_COR
                     , NACIONALIDADE
                     , UF_NASCIMENTO
                     , MUN_NASCIMENTO
                     , NOME_MAE
                     , IND_DEFICIENCIA
                     , TIPO_DEFICIENCIA
                     , CTPS_NUMERO
                     , CTPS_SERIE
                     , CTPS_UF
                     , RG_NUMERO
                     , RG_ORGAO
                     , TITULO_ELEITOR
                     , TIPO_LOGRADOURO
                     , LOGRADOURO
                     , NUMERO
                     , COMPLEMENTO
                     , BAIRRO
                     , CEP
                     , COD_MUNICIPIO
                     , UF
                     , TELEFONE
                     , COD_ESTABELEC
                     , TIPO_VINCULO
                     , TIPO_JORNADA
                     , COD_HORARIO
                     , TS_ATUALIZACAO
                     , USUARIO_ATUALIZ
                     )
                VALUES
                     ( :DCL-C-MATRICULA
                     , :DCL-C-ESTADO-CIVIL
                     , :DCL-C-RACA-COR
                     , :DCL-C-NACIONALIDADE
                     , :DCL-C-UF-NASCIMENTO
                     , :DCL-C-MUN-NASCIMENTO
                     , :DCL-C-NOME-MAE
                     , :DCL-C-IND-DEFICIENCIA
                     , :DCL-C-TIPO-DEFICIENCIA
                     , :DCL-C-CTPS-NUMERO
                     , :DCL-C-CTPS-SERIE
                     , :DCL-C-CTPS-UF
                     , :DCL-C-RG-NUMERO
                     , :DCL-C-RG-ORGAO
                     , :DCL-C-TITULO-ELEITOR
                     , :DCL-C-TIPO-LOGRADOURO
                     , :DCL-C-LOGRADOURO
                     , :DCL-C-NUMERO
                     , :DCL-C-COMPLEMENTO
                     , :DCL-C-BAIRRO
                     , :DCL-C-CEP
                     , :DCL-C-COD-MUNICIPIO
                     , :DCL-C-UF
                     , :DCL-C-TELEFONE
                     , :DCL-C-COD-ESTABELEC
                     , :DCL-C-TIPO-VINCULO
                     , :DCL-C-TIPO-JORNADA
                     , :DCL-C-COD-HORARIO
                     , CURRENT TIMESTAMP
                     , :DCL-C-USUARIO-ATUALI
                     )
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    EXEC CICS SYNCPOINT END-EXEC
                    MOVE 'N'           TO WS-ES-COMPL-NOVO
                    PERFORM 6300-LIMPAR-MAPA-2
                    PERFORM 3400-MOVER-PARA-TELA-2
                    PERFORM 3450-DESCREVER-TELA-2
                    MOVE 'DADOS PESSOAIS INCLUIDOS COM SUCESSO'
                                       TO MENSA2O
                    PERFORM 6400-ENVIAR-MAPA-2
               WHEN -530
                    MOVE 'MATRICULA NAO CADASTRADA NA PRIMEIRA TELA'
                                       TO MENSA2O
                    PERFORM 6400-ENVIAR-MAPA-2
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       4750-FIM.
           EXIT.
      *
       4800-ATUALIZAR-COMPL SECTION.
       4800-INICIO.
           EXEC SQL
                UPDATE SFPADM.TB_EMPREGADO_COMPL
                   SET ESTADO_CIVIL    = :DCL-C-ESTADO-CIVIL
                     , RACA_COR        = :DCL-C-RACA-COR
                     , NACIONALIDADE   = :DCL-C-NACIONALIDADE
                     , UF_NASCIMENTO   = :DCL-C-UF-NASCIMENTO
                     , MUN_NASCIMENTO  = :DCL-C-MUN-NASCIMENTO
                     , NOME_MAE        = :DCL-C-NOME-MAE
                     , IND_DEFICIENCIA = :DCL-C-IND-DEFICIENCIA
                     , TIPO_DEFICIENCIA= :DCL-C-TIPO-DEFICIENCIA
                     , CTPS_NUMERO     = :DCL-C-CTPS-NUMERO
                     , CTPS_SERIE      = :DCL-C-CTPS-SERIE
                     , CTPS_UF         = :DCL-C-CTPS-UF
                     , RG_NUMERO       = :DCL-C-RG-NUMERO
                     , RG_ORGAO        = :DCL-C-RG-ORGAO
                     , TITULO_ELEITOR  = :DCL-C-TITULO-ELEITOR
                     , TIPO_LOGRADOURO = :DCL-C-TIPO-LOGRADOURO
                     , LOGRADOURO      = :DCL-C-LOGRADOURO
                     , NUMERO          = :DCL-C-NUMERO
                     , COMPLEMENTO     = :DCL-C-COMPLEMENTO
                     , BAIRRO          = :DCL-C-BAIRRO
                     , CEP             = :DCL-C-CEP
                     , COD_MUNICIPIO   = :DCL-C-COD-MUNICIPIO
                     , UF              = :DCL-C-UF
                     , TELEFONE        = :DCL-C-TELEFONE
                     , COD_ESTABELEC   = :DCL-C-COD-ESTABELEC
                     , TIPO_VINCULO    = :DCL-C-TIPO-VINCULO
                     , TIPO_JORNADA    = :DCL-C-TIPO-JORNADA
                     , COD_HORARIO     = :DCL-C-COD-HORARIO
                     , TS_ATUALIZACAO  = CURRENT TIMESTAMP
                     , USUARIO_ATUALIZ = :DCL-C-USUARIO-ATUALI
                 WHERE MATRICULA       = :DCL-C-MATRICULA
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    EXEC CICS SYNCPOINT END-EXEC
                    PERFORM 6300-LIMPAR-MAPA-2
                    PERFORM 3400-MOVER-PARA-TELA-2
                    PERFORM 3450-DESCREVER-TELA-2
                    MOVE 'DADOS PESSOAIS ALTERADOS COM SUCESSO'
                                       TO MENSA2O
                    PERFORM 6400-ENVIAR-MAPA-2
               WHEN +100
                    MOVE 'S'           TO WS-ES-COMPL-NOVO
                    PERFORM 4750-INSERIR-COMPL
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       4800-FIM.
           EXIT.
      *

      *----------------------------------------------------------------*
      * 4900 - ABERTURA DA JANELA DE CONSULTA (F4)                     *
      *                                                                *
      * A LINHA E A COLUNA DO CURSOR DIZEM QUAL CAMPO PEDIU A LISTA.   *
      * O ESTADO VAI PARA A FILA TEMPORARIA ANTES DO XCTL, PORQUE O    *
      * SFP0900 DEVOLVE O CONTROLE EM UMA NOVA ENTRADA DO PROGRAMA.    *
      *----------------------------------------------------------------*
       4900-CHAMAR-LOOKUP SECTION.
       4900-INICIO.
           COMPUTE WS-LINHA-CURSOR = EIBCPOSN / 80 + 1
           COMPUTE WS-COL-CURSOR = FUNCTION MOD(EIBCPOSN, 80) + 1
      *
           INITIALIZE AREA-LOOKUP
      *
           IF WS-NA-TELA-2
               PERFORM 4950-CAMPO-F4-TELA-2
           ELSE
               PERFORM 4920-CAMPO-F4-TELA-1
           END-IF
      *
           IF LOK-TIPO-DOMINIO = SPACES
               IF WS-NA-TELA-2
                   PERFORM 6300-LIMPAR-MAPA-2
                   PERFORM 3400-MOVER-PARA-TELA-2
                   PERFORM 3450-DESCREVER-TELA-2
                   MOVE 'O CAMPO SOB O CURSOR NAO TEM LISTA'
                                       TO MENSA2O
                   PERFORM 6400-ENVIAR-MAPA-2
               ELSE
                   PERFORM 6000-LIMPAR-MAPA
                   PERFORM 3040-MAPA-DO-SNAPSHOT
                   MOVE 'O CAMPO SOB O CURSOR NAO TEM LISTA'
                                       TO MENSAGO
                   PERFORM 6100-ENVIAR-MAPA-ERASE
               END-IF
           END-IF
      *
           MOVE WS-PROGRAMA            TO LOK-PGM-CHAMADOR
           MOVE 1                      TO LOK-PAGINA
           SET LOK-EM-CURSO            TO TRUE
      *
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
           PERFORM 1300-GRAVAR-ESTADO
      *
           EXEC CICS XCTL PROGRAM(WS-PGM-LOOKUP)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       4900-FIM.
           EXIT.
      *
      *--- CAMPOS COM LISTA NA PRIMEIRA TELA --------------------------
      * LINHA 08 SITUACAO, LINHA 09 CARGO E DEPARTAMENTO (O CENTRO DE  *
      * CUSTO NAO TEM CADASTRO), LINHA 11 TIPO DE SALARIO, LINHA 17    *
      * BANCO.                                                        *
       4920-CAMPO-F4-TELA-1 SECTION.
       4920-INICIO.
           EVALUATE WS-LINHA-CURSOR
               WHEN 8
                    MOVE 'SIT'         TO LOK-TIPO-DOMINIO
                    MOVE 'SITUAC'      TO LOK-CAMPO-ORIGEM
               WHEN 9
                    IF WS-COL-CURSOR < 20
                        MOVE 'CAR'     TO LOK-TIPO-DOMINIO
                        MOVE 'CARGO'   TO LOK-CAMPO-ORIGEM
                    ELSE
                        IF WS-COL-CURSOR < 40
                            MOVE 'DPT' TO LOK-TIPO-DOMINIO
                            MOVE 'DEPTO'
                                       TO LOK-CAMPO-ORIGEM
                        END-IF
                    END-IF
               WHEN 11
                    IF WS-COL-CURSOR > 25 AND WS-COL-CURSOR < 40
                        MOVE 'TSA'     TO LOK-TIPO-DOMINIO
                        MOVE 'TPSAL'   TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 17
                    IF WS-COL-CURSOR < 20
                        MOVE 'BAN'     TO LOK-TIPO-DOMINIO
                        MOVE 'BANCO'   TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN OTHER
                    CONTINUE
           END-EVALUATE.
       4920-FIM.
           EXIT.
      *
      *--- CAMPOS COM LISTA NA SEGUNDA TELA ---------------------------
      * O MUNICIPIO SAI FILTRADO PELA UF QUE ESTIVER NA TELA, LOGO     *
      * CONVEM INFORMAR A UF ANTES DE PEDIR A LISTA DE MUNICIPIOS.     *
       4950-CAMPO-F4-TELA-2 SECTION.
       4950-INICIO.
           EVALUATE WS-LINHA-CURSOR
               WHEN 5
                    IF WS-COL-CURSOR < 20
                        MOVE 'SEX'     TO LOK-TIPO-DOMINIO
                        MOVE 'SEXO'    TO LOK-CAMPO-ORIGEM
                    ELSE
                        IF WS-COL-CURSOR < 45
                            MOVE 'ECI' TO LOK-TIPO-DOMINIO
                            MOVE 'ECIV'
                                       TO LOK-CAMPO-ORIGEM
                        ELSE
                            MOVE 'RAC' TO LOK-TIPO-DOMINIO
                            MOVE 'RACA'
                                       TO LOK-CAMPO-ORIGEM
                        END-IF
                    END-IF
               WHEN 6
                    IF WS-COL-CURSOR < 40
                        MOVE 'NAC'     TO LOK-TIPO-DOMINIO
                        MOVE 'NACION'  TO LOK-CAMPO-ORIGEM
                    ELSE
                        MOVE 'INS'     TO LOK-TIPO-DOMINIO
                        MOVE 'INSTRU'  TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 7
                    IF WS-COL-CURSOR < 30
                        MOVE 'UFE'     TO LOK-TIPO-DOMINIO
                        MOVE 'UFNASC'  TO LOK-CAMPO-ORIGEM
                    ELSE
                        MOVE 'MUN'     TO LOK-TIPO-DOMINIO
                        MOVE 'MUNNAS'  TO LOK-CAMPO-ORIGEM
                        MOVE WS-T2-UFNASC
                                       TO LOK-UF-FILTRO
                    END-IF
               WHEN 9
                    IF WS-COL-CURSOR > 20
                        MOVE 'DEF'     TO LOK-TIPO-DOMINIO
                        MOVE 'TPDEF'   TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 11
                    IF WS-COL-CURSOR > 30
                        MOVE 'UFE'     TO LOK-TIPO-DOMINIO
                        MOVE 'CTPSUF'  TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 14
                    IF WS-COL-CURSOR < 30
                        MOVE 'TLG'     TO LOK-TIPO-DOMINIO
                        MOVE 'TPLOGR'  TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 17
                    IF WS-COL-CURSOR < 40
                        MOVE 'MUN'     TO LOK-TIPO-DOMINIO
                        MOVE 'MUNIC'   TO LOK-CAMPO-ORIGEM
                        MOVE WS-T2-UF  TO LOK-UF-FILTRO
                    ELSE
                        MOVE 'UFE'     TO LOK-TIPO-DOMINIO
                        MOVE 'UF'      TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 18
                    IF WS-COL-CURSOR > 30
                        MOVE 'EST'     TO LOK-TIPO-DOMINIO
                        MOVE 'ESTAB'   TO LOK-CAMPO-ORIGEM
                    END-IF
               WHEN 19
                    IF WS-COL-CURSOR < 30
                        MOVE 'VIN'     TO LOK-TIPO-DOMINIO
                        MOVE 'VINCUL'  TO LOK-CAMPO-ORIGEM
                    ELSE
                        IF WS-COL-CURSOR < 55
                            MOVE 'JOR' TO LOK-TIPO-DOMINIO
                            MOVE 'JORNAD'
                                       TO LOK-CAMPO-ORIGEM
                        ELSE
                            MOVE 'HOR' TO LOK-TIPO-DOMINIO
                            MOVE 'HORARI'
                                       TO LOK-CAMPO-ORIGEM
                        END-IF
                    END-IF
               WHEN OTHER
                    CONTINUE
           END-EVALUATE.
       4950-FIM.
           EXIT.
      *================================================================*
      * 5000 - EXCLUSAO LOGICA                                         *
      *        RN16 E RN17: PRESERVA O HISTORICO E BLOQUEIA QUANDO     *
      *        EXISTE MOVIMENTO NA COMPETENCIA CORRENTE                *
      *================================================================*
       5000-EXCLUIR SECTION.
       5000-INICIO.
           IF WS-MATRICULA = ZEROS
               MOVE 'MATRICULA OBRIGATORIA PARA A EXCLUSAO'
                                       TO MENSAGO
               MOVE DFHBMBRY           TO MATRICA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-MATRICULA           TO DCL-MATRICULA
           MOVE WS-COMPET-ATUAL        TO DCLM-COMPETENCIA
      *
           EXEC SQL
                SELECT COUNT(*)
                  INTO :WS-QTD-MOVIMENTO
                  FROM SFPADM.TB_MOVIMENTO
                 WHERE MATRICULA   = :DCL-MATRICULA
                   AND COMPETENCIA = :DCLM-COMPETENCIA
                  WITH CS
           END-EXEC
      *
           IF SQLCODE NOT = 0
               PERFORM 9000-TRATAR-ERRO-SQL
           END-IF
      *
           IF WS-QTD-MOVIMENTO > ZEROS
               MOVE 'RN17 - EXISTE MOVIMENTO NA COMPETENCIA CORRENTE'
                                       TO MENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
      *    EXCLUSAO LOGICA: A SITUACAO PASSA A DEMITIDO
           EXEC SQL
                UPDATE SFPADM.TB_EMPREGADO
                   SET SITUACAO        = 'D'
                     , DT_DEMISSAO     = COALESCE(DT_DEMISSAO,
                                                  CURRENT DATE)
                     , TS_ATUALIZACAO  = CURRENT TIMESTAMP
                     , USUARIO_ATUALIZ = :DCL-USUARIO-ATUALIZ
                 WHERE MATRICULA       = :DCL-MATRICULA
                   AND SITUACAO       <> 'D'
           END-EXEC
      *
           EVALUATE SQLCODE
               WHEN 0
                    EXEC CICS SYNCPOINT END-EXEC
                    MOVE 'RN16 - EXCLUSAO LOGICA EFETUADA'
                                       TO MENSAGO
                    PERFORM 3100-CONSULTAR
      *
               WHEN +100
                    MOVE 'MATRICULA INEXISTENTE OU JA EXCLUIDA'
                                       TO MENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
      *
               WHEN OTHER
                    PERFORM 9000-TRATAR-ERRO-SQL
           END-EVALUATE.
       5000-FIM.
           EXIT.
      *
      *================================================================*
      * 5800 - TRANSFERENCIA PARA A TELA DE DEPENDENTES                *
      *================================================================*
       5800-CHAMAR-DEPENDENTES SECTION.
       5800-INICIO.
           MOVE WS-MATRICULA           TO COM-MATRICULA
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE WS-ACAO                TO COM-FUNCAO
      *
           EXEC CICS XCTL
                PROGRAM(WS-PGM-DEPEND)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'PROGRAMA DE DEPENDENTES INDISPONIVEL'
                                       TO MENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       5800-FIM.
           EXIT.
      *
      *
      *----------------------------------------------------------------*
      * 5700 - TROCA DE TELA (F9)                                      *
      *----------------------------------------------------------------*
       5700-IR-TELA-2 SECTION.
       5700-INICIO.
           IF WS-MATRICULA = ZEROS
               MOVE 'MATRICULA OBRIGATORIA PARA OS DADOS PESSOAIS'
                                       TO MENSAGO
               MOVE DFHBMBRY           TO MATRICA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-MATRICULA           TO WS-ES-MATRIC
           PERFORM 3500-CONSULTAR-COMPL
      *
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MENSAGO
               MOVE DFHBMBRY           TO MATRICA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE '2'                    TO WS-ES-TELA
           PERFORM 6300-LIMPAR-MAPA-2
           PERFORM 3400-MOVER-PARA-TELA-2
           PERFORM 3450-DESCREVER-TELA-2
           MOVE 'DADOS PESSOAIS - F9 VOLTA AO CONTRATO'
                                       TO MENSA2O
           PERFORM 6400-ENVIAR-MAPA-2.
       5700-FIM.
           EXIT.
      *
       5750-VOLTAR-TELA-1 SECTION.
       5750-INICIO.
           MOVE '1'                    TO WS-ES-TELA
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3040-MAPA-DO-SNAPSHOT
           MOVE 'DADOS DE CONTRATO - F9 VOLTA AOS DADOS PESSOAIS'
                                       TO MENSAGO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       5750-FIM.
           EXIT.
       5900-ENCERRAR-TRANSACAO SECTION.
       5900-INICIO.
           PERFORM 1400-APAGAR-ESTADO
      *
           EXEC CICS SEND TEXT
                FROM(WS-IDENTIFICACAO)
                LENGTH(LENGTH OF WS-IDENTIFICACAO)
                ERASE
                FREEKB
           END-EXEC
      *
           EXEC CICS RETURN END-EXEC.
       5900-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 - ROTINAS DE TELA                                         *
      *================================================================*
       6000-LIMPAR-MAPA SECTION.
       6000-INICIO.
           MOVE LOW-VALUES             TO MAPEMPO
           MOVE WS-DATA-HOJE           TO DATAO.
       6000-FIM.
           EXIT.
      *
       6100-ENVIAR-MAPA-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(MAPEMPO)
                ERASE
                CURSOR
                FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-MAPA-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA)
                MAPSET(WS-MAPSET)
                FROM(MAPEMPO)
                DATAONLY
                CURSOR
                FREEKB
                ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
      *
       6300-LIMPAR-MAPA-2 SECTION.
       6300-INICIO.
           MOVE LOW-VALUES             TO MAPEMP2O
           MOVE WS-DATA-HOJE           TO DATA2O.
       6300-FIM.
           EXIT.
      *
      *--- DESTAQUE E CURSOR NO CAMPO RECUSADO PELA CRITICA -----------
      * A MARCA VEM DEPOIS DA MONTAGEM DA TELA: O LOW-VALUES DO 6300   *
      * APAGARIA O ATRIBUTO SE ELE FOSSE ACESO NA VALIDACAO.           *
       6350-MARCAR-CAMPO-ERRO SECTION.
       6350-INICIO.
           IF WS-CAMPO-ERRO = SPACES
               GO TO 6350-FIM
           END-IF
      *
           EVALUATE WS-CAMPO-ERRO
               WHEN 'SEXO'
                    MOVE DFHBMBRY  TO SEXOA
                    MOVE -1        TO SEXOL
               WHEN 'ECIV'
                    MOVE DFHBMBRY  TO ECIVA
                    MOVE -1        TO ECIVL
               WHEN 'RACA'
                    MOVE DFHBMBRY  TO RACAA
                    MOVE -1        TO RACAL
               WHEN 'NACION'
                    MOVE DFHBMBRY  TO NACIONA
                    MOVE -1        TO NACIONL
               WHEN 'INSTRU'
                    MOVE DFHBMBRY  TO INSTRUA
                    MOVE -1        TO INSTRUL
               WHEN 'UFNASC'
                    MOVE DFHBMBRY  TO UFNASCA
                    MOVE -1        TO UFNASCL
               WHEN 'MUNNAS'
                    MOVE DFHBMBRY  TO MUNNASA
                    MOVE -1        TO MUNNASL
               WHEN 'NOMEMA'
                    MOVE DFHBMBRY  TO NOMEMAA
                    MOVE -1        TO NOMEMAL
               WHEN 'DEFIC'
                    MOVE DFHBMBRY  TO DEFICA
                    MOVE -1        TO DEFICL
               WHEN 'TPDEF'
                    MOVE DFHBMBRY  TO TPDEFA
                    MOVE -1        TO TPDEFL
               WHEN 'CTPSNR'
                    MOVE DFHBMBRY  TO CTPSNRA
                    MOVE -1        TO CTPSNRL
               WHEN 'CTPSSE'
                    MOVE DFHBMBRY  TO CTPSSEA
                    MOVE -1        TO CTPSSEL
               WHEN 'CTPSUF'
                    MOVE DFHBMBRY  TO CTPSUFA
                    MOVE -1        TO CTPSUFL
               WHEN 'RGNUM'
                    MOVE DFHBMBRY  TO RGNUMA
                    MOVE -1        TO RGNUML
               WHEN 'RGORG'
                    MOVE DFHBMBRY  TO RGORGA
                    MOVE -1        TO RGORGL
               WHEN 'TITELE'
                    MOVE DFHBMBRY  TO TITELEA
                    MOVE -1        TO TITELEL
               WHEN 'TPLOGR'
                    MOVE DFHBMBRY  TO TPLOGRA
                    MOVE -1        TO TPLOGRL
               WHEN 'LOGRAD'
                    MOVE DFHBMBRY  TO LOGRADA
                    MOVE -1        TO LOGRADL
               WHEN 'NUMERO'
                    MOVE DFHBMBRY  TO NUMEROA
                    MOVE -1        TO NUMEROL
               WHEN 'COMPLE'
                    MOVE DFHBMBRY  TO COMPLEA
                    MOVE -1        TO COMPLEL
               WHEN 'BAIRRO'
                    MOVE DFHBMBRY  TO BAIRROA
                    MOVE -1        TO BAIRROL
               WHEN 'CEP'
                    MOVE DFHBMBRY  TO CEPA
                    MOVE -1        TO CEPL
               WHEN 'MUNIC'
                    MOVE DFHBMBRY  TO MUNICA
                    MOVE -1        TO MUNICL
               WHEN 'UF'
                    MOVE DFHBMBRY  TO UFA
                    MOVE -1        TO UFL
               WHEN 'TELEF'
                    MOVE DFHBMBRY  TO TELEFA
                    MOVE -1        TO TELEFL
               WHEN 'ESTAB'
                    MOVE DFHBMBRY  TO ESTABA
                    MOVE -1        TO ESTABL
               WHEN 'VINCUL'
                    MOVE DFHBMBRY  TO VINCULA
                    MOVE -1        TO VINCULL
               WHEN 'JORNAD'
                    MOVE DFHBMBRY  TO JORNADA
                    MOVE -1        TO JORNADL
               WHEN 'HORARI'
                    MOVE DFHBMBRY  TO HORARIA
                    MOVE -1        TO HORARIL
               WHEN OTHER
                    CONTINUE
           END-EVALUATE.
       6350-FIM.
           EXIT.
      *
       6400-ENVIAR-MAPA-2 SECTION.
       6400-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA2)
                MAPSET(WS-MAPSET)
                FROM(MAPEMP2O)
                ERASE
                CURSOR
                FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6400-FIM.
           EXIT.
      *================================================================*
      * 7000 - ROTINAS DE APOIO                                        *
      *================================================================*
       7100-CARREGAR-PARAMETROS SECTION.
       7100-INICIO.
           EXEC SQL
                SELECT COALESCE(MAX(LIMITE),0)
                  INTO :WS-SALARIO-MINIMO
                  FROM SFPADM.TB_TABELA_LEGAL
                 WHERE TIPO_TABELA = 'PAR'
                   AND CHAVE       = 'SALARIO-MINIMO'
                  WITH UR
           END-EXEC
      *
           IF SQLCODE NOT = 0 OR WS-SALARIO-MINIMO = ZEROS
               MOVE 1518,00            TO WS-SALARIO-MINIMO
           END-IF
      *
           EXEC CICS ASKTIME
                ABSTIME(WS-HORA-ABS)
           END-EXEC
      *
           EXEC CICS FORMATTIME
                ABSTIME(WS-HORA-ABS)
                YYYYMMDD(WS-DATA-HOJE)
           END-EXEC
      *
           COMPUTE WS-COMPET-ATUAL = WS-DATA-HOJE / 100.
       7100-FIM.
           EXIT.
      *
       7200-DB2-PARA-8 SECTION.
       7200-INICIO.
           MOVE WS-DB2-ANO             TO WS-D8-ANO
           MOVE WS-DB2-MES             TO WS-D8-MES
           MOVE WS-DB2-DIA             TO WS-D8-DIA.
       7200-FIM.
           EXIT.
      *
       7300-8-PARA-DB2 SECTION.
       7300-INICIO.
           MOVE WS-D8-ANO              TO WS-DB2-ANO
           MOVE WS-D8-MES              TO WS-DB2-MES
           MOVE WS-D8-DIA              TO WS-DB2-DIA.
       7300-FIM.
           EXIT.
      *
      *
      *--- DES-EDICAO DE CAMPO DIGITADO (MESMA ROTINA DO SFP0130) -----
      * O BMS DEVOLVE O CAMPO ALINHADO A ESQUERDA, LOGO UM MOVE DIRETO *
      * PARA ITEM NUMERICO DARIA VALOR ERRADO.                         *
       7400-DE-EDITAR SECTION.
       7400-INICIO.
           MOVE 'S'                    TO WS-ED-OK
           MOVE ZEROS                  TO WS-ED-VALOR
                                          WS-ED-TAM
                                          WS-ED-VIRGULA
                                          WS-ED-INVALIDOS
                                          WS-ED-TAM-INT
                                          WS-ED-TAM-DEC
           MOVE SPACES                 TO WS-ED-COMPACTO
      *
           PERFORM VARYING WS-IX FROM 1 BY 1 UNTIL WS-IX > 20
               EVALUATE WS-ED-CAMPO(WS-IX:1)
               WHEN SPACE
               WHEN LOW-VALUE
                   CONTINUE
               WHEN ','
                   ADD 1               TO WS-ED-VIRGULA
                   MOVE WS-ED-TAM      TO WS-ED-TAM-INT
               WHEN '0' THRU '9'
                   ADD 1               TO WS-ED-TAM
                   MOVE WS-ED-CAMPO(WS-IX:1)
                                          TO WS-ED-COMPACTO
                                          (WS-ED-TAM:1)
               WHEN OTHER
                   ADD 1               TO WS-ED-INVALIDOS
               END-EVALUATE
           END-PERFORM
      *
           IF WS-ED-VIRGULA = ZEROS
               MOVE WS-ED-TAM          TO WS-ED-TAM-INT
           END-IF
           COMPUTE WS-ED-TAM-DEC = WS-ED-TAM - WS-ED-TAM-INT
      *
           EVALUATE TRUE
           WHEN WS-ED-INVALIDOS > ZEROS
           WHEN WS-ED-VIRGULA > 1
           WHEN WS-ED-TAM = ZEROS
           WHEN WS-ED-TAM-INT > 14
           WHEN WS-ED-TAM-DEC > 4
               MOVE 'N'                TO WS-ED-OK
           END-EVALUATE
      *
           IF WS-ED-OK = 'S'
               PERFORM 7450-REMONTAR-VALOR
           END-IF.
       7400-FIM.
           EXIT.
      *
       7450-REMONTAR-VALOR SECTION.
       7450-INICIO.
           MOVE ZEROS                  TO WS-ED-INT-X
           IF WS-ED-TAM-INT > ZEROS
               COMPUTE WS-IX = 15 - WS-ED-TAM-INT
               MOVE WS-ED-COMPACTO(1:WS-ED-TAM-INT)
                                          TO WS-ED-INT-X
                                          (WS-IX:WS-ED-TAM-INT)
           END-IF
           MOVE WS-ED-INT-X            TO WS-ED-INT
      *
           MOVE ZEROS                  TO WS-ED-CENT-X
           IF WS-ED-TAM-DEC > ZEROS
               COMPUTE WS-IX = WS-ED-TAM-INT + 1
               MOVE WS-ED-COMPACTO(WS-IX:WS-ED-TAM-DEC)
                                          TO WS-ED-CENT-X
                                          (1:WS-ED-TAM-DEC)
           END-IF
           MOVE WS-ED-CENT-X           TO WS-ED-CENT
      *
           COMPUTE WS-ED-VALOR = WS-ED-INT
                               + WS-ED-CENT / 10000.
       7450-FIM.
           EXIT.
      *

       8000-RETORNAR SECTION.
       8000-INICIO.
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
           PERFORM 1300-GRAVAR-ESTADO
      *
           EXEC CICS RETURN
                TRANSID(WS-TRANSACAO)
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       8000-FIM.
           EXIT.
      *
      *================================================================*
      * 9000 - TRATAMENTO DE ERROS                                     *
      *================================================================*
       9000-TRATAR-ERRO-SQL SECTION.
       9000-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
      *
           MOVE SPACES                 TO WS-MENSAGEM
           STRING 'ERRO DB2 SQLCODE ' SQLCODE
                  ' NO CADASTRO DE EMPREGADOS - ACIONE O SUPORTE'
                  DELIMITED BY SIZE INTO WS-MENSAGEM
      *
           IF WS-NA-TELA-2
               MOVE WS-MENSAGEM        TO MENSA2O
               PERFORM 6400-ENVIAR-MAPA-2
           ELSE
               MOVE WS-MENSAGEM        TO MENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       9000-FIM.
           EXIT.
      *
       9999-ABEND SECTION.
       9999-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
      *
           EXEC CICS SEND TEXT
                FROM(WS-IDENTIFICACAO)
                LENGTH(LENGTH OF WS-IDENTIFICACAO)
                ERASE FREEKB
           END-EXEC
      *
           EXEC CICS RETURN END-EXEC.
       9999-FIM.
           EXIT.
