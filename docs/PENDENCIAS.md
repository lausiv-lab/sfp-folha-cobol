# Pendencias Conhecidas

Cada item traz o sintoma, a causa e o que a correcao exige. Rode
`python3 tools/validar_bms.py --resumo` antes de atacar qualquer
item de mapa: os numeros abaixo saem dali.

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

## 2. Sete campos de menu do SFPM00 sobrepoem a coluna direita

Achado do validador, nao catalogado antes. Os itens da coluna
esquerda do menu tem `LENGTH=45` (linhas 53, 56, 59, 62, 87, 90 e
93 do `.bms`), o que leva os dados ate a coluna 49; a coluna
direita comeca com o byte de atributo na 45. O assembler BMS
recusa campos que se sobrepoem.

O literal ocupa 43 das 45 posicoes, entao nao basta baixar o
`LENGTH`: cabem 39 posicoes ate o atributo da coluna direita. Ou o
literal encurta ('11 - EMPRESA E ESTABELEC. .... SF05'), ou as
duas colunas do menu se reorganizam. `SFPM00.bms` e escrito a mao.

## 3. PICOUT maior que o LENGTH no SFPM01 e no SFPM02

Dezessete campos declaram um `PICOUT` com uma posicao a mais que o
`LENGTH` do proprio campo: `SALARIO`, `VLRVT`, `VLRVR`, `VLRPS`,
`PERPEN`, `VLRPEN` e `VLRCON` no `SFPM01`, e `VALO1` a `VALOA` no
`SFPM02` (`LENGTH=13` com `'ZZZ.ZZZ.ZZ9,99'`, que ocupa 14). Quem
escreveu contou o mascaramento sem um dos separadores.

Corrigir e escolher, campo a campo, entre alargar o `LENGTH` --
so onde a linha da tela tiver folga -- e reduzir a mascara em um
digito. Os dois mapas sao escritos a mao.

## 4. Rodape do SFPM01 truncado

Linha 209 do `SFPM01.bms`: `LENGTH=79` com literal de 85
caracteres. A tela perde o final, ' F12=CANCELAR', justamente a
tecla de cancelamento.

## 5. MTOTAL do SFPM02 com tamanho divergente no copybook

`MTOTAL` tem `LENGTH=14` no mapa e nenhum `PICIN`, mas
`copy/SFPM02.cpy` declara `MTOTALI PIC 9(009)V99`, de 11
posicoes -- enquanto `MTOTALO` tem as 14 certas
(`ZZZ.ZZZ.ZZ9,99`). O campo de entrada desalinha o que vem depois
dele na area simbolica.

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
