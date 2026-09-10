#!/usr/bin/env python3
"""Gera os mapsets BMS de grade e o copybook simbolico
correspondente (o que a PROC SFPPBMS produziria nos passos
ASMDSECT e ASMMAP).

Mapas de grade seguem todos o mesmo desenho: cabecalho com a
chave, faixa de colunas, N linhas repetidas e rodape com
mensagem e teclas. Descrever esse padrao uma vez e instanciar
por tabela evita centenas de linhas de assembler repetido."""
import os

RAIZ = os.path.join(os.path.dirname(__file__), '..')


def cab(mapset, mapa, titulo, largura=80, altura=24):
    L = []
    L.append("*" * 71)
    L.append(f"* MAPSET  : {mapset}  - {titulo}".ljust(70) + "*")
    L.append(f"* MAPA    : {mapa}".ljust(70) + "*")
    L.append("*" * 71)
    L.append(f"{mapset:<8} DFHMSD TYPE=&SYSPARM,".ljust(71) + "X")
    L.append("               MODE=INOUT,".ljust(71) + "X")
    L.append("               LANG=COBOL,".ljust(71) + "X")
    L.append("               STORAGE=AUTO,".ljust(71) + "X")
    L.append("               TIOAPFX=YES,".ljust(71) + "X")
    L.append("               CTRL=(FREEKB,FRSET),".ljust(71) + "X")
    L.append("               MAPATTS=(COLOR,HILIGHT),".ljust(71) + "X")
    L.append("               DSATTS=(COLOR,HILIGHT),".ljust(71) + "X")
    L.append("               EXTATT=YES")
    L.append("*" * 71)
    L.append(f"{mapa:<8} DFHMDI SIZE=({altura},{largura}),".ljust(71) + "X")
    L.append("               LINE=1,".ljust(71) + "X")
    L.append("               COLUMN=1")
    L.append("*" * 71)
    return L


def rotulo(lin, col, texto, cor='BLUE', attr='(PROT,NORM)'):
    """Emite o DFHMDF de um texto fixo.

    O literal do INITIAL vai ate a coluna 71; o que nao couber
    segue em linhas de continuacao com X na coluna 72 e operando
    retomado na coluna 16. Nao se pode encher o literal com
    espacos para alinhar o X: o espaco entraria no proprio
    texto do mapa."""
    L = [f"         DFHMDF POS=({lin},{col}),LENGTH={len(texto)},"
         f"ATTRB={attr},".ljust(71) + "X"]
    prefixo = f"               COLOR={cor},INITIAL='"
    prim = 71 - len(prefixo)
    cont = 71 - 15
    if len(texto) + 1 <= prim:
        return L + [prefixo + texto + "'"]
    pedacos = [texto[:prim]]
    resto = texto[prim:]
    while len(resto) + 1 > cont:
        pedacos.append(resto[:cont])
        resto = resto[cont:]
    pedacos.append(resto)
    L.append(prefixo + pedacos[0] + "X")
    for meio in pedacos[1:-1]:
        L.append(" " * 15 + meio + "X")
    L.append(" " * 15 + pedacos[-1] + "'")
    return L


def campo(nome, lin, col, tam, prot=False, cor='GREEN',
          brt=False, ic=False, stop=True):
    """Emite o DFHMDF de um campo.

    Campo desprotegido ganha um DFHMDF de comprimento zero logo
    depois, para o atributo fechar a area digitavel. Quando o
    campo seguinte ja encosta, esse stopper cairia na mesma POS
    dele: passe stop=False."""
    if prot:
        attr = '(PROT,BRT)' if brt else '(PROT,NORM)'
        extra = ''
    else:
        attr = '(UNPROT,IC,NORM)' if ic else '(UNPROT,NORM)'
        extra = ',HILIGHT=UNDERLINE'
    out = [f"{nome:<8} DFHMDF POS=({lin},{col}),LENGTH={tam},"
           f"ATTRB={attr},".ljust(71) + "X",
           f"               COLOR={cor}{extra}"]
    if not prot and stop:
        out.append(f"         DFHMDF POS=({lin},{col + tam + 1}),"
                   f"LENGTH=0,ATTRB=(ASKIP,NORM)")
    return out


