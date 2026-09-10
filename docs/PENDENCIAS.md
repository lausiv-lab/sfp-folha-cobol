# Pendencias Conhecidas

Cada item traz o sintoma, a causa e o que a correcao exige. Rode
`python3 tools/validar_bms.py --resumo` antes de atacar qualquer
item de mapa: os numeros saem dali. A medicao atual e
`8 mapset(s): 0 erro(s), 0 aviso(s)`, com codigo de retorno 0 --
nenhum item aberto abaixo vem do validador.

## 1. Sete campos do SFPWEST sem campo no SFPM04

Nao aparecem na tela: inscricao municipal, e-mail, CNPJ do
sindicato, percentual de contribuicao sindical, dia do
adiantamento, digito da conta pagadora e data de inicio de
atividade.

Sao carregados pela massa e preservados pela alteracao -- o
`4500-MONTAR-REGISTRO` do `SFP0130` grava sobre a imagem lida pelo
`READ UPDATE`, sem `INITIALIZE`, exatamente para nao zerar esses
sete campos. Na inclusao, `EST-DIA-ADIANTAMENTO` recebe 20 e os
demais ficam em branco ou zero.

Corrigir e ampliar o mapa (nao ha espaco na tela atual: exigiria
segunda tela, como a que o SFP0100 ganhou) ou aceitar que sao
mantidos so por carga.

## Resolvidos

Registro do que ja foi corrigido, para nao se reabrir a analise.

**DDL e DCLGEN dos cadastros de apoio** (antigo item 1).
`ddl/SFPDDL04.sql` cria `TB_UF`, `TB_MUNICIPIO`, `TB_ESTABELEC`,
`TB_DEPARTAMENTO`, `TB_CARGO` e `TB_DOMINIO`; `ddl/SFPDDL05.sql`
traz indices e GRANTs. Os DCLGEN correspondentes estao em
`dclgen/`, mais `SFPDEVE.cpy` para a `TB_EVENTO`, que ja existia
no `SFPDDL02`. Os programas online continuam sobre VSAM: a camada
DB2 e documental.

**Marca de continuacao na coluna 71** (achado do validador).
`tools/gerar_bms.py` fechava as linhas continuadas com
`ljust(70)`, o que punha o `X` na coluna 71 em 322 linhas dos
quatro mapsets gerados. O assembler so continua o statement se a
coluna 72 nao estiver em branco.

**SFPM04 sem rotulo F4 nas linhas 8 e 18** (antigo item 2).
O tipo de logradouro ganhou o rotulo curto `F4` colado ao campo --
a linha nao comporta `F4=LISTA` inteiro sem encurtar o
logradouro -- e `NUMERO:` virou `NUM:` para o numero manter oito
posicoes. O banco pagador ganhou `F4=LISTA` inteiro, com agencia,
conta e dia de pagamento deslocados para a direita sem mudar de
tamanho.

**Grade do SFPM05 fora da tela, sem CH e sem situacao** (antigos
itens 4 e 5). Piso e teto passaram de treze para dez posicoes
(`Z(006)9,99`, ate 9.999.999,99), o que trouxe a ultima coluna da
82 para a 80 e abriu espaco para as duas colunas que faltavam. Com
a coluna `CH` o `SFP0140` so supoe 220 horas quando o campo vem
vazio; com a coluna `S` a exclusao virou logica -- a acao `E`
marca `CAR-SITUACAO` com `E` por `REWRITE`, e o cargo continua na
grade para poder voltar a `A`. Duas criticas novas: RN10 (carga
maior que zero) e RN11 (situacao em A ou E).

**SFPM06 sem coluna para DOM-IND-SISTEMA** (antigo item 6).
Coluna `SIS`, protegida, nas colunas 77 a 79. O `SFP0160` a
preenche em `3850-REG-PARA-LINHA` e nas doze secoes de pintura. O
indicador continua sem entrar pela tela.

**Codigo de municipio truncado** (antigo item 3).
`LOK-COD-SELECIONADO` do `copy/SFPWLOK.cpy` passou de `PIC X(006)`
para `PIC X(007)`, e `AREA-LOOKUP` cresceu de 115 para 116 bytes.
O estado proprio dos chamadores mora em
`COM-AREA-TRABALHO(121:...)`, portanto o deslocamento continua
livre. Os campos `LCODn` do `SFPM09` e o `WS-LN-CODIGO` do
`SFP0900` acompanharam o alargamento. O `SFP0130` passou a oferecer
F4 de municipio: a linha 10 do `SFPM04` abriga dois campos com F4,
municipio na coluna 16 e UF na coluna 62, e o programa separa os
dois pela coluna do cursor (`FUNCTION MOD(EIBCPOSN, 80) + 1`).

