# SFP - Sistema de Folha de Pagamento (COBOL Mainframe)

Simulacao de sistema corporativo de folha para z/OS: COBOL batch
(GnuCOBOL, roda de verdade), COBOL CICS + BMS e DB2 (codigo
mainframe, exige tradutor CICS e precompilador DB2), JCL e PROCs.

## Comandos

`dados/`, `saidas/` e os executaveis de `build/` nao sao
versionados. Em clone novo, gere a massa antes de compilar:
`gerar_massa.py`, `gerar_dominios.py`, `build.sh`, `run.sh`.

```bash
python3 tools/gerar_massa.py      # gera a massa de empregados
python3 tools/gerar_dominios.py   # gera dominios e cadastros de apoio
./build/build.sh                  # compila os modulos batch
./build/run.sh                    # roda a cadeia mensal completa
python3 tools/gerar_dicionario.py # regera docs/DICIONARIO-DADOS.md
python3 tools/gerar_bms.py        # regera os mapsets BMS de grade
python3 tools/validar_bms.py      # valida os .bms sem CICS
python3 tools/auditar.py          # confere os calculos por fora
```

`gerar_dicionario.py` le os copybooks e acusa divergencia entre a
soma dos PICTUREs e o LRECL declarado. Rode depois de mexer em
qualquer layout: ja pegou tres bugs reais de filler.

## Convencoes obrigatorias

- **Coluna 72**: nenhuma linha de COBOL ou copybook pode
  ultrapassar. Validar com
  `awk 'length>72{print FILENAME" "NR}' cobol/*.cbl copy/*.cpy`
- **`DECIMAL-POINT IS COMMA`** em todos os programas. Por isso
  **nao use literais decimais** em COMPUTE: escreva razoes
  inteiras. Ex.: adicional noturno = `* 120 / 105`;
  hora extra 50% = `* (100 + 50) / 100`.
- **Nome do FD diferente do DDNAME**, senao o GnuCOBOL acusa
  "redefinition of". Ex.: `SELECT ARQ-TABELA ASSIGN TO SFPTAB`.
- **`COB_LS_FIXED=1`** e obrigatorio na execucao local, e cada
  DDNAME e resolvido pela variavel `DD_<ddname>`.
- **BMS**: linha de continuacao exige `X` na coluna 72. Um
  literal continuado nao pode ser preenchido com espacos ate a
  coluna 71: o espaco entra no texto do mapa. Quebre o literal
  em exatamente 71 colunas e retome na coluna 16.
- `SFPM03/04/05/06` sao **gerados** por `tools/gerar_bms.py`.
  Corrija o gerador, nao o `.bms`. Depois de mexer em qualquer
  mapa, rode `tools/validar_bms.py`: ele confere layout, coluna
  de continuacao e o mapa contra o copybook simbolico, e sai com
  codigo 1 se houver erro.
- **`POS` aponta o byte de atributo**, e os dados comecam na
  coluna seguinte. Um campo de `LENGTH=n` em `POS=(l,c)` ocupa de
  `c` a `c+n`. Quando a coluna seguinte encosta, o atributo dela
  ja fecha a area digitavel e o `DFHMDF LENGTH=0` de fechamento
  sobra -- em `gerar_bms.py`, `campo(..., stop=False)`.
- GnuCOBOL nao aceita `MOVE SPACES` para campo numerico-editado.
  Use `BLANK WHEN ZERO` mais `MOVE ZEROS`.
- Read-ahead em matching sequencial: o registro lido
  antecipadamente **nao pode compartilhar area** com o registro em
  processamento. Registro generico no FD, area de trabalho na
  WORKING-STORAGE.
- **Tela de grade com `CTRL=(FREEKB,FRSET)`**: no RECEIVE so
  voltam os campos digitados; o resto chega em LOW-VALUES. Logo a
  chave de cada linha da pagina tem de viajar na COMMAREA, nao ser
  relida da tela. `SFP0140` guarda isso em `WS-ESTADO` a partir de
  `COM-AREA-TRABALHO(121:...)`, depois dos 116 bytes que o
  `SFPWLOK` ocupa, para o ida-e-volta do F4 nao atropelar.
- **Campo `ATTRB=PROT` que o programa releia da tela precisa de
  `FSET`**: sem MDT ligado o `RECEIVE MAP` devolve LOW-VALUES. Era
  o caso da grade do `SFPM09`, e por isso nenhum F4 devolvia a
  selecao.
