# Dicionario de Dados - Sistema SFP

> Documento gerado automaticamente por `tools/gerar_dicionario.py`
> a partir dos copybooks em `copy/`. Nao editar a mao: recompile
> o dicionario apos qualquer alteracao de layout.

> Nota sobre o DD `SFPRSC`: o programa SFP0350 grava nesse DD o
> *detalhe calculado* da rescisao no layout `SFPWFOL` (LRECL 120),
> e nao no layout `SFPWRSC`. O copybook `SFPWRSC` descreve a
> *solicitacao* de rescisao, lida pelo DD `SFPRSCI`.

## Indice dos arquivos

| Copybook | DDNAME | LRECL | Conteudo |
|---|---|---|---|
| `SFPWCAB` | `-` | - | Linhas padrao de cabecalho de relatorio |
| `SFPWCAR` | `SFPCAR` | 120 | Cadastro de cargos |
| `SFPWCOM` | `-` | 512 | COMMAREA das transacoes CICS |
| `SFPWCON` | `-` | - | Constantes corporativas e codigos |
| `SFPWCTB` | `SFPCTB` | 150 | Interface contabil de partidas dobradas |
| `SFPWDEP` | `SFPDEP` | 80 | Dependentes do empregado |
| `SFPWDOM` | `SFPDOM` | 80 | Tabela generica de dominios |
| `SFPWDPT` | `SFPDPT` | 120 | Cadastro de departamentos |
| `SFPWEMP` | `SFPEMP` | 500 | Cadastro de empregados |
| `SFPWEST` | `SFPEST` | 480 | Empresa e estabelecimentos |
| `SFPWEVE` | `SFPEVE` | 80 | Cadastro de eventos / rubricas |
| `SFPWFOL` | `SFPFOL` | 120 | Folha calculada, detalhe por evento |
| `SFPWMOV` | `SFPMOV` | 100 | Movimento mensal lancado |
| `SFPWMUN` | `SFPMUN` | 80 | Municipios (codigo IBGE) |
| `SFPWPON` | `SFPPON` | 80 | Apuracao do ponto |
| `SFPWRES` | `SFPRES` | 250 | Resumo da folha por empregado |
| `SFPWRSC` | `SFPRSCI` | 80 | Solicitacao de rescisao (entrada) |
| `SFPWTAB` | `SFPTAB` | 80 | Tabelas legais e parametros |
| `SFPWTRB` | `-` | - | Area de comunicacao com SFP0310 |
| `SFPWUFE` | `SFPUFE` | 80 | Unidades da federacao |
| `SFPWUTL` | `-` | - | Area de comunicacao com SFPUTIL |

## SFPWCAB - Linhas padrao de cabecalho de relatorio

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `CAB01-PROGRAMA` | `X(008)` | 1 | 8 | 8 |
| 05 | `CAB01-EMPRESA` | `X(040)` | 9 | 48 | 40 |
| 05 | `CAB01-DATA` | `X(010)` | 49 | 58 | 10 |
| 05 | `CAB01-HORA` | `X(008)` | 59 | 66 | 8 |
| 05 | `CAB01-PAGINA` | `ZZ` | 67 | 68 | 2 |
| 05 | `CAB02-TITULO` | `X(052)` | 69 | 120 | 52 |
| 05 | `CAB03-COMPETENCIA` | `X(007)` | 121 | 127 | 7 |
| 05 | `CAB03-TIPO-FOLHA` | `X(020)` | 128 | 147 | 20 |

**Somatorio dos campos: 147 bytes.**

## SFPWCAR - Cadastro de cargos

DDNAME `SFPCAR` - LRECL 120 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `CAR-CHAVE` | `(grupo)` |  |  |  |
| 10 | `CAR-CODIGO` | `9(004)` | 1 | 4 | 4 |
| 05 | `CAR-DESCRICAO` | `X(035)` | 5 | 39 | 35 |
| 05 | `CAR-CBO` | `9(006)` | 40 | 45 | 6 |
| 05 | `CAR-NIVEL` | `X(001)` | 46 | 46 | 1 |
| 05 | `CAR-PISO-SALARIAL` | `9(009)V99` | 47 | 57 | 11 |
| 05 | `CAR-TETO-SALARIAL` | `9(009)V99` | 58 | 68 | 11 |
| 05 | `CAR-CARGA-HOR-MES` | `9(003)` | 69 | 71 | 3 |
| 05 | `CAR-IND-INSALUBRID` | `X(001)` | 72 | 72 | 1 |
| 05 | `CAR-PERC-INSALUBRID` | `9(002)` | 73 | 74 | 2 |
| 05 | `CAR-IND-PERICULOSID` | `X(001)` | 75 | 75 | 1 |
| 05 | `CAR-IND-CONFIANCA` | `X(001)` | 76 | 76 | 1 |
| 05 | `CAR-COD-CBO-FAMILIA` | `9(004)` | 77 | 80 | 4 |
| 05 | `CAR-DT-CRIACAO` | `9(008)` | 81 | 88 | 8 |
| 05 | `CAR-SITUACAO` | `X(001)` | 89 | 89 | 1 |
| 05 | `CAR-FILLER` | `X(031)` | 90 | 120 | 31 |