**F4 nao devolvia a selecao** (defeito descoberto na correcao
acima, nao catalogado antes).
O `SFP0900` remonta a grade a partir da tela em `2100-RECEBER`,
lendo `LCODnI` e `LDESnI`. Os campos estavam declarados no
`SFPM09.bms` como `ATTRB=(PROT,NORM)`, sem `FSET`. Campo protegido
nunca recebe o Modified Data Tag por digitacao, logo o `RECEIVE
MAP` devolvia LOW-VALUES e toda selecao voltava com codigo e
descricao vazios -- para qualquer tipo de dominio, nao so
municipio. Corrigido com `FSET` nos 20 campos (`LCODn` e `LDESn`
das 10 linhas).

**Browse de estabelecimento** (antigo item 6).
Nova secao `3800-BROWSE-ESTAB` no `SFP0900`, sobre `FILE('SFPEST')`
com `RIDFLD(EST-CHAVE)`, espelhada na `3400-BROWSE-DEPTO`. Descarta
`EST-SITUACAO NOT = 'A'`, usa `EST-NOME-FANTASIA` como descricao
(ou `EST-RAZAO-SOCIAL` quando em branco) e leva `EST-TIPO` na
coluna auxiliar. O tipo `'EST'` entrou no dispatcher `3100`.

**WS-IX sem inicializacao** (antigo item 7).
`2200-PAGINA-ANTERIOR` do `SFP0900` agora zera `WS-IX` antes do
`PERFORM UNTIL`.

**Chave de reposicionamento por tipo de dominio.**
As secoes `2200` e `2300` montavam a chave de reposicionamento a
partir de `WS-LN-CODIGO`, o que nao serve para municipio: o browse
usa o indice alternativo `SFPMUNA` (UF mais nome). Passaram a
escolher pelo tipo -- `WS-LN-DESCR(...)(1:9)` quando
`LOK-TIPO-DOMINIO = 'MUN'`, `WS-LN-CODIGO` nos demais casos -- e a
`3500-BROWSE-MUNICIPIO` descarta o registro que serviu de
reposicionamento.

**Segunda tela e F4 do SFP0100** (antigo item 1).
O `SFPM01.bms` ganhou o mapa `MAPEMP2` (dados pessoais, documentos,
endereco, contato e lotacao), com o simbolico correspondente em
`copy/SFPM01.cpy` -- 82 campos nomeados, mapa e simbolico
conferidos um contra o outro. Os dados novos vivem na tabela
`SFPADM.TB_EMPREGADO_COMPL` (DDL em `ddl/SFPDDL02.sql`, indice e
GRANT em `ddl/SFPDDL03.sql`, DCLGEN em `dclgen/SFPDEMC.cpy`), nao no
`SFPWEMP`, que continua sendo o layout VSAM do batch.

O estado das duas telas (`WS-ESTADO`) soma 500 bytes -- 50 de
controle, 206 da copia crua da primeira tela e 244 da segunda ja
criticada -- contra os 326 que sobram da `COM-AREA-TRABALHO` depois
do `SFPWLOK`. Por isso o `SFP0100` guarda o estado em fila
temporaria (`WRITEQ TS ... MAIN`, nome `'S01'` mais `EIBTRMID`),
como o `SFP0130` ja fazia. Navegacao por F9 nos dois sentidos, F6
grava os complementares e F3/F12 apagam a fila.

O F4 atende 21 campos: cinco na primeira tela (situacao, cargo,
departamento, tipo de salario, banco) e dezesseis na segunda. Onde
uma linha da tela abriga mais de um campo com lista, a escolha sai
da coluna do cursor (`FUNCTION MOD(EIBCPOSN, 80) + 1`), como no
`SFP0130`. Municipio -- de nascimento e de residencia -- vai
filtrado pela UF que estiver na tela. Os 18 tipos de dominio usados
ja existiam no dispatcher do `SFP0900`.

**SFPM01.bms linha 47: LENGTH=45 com literal de 46** (antigo item
5). O `LENGTH` passou a 46, igual ao literal
`'(C=CONSULTA I=INCLUSAO A=ALTERACAO E=EXCLUSAO)'`.

