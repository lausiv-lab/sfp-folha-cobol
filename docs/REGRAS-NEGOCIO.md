# Regras de Negocio do Sistema SFP

Referencia das regras implementadas, com o ponto exato do codigo
onde cada uma vive. Os valores legais sao parametrizados na
tabela `SFPTAB` (tipo `PAR`) e nao estao gravados no codigo.

## 1. Parametros vigentes na massa de teste (competencia 08/2026)

| Parametro | Valor |
|---|---|
| Salario minimo | 1.518,00 |
| Deducao por dependente (IRRF) | 189,59 |
| Desconto simplificado (IRRF) | 607,20 |
| Aliquota FGTS | 8% |
| Teto do vale-transporte | 6% do salario |
| Adiantamento salarial | 40% |
| Margem consignavel | 35% |
| Adicional noturno | 20% |
| Adicional de periculosidade | 30% |
| Quinquenio | 5% a cada 1.826 dias |
| Contribuicao sindical | 1% |

### Tabela do INSS (progressiva por faixa)

| Faixa ate | Aliquota |
|---|---|
| 1.518,00 | 7,5% |
| 2.793,88 | 9% |
| 4.190,83 | 12% |
| 8.157,41 | 14% |

Teto da contribuicao: 951,63.

### Tabela do IRRF

| Base ate | Aliquota | Deducao |
|---|---|---|
| 2.428,80 | isento | - |
| 2.826,65 | 7,5% | 182,16 |
| 3.751,05 | 15% | 394,16 |
| 4.664,68 | 22,5% | 675,49 |
| acima | 27,5% | 908,73 |

## 2. Calculo do INSS (`SFP0310`, funcao `INSS`)

O desconto e progressivo: cada faixa incide **apenas sobre a
parcela da remuneracao que cai dentro dela**, e nao sobre o total.

Detalhe de implementacao relevante para conferencia: o programa
acumula o valor **arredondado faixa a faixa**, nao ao final. Um
auditor que arredonde so no fim encontrara diferencas de
centavos. Essa escolha foi mantida por espelhar o comportamento
da folha de referencia usada na homologacao.

## 3. Calculo do IRRF (`SFP0310`, funcao `IRRF`)

O programa calcula os **dois regimes** e adota o de menor
retencao, devolvendo em `TRB-MSG-RETORNO` o metodo aplicado:

- **Deducoes legais (`L`)**: base = remuneracao tributavel
  menos INSS, menos pensao alimenticia, menos 189,59 por
  dependente de IRRF.
- **Desconto simplificado (`S`)**: base = remuneracao tributavel
  menos 607,20, menos pensao alimenticia.
- **Isento (`I`)**: base abaixo da primeira faixa.

A pensao alimenticia e deduzida **nos dois regimes**, por ser
verba que nao ingressa na disponibilidade do trabalhador.

## 4. Proventos automaticos (`SFP0300`, secao 2100)

| Secao | Verba | Regra |
|---|---|---|
| 2120 | Salario do mes | Proporcional a admissao, demissao e afastamento |
| 2130 | Horas extras | 50% e 100%, com DSR sobre HE |
| 2140 | Adicional noturno | Fator 120/105 sobre a hora, com DSR |
| 2150 | Insalubridade | Percentual sobre o **salario minimo** |
| 2160 | Periculosidade | 30% do salario, com critica de acumulo |
| 2170 | Quinquenio | 5% a cada 1.826 dias de casa |

### 4.1 Salario de referencia para verbas percentuais

Regra que gerou correcao durante o desenvolvimento: verbas
percentuais (periculosidade, quinquenio, VT, adiantamento,
sindical e o tipo de calculo 004) **nao podem incidir sobre o
salario cadastral de horistas e diaristas**, porque nesses casos
o campo guarda o valor da hora ou do dia, nao o salario mensal.

O motor calcula `WS-SALARIO-REFER`:

- mensalista: salario base do cadastro;
- horista e diarista: valor-hora multiplicado pela carga horaria
  mensal.

