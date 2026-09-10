#!/usr/bin/env python3
"""Validador estatico dos mapas BMS (Fase 1 de docs/AMBIENTE-SIMULADO.md).

Le os fontes de bms/, monta cada statement logico respeitando a
continuacao de coluna 72, e confere o que o assembler BMS conferiria
no mainframe -- mais as convencoes proprias deste repositorio:

  * marca de continuacao fora da coluna 72;
  * espaco de padding entrando dentro de literal continuado;
  * POS fora da tela declarada em DFHMDI;
  * campo (byte de atributo mais dados) estourando a tela;
  * campos que se sobrepoem, contando o byte de atributo;
  * INITIAL maior que o LENGTH declarado;
  * nome de campo repetido no mesmo mapa;
  * mapa contra o copybook simbolico de copy/: campo faltando de um
    lado ou de outro, e PIC do campo de entrada diferente do LENGTH.

Uso:
    python3 tools/validar_bms.py                 # valida bms/*.bms
    python3 tools/validar_bms.py bms/SFPM05.bms  # valida um fonte
    python3 tools/validar_bms.py --resumo        # so a contagem por tipo
    python3 tools/validar_bms.py --json          # despeja o parse

Sai com codigo 1 se houver ERRO, 0 se so houver AVISO ou nada.
"""

import glob
import json
import os
import re
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COL_CONT = 72          # coluna da marca de continuacao
COL_RETOMA = 16        # coluna em que a continuacao retoma
TELA_PADRAO = (24, 80)


class Achado:
    def __init__(self, arquivo, linha, nivel, texto):
        self.arquivo = arquivo
        self.linha = linha
        self.nivel = nivel
        self.texto = texto

    def __str__(self):
        rel = os.path.relpath(self.arquivo, RAIZ)
        return '%s:%d: %s: %s' % (rel, self.linha, self.nivel, self.texto)


CATEGORIAS = [
    ('marca de continuacao', 'continuacao fora da coluna 72'),
    ('literal continuado preenchido', 'espaco de padding dentro de literal'),
    ('fora da tela', 'POS fora da tela'),
    ('passa da coluna', 'campo invade a linha seguinte'),
    ('estoura o fim da tela', 'campo estoura o fim da tela'),
    ('sobrepoe o campo', 'campos sobrepostos'),
    ('na mesma POS', 'DFHMDF LENGTH=0 redundante'),
    ('o literal e truncado', 'INITIAL maior que o LENGTH'),
    ('PICOUT', 'PICOUT incompativel com o LENGTH'),
    ('nome repetido', 'nome de campo repetido'),
    ('e nao no 01', 'campo do mapa ausente do copybook'),
    ('e nao no mapa', 'campo do copybook ausente do mapa'),
    ('e o copybook declara', 'tamanho divergente do copybook'),
    ('sem copybook simbolico', 'copybook simbolico ausente'),
    ('sem 01', 'mapa sem estrutura simbolica'),
    ('sem POS reconhecivel', 'POS invalido'),
]


def categoria_de(texto):
    for marca, nome in CATEGORIAS:
        if marca in texto:
            return nome
    return 'outros'


def montar_statements(caminho, achados):
    """Junta as linhas fisicas em statements logicos.

    Devolve lista de (linha_inicial, texto). O texto ja vem com as
    continuacoes concatenadas do jeito que o assembler faria.
    """
    with open(caminho, encoding='utf-8') as fp:
        linhas = [l.rstrip('\n') for l in fp]

    statements = []
    i = 0
    while i < len(linhas):
        bruta = linhas[i]
        if not bruta.strip() or bruta[:1] in ('*', '.'):
            i += 1
            continue

        inicio = i + 1
        acumulado = ''
        primeira = True
        while True:
            bruta = linhas[i] if i < len(linhas) else ''
            corte, continua = onde_cortar(linhas, i, achados, caminho)
            trecho = bruta[:corte] if primeira else bruta[COL_RETOMA - 1:corte]

            if dentro_de_literal(acumulado):
                if trecho != trecho.rstrip() and continua:
                    achados.append(Achado(
                        caminho, i + 1, 'AVISO',
                        'literal continuado preenchido com espaco ate a '
                        'coluna %d: o espaco entra no texto do mapa' % corte))
                acumulado += trecho
            else:
                acumulado = acumulado.rstrip() + trecho.rstrip()

            primeira = False
            i += 1
            if not continua or i >= len(linhas):
                break

        statements.append((inicio, acumulado))
    return statements