def faixa_grade(colunas, tracejado=False):
    """Monta o cabecalho ou o tracejado de uma grade.

    Recebe as colunas como (coluna do primeiro byte de dado,
    largura, titulo) e devolve o literal para rotulo(lin, 1, ...),
    que comeca na coluna 2. Assim titulo, tracejado e campo saem
    da mesma fonte e nao ha como desalinhar."""
    buf = [' '] * 79
    for col, larg, titulo in colunas:
        texto = '-' * larg if tracejado else titulo[:larg]
        for i, ch in enumerate(texto):
            buf[col - 2 + i] = ch
    return ''.join(buf).rstrip()


def simbolico(mapset, mapa, campos, destino):
    L = []
    L.append("      *" + "=" * 64 + "*")
    L.append(f"      * COPYBOOK : {mapset} - ESTRUTURA SIMBOLICA "
             f"GERADA PELO BMS".ljust(71) + "*")
    L.append(f"      *            MAPSET {mapset} / MAPA {mapa}"
             .ljust(71) + "*")
    L.append("      *" + "=" * 64 + "*")
    L.append(f"       01  {mapa}I.")
    L.append("           02  FILLER              PIC X(012).")
    for nome, pic in campos:
        L.append(f"           02  {nome + 'L':<20}PIC S9(004) COMP.")
        L.append(f"           02  {nome + 'F':<20}PIC X.")
        L.append(f"           02  FILLER REDEFINES {nome}F.")
        L.append(f"               03 {nome + 'A':<17}PIC X.")
        L.append(f"           02  {nome + 'I':<20}PIC {pic}.")
    L.append("      *")
    L.append(f"       01  {mapa}O REDEFINES {mapa}I.")
    L.append("           02  FILLER              PIC X(012).")
    for nome, pic in campos:
        L.append("           02  FILLER              PIC X(003).")
        L.append(f"           02  {nome + 'O':<20}PIC {pic}.")
    open(destino, 'w').write("\n".join(L) + "\n")
    return len(L)


def rodape(L, linhas_teclas):
    L += [f"MMENSAG  DFHMDF POS=(23,1),LENGTH=79,ATTRB=(PROT,BRT),"
          .ljust(71) + "X",
          "               COLOR=RED"]
    L += rotulo(24, 1, linhas_teclas.ljust(79)[:79])
    L.append("*" * 71)
    L.append("         DFHMSD TYPE=FINAL")
    L.append("         END")


def grava(nome, linhas):
    caminho = os.path.join(RAIZ, 'bms', nome)
    open(caminho, 'w').write("\n".join(linhas) + "\n")
    print(f"  {nome:<14} {len(linhas):>4} linhas")


SUF = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C']

# =================================================================
# SFPM05 - CADASTRO DE CARGOS (GRADE)
# =================================================================
L = cab('SFPM05', 'MAPCARG', 'CADASTRO DE CARGOS E PISOS SALARIAIS')
L += rotulo(1, 1, 'SFP0140')
L += rotulo(1, 20, 'CADASTRO DE CARGOS E PISOS SALARIAIS',
            'NEUTRAL', '(PROT,BRT)')
L += rotulo(1, 68, 'SF06')
L += rotulo(2, 1, 'DATA:')
L += campo('MDATA', 2, 7, 10, prot=True, cor='TURQUOISE')
L += rotulo(2, 55, 'POSICIONAR NO CARGO:')
# o campo termina na coluna 80: o stopper cairia fora da tela
L += campo('MCARGO', 2, 76, 4, ic=True, stop=False)
L += rotulo(3, 1, '-' * 79)
# a grade nao cabia em 80 colunas com piso e teto de treze
# posicoes; dez ja comportam 9.999.999,99, e o que sobra abre
# espaco para a carga horaria e para a situacao, que o SFP0140
# antes so conseguia manter por fora da tela
COLUNAS_CARGO = [
    ('ACAO', 2, 1, 'A'),
    ('COD', 4, 4, 'COD'),
    ('DES', 9, 35, 'DESCRICAO'),
    ('CBO', 45, 6, 'CBO'),
    ('NIV', 52, 1, 'N'),
    ('PIS', 54, 10, 'PISO SAL.'),
    ('TET', 65, 10, 'TETO SAL.'),
    ('CHR', 76, 3, 'CH'),
    ('SIT', 80, 1, 'S'),
]
L += rotulo(4, 1, faixa_grade([c[1:] for c in COLUNAS_CARGO]))
L += rotulo(5, 1, faixa_grade([c[1:] for c in COLUNAS_CARGO], True))
lin = 6
# as colunas encostam umas nas outras: o atributo do campo
# seguinte ja fecha a area digitavel, e a ultima termina na
# coluna 80
for s in SUF:
    for pref, dado, larg, _ in COLUNAS_CARGO:
        L += campo(f'{pref}{s}', lin, dado - 1, larg, stop=False)
    lin += 1
