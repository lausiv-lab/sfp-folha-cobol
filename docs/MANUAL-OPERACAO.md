# Manual de Operacao do Sistema SFP

## 1. Execucao local (GnuCOBOL)

Requisitos: GnuCOBOL 3.x e Python 3.8 ou superior.

```bash
sudo apt-get install -y gnucobol      # se ainda nao instalado
cd SFPFOLHA
./build/build.sh                      # compila os modulos batch
./build/run.sh                        # roda a cadeia completa
```

Para regenerar a massa de dados ficticios:

```bash
python3 tools/gerar_massa.py
```

Para reconferir os calculos por um caminho independente:

```bash
python3 tools/auditar.py
```

### 1.1 Como o GnuCOBOL substitui as DD cards

No mainframe, `SELECT ARQ-EMPREGADO ASSIGN TO SFPEMP` resolve
pela DD card `//SFPEMP DD DSN=...`. Localmente, o GnuCOBOL le a
variavel de ambiente `DD_SFPEMP`. O `run.sh` faz esse mapeamento.

Duas configuracoes sao obrigatorias:

- `COB_LS_FIXED=1` - forca registro de tamanho fixo em arquivos
  `LINE SEQUENTIAL`, sem o qual os campos posicionais quebram.
- O nome do `FD` deve ser diferente do DDNAME (por isso
  `ARQ-EMPREGADO` e nao `SFPEMP`), senao o compilador acusa
  redefinicao.

### 1.2 E o online?

As transacoes CICS nao rodam localmente com o GnuCOBOL puro:
`EXEC CICS`, BMS e (em `SFP0100` e `SFP0120`) `EXEC SQL` exigem o
tradutor CICS e o precompilador DB2. `docs/AMBIENTE-SIMULADO.md`
descreve como montar um container que executa esses programas sem
alterar os fontes, e o que esse ambiente nao consegue reproduzir.

## 2. Execucao no mainframe

### 2.1 Sequencia mensal

| Ordem | Job | Funcao | Quando |
|---|---|---|---|
| 1 | `SFPJ0200` | Critica do movimento | Apos o fechamento do ponto |
| 2 | `SFPJ0300` | Calculo da folha | Apos analise das criticas |
| 3 | `SFPJ0400` | Fechamento contabil | Apos conferencia da folha |
| 4 | `SFPJ0500` | Holerites e CNAB240 | Dois dias uteis antes do pagamento |

O `SFPJ0100` (compilacao e bind) so roda em implantacao.

### 2.2 Cartoes de controle

**SFP0200 e SFP0300** (`SYSIN`):

```
 posicao  conteudo
 001-006  competencia AAAAMM
 008-008  tipo de folha (1=mensal 2=adiantamento 3/4=13o
          5=ferias 6=rescisao)
 010-015  centro de custo inicial
 017-022  centro de custo final
 024-024  simulacao (S/N)
 026-033  data de pagamento AAAAMMDD
```

Exemplo: `202608 1 000000 999999 N 20260805`

**SFP0400** (`SYSIN`):

```
 001-006  competencia AAAAMM
 008-008  tipo de folha
 010-017  data do lancamento contabil AAAAMMDD
 019-024  numero do lote contabil
 026-026  gerar provisoes (S/N)
```

Exemplo: `202608 1 20260831 000001 S`

**SFP0350** (`SYSIN`): usa o mesmo cartao do calculo, com o
motivo da rescisao na posicao 35.

## 3. Codigos de retorno

| RC | Significado | Acao |
|---|---|---|
| 00 | Execucao normal | Prosseguir |
| 04 | Concluido com criticas | Analisar relatorio e decidir |
| 08 | Erro de parametro ou arquivo | Corrigir e reexecutar |
| 12 | Erro grave, saida nao confiavel | Acionar o suporte |

`RC=04` no `SFP0200` e no `SFP0300` e esperado em operacao
normal: significa que houve lancamentos rejeitados ou criticas
informativas, nao falha de processamento.

`RC=12` no `SFP0400` indica partidas desbalanceadas. A interface
contabil **nao deve ser transmitida** nessa condicao.

