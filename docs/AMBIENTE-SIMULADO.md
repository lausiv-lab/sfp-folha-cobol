# Ambiente Simulado de Mainframe e CICS

Este documento responde a uma pergunta pratica: e possivel montar,
em um Docker rodando em Linux ou macOS, um ambiente que execute os
programas online deste repositorio (`SFP0000`, `SFP0100`, `SFP0110`,
`SFP0120`, `SFP0130`, `SFP0140`, `SFP0160` e `SFP0900`) com telas
3270, arquivos VSAM e comandos `EXEC CICS`?

A resposta curta e: **sim, com uma ressalva importante**. Da para
colocar em um container tudo o que o projeto precisa para executar
os programas online, mas nao da para colocar o CICS da IBM dentro
desse container. O que se constroi e um substituto: um interpretador
proprio dos comandos `EXEC CICS` que o projeto realmente usa. A
alternativa fiel (CICS de verdade) existe, custa licenca e nao roda
em Docker sobre x86 de forma legal e gratuita.

O documento esta organizado assim: primeiro o inventario exato do
que precisa ser emulado, depois as cinco rotas possiveis com custo
e fidelidade, depois o detalhamento da rota recomendada (container
com GnuCOBOL mais um shim CICS caseiro), incluindo esboco de
Dockerfile, plano de implantacao em fases e limitacoes conhecidas.

## 1. Inventario: o que precisa ser emulado

A vantagem de emular um sistema conhecido e que o alvo e finito. O
levantamento abaixo foi extraido dos fontes em `cobol/`.

### 1.1 Comandos EXEC CICS usados (19 verbos)

| Verbo | Ocorrencias | Grupo funcional |
|---|---|---|
| `SEND MAP` | 31 | terminal / BMS |
| `RETURN` (com e sem `TRANSID`) | 21 | controle de programa |
| `READ` | 18 | controle de arquivo |
| `SYNCPOINT` / `SYNCPOINT ROLLBACK` | 17 | recuperacao |
| `XCTL` | 12 | controle de programa |
| `STARTBR` | 10 | browse |
| `ENDBR` | 10 | browse |
| `RECEIVE MAP` | 8 | terminal / BMS |
| `READNEXT` | 8 | browse |
| `HANDLE ABEND` | 8 | tratamento de erro |
| `WRITE` | 4 | controle de arquivo |
| `REWRITE` | 4 | controle de arquivo |
| `DELETE` | 4 | controle de arquivo |
| `FORMATTIME` | 4 | data e hora |
| `ASKTIME` | 4 | data e hora |
| `READPREV` | 2 | browse |
| `DELETEQ TS` | 2 | armazenamento temporario |
| `WRITEQ TS` | 1 | armazenamento temporario |
| `READQ TS` | 1 | armazenamento temporario |

Dezenove verbos. O CICS tem centenas de comandos; o projeto usa
menos de vinte, todos das areas mais simples da API (terminal,
arquivo, programa, TS). Nao ha `START`, `LINK`, `ENQ`, `DEQ`,
`READQ TD`, `GETMAIN`, `ASSIGN`, `INQUIRE`, `SPOOL`, `WEB`, `LINK
CHANNEL`, nem interface com MQ. E por isso que a rota do shim
caseiro e viavel.

### 1.2 Opcoes usadas

`RESP` (61), `FILE` (60), `RIDFLD` (42), `FROM` (39), `INTO` (37),
`LENGTH` (31), `MAPSET` (28), `MAP` (28), `COMMAREA` (19),
`PROGRAM` (11), `TRANSID` (8), `LABEL` (8), `QUEUE` (4), `ITEM` (1),
mais as palavras isoladas `ERASE`, `DATAONLY`, `CURSOR`, `FREEKB`,
`ALARM`, `UPDATE`, `GTEQ`, `EQUAL`, `MAIN`.

Nenhum comando usa `NOHANDLE`, `RESP2`, `SET`, `KEYLENGTH`,
`GENERIC` ou `SYSID`.

### 1.3 Condicoes testadas