L += rotulo(19, 1, '-' * 79)
L += rotulo(20, 3, 'ACAO: I=INCLUIR A=ALTERAR E=EXCLUIR'
                   '   S: A=ATIVO E=EXTINTO')
L += rotulo(21, 3, 'NIVEL: O=OPERACIONAL T=TECNICO E=ESPECIALISTA '
                   'G=GERENCIAL D=DIRETIVO')
L += rotulo(22, 3, 'PAGINA:')
L += campo('MPAG', 22, 11, 3, prot=True, cor='TURQUOISE')
rodape(L, 'F3=SAIR  F4=CONSULTA  F5=CARREGAR  F6=GRAVAR  '
          'F7=ANTERIOR  F8=PROXIMA')
grava('SFPM05.bms', L)

campos = [('MDATA', 'X(010)'), ('MCARGO', 'X(004)')]
for s in SUF:
    for pref, _, larg, _ in COLUNAS_CARGO:
        pic = 'Z(006)9,99' if pref in ('PIS', 'TET') \
              else f'X({larg:03d})'
        campos.append((f'{pref}{s}', pic))
campos += [('MPAG', 'X(003)'), ('MMENSAG', 'X(079)')]
n = simbolico('SFPM05', 'MAPCARG', campos,
              os.path.join(RAIZ, 'copy', 'SFPM05.cpy'))
print(f"  copy/SFPM05.cpy {n:>4} linhas")

# =================================================================
# SFPM06 - MANUTENCAO DE DOMINIOS (GRADE)
# =================================================================
L = cab('SFPM06', 'MAPDOMI', 'MANUTENCAO DAS TABELAS DE DOMINIO')
L += rotulo(1, 1, 'SFP0160')
L += rotulo(1, 22, 'MANUTENCAO DE TABELAS DE DOMINIO',
            'NEUTRAL', '(PROT,BRT)')
L += rotulo(1, 68, 'SF08')
L += rotulo(2, 1, 'TIPO DE DOMINIO:')
L += campo('MTIPO', 2, 18, 3, ic=True)
L += campo('MDESTIP', 2, 24, 35, prot=True, cor='TURQUOISE')
L += rotulo(2, 62, 'F4=LISTA TIPOS')
L += rotulo(3, 1, '-' * 79)
# a coluna SIS marca o dominio de sistema, que a RN08 protege;
# sem ela o usuario so descobria a protecao quando o SFP0160
# recusava a acao
COLUNAS_DOMINIO = [
    ('ACAO', 2, 1, 'A'),
    ('COD', 4, 6, 'CODIGO'),
    ('DES', 11, 35, 'DESCRICAO'),
    ('RED', 47, 12, 'REDUZIDA'),
    ('ORD', 60, 3, 'ORD'),
    ('AUX', 64, 10, 'AUXILIAR'),
    ('SIT', 75, 1, 'S'),
    ('SIS', 77, 3, 'SIS'),
]
L += rotulo(4, 1, faixa_grade([c[1:] for c in COLUNAS_DOMINIO]))
L += rotulo(5, 1, faixa_grade([c[1:] for c in COLUNAS_DOMINIO], True))
lin = 6
for s in SUF:
    # as colunas encostam umas nas outras: o atributo do campo
    # seguinte ja fecha a area digitavel, e um stopper cairia na
    # mesma POS dele
    for pref, dado, larg, _ in COLUNAS_DOMINIO:
        L += campo(f'{pref}{s}', lin, dado - 1, larg,
                   prot=(pref == 'SIS'),
                   cor='TURQUOISE' if pref == 'SIS' else 'GREEN',
                   stop=False)
    lin += 1
L += rotulo(19, 1, '-' * 79)
L += rotulo(20, 3, 'ACAO: I=INCLUIR  A=ALTERAR  E=EXCLUIR    '
                   'SITUACAO: A=ATIVO  I=INATIVO')