Sem essa normalizacao, a periculosidade de um horista sairia
como 30% do valor da hora.

### 4.2 Nao acumulacao de insalubridade e periculosidade

Sao mutuamente excludentes (art. 193, paragrafo 2 da CLT). O
cadastro online (`SFP0100`) rejeita a combinacao na origem, e o
motor emite a critica `0221` caso o dado historico ja exista.

## 5. Tipos de calculo do movimento (`SFP0300`, secao 2200)

O campo `EVE-TIPO-CALCULO` da rubrica seleciona a formula:

| Tipo | Formula |
|---|---|
| 001 | Valor informado no lancamento |
| 002 | Horas x valor-hora x percentual |
| 003 | Dias x valor-dia |
| 004 | Percentual sobre o salario de referencia |
| 005 | Percentual sobre o salario minimo |
| 006 | Percentual sobre o total de proventos |
| 007 | Valor cadastrado no proprio empregado |
| 010 | Quantidade x valor unitario |

Tipos entre 100 e 199 sao reservados ao calculo automatico e
**recusam lancamento manual** (regra RN04 do `SFP0120`).

## 6. Descontos (`SFP0300`, secao 2700)

| Secao | Verba | Limite |
|---|---|---|
| 2710 | Vale-transporte | 6% do salario de referencia |
| 2720 | Vale-refeicao | Percentual de coparticipacao |
| 2730 | Plano de saude | Titular mais dependentes |
| 2740 | Consignado | Margem de 35% da remuneracao |
| 2750 | Adiantamento | 40% do salario |
| 2760 | Contribuicao sindical | 1%, so para sindicalizados |

Quando o consignado ultrapassa a margem, o motor **limita o
desconto** e emite a critica `0274`, em vez de recusar a folha.

## 7. Incidencias

Cada rubrica carrega seis flags (`INSS`, `IRRF`, `FGTS`, `DSR`,
`13o`, `ferias`) que alimentam as bases na secao 2400.

Decisao de projeto: **todos os eventos de desconto tem as flags
em `N`**. O INSS e a pensao entram na base do IRRF por dentro do
`SFP0310`, via `AREA-TRIBUTOS`. Se os descontos tambem
carregassem incidencia, haveria deducao em dobro.

## 8. Liquido negativo (`SFP0300`, secao 2850)

Se os descontos superam os proventos, o motor zera o liquido e
lanca a diferenca no evento `0551` (saldo devedor), que sera
recuperado na competencia seguinte. O `SFP0600` exclui da
remessa bancaria todo liquido menor ou igual a zero e registra
a exclusao no log.

## 9. Rescisao contratual (`SFP0350`)

| Verba | Regra |
|---|---|
| Saldo de salario | Dias trabalhados no mes |
| Aviso previo indenizado | 30 dias mais 3 por ano, teto de 90 |
| 13o proporcional | Avos do ano civil, projetados pelo aviso |
| Ferias proporcionais | Avos mais um terco constitucional |
| Multa do FGTS | 40% sobre o saldo mais o FGTS da rescisao |

**Verbas indenizatorias** (aviso previo indenizado e ferias
indenizadas) ficam **fora das bases de INSS e IRRF**. O INSS
sobre o 13o e apurado em separado, com tabela propria.

Regra que gerou correcao: o 13o e as ferias proporcionais usam o
**salario mensal equivalente**, nao o salario cadastral. Para
horistas, a versao inicial produzia um 13o de R$ 15,89 no lugar
de R$ 3.496,35.

Motivos aceitos (posicao 35 do cartao SYSIN):

| Codigo | Motivo | Aviso | Multa 40% |
|---|---|---|---|
| 1 | Sem justa causa | sim | sim |
| 2 | Pedido de demissao | nao | nao |
| 3 | Justa causa | nao | nao |
| 4 | Termino de contrato | nao | nao |

## 10. Criticas do calculo

| Codigo | Descricao | Efeito |
|---|---|---|
| 0110 | Empregado admitido no mes | Informativa |
| 0221 | Insalubridade e periculosidade acumuladas | Informativa |
| 0222 | Evento inexistente na tabela | Evento ignorado |
| 0274 | Consignado limitado a margem | Valor ajustado |

