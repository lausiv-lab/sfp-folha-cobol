# Arquitetura do Sistema SFP

Sistema de Folha de Pagamento em COBOL para ambiente mainframe
z/OS, com componentes batch (QSAM/DB2), online (CICS/BMS) e
persistencia relacional (DB2 for z/OS).

## 1. Visao geral

O SFP e organizado em tres camadas que se comunicam por arquivos
sequenciais e por tabelas DB2:

```
   CICS / BMS                 BATCH                    DB2
  +------------+        +---------------+        +------------+
  |  SFP0100   |        |   SFP0200     |        | TB_EMPRE.  |
  |  cadastro  |------->|   critica     |        | TB_EVENTO  |
  |            |        +-------+-------+        | TB_MOVIM.  |
  |  SFP0120   |                |                | TB_FOLHA   |
  |  movimento |                v                | TB_RESUMO  |
  +------------+        +---------------+        +------------+
                        |   SFP0300     |               ^
                        |   motor de    |               |
                        |   calculo     |               |
                        +-------+-------+               |
                                |                       |
              +-----------------+-----------------+     |
              v                 v                 v     |
        +-----------+    +-----------+    +-----------+ |
        |  SFP0400  |    |  SFP0500  |    |  SFP0600  | |
        | contabil  |    | holerite  |    |  CNAB240  | |
        +-----+-----+    +-----------+    +-----------+ |
              |                                         |
              +-----------------------------------------+
```

O SFP0350 (rescisao) roda em paralelo ao SFP0300, consumindo o
mesmo cadastro e as mesmas tabelas legais.

## 2. Inventario de modulos

### 2.1 Programas batch (compilam e executam com GnuCOBOL)

| Programa | Funcao | Chama |
|---|---|---|
| `SFP0200` | Critica e validacao do movimento mensal | - |
| `SFP0300` | Motor de calculo da folha | `SFP0310`, `SFPUTIL` |
| `SFP0350` | Rescisao contratual e emissao do TRCT | `SFP0310`, `SFPUTIL` |
| `SFP0400` | Fechamento contabil e partidas dobradas | - |
| `SFP0500` | Contracheque / espelho de pagamento | `SFPUTIL` |
| `SFP0600` | Remessa bancaria CNAB240 Febraban | - |

### 2.2 Subrotinas

| Modulo | Funcao | Interface |
|---|---|---|
| `SFP0310` | INSS, IRRF, FGTS, salario-familia | `SFPWTRB` |
| `SFPUTIL` | CPF, datas, avos, extenso, DV modulo 11 | `SFPWUTL` |

O `SFP0310` mantem as tabelas legais residentes entre chamadas
(nao usa `INITIAL`): carrega `SFPTAB` na primeira invocacao e
reaproveita em todas as demais, o que evita 60 releituras do
arquivo numa folha de 60 empregados.

### 2.3 Programas online (exigem tradutor CICS; alguns, DB2)

| Programa | Transacao | Mapset | Funcao |
|---|---|---|---|
| `SFP0100` | `SF01` | `SFPM01` | Cadastro de empregados |
| `SFP0110` | `SF04` | `SFPM03` | Cadastro de rubricas |
| `SFP0120` | `SF03` | `SFPM02` | Lancamento de movimento |
| `SFP0130` | `SF05` | `SFPM04` | Cadastro da empresa |
| `SFP0140` | `SF06` | `SFPM05` | Cadastro de cargos e pisos |
| `SFP0160` | `SF08` | `SFPM06` | Tabelas de dominio |
| `SFP0900` | -      | `SFPM09` | Janela de consulta (F4) |

Todos sao pseudoconversacionais: cada interacao termina com
`EXEC CICS RETURN TRANSID(...) COMMAREA(...)`, liberando a
tarefa entre um `SEND MAP` e o `RECEIVE MAP` seguinte. O estado
da sessao trafega na COMMAREA de 512 bytes (`SFPWCOM`).

`SFP0110`, `SFP0130`, `SFP0140` e `SFP0160` nao usam DB2 nem
SQL: leem e gravam VSAM pelos comandos de arquivo do CICS
(`SFPEVE`, `SFPEST`, `SFPCAR` e `SFPDOM`). `SFP0140` consulta
`TB_TABELA_LEGAL` apenas para o salario minimo da RN05.