Somente cinco: `DFHRESP(NORMAL)` (55), `DFHRESP(NOTFND)` (8),
`DFHRESP(DUPREC)` (2), `DFHRESP(MAPFAIL)` (2) e `DFHRESP(PGMIDERR)`
(1). No CICS real esses nomes viram os valores canonicos de
`EIBRESP` (`NORMAL`=0, `NOTFND`=13, `DUPREC`=14, `PGMIDERR`=27,
`MAPFAIL`=36). Confira os numeros na tabela do produto antes de
codificar o shim; o importante e que o programa nunca compara com
literal numerico, sempre com `DFHRESP(...)`, o que deixa o
pre-processador livre para escolher a representacao.

### 1.4 Campos do EIB

Somente quatro: `EIBCALEN` (8), `EIBAID` (8), `EIBTRMID` (14) e
`EIBCPOSN` (5). Um shim que preencha esses quatro campos atende
todo o online do projeto.

### 1.5 Simbolos do DFHAID e do DFHBMSCA

Do `DFHAID`: `DFHENTER`, `DFHCLEAR`, `DFHPF1`, `DFHPF3`, `DFHPF4`,
`DFHPF5`, `DFHPF6`, `DFHPF7`, `DFHPF8`, `DFHPF12`. Dez teclas.

Do `DFHBMSCA`: apenas `DFHBMBRY` (122 ocorrencias) -- o atributo de
intensidade alta usado para destacar campo em erro. Os dois
copybooks precisam ser reescritos localmente, com os mesmos nomes,
para o codigo compilar sem alteracao.

### 1.6 Mapsets e mapas

Oito mapsets, um mapa por mapset, todos `SIZE=(24,80)` menos o
`SFPM09` (janela `SIZE=(18,54)`):

| Mapset | Mapa | Fonte BMS | Linhas |
|---|---|---|---|
| `SFPM00` | `MAPMENU` | `bms/SFPM00.bms` | 141 |
| `SFPM01` | `MAPEMP` | `bms/SFPM01.bms` | 216 |
| `SFPM02` | `MAPMOV` | `bms/SFPM02.bms` | 256 |
| `SFPM03` | `MAPEVEN` | `bms/SFPM03.bms` | 145 |
| `SFPM04` | `MAPEMPR` | `bms/SFPM04.bms` | 216 |
| `SFPM05` | `MAPCARG` | `bms/SFPM05.bms` | 316 |
| `SFPM06` | `MAPDOMI` | `bms/SFPM06.bms` | 315 |
| `SFPM09` | `MAPLOOK` | `bms/SFPM09.bms` | 123 |

As estruturas simbolicas correspondentes ja existem em
`copy/SFPM0*.cpy` -- ou seja, metade do trabalho do `DFHMAPS` ja
esta feita a mao no repositorio. Falta o **mapa fisico**, que no
mainframe e um load module e aqui pode ser um JSON gerado pelo
parser dos `.bms`.

### 1.7 Arquivos VSAM referenciados pelo online

`SFPEVE` (rubricas), `SFPEST` (estabelecimentos), `SFPCAR` (cargos),
`SFPDOM` (dominios), `SFPUFE` (UF) e `SFPMUN` (municipios). Todos
tem massa correspondente em `dados/*.DAT`, hoje em formato
`LINE SEQUENTIAL` de registro fixo. Falta a chave: no online eles
sao KSDS, e o `SFP0900` browseia por chave parcial.

### 1.8 Uso de DB2

Somente dois programas: `SFP0100` (8 blocos `EXEC SQL`, mais
`INCLUDE SFPDEMP` e `INCLUDE SQLCA`) e `SFP0120` (13 blocos, mais
`INCLUDE SFPDMOV`, `INCLUDE SQLCA`, um cursor `CURMOV` com `OPEN`,
`FETCH` e `CLOSE`). Os outros seis programas online nao usam SQL.

Isso permite uma implantacao em etapas: os programas sem DB2
(`SFP0000`, `SFP0110`, `SFP0130`, `SFP0140`, `SFP0160`, `SFP0900`)
podem rodar antes de existir qualquer banco relacional no ambiente.

## 2. As cinco rotas possiveis

### 2.1 Hercules com MVS 3.8j (TK4- ou TK5)

O Hercules e um emulador de System/370, ESA/390 e z/Architecture,
open source, que roda em Linux, macOS e Windows, e existem imagens
Docker comunitarias com a distribuicao TK4- ou TK5 pre-instalada.
Sobe em minutos e da um mainframe de verdade, com JES2, TSO, ISPF e
JCL funcionando.

**Nao serve para este projeto**, por dois motivos independentes:

1. Nao ha CICS licenciavel para MVS 3.8j. O sistema operacional e
   de dominio publico porque a IBM liberou versoes de 1974-1981; o
   CICS nunca foi liberado. Nao existe versao legal e gratuita.
2. O compilador COBOL disponivel nesse ambiente e o OS/VS COBOL,
   que nao aceita a sintaxe usada aqui. `EVALUATE`, `INITIALIZE`,
   `PERFORM ... END-PERFORM`, escopo com `END-IF`, `FUNCTION
   LENGTH` e referencia `(inicio:tamanho)` sao COBOL 85 ou
   posterior. O fonte teria de ser reescrito, e o objetivo do
   ambiente e justamente executar o fonte como esta.

Vale como laboratorio de JCL e utilitarios (`IEBGENER`, `IDCAMS`,
`SORT`), nao como ambiente do SFP.

### 2.2 IBM ZD&T, Wazi as a Service ou IBM Z Xplore

O **ZD&T** (Z Development and Test Environment) emula z/Architecture
em x86 e permite rodar z/OS, CICS, DB2 e o COBOL for z/OS de
verdade, com licenca da IBM, tanto o produto quanto os sistemas
hospedados. E a rota de maior fidelidade fora de um mainframe
fisico. Distribui-se como imagem para instalacao em Linux e ha
material da IBM sobre execucao em container e em nuvem. Custo por
licenca, nao ha versao gratuita.

O **Wazi as a Service** e a mesma ideia entregue como servico na
IBM Cloud, cobrado por consumo.

O **IBM Z Xplore** e gratuito: da acesso remoto a um z/OS real com
COBOL, JCL, DB2 e (em alguns modulos) CICS, para aprendizado. Nao e
um ambiente que se controla, nao se instala nada, nao se define
transacao propria com liberdade e nao ha garantia de disponibilidade
para um projeto. Serve para conferir se um fonte compila no
compilador de verdade -- o que, para este repositorio, e um uso
legitimo e barato: os oito programas online nunca passaram pelo
tradutor CICS real.

Antes de decidir por qualquer um dos tres, confirme condicoes e
precos atuais com a IBM. Os termos mudam.

### 2.3 Rehosting comercial (CICS emulado sobre Linux)

Ha produtos que executam COBOL CICS em Linux ou Windows, sem
mainframe, reimplementando a API do CICS e o BMS. Os principais:
OpenText (ex-Micro Focus) Enterprise Server, Heirloom Computing,
TmaxSoft OpenFrame, Fujitsu NetCOBOL com sua camada de rehosting, e
AWS Mainframe Modernization (que oferece tanto o motor da
Micro Focus quanto o Blu Age).

Sao os ambientes onde o codigo deste projeto rodaria com menos
mudanca fora do mainframe, e todos suportam Docker ou Kubernetes de
forma documentada. Sao tambem licenciados, com precos corporativos,
e alguns exigem contrato antes do acesso ao instalador. Se o
contexto for corporativo e houver orcamento, esta e a rota que
entrega mais rapido. Se o contexto for estudo, e inviavel.

### 2.4 GnuCOBOL com shim CICS caseiro (recomendada aqui)

Constroi-se um container com GnuCOBOL, um pre-processador que
traduz `EXEC CICS` em chamadas de subprograma, e um modulo
`SFPCICS` que implementa os dezenove verbos do inventario. As telas
sao pintadas em um terminal de texto a partir dos `.bms`. Os
arquivos VSAM viram arquivos `ORGANIZATION INDEXED` do GnuCOBOL.

E a unica rota que reune tres propriedades desejaveis ao mesmo
tempo: custo zero, execucao local em Docker, e -- o ponto decisivo
-- **nenhuma alteracao nos fontes COBOL**. O codigo continua sendo
COBOL CICS de mainframe; quem se adapta e o ambiente.

Custo: e software a ser escrito. A estimativa da secao 4 e de
alguns milhares de linhas de Python mais dois copybooks e um
programa driver. Nao e um fim de semana, mas tambem nao e um
produto: o escopo esta fechado pelo inventario da secao 1.

### 2.5 Reescrever o online sem CICS

Descartada. Transformar os programas em COBOL batch interativo ou
em servico web destroi exatamente o que o repositorio demonstra
(pseudoconversacao, COMMAREA, BMS, `FRSET`). Nao e simulacao de
ambiente, e outro sistema.

