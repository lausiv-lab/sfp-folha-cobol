#!/usr/bin/env python3
"""Gera docs/DICIONARIO-DADOS.md a partir dos copybooks reais.
Evita divergencia entre documentacao e codigo: a fonte da verdade
sao os proprios arquivos .cpy."""
import re, os, glob

RAIZ = os.path.join(os.path.dirname(__file__), '..')
COPY = os.path.join(RAIZ, 'copy')

DESC = {
 'SFPWEMP': ('Cadastro de empregados', 'SFPEMP', 500),
 'SFPWDEP': ('Dependentes do empregado', 'SFPDEP', 80),
 'SFPWEVE': ('Cadastro de eventos / rubricas', 'SFPEVE', 80),
 'SFPWMOV': ('Movimento mensal lancado', 'SFPMOV', 100),
 'SFPWPON': ('Apuracao do ponto', 'SFPPON', 80),
 'SFPWTAB': ('Tabelas legais e parametros', 'SFPTAB', 80),
 'SFPWFOL': ('Folha calculada, detalhe por evento', 'SFPFOL', 120),
 'SFPWRES': ('Resumo da folha por empregado', 'SFPRES', 250),
 'SFPWRSC': ('Solicitacao de rescisao (entrada)', 'SFPRSCI', 80),
 'SFPWCTB': ('Interface contabil de partidas dobradas','SFPCTB',150),
 'SFPWDOM': ('Tabela generica de dominios', 'SFPDOM', 80),
 'SFPWUFE': ('Unidades da federacao', 'SFPUFE', 80),
 'SFPWMUN': ('Municipios (codigo IBGE)', 'SFPMUN', 80),
 'SFPWCAR': ('Cadastro de cargos', 'SFPCAR', 120),
 'SFPWDPT': ('Cadastro de departamentos', 'SFPDPT', 120),
 'SFPWEST': ('Empresa e estabelecimentos', 'SFPEST', 480),
 'SFPWTRB': ('Area de comunicacao com SFP0310', '-', 0),
 'SFPWUTL': ('Area de comunicacao com SFPUTIL', '-', 0),
 'SFPWCOM': ('COMMAREA das transacoes CICS', '-', 512),
 'SFPWCON': ('Constantes corporativas e codigos', '-', 0),
 'SFPWCAB': ('Linhas padrao de cabecalho de relatorio','-', 0),
}

def tamanho(pic):
    """Devolve o numero de bytes ocupados por uma clausula PICTURE.

    Trata corretamente casos como 9(001)V9999, em que a parte
    decimal vem escrita por extenso e nao entre parenteses."""
    if pic.startswith('S'):
        pic = pic[1:]
    pic = pic.replace('V', '')
    t = 0
    for m in re.finditer(r'([9XAZ])\((\d+)\)|([9XAZ]+)', pic):
        if m.group(2):
            t += int(m.group(2))
        else:
            t += len(m.group(3))
    return t

def analisar(caminho):
    linhas, pos, itens = open(caminho).read().split('\n'), 1, []
    for ln in linhas:
        if len(ln) > 6 and ln[6] == '*':
            continue
        m = re.match(r'\s+(\d\d)\s+([\w-]+)\s+PIC\s+([\w()V.-]+?)\s*\.', ln)
        if m:
            nivel, nome, pic = m.group(1), m.group(2), m.group(3)
            tam = tamanho(pic.rstrip('.'))
            itens.append((nivel, nome, pic.rstrip('.'), pos, tam))
            pos += tam
            continue
        m = re.match(r'\s+(\d\d)\s+([\w-]+)\s*\.\s*$', ln)
        if m and m.group(1) != '01':
            itens.append((m.group(1), m.group(2), '(grupo)', pos, 0))
    return itens, pos - 1

saida = []
w = saida.append
w('# Dicionario de Dados - Sistema SFP')
w('')
w('> Documento gerado automaticamente por `tools/gerar_dicionario.py`')
w('> a partir dos copybooks em `copy/`. Nao editar a mao: recompile')
w('> o dicionario apos qualquer alteracao de layout.')
w('')
w('> Nota sobre o DD `SFPRSC`: o programa SFP0350 grava nesse DD o')
w('> *detalhe calculado* da rescisao no layout `SFPWFOL` (LRECL 120),')
w('> e nao no layout `SFPWRSC`. O copybook `SFPWRSC` descreve a')
w('> *solicitacao* de rescisao, lida pelo DD `SFPRSCI`.')
w('')
w('## Indice dos arquivos')
w('')
w('| Copybook | DDNAME | LRECL | Conteudo |')
w('|---|---|---|---|')
for nome in sorted(DESC):
    d, dd, lr = DESC[nome]
    w(f'| `{nome}` | `{dd}` | {lr if lr else "-"} | {d} |')
w('')

for caminho in sorted(glob.glob(os.path.join(COPY, 'SFPW*.cpy'))):
    base = os.path.basename(caminho)[:-4]
    itens, total = analisar(caminho)
    if not itens:
        continue
    d, dd, lr = DESC.get(base, ('-', '-', 0))
    w(f'## {base} - {d}')
    w('')
    if dd != '-':
        w(f'DDNAME `{dd}` - LRECL {lr} - organizacao sequencial.')
        w('')
    w('| Niv | Campo | PICTURE | Ini | Fim | Tam |')
    w('|---|---|---|---|---|---|')
    for nivel, nome, pic, ini, tam in itens:
        fim = ini + tam - 1 if tam else ''
        w(f'| {nivel} | `{nome}` | `{pic}` | {ini if tam else ""} '
          f'| {fim} | {tam if tam else ""} |')
    w('')
    w(f'**Somatorio dos campos: {total} bytes.**')
    if lr and total != lr:
        w(f' ATENCAO: divergente do LRECL declarado ({lr}).')
    w('')

destino = os.path.join(RAIZ, 'docs', 'DICIONARIO-DADOS.md')
os.makedirs(os.path.dirname(destino), exist_ok=True)
open(destino, 'w').write('\n'.join(saida) + '\n')
print(f'Gerado {destino} com {len(saida)} linhas.')