**Somatorio dos campos: 120 bytes.**

## SFPWCOM - COMMAREA das transacoes CICS

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `COM-TRANSACAO` | `X(004)` | 1 | 4 | 4 |
| 05 | `COM-PROGRAMA-ANTERIOR` | `X(008)` | 5 | 12 | 8 |
| 05 | `COM-USUARIO` | `X(008)` | 13 | 20 | 8 |
| 05 | `COM-TERMINAL` | `X(004)` | 21 | 24 | 4 |
| 05 | `COM-FUNCAO` | `X(001)` | 25 | 25 | 1 |
| 05 | `COM-STATUS-TELA` | `9(002)` | 26 | 27 | 2 |
| 05 | `COM-MATRICULA` | `9(008)` | 28 | 35 | 8 |
| 05 | `COM-COMPETENCIA` | `9(006)` | 36 | 41 | 6 |
| 05 | `COM-CHAVE-BROWSE` | `9(008)` | 42 | 49 | 8 |
| 05 | `COM-CONTADOR-ERROS` | `9(003)` | 50 | 52 | 3 |
| 05 | `COM-DATA-SESSAO` | `9(008)` | 53 | 60 | 8 |
| 05 | `COM-HORA-SESSAO` | `9(006)` | 61 | 66 | 6 |
| 05 | `COM-AREA-TRABALHO` | `X(446)` | 67 | 512 | 446 |

**Somatorio dos campos: 512 bytes.**

## SFPWCON - Constantes corporativas e codigos

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `CTE-EVENTOS` | `(grupo)` |  |  |  |

**Somatorio dos campos: 0 bytes.**

## SFPWCTB - Interface contabil de partidas dobradas

DDNAME `SFPCTB` - LRECL 150 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `CTB-COMPETENCIA` | `9(006)` | 1 | 6 | 6 |
| 05 | `CTB-DATA-LANCAMENTO` | `9(008)` | 7 | 14 | 8 |
| 05 | `CTB-LOTE` | `9(006)` | 15 | 20 | 6 |
| 05 | `CTB-SEQUENCIA` | `9(006)` | 21 | 26 | 6 |
| 05 | `CTB-CONTA-DEBITO` | `9(008)` | 27 | 34 | 8 |
| 05 | `CTB-CONTA-CREDITO` | `9(008)` | 35 | 42 | 8 |
| 05 | `CTB-CENTRO-CUSTO` | `9(006)` | 43 | 48 | 6 |
| 05 | `CTB-VALOR` | `9(013)V99` | 49 | 63 | 15 |
| 05 | `CTB-HISTORICO` | `X(060)` | 64 | 123 | 60 |
| 05 | `CTB-ORIGEM` | `X(003)` | 124 | 126 | 3 |
| 05 | `CTB-TIPO-LANCAMENTO` | `X(001)` | 127 | 127 | 1 |
| 05 | `CTB-FILLER` | `X(023)` | 128 | 150 | 23 |

**Somatorio dos campos: 150 bytes.**

## SFPWDEP - Dependentes do empregado

DDNAME `SFPDEP` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `DEP-MATRICULA` | `9(008)` | 1 | 8 | 8 |
| 05 | `DEP-SEQUENCIA` | `9(002)` | 9 | 10 | 2 |
| 05 | `DEP-NOME` | `X(035)` | 11 | 45 | 35 |
| 05 | `DEP-DT-NASCIMENTO` | `9(008)` | 46 | 53 | 8 |
| 05 | `DEP-GRAU-PARENTESCO` | `9(002)` | 54 | 55 | 2 |
| 05 | `DEP-IND-IRRF` | `X(001)` | 56 | 56 | 1 |
| 05 | `DEP-IND-SALARIO-FAM` | `X(001)` | 57 | 57 | 1 |
| 05 | `DEP-IND-PLANO-SAUDE` | `X(001)` | 58 | 58 | 1 |
| 05 | `DEP-VLR-PLANO-SAUDE` | `9(007)V99` | 59 | 67 | 9 |
| 05 | `DEP-FILLER` | `X(013)` | 68 | 80 | 13 |

**Somatorio dos campos: 80 bytes.**

## SFPWDOM - Tabela generica de dominios

DDNAME `SFPDOM` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `DOM-CHAVE` | `(grupo)` |  |  |  |
| 10 | `DOM-TIPO` | `X(003)` | 1 | 3 | 3 |
| 10 | `DOM-CODIGO` | `X(006)` | 4 | 9 | 6 |
| 05 | `DOM-DESCRICAO` | `X(035)` | 10 | 44 | 35 |
| 05 | `DOM-DESCR-REDUZ` | `X(012)` | 45 | 56 | 12 |
| 05 | `DOM-ORDEM` | `9(003)` | 57 | 59 | 3 |
| 05 | `DOM-VALOR-AUX` | `X(010)` | 60 | 69 | 10 |
| 05 | `DOM-SITUACAO` | `X(001)` | 70 | 70 | 1 |
| 05 | `DOM-IND-SISTEMA` | `X(001)` | 71 | 71 | 1 |
| 05 | `DOM-FILLER` | `X(009)` | 72 | 80 | 9 |