### 2.6 Comparativo

| Rota | Custo | Fidelidade | Docker | Fonte muda? |
|---|---|---|---|---|
| Hercules + MVS 3.8j | zero | alta, mas sem CICS | sim | sim, muito |
| ZD&T / Wazi | licenca | total | parcial | nao |
| IBM Z Xplore | zero | total, sem controle | nao | nao |
| Rehosting comercial | licenca | alta | sim | pouco |
| GnuCOBOL + shim | zero | media | sim | **nao** |

## 3. Rota recomendada em detalhe

O ambiente tem seis componentes. Nomes propostos entre parenteses.

### 3.1 Pre-processador CICS (`tools/traduzir_cics.py`)

Le um fonte de `cobol/` e escreve em `build/cics/` uma versao em
COBOL puro. Cada bloco `EXEC CICS ... END-EXEC` e substituido por
um preenchimento de area de parametros mais um `CALL 'SFPCICS'`.
Papel equivalente ao do tradutor `DFHECP1$` no mainframe.

Regras que o tradutor precisa cobrir:

- Reconhecer o bloco entre `EXEC CICS` e `END-EXEC`, que pode
  ocupar varias linhas e sempre respeita a coluna 72.
- Trocar `DFHRESP(nome)` pela constante correspondente.
- Expandir `RESP(campo)` em um `MOVE` do codigo de retorno do shim
  para o campo indicado.
- Gerar, no inicio da `WORKING-STORAGE`, o `COPY SFPWCIC` com a
  area de parametros, e no `PROCEDURE DIVISION` a `COPY` da
  `DFHEIBLK` simulada.
- Emitir codigo que respeite a coluna 72 (o gerador de codigo mais
  o validador `awk 'length>72'` do `CLAUDE.md`).

Um detalhe critico: `XCTL` e `RETURN TRANSID` **nao podem** ser
apenas `CALL`. Ambos abandonam o programa. A traducao correta e
gravar o destino na area de parametros e emitir `GOBACK` logo
depois da chamada, deixando ao driver a decisao do que executar em
seguida. Isso reproduz com exatidao o modelo pseudoconversacional,
onde cada interacao e uma tarefa nova.

### 3.2 Modulo shim (`SFPCICS`, escrito em COBOL ou em C)

Implementa os verbos. Por area:

**Terminal e BMS.** `SEND MAP` recebe a estrutura de saida
(`MAPEMPRO` e similares) e o mapa fisico, e pinta as 24 linhas.
`ERASE` limpa antes; `DATAONLY` preserva os literais; `CURSOR`
posiciona; `ALARM` emite bipe; `FREEKB` e ruido no emulador de
texto. `RECEIVE MAP` faz o inverso: le a tela editada e preenche
`MxxxL` (comprimento digitado, zero se o campo nao foi tocado),
`MxxxF` e `MxxxI`. E aqui que se decide a fidelidade do ambiente:
com `CTRL=(FREEKB,FRSET)` o `RECEIVE` do CICS devolve **somente os
campos digitados**, e os demais chegam em `LOW-VALUES`. O shim tem
de reproduzir esse comportamento, senao os programas passam a
funcionar no simulador de um jeito que nao funcionaria no
mainframe -- e o valor do ambiente cai a zero. `MAPFAIL` quando a
tela volta sem nenhum campo alterado.

**Controle de arquivo.** `READ`, `READ UPDATE`, `WRITE`,
`REWRITE`, `DELETE`, `STARTBR`, `READNEXT`, `READPREV`, `ENDBR`
sobre arquivos `ORGANIZATION INDEXED ACCESS DYNAMIC` do GnuCOBOL.
`RIDFLD` mais `GTEQ` corresponde a `START ... KEY IS >=`; `EQUAL`
a `KEY IS =`. `NOTFND` e o `AT END` ou status 23; `DUPREC` e o
status 22. O `RIDFLD` do CICS e atualizado com a chave do registro
lido: o shim precisa devolve-la, porque o `SFP0900` depende disso
para paginar.

**Armazenamento temporario.** `WRITEQ TS`, `READQ TS` e
`DELETEQ TS` sobre um dicionario em memoria do processo driver,
indexado pelo nome da fila. Como o `SFP0130` usa `MAIN`, a
semantica correta e exatamente essa: memoria volatil, nao
recuperada pelo `SYNCPOINT ROLLBACK`. Se algum dia algum programa
usar `AUXILIARY`, a implementacao passa a exigir arquivo.