## 4. Conferencias obrigatorias antes do pagamento

1. **Relatorio de criticas** (`SFPCRI`) - toda critica `0222`
   (evento inexistente) indica rubrica lancada e nao paga.
2. **Balanceamento contabil** (`SFP0400`) - debitos iguais a
   creditos e saldo da conta de folha a pagar igual ao liquido.
3. **Triangulacao** - o total da remessa CNAB240 deve ser
   identico ao liquido do resumo e ao saldo credor da conta
   `21110001`. Os tres numeros vem de programas independentes;
   se divergirem, ha erro em algum deles.

Na massa de teste os tres valores fecham em **278.548,14**.

## 5. Reinicio apos abend

Os jobs sao codificados com `RESTART=*` e passos independentes.
Procedimento:

1. Identificar o passo que abendou no JESLOG.
2. Excluir os datasets de saida daquele passo (`DISP=(NEW,CATLG)`
   nao sobrepoe dataset existente).
3. Submeter com `RESTART=nome-do-passo`.

O `SFPJ0300` faz backup da folha anterior no passo `P005BKP`
antes de qualquer gravacao, permitindo restaurar a competencia.

## 6. Transacoes online

| Transacao | Programa | Funcao |
|---|---|---|
| `SF01` | `SFP0100` | Cadastro de empregados |
| `SF03` | `SFP0120` | Lancamento de movimento |
| `SF04` | `SFP0110` | Cadastro de rubricas da folha |
| `SF05` | `SFP0130` | Cadastro da empresa e estabelecimentos |
| `SF06` | `SFP0140` | Cadastro de cargos e pisos salariais |
| `SF08` | `SFP0160` | Tabelas de dominio |

Teclas de funcao:

| Tecla | Acao |
|---|---|
| `ENTER` | Valida e preenche descricoes |
| `PF3` | Encerra a transacao |
| `PF4` | Abre a janela de consulta do campo |
| `PF5` | Carrega os dados da chave informada |
| `PF6` | Grava as alteracoes |
| `PF7` | Pagina anterior (telas de grade) |
| `PF8` | Pagina seguinte (telas de grade) |
| `PF12` | Limpa a tela e recomeca |

Na grade do `SF03`, a coluna de acao aceita `I` (incluir), `A`
(alterar), `E` (excluir) ou branco (linha inalterada).

Nos formularios `SF04` e `SF05` o campo de acao aceita `C`
(consultar), `I` (incluir), `A` (alterar) e `E` (excluir). O F5
carrega o registro da chave informada sem depender do campo de
acao. Digitar uma chave diferente da que esta em edicao limpa os
demais campos, para nao se gravar um registro com os dados do
anterior.

No `SF05`, exclusao exige consulta previa (RN22) e a matriz 0001
nao pode ser excluida nem inativada (RN18).

Ainda no `SF05`, a linha de municipio e UF tem F4 nos dois campos:
a janela que abre depende de onde esta o cursor. Com o cursor no
municipio a lista sai filtrada pela UF que estiver na tela, logo
convem informar a UF primeiro.

## 7. Fechamento da competencia

Para bloquear novos lancamentos, incluir na `SFPTAB` um registro
tipo `PAR` com chave `STATUS-COMPETEN`, competencia alvo e
descricao `F`. A regra RN01 do `SFP0120` passa a recusar
lancamentos naquela competencia.

## 8. Estrutura de diretorios

| Diretorio | Conteudo |
|---|---|
| `cobol/` | Fontes COBOL |
| `copy/` | Copybooks e estruturas simbolicas BMS |
| `bms/` | Fontes dos mapas BMS |
| `dclgen/` | DCLGEN das tabelas DB2 |
| `ddl/` | Definicao dos objetos DB2 |
| `sql/` | Consultas analiticas |
| `ctl/` | Cards de LOAD e REORG |
| `jcl/` | Jobs |
| `proc/` | Procedures cataloged |
| `dados/` | Massa de teste ficticia |
| `saidas/` | Resultados da execucao |
| `build/` | Executaveis e scripts locais |
| `tools/` | Utilitarios Python |
| `docs/` | Documentacao |