O `SFP0130` e a excecao ao estado na COMMAREA: o estabelecimento
em edicao ocupa 372 bytes e nao cabe nos 326 que restam em
`COM-AREA-TRABALHO` a partir do byte 121, onde comeca o estado
proprio de cada programa (o `SFPWLOK` ocupa os 116 primeiros).
Ele guarda o estado em uma fila temporaria (`WRITEQ TS ... MAIN`)
com nome `'S13'` mais `EIBTRMID`, apagada no F3, no F12 e depois da
exclusao. Fila em MAIN nao e recuperavel, logo `SYNCPOINT
ROLLBACK` nao a desfaz: aceitavel, porque ela guarda digitacao,
nao dado confirmado.

O `SFP0160` mantem todas as tabelas de dominio em um arquivo
unico (`SFPDOM`), cuja chave e o tipo mais o codigo. O catalogo
dos tipos existentes fica no proprio arquivo, sob o tipo `TIP`
(meta-dominio): assim a tecla F4 do campo tipo usa o `SFP0900`
generico, e a critica do tipo informado e uma leitura de arquivo,
nao uma tabela codificada dentro do programa. Os registros do
`TIP` nascem com `DOM-IND-SISTEMA = 'S'` e a tela recusa alterar
ou excluir dominio de sistema, logo o catalogo nao se corrompe
pela propria manutencao. A lista de tipos vive em
`tools/gerar_dominios.py`, que aborta se algum tipo usado nos
dominios ficar fora do catalogo.

## 3. Fluxo de dados da folha mensal

1. **Coleta** - lancamentos chegam pelo online (`SFP0120`, origem
   `ONL`) ou por interfaces externas (origem `IMP`).
2. **Critica** (`SFP0200`) - separa o movimento em aceito
   (`SFPMOVA`) e rejeitado (`SFPMOVR`), com relatorio de log.
   O calculo consome **apenas** o movimento aceito.
3. **Calculo** (`SFP0300`) - casa quatro arquivos ordenados por
   matricula (cadastro, ponto, dependentes, movimento) e produz
   o detalhe por evento (`SFPFOL`) e o resumo por empregado
   (`SFPRES`).
4. **Contabilizacao** (`SFP0400`) - agrega a folha por conta
   contabil e centro de custo, apura encargos patronais e
   provisoes, e emite a interface de partidas dobradas.
5. **Distribuicao** - `SFP0500` emite os contracheques e
   `SFP0600` gera a remessa bancaria CNAB240.

## 4. Tecnica de matching multiplo (SFP0300)

O motor le quatro arquivos sequenciais em paralelo, todos
classificados por matricula. O cadastro e o arquivo mestre e
comanda o laco; os demais sao sincronizados por leitura
antecipada.

Um detalhe que gerou bug real durante o desenvolvimento: o
registro lido antecipadamente **nao pode compartilhar area com o
registro em processamento**. A versao inicial fazia
`INITIALIZE REG-PONTO` a cada empregado, destruindo o registro
ja lido do proximo. A solucao foi separar as areas:

- `REG-PONTO-E` fica no `FD` (registro generico de 80 bytes);
- `REG-PONTO` fica na `WORKING-STORAGE`;
- a secao 2020 copia `REG-PONTO-E` para `REG-PONTO` **antes** de
  avancar a leitura.

## 5. Persistencia DB2

Objetos definidos em `ddl/`:

- Storage group, database e quatro tablespaces (dois
  particionados por competencia).
- Oito tabelas com chaves primarias, estrangeiras e constraints
  de dominio.
- Doze indices, incluindo os de suporte as chaves estrangeiras.
- Tres views analiticas.

O acesso batch aos dados historicos usa `ISOLATION(UR)` para nao
bloquear o online. O `SFP0120` usa `ISOLATION(CS)` com `WITH CS`
explicito nas consultas de cadastro.

## 6. Decisao de arquitetura: arquivos vs DB2

O motor de calculo trabalha sobre arquivos sequenciais, nao
sobre DB2, por tres razoes:

1. **Desempenho** - o matching sequencial de quatro arquivos
   ordenados custa uma passagem por arquivo. A alternativa
   relacional exigiria um `FETCH` por empregado por tabela.
2. **Reprocessamento** - o insumo de uma folha fica congelado
   em arquivos, o que torna o recalculo auditavel e reproduzivel
   mesmo apos alteracoes no cadastro online.
3. **Restart** - em caso de abend, o job reinicia do passo, sem
   necessidade de rollback de milhares de linhas.

O DB2 recebe o **resultado** via utilitario `LOAD` (cards em
`ctl/`), servindo as consultas online e analiticas.