L += rotulo(21, 3, 'ATENCAO: DOMINIOS DE SISTEMA NAO PODEM SER '
                   'ALTERADOS NEM EXCLUIDOS')
L += rotulo(22, 3, 'PAGINA:')
L += campo('MPAG', 22, 11, 3, prot=True, cor='TURQUOISE')
rodape(L, 'F3=SAIR  F4=CONSULTA  F5=CARREGAR  F6=GRAVAR  '
          'F7=ANTERIOR  F8=PROXIMA')
grava('SFPM06.bms', L)

campos = [('MTIPO', 'X(003)'), ('MDESTIP', 'X(035)')]
for s in SUF:
    campos += [(f'{pref}{s}', f'X({larg:03d})')
               for pref, _, larg, _ in COLUNAS_DOMINIO]
campos += [('MPAG', 'X(003)'), ('MMENSAG', 'X(079)')]
n = simbolico('SFPM06', 'MAPDOMI', campos,
              os.path.join(RAIZ, 'copy', 'SFPM06.cpy'))
print(f"  copy/SFPM06.cpy {n:>4} linhas")

# =================================================================
# SFPM03 - CADASTRO DE RUBRICAS / EVENTOS (FORMULARIO)
# =================================================================
L = cab('SFPM03', 'MAPEVEN', 'CADASTRO DE RUBRICAS E EVENTOS')
L += rotulo(1, 1, 'SFP0110')
L += rotulo(1, 24, 'CADASTRO DE RUBRICAS / EVENTOS',
            'NEUTRAL', '(PROT,BRT)')
L += rotulo(1, 68, 'SF04')
L += rotulo(2, 1, 'ACAO:')
L += campo('MACAO', 2, 7, 1, ic=True)
L += rotulo(2, 12, '(I=INCLUIR A=ALTERAR C=CONSULTAR E=EXCLUIR)')
L += rotulo(2, 58, 'CODIGO:')
L += campo('MCODIGO', 2, 66, 4)
L += rotulo(3, 1, '-' * 79)
L += rotulo(4, 3, 'DESCRICAO ......:')
L += campo('MDESCR', 4, 21, 30)
L += rotulo(5, 3, 'NATUREZA .......:')
L += campo('MNATUR', 5, 21, 1)
L += campo('MDESNAT', 5, 24, 20, prot=True, cor='TURQUOISE')
L += rotulo(5, 60, 'F4=LISTA')
L += rotulo(6, 3, 'TIPO DE CALCULO :')
L += campo('MTIPCAL', 6, 21, 3)
L += campo('MDESTIP', 6, 26, 34, prot=True, cor='TURQUOISE')
L += rotulo(7, 3, 'UNIDADE ........:')
L += campo('MUNIDAD', 7, 21, 2)
L += campo('MDESUNI', 7, 25, 20, prot=True, cor='TURQUOISE')
L += rotulo(7, 60, 'F4=LISTA')
L += rotulo(8, 3, 'PERCENTUAL .....:')
L += campo('MPERCEN', 8, 21, 6)
L += rotulo(8, 30, '%')
L += rotulo(9, 3, 'CONTA CONTABIL .:')
L += campo('MCONTA', 9, 21, 8)
L += rotulo(10, 3, 'SITUACAO .......:')
L += campo('MSITUAC', 10, 21, 1)
L += rotulo(10, 24, '(A=ATIVA  I=INATIVA)')
L += rotulo(11, 1, '-' * 79)
L += rotulo(12, 3, 'INCIDENCIAS DA RUBRICA  (S=INCIDE  N=NAO INCIDE)',
            'YELLOW', '(PROT,BRT)')
L += rotulo(14, 5, 'BASE DE INSS ......:')
L += campo('MINCINS', 14, 26, 1)
L += rotulo(14, 42, 'BASE DE DSR .......:')
L += campo('MINCDSR', 14, 63, 1)
L += rotulo(15, 5, 'BASE DE IRRF ......:')
L += campo('MINCIRR', 15, 26, 1)
L += rotulo(15, 42, 'BASE DE 13o SALARIO:')
L += campo('MINC13O', 15, 63, 1)
L += rotulo(16, 5, 'BASE DE FGTS ......:')
L += campo('MINCFGT', 16, 26, 1)
L += rotulo(16, 42, 'BASE DE FERIAS ....:')
L += campo('MINCFER', 16, 63, 1)
L += rotulo(18, 1, '-' * 79)
L += rotulo(19, 3, 'TIPOS DE CALCULO: 001=VALOR INFORMADO  '
                   '002=HORAS X VALOR HORA')
