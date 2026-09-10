      *================================================================*
      * COPYBOOK : SFPWEST  - EMPRESA E ESTABELECIMENTOS               *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: EST-CODIGO            *
      * LRECL    : 480                                                 *
      *----------------------------------------------------------------*
      * O CODIGO 0001 E SEMPRE A MATRIZ. FILIAIS RECEBEM 0002 EM       *
      * DIANTE E HERDAM DA MATRIZ OS PARAMETROS NAO PREENCHIDOS.       *
      * OS DADOS DESTE CADASTRO ALIMENTAM O CABECALHO DOS RELATORIOS,  *
      * O HEADER DO ARQUIVO CNAB240 E A APURACAO DOS ENCARGOS.         *
      *================================================================*
       01  REG-ESTABELEC.
           05  EST-CHAVE.
               10  EST-CODIGO              PIC 9(004).
           05  EST-TIPO                    PIC X(001).
               88  EST-MATRIZ                  VALUE 'M'.
               88  EST-FILIAL                  VALUE 'F'.
           05  EST-CNPJ                    PIC 9(014).
           05  EST-RAZAO-SOCIAL            PIC X(060).
           05  EST-NOME-FANTASIA           PIC X(040).
           05  EST-INSC-ESTADUAL           PIC X(015).
           05  EST-INSC-MUNICIPAL          PIC X(015).
      *--- ENDERECO ---------------------------------------------------
           05  EST-ENDERECO.
               10  EST-TIPO-LOGRADOURO     PIC X(003).
               10  EST-LOGRADOURO          PIC X(040).
               10  EST-NUMERO              PIC X(008).
               10  EST-COMPLEMENTO         PIC X(015).
               10  EST-BAIRRO              PIC X(025).
               10  EST-COD-MUNICIPIO       PIC 9(007).
               10  EST-UF                  PIC X(002).
               10  EST-CEP                 PIC 9(008).
      *--- CONTATO ----------------------------------------------------
           05  EST-TELEFONE                PIC X(014).
           05  EST-EMAIL                   PIC X(040).
      *--- PARAMETROS PREVIDENCIARIOS E FISCAIS -----------------------
           05  EST-CNAE                    PIC 9(007).
           05  EST-COD-FPAS                PIC 9(003).
           05  EST-COD-TERCEIROS           PIC 9(004).
           05  EST-ALIQ-RAT                PIC 9(002)V99.
           05  EST-FAP                     PIC 9(001)V9999.
           05  EST-ALIQ-TERCEIROS          PIC 9(002)V99.
           05  EST-IND-SIMPLES             PIC X(001).
           05  EST-IND-DESONERACAO         PIC X(001).
      *--- SINDICATO E CONVENCAO COLETIVA -----------------------------
           05  EST-CNPJ-SINDICATO          PIC 9(014).
           05  EST-NOME-SINDICATO          PIC X(040).
           05  EST-MES-DATA-BASE           PIC 9(002).
           05  EST-PERC-CONTR-SIND         PIC 9(003)V99.
      *--- PARAMETROS DE PAGAMENTO ------------------------------------
           05  EST-DIA-PAGAMENTO           PIC 9(002).
           05  EST-DIA-ADIANTAMENTO        PIC 9(002).
           05  EST-BANCO-PAGADOR           PIC 9(003).
           05  EST-AGENCIA-PAGADORA        PIC 9(005).
           05  EST-CONTA-PAGADORA          PIC 9(012).
           05  EST-DIG-CONTA               PIC X(001).
           05  EST-COD-CONVENIO            PIC X(020).
      *--- CONTROLE ---------------------------------------------------
           05  EST-DT-INICIO-ATIV          PIC 9(008).
           05  EST-SITUACAO                PIC X(001).
               88  EST-ATIVO                   VALUE 'A'.
               88  EST-INATIVO                 VALUE 'I'.
           05  EST-FILLER                  PIC X(025).