**Controle de programa.** `XCTL` e `RETURN` conforme a secao 3.1.
`PGMIDERR` quando o modulo pedido nao existe em `build/cics/`.

**Data e hora.** `ASKTIME` preenche `EIBDATE` e `EIBTIME`;
`FORMATTIME` formata. Ambos triviais com `FUNCTION CURRENT-DATE`.

**Recuperacao.** `SYNCPOINT` e `SYNCPOINT ROLLBACK` sem transacao
real: sem DB2 ou VSAM recuperavel embaixo, o rollback nao tem o que
desfazer. Implementar como no-op registrado em log e **documentar
como limitacao**, para nao induzir a conclusao errada de que a
recuperacao foi testada.

**Tratamento de erro.** `HANDLE ABEND LABEL(...)` e o caso mais
dificil de emular com honestidade, porque depende de o ambiente
interceptar o abend. Em GnuCOBOL um erro grave termina o processo.
O caminho pragmatico e o driver capturar a morte do modulo e
registrar, sem executar o `LABEL`. Tambem uma limitacao a
documentar.

### 3.3 Gerador de mapa fisico (`tools/compilar_bms.py`)

Le `bms/*.bms` e produz, para cada mapa, um JSON com a geometria:
para cada `DFHMDF`, a posicao (`POS`), o comprimento (`LENGTH`), os
atributos (`ATTRB`), o texto inicial (`INITIAL`) e o nome do campo
quando existir. Equivale a metade `TYPE=MAP` do `DFHMAPS`; a metade
`TYPE=DSECT` ja esta em `copy/SFPM0*.cpy`.

Uma consequencia agradavel: esse parser detecta sozinho tres
pendencias ja registradas no `CLAUDE.md` -- o `LENGTH=45` com
literal de 46 caracteres no `SFPM01.bms` (item 8), os rotulos
`F4=LISTA` ausentes no `SFPM04` (item 4) e as colunas do cabecalho
sem `DFHMDF` correspondente no `SFPM05` e no `SFPM06` (itens 9 e
11). Cruzar o JSON gerado com os campos declarados no copybook
simbolico e uma validacao equivalente a que o
`tools/gerar_dicionario.py` faz para os copybooks de dados.

### 3.4 Driver de transacao (`SFPDRIV`)

O laco principal do ambiente, em Python ou COBOL:

1. Le a transacao inicial da linha de comando (`SF01`, `SF05`...).
2. Resolve transacao para programa por uma tabela em
   `conf/transacoes.txt` -- o equivalente local da `PCT` e da `PPT`
   do CICS, e um bom lugar para documentar o que hoje esta
   espalhado nos comentarios dos fontes.
3. Chama o modulo com `EIBCALEN = 0` e COMMAREA vazia.
4. Ao retorno, examina o que o shim registrou: `RETURN TRANSID`
   com COMMAREA (espera nova tecla e chama de novo, com
   `EIBCALEN` preenchido), `XCTL` (chama outro modulo, mesma
   COMMAREA, sem passar pelo terminal) ou `RETURN` simples
   (encerra).

`EIBTRMID` pode ser um valor fixo por instancia do container, por
exemplo `T001`. O `SFP0130` usa `EIBTRMID(4:4)` para compor o nome
da fila temporaria, entao qualquer valor de quatro bytes serve.

### 3.5 Carga inicial dos arquivos (`tools/carregar_vsam.py`)

Converte `dados/SFPEVE.DAT`, `SFPEST.DAT`, `SFPCAR.DAT`,
`SFPDOM.DAT`, `SFPUFE.DAT` e `SFPMUN.DAT` de sequencial de registro
fixo para os arquivos indexados. Equivale ao `IDCAMS DEFINE
CLUSTER` mais `REPRO` do JCL. O `SFPMUN` precisa tambem do indice
alternativo por UF mais nome (`SFPMUNA` no mainframe), que em
GnuCOBOL e `ALTERNATE RECORD KEY ... WITH DUPLICATES`.

Atencao a um requisito de instalacao: GnuCOBOL so trata
`ORGANIZATION INDEXED` se foi compilado com um backend ISAM
(Berkeley DB ou VBISAM). Conferir com `cobc --info` e olhar a
linha do handler de arquivo indexado antes de assumir que funciona.