def onde_cortar(linhas, i, achados, caminho):
    """Devolve (coluna de corte, continua?) para a linha fisica i."""
    bruta = linhas[i]
    if len(bruta) >= COL_CONT and bruta[COL_CONT - 1] != ' ':
        return COL_CONT - 1, True

    # marca deslocada uma coluna a esquerda: o assembler nao continua,
    # e o statement seguinte fica orfao. E defeito, nao estilo.
    if (len(bruta) >= COL_CONT - 1 and bruta[COL_CONT - 2] != ' '
            and bruta[:COL_CONT - 2].rstrip() != bruta[:COL_CONT - 1].rstrip()
            and i + 1 < len(linhas)
            and linhas[i + 1][:COL_RETOMA - 1].strip() == ''
            and linhas[i + 1].strip()):
        achados.append(Achado(
            caminho, i + 1, 'ERRO',
            'marca de continuacao "%s" na coluna %d, deveria estar na %d'
            % (bruta[COL_CONT - 2], COL_CONT - 1, COL_CONT)))
        return COL_CONT - 2, True

    return len(bruta), False


def dentro_de_literal(texto):
    return texto.count("'") % 2 == 1


def separar_operandos(texto):
    """Quebra os operandos por virgula fora de parenteses e de aspas."""
    partes, atual, nivel, literal = [], '', 0, False
    for ch in texto:
        if ch == "'":
            literal = not literal
        if not literal:
            if ch == '(':
                nivel += 1
            elif ch == ')':
                nivel -= 1
            elif ch == ',' and nivel == 0:
                partes.append(atual)
                atual = ''
                continue
        atual += ch
    if atual.strip():
        partes.append(atual)
    return [p.strip() for p in partes if p.strip()]


def parse_statement(texto):
    """Devolve (nome, opcode, dict de operandos) ou None."""
    m = re.match(r'^(\S+)?\s+(DFHMSD|DFHMDI|DFHMDF|DFHMSD\s|END)\b\s*(.*)$',
                 texto)
    if not m:
        return None
    nome, opcode, resto = m.group(1), m.group(2).strip(), m.group(3)
    operandos = {}
    for parte in separar_operandos(resto):
        if '=' in parte:
            chave, valor = parte.split('=', 1)
            operandos[chave.strip()] = valor.strip()
        else:
            operandos[parte] = ''
    return nome, opcode, operandos


def valor_inteiro(operandos, chave):
    bruto = operandos.get(chave)
    if bruto is None or not bruto.isdigit():
        return None
    return int(bruto)


def texto_literal(bruto):
    if bruto is None or not bruto.startswith("'"):
        return None
    corpo = bruto[1:]
    if corpo.endswith("'"):
        corpo = corpo[:-1]
    return corpo.replace("''", "'")


def analisar_mapa(caminho, statements, achados):
    """Percorre os statements e devolve os mapas com seus campos."""
    mapas = []
    atual = None
    for linha, texto in statements:
        parsed = parse_statement(texto)
        if not parsed:
            continue
        nome, opcode, operandos = parsed

        if opcode == 'DFHMDI':
            tamanho = operandos.get('SIZE', '')
            m = re.match(r'\((\d+),(\d+)\)', tamanho)
            tela = (int(m.group(1)), int(m.group(2))) if m else TELA_PADRAO
            atual = {'nome': nome, 'linha': linha, 'tela': tela, 'campos': []}
            mapas.append(atual)
            continue

        if opcode != 'DFHMDF' or atual is None:
            continue

        pos = operandos.get('POS', '')
        m = re.match(r'\((\d+),(\d+)\)', pos)
        if m:
            lin, col = int(m.group(1)), int(m.group(2))
        else:
            m = re.match(r'(\d+)$', pos)
            if not m:
                achados.append(Achado(caminho, linha, 'ERRO',
                                      'DFHMDF sem POS reconhecivel: %r' % pos))
                continue
            offset = int(m.group(1))
            lin = offset // atual['tela'][1] + 1
            col = offset % atual['tela'][1] + 1

        atual['campos'].append({
            'nome': nome,
            'linha': linha,
            'lin': lin,
            'col': col,
            'length': valor_inteiro(operandos, 'LENGTH'),
            'initial': texto_literal(operandos.get('INITIAL')),
            'attrb': operandos.get('ATTRB', ''),
            'picin': texto_literal(operandos.get('PICIN')),
            'picout': texto_literal(operandos.get('PICOUT')),
        })
    return mapas