Criticas geram `RC=04`, que **nao interrompe** a cadeia: cabe ao
analista avaliar o relatorio antes de liberar o pagamento.

## 11. Regras do cadastro online (`SFP0100`)

Dezessete validacoes, entre elas: CPF por modulo 11 com rejeicao
de digitos repetidos, PIS por modulo 11, coerencia entre data de
admissao e demissao, piso salarial por tipo de salario, limite de
dependentes, e a nao acumulacao de insalubridade com
periculosidade.

## 12. Regras do lancamento online (`SFP0120`)

| Regra | Descricao |
|---|---|
| RN01 | Competencia deve estar aberta |
| RN02 | Matricula existente e nao demitida |
| RN03 | Rubrica existente e ativa |
| RN04 | Rubrica automatica recusa lancamento manual |
| RN05 | Coerencia entre unidade e conteudo informado |
| RN06 | Sem duplicidade de evento na competencia |
| RN07 | Horas extras limitadas a 44 no mes |
| RN08 | Descontos ate 70% da remuneracao |

## 13. Regras do cadastro de cargos (`SFP0140`)

| Regra | Descricao |
|---|---|
| RN01 | Codigo do cargo entre 0001 e 9999 |
| RN02 | Descricao obrigatoria |
| RN03 | CBO com 6 digitos; a familia sao os 4 primeiros |
| RN04 | Nivel em `O`, `T`, `E`, `G` ou `D` |
| RN05 | Piso nao pode ficar abaixo do salario minimo |
| RN06 | Teto nao pode ficar abaixo do piso |
| RN07 | Inclusao nao pode duplicar codigo existente |
| RN08 | Alteracao e exclusao exigem cargo ja cadastrado |
| RN09 | Nao se exclui cargo com empregado nao demitido |

O salario minimo da RN05 vem de `TB_TABELA_LEGAL`
(`TIPO_TABELA = 'PAR'`, `CHAVE = 'SALARIO-MINIMO'`), com
1518,00 como valor de emergencia se a consulta falhar. A RN09
conta em `TB_EMPREGADO` os vinculos com `SITUACAO <> 'D'`.

A grade critica as doze linhas antes de gravar qualquer uma
delas: erro em qualquer linha aborta a gravacao inteira, para a
tela nao ficar meio gravada por erro de digitacao na ultima
linha. Se a aplicacao falhar no meio, `SYNCPOINT ROLLBACK`
desfaz o que ja tinha sido gravado.

Carga horaria mensal e os indicadores de insalubridade,
periculosidade e confianca nao tem campo no mapa `SFPM05`: na
inclusao recebem 220 e `N`, e na alteracao sao preservados como
estavam no registro.

## 14. Regras das tabelas de dominio (`SFP0160`)

| Regra | Descricao |
|---|---|
| RN01 | Tipo de dominio obrigatorio e cadastrado no `TIP` |
| RN02 | Codigo obrigatorio na linha com acao |
| RN03 | Descricao obrigatoria |
| RN04 | Ordem de exibicao entre 001 e 999 |
| RN05 | Situacao em `A` ou `I` |
| RN06 | Inclusao nao pode duplicar codigo dentro do tipo |
| RN07 | Alteracao e exclusao exigem dominio ja cadastrado |
| RN08 | Dominio de sistema nao aceita alteracao nem exclusao |

Todos os dominios moram em `SFPDOM` (VSAM KSDS), com chave
`DOM-TIPO` mais `DOM-CODIGO`. A tela trata um tipo por vez e o
browse para quando `DOM-TIPO` muda.

O tipo informado e criticado contra o **meta-dominio** `TIP`, que
tem um registro por tipo existente (`DOM-CODIGO` igual ao tipo,
`DOM-DESCRICAO` igual ao nome da tabela). Dai vem tambem a
descricao exibida no campo protegido ao lado do tipo, e a tecla
F4 chama o `SFP0900` com `LOK-TIPO-DOMINIO = 'TIP'`.