### 3.6 Camada SQL (opcional, fase posterior)

Para `SFP0100` e `SFP0120` e preciso um pre-compilador de SQL
embutido para GnuCOBOL. Ha dois projetos conhecidos: **GixSQL**
(suporta PostgreSQL, MySQL, SQLite e ODBC) e **ocesql** (voltado a
PostgreSQL). Os DCLGEN em `dclgen/` servem como estruturas host sem
alteracao; o `SQLCA` vem do proprio pre-compilador.

O DDL de `ddl/` precisa ser adaptado: storage group, database,
tablespace particionado, `CCSID` e clausulas `IN db.ts` sao
especificos do DB2 for z/OS e nao existem no PostgreSQL. O mais
pratico e manter `ddl/` como documentacao do alvo real e gerar um
DDL de simulacao a parte, em `ddl/local/`, com as mesmas colunas e
constraints.

Existem tambem imagens do **Db2 Community Edition** para Linux, que
reduzem a diferenca de dialeto SQL, embora nao eliminem: Db2 LUW
nao e Db2 for z/OS.

### 3.7 Terminal

Duas opcoes, na ordem de esforco:

1. **Terminal de texto 24x80** com `curses`: o driver pinta a tela
   e le as teclas, mapeando F1 a F12 e `Clear` para os codigos do
   `DFHAID`. Suficiente para exercitar toda a logica dos programas.
2. **Servidor TN3270** implementando o data stream 3270, para
   conectar com `c3270` ou `x3270` de verdade. Muito mais fiel
   (MDT, atributos, campos protegidos, insercao, cursor real),
   muito mais trabalho. Vale se o objetivo for demonstrar
   comportamento 3270, nao apenas rodar a logica.

Comecar pela opcao 1. A fronteira entre driver e terminal deve ser
uma interface estreita (pintar tela, ler tecla) para que trocar
pela opcao 2 depois nao mexa no shim.

## 4. Esboco do Dockerfile

```dockerfile
FROM debian:12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        gnucobol4 libdb-dev python3 python3-curses make \
        x3270-common c3270 \
    && rm -rf /var/lib/apt/lists/*

# Confirmar que o indexed handler existe nesta build:
RUN cobc --info | grep -i "indexed"

WORKDIR /sfp
COPY . /sfp

ENV COB_LS_FIXED=1
ENV COB_COPY_DIR=/sfp/copy

RUN python3 tools/traduzir_cics.py       \
 && python3 tools/compilar_bms.py        \
 && python3 tools/carregar_vsam.py       \
 && ./build/build.sh                     \
 && ./build/build_online.sh

ENTRYPOINT ["python3", "tools/sfpdriv.py"]
CMD ["SF00"]
```

Notas sobre o esboco:

- O nome do pacote GnuCOBOL varia por distribuicao (`gnucobol`,
  `gnucobol3`, `gnucobol4`); ajustar conforme a base escolhida.
- `COB_LS_FIXED=1` continua obrigatorio, pelo mesmo motivo do
  batch: registro fixo em `LINE SEQUENTIAL`.
- Os arquivos indexados devem ficar em volume, nao na imagem, senao
  toda inclusao feita pelas telas se perde ao recriar o container.
- Se a camada SQL entrar, e melhor `docker compose` com dois
  servicos (aplicacao e banco) do que um container unico.

## 5. Plano em fases

Cada fase termina com algo demonstravel, e nenhuma exige a
seguinte.

**Fase 0 -- validacao de premissas.** Confirmar que o GnuCOBOL
instalado suporta `ORGANIZATION INDEXED` e que a massa de
`dados/*.DAT` carrega em arquivo indexado sem perda. Se essa fase
falhar, todas as outras mudam.

**Fase 1 -- BMS. Feita.** `tools/validar_bms.py` monta os
statements logicos respeitando a continuacao de coluna 72, confere
o layout (POS na tela, campo que invade a linha, campos
sobrepostos contando o byte de atributo, INITIAL maior que o
LENGTH, PICOUT incompativel com o LENGTH) e cruza cada mapa com o
`01` correspondente de `copy/SFPM0*.cpy`. `--json` despeja o parse
e `--resumo` so a contagem por categoria; o codigo de retorno e 1
quando ha erro, o que serve de porta antes de commit.

