      *================================================================*
      * COPYBOOK : SFPWLOK - AREA DE COMUNICACAO DA CONSULTA DE        *
      *            DOMINIOS (PROGRAMA SFP0900, TECLA F4)               *
      *----------------------------------------------------------------*
      * PROTOCOLO DE USO                                               *
      *  1. O PROGRAMA CHAMADOR PREENCHE LOK-TIPO-DOMINIO COM O TIPO   *
      *     DESEJADO (SEX, ECI, CAR, MUN, ...) E LOK-PGM-CHAMADOR.     *
      *  2. FAZ EXEC CICS XCTL PARA SFP0900 PASSANDO ESTA AREA DENTRO  *
      *     DA COMMAREA.                                               *
      *  3. O SFP0900 EXIBE A JANELA E, AO RECEBER A SELECAO, DEVOLVE  *
      *     O CONTROLE AO CHAMADOR COM LOK-COD-SELECIONADO PREENCHIDO  *
      *     E LOK-RETORNO IGUAL A 'S'.                                 *
      *  4. SE O USUARIO CANCELAR COM F3, LOK-RETORNO VOLTA COMO 'C'.  *
      *----------------------------------------------------------------*
      * OS TIPOS CAR, DPT, MUN E EST NAO ESTAO NA TABELA DE DOMINIOS:  *
      * SAO CADASTROS PROPRIOS E O SFP0900 OS LE DE SEUS ARQUIVOS,     *
      * NORMALIZANDO O RESULTADO NO MESMO FORMATO CODIGO/DESCRICAO.    *
      *================================================================*
       01  AREA-LOOKUP.
           05  LOK-TIPO-DOMINIO        PIC X(003).
           05  LOK-PGM-CHAMADOR        PIC X(008).
           05  LOK-CAMPO-ORIGEM        PIC X(018).
           05  LOK-FILTRO              PIC X(020).
           05  LOK-UF-FILTRO           PIC X(002).
           05  LOK-COD-SELECIONADO     PIC X(007).
           05  LOK-DES-SELECIONADA     PIC X(035).
           05  LOK-AUX-SELECIONADO     PIC X(010).
           05  LOK-CHAVE-BROWSE        PIC X(009).
           05  LOK-PAGINA              PIC 9(003).
           05  LOK-RETORNO             PIC X(001).
               88  LOK-SELECIONOU          VALUE 'S'.
               88  LOK-CANCELOU            VALUE 'C'.
               88  LOK-EM-CURSO            VALUE ' '.
