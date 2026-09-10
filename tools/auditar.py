# -*- coding: utf-8 -*-
"""Auditoria independente das saidas do motor SFP0300.
Recalcula INSS, IRRF, FGTS e liquido a partir dos eventos gravados
em SFPFOL.DAT e confronta com o resumo SFPRES.DAT."""
from decimal import Decimal, ROUND_HALF_UP

D = lambda s: Decimal(s)
def v(campo):           # PIC 9(n)V99 -> Decimal
    return Decimal(campo[:-2] + '.' + campo[-2:])
def r2(x):
    return x.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)

INSS = [(D('1518.00'), D('7.5')), (D('2793.88'), D('9')),
        (D('4190.83'), D('12')),  (D('8157.41'), D('14'))]
IRRF = [(D('2428.80'), D('0'),    D('0')),
        (D('2826.65'), D('7.5'),  D('182.16')),
        (D('3751.05'), D('15'),   D('394.16')),
        (D('4664.68'), D('22.5'), D('675.49')),
        (D('99999999'), D('27.5'), D('908.73'))]
DEP  = D('189.59')
SIMP = D('607.20')

def calc_inss(base):
    # replica o acumulo arredondado faixa a faixa do SFP0310
    tot, ant = D(0), D(0)
    for lim, aliq in INSS:
        if base > ant:
            faixa = min(base, lim) - ant
            tot = r2(tot + faixa * aliq / 100)
        ant = lim
    teto = D('951.63')
    return teto if tot > teto else tot

def calc_irrf(base, inss, pensao, ndep):
    b1 = base - inss - pensao - ndep * DEP
    if b1 < 0: b1 = D(0)
    b2 = base - SIMP - pensao
    if b2 < 0: b2 = D(0)
    def tab(b):
        for lim, aliq, ded in IRRF:
            if b <= lim:
                x = r2(b * aliq / 100 - ded)
                return x if x > 0 else D(0)
        return D(0)
    t1, t2 = tab(b1), tab(b2)
    return (t1, 'L') if t1 <= t2 else (t2, 'S')

# ---- carrega eventos calculados -------------------------------------
eventos = {}
for ln in open('saidas/SFPFOL.DAT'):
    ln = ln.rstrip('\n')
    if len(ln) < 60: continue
    mat = ln[7:15]
    cod = ln[18:22]
    nat = ln[52:53]
    val = v(ln[60:71])
    eventos.setdefault(mat, []).append((cod, nat, val))

dep_irrf = {}
for ln in open('dados/SFPDEP.DAT'):
    mat = ln[0:8]
    if ln[55:56] == 'S':
        dep_irrf[mat] = dep_irrf.get(mat, 0) + 1

erros, ok = [], 0
for ln in open('saidas/SFPRES.DAT'):
    ln = ln.rstrip('\n')
    mat  = ln[7:15]
    prov = v(ln[72:83]); desc = v(ln[83:94]); liq = v(ln[94:105])
    bins = v(ln[105:116]); vins = v(ln[138:149])
    birf = v(ln[116:127]); virf = v(ln[149:160])
    bfgt = v(ln[127:138]); vfgt = v(ln[160:171])
    ev = eventos.get(mat, [])
    sp = sum((x[2] for x in ev if x[1] == 'P'), D(0))
    sd = sum((x[2] for x in ev if x[1] == 'D'), D(0))
    pen = sum((x[2] for x in ev if x[0] == '0530'), D(0))
    e = []
    if sp != prov: e.append(f'proventos {sp} x {prov}')
    if sd != desc: e.append(f'descontos {sd} x {desc}')
    if r2(prov - desc) != liq: e.append(f'liquido {prov-desc} x {liq}')
    ci = calc_inss(bins)
    if ci != vins: e.append(f'INSS {ci} x {vins}')
    cf = r2(bfgt * 8 / 100)
    if cf != vfgt: e.append(f'FGTS {cf} x {vfgt}')
    ct, met = calc_irrf(birf, vins, pen, dep_irrf.get(mat, 0))
    if ct != virf: e.append(f'IRRF {ct}({met}) x {virf}')
    if e: erros.append((mat, e))
    else: ok += 1

print(f'Empregados conferidos ..: {ok + len(erros)}')
print(f'Aderentes ..............: {ok}')
print(f'Com divergencia ........: {len(erros)}')
for m, e in erros[:15]:
    print('  ', m, '; '.join(e))
