      *================================================================*
      * COPYBOOK : SFPWEMP  - CADASTRO DE EMPREGADOS                   *
      * SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: EMP-MATRICULA         *
      * LRECL    : 500                                                 *
      *================================================================*
       01  REG-EMPREGADO.
           05  EMP-CHAVE.
               10  EMP-MATRICULA           PIC 9(008).
           05  EMP-NOME                    PIC X(040).
           05  EMP-CPF                     PIC 9(011).
           05  EMP-PIS                     PIC 9(011).
           05  EMP-DT-ADMISSAO             PIC 9(008).
           05  EMP-DT-DEMISSAO             PIC 9(008).
           05  EMP-DT-NASCIMENTO           PIC 9(008).
           05  EMP-SITUACAO                PIC X(001).
               88  EMP-ATIVO                   VALUE 'A'.
               88  EMP-FERIAS                  VALUE 'F'.
               88  EMP-AFASTADO                VALUE 'L'.
               88  EMP-DEMITIDO                VALUE 'D'.
               88  EMP-SIT-VALIDA              VALUE 'A' 'F' 'L' 'D'.
           05  EMP-COD-CARGO               PIC 9(004).
           05  EMP-COD-DEPTO               PIC 9(004).
           05  EMP-CENTRO-CUSTO            PIC 9(006).
           05  EMP-SALARIO-BASE            PIC 9(009)V99.
           05  EMP-TIPO-SALARIO            PIC X(001).
               88  EMP-MENSALISTA              VALUE 'M'.
               88  EMP-HORISTA                 VALUE 'H'.
               88  EMP-DIARISTA                VALUE 'D'.
           05  EMP-CARGA-HOR-MES           PIC 9(003).
           05  EMP-QTD-DEP-IRRF            PIC 9(002).
           05  EMP-QTD-DEP-SALFAM          PIC 9(002).
           05  EMP-PERC-INSALUBRID         PIC 9(002).
           05  EMP-IND-PERICULOSID         PIC X(001).
           05  EMP-IND-VALE-TRANSP         PIC X(001).
           05  EMP-VLR-VALE-TRANSP         PIC 9(007)V99.
           05  EMP-IND-VALE-REFEIC         PIC X(001).
           05  EMP-VLR-VALE-REFEIC         PIC 9(007)V99.
           05  EMP-IND-PLANO-SAUDE         PIC X(001).
           05  EMP-VLR-PLANO-SAUDE         PIC 9(007)V99.
           05  EMP-PERC-PENSAO             PIC 9(003)V99.
           05  EMP-VLR-PENSAO-FIXO         PIC 9(007)V99.
           05  EMP-VLR-CONSIGNADO          PIC 9(007)V99.
           05  EMP-QTD-PARC-CONSIG         PIC 9(003).
           05  EMP-IND-ADIANTAMENTO        PIC X(001).
           05  EMP-PERC-ADIANTAMENTO       PIC 9(003).
           05  EMP-IND-SINDICALIZADO       PIC X(001).
           05  EMP-DADOS-BANCARIOS.
               10  EMP-BANCO               PIC 9(003).
               10  EMP-AGENCIA             PIC 9(005).
               10  EMP-CONTA               PIC 9(012).
               10  EMP-DIG-CONTA           PIC X(001).
               10  EMP-TIPO-CONTA          PIC X(001).
           05  EMP-CATEG-ESOCIAL           PIC 9(003).
      *--- DADOS PESSOAIS (DOMINIOS VALIDADOS PELA TELA SFP0100) ------
           05  EMP-SEXO                    PIC X(001).
               88  EMP-MASCULINO               VALUE 'M'.
               88  EMP-FEMININO                VALUE 'F'.
           05  EMP-GRAU-INSTRUCAO          PIC 9(002).
           05  EMP-ESTADO-CIVIL            PIC X(001).
               88  EMP-SOLTEIRO                VALUE 'S'.
               88  EMP-CASADO                  VALUE 'C'.
               88  EMP-DIVORCIADO              VALUE 'D'.
               88  EMP-VIUVO                   VALUE 'V'.
               88  EMP-UNIAO-ESTAVEL           VALUE 'U'.
           05  EMP-RACA-COR                PIC 9(002).
           05  EMP-NACIONALIDADE           PIC 9(003).
           05  EMP-UF-NASCIMENTO           PIC X(002).
           05  EMP-MUN-NASCIMENTO          PIC 9(007).
           05  EMP-NOME-MAE                PIC X(040).
           05  EMP-IND-DEFICIENCIA         PIC X(001).
           05  EMP-TIPO-DEFICIENCIA        PIC 9(002).
      *--- DOCUMENTOS -------------------------------------------------
           05  EMP-DOCUMENTOS.
               10  EMP-CTPS-NUMERO         PIC 9(008).
               10  EMP-CTPS-SERIE          PIC 9(005).
               10  EMP-CTPS-UF             PIC X(002).
               10  EMP-RG-NUMERO           PIC X(015).
               10  EMP-RG-ORGAO            PIC X(008).
               10  EMP-TITULO-ELEITOR      PIC 9(012).
      *--- ENDERECO RESIDENCIAL ---------------------------------------
           05  EMP-ENDERECO.
               10  EMP-TIPO-LOGRADOURO     PIC X(003).
               10  EMP-LOGRADOURO          PIC X(040).
               10  EMP-NUMERO              PIC X(008).
               10  EMP-COMPLEMENTO         PIC X(015).
               10  EMP-BAIRRO              PIC X(025).
               10  EMP-COD-MUNICIPIO       PIC 9(007).
               10  EMP-UF                  PIC X(002).
               10  EMP-CEP                 PIC 9(008).
      *--- CONTATO ----------------------------------------------------
           05  EMP-TELEFONE                PIC X(014).
      *--- VINCULO E LOTACAO ------------------------------------------
           05  EMP-COD-ESTABELEC           PIC 9(004).
           05  EMP-TIPO-VINCULO            PIC 9(002).
           05  EMP-TIPO-JORNADA            PIC 9(002).
           05  EMP-COD-HORARIO             PIC 9(003).
           05  EMP-MEDIA-VARIAVEIS         PIC 9(009)V99.
           05  EMP-SALDO-FGTS              PIC 9(009)V99.
           05  EMP-FILLER                  PIC X(017).