**Somatorio dos campos: 80 bytes.**

## SFPWDPT - Cadastro de departamentos

DDNAME `SFPDPT` - LRECL 120 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `DPT-CHAVE` | `(grupo)` |  |  |  |
| 10 | `DPT-CODIGO` | `9(004)` | 1 | 4 | 4 |
| 05 | `DPT-DESCRICAO` | `X(035)` | 5 | 39 | 35 |
| 05 | `DPT-CENTRO-CUSTO` | `9(006)` | 40 | 45 | 6 |
| 05 | `DPT-COD-ESTABELEC` | `9(004)` | 46 | 49 | 4 |
| 05 | `DPT-MATR-RESPONSAVEL` | `9(008)` | 50 | 57 | 8 |
| 05 | `DPT-DPT-SUPERIOR` | `9(004)` | 58 | 61 | 4 |
| 05 | `DPT-CONTA-CONTABIL` | `9(008)` | 62 | 69 | 8 |
| 05 | `DPT-IND-RATEIO` | `X(001)` | 70 | 70 | 1 |
| 05 | `DPT-DT-CRIACAO` | `9(008)` | 71 | 78 | 8 |
| 05 | `DPT-SITUACAO` | `X(001)` | 79 | 79 | 1 |
| 05 | `DPT-FILLER` | `X(041)` | 80 | 120 | 41 |

**Somatorio dos campos: 120 bytes.**

## SFPWEMP - Cadastro de empregados