**Sete campos de menu do SFPM00 sobrepoem a coluna direita**
(antigo item 2). A colisao era geometrica: item da coluna esquerda
em `POS=(lin,5)` com `LENGTH=45` ocupa as colunas 5 a 50, e o da
direita abria o byte de atributo na 46 -- cinco colunas de
cruzamento nas linhas de tela 5, 6, 7, 8, 11, 12 e 13. Encurtar o
leader de pontos resolveria cinco itens, mas
`13 - DEPARTAMENTOS E CENTROS DE CUSTO` e
`34 - ABERTURA E FECHAMENTO DE COMPET.` tem 37 caracteres e nenhum
ponto para tirar. A saida nao mexeu em texto: esquerda para
`POS=(lin,3)`/`LENGTH=43` e direita para `POS=(lin,47)`/`LENGTH=32`,
faixas 3-46 e 47-79. Os itens perdem duas colunas de recuo e os
dois lados ficam com `LENGTH` igual ao literal, sem folga -- quem
alargar uma descricao volta a sobrepor. Os quinze campos sao
`DFHMDF` anonimos, portanto `copy/SFPM00.cpy` nao mudou, e o
`SFP0000` tambem nao, porque o roteamento vive na
`WS-TABELA-OPCOES`. Os rotulos de cabecalho continuam alinhados
para a geometria antiga; o desalinhamento e cosmetico, o validador
nao o checa e nao foi corrigido. Commit `a9593da`.

**PICOUT maior que o LENGTH no SFPM01 e no SFPM02** (antigo item
3). Os dezessete campos tinham duas causas opostas, medidas uma a
uma. No `SFPM02` o `PICOUT` estava certo: `PICIN` e o
`WS-LN-VALOR PIC 9(009)V99` do `SFP0120` confirmam nove digitos
inteiros, logo `VALO1` a `VALOA` passaram de `LENGTH=13` para 14 e
empurraram `TIPOn` (59 para 60), `ORIGn` (61 para 62) e o stopper
`ASKIP` (65 para 66) nas dez linhas de grade, com o terminador da
linha indo de 65 para 66. No `SFPM01`, `SALARIO` (11 para 14) e
`PERPEN` (05 para 06, que nao contava a virgula) eram so largura
de tela curta, mas nos cinco campos de valor (`VLRVT`, `VLRVR`,
`VLRPS`, `VLRPEN`, `VLRCON`) o errado era a mascara:
`'ZZZ.ZZ9,99'` mostrava seis digitos inteiros contra os sete que
`PICIN='9(7)V99'`, o `PIC 9(007)V99` do `SFP0100` e o
`DECIMAL(9,2)` da tabela pedem -- valor a partir de
R$ 1.000.000,00 saia truncado no digito das centenas de milhar.
Viraram `'Z.ZZZ.ZZ9,99'` com `LENGTH=12`, e os cinco campos `*O`
do copybook acompanharam. As colunas das linhas de tela 11, 14 e
15 foram realocadas; a 14 passa a terminar na coluna 80, o limite
exato, sem folga -- troca deliberada por exibir a amplitude real.
Nenhum programa mudou: `SFP0120` e `SFP0100` referenciam os campos
por nome, nunca pela largura fisica. No `SFPM02` os rotulos de
cabecalho da grade ficaram um caractere fora do lugar sobre as
colunas deslocadas; e cosmetico, o validador nao checa e nao foi
corrigido. Commits `e28c722` (SFPM02) e `1244891` (SFPM01).

**Rodape do SFPM01 truncado** (antigo item 4). O `INITIAL` das
teclas de funcao tinha 85 caracteres em `LENGTH=79`, e 79 ja e o
teto fisico da linha 23 -- nao havia como alargar. Os separadores
de espaco duplo entre as teclas viraram simples, o que da
exatamente 79 e devolve o ` F12=CANCELAR` que se perdia.
Commit `1244891`.

**MTOTAL do SFPM02 com tamanho divergente no copybook** (antigo
item 5). Campo so-protegido, sem `PICIN`: a area de entrada tem de
ser `X(length)`, e nao a imagem numerica do dado. `MTOTALI` estava
`PIC 9(009)V99`, onze bytes contra o `LENGTH=14` do mapa, e
desalinhava o que vinha depois na area simbolica. Virou
`PIC X(014)`; `MTOTALO` ja tinha as catorze certas.
Commit `e28c722`.
