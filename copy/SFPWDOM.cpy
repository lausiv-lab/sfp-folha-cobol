      *================================================================*
      * COPYBOOK : SFPWDOM  - TABELA GENERICA DE DOMINIOS              *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: DOM-CHAVE             *
      * LRECL    : 080                                                 *
      *----------------------------------------------------------------*
      * TABELA UNICA QUE ATENDE TODAS AS LISTAS DE SELECAO DO SISTEMA. *
      * CADA DOMINIO E IDENTIFICADO POR DOM-TIPO E SUAS OPCOES SAO OS  *
      * REGISTROS COM AQUELE TIPO. A TELA SFP0160 MANTEM A TABELA E O  *
      * PROGRAMA SFP0900 A EXIBE COMO JANELA DE CONSULTA (TECLA F4).   *
      *----------------------------------------------------------------*
      * TIPOS DE DOMINIO PREVISTOS                                     *
      *   SEX SEXO                    ECI ESTADO CIVIL                 *
      *   INS GRAU DE INSTRUCAO       RAC RACA / COR                   *
      *   NAC NACIONALIDADE           PAR GRAU DE PARENTESCO           *
      *   TCO TIPO DE CONTA BANCARIA  TLG TIPO DE LOGRADOURO           *
      *   CAT CATEGORIA ESOCIAL       MRE MOTIVO DE RESCISAO           *
      *   SIT SITUACAO DO EMPREGADO   TSA TIPO DE SALARIO              *
      *   TLA TIPO DE LANCAMENTO      UNI UNIDADE DA RUBRICA           *
      *   NAT NATUREZA DA RUBRICA     TFO TIPO DE FOLHA                *
      *   VIN TIPO DE VINCULO         JOR TIPO DE JORNADA              *
      *   BAN BANCO                   DEF TIPO DE DEFICIENCIA          *
      *   AFA MOTIVO DE AFASTAMENTO   HOR HORARIO DE TRABALHO          *
      *----------------------------------------------------------------*
      * O TIPO TIP E O META-DOMINIO: SEUS REGISTROS SAO OS PROPRIOS    *
      * TIPOS ACIMA (DOM-CODIGO = TIPO, DOM-DESCRICAO = NOME DA        *
      * TABELA). SERVE A TECLA F4 DO CAMPO TIPO NO SFP0160 E A CRITICA *
      * DO TIPO INFORMADO, SEM TABELA INTERNA EM PROGRAMA. TIP NASCE   *
      * COM DOM-IND-SISTEMA = 'S' EM tools/gerar_dominios.py.          *
      *================================================================*
       01  REG-DOMINIO.
           05  DOM-CHAVE.
               10  DOM-TIPO                PIC X(003).
               10  DOM-CODIGO              PIC X(006).
           05  DOM-DESCRICAO               PIC X(035).
           05  DOM-DESCR-REDUZ             PIC X(012).
           05  DOM-ORDEM                   PIC 9(003).
           05  DOM-VALOR-AUX               PIC X(010).
           05  DOM-SITUACAO                PIC X(001).
               88  DOM-ATIVO                   VALUE 'A'.
               88  DOM-INATIVO                 VALUE 'I'.
           05  DOM-IND-SISTEMA             PIC X(001).
               88  DOM-PROTEGIDO               VALUE 'S'.
           05  DOM-FILLER                  PIC X(009).