DDNAME `SFPEMP` - LRECL 500 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `EMP-CHAVE` | `(grupo)` |  |  |  |
| 10 | `EMP-MATRICULA` | `9(008)` | 1 | 8 | 8 |
| 05 | `EMP-NOME` | `X(040)` | 9 | 48 | 40 |
| 05 | `EMP-CPF` | `9(011)` | 49 | 59 | 11 |
| 05 | `EMP-PIS` | `9(011)` | 60 | 70 | 11 |
| 05 | `EMP-DT-ADMISSAO` | `9(008)` | 71 | 78 | 8 |
| 05 | `EMP-DT-DEMISSAO` | `9(008)` | 79 | 86 | 8 |
| 05 | `EMP-DT-NASCIMENTO` | `9(008)` | 87 | 94 | 8 |
| 05 | `EMP-SITUACAO` | `X(001)` | 95 | 95 | 1 |
| 05 | `EMP-COD-CARGO` | `9(004)` | 96 | 99 | 4 |
| 05 | `EMP-COD-DEPTO` | `9(004)` | 100 | 103 | 4 |
| 05 | `EMP-CENTRO-CUSTO` | `9(006)` | 104 | 109 | 6 |
| 05 | `EMP-SALARIO-BASE` | `9(009)V99` | 110 | 120 | 11 |
| 05 | `EMP-TIPO-SALARIO` | `X(001)` | 121 | 121 | 1 |
| 05 | `EMP-CARGA-HOR-MES` | `9(003)` | 122 | 124 | 3 |
| 05 | `EMP-QTD-DEP-IRRF` | `9(002)` | 125 | 126 | 2 |
| 05 | `EMP-QTD-DEP-SALFAM` | `9(002)` | 127 | 128 | 2 |
| 05 | `EMP-PERC-INSALUBRID` | `9(002)` | 129 | 130 | 2 |
| 05 | `EMP-IND-PERICULOSID` | `X(001)` | 131 | 131 | 1 |
| 05 | `EMP-IND-VALE-TRANSP` | `X(001)` | 132 | 132 | 1 |
| 05 | `EMP-VLR-VALE-TRANSP` | `9(007)V99` | 133 | 141 | 9 |
| 05 | `EMP-IND-VALE-REFEIC` | `X(001)` | 142 | 142 | 1 |
| 05 | `EMP-VLR-VALE-REFEIC` | `9(007)V99` | 143 | 151 | 9 |
| 05 | `EMP-IND-PLANO-SAUDE` | `X(001)` | 152 | 152 | 1 |
| 05 | `EMP-VLR-PLANO-SAUDE` | `9(007)V99` | 153 | 161 | 9 |
| 05 | `EMP-PERC-PENSAO` | `9(003)V99` | 162 | 166 | 5 |
| 05 | `EMP-VLR-PENSAO-FIXO` | `9(007)V99` | 167 | 175 | 9 |
| 05 | `EMP-VLR-CONSIGNADO` | `9(007)V99` | 176 | 184 | 9 |
| 05 | `EMP-QTD-PARC-CONSIG` | `9(003)` | 185 | 187 | 3 |
| 05 | `EMP-IND-ADIANTAMENTO` | `X(001)` | 188 | 188 | 1 |
| 05 | `EMP-PERC-ADIANTAMENTO` | `9(003)` | 189 | 191 | 3 |
| 05 | `EMP-IND-SINDICALIZADO` | `X(001)` | 192 | 192 | 1 |
| 05 | `EMP-DADOS-BANCARIOS` | `(grupo)` |  |  |  |
| 10 | `EMP-BANCO` | `9(003)` | 193 | 195 | 3 |
| 10 | `EMP-AGENCIA` | `9(005)` | 196 | 200 | 5 |
| 10 | `EMP-CONTA` | `9(012)` | 201 | 212 | 12 |
| 10 | `EMP-DIG-CONTA` | `X(001)` | 213 | 213 | 1 |
| 10 | `EMP-TIPO-CONTA` | `X(001)` | 214 | 214 | 1 |
| 05 | `EMP-CATEG-ESOCIAL` | `9(003)` | 215 | 217 | 3 |
| 05 | `EMP-SEXO` | `X(001)` | 218 | 218 | 1 |
| 05 | `EMP-GRAU-INSTRUCAO` | `9(002)` | 219 | 220 | 2 |
| 05 | `EMP-ESTADO-CIVIL` | `X(001)` | 221 | 221 | 1 |
| 05 | `EMP-RACA-COR` | `9(002)` | 222 | 223 | 2 |
| 05 | `EMP-NACIONALIDADE` | `9(003)` | 224 | 226 | 3 |
| 05 | `EMP-UF-NASCIMENTO` | `X(002)` | 227 | 228 | 2 |
| 05 | `EMP-MUN-NASCIMENTO` | `9(007)` | 229 | 235 | 7 |
| 05 | `EMP-NOME-MAE` | `X(040)` | 236 | 275 | 40 |
| 05 | `EMP-IND-DEFICIENCIA` | `X(001)` | 276 | 276 | 1 |
| 05 | `EMP-TIPO-DEFICIENCIA` | `9(002)` | 277 | 278 | 2 |
| 05 | `EMP-DOCUMENTOS` | `(grupo)` |  |  |  |
| 10 | `EMP-CTPS-NUMERO` | `9(008)` | 279 | 286 | 8 |
| 10 | `EMP-CTPS-SERIE` | `9(005)` | 287 | 291 | 5 |
| 10 | `EMP-CTPS-UF` | `X(002)` | 292 | 293 | 2 |
| 10 | `EMP-RG-NUMERO` | `X(015)` | 294 | 308 | 15 |
| 10 | `EMP-RG-ORGAO` | `X(008)` | 309 | 316 | 8 |
| 10 | `EMP-TITULO-ELEITOR` | `9(012)` | 317 | 328 | 12 |
| 05 | `EMP-ENDERECO` | `(grupo)` |  |  |  |
| 10 | `EMP-TIPO-LOGRADOURO` | `X(003)` | 329 | 331 | 3 |
| 10 | `EMP-LOGRADOURO` | `X(040)` | 332 | 371 | 40 |
| 10 | `EMP-NUMERO` | `X(008)` | 372 | 379 | 8 |
| 10 | `EMP-COMPLEMENTO` | `X(015)` | 380 | 394 | 15 |
| 10 | `EMP-BAIRRO` | `X(025)` | 395 | 419 | 25 |
| 10 | `EMP-COD-MUNICIPIO` | `9(007)` | 420 | 426 | 7 |
| 10 | `EMP-UF` | `X(002)` | 427 | 428 | 2 |
| 10 | `EMP-CEP` | `9(008)` | 429 | 436 | 8 |
| 05 | `EMP-TELEFONE` | `X(014)` | 437 | 450 | 14 |
| 05 | `EMP-COD-ESTABELEC` | `9(004)` | 451 | 454 | 4 |
| 05 | `EMP-TIPO-VINCULO` | `9(002)` | 455 | 456 | 2 |
| 05 | `EMP-TIPO-JORNADA` | `9(002)` | 457 | 458 | 2 |
| 05 | `EMP-COD-HORARIO` | `9(003)` | 459 | 461 | 3 |
| 05 | `EMP-MEDIA-VARIAVEIS` | `9(009)V99` | 462 | 472 | 11 |
| 05 | `EMP-SALDO-FGTS` | `9(009)V99` | 473 | 483 | 11 |
| 05 | `EMP-FILLER` | `X(017)` | 484 | 500 | 17 |

**Somatorio dos campos: 500 bytes.**

## SFPWEST - Empresa e estabelecimentos

