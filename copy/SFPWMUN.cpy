      *================================================================*
      * COPYBOOK : SFPWMUN  - MUNICIPIOS (CODIGO IBGE)                 *
      * ORGANIZ. : INDEXADO (VSAM KSDS) - CHAVE: MUN-COD-IBGE          *
      * ALT.KEY  : MUN-UF-NOME (BROWSE POR UF E NOME NA TELA)          *
      * LRECL    : 080                                                 *
      *================================================================*
       01  REG-MUNICIPIO.
           05  MUN-CHAVE.
               10  MUN-COD-IBGE            PIC 9(007).
           05  MUN-UF-NOME.
               10  MUN-UF                  PIC X(002).
               10  MUN-NOME                PIC X(040).
           05  MUN-COD-SIAFI               PIC 9(004).
           05  MUN-IND-CAPITAL             PIC X(001).
           05  MUN-CEP-INICIAL             PIC 9(008).
           05  MUN-CEP-FINAL               PIC 9(008).
           05  MUN-SITUACAO                PIC X(001).
           05  MUN-FILLER                  PIC X(009).