Rodada de estreia: 438 erros. A marca de continuacao saia na
coluna 71 nos quatro mapsets gerados (322 linhas), a grade do
`SFPM05` passava da coluna 80, e sobraram 26 achados nos tres
mapas escritos a mao -- ver `docs/PENDENCIAS.md`.

**Fase 2 -- shim minimo e `SFP0000`.** Pre-processador,
`SFPCICS` com `SEND MAP`, `RECEIVE MAP`, `RETURN TRANSID`, `XCTL`
e os quatro campos do EIB, mais o driver com terminal de texto.
Alvo: o menu `SFP0000` pintando e navegando. E o programa mais
simples do conjunto e o unico que so precisa dessas cinco coisas.

**Fase 3 -- controle de arquivo.** Acrescentar `READ`,
`READ UPDATE`, `WRITE`, `REWRITE`, `DELETE` e a carga dos
indexados. Alvo: `SFP0110` (rubricas) e `SFP0130` (empresa)
completos, incluindo as filas TS que o `SFP0130` usa.

**Fase 4 -- browse.** `STARTBR`, `READNEXT`, `READPREV`, `ENDBR`.
Alvo: `SFP0900` (a janela F4) e, com ele, `SFP0140` e `SFP0160`.
Neste ponto seis dos oito programas online rodam.

**Fase 5 -- SQL.** GixSQL ou ocesql mais banco, DDL local e carga.
Alvo: `SFP0100` e `SFP0120`.

**Fase 6 -- fidelidade (opcional).** Servidor TN3270 para uso com
`c3270`, e reexame de `HANDLE ABEND` e `SYNCPOINT`.

## 6. Limitacoes do ambiente proposto

Estas limitacoes precisam ficar visiveis a quem usar o container,
porque o risco de um simulador nao e ele falhar: e ele funcionar de
um jeito que o mainframe nao funcionaria.

1. **Recuperacao nao e testada.** Sem gerenciador transacional,
   `SYNCPOINT ROLLBACK` nao desfaz gravacao. Um bug de rollback
   nao aparece aqui.
2. **`HANDLE ABEND` nao executa o label.** O tratador de abend dos
   programas fica sem exercicio.
3. **Sem concorrencia.** Um terminal, uma tarefa. `ENQ`, `DEQ`,
   deadlock, `READ UPDATE` concorrente e timeout de tarefa nao
   existem. O `READ UPDATE` do shim nao segura registro.
4. **Sem seguranca.** Nao ha RACF, nem verificacao de transacao por
   usuario.
5. **VSAM aproximado.** `ORGANIZATION INDEXED` do GnuCOBOL nao e
   KSDS: `CI`/`CA`, split, `SHAREOPTIONS`, `AIX` com upgrade e
   `PATH` nao tem equivalente. Chave, ordem e browse tem.
6. **Dialeto SQL diferente.** Se a camada SQL usar PostgreSQL, uma
   consulta pode passar no simulador e falhar no `BIND` do DB2 for
   z/OS -- especialmente `FETCH FIRST`, funcoes escalares,
   `ISOLATION` e `WITH UR`.
7. **EBCDIC ausente.** Tudo roda em ASCII. Ordenacao de caracteres
   difere do mainframe (em EBCDIC minusculas precedem maiusculas e
   digitos vem depois das letras). Qualquer regra que dependa de
   comparacao de caracteres tem de ser reavaliada.
8. **Sem 3270 real na primeira versao.** MDT, insercao, campos
   protegidos e cursor sao aproximados pelo terminal de texto.

Regra de ouro: o ambiente serve para **desenvolver e demonstrar**,
nao para certificar. A conclusao de que um programa funciona no
z/OS continua exigindo o tradutor CICS e o compilador de verdade --
o que reforca o valor da rota 2.2 como conferencia pontual, mesmo
que a rota 2.4 seja a de trabalho diario.

## 7. Recomendacao

Montar o container da rota 2.4 em fases, comecando pela fase 0 e
pela fase 1, que dao retorno independente de todo o resto: a fase 1
sozinha ja fecha quatro pendencias de BMS registradas no
`CLAUDE.md`.

Em paralelo, e sem custo, submeter os oito programas online a um
tradutor CICS real via IBM Z Xplore, uma vez, para saber se o
codigo compila no ambiente que ele diz ter como alvo. Hoje isso
nunca foi verificado, e nenhum simulador vai verificar.