DDNAME `SFPEST` - LRECL 480 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `EST-CHAVE` | `(grupo)` |  |  |  |
| 10 | `EST-CODIGO` | `9(004)` | 1 | 4 | 4 |
| 05 | `EST-TIPO` | `X(001)` | 5 | 5 | 1 |
| 05 | `EST-CNPJ` | `9(014)` | 6 | 19 | 14 |
| 05 | `EST-RAZAO-SOCIAL` | `X(060)` | 20 | 79 | 60 |
| 05 | `EST-NOME-FANTASIA` | `X(040)` | 80 | 119 | 40 |
| 05 | `EST-INSC-ESTADUAL` | `X(015)` | 120 | 134 | 15 |
| 05 | `EST-INSC-MUNICIPAL` | `X(015)` | 135 | 149 | 15 |
| 05 | `EST-ENDERECO` | `(grupo)` |  |  |  |
| 10 | `EST-TIPO-LOGRADOURO` | `X(003)` | 150 | 152 | 3 |
| 10 | `EST-LOGRADOURO` | `X(040)` | 153 | 192 | 40 |
| 10 | `EST-NUMERO` | `X(008)` | 193 | 200 | 8 |
| 10 | `EST-COMPLEMENTO` | `X(015)` | 201 | 215 | 15 |
| 10 | `EST-BAIRRO` | `X(025)` | 216 | 240 | 25 |
| 10 | `EST-COD-MUNICIPIO` | `9(007)` | 241 | 247 | 7 |
| 10 | `EST-UF` | `X(002)` | 248 | 249 | 2 |
| 10 | `EST-CEP` | `9(008)` | 250 | 257 | 8 |
| 05 | `EST-TELEFONE` | `X(014)` | 258 | 271 | 14 |
| 05 | `EST-EMAIL` | `X(040)` | 272 | 311 | 40 |
| 05 | `EST-CNAE` | `9(007)` | 312 | 318 | 7 |
| 05 | `EST-COD-FPAS` | `9(003)` | 319 | 321 | 3 |
| 05 | `EST-COD-TERCEIROS` | `9(004)` | 322 | 325 | 4 |
| 05 | `EST-ALIQ-RAT` | `9(002)V99` | 326 | 329 | 4 |
| 05 | `EST-FAP` | `9(001)V9999` | 330 | 334 | 5 |
| 05 | `EST-ALIQ-TERCEIROS` | `9(002)V99` | 335 | 338 | 4 |
| 05 | `EST-IND-SIMPLES` | `X(001)` | 339 | 339 | 1 |
| 05 | `EST-IND-DESONERACAO` | `X(001)` | 340 | 340 | 1 |
| 05 | `EST-CNPJ-SINDICATO` | `9(014)` | 341 | 354 | 14 |
| 05 | `EST-NOME-SINDICATO` | `X(040)` | 355 | 394 | 40 |
| 05 | `EST-MES-DATA-BASE` | `9(002)` | 395 | 396 | 2 |
| 05 | `EST-PERC-CONTR-SIND` | `9(003)V99` | 397 | 401 | 5 |
| 05 | `EST-DIA-PAGAMENTO` | `9(002)` | 402 | 403 | 2 |
| 05 | `EST-DIA-ADIANTAMENTO` | `9(002)` | 404 | 405 | 2 |
| 05 | `EST-BANCO-PAGADOR` | `9(003)` | 406 | 408 | 3 |
| 05 | `EST-AGENCIA-PAGADORA` | `9(005)` | 409 | 413 | 5 |
| 05 | `EST-CONTA-PAGADORA` | `9(012)` | 414 | 425 | 12 |
| 05 | `EST-DIG-CONTA` | `X(001)` | 426 | 426 | 1 |
| 05 | `EST-COD-CONVENIO` | `X(020)` | 427 | 446 | 20 |
| 05 | `EST-DT-INICIO-ATIV` | `9(008)` | 447 | 454 | 8 |
| 05 | `EST-SITUACAO` | `X(001)` | 455 | 455 | 1 |
| 05 | `EST-FILLER` | `X(025)` | 456 | 480 | 25 |

**Somatorio dos campos: 480 bytes.**

## SFPWEVE - Cadastro de eventos / rubricas

DDNAME `SFPEVE` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `EVE-CODIGO` | `9(004)` | 1 | 4 | 4 |
| 05 | `EVE-DESCRICAO` | `X(030)` | 5 | 34 | 30 |
| 05 | `EVE-NATUREZA` | `X(001)` | 35 | 35 | 1 |
| 05 | `EVE-TIPO-CALCULO` | `9(003)` | 36 | 38 | 3 |
| 05 | `EVE-INCIDENCIAS` | `(grupo)` |  |  |  |
| 10 | `EVE-INC-INSS` | `X(001)` | 39 | 39 | 1 |
| 10 | `EVE-INC-IRRF` | `X(001)` | 40 | 40 | 1 |
| 10 | `EVE-INC-FGTS` | `X(001)` | 41 | 41 | 1 |
| 10 | `EVE-INC-DSR` | `X(001)` | 42 | 42 | 1 |
| 10 | `EVE-INC-13O` | `X(001)` | 43 | 43 | 1 |
| 10 | `EVE-INC-FERIAS` | `X(001)` | 44 | 44 | 1 |
| 05 | `EVE-UNIDADE` | `X(002)` | 45 | 46 | 2 |
| 05 | `EVE-PERCENTUAL` | `9(003)V99` | 47 | 51 | 5 |
| 05 | `EVE-CONTA-CONTABIL` | `9(008)` | 52 | 59 | 8 |
| 05 | `EVE-SITUACAO` | `X(001)` | 60 | 60 | 1 |
| 05 | `EVE-FILLER` | `X(020)` | 61 | 80 | 20 |

**Somatorio dos campos: 80 bytes.**

## SFPWFOL - Folha calculada, detalhe por evento