def conferir_campos(caminho, mapa, achados):
    altura, largura = mapa['tela']
    ocupado = {}
    vistos = {}

    for campo in mapa['campos']:
        lin, col = campo['lin'], campo['col']
        rotulo = campo['nome'] or '(sem nome)'
        n = campo['length']
        stopper = campo['nome'] is None and n == 0

        if not (1 <= lin <= altura) or not (1 <= col <= largura):
            achados.append(Achado(
                caminho, campo['linha'], 'ERRO',
                '%s: POS=(%d,%d) fora da tela %dx%d'
                % (rotulo, lin, col, altura, largura)))

        if campo['nome']:
            if campo['nome'] in vistos:
                achados.append(Achado(
                    caminho, campo['linha'], 'ERRO',
                    '%s: nome repetido, ja definido na linha %d'
                    % (rotulo, vistos[campo['nome']])))
            vistos[campo['nome']] = campo['linha']

        if n is None:
            continue

        # POS aponta o byte de atributo; os dados vem logo depois
        attr = (lin - 1) * largura + (col - 1)
        if attr + n >= altura * largura:
            achados.append(Achado(
                caminho, campo['linha'], 'ERRO',
                '%s: LENGTH=%d estoura o fim da tela' % (rotulo, n)))
        if n and (attr + n) // largura + 1 != lin:
            achados.append(Achado(
                caminho, campo['linha'], 'ERRO',
                '%s: POS=(%d,%d) com LENGTH=%d passa da coluna %d e invade '
                'a linha seguinte' % (rotulo, lin, col, n, largura)))

        for offset in range(attr, attr + n + 1):
            anterior = ocupado.get(offset)
            if anterior is None:
                continue
            outra_linha, outro_attr, outro_stopper = anterior
            # o stopper existe so para fechar o campo anterior; quando cai
            # na mesma POS do campo seguinte ele e redundante, nao colisao
            # de area de dados
            if (stopper or outro_stopper) and offset == attr == outro_attr:
                achados.append(Achado(
                    caminho, campo['linha'], 'AVISO',
                    '%s: DFHMDF LENGTH=0 na mesma POS do campo da linha %d, '
                    'redundante' % (rotulo, outra_linha)))
            else:
                achados.append(Achado(
                    caminho, campo['linha'], 'ERRO',
                    '%s: sobrepoe o campo da linha %d na posicao (%d,%d)'
                    % (rotulo, outra_linha, offset // largura + 1,
                       offset % largura + 1)))
            break
        for offset in range(attr, attr + n + 1):
            if offset not in ocupado or not stopper:
                ocupado[offset] = (campo['linha'], attr, stopper)

        if campo['picout']:
            saida = tamanho_pic(campo['picout'])
            if saida is not None and saida != n:
                achados.append(Achado(
                    caminho, campo['linha'], 'ERRO',
                    "%s: LENGTH=%d e PICOUT='%s' de %d posicoes"
                    % (rotulo, n, campo['picout'], saida)))

        # LENGTH maior que o literal e reserva deliberada de espaco;
        # menor trunca o texto no mapa, e defeito.
        if campo['initial'] is not None and len(campo['initial']) > n:
            achados.append(Achado(
                caminho, campo['linha'], 'ERRO',
                '%s: LENGTH=%d e INITIAL de %d caracteres, o literal e '
                'truncado' % (rotulo, n, len(campo['initial']))))


def tamanho_pic(pic):
    """Posicoes ocupadas por um PICTURE de campo DISPLAY."""
    total = 0
    i = 0
    while i < len(pic):
        ch = pic[i]
        if ch == '(':
            fim = pic.find(')', i)
            if fim < 0:
                return None
            total += int(pic[i + 1:fim]) - 1
            i = fim + 1
            continue
        if ch in 'XA9ZB0/,.-+*$':
            total += 1
        elif ch in 'VS':
            pass
        else:
            return None
        i += 1
    return total


