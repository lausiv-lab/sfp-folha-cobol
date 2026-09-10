# Otimizacao de Tokens da Sessao

Este documento existe porque o custo de uma sessao de agente nao e
dominado pelo que ele escreve, e sim pelo que ele relê. Registra o
metodo de medicao, os numeros de referencia deste projeto e o que
ja esta configurado, para que ninguem tenha de redescobrir.

## A conta que importa

O custo de uma sessao e, aproximadamente:

```
contexto medio por turno  x  numero de turnos
```

O contexto inteiro e reenviado a cada turno. Com prompt caching
ele vai como leitura de cache, bem mais barato que entrada nova,
mas o volume continua sendo o volume. Numa medicao real deste
projeto, a leitura de cache respondeu por **97% de todos os
tokens movimentados**.

Disso decorrem tres alavancas, e so tres:

1. **Baixar o piso** -- o que ja esta no contexto antes de
   qualquer trabalho.
2. **Impedir o contexto de inchar** -- nao despejar arquivo grande
   nele, e compactar quando crescer.
3. **Tirar trabalho do contexto principal** -- delegar leitura
   ampla a subagentes, cujo contexto morre com eles.

## Como medir

Cada sessao grava um `.jsonl` em
`~/.claude/projects/<slug-do-projeto>/`. O bloco `usage` de cada
mensagem do assistente traz os contadores.

```bash
python3 - <<'PY'
import json, glob, os
base = os.path.expanduser('~/.claude/projects/<slug>')
f = sorted(glob.glob(base + '/*.jsonl'), key=os.path.getmtime)[-1]
tin = tout = tcr = trd = n = 0
for linha in open(f):
    try: d = json.loads(linha)
    except: continue
    u = (d.get('message') or {}).get('usage')
    if not u: continue
    n += 1
    tin += u.get('input_tokens', 0)
    tout += u.get('output_tokens', 0)
    tcr += u.get('cache_creation_input_tokens', 0)
    trd += u.get('cache_read_input_tokens', 0)
print(f'turnos={n} out={tout} cache_write={tcr} cache_read={trd}')
print(f'contexto medio por turno = {trd // max(n, 1)}')
PY
```

O contexto do primeiro turno (soma dos tres contadores de entrada)
e o **piso**: o que se paga sempre, mesmo sem fazer nada.

## Numeros de referencia (medidos em 09/2026)

| Metrica | Valor |
|---|---|
| Piso, antes de qualquer trabalho | 45.130 tokens |
| Turnos numa sessao longa | 136 |
| Leitura de cache acumulada | 12.062.945 |
| Escrita de cache | 321.879 |
| Saida | 139.012 |
| Contexto medio relido por turno | ~88.700 |

A distancia entre o piso (45.130) e a media (88.700) e o inchaco:
a sessao dobrou de tamanho e ninguem a cortou.

Composicao aproximada do piso: conectores MCP da conta (o de
design declara sozinho cerca de 50 ferramentas e um bloco de
instrucoes), lista de agentes disponiveis, os dois `CLAUDE.md`
(este projeto pesa ~1.650 tokens; o global, ~550) e os hooks de
sessao. Cada token aqui e pago uma vez por turno.

## O que esta configurado neste projeto

**`.claude/settings.json`** -- lista de permissoes dos comandos
rotineiros (geradores, build, run, e as ferramentas de leitura).
Isso corta idas e vindas de aprovacao; economiza tempo de sessao,
nao tokens.

**`.claude/agents/inspetor-tela.md`** -- investigador read-only de
mapas BMS. Carrega de uma vez a convencao de coluna do 3270, o
orcamento de linha de grade, onde cada mapa e gerado e as
armadilhas de `FSET`/`FRSET`. Sem ele, cada investigacao exige
repetir 40 linhas de instrucao no prompt do subagente.

**`.claude/agents/conferente-cadeia.md`** -- roda a cadeia do zero
e devolve o veredito da triangulacao, nao o log. Usa modelo
pequeno: a tarefa e mecanica.

**`CLAUDE.md` enxuto** -- as secoes "Estado atual" e "Pendente"
eram inventario e duplicavam `docs/PENDENCIAS.md`. Inventario
envelhece sozinho e o lugar dele e a fonte viva (`ls cobol/`,
`git log`). Viraram ponteiro. O que era desenho nao obvio -- por
que `SFP0130` e `SFP0100` usam fila TS -- migrou para
"Convencoes obrigatorias", onde evita bug em vez de so informar.

## O que depende de configuracao global, fora deste repositorio

**Desabilitar conectores MCP nao usados** (`/mcp` no Claude Code).
E a maior economia estrutural disponivel: sai do piso e vale para
toda sessao de todo projeto. Manter ligado so o que se usa de
fato.

**Ligar o auto-compact** (`autoCompactEnabled`). Compactar custa
uma chamada cara e derruba o cache; nao compactar custa a
diferenca entre o contexto inchado e o piso em **todos** os turnos
seguintes. Com mais de dois turnos pela frente, compactar ganha.

## Habitos que pesam mais que qualquer configuracao

- **Ler pedaco, nao arquivo.** `sed -n '120,160p'` em vez de abrir
  um fonte de 1.500 linhas. O fonte inteiro fica no contexto ate o
  fim da sessao.
- **Delegar leitura ampla.** Um subagente que varre seis arquivos
  e devolve meia pagina custa os tokens dele uma vez; ler os seis
  no contexto principal custa em cada turno restante. Foi por isso
  que quatro subagentes gastando 487 mil tokens sairam mais
  baratos que a alternativa.
- **Pedir veredito, nao log.** Instrua o subagente a nao colar
  saida de execucao. O relatorio dele entra no seu contexto.
- **Nao reconferir o que ja foi conferido.** Reler um arquivo para
  "ter certeza" paga o preco de novo e raramente muda a resposta.