- Campo numerico-editado (`Z(009)9,99`) que volta do BMS vem
  alinhado a esquerda: `MOVE` direto para `9(009)V99` da valor
  errado. Des-editar a mao (ver `7400-DE-EDITAR` no `SFP0140`).
  Vale tambem para codigo curto digitado em campo `X(004)`.
- **Estado que nao cabe na COMMAREA vai para fila TS.**
  `COM-AREA-TRABALHO` deixa 326 bytes livres depois do `SFPWLOK`.
  O estabelecimento em edicao do `SFP0130` tem 372 e o estado das
  duas telas do `SFP0100` tem 500, entao os dois usam
  `WRITEQ TS ... MAIN` (nome `'S13'`/`'S01'` mais `EIBTRMID`).
  Fila em MAIN nao e recuperavel: o `SYNCPOINT ROLLBACK` do
  tratador de abend nao a desfaz.

## Regras de negocio que ja geraram bug

- **Salario de referencia**: verbas percentuais (periculosidade,
  quinquenio, VT, adiantamento, sindical, tipo de calculo 004) nao
  podem incidir sobre `EMP-SALARIO-BASE` de horista ou diarista,
  porque ali o campo guarda valor-hora ou valor-dia. Use
  `WS-SALARIO-REFER` (mensalista: salario base; demais: valor-hora
  x carga horaria mensal). Mesma armadilha no SFP0350 para 13o e
  ferias proporcionais.
- **Incidencias**: todo evento de desconto tem as seis flags em
  `N`. INSS e pensao entram na base do IRRF por dentro do SFP0310,
  via `AREA-TRIBUTOS`. Ligar as flags causa deducao em dobro.
- **INSS**: acumula arredondado faixa a faixa, nao no total.
- **IRRF**: calcula os dois regimes (deducoes legais e desconto
  simplificado) e adota o de menor retencao. Pensao alimenticia e
  deduzida nos dois.

## Conferencia que precisa continuar fechando

Liquido do resumo (SFP0300) = saldo credor da conta 21110001
(SFP0400) = total dos segmentos A do CNAB240 (SFP0600). Sao tres
programas sem codigo de calculo em comum. Se divergirem, ha erro.

## Estrutura

| Pasta | Conteudo |
|---|---|
| `cobol/` | fontes COBOL |
| `copy/` | copybooks e estruturas simbolicas BMS |
| `bms/` | fontes dos mapas |
| `dclgen/` `ddl/` `sql/` `ctl/` | camada DB2 |
| `jcl/` `proc/` | jobs e procedures |
| `dados/` | massa ficticia (semente fixa, nao versionada) |
| `saidas/` | resultados da execucao (nao versionados) |
| `tools/` | geradores Python |
| `docs/` | docs de arquitetura, regras, operacao e ambiente |

## Estado atual

Batch completo e validado; online com nove programas prontos.
Inventario vivo: `ls cobol/`, `git log`, e a secao 2 (Inventario
de modulos) de `docs/ARQUITETURA.md`. O que nao esta pronto, com o motivo de
cada item, esta em `docs/PENDENCIAS.md` -- que tambem registra o
que ja foi corrigido, para nao se reabrir a analise.

Confira o item no fonte antes de ataca-lo. Para item de mapa a
medicao e `python3 tools/validar_bms.py --resumo`.

## Ambiente para rodar o online

Os programas CICS nao rodam localmente: exigem tradutor CICS e, em
dois casos, precompilador DB2. `docs/AMBIENTE-SIMULADO.md` compara
as rotas e detalha a recomendada (container com GnuCOBOL, um
pre-processador `EXEC CICS` e um modulo `SFPCICS`), com plano em
seis fases. A Fase 1 -- validacao estatica dos `.bms` -- esta
feita, em `tools/validar_bms.py`.

## Como trabalhar aqui

Um programa por vez. Antes de escrever, leia o copybook envolvido
e um programa existente do mesmo tipo como referencia de estilo
(`SFP0120.cbl` para tela de grade, `SFP0100.cbl` para formulario).
Nao revalide a cadeia batch inteira a menos que o pedido tenha
mexido no motor de calculo.

Dois agentes locais evitam carregar contexto a toa:
`inspetor-tela` (read-only) ja sabe a convencao de coluna do BMS e
as armadilhas de `FSET`/`FRSET` -- use para qualquer medicao de
mapa; `conferente-cadeia` roda a cadeia do zero e devolve so o
veredito da triangulacao. O porque e o metodo de medicao estao em
`docs/OTIMIZACAO-TOKENS.md`.