DDNAME `SFPFOL` - LRECL 120 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `FOL-COMPETENCIA` | `9(006)` | 1 | 6 | 6 |
| 05 | `FOL-TIPO-FOLHA` | `X(001)` | 7 | 7 | 1 |
| 05 | `FOL-MATRICULA` | `9(008)` | 8 | 15 | 8 |
| 05 | `FOL-SEQUENCIA` | `9(003)` | 16 | 18 | 3 |
| 05 | `FOL-COD-EVENTO` | `9(004)` | 19 | 22 | 4 |
| 05 | `FOL-DESCRICAO` | `X(030)` | 23 | 52 | 30 |
| 05 | `FOL-NATUREZA` | `X(001)` | 53 | 53 | 1 |
| 05 | `FOL-REFERENCIA` | `9(005)V99` | 54 | 60 | 7 |
| 05 | `FOL-VALOR` | `9(009)V99` | 61 | 71 | 11 |
| 05 | `FOL-CENTRO-CUSTO` | `9(006)` | 72 | 77 | 6 |
| 05 | `FOL-CONTA-CONTABIL` | `9(008)` | 78 | 85 | 8 |
| 05 | `FOL-FILLER` | `X(035)` | 86 | 120 | 35 |

**Somatorio dos campos: 120 bytes.**

## SFPWLOK - -

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `LOK-TIPO-DOMINIO` | `X(003)` | 1 | 3 | 3 |
| 05 | `LOK-PGM-CHAMADOR` | `X(008)` | 4 | 11 | 8 |
| 05 | `LOK-CAMPO-ORIGEM` | `X(018)` | 12 | 29 | 18 |
| 05 | `LOK-FILTRO` | `X(020)` | 30 | 49 | 20 |
| 05 | `LOK-UF-FILTRO` | `X(002)` | 50 | 51 | 2 |
| 05 | `LOK-COD-SELECIONADO` | `X(007)` | 52 | 58 | 7 |
| 05 | `LOK-DES-SELECIONADA` | `X(035)` | 59 | 93 | 35 |
| 05 | `LOK-AUX-SELECIONADO` | `X(010)` | 94 | 103 | 10 |
| 05 | `LOK-CHAVE-BROWSE` | `X(009)` | 104 | 112 | 9 |
| 05 | `LOK-PAGINA` | `9(003)` | 113 | 115 | 3 |
| 05 | `LOK-RETORNO` | `X(001)` | 116 | 116 | 1 |

**Somatorio dos campos: 116 bytes.**

## SFPWMOV - Movimento mensal lancado

DDNAME `SFPMOV` - LRECL 100 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `MOV-CHAVE` | `(grupo)` |  |  |  |
| 10 | `MOV-MATRICULA` | `9(008)` | 1 | 8 | 8 |
| 10 | `MOV-COMPETENCIA` | `9(006)` | 9 | 14 | 6 |
| 10 | `MOV-COD-EVENTO` | `9(004)` | 15 | 18 | 4 |
| 05 | `MOV-REFERENCIA` | `9(005)V99` | 19 | 25 | 7 |
| 05 | `MOV-VALOR` | `9(009)V99` | 26 | 36 | 11 |
| 05 | `MOV-TIPO-LANC` | `X(001)` | 37 | 37 | 1 |
| 05 | `MOV-ORIGEM` | `X(003)` | 38 | 40 | 3 |
| 05 | `MOV-DATA-LANC` | `9(008)` | 41 | 48 | 8 |
| 05 | `MOV-USUARIO` | `X(008)` | 49 | 56 | 8 |
| 05 | `MOV-SIT-CRITICA` | `X(001)` | 57 | 57 | 1 |
| 05 | `MOV-FILLER` | `X(043)` | 58 | 100 | 43 |

**Somatorio dos campos: 100 bytes.**

## SFPWMUN - Municipios (codigo IBGE)

DDNAME `SFPMUN` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `MUN-CHAVE` | `(grupo)` |  |  |  |
| 10 | `MUN-COD-IBGE` | `9(007)` | 1 | 7 | 7 |
| 05 | `MUN-UF-NOME` | `(grupo)` |  |  |  |
| 10 | `MUN-UF` | `X(002)` | 8 | 9 | 2 |
| 10 | `MUN-NOME` | `X(040)` | 10 | 49 | 40 |
| 05 | `MUN-COD-SIAFI` | `9(004)` | 50 | 53 | 4 |
| 05 | `MUN-IND-CAPITAL` | `X(001)` | 54 | 54 | 1 |
| 05 | `MUN-CEP-INICIAL` | `9(008)` | 55 | 62 | 8 |
| 05 | `MUN-CEP-FINAL` | `9(008)` | 63 | 70 | 8 |
| 05 | `MUN-SITUACAO` | `X(001)` | 71 | 71 | 1 |
| 05 | `MUN-FILLER` | `X(009)` | 72 | 80 | 9 |

**Somatorio dos campos: 80 bytes.**

## SFPWPON - Apuracao do ponto

