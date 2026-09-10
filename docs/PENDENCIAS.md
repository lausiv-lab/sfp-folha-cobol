# Pendencias Conhecidas

Detalhamento dos itens listados de forma resumida no `CLAUDE.md`.
Cada item traz o sintoma, a causa e o que a correcao exige. A
numeracao acompanha a do `CLAUDE.md`.

## 1. DDL e DCLGEN das seis tabelas novas

Os programas online criados depois do `SFP0120` trabalham sobre
VSAM: `SFPEVE`, `SFPEST`, `SFPCAR`, `SFPDOM`, `SFPDPT`, `SFPUFE` e
`SFPMUN`. As tabelas DB2 equivalentes nao existem em `ddl/`, e nao
ha DCLGEN em `dclgen/` para elas.

Nao e bug: o desenho decidiu que esses cadastros ficam em arquivo.
A pendencia e de completude da camada DB2 documentada, caso se
queira o mesmo cadastro consultavel por SQL.

## 2. SFPM04 sem rotulo F4=LISTA nas linhas 8 e 18

O `SFP0130` implementa F4 em tres campos: UF (linha 10), tipo de
logradouro (linha 8) e banco pagador (linha 18). Somente o da UF
tem rotulo `F4=LISTA` no mapa. Os outros dois funcionam, mas o
usuario nao tem como saber.

Corrigir em `tools/gerar_bms.py`, nunca no `.bms`, que e gerado.

## 3. Sete campos do SFPWEST sem campo no SFPM04

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

## 4. SFPM05 tem coluna CH no cabecalho e nao tem DFHMDF

O cabecalho e o tracejado da grade do `SFPM05` reservam a coluna
`CH` (carga horaria mensal), mas nao existe `DFHMDF` para ela: a
grade termina no teto salarial. Duas saidas, ambas em
`tools/gerar_bms.py`: criar o campo (e o `SFP0140` passa a manter
`CAR-CARGA-HOR-MES` pela tela) ou remover o rotulo.

Hoje o `SFP0140` assume 220 na inclusao e preserva o valor na
alteracao.

## 5. SFPM05 sem coluna de situacao

Como a grade nao tem onde exibir nem alterar `CAR-SITUACAO`, o
`SFP0140` exclui fisicamente (`EXEC CICS DELETE`) em vez de marcar
`CAR-SITUACAO = 'E'`. Marcar sem exibir seria pior: o registro
desapareceria da grade sem forma de reverter pela tela.

Corrigir e acrescentar a coluna no gerador e trocar o `DELETE` por
`REWRITE` com a situacao, mais o filtro de exibicao.

## 6. SFPM06 sem coluna para DOM-IND-SISTEMA

A grade de dominios nao mostra quais registros sao de sistema; ha
apenas o aviso fixo na linha 21. O usuario descobre que o dominio e
protegido quando o `SFP0160` recusa a acao (RN08). Uma coluna `SIS`
protegida em `tools/gerar_bms.py` resolveria.

## Resolvidos

Registro do que ja foi corrigido, para nao se reabrir a analise.

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