L += rotulo(20, 3, '004=% SOBRE SALARIO  005=% SOBRE MINIMO  '
                   '006=% SOBRE PROVENTOS')
L += rotulo(21, 3, 'ATENCAO: TIPOS DE 100 A 199 SAO RESERVADOS AO '
                   'CALCULO AUTOMATICO')
rodape(L, 'F3=SAIR  F4=CONSULTA  F5=LER  F6=GRAVAR  F12=LIMPAR')
grava('SFPM03.bms', L)

campos = [('MACAO', 'X(001)'), ('MCODIGO', 'X(004)'),
          ('MDESCR', 'X(030)'), ('MNATUR', 'X(001)'),
          ('MDESNAT', 'X(020)'), ('MTIPCAL', 'X(003)'),
          ('MDESTIP', 'X(034)'), ('MUNIDAD', 'X(002)'),
          ('MDESUNI', 'X(020)'), ('MPERCEN', 'ZZ9,99'),
          ('MCONTA', 'X(008)'), ('MSITUAC', 'X(001)'),
          ('MINCINS', 'X(001)'), ('MINCDSR', 'X(001)'),
          ('MINCIRR', 'X(001)'), ('MINC13O', 'X(001)'),
          ('MINCFGT', 'X(001)'), ('MINCFER', 'X(001)'),
          ('MMENSAG', 'X(079)')]
n = simbolico('SFPM03', 'MAPEVEN', campos,
              os.path.join(RAIZ, 'copy', 'SFPM03.cpy'))
print(f"  copy/SFPM03.cpy {n:>4} linhas")

# =================================================================
# SFPM04 - CADASTRO DA EMPRESA / ESTABELECIMENTO
# =================================================================
L = cab('SFPM04', 'MAPEMPR', 'CADASTRO DA EMPRESA E ESTABELECIMENTOS')
L += rotulo(1, 1, 'SFP0130')
L += rotulo(1, 20, 'CADASTRO DE EMPRESA / ESTABELECIMENTO',
            'NEUTRAL', '(PROT,BRT)')