DDNAME `SFPPON` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `PON-MATRICULA` | `9(008)` | 1 | 8 | 8 |
| 05 | `PON-COMPETENCIA` | `9(006)` | 9 | 14 | 6 |
| 05 | `PON-DIAS-TRABALHADOS` | `9(003)` | 15 | 17 | 3 |
| 05 | `PON-DIAS-UTEIS-MES` | `9(003)` | 18 | 20 | 3 |
| 05 | `PON-HORAS-NORMAIS` | `9(005)V99` | 21 | 27 | 7 |
| 05 | `PON-HE-050` | `9(005)V99` | 28 | 34 | 7 |
| 05 | `PON-HE-100` | `9(005)V99` | 35 | 41 | 7 |
| 05 | `PON-HORAS-NOTURNAS` | `9(005)V99` | 42 | 48 | 7 |
| 05 | `PON-FALTAS-DIAS` | `9(003)` | 49 | 51 | 3 |
| 05 | `PON-ATRASOS-MIN` | `9(005)` | 52 | 56 | 5 |
| 05 | `PON-DSR-PERDIDOS` | `9(003)` | 57 | 59 | 3 |
| 05 | `PON-DIAS-AFASTAM` | `9(003)` | 60 | 62 | 3 |
| 05 | `PON-DIAS-FERIAS` | `9(003)` | 63 | 65 | 3 |
| 05 | `PON-FILLER` | `X(015)` | 66 | 80 | 15 |

**Somatorio dos campos: 80 bytes.**

## SFPWRES - Resumo da folha por empregado

DDNAME `SFPRES` - LRECL 250 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `RES-COMPETENCIA` | `9(006)` | 1 | 6 | 6 |
| 05 | `RES-TIPO-FOLHA` | `X(001)` | 7 | 7 | 1 |
| 05 | `RES-MATRICULA` | `9(008)` | 8 | 15 | 8 |
| 05 | `RES-NOME` | `X(040)` | 16 | 55 | 40 |
| 05 | `RES-CENTRO-CUSTO` | `9(006)` | 56 | 61 | 6 |
| 05 | `RES-SALARIO-BASE` | `9(009)V99` | 62 | 72 | 11 |
| 05 | `RES-TOT-PROVENTOS` | `9(009)V99` | 73 | 83 | 11 |
| 05 | `RES-TOT-DESCONTOS` | `9(009)V99` | 84 | 94 | 11 |
| 05 | `RES-LIQUIDO` | `S9(009)V99` | 95 | 105 | 11 |
| 05 | `RES-BASE-INSS` | `9(009)V99` | 106 | 116 | 11 |
| 05 | `RES-BASE-IRRF` | `9(009)V99` | 117 | 127 | 11 |
| 05 | `RES-BASE-FGTS` | `9(009)V99` | 128 | 138 | 11 |
| 05 | `RES-VLR-INSS` | `9(009)V99` | 139 | 149 | 11 |
| 05 | `RES-VLR-IRRF` | `9(009)V99` | 150 | 160 | 11 |
| 05 | `RES-VLR-FGTS` | `9(009)V99` | 161 | 171 | 11 |
| 05 | `RES-VLR-SAL-FAMILIA` | `9(007)V99` | 172 | 180 | 9 |
| 05 | `RES-ALIQ-INSS-EFET` | `9(003)V99` | 181 | 185 | 5 |
| 05 | `RES-ALIQ-IRRF` | `9(003)V99` | 186 | 190 | 5 |
| 05 | `RES-QTD-EVENTOS` | `9(003)` | 191 | 193 | 3 |
| 05 | `RES-BANCO` | `9(003)` | 194 | 196 | 3 |
| 05 | `RES-AGENCIA` | `9(005)` | 197 | 201 | 5 |
| 05 | `RES-CONTA` | `9(012)` | 202 | 213 | 12 |
| 05 | `RES-DIG-CONTA` | `X(001)` | 214 | 214 | 1 |
| 05 | `RES-CPF` | `9(011)` | 215 | 225 | 11 |
| 05 | `RES-FILLER` | `X(025)` | 226 | 250 | 25 |

**Somatorio dos campos: 250 bytes.**

## SFPWRSC - Solicitacao de rescisao (entrada)

DDNAME `SFPRSCI` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `RSC-MATRICULA` | `9(008)` | 1 | 8 | 8 |
| 05 | `RSC-DT-DESLIGAMENTO` | `9(008)` | 9 | 16 | 8 |
| 05 | `RSC-COD-MOTIVO` | `9(002)` | 17 | 18 | 2 |
| 05 | `RSC-IND-AVISO` | `X(001)` | 19 | 19 | 1 |
| 05 | `RSC-IND-FER-VENCIDAS` | `X(001)` | 20 | 20 | 1 |
| 05 | `RSC-DIAS-FER-VENCIDAS` | `9(002)` | 21 | 22 | 2 |
| 05 | `RSC-DT-BASE-FERIAS` | `9(008)` | 23 | 30 | 8 |
| 05 | `RSC-SALDO-FGTS-INFO` | `9(009)V99` | 31 | 41 | 11 |
| 05 | `RSC-USUARIO` | `X(008)` | 42 | 49 | 8 |
| 05 | `RSC-FILLER` | `X(031)` | 50 | 80 | 31 |

**Somatorio dos campos: 80 bytes.**

## SFPWTAB - Tabelas legais e parametros

