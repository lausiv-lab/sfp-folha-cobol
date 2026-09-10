# SFP - Sistema de Folha de Pagamento (COBOL Mainframe)

Simulacao completa de um sistema corporativo de folha de
pagamento para ambiente z/OS: COBOL batch e CICS, mapas BMS,
DB2, JCL e PROCs, com massa de dados ficticios e saidas reais.

Os programas batch **compilam e executam de verdade** sob
GnuCOBOL. Os modulos online e o SQL embutido sao codigo
mainframe legitimo, mas exigem o tradutor CICS e o
precompilador DB2, indisponiveis fora do z/OS.

## Numeros do projeto

| Componente | Arquivos | Linhas |
|---|---|---|
| Programas COBOL | 10 | 7.732 |
| Copybooks e estruturas BMS | 18 | 1.242 |
| Mapas BMS | 2 | 472 |
| JCL e PROCs | 7 | 472 |
| DDL, DCLGEN, SQL e cards | 11 | 961 |
| Ferramentas Python | 3 | 548 |
| Documentacao | 4 | 924 |

## Resultado da execucao (competencia 08/2026, 60 empregados)

| Programa | Resultado | RC |
|---|---|---|
| `SFP0200` critica | 68 lidos, 64 aceitos, 4 rejeitados | 04 |
| `SFP0300` calculo | 60 calculados, 695 eventos, 7 criticas | 04 |
| `SFP0350` rescisao | 1 TRCT emitido | 00 |
| `SFP0400` contabil | 190 partidas, debito igual a credito | 00 |
| `SFP0500` holerite | 60 contracheques em 27 paginas | 00 |
| `SFP0600` CNAB240 | 64 registros de 240 bytes | 00 |

**Triangulacao independente:** o liquido do resumo, o saldo
credor da conta contabil de folha a pagar e o total da remessa
bancaria fecham nos mesmos **R$ 278.548,14**, apurados por tres
programas que nao compartilham codigo de calculo.

## Comecando

```bash
./build/build.sh      # compila os modulos batch
./build/run.sh        # executa a cadeia completa
```

As saidas aparecem em `saidas/`: holerites, remessa bancaria,
termo de rescisao, razao contabil e logs de critica.

## Onde olhar primeiro

| Interesse | Arquivo |
|---|---|
| Motor de calculo | `cobol/SFP0300.cbl` |
| Legislacao (INSS, IRRF, FGTS) | `cobol/SFP0310.cbl` |
| Tela de cadastro CICS | `cobol/SFP0100.cbl` + `bms/SFPM01.bms` |
| Contabilizacao | `cobol/SFP0400.cbl` |
| Regras implementadas | `docs/REGRAS-NEGOCIO.md` |
| Como operar | `docs/MANUAL-OPERACAO.md` |
| Layouts de arquivo | `docs/DICIONARIO-DADOS.md` |
| Visao geral tecnica | `docs/ARQUITETURA.md` |

## Aviso

Massa de dados inteiramente ficticia, gerada com semente fixa
por `tools/gerar_massa.py`. Nomes, CPFs, contas bancarias e
salarios sao sinteticos. As tabelas legais reproduzem valores
plausiveis para fins de demonstracao e **nao devem ser usadas
para calculo real** sem conferencia com a legislacao vigente.
