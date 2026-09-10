# SFP - Sistema de Folha de Pagamento (COBOL Mainframe)

Simulacao de sistema corporativo de folha para z/OS: COBOL batch
(GnuCOBOL, roda de verdade), COBOL CICS + BMS e DB2 (codigo
mainframe, exige tradutor CICS e precompilador DB2), JCL e PROCs.

## Comandos

```bash
./build/build.sh              # compila os modulos batch
./build/run.sh                # roda a cadeia mensal completa
python3 tools/gerar_massa.py      # regera a massa de empregados
python3 tools/gerar_dominios.py   # regera dominios e cadastros de apoio
python3 tools/gerar_dicionario.py # regera docs/DICIONARIO-DADOS.md
python3 tools/gerar_bms.py        # regera os mapsets BMS de grade
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
  Corrija o gerador, nao o `.bms`.
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
| `dados/` | massa ficticia (semente fixa) |
| `saidas/` | resultados da execucao |
| `tools/` | geradores Python |
| `docs/` | docs de arquitetura, regras, operacao e ambiente |

## Estado atual

Batch completo e validado: SFP0200 critica, SFP0300 calculo,
SFP0350 rescisao, SFP0400 contabil, SFP0500 holerite, SFP0600
CNAB240, mais SFP0310 e SFPUTIL.

Online pronto: SFP0000 (menu), SFP0100 (cadastro de empregado,
duas telas), SFP0110 (rubricas), SFP0120 (movimento), SFP0130
(empresa e estabelecimentos), SFP0140 (cargos), SFP0160
(dominios), SFP0900 (janela F4 generica que atende todas as
listas de selecao).

`SFP0130` e `SFP0100` guardam o estado numa fila temporaria do
CICS (`WRITEQ TS ... MAIN`, nome `'S13'`/`'S01'` mais `EIBTRMID`)
em vez da COMMAREA, porque nao cabem nos 326 bytes que restam de
`COM-AREA-TRABALHO` depois do `SFPWLOK`: o estabelecimento em
edicao tem 372 bytes, e o estado das duas telas do `SFP0100` tem
500. Fila em MAIN nao e recuperavel, logo o `SYNCPOINT ROLLBACK`
do tratador de abend nao a desfaz.

O `SFP0100` cobre `MAPEMP` (contrato) e `MAPEMP2` (dados
pessoais, documentos, endereco e lotacao), com F9 nos dois
sentidos e F4 em 21 campos. Os complementares moram na tabela
`TB_EMPREGADO_COMPL`, gravada por F6 na segunda tela; o
`SFPWEMP` continua sendo o layout VSAM do batch.

Dominios prontos: 22 tabelas com 131 registros em `SFPDOM.DAT`,
mais o meta-dominio `TIP` (22 registros, um por tipo) — 153 no
total — mais UF, municipios, cargos, departamentos e
estabelecimentos.

### Pendente

Detalhe de cada item em `docs/PENDENCIAS.md`, que tambem registra
o que ja foi corrigido.

1. DDL e DCLGEN das seis tabelas novas.
2. `SFPM04` sem rotulo `F4=LISTA` nas linhas 8 e 18 (corrigir em
   `gerar_bms.py`).
3. Sete campos do `SFPWEST` sem campo no `SFPM04`: so a massa os
   carrega, a alteracao os preserva.
4. `SFPM05` tem coluna `CH` no cabecalho e nao tem `DFHMDF`.
   Hoje `SFP0140` assume 220 e preserva na alteracao.
5. `SFPM05` sem coluna de situacao: por isso `SFP0140` exclui
   fisicamente em vez de marcar `CAR-SITUACAO = 'E'`.
6. `SFPM06` sem coluna para `DOM-IND-SISTEMA`.

## Ambiente para rodar o online

Os programas CICS nao rodam localmente hoje: exigem tradutor CICS e,
em dois casos, precompilador DB2. `docs/AMBIENTE-SIMULADO.md`
compara as rotas possiveis (Hercules/MVS 3.8j, ZD&T, Z Xplore,
rehosting comercial, shim caseiro) e detalha a recomendada: um
container com GnuCOBOL, um pre-processador `EXEC CICS` e um modulo
`SFPCICS` que implementa os 19 verbos que o repositorio usa, sem
alterar nenhum fonte COBOL. Traz inventario de verbos, opcoes,
condicoes, campos do EIB, esboco de Dockerfile, plano em 6 fases e
as limitacoes (sem rollback real, sem concorrencia, ASCII e nao
EBCDIC).

## Como trabalhar aqui

Um programa por vez. Antes de escrever, leia o copybook envolvido
e um programa existente do mesmo tipo como referencia de estilo
(`SFP0120.cbl` para tela de grade, `SFP0100.cbl` para formulario).
Nao revalide a cadeia batch inteira a menos que o pedido tenha
mexido no motor de calculo.
