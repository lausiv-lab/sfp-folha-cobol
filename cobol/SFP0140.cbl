      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0140                                             *
      * TRANSACAO: SF06                                                *
      * MAPSET   : SFPM05   MAPA: MAPCARG                              *
      * FUNCAO   : CADASTRO DE CARGOS E PISOS SALARIAIS                *
      *            GRADE DE 12 LINHAS COM PAGINACAO EM VSAM            *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE OS TRADUTORES CICS E DB2 ANTES DO COMPILADOR *
      * COBOL. NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME.            *
      *----------------------------------------------------------------*
      * O ARQUIVO SFPCAR (VSAM KSDS, CHAVE CAR-CODIGO) TEM OS CARGOS.  *
      * O DB2 ENTRA EM DUAS CONSULTAS APENAS: O SALARIO MINIMO VIGENTE *
      * E A CONTAGEM DE EMPREGADOS VINCULADOS AO CARGO (RN09).         *
      *----------------------------------------------------------------*
      * ACOES ACEITAS EM CADA LINHA DA GRADE                           *
      *   BRANCO - LINHA INALTERADA                                    *
      *   I      - INCLUIR O CARGO                                     *
      *   A      - ALTERAR OS CAMPOS DIGITADOS                         *
      *   E      - EXCLUIR O CARGO                                     *
      *----------------------------------------------------------------*
      * O MAPA USA CTRL=(FREEKB,FRSET): NO RECEIVE SO VOLTAM OS        *
      * CAMPOS QUE O USUARIO DIGITOU E OS DEMAIS CHEGAM EM LOW-VALUES. *
      * POR ISSO O CODIGO DE CADA LINHA DA PAGINA FICA GUARDADO NA     *
      * COMMAREA (WS-ESTADO) E NAO PODE SER LIDO DA TELA, E CADA CAMPO *
      * CARREGA UM INDICADOR -INF QUE DIZ SE FOI DIGITADO NESTA        *
      * INTERACAO. NA ALTERACAO SO OS CAMPOS COM -INF IGUAL A S        *
      * SOBREPOEM O REGISTRO LIDO DO ARQUIVO.                          *
      *----------------------------------------------------------------*
      * PISO E TETO CHEGAM DA TELA COMO NUMERICO EDITADO ALINHADO A    *
      * ESQUERDA. NAO SE PODE DES-EDITAR ISSO COM UM MOVE DIRETO: O    *
      * PARAGRAFO 7400 CRITICA OS CARACTERES E MONTA O VALOR A MAO.    *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO                                              *
      *  RN01 - CODIGO DO CARGO ENTRE 0001 E 9999                      *
      *  RN02 - DESCRICAO OBRIGATORIA                                  *
      *  RN03 - CBO COM 6 DIGITOS; A FAMILIA SAO OS 4 PRIMEIROS        *
      *  RN04 - NIVEL EM O, T, E, G OU D                               *
      *  RN05 - PISO NAO PODE FICAR ABAIXO DO SALARIO MINIMO           *
      *  RN06 - TETO NAO PODE FICAR ABAIXO DO PISO                     *
      *  RN07 - INCLUSAO NAO PODE DUPLICAR CODIGO EXISTENTE            *
      *  RN08 - ALTERACAO E EXCLUSAO EXIGEM CARGO JA CADASTRADO        *
      *  RN09 - NAO SE EXCLUI CARGO COM EMPREGADO NAO DEMITIDO         *
      *  RN10 - CARGA HORARIA MENSAL MAIOR QUE ZERO                    *
      *  RN11 - SITUACAO EM A OU E                                     *
      *----------------------------------------------------------------*
      * A GRADE DO SFPM05 TEM COLUNA PARA CARGA HORARIA (CH) E PARA    *
      * SITUACAO (S). A EXCLUSAO PELA ACAO E E LOGICA: MARCA           *
      * CAR-SITUACAO COM E, E O CARGO CONTINUA NA GRADE PARA PODER     *
      * VOLTAR A A. NA INCLUSAO A CARGA OMITIDA SAI COMO 220 E A       *
      * SITUACAO COMO A. OS INDICADORES DE INSALUBRIDADE,              *
      * PERICULOSIDADE E CONFIANCA CONTINUAM SEM CAMPO NO MAPA: NA     *
      * INCLUSAO RECEBEM N E NA ALTERACAO SAO PRESERVADOS.             *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0140.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF06'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0140 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM05 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPCARG'.
           05  WS-ARQUIVO          PIC X(008) VALUE 'SFPCAR  '.
           05  WS-TITULO           PIC X(050) VALUE
               'SFP0140 - CADASTRO DE CARGOS - FIM DA SESSAO'.
           05  WS-LINHAS-PAGINA    PIC S9(004) COMP VALUE 12.
           05  WS-CARGA-PADRAO     PIC 9(003) VALUE 220.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM05.
      *
       COPY SFPWCAR.
      *
       EXEC SQL INCLUDE SQLCA END-EXEC.
      *
      *--- TABELA INTERNA DA GRADE (ESPELHO DA TELA) -------------------
       01  WS-GRADE.
           05  WS-LINHA OCCURS 12 TIMES.
               10  WS-LN-ACAO      PIC X(001).
               10  WS-LN-CODIGO    PIC 9(004).
               10  WS-LN-DESCR     PIC X(035).
               10  WS-LN-CBO       PIC 9(006).
               10  WS-LN-NIVEL     PIC X(001).
               10  WS-LN-PISO      PIC 9(009)V99.
               10  WS-LN-TETO      PIC 9(009)V99.
               10  WS-LN-CARGA     PIC 9(003).
               10  WS-LN-SITUAC    PIC X(001).
               10  WS-LN-DES-INF   PIC X(001).
               10  WS-LN-CBO-INF   PIC X(001).
               10  WS-LN-NIV-INF   PIC X(001).
               10  WS-LN-PIS-INF   PIC X(001).
               10  WS-LN-TET-INF   PIC X(001).
               10  WS-LN-CAR-INF   PIC X(001).
               10  WS-LN-SIT-INF   PIC X(001).
               10  WS-LN-MAL-FORM  PIC X(001).
      *
      *--- PAGINA LIDA DE TRAS PARA FRENTE (F7) ------------------------
       01  WS-REVERSO.
           05  WS-REV-REG OCCURS 12 TIMES PIC X(120).
      *
      *--- CAMPOS BRUTOS DE UMA LINHA RECEBIDA DO MAPA -----------------
       01  WS-CAMPOS.
           05  WS-CP-ACAO          PIC X(001) VALUE SPACES.
           05  WS-CP-CODIGO        PIC X(004) VALUE SPACES.
           05  WS-CP-DESCR         PIC X(035) VALUE SPACES.
           05  WS-CP-CBO           PIC X(006) VALUE SPACES.
           05  WS-CP-NIVEL         PIC X(001) VALUE SPACES.
           05  WS-CP-PISO          PIC X(010) VALUE SPACES.
           05  WS-CP-TETO          PIC X(010) VALUE SPACES.
           05  WS-CP-CARGA         PIC X(003) VALUE SPACES.
           05  WS-CP-SITUAC        PIC X(001) VALUE SPACES.
      *
      *--- ESTADO DA PAGINA - VIVE NA COMMAREA A PARTIR DO BYTE 121 ----
       01  WS-ESTADO.
           05  WS-ES-PAGINA        PIC 9(003) VALUE ZEROS.
           05  WS-ES-PRIMEIRA      PIC 9(004) VALUE ZEROS.
           05  WS-ES-ULTIMA        PIC 9(004) VALUE ZEROS.
           05  WS-ES-CODIGO OCCURS 12 TIMES PIC 9(004).
      *
      *--- AREA DE TRABALHO --------------------------------------------
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-FIM-BROWSE       PIC X(001) VALUE 'N'.
               88  FIM-BROWSE          VALUE 'S'.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-IY               PIC S9(004) COMP VALUE ZEROS.
           05  WS-QTD-LINHAS       PIC S9(004) COMP VALUE ZEROS.
           05  WS-QTD-REV          PIC S9(004) COMP VALUE ZEROS.
           05  WS-CHAVE-BUSCA      PIC 9(004) VALUE ZEROS.
           05  WS-PULAR-IGUAL      PIC X(001) VALUE 'N'.
           05  WS-INCLUIDOS        PIC 9(003) VALUE ZEROS.
           05  WS-ALTERADOS        PIC 9(003) VALUE ZEROS.
           05  WS-EXCLUIDOS        PIC 9(003) VALUE ZEROS.
           05  WS-LINHA-ERRO       PIC 9(002) VALUE ZEROS.
           05  WS-TEXTO-ERRO       PIC X(060) VALUE SPACES.
           05  WS-HORA-ABS         PIC S9(015) COMP-3 VALUE ZEROS.
           05  WS-DATA-HOJE        PIC 9(008) VALUE ZEROS.
           05  WS-SALARIO-MINIMO   PIC 9(009)V99 VALUE ZEROS.
           05  WS-QTD-EMPREG       PIC S9(009) COMP VALUE ZEROS.
           05  WS-CARGO-SQL        PIC S9(004) COMP VALUE ZEROS.
      *
      *--- DATA DE HOJE QUEBRADA PARA MONTAR DD/MM/AAAA NO MAPA --------
       01  WS-DATA-QUEBRA.
           05  WS-DQ-ANO           PIC 9(004).
           05  WS-DQ-MES           PIC 9(002).
           05  WS-DQ-DIA           PIC 9(002).
      *
       01  WS-DATA-TELA.
           05  WS-DT-DIA           PIC 9(002).
           05  FILLER              PIC X(001) VALUE '/'.
           05  WS-DT-MES           PIC 9(002).
           05  FILLER              PIC X(001) VALUE '/'.
           05  WS-DT-ANO           PIC 9(004).
      *
      *--- RESUMO DA GRAVACAO EXIBIDO NA LINHA DE MENSAGEM -------------
       01  WS-MSG-GRAVOU.
           05  FILLER              PIC X(009) VALUE 'GRAVADO: '.
           05  WS-MSG-INC          PIC ZZ9.
           05  FILLER              PIC X(012) VALUE ' INCLUIDOS, '.
           05  WS-MSG-ALT          PIC ZZ9.
           05  FILLER              PIC X(012) VALUE ' ALTERADOS, '.
           05  WS-MSG-EXC          PIC ZZ9.
           05  FILLER              PIC X(010) VALUE ' EXTINTOS '.
      *
      *--- DES-EDICAO DE PISO E TETO (VER 7400) ------------------------
       01  WS-EDIT.
           05  WS-ED-CAMPO         PIC X(013) VALUE SPACES.
           05  WS-ED-COMPACTO      PIC X(013) VALUE SPACES.
           05  WS-ED-TAM           PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VIRGULA       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-INVALIDOS     PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-OK            PIC X(001) VALUE 'S'.
           05  WS-ED-VALOR         PIC 9(009)V99 VALUE ZEROS.
           05  WS-ED-INT-X         PIC X(009) VALUE SPACES.
           05  WS-ED-INT           PIC 9(009) VALUE ZEROS.
           05  WS-ED-CENT-X        PIC X(002) VALUE SPACES.
           05  WS-ED-CENT          PIC 9(002) VALUE ZEROS.
           05  WS-ED-TAM-INT       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-TAM-DEC       PIC S9(004) COMP VALUE ZEROS.
      *
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
           EXEC CICS HANDLE ABEND LABEL(9999-ABEND) END-EXEC
      *
           PERFORM 7000-OBTER-DATA
           PERFORM 7100-CARREGAR-PARAMETROS
      *
           IF EIBCALEN = ZEROS
               PERFORM 1000-PRIMEIRA-VEZ
           ELSE
               MOVE DFHCOMMAREA        TO COMMAREA-SFP
               MOVE COM-AREA-TRABALHO
                    (121:LENGTH OF WS-ESTADO) TO WS-ESTADO
               MOVE COM-AREA-TRABALHO
                    (1:LENGTH OF AREA-LOOKUP) TO AREA-LOOKUP
      *
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
       1000-PRIMEIRA-VEZ SECTION.
       1000-INICIO.
           INITIALIZE COMMAREA-SFP
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           MOVE EIBTRMID               TO COM-TERMINAL
           SET COM-PRIMEIRA-VEZ        TO TRUE
      *
           INITIALIZE WS-ESTADO
           INITIALIZE WS-GRADE
           MOVE 1                      TO WS-ES-PAGINA
           MOVE ZEROS                  TO WS-QTD-LINHAS
      *
           MOVE LOW-VALUES             TO MAPCARGO
           MOVE WS-DATA-TELA           TO MDATAO
           MOVE WS-ES-PAGINA           TO MPAGO
           MOVE 'INFORME O CARGO INICIAL E TECLE F5 PARA CARREGAR'
                                       TO MMENSAGO
      *
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPCARGO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - RETORNO DA JANELA F4 (SFP0900). O SFP0900 DEVOLVE O     *
      * CONTROLE POR XCTL, LOGO ESTA E UMA NOVA ENTRADA NO PROGRAMA E  *
      * A TELA PRECISA SER REMONTADA DO ARQUIVO.                       *
      *----------------------------------------------------------------*
       1100-VOLTA-DO-LOOKUP SECTION.
       1100-INICIO.
           IF LOK-SELECIONOU
               IF LOK-COD-SELECIONADO(1:4) NUMERIC
                   MOVE LOK-COD-SELECIONADO(1:4)
                                       TO WS-CHAVE-BUSCA
               END-IF
           END-IF
      *
           MOVE SPACES                 TO LOK-PGM-CHAMADOR
           SET LOK-EM-CURSO            TO TRUE
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
      *
           MOVE 'N'                    TO WS-PULAR-IGUAL
           MOVE 1                      TO WS-ES-PAGINA
           PERFORM 3800-LER-ADIANTE
           PERFORM 3950-FIXAR-PAGINA
      *
           PERFORM 6000-TABELA-PARA-MAPA
           MOVE WS-CHAVE-BUSCA         TO MCARGOO
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'NENHUM CARGO A PARTIR DESSE CODIGO'
                                       TO MMENSAGO
           END-IF
           PERFORM 6100-ENVIAR-ERASE.
       1100-FIM.
           EXIT.
      *
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           EVALUATE EIBAID
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
               WHEN DFHPF4
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4500-CHAMAR-LOOKUP
               WHEN DFHPF5
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3500-CARREGAR-PAGINA
               WHEN DFHPF6
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-GRAVAR-GRADE
               WHEN DFHPF7
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3700-PAGINA-ANTERIOR
               WHEN DFHPF8
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3600-PAGINA-SEGUINTE
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3500-CARREGAR-PAGINA
               WHEN OTHER
                    MOVE 'TECLA INVALIDA PARA ESTA TRANSACAO'
                                       TO WS-MENSAGEM
                    PERFORM 6300-AVISAR
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
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPCARGI)
                RESP(WS-RESP)
           END-EXEC
      *
           IF MCARGOI NOT = LOW-VALUES AND MCARGOI NOT = SPACES
               MOVE MCARGOI            TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
                  AND WS-ED-TAM-INT <= 4
                   MOVE WS-ED-INT      TO WS-CHAVE-BUSCA
               END-IF
           END-IF
      *
           PERFORM 3100-MAPA-PARA-TABELA.
       3000-FIM.
           EXIT.
      *
       3100-MAPA-PARA-TABELA SECTION.
       3100-INICIO.
           INITIALIZE WS-GRADE
           PERFORM 3110-CARREGAR-LINHA-01
           PERFORM 3111-CARREGAR-LINHA-02
           PERFORM 3112-CARREGAR-LINHA-03
           PERFORM 3113-CARREGAR-LINHA-04
           PERFORM 3114-CARREGAR-LINHA-05
           PERFORM 3115-CARREGAR-LINHA-06
           PERFORM 3116-CARREGAR-LINHA-07
           PERFORM 3117-CARREGAR-LINHA-08
           PERFORM 3118-CARREGAR-LINHA-09
           PERFORM 3119-CARREGAR-LINHA-10
           PERFORM 3120-CARREGAR-LINHA-11
           PERFORM 3121-CARREGAR-LINHA-12.
       3100-FIM.
           EXIT.
      *
       3110-CARREGAR-LINHA-01 SECTION.
       3110-INICIO.
           MOVE 1                      TO WS-IX
           MOVE ACAO1I                 TO WS-CP-ACAO
           MOVE COD1I                  TO WS-CP-CODIGO
           MOVE DES1I                  TO WS-CP-DESCR
           MOVE CBO1I                  TO WS-CP-CBO
           MOVE NIV1I                  TO WS-CP-NIVEL
           MOVE PIS1I                  TO WS-CP-PISO
           MOVE TET1I                  TO WS-CP-TETO
           MOVE CHR1I                  TO WS-CP-CARGA
           MOVE SIT1I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3110-FIM.
           EXIT.
      *
       3111-CARREGAR-LINHA-02 SECTION.
       3111-INICIO.
           MOVE 2                      TO WS-IX
           MOVE ACAO2I                 TO WS-CP-ACAO
           MOVE COD2I                  TO WS-CP-CODIGO
           MOVE DES2I                  TO WS-CP-DESCR
           MOVE CBO2I                  TO WS-CP-CBO
           MOVE NIV2I                  TO WS-CP-NIVEL
           MOVE PIS2I                  TO WS-CP-PISO
           MOVE TET2I                  TO WS-CP-TETO
           MOVE CHR2I                  TO WS-CP-CARGA
           MOVE SIT2I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3111-FIM.
           EXIT.
      *
       3112-CARREGAR-LINHA-03 SECTION.
       3112-INICIO.
           MOVE 3                      TO WS-IX
           MOVE ACAO3I                 TO WS-CP-ACAO
           MOVE COD3I                  TO WS-CP-CODIGO
           MOVE DES3I                  TO WS-CP-DESCR
           MOVE CBO3I                  TO WS-CP-CBO
           MOVE NIV3I                  TO WS-CP-NIVEL
           MOVE PIS3I                  TO WS-CP-PISO
           MOVE TET3I                  TO WS-CP-TETO
           MOVE CHR3I                  TO WS-CP-CARGA
           MOVE SIT3I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3112-FIM.
           EXIT.
      *
       3113-CARREGAR-LINHA-04 SECTION.
       3113-INICIO.
           MOVE 4                      TO WS-IX
           MOVE ACAO4I                 TO WS-CP-ACAO
           MOVE COD4I                  TO WS-CP-CODIGO
           MOVE DES4I                  TO WS-CP-DESCR
           MOVE CBO4I                  TO WS-CP-CBO
           MOVE NIV4I                  TO WS-CP-NIVEL
           MOVE PIS4I                  TO WS-CP-PISO
           MOVE TET4I                  TO WS-CP-TETO
           MOVE CHR4I                  TO WS-CP-CARGA
           MOVE SIT4I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3113-FIM.
           EXIT.
      *
       3114-CARREGAR-LINHA-05 SECTION.
       3114-INICIO.
           MOVE 5                      TO WS-IX
           MOVE ACAO5I                 TO WS-CP-ACAO
           MOVE COD5I                  TO WS-CP-CODIGO
           MOVE DES5I                  TO WS-CP-DESCR
           MOVE CBO5I                  TO WS-CP-CBO
           MOVE NIV5I                  TO WS-CP-NIVEL
           MOVE PIS5I                  TO WS-CP-PISO
           MOVE TET5I                  TO WS-CP-TETO
           MOVE CHR5I                  TO WS-CP-CARGA
           MOVE SIT5I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3114-FIM.
           EXIT.
      *
       3115-CARREGAR-LINHA-06 SECTION.
       3115-INICIO.
           MOVE 6                      TO WS-IX
           MOVE ACAO6I                 TO WS-CP-ACAO
           MOVE COD6I                  TO WS-CP-CODIGO
           MOVE DES6I                  TO WS-CP-DESCR
           MOVE CBO6I                  TO WS-CP-CBO
           MOVE NIV6I                  TO WS-CP-NIVEL
           MOVE PIS6I                  TO WS-CP-PISO
           MOVE TET6I                  TO WS-CP-TETO
           MOVE CHR6I                  TO WS-CP-CARGA
           MOVE SIT6I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3115-FIM.
           EXIT.
      *
       3116-CARREGAR-LINHA-07 SECTION.
       3116-INICIO.
           MOVE 7                      TO WS-IX
           MOVE ACAO7I                 TO WS-CP-ACAO
           MOVE COD7I                  TO WS-CP-CODIGO
           MOVE DES7I                  TO WS-CP-DESCR
           MOVE CBO7I                  TO WS-CP-CBO
           MOVE NIV7I                  TO WS-CP-NIVEL
           MOVE PIS7I                  TO WS-CP-PISO
           MOVE TET7I                  TO WS-CP-TETO
           MOVE CHR7I                  TO WS-CP-CARGA
           MOVE SIT7I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3116-FIM.
           EXIT.
      *
       3117-CARREGAR-LINHA-08 SECTION.
       3117-INICIO.
           MOVE 8                      TO WS-IX
           MOVE ACAO8I                 TO WS-CP-ACAO
           MOVE COD8I                  TO WS-CP-CODIGO
           MOVE DES8I                  TO WS-CP-DESCR
           MOVE CBO8I                  TO WS-CP-CBO
           MOVE NIV8I                  TO WS-CP-NIVEL
           MOVE PIS8I                  TO WS-CP-PISO
           MOVE TET8I                  TO WS-CP-TETO
           MOVE CHR8I                  TO WS-CP-CARGA
           MOVE SIT8I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3117-FIM.
           EXIT.
      *
       3118-CARREGAR-LINHA-09 SECTION.
       3118-INICIO.
           MOVE 9                      TO WS-IX
           MOVE ACAO9I                 TO WS-CP-ACAO
           MOVE COD9I                  TO WS-CP-CODIGO
           MOVE DES9I                  TO WS-CP-DESCR
           MOVE CBO9I                  TO WS-CP-CBO
           MOVE NIV9I                  TO WS-CP-NIVEL
           MOVE PIS9I                  TO WS-CP-PISO
           MOVE TET9I                  TO WS-CP-TETO
           MOVE CHR9I                  TO WS-CP-CARGA
           MOVE SIT9I                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3118-FIM.
           EXIT.
      *
       3119-CARREGAR-LINHA-10 SECTION.
       3119-INICIO.
           MOVE 10                     TO WS-IX
           MOVE ACAOAI                 TO WS-CP-ACAO
           MOVE CODAI                  TO WS-CP-CODIGO
           MOVE DESAI                  TO WS-CP-DESCR
           MOVE CBOAI                  TO WS-CP-CBO
           MOVE NIVAI                  TO WS-CP-NIVEL
           MOVE PISAI                  TO WS-CP-PISO
           MOVE TETAI                  TO WS-CP-TETO
           MOVE CHRAI                  TO WS-CP-CARGA
           MOVE SITAI                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3119-FIM.
           EXIT.
      *
       3120-CARREGAR-LINHA-11 SECTION.
       3120-INICIO.
           MOVE 11                     TO WS-IX
           MOVE ACAOBI                 TO WS-CP-ACAO
           MOVE CODBI                  TO WS-CP-CODIGO
           MOVE DESBI                  TO WS-CP-DESCR
           MOVE CBOBI                  TO WS-CP-CBO
           MOVE NIVBI                  TO WS-CP-NIVEL
           MOVE PISBI                  TO WS-CP-PISO
           MOVE TETBI                  TO WS-CP-TETO
           MOVE CHRBI                  TO WS-CP-CARGA
           MOVE SITBI                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3120-FIM.
           EXIT.
      *
       3121-CARREGAR-LINHA-12 SECTION.
       3121-INICIO.
           MOVE 12                     TO WS-IX
           MOVE ACAOCI                 TO WS-CP-ACAO
           MOVE CODCI                  TO WS-CP-CODIGO
           MOVE DESCI                  TO WS-CP-DESCR
           MOVE CBOCI                  TO WS-CP-CBO
           MOVE NIVCI                  TO WS-CP-NIVEL
           MOVE PISCI                  TO WS-CP-PISO
           MOVE TETCI                  TO WS-CP-TETO
           MOVE CHRCI                  TO WS-CP-CARGA
           MOVE SITCI                  TO WS-CP-SITUAC
           PERFORM 3150-GUARDAR-LINHA.
       3121-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3150 - CRITICA DE FORMA E GUARDA DE UMA LINHA RECEBIDA.        *
      * CAMPO EM LOW-VALUES SIGNIFICA NAO DIGITADO (FRSET), E NAO      *
      * CAMPO APAGADO: PARA ESSES O INDICADOR -INF FICA EM N E A       *
      * ALTERACAO PRESERVA O QUE ESTA NO ARQUIVO.                      *
      *----------------------------------------------------------------*
       3150-GUARDAR-LINHA SECTION.
       3150-INICIO.
           MOVE SPACES                 TO WS-LN-ACAO(WS-IX)
                                          WS-LN-DESCR(WS-IX)
                                          WS-LN-NIVEL(WS-IX)
                                          WS-LN-SITUAC(WS-IX)
           MOVE 'N'                    TO WS-LN-DES-INF(WS-IX)
                                          WS-LN-CBO-INF(WS-IX)
                                          WS-LN-NIV-INF(WS-IX)
                                          WS-LN-PIS-INF(WS-IX)
                                          WS-LN-TET-INF(WS-IX)
                                          WS-LN-CAR-INF(WS-IX)
                                          WS-LN-SIT-INF(WS-IX)
                                          WS-LN-MAL-FORM(WS-IX)
           MOVE ZEROS                  TO WS-LN-CBO(WS-IX)
                                          WS-LN-PISO(WS-IX)
                                          WS-LN-TETO(WS-IX)
                                          WS-LN-CARGA(WS-IX)
      *
           IF WS-CP-ACAO NOT = LOW-VALUES
               MOVE FUNCTION UPPER-CASE(WS-CP-ACAO)
                                       TO WS-LN-ACAO(WS-IX)
           END-IF
      *
      *--- CODIGO: O DIGITADO PREVALECE SOBRE O DA PAGINA --------------
           MOVE WS-ES-CODIGO(WS-IX)    TO WS-LN-CODIGO(WS-IX)
           IF WS-CP-CODIGO NOT = LOW-VALUES
              AND WS-CP-CODIGO NOT = SPACES
               MOVE WS-CP-CODIGO       TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
                  AND WS-ED-TAM-INT <= 4
                   MOVE WS-ED-INT      TO WS-LN-CODIGO(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-DESCR NOT = LOW-VALUES
              AND WS-CP-DESCR NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-DESCR)
                                       TO WS-LN-DESCR(WS-IX)
               MOVE 'S'                TO WS-LN-DES-INF(WS-IX)
           END-IF
      *
           IF WS-CP-CBO NOT = LOW-VALUES
              AND WS-CP-CBO NOT = SPACES
               MOVE 'S'                TO WS-LN-CBO-INF(WS-IX)
               MOVE WS-CP-CBO          TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
                  AND WS-ED-TAM-INT <= 6
                   MOVE WS-ED-INT      TO WS-LN-CBO(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-NIVEL NOT = LOW-VALUES
              AND WS-CP-NIVEL NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-NIVEL)
                                       TO WS-LN-NIVEL(WS-IX)
               MOVE 'S'                TO WS-LN-NIV-INF(WS-IX)
           END-IF
      *
           IF WS-CP-PISO NOT = LOW-VALUES
              AND WS-CP-PISO NOT = SPACES
               MOVE 'S'                TO WS-LN-PIS-INF(WS-IX)
               MOVE WS-CP-PISO         TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-LN-PISO(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-TETO NOT = LOW-VALUES
              AND WS-CP-TETO NOT = SPACES
               MOVE 'S'                TO WS-LN-TET-INF(WS-IX)
               MOVE WS-CP-TETO         TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-LN-TETO(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-CARGA NOT = LOW-VALUES
              AND WS-CP-CARGA NOT = SPACES
               MOVE 'S'                TO WS-LN-CAR-INF(WS-IX)
               MOVE WS-CP-CARGA        TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
                  AND WS-ED-TAM-INT <= 3
                   MOVE WS-ED-INT      TO WS-LN-CARGA(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-SITUAC NOT = LOW-VALUES
              AND WS-CP-SITUAC NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-SITUAC)
                                       TO WS-LN-SITUAC(WS-IX)
               MOVE 'S'                TO WS-LN-SIT-INF(WS-IX)
           END-IF.
       3150-FIM.
           EXIT.
      *
      *================================================================*
      * 3500 A 3950 - CARGA E PAGINACAO DA GRADE                       *
      *                                                                *
      * A PAGINA SEGUINTE RELE A PARTIR DA ULTIMA CHAVE EXIBIDA. A     *
      * PAGINA ANTERIOR USA READPREV A PARTIR DA PRIMEIRA CHAVE DA     *
      * PAGINA ATUAL, EVITANDO REPERCORRER O ARQUIVO DESDE O INICIO.   *
      *                                                                *
      * ATENCAO: 6300-AVISAR TERMINA EM EXEC CICS RETURN, LOGO NAO     *
      * DEVOLVE O CONTROLE. O GO TO APOS ELE E DOCUMENTACAO DO FLUXO.  *
      *================================================================*
       3500-CARREGAR-PAGINA SECTION.
       3500-INICIO.
           MOVE 'N'                    TO WS-PULAR-IGUAL
           MOVE 1                      TO WS-ES-PAGINA
           PERFORM 3800-LER-ADIANTE
           PERFORM 3950-FIXAR-PAGINA
      *
           PERFORM 6000-TABELA-PARA-MAPA
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'NENHUM CARGO A PARTIR DESSE CODIGO'
                                       TO MMENSAGO
           END-IF
           PERFORM 6100-ENVIAR-ERASE.
       3500-FIM.
           EXIT.
      *
       3600-PAGINA-SEGUINTE SECTION.
       3600-INICIO.
           IF WS-ES-ULTIMA = ZEROS
               MOVE 'CARREGUE A GRADE COM F5 ANTES DE PAGINAR'
                                       TO WS-MENSAGEM
               PERFORM 6300-AVISAR
               GO TO 3600-FIM
           END-IF
      *
           MOVE WS-ES-ULTIMA           TO WS-CHAVE-BUSCA
           MOVE 'S'                    TO WS-PULAR-IGUAL
           PERFORM 3800-LER-ADIANTE
      *
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'JA ESTA NA ULTIMA PAGINA' TO WS-MENSAGEM
               PERFORM 6300-AVISAR
               GO TO 3600-FIM
           END-IF
      *
           ADD 1                       TO WS-ES-PAGINA
           PERFORM 3950-FIXAR-PAGINA
           PERFORM 6000-TABELA-PARA-MAPA
           PERFORM 6100-ENVIAR-ERASE.
       3600-FIM.
           EXIT.
      *
       3700-PAGINA-ANTERIOR SECTION.
       3700-INICIO.
           IF WS-ES-PRIMEIRA = ZEROS
               MOVE 'CARREGUE A GRADE COM F5 ANTES DE PAGINAR'
                                       TO WS-MENSAGEM
               PERFORM 6300-AVISAR
               GO TO 3700-FIM
           END-IF
      *
           IF WS-ES-PAGINA <= 1
               MOVE 'JA ESTA NA PRIMEIRA PAGINA' TO WS-MENSAGEM
               PERFORM 6300-AVISAR
               GO TO 3700-FIM
           END-IF
      *
           PERFORM 3900-LER-ATRAS
           IF WS-QTD-REV = ZEROS
               MOVE 'JA ESTA NA PRIMEIRA PAGINA' TO WS-MENSAGEM
               PERFORM 6300-AVISAR
               GO TO 3700-FIM
           END-IF
      *
           SUBTRACT 1 FROM WS-ES-PAGINA
           PERFORM 3950-FIXAR-PAGINA
           PERFORM 6000-TABELA-PARA-MAPA
           PERFORM 6100-ENVIAR-ERASE.
       3700-FIM.
           EXIT.
      *
       3800-LER-ADIANTE SECTION.
       3800-INICIO.
           INITIALIZE WS-GRADE
           MOVE ZEROS                  TO WS-QTD-LINHAS
           MOVE 'N'                    TO WS-FIM-BROWSE
           MOVE WS-CHAVE-BUSCA         TO CAR-CODIGO
      *
           EXEC CICS STARTBR
                FILE(WS-ARQUIVO) RIDFLD(CAR-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE          TO TRUE
               GO TO 3800-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-LINHAS >= WS-LINHAS-PAGINA
               EXEC CICS READNEXT
                    FILE(WS-ARQUIVO) INTO(REG-CARGO)
                    RIDFLD(CAR-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF WS-PULAR-IGUAL = 'S'
                  AND CAR-CODIGO = WS-CHAVE-BUSCA
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-LINHAS
               MOVE WS-QTD-LINHAS      TO WS-IY
               PERFORM 3850-REG-PARA-LINHA
           END-PERFORM
      *
           EXEC CICS ENDBR FILE(WS-ARQUIVO) END-EXEC.
       3800-FIM.
           EXIT.
      *
       3850-REG-PARA-LINHA SECTION.
       3850-INICIO.
           MOVE SPACES                 TO WS-LN-ACAO(WS-IY)
           MOVE CAR-CODIGO             TO WS-LN-CODIGO(WS-IY)
           MOVE CAR-DESCRICAO          TO WS-LN-DESCR(WS-IY)
           MOVE CAR-CBO                TO WS-LN-CBO(WS-IY)
           MOVE CAR-NIVEL              TO WS-LN-NIVEL(WS-IY)
           MOVE CAR-PISO-SALARIAL      TO WS-LN-PISO(WS-IY)
           MOVE CAR-TETO-SALARIAL      TO WS-LN-TETO(WS-IY)
           MOVE CAR-CARGA-HOR-MES      TO WS-LN-CARGA(WS-IY)
           MOVE CAR-SITUACAO           TO WS-LN-SITUAC(WS-IY)
           MOVE 'N'                    TO WS-LN-DES-INF(WS-IY)
                                          WS-LN-CBO-INF(WS-IY)
                                          WS-LN-NIV-INF(WS-IY)
                                          WS-LN-PIS-INF(WS-IY)
                                          WS-LN-TET-INF(WS-IY)
                                          WS-LN-CAR-INF(WS-IY)
                                          WS-LN-SIT-INF(WS-IY)
                                          WS-LN-MAL-FORM(WS-IY).
       3850-FIM.
           EXIT.
      *
       3900-LER-ATRAS SECTION.
       3900-INICIO.
           INITIALIZE WS-GRADE
           INITIALIZE WS-REVERSO
           MOVE ZEROS                  TO WS-QTD-REV
                                          WS-QTD-LINHAS
           MOVE 'N'                    TO WS-FIM-BROWSE
           MOVE WS-ES-PRIMEIRA         TO CAR-CODIGO
      *
           EXEC CICS STARTBR
                FILE(WS-ARQUIVO) RIDFLD(CAR-CHAVE)
                GTEQ RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               SET FIM-BROWSE          TO TRUE
               GO TO 3900-FIM
           END-IF
      *
           PERFORM UNTIL FIM-BROWSE
                      OR WS-QTD-REV >= WS-LINHAS-PAGINA
               EXEC CICS READPREV
                    FILE(WS-ARQUIVO) INTO(REG-CARGO)
                    RIDFLD(CAR-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF CAR-CODIGO >= WS-ES-PRIMEIRA
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-REV
               MOVE REG-CARGO          TO WS-REV-REG(WS-QTD-REV)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE(WS-ARQUIVO) END-EXEC
      *
      *--- A LEITURA VEIO EM ORDEM DECRESCENTE: INVERTE NA GRADE -------
           MOVE WS-QTD-REV             TO WS-QTD-LINHAS
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-QTD-REV
               MOVE WS-REV-REG(WS-IX)  TO REG-CARGO
               COMPUTE WS-IY = WS-QTD-REV - WS-IX + 1
               PERFORM 3850-REG-PARA-LINHA
           END-PERFORM.
       3900-FIM.
           EXIT.
      *
       3950-FIXAR-PAGINA SECTION.
       3950-INICIO.
           MOVE ZEROS                  TO WS-ES-PRIMEIRA
                                          WS-ES-ULTIMA
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
               MOVE WS-LN-CODIGO(WS-IX)
                                       TO WS-ES-CODIGO(WS-IX)
           END-PERFORM
      *
           IF WS-QTD-LINHAS > ZEROS
               MOVE WS-LN-CODIGO(1)    TO WS-ES-PRIMEIRA
               MOVE WS-LN-CODIGO(WS-QTD-LINHAS)
                                       TO WS-ES-ULTIMA
           END-IF.
       3950-FIM.
           EXIT.
      *
      *================================================================*
      * 4000 A 4500 - GRAVACAO DA GRADE                                *
      *                                                                *
      * DUAS FASES. A PRIMEIRA CRITICA AS DOZE LINHAS SEM TOCAR NO     *
      * ARQUIVO; SO SE TODAS PASSAREM E QUE A SEGUNDA APLICA. ASSIM A  *
      * TELA NAO FICA GRAVADA PELA METADE POR ERRO DE DIGITACAO NA     *
      * ULTIMA LINHA.                                                  *
      *                                                                *
      * SE A APLICACAO FALHAR NO MEIO, SYNCPOINT ROLLBACK DESFAZ AS    *
      * ALTERACOES DA UNIDADE DE TRABALHO (VSAM RECUPERAVEL).          *
      *================================================================*
       4000-GRAVAR-GRADE SECTION.
       4000-INICIO.
           MOVE 'N'                    TO WS-ERRO
           MOVE ZEROS                  TO WS-INCLUIDOS
                                          WS-ALTERADOS
                                          WS-EXCLUIDOS
                                          WS-LINHA-ERRO
      *
      *--- FASE 1 - CRITICA --------------------------------------------
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
                      OR TEM-ERRO
               PERFORM 4100-VALIDAR-LINHA
           END-PERFORM
      *
           IF TEM-ERRO
               PERFORM 6300-AVISAR
               GO TO 4000-FIM
           END-IF
      *
      *--- FASE 2 - APLICA ---------------------------------------------
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
                      OR TEM-ERRO
               EVALUATE WS-LN-ACAO(WS-IX)
                   WHEN 'I'
                        PERFORM 4200-INCLUIR-CARGO
                   WHEN 'A'
                        PERFORM 4300-ALTERAR-CARGO
                   WHEN 'E'
                        PERFORM 4400-EXCLUIR-CARGO
                   WHEN OTHER
                        CONTINUE
               END-EVALUATE
           END-PERFORM
      *
           IF TEM-ERRO
               EXEC CICS SYNCPOINT ROLLBACK END-EXEC
               PERFORM 6300-AVISAR
               GO TO 4000-FIM
           END-IF
      *
      *--- RECARREGA A PAGINA PARA REFLETIR O QUE FOI GRAVADO ----------
           MOVE WS-ES-PRIMEIRA         TO WS-CHAVE-BUSCA
           MOVE 'N'                    TO WS-PULAR-IGUAL
           PERFORM 3800-LER-ADIANTE
           PERFORM 3950-FIXAR-PAGINA
           PERFORM 6000-TABELA-PARA-MAPA
      *
           MOVE WS-INCLUIDOS           TO WS-MSG-INC
           MOVE WS-ALTERADOS           TO WS-MSG-ALT
           MOVE WS-EXCLUIDOS           TO WS-MSG-EXC
           MOVE WS-MSG-GRAVOU          TO MMENSAGO
           PERFORM 6100-ENVIAR-ERASE.
       4000-FIM.
           EXIT.
      *
       4100-VALIDAR-LINHA SECTION.
       4100-INICIO.
           IF WS-LN-ACAO(WS-IX) = SPACES
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-ACAO(WS-IX) NOT = 'I' AND 'A' AND 'E'
               MOVE 'ACAO INVALIDA - USE I, A OU E'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-CODIGO(WS-IX) = ZEROS
               MOVE 'RN01 - CODIGO DO CARGO OBRIGATORIO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-MAL-FORM(WS-IX) = 'S'
               MOVE 'CBO, PISO OU TETO COM CARACTER INVALIDO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- O CARGO EXISTE OU NAO? RN07 E RN08 --------------------------
           MOVE WS-LN-CODIGO(WS-IX)    TO CAR-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-CARGO)
                RIDFLD(CAR-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
              AND WS-RESP NOT = DFHRESP(NOTFND)
               MOVE 'ERRO DE LEITURA NO SFPCAR - VER SUPORTE'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-ACAO(WS-IX) = 'I'
              AND WS-RESP = DFHRESP(NORMAL)
               MOVE 'RN07 - CARGO JA CADASTRADO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-ACAO(WS-IX) NOT = 'I'
              AND WS-RESP = DFHRESP(NOTFND)
               MOVE 'RN08 - CARGO NAO CADASTRADO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- EXCLUSAO SO PRECISA DA RN09 ---------------------------------
           IF WS-LN-ACAO(WS-IX) = 'E'
               PERFORM 4180-CONTAR-EMPREGADOS
               IF WS-QTD-EMPREG > ZEROS
                   MOVE 'RN09 - CARGO COM EMPREGADO ATIVO VINCULADO'
                                       TO WS-MENSAGEM
                   PERFORM 4190-MARCAR-ERRO
               END-IF
               GO TO 4100-FIM
           END-IF
      *
      *--- INCLUSAO EXIGE TODOS OS CAMPOS PREENCHIDOS ------------------
           IF WS-LN-ACAO(WS-IX) = 'I'
               IF WS-LN-DES-INF(WS-IX) NOT = 'S'
                  OR WS-LN-CBO-INF(WS-IX) NOT = 'S'
                  OR WS-LN-NIV-INF(WS-IX) NOT = 'S'
                  OR WS-LN-PIS-INF(WS-IX) NOT = 'S'
                  OR WS-LN-TET-INF(WS-IX) NOT = 'S'
                   MOVE 'INCLUSAO EXIGE TODOS OS CAMPOS DA LINHA'
                                       TO WS-MENSAGEM
                   PERFORM 4190-MARCAR-ERRO
                   GO TO 4100-FIM
               END-IF
               INITIALIZE REG-CARGO
           END-IF
      *
      *--- CRITICA O REGISTRO JA COM OS CAMPOS DA TELA APLICADOS -------
           PERFORM 4150-MONTAR-REGISTRO
           PERFORM 4160-CRITICAR-REGISTRO.
       4100-FIM.
           EXIT.
      *
       4150-MONTAR-REGISTRO SECTION.
       4150-INICIO.
           IF WS-LN-DES-INF(WS-IX) = 'S'
               MOVE WS-LN-DESCR(WS-IX) TO CAR-DESCRICAO
           END-IF
           IF WS-LN-CBO-INF(WS-IX) = 'S'
               MOVE WS-LN-CBO(WS-IX)   TO CAR-CBO
           END-IF
           IF WS-LN-NIV-INF(WS-IX) = 'S'
               MOVE WS-LN-NIVEL(WS-IX) TO CAR-NIVEL
           END-IF
           IF WS-LN-PIS-INF(WS-IX) = 'S'
               MOVE WS-LN-PISO(WS-IX)  TO CAR-PISO-SALARIAL
           END-IF
           IF WS-LN-TET-INF(WS-IX) = 'S'
               MOVE WS-LN-TETO(WS-IX)  TO CAR-TETO-SALARIAL
           END-IF
           IF WS-LN-CAR-INF(WS-IX) = 'S'
               MOVE WS-LN-CARGA(WS-IX) TO CAR-CARGA-HOR-MES
           END-IF
           IF WS-LN-SIT-INF(WS-IX) = 'S'
               MOVE WS-LN-SITUAC(WS-IX) TO CAR-SITUACAO
           END-IF
      *
      *--- A FAMILIA SAO OS QUATRO PRIMEIROS DIGITOS DO CBO ------------
           COMPUTE CAR-COD-CBO-FAMILIA = CAR-CBO / 100.
       4150-FIM.
           EXIT.
      *
       4160-CRITICAR-REGISTRO SECTION.
       4160-INICIO.
           IF CAR-DESCRICAO = SPACES
               MOVE 'RN02 - DESCRICAO DO CARGO OBRIGATORIA'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-CBO < 100000
               MOVE 'RN03 - CBO DEVE TER SEIS DIGITOS'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-NIVEL NOT = 'O' AND 'T' AND 'E' AND 'G'
                            AND 'D'
               MOVE 'RN04 - NIVEL DEVE SER O, T, E, G OU D'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-PISO-SALARIAL < WS-SALARIO-MINIMO
               MOVE 'RN05 - PISO ABAIXO DO SALARIO MINIMO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-TETO-SALARIAL < CAR-PISO-SALARIAL
               MOVE 'RN06 - TETO NAO PODE SER MENOR QUE O PISO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-CARGA-HOR-MES = ZEROS
               MOVE 'RN10 - CARGA HORARIA MENSAL OBRIGATORIA'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF CAR-SITUACAO NOT = 'A' AND 'E'
               MOVE 'RN11 - SITUACAO DEVE SER A OU E'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4160-FIM.
           EXIT.
      *
       4180-CONTAR-EMPREGADOS SECTION.
       4180-INICIO.
           MOVE WS-LN-CODIGO(WS-IX)    TO WS-CARGO-SQL
           MOVE ZEROS                  TO WS-QTD-EMPREG
      *
           EXEC SQL
                SELECT COUNT(*)
                  INTO :WS-QTD-EMPREG
                  FROM SFPADM.TB_EMPREGADO
                 WHERE COD_CARGO = :WS-CARGO-SQL
                   AND SITUACAO <> 'D'
                  WITH UR
           END-EXEC
      *
           IF SQLCODE NOT = 0
               PERFORM 9000-ERRO-SQL
           END-IF.
       4180-FIM.
           EXIT.
      *
       4190-MARCAR-ERRO SECTION.
       4190-INICIO.
           SET TEM-ERRO                TO TRUE
           MOVE WS-IX                  TO WS-LINHA-ERRO
           MOVE WS-MENSAGEM            TO WS-TEXTO-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
           STRING 'LINHA ' WS-LINHA-ERRO ' - ' WS-TEXTO-ERRO
                  DELIMITED BY SIZE INTO WS-MENSAGEM.
       4190-FIM.
           EXIT.
      *
       4200-INCLUIR-CARGO SECTION.
       4200-INICIO.
           INITIALIZE REG-CARGO
           MOVE WS-LN-CODIGO(WS-IX)    TO CAR-CODIGO
           MOVE WS-CARGA-PADRAO        TO CAR-CARGA-HOR-MES
           MOVE 'N'                    TO CAR-IND-INSALUBRID
                                          CAR-IND-PERICULOSID
                                          CAR-IND-CONFIANCA
           MOVE ZEROS                  TO CAR-PERC-INSALUBRID
           MOVE WS-DATA-HOJE           TO CAR-DT-CRIACAO
           SET CAR-ATIVO               TO TRUE
           MOVE SPACES                 TO CAR-FILLER
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS WRITE
                FILE(WS-ARQUIVO) FROM(REG-CARGO)
                RIDFLD(CAR-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-INCLUIDOS
           ELSE
               MOVE 'FALHA AO INCLUIR O CARGO NO SFPCAR'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4200-FIM.
           EXIT.
      *
       4300-ALTERAR-CARGO SECTION.
       4300-INICIO.
           MOVE WS-LN-CODIGO(WS-IX)    TO CAR-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-CARGO)
                RIDFLD(CAR-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'FALHA AO LER O CARGO PARA ALTERACAO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4300-FIM
           END-IF
      *
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS REWRITE
                FILE(WS-ARQUIVO) FROM(REG-CARGO)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-ALTERADOS
           ELSE
               MOVE 'FALHA AO ALTERAR O CARGO NO SFPCAR'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4300-FIM.
           EXIT.
      *
       4400-EXCLUIR-CARGO SECTION.
       4400-INICIO.
           MOVE WS-LN-CODIGO(WS-IX)    TO CAR-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-CARGO)
                RIDFLD(CAR-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'FALHA AO LER O CARGO PARA EXCLUSAO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4400-FIM
           END-IF
      *
      *--- EXCLUSAO E LOGICA: A COLUNA S DA GRADE MOSTRA O CARGO -------
      *--- EXTINTO E PERMITE REVERTER PARA A -------------------------
           SET CAR-EXTINTO             TO TRUE
      *
           EXEC CICS REWRITE
                FILE(WS-ARQUIVO) FROM(REG-CARGO)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-EXCLUIDOS
           ELSE
               MOVE 'FALHA AO EXTINGUIR O CARGO NO SFPCAR'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4400-FIM.
           EXIT.
      *
       4500-CHAMAR-LOOKUP SECTION.
       4500-INICIO.
           INITIALIZE AREA-LOOKUP
           MOVE 'CAR'                  TO LOK-TIPO-DOMINIO
           MOVE WS-PROGRAMA            TO LOK-PGM-CHAMADOR
           MOVE 'MCARGO'               TO LOK-CAMPO-ORIGEM
           MOVE 1                      TO LOK-PAGINA
           SET LOK-EM-CURSO            TO TRUE
      *
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
           MOVE WS-ESTADO              TO COM-AREA-TRABALHO
                                          (121:LENGTH OF WS-ESTADO)
      *
           EXEC CICS XCTL PROGRAM('SFP0900')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       4500-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 A 6300 - MONTAGEM E ENVIO DO MAPA                         *
      *                                                                *
      * MOVE LOW-VALUES NO MAPA INTEIRO ANTES DE PREENCHER: O QUE      *
      * FICAR EM LOW-VALUES NAO E TRANSMITIDO. POR ISSO O ENVIO DE     *
      * MENSAGEM (6300) SO CARREGA DATA, PAGINA E MENSAGEM: O QUE O    *
      * USUARIO DIGITOU CONTINUA NA TELA.                              *
      *                                                                *
      * AS DOZE LINHAS SAO TRATADAS UMA A UMA PORQUE OS NOMES DO       *
      * COPYBOOK SIMBOLICO NAO FORMAM UM OCCURS.                       *
      *================================================================*
       6000-TABELA-PARA-MAPA SECTION.
       6000-INICIO.
           MOVE LOW-VALUES             TO MAPCARGO
           MOVE WS-DATA-TELA           TO MDATAO
           MOVE WS-CHAVE-BUSCA         TO MCARGOO
           MOVE WS-ES-PAGINA           TO MPAGO
      *
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
               IF WS-LN-CODIGO(WS-IX) > ZEROS
                   EVALUATE WS-IX
                       WHEN 1  PERFORM 6010-MOSTRAR-LINHA-01
                       WHEN 2  PERFORM 6011-MOSTRAR-LINHA-02
                       WHEN 3  PERFORM 6012-MOSTRAR-LINHA-03
                       WHEN 4  PERFORM 6013-MOSTRAR-LINHA-04
                       WHEN 5  PERFORM 6014-MOSTRAR-LINHA-05
                       WHEN 6  PERFORM 6015-MOSTRAR-LINHA-06
                       WHEN 7  PERFORM 6016-MOSTRAR-LINHA-07
                       WHEN 8  PERFORM 6017-MOSTRAR-LINHA-08
                       WHEN 9  PERFORM 6018-MOSTRAR-LINHA-09
                       WHEN 10 PERFORM 6019-MOSTRAR-LINHA-10
                       WHEN 11 PERFORM 6020-MOSTRAR-LINHA-11
                       WHEN 12 PERFORM 6021-MOSTRAR-LINHA-12
                       WHEN OTHER CONTINUE
                   END-EVALUATE
               END-IF
           END-PERFORM.
       6000-FIM.
           EXIT.
      *
       6010-MOSTRAR-LINHA-01 SECTION.
       6010-INICIO.
           MOVE SPACES                 TO ACAO1O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD1O
           MOVE WS-LN-DESCR(WS-IX)     TO DES1O
           MOVE WS-LN-CBO(WS-IX)       TO CBO1O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV1O
           MOVE WS-LN-PISO(WS-IX)      TO PIS1O
           MOVE WS-LN-TETO(WS-IX)      TO TET1O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR1O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT1O.
       6010-FIM.
           EXIT.
      *
       6011-MOSTRAR-LINHA-02 SECTION.
       6011-INICIO.
           MOVE SPACES                 TO ACAO2O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD2O
           MOVE WS-LN-DESCR(WS-IX)     TO DES2O
           MOVE WS-LN-CBO(WS-IX)       TO CBO2O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV2O
           MOVE WS-LN-PISO(WS-IX)      TO PIS2O
           MOVE WS-LN-TETO(WS-IX)      TO TET2O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR2O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT2O.
       6011-FIM.
           EXIT.
      *
       6012-MOSTRAR-LINHA-03 SECTION.
       6012-INICIO.
           MOVE SPACES                 TO ACAO3O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD3O
           MOVE WS-LN-DESCR(WS-IX)     TO DES3O
           MOVE WS-LN-CBO(WS-IX)       TO CBO3O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV3O
           MOVE WS-LN-PISO(WS-IX)      TO PIS3O
           MOVE WS-LN-TETO(WS-IX)      TO TET3O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR3O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT3O.
       6012-FIM.
           EXIT.
      *
       6013-MOSTRAR-LINHA-04 SECTION.
       6013-INICIO.
           MOVE SPACES                 TO ACAO4O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD4O
           MOVE WS-LN-DESCR(WS-IX)     TO DES4O
           MOVE WS-LN-CBO(WS-IX)       TO CBO4O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV4O
           MOVE WS-LN-PISO(WS-IX)      TO PIS4O
           MOVE WS-LN-TETO(WS-IX)      TO TET4O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR4O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT4O.
       6013-FIM.
           EXIT.
      *
       6014-MOSTRAR-LINHA-05 SECTION.
       6014-INICIO.
           MOVE SPACES                 TO ACAO5O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD5O
           MOVE WS-LN-DESCR(WS-IX)     TO DES5O
           MOVE WS-LN-CBO(WS-IX)       TO CBO5O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV5O
           MOVE WS-LN-PISO(WS-IX)      TO PIS5O
           MOVE WS-LN-TETO(WS-IX)      TO TET5O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR5O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT5O.
       6014-FIM.
           EXIT.
      *
       6015-MOSTRAR-LINHA-06 SECTION.
       6015-INICIO.
           MOVE SPACES                 TO ACAO6O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD6O
           MOVE WS-LN-DESCR(WS-IX)     TO DES6O
           MOVE WS-LN-CBO(WS-IX)       TO CBO6O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV6O
           MOVE WS-LN-PISO(WS-IX)      TO PIS6O
           MOVE WS-LN-TETO(WS-IX)      TO TET6O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR6O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT6O.
       6015-FIM.
           EXIT.
      *
       6016-MOSTRAR-LINHA-07 SECTION.
       6016-INICIO.
           MOVE SPACES                 TO ACAO7O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD7O
           MOVE WS-LN-DESCR(WS-IX)     TO DES7O
           MOVE WS-LN-CBO(WS-IX)       TO CBO7O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV7O
           MOVE WS-LN-PISO(WS-IX)      TO PIS7O
           MOVE WS-LN-TETO(WS-IX)      TO TET7O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR7O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT7O.
       6016-FIM.
           EXIT.
      *
       6017-MOSTRAR-LINHA-08 SECTION.
       6017-INICIO.
           MOVE SPACES                 TO ACAO8O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD8O
           MOVE WS-LN-DESCR(WS-IX)     TO DES8O
           MOVE WS-LN-CBO(WS-IX)       TO CBO8O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV8O
           MOVE WS-LN-PISO(WS-IX)      TO PIS8O
           MOVE WS-LN-TETO(WS-IX)      TO TET8O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR8O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT8O.
       6017-FIM.
           EXIT.
      *
       6018-MOSTRAR-LINHA-09 SECTION.
       6018-INICIO.
           MOVE SPACES                 TO ACAO9O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD9O
           MOVE WS-LN-DESCR(WS-IX)     TO DES9O
           MOVE WS-LN-CBO(WS-IX)       TO CBO9O
           MOVE WS-LN-NIVEL(WS-IX)     TO NIV9O
           MOVE WS-LN-PISO(WS-IX)      TO PIS9O
           MOVE WS-LN-TETO(WS-IX)      TO TET9O
           MOVE WS-LN-CARGA(WS-IX)     TO CHR9O
           MOVE WS-LN-SITUAC(WS-IX)    TO SIT9O.
       6018-FIM.
           EXIT.
      *
       6019-MOSTRAR-LINHA-10 SECTION.
       6019-INICIO.
           MOVE SPACES                 TO ACAOAO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODAO
           MOVE WS-LN-DESCR(WS-IX)     TO DESAO
           MOVE WS-LN-CBO(WS-IX)       TO CBOAO
           MOVE WS-LN-NIVEL(WS-IX)     TO NIVAO
           MOVE WS-LN-PISO(WS-IX)      TO PISAO
           MOVE WS-LN-TETO(WS-IX)      TO TETAO
           MOVE WS-LN-CARGA(WS-IX)     TO CHRAO
           MOVE WS-LN-SITUAC(WS-IX)    TO SITAO.
       6019-FIM.
           EXIT.
      *
       6020-MOSTRAR-LINHA-11 SECTION.
       6020-INICIO.
           MOVE SPACES                 TO ACAOBO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODBO
           MOVE WS-LN-DESCR(WS-IX)     TO DESBO
           MOVE WS-LN-CBO(WS-IX)       TO CBOBO
           MOVE WS-LN-NIVEL(WS-IX)     TO NIVBO
           MOVE WS-LN-PISO(WS-IX)      TO PISBO
           MOVE WS-LN-TETO(WS-IX)      TO TETBO
           MOVE WS-LN-CARGA(WS-IX)     TO CHRBO
           MOVE WS-LN-SITUAC(WS-IX)    TO SITBO.
       6020-FIM.
           EXIT.
      *
       6021-MOSTRAR-LINHA-12 SECTION.
       6021-INICIO.
           MOVE SPACES                 TO ACAOCO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODCO
           MOVE WS-LN-DESCR(WS-IX)     TO DESCO
           MOVE WS-LN-CBO(WS-IX)       TO CBOCO
           MOVE WS-LN-NIVEL(WS-IX)     TO NIVCO
           MOVE WS-LN-PISO(WS-IX)      TO PISCO
           MOVE WS-LN-TETO(WS-IX)      TO TETCO
           MOVE WS-LN-CARGA(WS-IX)     TO CHRCO
           MOVE WS-LN-SITUAC(WS-IX)    TO SITCO.
       6021-FIM.
           EXIT.
      *
       6100-ENVIAR-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPCARGO)
                ERASE FREEKB CURSOR
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPCARGO)
                DATAONLY FREEKB CURSOR
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
       6300-AVISAR SECTION.
       6300-INICIO.
           MOVE LOW-VALUES             TO MAPCARGO
           MOVE WS-DATA-TELA           TO MDATAO
           MOVE WS-ES-PAGINA           TO MPAGO
           MOVE WS-MENSAGEM            TO MMENSAGO
           PERFORM 6200-ENVIAR-DATAONLY.
       6300-FIM.
           EXIT.
      *
      *================================================================*
      * 7000 A 7400 - APOIO                                            *
      *                                                                *
      * 7400 DES-EDITA O QUE O USUARIO DIGITOU NOS CAMPOS DE PISO E    *
      * TETO. O CAMPO CHEGA DO BMS COMO X(013) ALINHADO A ESQUERDA:    *
      * MOVE DIRETO PARA 9(009)V99 DARIA VALOR ERRADO. AQUI O TEXTO    *
      * E VALIDADO CARACTERE A CARACTERE, COMPACTADO, PARTIDO NA       *
      * VIRGULA E REMONTADO. NENHUM LITERAL DECIMAL E USADO: O         *
      * PROGRAMA TEM DECIMAL-POINT IS COMMA, ENTAO CENTAVOS ENTRAM     *
      * COMO RAZAO INTEIRA (/ 100).                                    *
      *================================================================*
       7000-OBTER-DATA SECTION.
       7000-INICIO.
           EXEC CICS ASKTIME ABSTIME(WS-HORA-ABS) END-EXEC
           EXEC CICS FORMATTIME
                ABSTIME(WS-HORA-ABS)
                YYYYMMDD(WS-DATA-HOJE)
           END-EXEC
      *
           MOVE WS-DATA-HOJE           TO WS-DATA-QUEBRA
           MOVE WS-DQ-DIA              TO WS-DT-DIA
           MOVE WS-DQ-MES              TO WS-DT-MES
           MOVE WS-DQ-ANO              TO WS-DT-ANO.
       7000-FIM.
           EXIT.
      *
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
           END-IF.
       7100-FIM.
           EXIT.
      *
       7400-DE-EDITAR SECTION.
       7400-INICIO.
           MOVE 'S'                    TO WS-ED-OK
           MOVE ZEROS                  TO WS-ED-VALOR
                                          WS-ED-TAM
                                          WS-ED-VIRGULA
                                          WS-ED-INVALIDOS
                                          WS-ED-TAM-INT
                                          WS-ED-TAM-DEC
                                          WS-ED-INT
                                          WS-ED-CENT
           MOVE SPACES                 TO WS-ED-COMPACTO
      *
           IF WS-ED-CAMPO = SPACES
               GO TO 7400-FIM
           END-IF
      *
      *--- TIRA ESPACOS, CONTA VIRGULAS E RECUSA O RESTO ---------------
           PERFORM VARYING WS-IY FROM 1 BY 1 UNTIL WS-IY > 13
               EVALUATE WS-ED-CAMPO(WS-IY:1)
                   WHEN SPACE
                        CONTINUE
                   WHEN LOW-VALUE
                        CONTINUE
                   WHEN ','
                        ADD 1           TO WS-ED-VIRGULA
                        ADD 1           TO WS-ED-TAM
                        MOVE ','        TO WS-ED-COMPACTO
                                           (WS-ED-TAM:1)
                   WHEN '0' THRU '9'
                        ADD 1           TO WS-ED-TAM
                        MOVE WS-ED-CAMPO(WS-IY:1)
                                        TO WS-ED-COMPACTO
                                           (WS-ED-TAM:1)
                   WHEN OTHER
                        ADD 1           TO WS-ED-INVALIDOS
               END-EVALUATE
           END-PERFORM
      *
           IF WS-ED-INVALIDOS > ZEROS OR WS-ED-VIRGULA > 1
               MOVE 'N'                TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
           IF WS-ED-TAM = ZEROS
               GO TO 7400-FIM
           END-IF
      *
      *--- SEPARA A PARTE INTEIRA DOS CENTAVOS -------------------------
           MOVE WS-ED-TAM              TO WS-ED-TAM-INT
           IF WS-ED-VIRGULA = 1
               PERFORM VARYING WS-IY FROM 1 BY 1
                       UNTIL WS-IY > WS-ED-TAM
                   IF WS-ED-COMPACTO(WS-IY:1) = ','
                       COMPUTE WS-ED-TAM-INT = WS-IY - 1
                       COMPUTE WS-ED-TAM-DEC = WS-ED-TAM - WS-IY
                       EXIT PERFORM
                   END-IF
               END-PERFORM
           END-IF
      *
           IF WS-ED-TAM-INT > 9 OR WS-ED-TAM-DEC > 2
               MOVE 'N'                TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
      *--- PARTE INTEIRA ALINHADA A DIREITA, CENTAVOS A ESQUERDA -------
           MOVE ZEROS                  TO WS-ED-INT-X
           IF WS-ED-TAM-INT > ZEROS
               COMPUTE WS-IY = 10 - WS-ED-TAM-INT
               MOVE WS-ED-COMPACTO(1:WS-ED-TAM-INT)
                                       TO WS-ED-INT-X
                                          (WS-IY:WS-ED-TAM-INT)
           END-IF
           MOVE WS-ED-INT-X            TO WS-ED-INT
      *
           MOVE ZEROS                  TO WS-ED-CENT-X
           IF WS-ED-TAM-DEC > ZEROS
               COMPUTE WS-IY = WS-ED-TAM-INT + 2
               MOVE WS-ED-COMPACTO(WS-IY:WS-ED-TAM-DEC)
                                       TO WS-ED-CENT-X
                                          (1:WS-ED-TAM-DEC)
           END-IF
           MOVE WS-ED-CENT-X           TO WS-ED-CENT
      *
           COMPUTE WS-ED-VALOR = WS-ED-INT + WS-ED-CENT / 100.
       7400-FIM.
           EXIT.
      *
      *================================================================*
      * 5900 A 9999 - ENCERRAMENTO E TRATAMENTO DE ERRO                *
      *================================================================*
       5900-ENCERRAR SECTION.
       5900-INICIO.
           MOVE WS-PROGRAMA            TO COM-PROGRAMA-ANTERIOR
           EXEC CICS XCTL PROGRAM('SFP0000')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       5900-FIM.
           EXIT.
      *
       8000-RETORNAR SECTION.
       8000-INICIO.
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
           MOVE WS-ESTADO              TO COM-AREA-TRABALHO
                                          (121:LENGTH OF WS-ESTADO)
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
                  ' EM TB_EMPREGADO - ACIONE O SUPORTE TECNICO'
                  DELIMITED BY SIZE INTO WS-MENSAGEM
           PERFORM 6300-AVISAR.
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
