      *================================================================*
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * PROGRAMA : SFP0130                                             *
      * TRANSACAO: SF05                                                *
      * MAPSET   : SFPM04   MAPA: MAPEMPR                              *
      * FUNCAO   : CADASTRO DA EMPRESA E DOS ESTABELECIMENTOS          *
      *            FORMULARIO COM ACAO I, A, C E E                     *
      *----------------------------------------------------------------*
      * ESTE MODULO EXIGE O TRADUTOR CICS ANTES DO COMPILADOR COBOL.   *
      * NAO E COMPILAVEL FORA DO AMBIENTE MAINFRAME. NAO USA DB2: O    *
      * ESTABELECIMENTO MORA NO ARQUIVO VSAM SFPEST, LIDO PELOS        *
      * COMANDOS DE ARQUIVO DO CICS, COMO NO SFP0110 E NO SFP0140.     *
      *----------------------------------------------------------------*
      * O CODIGO 0001 E SEMPRE A MATRIZ. AS FILIAIS (0002 EM DIANTE)   *
      * HERDAM DA MATRIZ, NO BATCH, OS PARAMETROS QUE DEIXAREM EM      *
      * BRANCO. O CADASTRO ALIMENTA O CABECALHO DOS RELATORIOS, O      *
      * HEADER DO CNAB240 (SFP0600) E A APURACAO DE ENCARGOS.          *
      *----------------------------------------------------------------*
      * O MAPA USA CTRL=(FREEKB,FRSET): NO RECEIVE SO VOLTAM OS        *
      * CAMPOS QUE O USUARIO DIGITOU. POR ISSO O ESTABELECIMENTO EM    *
      * EDICAO VIVE FORA DA TELA E CADA CAMPO SO E SUBSTITUIDO QUANDO  *
      * O COMPRIMENTO RECEBIDO (MxxxL) E MAIOR QUE ZERO.               *
      *                                                                *
      * AQUI O ESTADO NAO CABE NA COMMAREA: O REGISTRO TEM 372 BYTES   *
      * DE CAMPOS DE TELA E A COM-AREA-TRABALHO SO OFERECE 326 BYTES   *
      * DEPOIS DOS 120 QUE O SFPWLOK RESERVA. LOGO O ESTADO VIVE NUMA  *
      * FILA TEMPORARIA (TS QUEUE) EM MEMORIA PRINCIPAL, UMA POR       *
      * TERMINAL: S13 MAIS EIBTRMID. A COMMAREA CONTINUA LEVANDO SO    *
      * A AREA DE LOOKUP, COMO NOS OUTROS PROGRAMAS.                   *
      *                                                                *
      * A FILA E APAGADA NO F12, NA SAIDA PELO F3 E DEPOIS DA          *
      * EXCLUSAO. POR SER MAIN, ELA NAO E RECUPERAVEL: O SYNCPOINT     *
      * ROLLBACK DO 9999 DESFAZ O SFPEST, NAO A FILA. NAO E PROBLEMA   *
      * PORQUE A FILA GUARDA DIGITACAO, NAO DADO CONFIRMADO.           *
      *----------------------------------------------------------------*
      * AS ALIQUOTAS CHEGAM DO BMS EM CAMPO DE TEXTO ALINHADO A        *
      * ESQUERDA: MOVE DIRETO PARA 9(002)V99 DARIA VALOR ERRADO. VER   *
      * 7400-DE-EDITAR, QUE AQUI TRABALHA COM ATE 14 DIGITOS INTEIROS  *
      * PORQUE O CNPJ E A CONTA PAGADORA PASSAM PELA MESMA ROTINA.     *
      *----------------------------------------------------------------*
      * A TECLA F4 ATENDE TIPO DE LOGRADOURO (LINHA 8), MUNICIPIO E UF *
      * (AMBOS NA LINHA 10) E BANCO PAGADOR (LINHA 18). A LINHA DO     *
      * CURSOR (EIBCPOSN) NAO BASTA PARA A LINHA 10, QUE ABRIGA DOIS   *
      * CAMPOS COM F4: O PROGRAMA CALCULA A COLUNA COM                 *
      * FUNCTION MOD(EIBCPOSN, 80) + 1 E TRATA COLUNA MENOR QUE 40     *
      * COMO MUNICIPIO (COM A UF DA TELA EM LOK-UF-FILTRO) E AS        *
      * DEMAIS COMO UF. O CODIGO IBGE TEM 7 DIGITOS E CABE EM          *
      * LOK-COD-SELECIONADO DESDE QUE O CAMPO PASSOU A X(007).         *
      *----------------------------------------------------------------*
      * REGRAS DE NEGOCIO                                              *
      *  RN01 - CODIGO DO ESTABELECIMENTO: 0001 A 9999                 *
      *  RN02 - O CODIGO 0001 E A MATRIZ (TIPO M); OS DEMAIS SAO       *
      *         FILIAIS (TIPO F)                                       *
      *  RN03 - CNPJ OBRIGATORIO, COM 14 DIGITOS                       *
      *  RN04 - RAZAO SOCIAL OBRIGATORIA                               *
      *  RN05 - TIPO DE LOGRADOURO CADASTRADO NO DOMINIO TLG           *
      *  RN06 - LOGRADOURO, NUMERO E BAIRRO OBRIGATORIOS               *
      *  RN07 - MUNICIPIO CADASTRADO NO SFPMUN E DA UF INFORMADA       *
      *  RN08 - UF CADASTRADA NO SFPUFE                                *
      *  RN09 - CEP OBRIGATORIO, COM 8 DIGITOS                         *
      *  RN10 - CNAE E FPAS OBRIGATORIOS                               *
      *  RN11 - ALIQUOTA RAT IGUAL A 1,00, 2,00 OU 3,00                *
      *  RN12 - FAP DE 0,5000 A 2,0000                                 *
      *  RN13 - CODIGO E ALIQUOTA DE TERCEIROS ANDAM JUNTOS: OS DOIS   *
      *         PREENCHIDOS OU OS DOIS EM ZEROS                        *
      *  RN14 - SIMPLES E DESONERACAO EM S OU N, NUNCA OS DOIS EM S    *
      *  RN15 - MES DA DATA-BASE DE 01 A 12                            *
      *  RN16 - DIA DE PAGAMENTO DE 01 A 31                            *
      *  RN17 - BANCO PAGADOR NO DOMINIO BAN, COM AGENCIA E CONTA      *
      *  RN18 - SITUACAO EM A OU I; A MATRIZ 0001 NAO PODE SER         *
      *         INATIVADA NEM EXCLUIDA                                 *
      *  RN19 - INCLUSAO NAO PODE DUPLICAR CODIGO                      *
      *  RN20 - CONSULTA, ALTERACAO E EXCLUSAO EXIGEM ESTABELECIMENTO  *
      *         JA CADASTRADO                                          *
      *  RN21 - FILIAL SO PODE SER INCLUIDA SE A MATRIZ 0001 EXISTIR   *
      *  RN22 - EXCLUSAO EXIGE CONSULTA PREVIA DO ESTABELECIMENTO      *
      *----------------------------------------------------------------*
      * A RN11 E A RN12 VEM DA LEGISLACAO DO SEGURO DE ACIDENTE DE     *
      * TRABALHO: O RAT E 1, 2 OU 3 POR CENTO SEGUNDO O RISCO DA       *
      * ATIVIDADE E O FAP MULTIPLICA ESSE PERCENTUAL ENTRE METADE E    *
      * DOBRO. O PRODUTO E O QUE O SFP0400 LANCA COMO ENCARGO.         *
      *                                                                *
      * A RN17 EXISTE PORQUE O SFP0600 MONTA O HEADER DO CNAB240 COM   *
      * BANCO, AGENCIA E CONTA DA MATRIZ. SEM ELES O ARQUIVO SAI       *
      * INVALIDO E O BANCO RECUSA A REMESSA INTEIRA.                   *
      *                                                                *
      * A RN21 PROTEGE A HERANCA: FILIAL CADASTRADA ANTES DA MATRIZ    *
      * FICARIA SEM DE ONDE HERDAR FPAS, RAT E FAP.                    *
      *                                                                *
      * SETE CAMPOS DO SFPWEST NAO TEM LUGAR NO SFPM04: INSCRICAO      *
      * MUNICIPAL, E-MAIL, CNPJ DO SINDICATO, PERCENTUAL DE            *
      * CONTRIBUICAO SINDICAL, DIA DO ADIANTAMENTO, DIGITO DA CONTA E  *
      * DATA DE INICIO DE ATIVIDADE. A ALTERACAO PARTE DA IMAGEM LIDA  *
      * PELO READ UPDATE, ENTAO ELES SAO PRESERVADOS; NA INCLUSAO      *
      * NASCEM EM BRANCO E SO PODEM SER CARREGADOS PELA MASSA.         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SFP0130.
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
           05  WS-TRANSACAO        PIC X(004) VALUE 'SF05'.
           05  WS-PROGRAMA         PIC X(008) VALUE 'SFP0130 '.
           05  WS-MAPSET           PIC X(007) VALUE 'SFPM04 '.
           05  WS-MAPA             PIC X(007) VALUE 'MAPEMPR'.
           05  WS-ARQUIVO          PIC X(008) VALUE 'SFPEST  '.
           05  WS-ARQ-DOMINIO      PIC X(008) VALUE 'SFPDOM  '.
           05  WS-ARQ-UF           PIC X(008) VALUE 'SFPUFE  '.
           05  WS-ARQ-MUNICIPIO    PIC X(008) VALUE 'SFPMUN  '.
           05  WS-IDENTIFICACAO    PIC X(050) VALUE
               'SFP0130 - CADASTRO DA EMPRESA - FIM DA SESSAO'.
      *
       COPY DFHAID.
       COPY DFHBMSCA.
       COPY SFPM04.
      *
       COPY SFPWEST.
      *
       COPY SFPWDOM.
      *
       COPY SFPWUFE.
      *
       COPY SFPWMUN.
      *
      *--- ESTABELECIMENTO EM EDICAO - VIVE NA FILA TEMPORARIA ---------
      * SAO OS CAMPOS QUE O SFPM04 EXIBE, NA ORDEM DO SFPWEST. 372     *
      * BYTES: NAO CABEM NA COMMAREA, VER O COMENTARIO DO CABECALHO.   *
       01  WS-ESTADO.
           05  WS-ES-ACAO          PIC X(001) VALUE SPACES.
           05  WS-ES-CODIGO        PIC 9(004) VALUE ZEROS.
           05  WS-ES-TIPO          PIC X(001) VALUE SPACES.
           05  WS-ES-CNPJ          PIC 9(014) VALUE ZEROS.
           05  WS-ES-IE            PIC X(015) VALUE SPACES.
           05  WS-ES-RAZAO         PIC X(060) VALUE SPACES.
           05  WS-ES-FANTAS        PIC X(040) VALUE SPACES.
           05  WS-ES-TIPLOG        PIC X(003) VALUE SPACES.
           05  WS-ES-LOGRAD        PIC X(040) VALUE SPACES.
           05  WS-ES-NUMERO        PIC X(008) VALUE SPACES.
           05  WS-ES-COMPL         PIC X(015) VALUE SPACES.
           05  WS-ES-BAIRRO        PIC X(025) VALUE SPACES.
           05  WS-ES-MUNIC         PIC 9(007) VALUE ZEROS.
           05  WS-ES-UF            PIC X(002) VALUE SPACES.
           05  WS-ES-CEP           PIC 9(008) VALUE ZEROS.
           05  WS-ES-TELEF         PIC X(014) VALUE SPACES.
           05  WS-ES-CNAE          PIC 9(007) VALUE ZEROS.
           05  WS-ES-FPAS          PIC 9(003) VALUE ZEROS.
           05  WS-ES-CODTER        PIC 9(004) VALUE ZEROS.
           05  WS-ES-ALIRAT        PIC 9(002)V99 VALUE ZEROS.
           05  WS-ES-FAP           PIC 9(001)V9999 VALUE ZEROS.
           05  WS-ES-ALITER        PIC 9(002)V99 VALUE ZEROS.
           05  WS-ES-SIMPLE        PIC X(001) VALUE SPACES.
           05  WS-ES-DESONE        PIC X(001) VALUE SPACES.
           05  WS-ES-SINDIC        PIC X(040) VALUE SPACES.
           05  WS-ES-DTBASE        PIC 9(002) VALUE ZEROS.
           05  WS-ES-BANCO         PIC 9(003) VALUE ZEROS.
           05  WS-ES-AGENCI        PIC 9(005) VALUE ZEROS.
           05  WS-ES-CONTA         PIC 9(012) VALUE ZEROS.
           05  WS-ES-DIAPAG        PIC 9(002) VALUE ZEROS.
           05  WS-ES-CONVEN        PIC X(020) VALUE SPACES.
           05  WS-ES-SITUAC        PIC X(001) VALUE SPACES.
           05  WS-ES-LIDA          PIC X(001) VALUE SPACES.
               88  WS-ES-VEIO-DO-ARQUIVO       VALUE 'S'.
      *
      *--- AREA DE TRABALHO --------------------------------------------
       01  WS-TRABALHO.
           05  WS-RESP             PIC S9(008) COMP VALUE ZEROS.
           05  WS-ERRO             PIC X(001) VALUE 'N'.
               88  TEM-ERRO            VALUE 'S'.
           05  WS-MENSAGEM         PIC X(079) VALUE SPACES.
           05  WS-IX               PIC S9(004) COMP VALUE ZEROS.
           05  WS-LINHA-CURSOR     PIC S9(004) COMP VALUE ZEROS.
           05  WS-COL-CURSOR       PIC S9(004) COMP VALUE ZEROS.
           05  WS-CODIGO-TELA      PIC 9(004) VALUE ZEROS.
           05  WS-ACAO-SALVA       PIC X(001) VALUE SPACES.
           05  WS-INT-OK           PIC X(001) VALUE 'N'.
           05  WS-DOM-TIPO         PIC X(003) VALUE SPACES.
           05  WS-DOM-CODIGO       PIC X(006) VALUE SPACES.
           05  WS-DOM-DESCR        PIC X(035) VALUE SPACES.
           05  WS-DOM-OK           PIC X(001) VALUE 'N'.
           05  WS-UF-OK            PIC X(001) VALUE 'N'.
           05  WS-MUN-OK           PIC X(001) VALUE 'N'.
           05  WS-MUN-NOME         PIC X(040) VALUE SPACES.
           05  WS-MUN-UF           PIC X(002) VALUE SPACES.
           05  WS-MATRIZ-EXISTE    PIC X(001) VALUE 'N'.
           05  WS-TS-FILA          PIC X(008) VALUE SPACES.
           05  WS-TS-TAM           PIC S9(004) COMP VALUE ZEROS.
      *
      *--- EDICAO DAS ALIQUOTAS PARA A TELA ----------------------------
       01  WS-SAIDA.
           05  WS-SA-RAT           PIC Z9,99.
           05  WS-SA-FAP           PIC 9,9999.
           05  WS-SA-TER           PIC Z9,99.
      *
      *--- DES-EDICAO DOS CAMPOS DIGITADOS (VER 7400) ------------------
      * WS-ED-INT TEM 14 DIGITOS PORQUE O CNPJ PASSA POR AQUI.         *
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
           MOVE SPACES                 TO WS-TS-FILA
           MOVE 'S13'                  TO WS-TS-FILA(1:3)
           MOVE EIBTRMID               TO WS-TS-FILA(4:4)
      *
           IF EIBCALEN = ZEROS
               PERFORM 1000-PRIMEIRA-VEZ
           ELSE
               MOVE DFHCOMMAREA        TO COMMAREA-SFP
               MOVE COM-AREA-TRABALHO
                    (1:LENGTH OF AREA-LOOKUP) TO AREA-LOOKUP
               PERFORM 1200-LER-ESTADO
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
      *
           INITIALIZE WS-ESTADO
           PERFORM 1400-APAGAR-ESTADO
           PERFORM 6000-LIMPAR-MAPA
           MOVE 'INFORME O CODIGO DO ESTABELECIMENTO E A ACAO DESEJADA'
                                       TO MMENSAGO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       1000-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1100 - RETORNO DA JANELA F4 (SFP0900)                          *
      *                                                                *
      * O SFP0900 DEVOLVE O CONTROLE POR XCTL: ESTA E UMA NOVA ENTRADA *
      * NO PROGRAMA E A TELA PRECISA SER REMONTADA DO WS-ESTADO.       *
      * LOK-CAMPO-ORIGEM DIZ QUAL CAMPO PEDIU A JANELA. O BANCO VOLTA  *
      * COMO TEXTO NO DOMINIO BAN E PASSA PELO 7400 PARA VIRAR 9(003). *
      *----------------------------------------------------------------*
       1100-VOLTA-DO-LOOKUP SECTION.
       1100-INICIO.
           IF LOK-SELECIONOU
               EVALUATE LOK-CAMPO-ORIGEM
                   WHEN 'MTIPLOG'
                        MOVE LOK-COD-SELECIONADO(1:3)
                                       TO WS-ES-TIPLOG
                   WHEN 'MUF'
                        MOVE LOK-COD-SELECIONADO(1:2)
                                       TO WS-ES-UF
                   WHEN 'MMUNIC'
                        MOVE SPACES    TO WS-ED-CAMPO
                        MOVE LOK-COD-SELECIONADO
                                       TO WS-ED-CAMPO(1:7)
                        MOVE 9999999   TO WS-ED-LIMITE
                        PERFORM 3060-INTEIRO-DA-TELA
                        IF WS-INT-OK = 'S'
                            MOVE WS-ED-VALOR
                                       TO WS-ES-MUNIC
                        END-IF
                   WHEN 'MBANCO'
                        MOVE SPACES    TO WS-ED-CAMPO
                        MOVE LOK-COD-SELECIONADO TO WS-ED-CAMPO(1:7)
                        MOVE 999       TO WS-ED-LIMITE
                        PERFORM 3060-INTEIRO-DA-TELA
                        IF WS-INT-OK = 'S'
                            MOVE WS-ED-VALOR
                                       TO WS-ES-BANCO
                        END-IF
                   WHEN OTHER
                        CONTINUE
               END-EVALUATE
           END-IF
      *
           MOVE SPACES                 TO LOK-PGM-CHAMADOR
           SET LOK-EM-CURSO            TO TRUE
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
      *
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       1100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 1200 A 1400 - ESTADO NA FILA TEMPORARIA                        *
      *                                                                *
      * FILA AUSENTE OU ILEGIVEL NAO E ERRO: O USUARIO PODE ESTAR      *
      * ENTRANDO AGORA, DEPOIS DE UM F12 OU DE UMA EXCLUSAO. NESSE     *
      * CASO O ESTADO NASCE VAZIO.                                     *
      *----------------------------------------------------------------*
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
      *
      *================================================================*
      * 2000 - TRATAMENTO DA TECLA ACIONADA                            *
      *================================================================*
       2000-PROCESSAR-TECLA SECTION.
       2000-INICIO.
           EVALUATE EIBAID
               WHEN DFHPF3
                    PERFORM 5900-ENCERRAR-TRANSACAO
               WHEN DFHPF12
                    PERFORM 1000-PRIMEIRA-VEZ
               WHEN DFHPF4
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4900-CHAMAR-LOOKUP
               WHEN DFHPF5
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 3100-CONSULTAR
               WHEN DFHPF6
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 4000-GRAVAR
               WHEN DFHENTER
                    PERFORM 3000-RECEBER-MAPA
                    PERFORM 2100-EXECUTAR-ACAO
               WHEN OTHER
                    MOVE 'TECLA INVALIDA PARA ESTA TRANSACAO'
                                       TO MMENSAGO
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2000-FIM.
           EXIT.
      *
       2100-EXECUTAR-ACAO SECTION.
       2100-INICIO.
           EVALUATE WS-ES-ACAO
               WHEN 'C' PERFORM 3100-CONSULTAR
               WHEN 'I' PERFORM 4000-GRAVAR
               WHEN 'A' PERFORM 4000-GRAVAR
               WHEN 'E' PERFORM 4800-EXCLUIR
               WHEN OTHER
                    MOVE 'ACAO INVALIDA. USE C, I, A OU E'
                                       TO MMENSAGO
                    MOVE DFHBMBRY      TO MACAOA
                    PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE.
       2100-FIM.
           EXIT.
      *
      *================================================================*
      * 3000 - RECEPCAO DA TELA                                        *
      *                                                                *
      * CADA CAMPO SO SUBSTITUI O ESTADO SE VOLTOU DIGITADO (MxxxL     *
      * MAIOR QUE ZERO). CODIGO DIFERENTE DO QUE ESTAVA EM EDICAO      *
      * LIMPA O RESTO DO ESTADO: OS DADOS NA TELA SAO DE OUTRO         *
      * ESTABELECIMENTO E NAO PODEM SER GRAVADOS NESTE.                *
      *================================================================*
       3000-RECEBER-MAPA SECTION.
       3000-INICIO.
           EXEC CICS RECEIVE
                MAP(WS-MAPA) MAPSET(WS-MAPSET) INTO(MAPEMPRI)
                RESP(WS-RESP)
           END-EXEC
      *
      *--- ENTER SEM NADA DIGITADO DA MAPFAIL: A AREA DE ENTRADA
      *--- NAO E PREENCHIDA E OS COMPRIMENTOS FICAM COM LIXO ------
           IF WS-RESP = DFHRESP(MAPFAIL)
               MOVE LOW-VALUES         TO MAPEMPRI
           END-IF
      *
           MOVE 'N'                    TO WS-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
      *
           IF MACAOL > ZEROS
               MOVE FUNCTION UPPER-CASE(MACAOI)
                                       TO WS-ES-ACAO
           END-IF
      *
           IF MCODIGOL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCODIGOI           TO WS-ED-CAMPO(1:4)
               MOVE 9999               TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S' AND WS-ED-VALOR > ZEROS
                   MOVE WS-ED-VALOR    TO WS-CODIGO-TELA
                   IF WS-CODIGO-TELA NOT = WS-ES-CODIGO
                       PERFORM 3050-TROCAR-ESTABELEC
                   END-IF
               ELSE
                   MOVE 'RN01 - CODIGO DO ESTABELECIMENTO: 0001 A 9999'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCODIGOA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
      *
           PERFORM 3010-RECEBER-IDENTIFICACAO
           PERFORM 3020-RECEBER-ENDERECO
           PERFORM 3030-RECEBER-ENCARGOS
           PERFORM 3040-RECEBER-PAGAMENTO
           PERFORM 3080-CRITICAR-RECEBIMENTO.
       3000-FIM.
           EXIT.
      *
       3010-RECEBER-IDENTIFICACAO SECTION.
       3010-INICIO.
           IF MTIPOL > ZEROS
               MOVE FUNCTION UPPER-CASE(MTIPOI)
                                       TO WS-ES-TIPO
           END-IF
           IF MCNPJL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCNPJI             TO WS-ED-CAMPO(1:14)
               MOVE 99999999999999     TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CNPJ
               ELSE
                   MOVE 'RN03 - CNPJ INVALIDO - USE 14 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCNPJA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MIEL > ZEROS
               MOVE FUNCTION UPPER-CASE(MIEI)
                                       TO WS-ES-IE
           END-IF
           IF MRAZAOL > ZEROS
               MOVE FUNCTION UPPER-CASE(MRAZAOI)
                                       TO WS-ES-RAZAO
           END-IF
           IF MFANTASL > ZEROS
               MOVE FUNCTION UPPER-CASE(MFANTASI)
                                       TO WS-ES-FANTAS
           END-IF
           .
       3010-FIM.
           EXIT.
      *
       3020-RECEBER-ENDERECO SECTION.
       3020-INICIO.
           IF MTIPLOGL > ZEROS
               MOVE FUNCTION UPPER-CASE(MTIPLOGI)
                                       TO WS-ES-TIPLOG
           END-IF
           IF MLOGRADL > ZEROS
               MOVE FUNCTION UPPER-CASE(MLOGRADI)
                                       TO WS-ES-LOGRAD
           END-IF
           IF MNUMEROL > ZEROS
               MOVE FUNCTION UPPER-CASE(MNUMEROI)
                                       TO WS-ES-NUMERO
           END-IF
           IF MCOMPLL > ZEROS
               MOVE FUNCTION UPPER-CASE(MCOMPLI)
                                       TO WS-ES-COMPL
           END-IF
           IF MBAIRROL > ZEROS
               MOVE FUNCTION UPPER-CASE(MBAIRROI)
                                       TO WS-ES-BAIRRO
           END-IF
           IF MMUNICL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MMUNICI            TO WS-ED-CAMPO(1:7)
               MOVE 9999999            TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-MUNIC
               ELSE
                   MOVE 'RN07 - MUNICIPIO INVALIDO - 7 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MMUNICA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MUFL > ZEROS
               MOVE FUNCTION UPPER-CASE(MUFI)
                                       TO WS-ES-UF
           END-IF
           IF MCEPL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCEPI              TO WS-ED-CAMPO(1:8)
               MOVE 99999999           TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CEP
               ELSE
                   MOVE 'RN09 - CEP INVALIDO - USE 8 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCEPA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MTELEFL > ZEROS
               MOVE FUNCTION UPPER-CASE(MTELEFI)
                                       TO WS-ES-TELEF
           END-IF
           .
       3020-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3030 - ENCARGOS                                                *
      *                                                                *
      * RAT, FAP E TERCEIROS CHEGAM COMO TEXTO E VOLTAM DO 7400 EM     *
      * WS-ED-VALOR, QUE TEM QUATRO CASAS PARA COMPORTAR O FAP.        *
      *----------------------------------------------------------------*
       3030-RECEBER-ENCARGOS SECTION.
       3030-INICIO.
           IF MCNAEL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCNAEI             TO WS-ED-CAMPO(1:7)
               MOVE 9999999            TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CNAE
               ELSE
                   MOVE 'RN10 - CNAE INVALIDO - 7 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCNAEA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MFPASL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MFPASI             TO WS-ED-CAMPO(1:3)
               MOVE 999                TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-FPAS
               ELSE
                   MOVE 'RN10 - FPAS INVALIDO - ATE 3 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MFPASA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MCODTERL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCODTERI           TO WS-ED-CAMPO(1:4)
               MOVE 9999               TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CODTER
               ELSE
                   MOVE 'RN13 - COD. TERCEIROS: ATE 4 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCODTERA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MALIRATL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MALIRATI           TO WS-ED-CAMPO(1:5)
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-VALOR <= 99,99
                   MOVE WS-ED-VALOR    TO WS-ES-ALIRAT
               ELSE
                   MOVE 'RN11 - RAT: USE 1,00, 2,00 OU 3,00'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MALIRATA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MFAPL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MFAPI              TO WS-ED-CAMPO(1:6)
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-VALOR <= 9,9999
                   MOVE WS-ED-VALOR    TO WS-ES-FAP
               ELSE
                   MOVE 'RN12 - FAP INVALIDO - USE DE 0,5000 A 2,0000'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MFAPA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MALITERL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MALITERI           TO WS-ED-CAMPO(1:5)
               PERFORM 7400-DE-EDITAR
               IF WS-ED-OK = 'S' AND WS-ED-VALOR <= 99,99
                   MOVE WS-ED-VALOR    TO WS-ES-ALITER
               ELSE
                   MOVE 'ALIQUOTA DE TERCEIROS INVALIDA - USE ATE 99,99'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MALITERA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MSIMPLEL > ZEROS
               MOVE FUNCTION UPPER-CASE(MSIMPLEI)
                                       TO WS-ES-SIMPLE
           END-IF
           IF MDESONEL > ZEROS
               MOVE FUNCTION UPPER-CASE(MDESONEI)
                                       TO WS-ES-DESONE
           END-IF
           .
       3030-FIM.
           EXIT.
      *
       3040-RECEBER-PAGAMENTO SECTION.
       3040-INICIO.
           IF MSINDICL > ZEROS
               MOVE FUNCTION UPPER-CASE(MSINDICI)
                                       TO WS-ES-SINDIC
           END-IF
           IF MDTBASEL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MDTBASEI           TO WS-ED-CAMPO(1:2)
               MOVE 99                 TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-DTBASE
               ELSE
                   MOVE 'RN15 - MES DA DATA-BASE INVALIDO - USE 01 A 12'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MDTBASEA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MBANCOL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MBANCOI            TO WS-ED-CAMPO(1:3)
               MOVE 999                TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-BANCO
               ELSE
                   MOVE 'RN17 - BANCO PAGADOR INVALIDO - ATE 3 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MBANCOA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MAGENCIL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MAGENCII           TO WS-ED-CAMPO(1:5)
               MOVE 99999              TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-AGENCI
               ELSE
                   MOVE 'RN17 - AGENCIA INVALIDA - ATE 5 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MAGENCIA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MCONTAL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MCONTAI            TO WS-ED-CAMPO(1:12)
               MOVE 999999999999       TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-CONTA
               ELSE
                   MOVE 'RN17 - CONTA PAGADORA: ATE 12 DIGITOS'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MCONTAA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MDIAPAGL > ZEROS
               MOVE SPACES             TO WS-ED-CAMPO
               MOVE MDIAPAGI           TO WS-ED-CAMPO(1:2)
               MOVE 99                 TO WS-ED-LIMITE
               PERFORM 3060-INTEIRO-DA-TELA
               IF WS-INT-OK = 'S'
                   MOVE WS-ED-VALOR    TO WS-ES-DIAPAG
               ELSE
                   MOVE 'RN16 - DIA DE PAGAMENTO INVALIDO - USE 01 A 31'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MDIAPAGA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
           IF MCONVENL > ZEROS
               MOVE FUNCTION UPPER-CASE(MCONVENI)
                                       TO WS-ES-CONVEN
           END-IF
           IF MSITUACL > ZEROS
               MOVE FUNCTION UPPER-CASE(MSITUACI)
                                       TO WS-ES-SITUAC
           END-IF
           .
       3040-FIM.
           EXIT.
      *
       3050-TROCAR-ESTABELEC SECTION.
       3050-INICIO.
           MOVE WS-ES-ACAO             TO WS-ACAO-SALVA
           INITIALIZE WS-ESTADO
           MOVE WS-ACAO-SALVA          TO WS-ES-ACAO
           MOVE WS-CODIGO-TELA         TO WS-ES-CODIGO
           MOVE SPACES                 TO MDESMUNO
           .
       3050-FIM.
           EXIT.
      *
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
       3080-CRITICAR-RECEBIMENTO SECTION.
       3080-INICIO.
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF.
       3080-FIM.
           EXIT.
      *
      *================================================================*
      * 3100 - CONSULTA DO ESTABELECIMENTO                             *
      *================================================================*
       3100-CONSULTAR SECTION.
       3100-INICIO.
           IF WS-ES-CODIGO = ZEROS
               MOVE 'RN01 - CODIGO DO ESTABELECIMENTO OBRIGATORIO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-ES-CODIGO           TO EST-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NOTFND)
               PERFORM 6000-LIMPAR-MAPA
               MOVE WS-ES-ACAO         TO MACAOO
               MOVE WS-ES-CODIGO       TO MCODIGOO
               MOVE 'RN20 - ESTABELECIMENTO NAO CADASTRADO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE LEITURA NO SFPEST - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 3150-ARQUIVO-PARA-ESTADO
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
      *
           IF WS-ES-CODIGO = 0001
               MOVE 'MATRIZ EXIBIDA. ALTERE E TECLE F6 PARA GRAVAR'
                                       TO MMENSAGO
           ELSE
               MOVE 'FILIAL EXIBIDA. ALTERE E TECLE F6 PARA GRAVAR'
                                       TO MMENSAGO
           END-IF
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       3100-FIM.
           EXIT.
      *
       3150-ARQUIVO-PARA-ESTADO SECTION.
       3150-INICIO.
           MOVE EST-CODIGO             TO WS-ES-CODIGO
           MOVE EST-TIPO               TO WS-ES-TIPO
           MOVE EST-CNPJ               TO WS-ES-CNPJ
           MOVE EST-INSC-ESTADUAL      TO WS-ES-IE
           MOVE EST-RAZAO-SOCIAL       TO WS-ES-RAZAO
           MOVE EST-NOME-FANTASIA      TO WS-ES-FANTAS
           MOVE EST-TIPO-LOGRADOURO    TO WS-ES-TIPLOG
           MOVE EST-LOGRADOURO         TO WS-ES-LOGRAD
           MOVE EST-NUMERO             TO WS-ES-NUMERO
           MOVE EST-COMPLEMENTO        TO WS-ES-COMPL
           MOVE EST-BAIRRO             TO WS-ES-BAIRRO
           MOVE EST-COD-MUNICIPIO      TO WS-ES-MUNIC
           MOVE EST-UF                 TO WS-ES-UF
           MOVE EST-CEP                TO WS-ES-CEP
           MOVE EST-TELEFONE           TO WS-ES-TELEF
           MOVE EST-CNAE               TO WS-ES-CNAE
           MOVE EST-COD-FPAS           TO WS-ES-FPAS
           MOVE EST-COD-TERCEIROS      TO WS-ES-CODTER
           MOVE EST-ALIQ-RAT           TO WS-ES-ALIRAT
           MOVE EST-FAP                TO WS-ES-FAP
           MOVE EST-ALIQ-TERCEIROS     TO WS-ES-ALITER
           MOVE EST-IND-SIMPLES        TO WS-ES-SIMPLE
           MOVE EST-IND-DESONERACAO    TO WS-ES-DESONE
           MOVE EST-NOME-SINDICATO     TO WS-ES-SINDIC
           MOVE EST-MES-DATA-BASE      TO WS-ES-DTBASE
           MOVE EST-BANCO-PAGADOR      TO WS-ES-BANCO
           MOVE EST-AGENCIA-PAGADORA   TO WS-ES-AGENCI
           MOVE EST-CONTA-PAGADORA     TO WS-ES-CONTA
           MOVE EST-DIA-PAGAMENTO      TO WS-ES-DIAPAG
           MOVE EST-COD-CONVENIO       TO WS-ES-CONVEN
           MOVE EST-SITUACAO           TO WS-ES-SITUAC
           MOVE 'S'                    TO WS-ES-LIDA.
       3150-FIM.
           EXIT.
      *
       3200-MOVER-PARA-TELA SECTION.
       3200-INICIO.
           MOVE WS-ES-ACAO             TO MACAOO
           MOVE WS-ES-CODIGO           TO MCODIGOO
           MOVE WS-ES-TIPO             TO MTIPOO
           MOVE WS-ES-CNPJ             TO MCNPJO
           MOVE WS-ES-IE               TO MIEO
           MOVE WS-ES-RAZAO            TO MRAZAOO
           MOVE WS-ES-FANTAS           TO MFANTASO
           MOVE WS-ES-TIPLOG           TO MTIPLOGO
           MOVE WS-ES-LOGRAD           TO MLOGRADO
           MOVE WS-ES-NUMERO           TO MNUMEROO
           MOVE WS-ES-COMPL            TO MCOMPLO
           MOVE WS-ES-BAIRRO           TO MBAIRROO
           MOVE WS-ES-MUNIC            TO MMUNICO
           MOVE WS-ES-UF               TO MUFO
           MOVE WS-ES-CEP              TO MCEPO
           MOVE WS-ES-TELEF            TO MTELEFO
           MOVE WS-ES-CNAE             TO MCNAEO
           MOVE WS-ES-FPAS             TO MFPASO
           MOVE WS-ES-CODTER           TO MCODTERO
           MOVE WS-ES-SIMPLE           TO MSIMPLEO
           MOVE WS-ES-DESONE           TO MDESONEO
           MOVE WS-ES-SINDIC           TO MSINDICO
           MOVE WS-ES-DTBASE           TO MDTBASEO
           MOVE WS-ES-BANCO            TO MBANCOO
           MOVE WS-ES-AGENCI           TO MAGENCIO
           MOVE WS-ES-CONTA            TO MCONTAO
           MOVE WS-ES-DIAPAG           TO MDIAPAGO
           MOVE WS-ES-CONVEN           TO MCONVENO
           MOVE WS-ES-SITUAC           TO MSITUACO
           PERFORM 3250-MOVER-ALIQUOTAS
           MOVE -1                     TO MCODIGOL.
       3200-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 3250 - ALIQUOTAS NA TELA                                       *
      *                                                                *
      * OS CAMPOS DO MAPA SAO ALFANUMERICOS, ENTAO A EDICAO PASSA POR  *
      * ITENS NUMERICO-EDITADOS DA WORKING-STORAGE.                    *
      *----------------------------------------------------------------*
       3250-MOVER-ALIQUOTAS SECTION.
       3250-INICIO.
           MOVE WS-ES-ALIRAT           TO WS-SA-RAT
           MOVE WS-ES-FAP              TO WS-SA-FAP
           MOVE WS-ES-ALITER           TO WS-SA-TER
      *
           MOVE WS-SA-RAT              TO MALIRATO
           MOVE WS-SA-FAP              TO MFAPO
           MOVE WS-SA-TER              TO MALITERO
           .
       3250-FIM.
           EXIT.
      *
       3300-DESCREVER-CODIGOS SECTION.
       3300-INICIO.
           IF WS-ES-MUNIC NOT = ZEROS
               PERFORM 3370-LER-MUNICIPIO
               MOVE WS-MUN-NOME(1:30)  TO MDESMUNO
           END-IF.
       3300-FIM.
           EXIT.
      *
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
           MOVE WS-ES-UF               TO UFE-SIGLA
           EXEC CICS READ
                FILE(WS-ARQ-UF) INTO(REG-UF)
                RIDFLD(UFE-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL) AND UFE-SITUACAO = 'A'
               MOVE 'S'                TO WS-UF-OK
           END-IF.
       3360-FIM.
           EXIT.
      *
       3370-LER-MUNICIPIO SECTION.
       3370-INICIO.
           MOVE 'N'                    TO WS-MUN-OK
           MOVE SPACES                 TO WS-MUN-NOME
                                          WS-MUN-UF
           MOVE WS-ES-MUNIC            TO MUN-COD-IBGE
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
      *================================================================*
      * 4000 - GRAVACAO (F6)                                           *
      *                                                                *
      * AS CRITICAS SAO EVALUATE TRUE PARA QUE APENAS A PRIMEIRA       *
      * PENDENCIA APARECA, JA QUE A TELA TEM UMA UNICA LINHA DE        *
      * MENSAGEM.                                                      *
      *================================================================*
       4000-GRAVAR SECTION.
       4000-INICIO.
           MOVE 'N'                    TO WS-ERRO
           MOVE SPACES                 TO WS-MENSAGEM
      *
           PERFORM 4100-VALIDAR-IDENTIFICACAO
           IF NOT TEM-ERRO
               PERFORM 4200-VALIDAR-ENDERECO
           END-IF
           IF NOT TEM-ERRO
               PERFORM 4300-VALIDAR-ENCARGOS
           END-IF
           IF NOT TEM-ERRO
               PERFORM 4400-VALIDAR-PAGAMENTO
           END-IF
      *
           IF TEM-ERRO
               MOVE WS-MENSAGEM        TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           EVALUATE WS-ES-ACAO
           WHEN 'I'
               PERFORM 4600-INCLUIR
           WHEN 'A'
               PERFORM 4700-ALTERAR
           END-EVALUATE.
       4000-FIM.
           EXIT.
      *
       4100-VALIDAR-IDENTIFICACAO SECTION.
       4100-INICIO.
           EVALUATE TRUE
           WHEN WS-ES-CODIGO = ZEROS
               MOVE 'RN01 - CODIGO DO ESTABELECIMENTO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCODIGOA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CODIGO = 0001 AND WS-ES-TIPO NOT = 'M'
               MOVE 'RN02 - CODIGO 0001 E A MATRIZ - TIPO M'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MTIPOA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CODIGO NOT = 0001 AND WS-ES-TIPO NOT = 'F'
               MOVE 'RN02 - CODIGO ACIMA DE 0001 E FILIAL - TIPO F'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MTIPOA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CNPJ = ZEROS
               MOVE 'RN03 - CNPJ OBRIGATORIO - DIGITE OS 14 DIGITOS'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCNPJA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-RAZAO = SPACES
               MOVE 'RN04 - RAZAO SOCIAL OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MRAZAOA
               SET TEM-ERRO            TO TRUE
           END-EVALUATE
      *
      *--- RN05: SEM NOME FANTASIA, VALE A RAZAO SOCIAL -------------
           IF WS-ES-FANTAS = SPACES
               MOVE WS-ES-RAZAO(1:40)  TO WS-ES-FANTAS
           END-IF.
       4100-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4200 - ENDERECO                                                *
      *                                                                *
      * A UF E CRITICADA ANTES DO MUNICIPIO PORQUE O MUNICIPIO E       *
      * CONFERIDO CONTRA ELA (RN07).                                   *
      *----------------------------------------------------------------*
       4200-VALIDAR-ENDERECO SECTION.
       4200-INICIO.
           IF WS-ES-NUMERO = SPACES
               MOVE 'S/N'
                                       TO WS-ES-NUMERO
           END-IF
      *
           EVALUATE TRUE
           WHEN WS-ES-TIPLOG = SPACES
               MOVE 'RN05 - TIPO DE LOGRADOURO OBRIGATORIO - F4 LISTA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MTIPLOGA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-LOGRAD = SPACES
               MOVE 'RN06 - LOGRADOURO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MLOGRADA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-BAIRRO = SPACES
               MOVE 'RN06 - BAIRRO OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MBAIRROA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-UF = SPACES
               MOVE 'RN08 - UF OBRIGATORIA - F4 LISTA AS UNIDADES'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MUFA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-MUNIC = ZEROS
               MOVE 'RN07 - CODIGO DO MUNICIPIO (IBGE) OBRIGATORIO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MMUNICA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CEP = ZEROS
               MOVE 'RN09 - CEP OBRIGATORIO - 8 DIGITOS'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCEPA
               SET TEM-ERRO            TO TRUE
           END-EVALUATE
      *
           IF NOT TEM-ERRO
               MOVE 'TLG'
                                       TO WS-DOM-TIPO
               MOVE SPACES             TO WS-DOM-CODIGO
               MOVE WS-ES-TIPLOG       TO WS-DOM-CODIGO(1:3)
               PERFORM 3350-LER-DOMINIO
               IF WS-DOM-OK NOT = 'S'
                   MOVE 'RN05 - TIPO DE LOGRADOURO INEXISTENTE'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MTIPLOGA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
      *
           IF NOT TEM-ERRO
               PERFORM 3360-LER-UF
               IF WS-UF-OK NOT = 'S'
                   MOVE 'RN08 - UF INEXISTENTE OU INATIVA - F4 LISTA'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MUFA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF
      *
           IF NOT TEM-ERRO
               PERFORM 3370-LER-MUNICIPIO
               EVALUATE TRUE
               WHEN WS-MUN-OK NOT = 'S'
                       MOVE 'RN07 - MUNICIPIO NAO CADASTRADO NO SFPMUN'
                                       TO WS-MENSAGEM
                       MOVE DFHBMBRY   TO MMUNICA
                       SET TEM-ERRO    TO TRUE
               WHEN WS-MUN-UF NOT = WS-ES-UF
                       MOVE 'RN07 - MUNICIPIO NAO PERTENCE A ESSA UF'
                                       TO WS-MENSAGEM
                       MOVE DFHBMBRY   TO MMUNICA
                       SET TEM-ERRO    TO TRUE
               WHEN OTHER
                       MOVE WS-MUN-NOME(1:30) TO MDESMUNO
               END-EVALUATE
           END-IF.
       4200-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4300 - ENCARGOS                                                *
      *                                                                *
      * RAT E FAP SAO COMPARADOS EM CENTESIMOS E DECIMOS DE MILESIMO   *
      * PARA NAO DEPENDER DE LITERAL DECIMAL NO FONTE.                 *
      * FILIAL PODE DEIXAR FPAS, RAT E FAP EM ZEROS: O SFP0300 HERDA   *
      * DA MATRIZ (RN21). A MATRIZ E OBRIGADA A PREENCHER.             *
      *----------------------------------------------------------------*
       4300-VALIDAR-ENCARGOS SECTION.
       4300-INICIO.
           IF WS-ES-SIMPLE = SPACES
               MOVE 'N'
                                       TO WS-ES-SIMPLE
           END-IF
           IF WS-ES-DESONE = SPACES
               MOVE 'N'
                                       TO WS-ES-DESONE
           END-IF
      *
           EVALUATE TRUE
           WHEN WS-ES-CNAE = ZEROS
               MOVE 'RN10 - CNAE OBRIGATORIO - 7 DIGITOS'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCNAEA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-TIPO = 'M' AND WS-ES-FPAS = ZEROS
               MOVE 'RN10 - FPAS OBRIGATORIO NA MATRIZ'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MFPASA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CODTER NOT = ZEROS
                AND WS-ES-ALITER = ZEROS
               MOVE 'RN13 - COM CODIGO DE TERCEIROS, INFORME A ALIQUOTA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MALITERA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CODTER = ZEROS
                AND WS-ES-ALITER NOT = ZEROS
               MOVE 'RN13 - ALIQUOTA DE TERCEIROS SEM O CODIGO'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCODTERA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-SIMPLE NOT = 'S' AND WS-ES-SIMPLE NOT = 'N'
               MOVE 'RN14 - SIMPLES ACEITA SO S OU N'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MSIMPLEA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-DESONE NOT = 'S' AND WS-ES-DESONE NOT = 'N'
               MOVE 'RN14 - DESONERACAO ACEITA SO S OU N'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MDESONEA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-SIMPLE = 'S' AND WS-ES-DESONE = 'S'
               MOVE 'RN14 - SIMPLES E DESONERACAO NAO CONVIVEM'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MDESONEA
               SET TEM-ERRO            TO TRUE
           END-EVALUATE
      *
           IF NOT TEM-ERRO
               PERFORM 4350-VALIDAR-RAT-FAP
           END-IF.
       4300-FIM.
           EXIT.
      *
       4350-VALIDAR-RAT-FAP SECTION.
       4350-INICIO.
           COMPUTE WS-ED-LIMITE = WS-ES-ALIRAT * 100
           EVALUATE WS-ED-LIMITE
           WHEN 0
           WHEN 100
           WHEN 200
           WHEN 300
               CONTINUE
           WHEN OTHER
               MOVE 'RN11 - ALIQUOTA RAT ACEITA SO 1,00, 2,00 OU 3,00'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MALIRATA
               SET TEM-ERRO            TO TRUE
           END-EVALUATE
      *
           IF WS-ES-TIPO = 'M' AND WS-ES-ALIRAT = ZEROS
               MOVE 'RN11 - ALIQUOTA RAT OBRIGATORIA NA MATRIZ'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MALIRATA
               SET TEM-ERRO            TO TRUE
           END-IF
      *
           COMPUTE WS-ED-LIMITE = WS-ES-FAP * 10000
           IF WS-ED-LIMITE NOT = ZEROS
              AND (WS-ED-LIMITE < 5000 OR WS-ED-LIMITE > 20000)
               MOVE 'RN12 - FAP FORA DA FAIXA LEGAL DE 0,5000 A 2,0000'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MFAPA
               SET TEM-ERRO            TO TRUE
           END-IF
      *
           IF WS-ES-TIPO = 'M' AND WS-ES-FAP = ZEROS
               MOVE 'RN12 - FAP OBRIGATORIO NA MATRIZ'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MFAPA
               SET TEM-ERRO            TO TRUE
           END-IF.
       4350-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4400 - SINDICATO, PAGAMENTO E SITUACAO                         *
      *----------------------------------------------------------------*
       4400-VALIDAR-PAGAMENTO SECTION.
       4400-INICIO.
           IF WS-ES-SITUAC = SPACES
               MOVE 'A'
                                       TO WS-ES-SITUAC
           END-IF
      *
           EVALUATE TRUE
           WHEN WS-ES-DTBASE < 01 OR WS-ES-DTBASE > 12
               MOVE 'RN15 - MES DA DATA-BASE TEM DE ESTAR ENTRE 01 E 12'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MDTBASEA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-DIAPAG < 01 OR WS-ES-DIAPAG > 31
               MOVE 'RN16 - DIA DE PAGAMENTO TEM DE ESTAR ENTRE 01 E 31'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MDIAPAGA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-BANCO = ZEROS
               MOVE 'RN17 - BANCO PAGADOR OBRIGATORIO - F4 LISTA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MBANCOA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-AGENCI = ZEROS
               MOVE 'RN17 - AGENCIA PAGADORA OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MAGENCIA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CONTA = ZEROS
               MOVE 'RN17 - CONTA PAGADORA OBRIGATORIA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCONTAA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-TIPO = 'M' AND WS-ES-CONVEN = SPACES
               MOVE 'RN17 - CONVENIO OBRIGATORIO NA MATRIZ'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MCONVENA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-SITUAC NOT = 'A' AND WS-ES-SITUAC NOT = 'I'
               MOVE 'RN18 - SITUACAO ACEITA SO A OU I'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MSITUACA
               SET TEM-ERRO            TO TRUE
           WHEN WS-ES-CODIGO = 0001 AND WS-ES-SITUAC = 'I'
               MOVE 'RN18 - A MATRIZ 0001 NAO PODE SER INATIVADA'
                                       TO WS-MENSAGEM
               MOVE DFHBMBRY           TO MSITUACA
               SET TEM-ERRO            TO TRUE
           END-EVALUATE
      *
           IF NOT TEM-ERRO
               MOVE 'BAN'
                                       TO WS-DOM-TIPO
               MOVE SPACES             TO WS-DOM-CODIGO
               MOVE WS-ES-BANCO        TO WS-DOM-CODIGO(1:3)
               PERFORM 3350-LER-DOMINIO
               IF WS-DOM-OK NOT = 'S'
                   MOVE 'RN17 - BANCO INEXISTENTE - F4 LISTA'
                                       TO WS-MENSAGEM
                   MOVE DFHBMBRY       TO MBANCOA
                   SET TEM-ERRO        TO TRUE
               END-IF
           END-IF.
       4400-FIM.
           EXIT.
      *
      *================================================================*
      * 4500 - MONTAGEM DO REGISTRO                                    *
      *                                                                *
      * ESTA SECAO NAO DA INITIALIZE: NA ALTERACAO ELA ESCREVE SOBRE A *
      * IMAGEM VINDA DO READ UPDATE E PRESERVA OS SETE CAMPOS DO       *
      * SFPWEST QUE NAO TEM CAMPO NO SFPM04 (INSCRICAO MUNICIPAL,      *
      * E-MAIL, CNPJ E PERCENTUAL DO SINDICATO, DIA DO ADIANTAMENTO,   *
      * DIGITO DA CONTA E DATA DE INICIO DE ATIVIDADE). QUEM ZERA E O  *
      * 4600, ANTES DE CHAMAR AQUI.                                    *
      *================================================================*
       4500-MONTAR-REGISTRO SECTION.
       4500-INICIO.
           MOVE WS-ES-CODIGO           TO EST-CODIGO
           MOVE WS-ES-TIPO             TO EST-TIPO
           MOVE WS-ES-CNPJ             TO EST-CNPJ
           MOVE WS-ES-RAZAO            TO EST-RAZAO-SOCIAL
           MOVE WS-ES-FANTAS           TO EST-NOME-FANTASIA
           MOVE WS-ES-IE               TO EST-INSC-ESTADUAL
           MOVE WS-ES-TIPLOG           TO EST-TIPO-LOGRADOURO
           MOVE WS-ES-LOGRAD           TO EST-LOGRADOURO
           MOVE WS-ES-NUMERO           TO EST-NUMERO
           MOVE WS-ES-COMPL            TO EST-COMPLEMENTO
           MOVE WS-ES-BAIRRO           TO EST-BAIRRO
           MOVE WS-ES-MUNIC            TO EST-COD-MUNICIPIO
           MOVE WS-ES-UF               TO EST-UF
           MOVE WS-ES-CEP              TO EST-CEP
           MOVE WS-ES-TELEF            TO EST-TELEFONE
           MOVE WS-ES-CNAE             TO EST-CNAE
           MOVE WS-ES-FPAS             TO EST-COD-FPAS
           MOVE WS-ES-CODTER           TO EST-COD-TERCEIROS
           MOVE WS-ES-ALIRAT           TO EST-ALIQ-RAT
           MOVE WS-ES-FAP              TO EST-FAP
           MOVE WS-ES-ALITER           TO EST-ALIQ-TERCEIROS
           MOVE WS-ES-SIMPLE           TO EST-IND-SIMPLES
           MOVE WS-ES-DESONE           TO EST-IND-DESONERACAO
           MOVE WS-ES-SINDIC           TO EST-NOME-SINDICATO
           MOVE WS-ES-DTBASE           TO EST-MES-DATA-BASE
           MOVE WS-ES-BANCO            TO EST-BANCO-PAGADOR
           MOVE WS-ES-AGENCI           TO EST-AGENCIA-PAGADORA
           MOVE WS-ES-CONTA            TO EST-CONTA-PAGADORA
           MOVE WS-ES-DIAPAG           TO EST-DIA-PAGAMENTO
           MOVE WS-ES-CONVEN           TO EST-COD-CONVENIO
           MOVE WS-ES-SITUAC           TO EST-SITUACAO
           .
       4500-FIM.
           EXIT.
      *
       4550-CHECAR-MATRIZ SECTION.
       4550-INICIO.
           MOVE 'N'                    TO WS-MATRIZ-EXISTE
           MOVE 0001                   TO EST-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NORMAL)
               MOVE 'S'                TO WS-MATRIZ-EXISTE
           END-IF.
       4550-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4600 - INCLUSAO                                                *
      *----------------------------------------------------------------*
       4600-INCLUIR SECTION.
       4600-INICIO.
           IF WS-ES-TIPO = 'F'
               PERFORM 4550-CHECAR-MATRIZ
               IF WS-MATRIZ-EXISTE NOT = 'S'
                   MOVE 'RN21 - CADASTRE A MATRIZ 0001 PRIMEIRO'
                                       TO MMENSAGO
                   MOVE DFHBMBRY       TO MCODIGOA
                   PERFORM 6200-ENVIAR-MAPA-DATAONLY
               END-IF
           END-IF
      *
           INITIALIZE REG-ESTABELEC
           PERFORM 4500-MONTAR-REGISTRO
      *
      *--- DEFAULTS DOS CAMPOS QUE A TELA NAO OFERECE ---------------
           MOVE 20                     TO EST-DIA-ADIANTAMENTO
      *
           EXEC CICS WRITE
                FILE(WS-ARQUIVO) FROM(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(DUPREC)
               MOVE 'RN19 - JA CADASTRADO - USE A ACAO A'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE GRAVACAO NO SFPEST - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE 'A'                    TO WS-ES-ACAO
           MOVE 'S'                    TO WS-ES-LIDA
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
           PERFORM 4750-MENSAGEM-GRAVACAO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       4600-FIM.
           EXIT.
      *
       4700-ALTERAR SECTION.
       4700-INICIO.
           MOVE WS-ES-CODIGO           TO EST-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NOTFND)
               MOVE 'RN20 - NAO CADASTRADO - USE A ACAO I'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE LEITURA PARA ALTERACAO - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 4500-MONTAR-REGISTRO
      *
           EXEC CICS REWRITE
                FILE(WS-ARQUIVO) FROM(REG-ESTABELEC)
                RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE REGRAVACAO NO SFPEST - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           PERFORM 6000-LIMPAR-MAPA
           PERFORM 3200-MOVER-PARA-TELA
           PERFORM 3300-DESCREVER-CODIGOS
           PERFORM 4750-MENSAGEM-GRAVACAO
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       4700-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4750 - MENSAGEM DE SUCESSO                                     *
      *                                                                *
      * FILIAL COM FPAS, RAT E FAP EM ZEROS NAO E ERRO, MAS O USUARIO  *
      * TEM DE SABER QUE O CALCULO VAI BUSCAR ESSES PARAMETROS NA      *
      * MATRIZ (RN21).                                                 *
      *----------------------------------------------------------------*
       4750-MENSAGEM-GRAVACAO SECTION.
       4750-INICIO.
           IF WS-ES-TIPO = 'F' AND WS-ES-FPAS = ZEROS
              AND WS-ES-ALIRAT = ZEROS AND WS-ES-FAP = ZEROS
               MOVE 'GRAVADO. FPAS, RAT E FAP VIRAO DA MATRIZ'
                                       TO MMENSAGO
           ELSE
               MOVE 'ESTABELECIMENTO GRAVADO COM SUCESSO'
                                       TO MMENSAGO
           END-IF.
       4750-FIM.
           EXIT.
      *
      *----------------------------------------------------------------*
      * 4800 - EXCLUSAO                                                *
      *                                                                *
      * A MATRIZ 0001 NAO PODE SER EXCLUIDA (RN18): O CABECALHO DOS    *
      * RELATORIOS, O HEADER DO CNAB240 E A HERANCA DE PARAMETROS      *
      * DEPENDEM DELA.                                                 *
      *----------------------------------------------------------------*
       4800-EXCLUIR SECTION.
       4800-INICIO.
           IF NOT WS-ES-VEIO-DO-ARQUIVO
               MOVE 'RN22 - CONSULTE (ACAO C) ANTES DE EXCLUIR'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MACAOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-ES-CODIGO = 0001
               MOVE 'RN18 - A MATRIZ 0001 NAO PODE SER EXCLUIDA'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           MOVE WS-ES-CODIGO           TO EST-CODIGO
           EXEC CICS READ
                FILE(WS-ARQUIVO) INTO(REG-ESTABELEC)
                RIDFLD(EST-CHAVE) UPDATE RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP = DFHRESP(NOTFND)
               MOVE 'RN20 - ESTABELECIMENTO NAO CADASTRADO'
                                       TO MMENSAGO
               MOVE DFHBMBRY           TO MCODIGOA
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE LEITURA PARA EXCLUSAO - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           EXEC CICS DELETE
                FILE(WS-ARQUIVO) RESP(WS-RESP)
           END-EXEC
      *
           IF WS-RESP NOT = DFHRESP(NORMAL)
               MOVE 'ERRO DE EXCLUSAO NO SFPEST - ACIONE O SUPORTE'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-IF
      *
           INITIALIZE WS-ESTADO
           PERFORM 6000-LIMPAR-MAPA
           MOVE 'ESTABELECIMENTO EXCLUIDO. INFORME OUTRO CODIGO'
                                       TO MMENSAGO
           MOVE -1                     TO MACAOL
           PERFORM 6100-ENVIAR-MAPA-ERASE.
       4800-FIM.
           EXIT.
      *
      *================================================================*
      * 4900 - JANELA DE CONSULTA (F4)                                 *
      *                                                                *
      * A LINHA DO CURSOR DIZ QUAL LISTA ABRIR. O ESTADO VAI PARA A    *
      * FILA TS ANTES DO XCTL, PORQUE O XCTL NAO PASSA PELO 8000.      *
      * A LINHA 10 ABRIGA DOIS CAMPOS COM F4: MUNICIPIO (COLUNA 16) E  *
      * UF (COLUNA 62). A COLUNA DO CURSOR SEPARA OS DOIS.             *
      *================================================================*
       4900-CHAMAR-LOOKUP SECTION.
       4900-INICIO.
           COMPUTE WS-LINHA-CURSOR = EIBCPOSN / 80 + 1
           COMPUTE WS-COL-CURSOR = FUNCTION MOD(EIBCPOSN, 80) + 1
      *
           INITIALIZE AREA-LOOKUP
           EVALUATE WS-LINHA-CURSOR
           WHEN 8
               MOVE 'TLG'
                                       TO LOK-TIPO-DOMINIO
               MOVE 'MTIPLOG'
                                       TO LOK-CAMPO-ORIGEM
           WHEN 10
      *--- A LINHA 10 TEM MUNICIPIO NA COLUNA 16 E UF NA COLUNA 62 -----
               IF WS-COL-CURSOR < 40
                   MOVE 'MUN'
                                       TO LOK-TIPO-DOMINIO
                   MOVE 'MMUNIC'
                                       TO LOK-CAMPO-ORIGEM
                   MOVE WS-ES-UF       TO LOK-UF-FILTRO
               ELSE
                   MOVE 'UFE'
                                       TO LOK-TIPO-DOMINIO
                   MOVE 'MUF'
                                       TO LOK-CAMPO-ORIGEM
               END-IF
           WHEN 18
               MOVE 'BAN'
                                       TO LOK-TIPO-DOMINIO
               MOVE 'MBANCO'
                                       TO LOK-CAMPO-ORIGEM
           WHEN OTHER
               MOVE 'F4 ATENDE LOGRADOURO, MUNICIPIO, UF E BANCO'
                                       TO MMENSAGO
               PERFORM 6200-ENVIAR-MAPA-DATAONLY
           END-EVALUATE
      *
           MOVE WS-PROGRAMA            TO LOK-PGM-CHAMADOR
           MOVE 1                      TO LOK-PAGINA
           SET LOK-EM-CURSO            TO TRUE
      *
           MOVE AREA-LOOKUP            TO COM-AREA-TRABALHO
                                          (1:LENGTH OF AREA-LOOKUP)
           PERFORM 1300-GRAVAR-ESTADO
      *
           EXEC CICS XCTL PROGRAM('SFP0900')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       4900-FIM.
           EXIT.
      *
       5900-ENCERRAR-TRANSACAO SECTION.
       5900-INICIO.
           PERFORM 1400-APAGAR-ESTADO
      *
           EXEC CICS XCTL PROGRAM('SFP0000')
                COMMAREA(COMMAREA-SFP)
                LENGTH(LENGTH OF COMMAREA-SFP)
           END-EXEC.
       5900-FIM.
           EXIT.
      *
      *================================================================*
      * 6000 - MONTAGEM E ENVIO DA TELA                                *
      *================================================================*
       6000-LIMPAR-MAPA SECTION.
       6000-INICIO.
           MOVE LOW-VALUES             TO MAPEMPRO
           MOVE ZEROS                  TO WS-SA-RAT
                                          WS-SA-FAP
                                          WS-SA-TER.
       6000-FIM.
           EXIT.
      *
       6100-ENVIAR-MAPA-ERASE SECTION.
       6100-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPEMPRO)
                ERASE CURSOR FREEKB
           END-EXEC
           PERFORM 8000-RETORNAR.
       6100-FIM.
           EXIT.
      *
       6200-ENVIAR-MAPA-DATAONLY SECTION.
       6200-INICIO.
           EXEC CICS SEND
                MAP(WS-MAPA) MAPSET(WS-MAPSET) FROM(MAPEMPRO)
                DATAONLY CURSOR FREEKB ALARM
           END-EXEC
           PERFORM 8000-RETORNAR.
       6200-FIM.
           EXIT.
      *
      *================================================================*
      * 7400 - DES-EDICAO DE CAMPO NUMERICO DA TELA                    *
      *                                                                *
      * CAMPO NUMERICO EDITADO VOLTA DO BMS ALINHADO A ESQUERDA E      *
      * COM ESPACOS, ENTAO MOVE DIRETO PARA 9(N)V99 DA VALOR ERRADO.   *
      * AQUI OS DIGITOS SAO COMPACTADOS, A VIRGULA LOCALIZA A PARTE    *
      * DECIMAL E O VALOR E REMONTADO COM ESCALA DE QUATRO CASAS       *
      * PARA COMPORTAR O FAP. QUATORZE DIGITOS INTEIROS PORQUE O       *
      * CNPJ E A CONTA PAGADORA TAMBEM PASSAM POR AQUI.                *
      *================================================================*
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
      *================================================================*
      * 8000 - RETORNO PSEUDOCONVERSACIONAL                            *
      *                                                                *
      * O ESTADO VAI PARA A FILA TS, NAO PARA A COMMAREA: 372 BYTES    *
      * NAO CABEM NOS 326 QUE RESTAM DEPOIS DO SFPWLOK.                *
      *================================================================*
       8000-RETORNAR SECTION.
       8000-INICIO.
           MOVE WS-TRANSACAO           TO COM-TRANSACAO
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
       9999-ABEND SECTION.
       9999-INICIO.
           EXEC CICS SYNCPOINT ROLLBACK END-EXEC
           PERFORM 1400-APAGAR-ESTADO
           EXEC CICS SEND TEXT
                FROM(WS-IDENTIFICACAO)
                LENGTH(LENGTH OF WS-IDENTIFICACAO)
                ERASE FREEKB
           END-EXEC
           EXEC CICS RETURN END-EXEC.
       9999-FIM.
           EXIT.
      *================================================================*