DDNAME `SFPTAB` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `TAB-TIPO` | `X(003)` | 1 | 3 | 3 |
| 05 | `TAB-COMPETENCIA` | `9(006)` | 4 | 9 | 6 |
| 05 | `TAB-SEQUENCIA` | `9(002)` | 10 | 11 | 2 |
| 05 | `TAB-CHAVE` | `X(015)` | 12 | 26 | 15 |
| 05 | `TAB-LIMITE` | `9(009)V99` | 27 | 37 | 11 |
| 05 | `TAB-ALIQUOTA` | `9(003)V99` | 38 | 42 | 5 |
| 05 | `TAB-DEDUCAO` | `9(009)V99` | 43 | 53 | 11 |
| 05 | `TAB-DESCRICAO` | `X(027)` | 54 | 80 | 27 |

**Somatorio dos campos: 80 bytes.**

## SFPWTRB - Area de comunicacao com SFP0310

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `TRB-FUNCAO` | `X(004)` | 1 | 4 | 4 |
| 05 | `TRB-COMPETENCIA` | `9(006)` | 5 | 10 | 6 |
| 05 | `TRB-BASE-CALCULO` | `9(009)V99` | 11 | 21 | 11 |
| 05 | `TRB-QTD-DEPENDENTES` | `9(002)` | 22 | 23 | 2 |
| 05 | `TRB-VLR-INSS-DEDUZIR` | `9(009)V99` | 24 | 34 | 11 |
| 05 | `TRB-VLR-PENSAO-DEDUZIR` | `9(009)V99` | 35 | 45 | 11 |
| 05 | `TRB-VLR-REMUN-SALFAM` | `9(009)V99` | 46 | 56 | 11 |
| 05 | `TRB-QTD-FILHOS-SALFAM` | `9(002)` | 57 | 58 | 2 |
| 05 | `TRB-VLR-CALCULADO` | `9(009)V99` | 59 | 69 | 11 |
| 05 | `TRB-ALIQUOTA-NOMINAL` | `9(003)V99` | 70 | 74 | 5 |
| 05 | `TRB-ALIQUOTA-EFETIVA` | `9(003)V99` | 75 | 79 | 5 |
| 05 | `TRB-FAIXA-APLICADA` | `9(002)` | 80 | 81 | 2 |
| 05 | `TRB-BASE-APURADA` | `9(009)V99` | 82 | 92 | 11 |
| 05 | `TRB-VLR-DEDUCOES` | `9(009)V99` | 93 | 103 | 11 |
| 05 | `TRB-METODO-IRRF` | `X(001)` | 104 | 104 | 1 |
| 05 | `TRB-COD-RETORNO` | `9(002)` | 105 | 106 | 2 |
| 05 | `TRB-MSG-RETORNO` | `X(060)` | 107 | 166 | 60 |

**Somatorio dos campos: 166 bytes.**

## SFPWUFE - Unidades da federacao

DDNAME `SFPUFE` - LRECL 80 - organizacao sequencial.

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `UFE-CHAVE` | `(grupo)` |  |  |  |
| 10 | `UFE-SIGLA` | `X(002)` | 1 | 2 | 2 |
| 05 | `UFE-NOME` | `X(025)` | 3 | 27 | 25 |
| 05 | `UFE-COD-IBGE` | `9(002)` | 28 | 29 | 2 |
| 05 | `UFE-REGIAO` | `X(012)` | 30 | 41 | 12 |
| 05 | `UFE-CAPITAL` | `X(025)` | 42 | 66 | 25 |
| 05 | `UFE-ALIQ-ICMS` | `9(002)V99` | 67 | 70 | 4 |
| 05 | `UFE-SITUACAO` | `X(001)` | 71 | 71 | 1 |
| 05 | `UFE-FILLER` | `X(009)` | 72 | 80 | 9 |

**Somatorio dos campos: 80 bytes.**

## SFPWUTL - Area de comunicacao com SFPUTIL

| Niv | Campo | PICTURE | Ini | Fim | Tam |
|---|---|---|---|---|---|
| 05 | `UTL-FUNCAO` | `X(004)` | 1 | 4 | 4 |
| 05 | `UTL-CPF` | `9(011)` | 5 | 15 | 11 |
| 05 | `UTL-DATA-INI` | `9(008)` | 16 | 23 | 8 |
| 05 | `UTL-DATA-FIM` | `9(008)` | 24 | 31 | 8 |
| 05 | `UTL-QTD-DIAS` | `S9(007)` | 32 | 38 | 7 |
| 05 | `UTL-QTD-AVOS` | `9(002)` | 39 | 40 | 2 |
| 05 | `UTL-VALOR` | `9(009)V99` | 41 | 51 | 11 |
| 05 | `UTL-DATA-FORMATADA` | `X(010)` | 52 | 61 | 10 |
| 05 | `UTL-EXTENSO` | `X(180)` | 62 | 241 | 180 |
| 05 | `UTL-NUMERO-DV` | `9(012)` | 242 | 253 | 12 |
| 05 | `UTL-DIGITO` | `9(001)` | 254 | 254 | 1 |
| 05 | `UTL-COD-RETORNO` | `9(002)` | 255 | 256 | 2 |
| 05 | `UTL-MENSAGEM` | `X(060)` | 257 | 316 | 60 |

**Somatorio dos campos: 316 bytes.**