def ler_copybook(caminho):
    """Devolve {nome do 01: {campo: tamanho do PIC de entrada}}."""
    if not os.path.exists(caminho):
        return None
    blocos = {}
    atual = None
    for linha in open(caminho, encoding='utf-8'):
        if linha[6:7] == '*':
            continue
        m = re.match(r'\s*01\s+([A-Z0-9]+)I\b', linha)
        if m:
            atual = blocos.setdefault(m.group(1), {})
            continue
        if re.match(r'\s*01\s+', linha):
            atual = None
            continue
        if atual is None:
            continue
        m = re.search(r'\b([A-Z0-9]+)I\s+PIC\s+([^. ]+)', linha)
        if m:
            tam = tamanho_pic(m.group(2))
            if tam is not None:
                atual[m.group(1)] = tam
    return blocos


def conferir_copybook(caminho, mapset, mapa, achados):
    copybook = os.path.join(RAIZ, 'copy', mapset + '.cpy')
    blocos = ler_copybook(copybook)
    if blocos is None:
        achados.append(Achado(caminho, mapa['linha'], 'AVISO',
                              'sem copybook simbolico em copy/%s.cpy' % mapset))
        return
    if mapa['nome'] not in blocos:
        achados.append(Achado(
            caminho, mapa['linha'], 'ERRO',
            'mapa %s sem 01 %sI em copy/%s.cpy'
            % (mapa['nome'], mapa['nome'], mapset)))
        return

    simbolicos = blocos[mapa['nome']]
    nomeados = {c['nome']: c for c in mapa['campos'] if c['nome']}
    for nome, campo in sorted(nomeados.items()):
        if nome not in simbolicos:
            achados.append(Achado(
                caminho, campo['linha'], 'ERRO',
                '%s: no mapa e nao no 01 %sI de copy/%s.cpy'
                % (nome, mapa['nome'], mapset)))
        else:
            # com PICIN o campo simbolico de entrada segue o PICIN, nao o
            # LENGTH, que dimensiona o que a tela mostra
            esperado = (tamanho_pic(campo['picin']) if campo['picin']
                        else campo['length'])
            origem = ("PICIN='%s'" % campo['picin'] if campo['picin']
                      else 'LENGTH=%s' % campo['length'])
            if esperado is not None and simbolicos[nome] != esperado:
                achados.append(Achado(
                    caminho, campo['linha'], 'ERRO',
                    '%s: %s pede %d posicoes e o copybook declara %d'
                    % (nome, origem, esperado, simbolicos[nome])))

    for nome in sorted(set(simbolicos) - set(nomeados)):
        achados.append(Achado(
            caminho, mapa['linha'], 'ERRO',
            '%s: no 01 %sI de copy/%s.cpy e nao no mapa'
            % (nome, mapa['nome'], mapset)))


def validar(caminho, despejo):
    achados = []
    statements = montar_statements(caminho, achados)
    mapas = analisar_mapa(caminho, statements, achados)
    mapset = os.path.splitext(os.path.basename(caminho))[0]

    for mapa in mapas:
        conferir_campos(caminho, mapa, achados)
        conferir_copybook(caminho, mapset, mapa, achados)

    if despejo is not None:
        despejo[mapset] = mapas
    return achados


def main(argv):
    despejo = {} if '--json' in argv else None
    resumo_apenas = '--resumo' in argv
    alvos = [a for a in argv if not a.startswith('--')]
    if not alvos:
        alvos = sorted(glob.glob(os.path.join(RAIZ, 'bms', '*.bms')))

    achados = []
    for alvo in alvos:
        achados.extend(validar(os.path.abspath(alvo), despejo))

    if despejo is not None:
        print(json.dumps(despejo, indent=2, ensure_ascii=False))
        return 0

    if not resumo_apenas:
        for achado in achados:
            print(achado)

    agrupado = {}
    for achado in achados:
        chave = (os.path.relpath(achado.arquivo, RAIZ),
                 achado.nivel, categoria_de(achado.texto))
        agrupado[chave] = agrupado.get(chave, 0) + 1

    if agrupado:
        print('\nResumo:')
        for (arquivo, nivel, categoria), n in sorted(agrupado.items()):
            print('  %-16s %-5s %3d  %s' % (arquivo, nivel, n, categoria))

    erros = sum(1 for a in achados if a.nivel == 'ERRO')
    avisos = len(achados) - erros
    print('\n%d mapset(s): %d erro(s), %d aviso(s)'
          % (len(alvos), erros, avisos))
    return 1 if erros else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