A RN08 le `DOM-IND-SISTEMA`. Os dominios protegidos sao gerados
com `S` por `tools/gerar_dominios.py` (hoje `TIP`, `SEX`, `NAT`,
`UNI`, `TSA`, `SIT`, `TFO` e `TLA`): sao os que aparecem em
`EVALUATE` de programa ou em regra de calculo, e renomear ou
excluir um deles quebraria o batch.

Como no `SFP0140`, a grade critica as doze linhas antes de gravar
qualquer uma delas, e `SYNCPOINT ROLLBACK` desfaz o que ja tinha
sido aplicado se a segunda fase falhar.

Na inclusao, descricao e ordem sao obrigatorias; a reduzida
omitida sai dos 12 primeiros caracteres da descricao e a situacao
omitida sai como `A`. `DOM-IND-SISTEMA` nao tem coluna no mapa
`SFPM06`: na inclusao recebe `N` e na alteracao e preservado.

## 15. Regras do cadastro de rubricas (`SFP0110`)

| Regra | Descricao |
|---|---|
| RN01 | Codigo da rubrica entre 0001 e 9999 |
| RN02 | Descricao obrigatoria |
| RN03 | Natureza cadastrada no dominio `NAT` (`P`, `D`, `I`, `B`) |
| RN04 | Tipo de calculo implementado no motor |
| RN05 | Unidade cadastrada no dominio `UNI` |
| RN06 | Tipos 002 e 005 exigem percentual maior que zero |
| RN07 | Conta contabil obrigatoria em provento e desconto |
| RN08 | Desconto exige as seis incidencias em `N` |
| RN09 | Incidencias em `S` ou `N` |
| RN10 | Situacao em `A` ou `I` |
| RN11 | Inclusao nao pode duplicar codigo |
| RN12 | Consulta, alteracao e exclusao exigem rubrica cadastrada |
| RN13 | Rubrica citada pelo motor nao se exclui nem se inativa |

A rubrica e o seletor do motor: `EVE-TIPO-CALCULO` escolhe a
formula na secao 2220 do `SFP0300` e as seis incidencias dizem em
que bases o valor entra. A RN08 existe porque INSS e pensao
alimenticia ja entram na base do IRRF por dentro do `SFP0310`
(area `AREA-TRIBUTOS`): ligar as flags de um desconto causaria
deducao em dobro.

A RN13 percorre `CTE-EVENTOS-TAB` (copybook `SFPWCON`), a lista
dos codigos que o `SFP0300` e o `SFP0350` geram por conta
propria. Alterar descricao, conta e percentual desses codigos
continua permitido; excluir ou inativar, nao.

O percentual chega do BMS em campo numerico-editado `ZZ9,99`
alinhado a esquerda, des-editado na secao `7400-DE-EDITAR`. A
tecla F4 atende natureza (linha 5) e unidade (linha 7), decidido
pela linha do cursor em `EIBCPOSN`.

## 16. Regras do cadastro da empresa (`SFP0130`)

| Regra | Descricao |
|---|---|
| RN01 | Codigo do estabelecimento entre 0001 e 9999 |
| RN02 | O codigo 0001 e a matriz (tipo `M`); os demais, filiais (`F`) |
| RN03 | CNPJ obrigatorio, com 14 digitos |
| RN04 | Razao social obrigatoria |
| RN05 | Tipo de logradouro cadastrado no dominio `TLG` |
| RN06 | Logradouro, numero e bairro obrigatorios |
| RN07 | Municipio cadastrado no `SFPMUN` e da UF informada |
| RN08 | UF cadastrada e ativa no `SFPUFE` |
| RN09 | CEP obrigatorio, com 8 digitos |
| RN10 | CNAE obrigatorio; FPAS obrigatorio na matriz |
| RN11 | Aliquota RAT igual a 1,00, 2,00 ou 3,00 |
| RN12 | FAP de 0,5000 a 2,0000 |
| RN13 | Codigo e aliquota de terceiros andam juntos |
| RN14 | Simples e desoneracao em `S` ou `N`, nunca os dois em `S` |
| RN15 | Mes da data-base de 01 a 12 |
| RN16 | Dia de pagamento de 01 a 31 |
| RN17 | Banco pagador no dominio `BAN`, com agencia e conta |
| RN18 | Situacao em `A` ou `I`; a matriz 0001 nao se inativa |
| RN19 | Inclusao nao pode duplicar codigo |
| RN20 | Consulta, alteracao e exclusao exigem estabelecimento cadastrado |
| RN21 | Filial so entra se a matriz 0001 existir |
| RN22 | Exclusao exige consulta previa |

