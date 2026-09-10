      *================================================================*
      * COPYBOOK : SFPWCAB - LINHAS PADRAO DE CABECALHO DE RELATORIO   *
      *================================================================*
       01  LINHAS-RELATORIO.
           05  LIN-TRACO                   PIC X(132) VALUE ALL '='.
           05  LIN-TRACO-FINO              PIC X(132) VALUE ALL '-'.
           05  LIN-BRANCO                  PIC X(132) VALUE SPACES.
       01  CAB-01.
           05  FILLER                      PIC X(009) VALUE 'SFP/'.
           05  CAB01-PROGRAMA              PIC X(008).
           05  FILLER                      PIC X(005) VALUE SPACES.
           05  CAB01-EMPRESA               PIC X(040).
           05  FILLER                      PIC X(010) VALUE SPACES.
           05  FILLER                      PIC X(008) VALUE 'EMISSAO:'.
           05  CAB01-DATA                  PIC X(010).
           05  FILLER                      PIC X(002) VALUE SPACES.
           05  CAB01-HORA                  PIC X(008).
           05  FILLER                      PIC X(007) VALUE ' PAGINA'.
           05  CAB01-PAGINA                PIC ZZ.ZZ9.
           05  FILLER                      PIC X(019) VALUE SPACES.
       01  CAB-02.
           05  FILLER                      PIC X(040) VALUE SPACES.
           05  CAB02-TITULO                PIC X(052).
           05  FILLER                      PIC X(040) VALUE SPACES.
       01  CAB-03.
           05  FILLER                      PIC X(040) VALUE SPACES.
           05  FILLER                      PIC X(013)
                                    VALUE 'COMPETENCIA: '.
           05  CAB03-COMPETENCIA           PIC X(007).
           05  FILLER                      PIC X(014)
                                    VALUE '   TIPO FOLHA:'.
           05  CAB03-TIPO-FOLHA            PIC X(020).
           05  FILLER                      PIC X(038) VALUE SPACES.
