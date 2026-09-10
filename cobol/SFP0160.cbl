      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0160                                             *
      * TRANSACAO: SF08                                                *
      * MAPSET   : SFPM06   MAPA: MAPDOMI                              *
      * FUNCAO   : MANUTENCAO DAS TABELAS DE DOMINIO                   *
      *            GRADE DE 12 LINHAS COM PAGINACAO EM VSAM            *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE O TRADUTOR CICS ANTES DO COMPILADOR COBOL.   *
      * NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME. NAO USA DB2.      *
      *----------------------------------------------------------------*
      * O ARQUIVO SFPDOM (VSAM KSDS) GUARDA TODOS OS DOMINIOS EM UMA   *
      * TABELA UNICA. A CHAVE E DOM-TIPO MAIS DOM-CODIGO, LOGO OS      *
      * REGISTROS DE UM TIPO FICAM CONTIGUOS E O BROWSE PARA QUANDO    *
      * DOM-TIPO MUDA. A TELA MANTEM UM TIPO POR VEZ.                  *
      *----------------------------------------------------------------*
      * O TIPO INFORMADO E CRITICADO CONTRA O META-DOMINIO TIP, QUE    *
      * TEM UM REGISTRO PARA CADA TIPO EXISTENTE (DOM-CODIGO IGUAL AO  *
      * TIPO, DOM-DESCRICAO IGUAL AO NOME DA TABELA). ASSIM NAO HA     *
      * TABELA DE TIPOS CODIFICADA AQUI DENTRO E A TECLA F4 CHAMA O    *
      * SFP0900 COM LOK-TIPO-DOMINIO IGUAL A TIP. OS REGISTROS DO TIP  *
      * NASCEM COM DOM-IND-SISTEMA IGUAL A S, ENTAO ESTA TELA NAO      *
      * CONSEGUE CORROMPER O PROPRIO CATALOGO.                         *
      *----------------------------------------------------------------*
      * ACOES ACEITAS EM CADA LINHA DA GRADE                           *
      *   BRANCO - LINHA INALTERADA                                    *
      *   I      - INCLUIR O DOMINIO                                   *
      *   A      - ALTERAR OS CAMPOS DIGITADOS                         *
      *   E      - EXCLUIR O DOMINIO                                   *
      *----------------------------------------------------------------*
      * O MAPA USA CTRL=(FREEKB,FRSET): NO RECEIVE SO VOLTAM OS        *
      * CAMPOS QUE O USUARIO DIGITOU E OS DEMAIS CHEGAM EM LOW-VALUES. *
      * POR ISSO O TIPO E O CODIGO DE CADA LINHA DA PAGINA FICAM       *
      * GUARDADOS NA COMMAREA (WS-ESTADO) E NAO SAO RELIDOS DA TELA, E *
      * CADA CAMPO CARREGA UM INDICADOR -INF QUE DIZ SE FOI DIGITADO   *
      * NESTA INTERACAO. NA ALTERACAO SO OS CAMPOS COM -INF IGUAL A S  *
      * SOBREPOEM O REGISTRO LIDO DO ARQUIVO. CONSEQUENCIA ACEITA: A   *
      * GRADE NAO APAGA CONTEUDO, SO SUBSTITUI.                        *
      *----------------------------------------------------------------*
      * A ORDEM CHEGA DA TELA EM CAMPO X(003) ALINHADO A ESQUERDA E O  *
      * CODIGO EM X(006). MOVE DIRETO PARA CAMPO NUMERICO DARIA VALOR  *
      * ERRADO: 7300 COMPACTA O CODIGO E 7400 CRITICA E MONTA A ORDEM. *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO                                              *
      *  RN01 - TIPO DE DOMINIO OBRIGATORIO E CADASTRADO NO TIP        *
      *  RN02 - CODIGO OBRIGATORIO NA LINHA COM ACAO                   *
      *  RN03 - DESCRICAO OBRIGATORIA                                  *
      *  RN04 - ORDEM DE EXIBICAO ENTRE 001 E 999                      *
      *  RN05 - SITUACAO EM A OU I                                     *
      *  RN06 - INCLUSAO NAO PODE DUPLICAR CODIGO DENTRO DO TIPO       *
      *  RN07 - ALTERACAO E EXCLUSAO EXIGEM DOMINIO JA CADASTRADO      *
      *  RN08 - DOMINIO DE SISTEMA NAO ACEITA ALTERACAO NEM EXCLUSAO   *
      *----------------------------------------------------------------*
      * DOM-IND-SISTEMA APARECE NA COLUNA SIS DO MAPA SFPM06, QUE E    *
      * PROTEGIDA: NA INCLUSAO O INDICADOR RECEBE N E NA ALTERACAO E   *
      * PRESERVADO. QUEM PRECISA MARCAR UM DOMINIO COMO DE SISTEMA     *
      * FAZ ISSO EM tools/gerar_dominios.py. A COLUNA EXISTE PARA A    *
      * RN08 NAO SER UMA SURPRESA NO MOMENTO DA RECUSA.                *
      * A REDUZIDA OMITIDA NA INCLUSAO SAI DOS 12 PRIMEIROS            *
      * CARACTERES DA DESCRICAO E A SITUACAO OMITIDA SAI COMO A.       *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0160.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF08'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0160 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM06 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPDOMI'.
           05  WS-ARQUIVO          PIC X(008) VALUE 'SFPDOM  '.
           05  WS-META-TIPO        PIC X(003) VALUE 'TIP'.
           05  WS-TITULO           PIC X(050) VALUE
               'SFP0160 - TABELAS DE DOMINIO - FIM DA SESSAO'.
           05  WS-LINHAS-PAGINA    PIC S9(004) COMP VALUE 12.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM06.
      *
       COPY SFPWDOM.
      *
      *--- TABELA INTERNA DA GRADE (ESPELHO DA TELA) -----------------
       01  WS-GRADE.
           05  WS-LINHA OCCURS 12 TIMES.
               10  WS-LN-ACAO      PIC X(001).
               10  WS-LN-CODIGO    PIC X(006).
               10  WS-LN-DESCR     PIC X(035).
               10  WS-LN-REDUZ     PIC X(012).
               10  WS-LN-ORDEM     PIC 9(003).
               10  WS-LN-AUX       PIC X(010).
               10  WS-LN-SIT       PIC X(001).
               10  WS-LN-SIS       PIC X(003).
               10  WS-LN-DES-INF   PIC X(001).
               10  WS-LN-RED-INF   PIC X(001).
               10  WS-LN-ORD-INF   PIC X(001).
               10  WS-LN-AUX-INF   PIC X(001).
               10  WS-LN-SIT-INF   PIC X(001).
               10  WS-LN-MAL-FORM  PIC X(001).
      *
      *--- PAGINA LIDA DE TRAS PARA FRENTE (F7) ----------------------
       01  WS-REVERSO.
           05  WS-REV-REG OCCURS 12 TIMES PIC X(080).
      *
      *--- CAMPOS BRUTOS DE UMA LINHA RECEBIDA DO MAPA ---------------
       01  WS-CAMPOS.
           05  WS-CP-ACAO          PIC X(001) VALUE SPACES.
           05  WS-CP-CODIGO        PIC X(006) VALUE SPACES.
           05  WS-CP-DESCR         PIC X(035) VALUE SPACES.
           05  WS-CP-REDUZ         PIC X(012) VALUE SPACES.
           05  WS-CP-ORDEM         PIC X(003) VALUE SPACES.
           05  WS-CP-AUX           PIC X(010) VALUE SPACES.
           05  WS-CP-SIT           PIC X(001) VALUE SPACES.
      *
      *--- ESTADO DA PAGINA - VIVE NA COMMAREA DO BYTE 121 -----------
       01  WS-ESTADO.
           05  WS-ES-TIPO          PIC X(003) VALUE SPACES.
           05  WS-ES-PAGINA        PIC 9(003) VALUE ZEROS.
           05  WS-ES-PRIMEIRA      PIC X(006) VALUE SPACES.
           05  WS-ES-ULTIMA        PIC X(006) VALUE SPACES.
           05  WS-ES-CODIGO OCCURS 12 TIMES PIC X(006).
      *
      *--- AREA DE TRABALHO ------------------------------------------
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-FIM-BROWSE       PIC X(001) VALUE 'N'.
               88  FIM-BROWSE          VALUE 'S'.
           05  WS-TIPO-OK          PIC X(001) VALUE 'N'.
               88  TIPO-VALIDO         VALUE 'S'.
           05  WS-DESC-TIPO        PIC X(035) VALUE SPACES.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-IY               PIC S9(004) COMP VALUE ZEROS.
           05  WS-QTD-LINHAS       PIC S9(004) COMP VALUE ZEROS.
           05  WS-QTD-REV          PIC S9(004) COMP VALUE ZEROS.
           05  WS-CHAVE-BUSCA      PIC X(006) VALUE SPACES.
           05  WS-PULAR-IGUAL      PIC X(001) VALUE 'N'.
           05  WS-INCLUIDOS        PIC 9(003) VALUE ZEROS.
           05  WS-ALTERADOS        PIC 9(003) VALUE ZEROS.
           05  WS-EXCLUIDOS        PIC 9(003) VALUE ZEROS.
           05  WS-LINHA-ERRO       PIC 9(002) VALUE ZEROS.
           05  WS-TEXTO-ERRO       PIC X(060) VALUE SPACES.
      *
      *--- RESUMO DA GRAVACAO EXIBIDO NA LINHA DE MENSAGEM -----------
       01  WS-MSG-GRAVOU.
           05  FILLER              PIC X(009) VALUE 'GRAVADO: '.
           05  WS-MSG-INC          PIC ZZ9.
           05  FILLER              PIC X(012) VALUE ' INCLUIDOS, '.
           05  WS-MSG-ALT          PIC ZZ9.
           05  FILLER              PIC X(012) VALUE ' ALTERADOS, '.
           05  WS-MSG-EXC          PIC ZZ9.
           05  FILLER              PIC X(010) VALUE ' EXCLUIDOS'.
      *
      *--- COMPACTACAO DO CODIGO DIGITADO (VER 7300) -----------------
       01  WS-CODIGO.
           05  WS-CD-BRUTO         PIC X(006) VALUE SPACES.
           05  WS-CD-LIMPO         PIC X(006) VALUE SPACES.
           05  WS-CD-TAM           PIC S9(004) COMP VALUE ZEROS.
      *
      *--- DES-EDICAO DA ORDEM DE EXIBICAO (VER 7400) ----------------
       01  WS-EDIT.
           05  WS-ED-CAMPO         PIC X(013) VALUE SPACES.
           05  WS-ED-COMPACTO      PIC X(013) VALUE SPACES.
           05  WS-ED-TAM           PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-VIRGULA       PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-INVALIDOS     PIC S9(004) COMP VALUE ZEROS.
           05  WS-ED-OK            PIC X(001) VALUE 'S'.
           05  WS-ED-INT-X         PIC X(009) VALUE SPACES.
           05  WS-ED-INT           PIC 9(009) VALUE ZEROS.
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
           MOVE 'N'                    TO WS-TIPO-OK
      *
           MOVE LOW-VALUES             TO MAPDOMIO
           MOVE WS-ES-PAGINA           TO MPAGO
           MOVE 'INFORME O TIPO DE DOMINIO (F4 LISTA) E TECLE F5'
                                       TO MMENSAGO
      *
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPDOMIO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - RETORNO DA JANELA F4 (SFP0900). A JANELA LISTOU O       *
      * META-DOMINIO TIP, LOGO O CODIGO SELECIONADO E O PROPRIO TIPO.  *
      * O SFP0900 DEVOLVE O CONTROLE POR XCTL: ESTA E UMA NOVA ENTRADA *
      * NO PROGRAMA E A TELA PRECISA SER REMONTADA DO ARQUIVO.         *
      *----------------------------------------------------------------*
       1100-VOLTA-DO-LOOKUP SECTION.
       1100-INICIO.
           IF LOK-SELECIONOU
               MOVE LOK-COD-SELECIONADO(1:3)
                                       TO WS-ES-TIPO
           MOVE SPACES                 TO WS-ES-PRIMEIRA
                                          WS-ES-ULTIMA
           MOVE 1                      TO WS-ES-PAGINA
           END-IF
      *
           MOVE SPACES                 TO LOK-PGM-CHAMADOR
           SET LOK-EM-CURSO            TO TRUE
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
      *
           PERFORM 3200-CRITICAR-TIPO
           IF NOT TIPO-VALIDO
               PERFORM 6300-AVISAR
               GO TO 1100-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-PULAR-IGUAL
           MOVE SPACES                 TO WS-CHAVE-BUSCA
           PERFORM 3800-LER-ADIANTE
           PERFORM 3950-FIXAR-PAGINA
      *
           PERFORM 6000-TABELA-PARA-MAPA
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'TIPO SEM NENHUM DOMINIO CADASTRADO'
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
      *                                                                *
      * TROCAR O TIPO INVALIDA A PAGINACAO: PRIMEIRA, ULTIMA E OS DOZE *
      * CODIGOS GUARDADOS SAO DE OUTRA TABELA. POR ISSO O ESTADO E     *
      * ZERADO ANTES DE QUALQUER LEITURA.                              *
      *================================================================*
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPDOMII)
                RESP(WS-RESP)
           END-EXEC
      *
           IF MTIPOI NOT = LOW-VALUES AND MTIPOI NOT = SPACES
               IF FUNCTION UPPER-CASE(MTIPOI) NOT = WS-ES-TIPO
                   MOVE FUNCTION UPPER-CASE(MTIPOI)
                                       TO WS-ES-TIPO
                   INITIALIZE WS-GRADE
           MOVE SPACES                 TO WS-ES-PRIMEIRA
                                          WS-ES-ULTIMA
                   PERFORM VARYING WS-IX FROM 1 BY 1
                           UNTIL WS-IX > WS-LINHAS-PAGINA
                       MOVE SPACES     TO WS-ES-CODIGO(WS-IX)
                   END-PERFORM
           MOVE 1                      TO WS-ES-PAGINA
               END-IF
           END-IF
      *
           PERFORM 3200-CRITICAR-TIPO
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
           MOVE RED1I                  TO WS-CP-REDUZ
           MOVE ORD1I                  TO WS-CP-ORDEM
           MOVE AUX1I                  TO WS-CP-AUX
           MOVE SIT1I                  TO WS-CP-SIT
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
           MOVE RED2I                  TO WS-CP-REDUZ
           MOVE ORD2I                  TO WS-CP-ORDEM
           MOVE AUX2I                  TO WS-CP-AUX
           MOVE SIT2I                  TO WS-CP-SIT
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
           MOVE RED3I                  TO WS-CP-REDUZ
           MOVE ORD3I                  TO WS-CP-ORDEM
           MOVE AUX3I                  TO WS-CP-AUX
           MOVE SIT3I                  TO WS-CP-SIT
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
           MOVE RED4I                  TO WS-CP-REDUZ
           MOVE ORD4I                  TO WS-CP-ORDEM
           MOVE AUX4I                  TO WS-CP-AUX
           MOVE SIT4I                  TO WS-CP-SIT
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
           MOVE RED5I                  TO WS-CP-REDUZ
           MOVE ORD5I                  TO WS-CP-ORDEM
           MOVE AUX5I                  TO WS-CP-AUX
           MOVE SIT5I                  TO WS-CP-SIT
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
           MOVE RED6I                  TO WS-CP-REDUZ
           MOVE ORD6I                  TO WS-CP-ORDEM
           MOVE AUX6I                  TO WS-CP-AUX
           MOVE SIT6I                  TO WS-CP-SIT
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
           MOVE RED7I                  TO WS-CP-REDUZ
           MOVE ORD7I                  TO WS-CP-ORDEM
           MOVE AUX7I                  TO WS-CP-AUX
           MOVE SIT7I                  TO WS-CP-SIT
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
           MOVE RED8I                  TO WS-CP-REDUZ
           MOVE ORD8I                  TO WS-CP-ORDEM
           MOVE AUX8I                  TO WS-CP-AUX
           MOVE SIT8I                  TO WS-CP-SIT
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
           MOVE RED9I                  TO WS-CP-REDUZ
           MOVE ORD9I                  TO WS-CP-ORDEM
           MOVE AUX9I                  TO WS-CP-AUX
           MOVE SIT9I                  TO WS-CP-SIT
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
           MOVE REDAI                  TO WS-CP-REDUZ
           MOVE ORDAI                  TO WS-CP-ORDEM
           MOVE AUXAI                  TO WS-CP-AUX
           MOVE SITAI                  TO WS-CP-SIT
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
           MOVE REDBI                  TO WS-CP-REDUZ
           MOVE ORDBI                  TO WS-CP-ORDEM
           MOVE AUXBI                  TO WS-CP-AUX
           MOVE SITBI                  TO WS-CP-SIT
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
           MOVE REDCI                  TO WS-CP-REDUZ
           MOVE ORDCI                  TO WS-CP-ORDEM
           MOVE AUXCI                  TO WS-CP-AUX
           MOVE SITCI                  TO WS-CP-SIT
           PERFORM 3150-GUARDAR-LINHA.
       3121-FIM.
           EXIT.
      *
       3150-GUARDAR-LINHA SECTION.
       3150-INICIO.
           MOVE SPACES                 TO WS-LN-ACAO(WS-IX)
                                          WS-LN-DESCR(WS-IX)
                                          WS-LN-REDUZ(WS-IX)
                                          WS-LN-AUX(WS-IX)
                                          WS-LN-SIT(WS-IX)
                                          WS-LN-SIS(WS-IX)
           MOVE 'N'                    TO WS-LN-DES-INF(WS-IX)
                                          WS-LN-RED-INF(WS-IX)
                                          WS-LN-ORD-INF(WS-IX)
                                          WS-LN-AUX-INF(WS-IX)
                                          WS-LN-SIT-INF(WS-IX)
                                          WS-LN-MAL-FORM(WS-IX)
           MOVE ZEROS                  TO WS-LN-ORDEM(WS-IX)
      *
           IF WS-CP-ACAO NOT = LOW-VALUES
               MOVE FUNCTION UPPER-CASE(WS-CP-ACAO)
                                       TO WS-LN-ACAO(WS-IX)
           END-IF
      *
      *--- CODIGO: O DIGITADO PREVALECE SOBRE O DA PAGINA ------------
           MOVE WS-ES-CODIGO(WS-IX)    TO WS-LN-CODIGO(WS-IX)
           IF WS-CP-CODIGO NOT = LOW-VALUES
              AND WS-CP-CODIGO NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-CODIGO)
                                       TO WS-CD-BRUTO
               PERFORM 7300-COMPACTAR-COD
               MOVE WS-CD-LIMPO        TO WS-LN-CODIGO(WS-IX)
           END-IF
      *
           IF WS-CP-DESCR NOT = LOW-VALUES
              AND WS-CP-DESCR NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-DESCR)
                                       TO WS-LN-DESCR(WS-IX)
               MOVE 'S'                TO WS-LN-DES-INF(WS-IX)
           END-IF
      *
           IF WS-CP-REDUZ NOT = LOW-VALUES
              AND WS-CP-REDUZ NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-REDUZ)
                                       TO WS-LN-REDUZ(WS-IX)
               MOVE 'S'                TO WS-LN-RED-INF(WS-IX)
           END-IF
      *
           IF WS-CP-ORDEM NOT = LOW-VALUES
              AND WS-CP-ORDEM NOT = SPACES
               MOVE 'S'                TO WS-LN-ORD-INF(WS-IX)
           MOVE WS-CP-ORDEM            TO WS-ED-CAMPO
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-TAM-DEC = ZEROS
                  AND WS-ED-TAM-INT <= 3
                   MOVE WS-ED-INT      TO WS-LN-ORDEM(WS-IX)
               ELSE
                   MOVE 'S'            TO WS-LN-MAL-FORM(WS-IX)
               END-IF
           END-IF
      *
           IF WS-CP-AUX NOT = LOW-VALUES
              AND WS-CP-AUX NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-AUX)
                                       TO WS-LN-AUX(WS-IX)
               MOVE 'S'                TO WS-LN-AUX-INF(WS-IX)
           END-IF
      *
           IF WS-CP-SIT NOT = LOW-VALUES
              AND WS-CP-SIT NOT = SPACES
               MOVE FUNCTION UPPER-CASE(WS-CP-SIT)
                                       TO WS-LN-SIT(WS-IX)
               MOVE 'S'                TO WS-LN-SIT-INF(WS-IX)
           END-IF.
       3150-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3200 - CRITICA DO TIPO CONTRA O META-DOMINIO TIP (RN01)        *
      *                                                                *
      * A DESCRICAO DO TIPO VEM DO PROPRIO REGISTRO TIP E ALIMENTA O   *
      * CAMPO PROTEGIDO MDESTIP. TIPO INVALIDO DEIXA WS-TIPO-OK EM N E *
      * AS TECLAS DE CARGA, PAGINACAO E GRAVACAO RECUSAM O SERVICO.    *
      *----------------------------------------------------------------*
       3200-CRITICAR-TIPO SECTION.
       3200-INICIO.
           MOVE 'N'                    TO WS-TIPO-OK
           MOVE SPACES                 TO WS-DESC-TIPO
      *
           IF WS-ES-TIPO = SPACES
               MOVE 'RN01 - INFORME O TIPO DE DOMINIO (F4 LISTA)'
                                       TO WS-MENSAGEM
               GO TO 3200-FIM
           END-IF
      *
           MOVE WS-META-TIPO           TO DOM-TIPO
           MOVE WS-ES-TIPO             TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
           MOVE SPACES                 TO WS-MENSAGEM
               STRING 'RN01 - TIPO ' WS-ES-TIPO
                      ' NAO CADASTRADO NO CATALOGO TIP'
                      DELIMITED BY SIZE INTO WS-MENSAGEM
               GO TO 3200-FIM
           END-IF
      *
           MOVE DOM-DESCRICAO          TO WS-DESC-TIPO
           SET TIPO-VALIDO             TO TRUE.
       3200-FIM.
           EXIT.
      *
      *================================================================*
      * 3500 A 3950 - CARGA E PAGINACAO DA GRADE                       *
      *                                                                *
      * A PAGINA SEGUINTE RELE A PARTIR DA ULTIMA CHAVE EXIBIDA. A     *
      * PAGINA ANTERIOR USA READPREV A PARTIR DA PRIMEIRA CHAVE DA     *
      * PAGINA ATUAL, EVITANDO REPERCORRER O ARQUIVO DESDE O INICIO.   *
      * OS DOIS SENTIDOS PARAM QUANDO DOM-TIPO DEIXA DE SER O TIPO DA  *
      * TELA, PORQUE A CHAVE DO SFPDOM COMECA PELO TIPO.               *
      *                                                                *
      * ATENCAO: 6300-AVISAR TERMINA EM EXEC CICS RETURN, LOGO NAO     *
      * DEVOLVE O CONTROLE. O GO TO APOS ELE E DOCUMENTACAO DO FLUXO.  *
      *================================================================*
       3500-CARREGAR-PAGINA SECTION.
       3500-INICIO.
           IF NOT TIPO-VALIDO
               PERFORM 6300-AVISAR
               GO TO 3500-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-PULAR-IGUAL
           MOVE SPACES                 TO WS-CHAVE-BUSCA
           MOVE 1                      TO WS-ES-PAGINA
           PERFORM 3800-LER-ADIANTE
           PERFORM 3950-FIXAR-PAGINA
      *
           PERFORM 6000-TABELA-PARA-MAPA
           IF WS-QTD-LINHAS = ZEROS
               MOVE 'TIPO SEM NENHUM DOMINIO CADASTRADO'
                                       TO MMENSAGO
           END-IF
           PERFORM 6100-ENVIAR-ERASE.
       3500-FIM.
           EXIT.
      *
       3600-PAGINA-SEGUINTE SECTION.
       3600-INICIO.
           IF NOT TIPO-VALIDO
               PERFORM 6300-AVISAR
               GO TO 3600-FIM
           END-IF
      *
           IF WS-ES-ULTIMA = SPACES
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
           IF NOT TIPO-VALIDO
               PERFORM 6300-AVISAR
               GO TO 3700-FIM
           END-IF
      *
           IF WS-ES-PRIMEIRA = SPACES
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
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-CHAVE-BUSCA         TO DOM-CODIGO
      *
           EXEC CICS STARTBR
                FILE(WS-ARQUIVO) RIDFLD(DOM-CHAVE)
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
                    FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                    RIDFLD(DOM-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF DOM-TIPO NOT = WS-ES-TIPO
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF WS-PULAR-IGUAL = 'S'
                  AND DOM-CODIGO = WS-CHAVE-BUSCA
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
           MOVE DOM-CODIGO             TO WS-LN-CODIGO(WS-IY)
           MOVE DOM-DESCRICAO          TO WS-LN-DESCR(WS-IY)
           MOVE DOM-DESCR-REDUZ        TO WS-LN-REDUZ(WS-IY)
           MOVE DOM-ORDEM              TO WS-LN-ORDEM(WS-IY)
           MOVE DOM-VALOR-AUX          TO WS-LN-AUX(WS-IY)
           MOVE DOM-SITUACAO           TO WS-LN-SIT(WS-IY)
           IF DOM-IND-SISTEMA = 'S'
               MOVE 'SIS'              TO WS-LN-SIS(WS-IY)
           ELSE
               MOVE SPACES             TO WS-LN-SIS(WS-IY)
           END-IF
           MOVE 'N'                    TO WS-LN-DES-INF(WS-IY)
                                          WS-LN-RED-INF(WS-IY)
                                          WS-LN-ORD-INF(WS-IY)
                                          WS-LN-AUX-INF(WS-IY)
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
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-ES-PRIMEIRA         TO DOM-CODIGO
      *
           EXEC CICS STARTBR
                FILE(WS-ARQUIVO) RIDFLD(DOM-CHAVE)
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
                    FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                    RIDFLD(DOM-CHAVE) RESP(WS-RESP)
               END-EXEC
      *
               IF WS-RESP NOT = DFHRESP(NORMAL)
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF DOM-TIPO NOT = WS-ES-TIPO
                   SET FIM-BROWSE      TO TRUE
                   EXIT PERFORM
               END-IF
      *
               IF DOM-CODIGO >= WS-ES-PRIMEIRA
                   EXIT PERFORM CYCLE
               END-IF
      *
               ADD 1                   TO WS-QTD-REV
               MOVE REG-DOMINIO        TO WS-REV-REG(WS-QTD-REV)
           END-PERFORM
      *
           EXEC CICS ENDBR FILE(WS-ARQUIVO) END-EXEC
      *
      *--- A LEITURA VEIO DECRESCENTE: INVERTE NA GRADE ---------------
           MOVE WS-QTD-REV             TO WS-QTD-LINHAS
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-QTD-REV
               MOVE WS-REV-REG(WS-IX)  TO REG-DOMINIO
               COMPUTE WS-IY = WS-QTD-REV - WS-IX + 1
               PERFORM 3850-REG-PARA-LINHA
           END-PERFORM.
       3900-FIM.
           EXIT.
      *
       3950-FIXAR-PAGINA SECTION.
       3950-INICIO.
           MOVE SPACES                 TO WS-ES-PRIMEIRA
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
           IF NOT TIPO-VALIDO
               PERFORM 6300-AVISAR
               GO TO 4000-FIM
           END-IF
      *
           MOVE 'N'                    TO WS-ERRO
           MOVE ZEROS                  TO WS-INCLUIDOS
                                          WS-ALTERADOS
                                          WS-EXCLUIDOS
                                          WS-LINHA-ERRO
      *
      *--- FASE 1 - CRITICA ------------------------------------------
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
      *--- FASE 2 - APLICA -------------------------------------------
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
                      OR TEM-ERRO
               EVALUATE WS-LN-ACAO(WS-IX)
                   WHEN 'I'
                        PERFORM 4200-INCLUIR-DOMINIO
                   WHEN 'A'
                        PERFORM 4300-ALTERAR-DOMINIO
                   WHEN 'E'
                        PERFORM 4400-EXCLUIR-DOMINIO
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
      *--- RECARREGA A PAGINA PARA REFLETIR O QUE FOI GRAVADO --------
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
           IF WS-LN-CODIGO(WS-IX) = SPACES
               MOVE 'RN02 - CODIGO DO DOMINIO OBRIGATORIO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-MAL-FORM(WS-IX) = 'S'
               MOVE 'ORDEM DE EXIBICAO COM CARACTER INVALIDO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- O DOMINIO EXISTE OU NAO? RN06 E RN07 ----------------------
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-LN-CODIGO(WS-IX)    TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
              AND WS-RESP NOT = DFHRESP(NOTFND)
               MOVE 'ERRO DE LEITURA NO SFPDOM - VER SUPORTE'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-ACAO(WS-IX) = 'I'
              AND WS-RESP = DFHRESP(NORMAL)
               MOVE 'RN06 - DOMINIO JA CADASTRADO NESTE TIPO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
           IF WS-LN-ACAO(WS-IX) NOT = 'I'
              AND WS-RESP = DFHRESP(NOTFND)
               MOVE 'RN07 - DOMINIO NAO CADASTRADO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- RN08 - DOMINIO DE SISTEMA E INTOCAVEL ---------------------
           IF WS-LN-ACAO(WS-IX) NOT = 'I'
              AND DOM-PROTEGIDO
               MOVE 'RN08 - DOMINIO DE SISTEMA NAO PODE SER'
                                       TO WS-MENSAGEM
               MOVE ' ALTERADO NEM EXCLUIDO'
                                       TO WS-MENSAGEM(39:23)
               PERFORM 4190-MARCAR-ERRO
               GO TO 4100-FIM
           END-IF
      *
      *--- EXCLUSAO NAO CRITICA CONTEUDO -----------------------------
           IF WS-LN-ACAO(WS-IX) = 'E'
               GO TO 4100-FIM
           END-IF
      *
      *--- INCLUSAO: EXIGENCIAS E VALORES PADRAO ---------------------
           IF WS-LN-ACAO(WS-IX) = 'I'
               IF WS-LN-DES-INF(WS-IX) NOT = 'S'
                  OR WS-LN-ORD-INF(WS-IX) NOT = 'S'
                   MOVE 'INCLUSAO EXIGE DESCRICAO E ORDEM'
                                       TO WS-MENSAGEM
                   PERFORM 4190-MARCAR-ERRO
                   GO TO 4100-FIM
               END-IF
      *
               IF WS-LN-RED-INF(WS-IX) NOT = 'S'
                   MOVE WS-LN-DESCR(WS-IX)(1:12)
                                       TO WS-LN-REDUZ(WS-IX)
                   MOVE 'S'            TO WS-LN-RED-INF(WS-IX)
               END-IF
               IF WS-LN-SIT-INF(WS-IX) NOT = 'S'
                   MOVE 'A'            TO WS-LN-SIT(WS-IX)
                   MOVE 'S'            TO WS-LN-SIT-INF(WS-IX)
               END-IF
               INITIALIZE REG-DOMINIO
           END-IF
      *
      *--- CRITICA O REGISTRO COM OS CAMPOS DA TELA APLICADOS --------
           PERFORM 4150-MONTAR-REGISTRO
           PERFORM 4160-CRITICAR-REGISTRO.
       4100-FIM.
           EXIT.
      *
       4150-MONTAR-REGISTRO SECTION.
       4150-INICIO.
           IF WS-LN-DES-INF(WS-IX) = 'S'
               MOVE WS-LN-DESCR(WS-IX) TO DOM-DESCRICAO
           END-IF
           IF WS-LN-RED-INF(WS-IX) = 'S'
               MOVE WS-LN-REDUZ(WS-IX) TO DOM-DESCR-REDUZ
           END-IF
           IF WS-LN-ORD-INF(WS-IX) = 'S'
               MOVE WS-LN-ORDEM(WS-IX) TO DOM-ORDEM
           END-IF
           IF WS-LN-AUX-INF(WS-IX) = 'S'
               MOVE WS-LN-AUX(WS-IX)   TO DOM-VALOR-AUX
           END-IF
           IF WS-LN-SIT-INF(WS-IX) = 'S'
               MOVE WS-LN-SIT(WS-IX)   TO DOM-SITUACAO
           END-IF.
       4150-FIM.
           EXIT.
      *
       4160-CRITICAR-REGISTRO SECTION.
       4160-INICIO.
           IF DOM-DESCRICAO = SPACES
               MOVE 'RN03 - DESCRICAO DO DOMINIO OBRIGATORIA'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF DOM-ORDEM = ZEROS
               MOVE 'RN04 - ORDEM DE EXIBICAO DE 001 A 999'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4160-FIM
           END-IF
      *
           IF NOT DOM-ATIVO AND NOT DOM-INATIVO
               MOVE 'RN05 - SITUACAO DEVE SER A OU I'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4160-FIM.
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
       4200-INCLUIR-DOMINIO SECTION.
       4200-INICIO.
           INITIALIZE REG-DOMINIO
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-LN-CODIGO(WS-IX)    TO DOM-CODIGO
           MOVE 'N'                    TO DOM-IND-SISTEMA
           MOVE SPACES                 TO DOM-FILLER
           SET DOM-ATIVO               TO TRUE
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS WRITE
                FILE(WS-ARQUIVO) FROM(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-INCLUIDOS
           ELSE
               MOVE 'FALHA AO INCLUIR O DOMINIO NO SFPDOM'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4200-FIM.
           EXIT.
      *
       4300-ALTERAR-DOMINIO SECTION.
       4300-INICIO.
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-LN-CODIGO(WS-IX)    TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'FALHA AO LER O DOMINIO PARA ALTERACAO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4300-FIM
           END-IF
      *
           PERFORM 4150-MONTAR-REGISTRO
      *
           EXEC CICS REWRITE
                FILE(WS-ARQUIVO) FROM(REG-DOMINIO)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-ALTERADOS
           ELSE
               MOVE 'FALHA AO ALTERAR O DOMINIO NO SFPDOM'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4300-FIM.
           EXIT.
      *
       4400-EXCLUIR-DOMINIO SECTION.
       4400-INICIO.
           MOVE WS-ES-TIPO             TO DOM-TIPO
           MOVE WS-LN-CODIGO(WS-IX)    TO DOM-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-DOMINIO)
                RIDFLD(DOM-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'FALHA AO LER O DOMINIO PARA EXCLUSAO'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
               GO TO 4400-FIM
           END-IF
      *
           EXEC CICS DELETE
                FILE(WS-ARQUIVO) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               ADD 1                   TO WS-EXCLUIDOS
           ELSE
               MOVE 'FALHA AO EXCLUIR O DOMINIO NO SFPDOM'
                                       TO WS-MENSAGEM
               PERFORM 4190-MARCAR-ERRO
           END-IF.
       4400-FIM.
           EXIT.
      *
       4500-CHAMAR-LOOKUP SECTION.
       4500-INICIO.
           INITIALIZE AREA-LOOKUP
           MOVE WS-META-TIPO           TO LOK-TIPO-DOMINIO
           MOVE WS-PROGRAMA            TO LOK-PGM-CHAMADOR
           MOVE 'MTIPO'                TO LOK-CAMPO-ORIGEM
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
      * MENSAGEM (6300) SO CARREGA PAGINA E MENSAGEM: O QUE O USUARIO  *
      * DIGITOU CONTINUA NA TELA.                                      *
      *                                                                *
      * AS DOZE LINHAS SAO TRATADAS UMA A UMA PORQUE OS NOMES DO       *
      * COPYBOOK SIMBOLICO NAO FORMAM UM OCCURS.                       *
      *================================================================*
       6000-TABELA-PARA-MAPA SECTION.
       6000-INICIO.
           MOVE LOW-VALUES             TO MAPDOMIO
           MOVE WS-ES-TIPO             TO MTIPOO
           MOVE WS-DESC-TIPO           TO MDESTIPO
           MOVE WS-ES-PAGINA           TO MPAGO
      *
           PERFORM VARYING WS-IX FROM 1 BY 1
                   UNTIL WS-IX > WS-LINHAS-PAGINA
               IF WS-LN-CODIGO(WS-IX) NOT = SPACES
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
           MOVE WS-LN-REDUZ(WS-IX)     TO RED1O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD1O
           MOVE WS-LN-AUX(WS-IX)       TO AUX1O
           MOVE WS-LN-SIT(WS-IX)       TO SIT1O
           MOVE WS-LN-SIS(WS-IX)       TO SIS1O.
       6010-FIM.
           EXIT.
      *
       6011-MOSTRAR-LINHA-02 SECTION.
       6011-INICIO.
           MOVE SPACES                 TO ACAO2O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD2O
           MOVE WS-LN-DESCR(WS-IX)     TO DES2O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED2O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD2O
           MOVE WS-LN-AUX(WS-IX)       TO AUX2O
           MOVE WS-LN-SIT(WS-IX)       TO SIT2O
           MOVE WS-LN-SIS(WS-IX)       TO SIS2O.
       6011-FIM.
           EXIT.
      *
       6012-MOSTRAR-LINHA-03 SECTION.
       6012-INICIO.
           MOVE SPACES                 TO ACAO3O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD3O
           MOVE WS-LN-DESCR(WS-IX)     TO DES3O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED3O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD3O
           MOVE WS-LN-AUX(WS-IX)       TO AUX3O
           MOVE WS-LN-SIT(WS-IX)       TO SIT3O
           MOVE WS-LN-SIS(WS-IX)       TO SIS3O.
       6012-FIM.
           EXIT.
      *
       6013-MOSTRAR-LINHA-04 SECTION.
       6013-INICIO.
           MOVE SPACES                 TO ACAO4O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD4O
           MOVE WS-LN-DESCR(WS-IX)     TO DES4O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED4O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD4O
           MOVE WS-LN-AUX(WS-IX)       TO AUX4O
           MOVE WS-LN-SIT(WS-IX)       TO SIT4O
           MOVE WS-LN-SIS(WS-IX)       TO SIS4O.
       6013-FIM.
           EXIT.
      *
       6014-MOSTRAR-LINHA-05 SECTION.
       6014-INICIO.
           MOVE SPACES                 TO ACAO5O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD5O
           MOVE WS-LN-DESCR(WS-IX)     TO DES5O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED5O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD5O
           MOVE WS-LN-AUX(WS-IX)       TO AUX5O
           MOVE WS-LN-SIT(WS-IX)       TO SIT5O
           MOVE WS-LN-SIS(WS-IX)       TO SIS5O.
       6014-FIM.
           EXIT.
      *
       6015-MOSTRAR-LINHA-06 SECTION.
       6015-INICIO.
           MOVE SPACES                 TO ACAO6O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD6O
           MOVE WS-LN-DESCR(WS-IX)     TO DES6O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED6O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD6O
           MOVE WS-LN-AUX(WS-IX)       TO AUX6O
           MOVE WS-LN-SIT(WS-IX)       TO SIT6O
           MOVE WS-LN-SIS(WS-IX)       TO SIS6O.
       6015-FIM.
           EXIT.
      *
       6016-MOSTRAR-LINHA-07 SECTION.
       6016-INICIO.
           MOVE SPACES                 TO ACAO7O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD7O
           MOVE WS-LN-DESCR(WS-IX)     TO DES7O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED7O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD7O
           MOVE WS-LN-AUX(WS-IX)       TO AUX7O
           MOVE WS-LN-SIT(WS-IX)       TO SIT7O
           MOVE WS-LN-SIS(WS-IX)       TO SIS7O.
       6016-FIM.
           EXIT.
      *
       6017-MOSTRAR-LINHA-08 SECTION.
       6017-INICIO.
           MOVE SPACES                 TO ACAO8O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD8O
           MOVE WS-LN-DESCR(WS-IX)     TO DES8O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED8O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD8O
           MOVE WS-LN-AUX(WS-IX)       TO AUX8O
           MOVE WS-LN-SIT(WS-IX)       TO SIT8O
           MOVE WS-LN-SIS(WS-IX)       TO SIS8O.
       6017-FIM.
           EXIT.
      *
       6018-MOSTRAR-LINHA-09 SECTION.
       6018-INICIO.
           MOVE SPACES                 TO ACAO9O
           MOVE WS-LN-CODIGO(WS-IX)    TO COD9O
           MOVE WS-LN-DESCR(WS-IX)     TO DES9O
           MOVE WS-LN-REDUZ(WS-IX)     TO RED9O
           MOVE WS-LN-ORDEM(WS-IX)     TO ORD9O
           MOVE WS-LN-AUX(WS-IX)       TO AUX9O
           MOVE WS-LN-SIT(WS-IX)       TO SIT9O
           MOVE WS-LN-SIS(WS-IX)       TO SIS9O.
       6018-FIM.
           EXIT.
      *
       6019-MOSTRAR-LINHA-10 SECTION.
       6019-INICIO.
           MOVE SPACES                 TO ACAOAO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODAO
           MOVE WS-LN-DESCR(WS-IX)     TO DESAO
           MOVE WS-LN-REDUZ(WS-IX)     TO REDAO
           MOVE WS-LN-ORDEM(WS-IX)     TO ORDAO
           MOVE WS-LN-AUX(WS-IX)       TO AUXAO
           MOVE WS-LN-SIT(WS-IX)       TO SITAO
           MOVE WS-LN-SIS(WS-IX)       TO SISAO.
       6019-FIM.
           EXIT.
      *
       6020-MOSTRAR-LINHA-11 SECTION.
       6020-INICIO.
           MOVE SPACES                 TO ACAOBO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODBO
           MOVE WS-LN-DESCR(WS-IX)     TO DESBO
           MOVE WS-LN-REDUZ(WS-IX)     TO REDBO
           MOVE WS-LN-ORDEM(WS-IX)     TO ORDBO
           MOVE WS-LN-AUX(WS-IX)       TO AUXBO
           MOVE WS-LN-SIT(WS-IX)       TO SITBO
           MOVE WS-LN-SIS(WS-IX)       TO SISBO.
       6020-FIM.
           EXIT.
      *
       6021-MOSTRAR-LINHA-12 SECTION.
       6021-INICIO.
           MOVE SPACES                 TO ACAOCO
           MOVE WS-LN-CODIGO(WS-IX)    TO CODCO
           MOVE WS-LN-DESCR(WS-IX)     TO DESCO
           MOVE WS-LN-REDUZ(WS-IX)     TO REDCO
           MOVE WS-LN-ORDEM(WS-IX)     TO ORDCO
           MOVE WS-LN-AUX(WS-IX)       TO AUXCO
           MOVE WS-LN-SIT(WS-IX)       TO SITCO
           MOVE WS-LN-SIS(WS-IX)       TO SISCO.
       6021-FIM.
           EXIT.
      *
       6100-ENVIAR-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPDOMIO)
                ERASE FREEKB CURSOR
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND MAP(WS-MAPA)
                MAPSET(WS-MAPSET) FROM(MAPDOMIO)
                DATAONLY FREEKB CURSOR
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
       6300-AVISAR SECTION.
       6300-INICIO.
           MOVE LOW-VALUES             TO MAPDOMIO
           MOVE WS-ES-PAGINA           TO MPAGO
           MOVE WS-MENSAGEM            TO MMENSAGO
           PERFORM 6200-ENVIAR-DATAONLY.
       6300-FIM.
           EXIT.
      *
      *================================================================*
      * 7300 E 7400 - APOIO                                            *
      *                                                                *
      * 7300 TIRA OS ESPACOS DO CODIGO DIGITADO E O ALINHA A ESQUERDA: *
      * O CODIGO GRAVADO NO SFPDOM E ALINHADO A ESQUERDA E UM ESPACO   *
      * NA FRENTE GERARIA OUTRA CHAVE.                                 *
      *                                                                *
      * 7400 DES-EDITA A ORDEM DE EXIBICAO. O CAMPO CHEGA DO BMS COMO  *
      * X(003) ALINHADO A ESQUERDA: MOVE DIRETO PARA 9(003) DARIA      *
      * VALOR ERRADO. AQUI O TEXTO E VALIDADO CARACTERE A CARACTERE,   *
      * COMPACTADO E REMONTADO. A VIRGULA E CONTADA SO PARA PODER SER  *
      * RECUSADA PELO CHAMADOR (WS-ED-TAM-DEC MAIOR QUE ZERO).         *
      *================================================================*
       7300-COMPACTAR-COD SECTION.
       7300-INICIO.
           MOVE SPACES                 TO WS-CD-LIMPO
           MOVE ZEROS                  TO WS-CD-TAM
      *
           PERFORM VARYING WS-IY FROM 1 BY 1 UNTIL WS-IY > 6
               EVALUATE WS-CD-BRUTO(WS-IY:1)
                   WHEN SPACE
                        CONTINUE
                   WHEN LOW-VALUE
                        CONTINUE
                   WHEN OTHER
                        ADD 1           TO WS-CD-TAM
                        MOVE WS-CD-BRUTO(WS-IY:1)
                                        TO WS-CD-LIMPO
                                           (WS-CD-TAM:1)
               END-EVALUATE
           END-PERFORM.
       7300-FIM.
           EXIT.
      *
       7400-DE-EDITAR SECTION.
       7400-INICIO.
           MOVE 'S'                    TO WS-ED-OK
           MOVE ZEROS                  TO WS-ED-TAM
                                          WS-ED-VIRGULA
                                          WS-ED-INVALIDOS
                                          WS-ED-TAM-INT
                                          WS-ED-TAM-DEC
                                          WS-ED-INT
           MOVE SPACES                 TO WS-ED-COMPACTO
      *
           IF WS-ED-CAMPO = SPACES
               GO TO 7400-FIM
           END-IF
      *
      *--- TIRA ESPACOS, CONTA VIRGULAS E RECUSA O RESTO --------------
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
           MOVE 'N'                    TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
           IF WS-ED-TAM = ZEROS
               GO TO 7400-FIM
           END-IF
      *
      *--- SEPARA A PARTE INTEIRA DOS DECIMAIS ------------------------
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
           IF WS-ED-TAM-INT > 9
           MOVE 'N'                    TO WS-ED-OK
               GO TO 7400-FIM
           END-IF
      *
      *--- PARTE INTEIRA ALINHADA A DIREITA --------------------------
           MOVE ZEROS                  TO WS-ED-INT-X
           IF WS-ED-TAM-INT > ZEROS
               COMPUTE WS-IY = 10 - WS-ED-TAM-INT
               MOVE WS-ED-COMPACTO(1:WS-ED-TAM-INT)
                                       TO WS-ED-INT-X
                                          (WS-IY:WS-ED-TAM-INT)
           END-IF
           MOVE WS-ED-INT-X            TO WS-ED-INT.
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