L += rotulo(1, 68, 'SF05')
L += rotulo(2, 1, 'ACAO:')
L += campo('MACAO', 2, 7, 1, ic=True)
L += rotulo(2, 12, '(I/A/C/E)')
L += rotulo(2, 26, 'ESTABELECIMENTO:')
L += campo('MCODIGO', 2, 43, 4)
L += rotulo(2, 50, 'TIPO:')
L += campo('MTIPO', 2, 56, 1)
L += rotulo(2, 59, '(M=MATRIZ F=FILIAL)')
L += rotulo(3, 1, '-' * 79)
L += rotulo(4, 2, 'CNPJ .......:')
L += campo('MCNPJ', 4, 16, 14)
L += rotulo(4, 34, 'INSC.ESTADUAL:')
L += campo('MIE', 4, 49, 15)
L += rotulo(5, 2, 'RAZAO SOCIAL:')
L += campo('MRAZAO', 5, 16, 60)
L += rotulo(6, 2, 'N.FANTASIA .:')
L += campo('MFANTAS', 6, 16, 40)
L += rotulo(7, 1, '-- ENDERECO ' + '-' * 67)
L += rotulo(8, 2, 'LOGRADOURO .:')
L += campo('MTIPLOG', 8, 16, 3, stop=False)
L += rotulo(8, 20, 'F4')
L += campo('MLOGRAD', 8, 23, 40)
L += rotulo(8, 65, 'NUM:')
L += campo('MNUMERO', 8, 70, 8)
L += rotulo(9, 2, 'COMPLEMENTO :')
L += campo('MCOMPL', 9, 16, 15)
L += rotulo(9, 34, 'BAIRRO:')
L += campo('MBAIRRO', 9, 42, 25)
L += rotulo(10, 2, 'MUNICIPIO ..:')
L += campo('MMUNIC', 10, 16, 7)
L += campo('MDESMUN', 10, 25, 30, prot=True, cor='TURQUOISE')
L += rotulo(10, 58, 'UF:')
L += campo('MUF', 10, 62, 2)
L += rotulo(10, 66, 'F4=LISTA')
L += rotulo(11, 2, 'CEP ........:')
L += campo('MCEP', 11, 16, 8)
L += rotulo(11, 28, 'TELEFONE:')
L += campo('MTELEF', 11, 38, 14)
L += rotulo(12, 1, '-- PARAMETROS PREVIDENCIARIOS ' + '-' * 49)
L += rotulo(13, 2, 'CNAE .......:')
L += campo('MCNAE', 13, 16, 7)
L += rotulo(13, 26, 'FPAS:')
L += campo('MFPAS', 13, 32, 3)
L += rotulo(13, 38, 'COD.TERCEIROS:')
L += campo('MCODTER', 13, 53, 4)
L += rotulo(14, 2, 'ALIQ.RAT ...:')
L += campo('MALIRAT', 14, 16, 5)
L += rotulo(14, 24, 'FAP:')
L += campo('MFAP', 14, 29, 6)
L += rotulo(14, 38, 'ALIQ.TERCEIROS:')
L += campo('MALITER', 14, 54, 5)
L += rotulo(15, 2, 'SIMPLES ....:')
L += campo('MSIMPLE', 15, 16, 1)
L += rotulo(15, 20, 'DESONERACAO DA FOLHA:')
L += campo('MDESONE', 15, 42, 1)
L += rotulo(16, 1, '-- SINDICATO E PAGAMENTO ' + '-' * 54)
L += rotulo(17, 2, 'SINDICATO ..:')
L += campo('MSINDIC', 17, 16, 40)
L += rotulo(17, 58, 'DATA BASE:')
L += campo('MDTBASE', 17, 69, 2)
L += rotulo(18, 2, 'BANCO PAGADOR:')
L += campo('MBANCO', 18, 17, 3, stop=False)
L += rotulo(18, 21, 'F4=LISTA')
L += rotulo(18, 30, 'AGENCIA:')
L += campo('MAGENCI', 18, 39, 5, stop=False)
L += rotulo(18, 45, 'CONTA:')
L += campo('MCONTA', 18, 52, 12, stop=False)
L += rotulo(18, 65, 'DIA PAGTO:')
L += campo('MDIAPAG', 18, 76, 2, stop=False)
L += rotulo(19, 2, 'CONVENIO ...:')
L += campo('MCONVEN', 19, 16, 20)
L += rotulo(19, 40, 'SITUACAO:')
L += campo('MSITUAC', 19, 50, 1)
L += rotulo(19, 53, '(A=ATIVO I=INATIVO)')
L += rotulo(21, 1, '-' * 79)
rodape(L, 'F3=SAIR  F4=CONSULTA  F5=LER  F6=GRAVAR  F12=LIMPAR')
grava('SFPM04.bms', L)

campos = [('MACAO', 'X(001)'), ('MCODIGO', 'X(004)'),
          ('MTIPO', 'X(001)'), ('MCNPJ', 'X(014)'),
          ('MIE', 'X(015)'), ('MRAZAO', 'X(060)'),
          ('MFANTAS', 'X(040)'), ('MTIPLOG', 'X(003)'),
          ('MLOGRAD', 'X(040)'), ('MNUMERO', 'X(008)'),
          ('MCOMPL', 'X(015)'), ('MBAIRRO', 'X(025)'),
          ('MMUNIC', 'X(007)'), ('MDESMUN', 'X(030)'),
          ('MUF', 'X(002)'), ('MCEP', 'X(008)'),
          ('MTELEF', 'X(014)'), ('MCNAE', 'X(007)'),
          ('MFPAS', 'X(003)'), ('MCODTER', 'X(004)'),
          ('MALIRAT', 'X(005)'), ('MFAP', 'X(006)'),
          ('MALITER', 'X(005)'), ('MSIMPLE', 'X(001)'),
          ('MDESONE', 'X(001)'), ('MSINDIC', 'X(040)'),
          ('MDTBASE', 'X(002)'), ('MBANCO', 'X(003)'),
          ('MAGENCI', 'X(005)'), ('MCONTA', 'X(012)'),
          ('MDIAPAG', 'X(002)'), ('MCONVEN', 'X(020)'),
          ('MSITUAC', 'X(001)'), ('MMENSAG', 'X(079)')]
n = simbolico('SFPM04', 'MAPEMPR', campos,
              os.path.join(RAIZ, 'copy', 'SFPM04.cpy'))
print(f"  copy/SFPM04.cpy {n:>4} linhas")