O codigo 0001 e sempre a matriz: dela saem o cabecalho dos
relatorios, o header do CNAB240 e os parametros herdados pelas
filiais. Por isso ela nao pode ser inativada nem excluida (RN18)
e nenhuma filial entra antes dela (RN21).

Filial pode deixar FPAS, RAT e FAP em zeros: o `SFP0300` busca
esses parametros na matriz. A gravacao avisa em mensagem, sem
recusar. Na matriz os tres sao obrigatorios (RN10, RN11, RN12).

RAT e FAP sao comparados em centesimos e decimos de milesimo
(`COMPUTE WS-ED-LIMITE = WS-ES-ALIRAT * 100`), para nao depender
de literal decimal em fonte com `DECIMAL-POINT IS COMMA`.

Sete campos do `SFPWEST` nao tem campo no mapa `SFPM04`
(inscricao municipal, e-mail, CNPJ e percentual do sindicato, dia
do adiantamento, digito da conta e data de inicio de atividade).
A alteracao grava sobre a imagem do `READ UPDATE` e os preserva;
a inclusao os deixa em zeros e brancos, menos o dia do
adiantamento, que nasce 20.

O F4 atende tipo de logradouro (linha 8), municipio e UF (ambos
na linha 10) e banco pagador (linha 18). A linha 10 abriga dois
campos com F4, e por isso o programa nao decide pela linha do
cursor: calcula a coluna com `FUNCTION MOD(EIBCPOSN, 80) + 1` e
trata coluna menor que 40 como municipio (com a UF da tela em
`LOK-UF-FILTRO`, para a janela listar so os municipios daquele
estado) e as demais como UF.

O codigo devolvido pela janela chega em `LOK-COD-SELECIONADO`, que
tem 7 bytes desde a inclusao do F4 de municipio -- o codigo do
IBGE tem 7 digitos. Como o campo de municipio do `SFPM04` e
numerico editado, o retorno passa por `3060-INTEIRO-DA-TELA`
antes de ir para `WS-ES-MUNIC`.

## 17. Regras contabeis (`SFP0400`)

| Fato | Debito | Credito |
|---|---|---|
| Provento | Despesa do evento | Folha a pagar |
| Desconto | Folha a pagar | Passivo do evento |
| FGTS 8% | Despesa FGTS | FGTS a recolher |
| INSS patronal 20% | Despesa CPP | INSS a recolher |
| RAT 2% | Despesa RAT | RAT a recolher |
| Terceiros 5,8% | Despesa terceiros | Terceiros a recolher |
| Provisao de 13o | Despesa provisao | Provisao a pagar |
| Provisao de ferias | Despesa provisao | Provisao a pagar |

Descontos cuja conta pertence ao grupo 3 (faltas, DSR sobre
faltas e atrasos) creditam a **propria conta de despesa**,
reduzindo-a, em vez de constituir passivo.

Duas conferencias fecham o processo:

1. Total de debitos igual ao total de creditos, sob pena de
   `RC=12` e interface considerada nao confiavel.
2. Saldo credor da conta `21110001` (folha a pagar) igual ao
   liquido do resumo, sob pena de `RC=04`.

A provisao de ferias inclui o terco constitucional, e os
encargos sobre as provisoes somam 35,8% (20% mais 2% mais 5,8%
mais 8% de FGTS).
