#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
=============================================================================
 SFP - SISTEMA DE FOLHA DE PAGAMENTO
 GERADOR DE MASSA DE DADOS FICTICIOS PARA TESTE DOS PROGRAMAS COBOL
-----------------------------------------------------------------------------
 Gera os arquivos posicionais (fixed-width) consumidos pelos programas
 batch, respeitando exatamente os layouts dos copybooks da pasta ./copy:

   SFPEMP.DAT  500 bytes  Cadastro de empregados      (SFPWEMP)
   SFPDEP.DAT   80 bytes  Dependentes                 (SFPWDEP)
   SFPPON.DAT   80 bytes  Apuracao do ponto           (SFPWPON)
   SFPMOV.DAT  100 bytes  Movimento mensal            (SFPWMOV)
   SFPEVE.DAT   80 bytes  Cadastro de eventos         (SFPWEVE)
   SFPTAB.DAT   80 bytes  Tabelas legais/parametros   (SFPWTAB)
   SYSIN.DAT    80 bytes  Cartao de parametro do JOB

 Todos os dados sao ficticios e gerados com semente fixa (reprodutivel).
=============================================================================
"""
import random, os, sys

random.seed(20260909)
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'dados')
DEST = os.path.normpath(DEST)
COMPETENCIA = "202608"
ANO, MES = 2026, 8

# ---------------------------------------------------------------- helpers
def N(valor, tam):
    """Campo numerico zero-filled a direita do PIC 9(n)."""
    return str(int(valor)).rjust(tam, '0')[-tam:]

def V(valor, inteiros, decimais=2):
    """Campo PIC 9(i)V99 - virgula implicita, sem separador."""
    cents = int(round(float(valor) * (10 ** decimais)))
    return str(cents).rjust(inteiros + decimais, '0')[-(inteiros + decimais):]

def A(texto, tam):
    """Campo alfanumerico ajustado a esquerda, sem acentuacao."""
    tr = str.maketrans("ÁÀÂÃÉÊÍÓÔÕÚÜÇáàâãéêíóôõúüç",
                       "AAAAEEIOOOUUCaaaaeeiooouuc")
    return texto.translate(tr).upper()[:tam].ljust(tam)

def dv_cpf(base9):
    d = [int(c) for c in base9]
    s = sum(d[i] * (10 - i) for i in range(9))
    d1 = (s * 10) % 11
    d1 = 0 if d1 > 9 else d1
    d.append(d1)
    s = sum(d[i] * (11 - i) for i in range(10))
    d2 = (s * 10) % 11
    d2 = 0 if d2 > 9 else d2
    return base9 + str(d1) + str(d2)

# ---------------------------------------------------------------- nomes
PRE = ["JOAO","MARIA","CARLOS","ANA","PEDRO","JULIANA","RICARDO","FERNANDA",
       "MARCOS","PATRICIA","ANDRE","CAMILA","RAFAEL","LUCIANA","BRUNO",
       "SIMONE","EDUARDO","VANESSA","GUSTAVO","ADRIANA","LEONARDO","TATIANE",
       "FABIO","CRISTINA","RODRIGO","SANDRA","MAURICIO","ELAINE","THIAGO",
       "MONICA","VINICIUS","ROSANA","ALEXANDRE","DENISE","GABRIEL","SILVIA",
       "HENRIQUE","BEATRIZ","IGOR","LARISSA","OTAVIO","PRISCILA","SERGIO",
       "VERONICA","WAGNER","YARA","ZULEICA","DANIEL","ELISA","FELIPE"]
SOB = ["SILVA","SANTOS","OLIVEIRA","SOUZA","PEREIRA","COSTA","RODRIGUES",
       "ALMEIDA","NASCIMENTO","LIMA","ARAUJO","FERNANDES","CARVALHO",
       "GOMES","MARTINS","ROCHA","RIBEIRO","ALVES","MONTEIRO","BARBOSA",
       "CARDOSO","TEIXEIRA","CORREIA","MENDES","FREITAS","AZEVEDO"]

CARGOS = [(1010,"ANALISTA DE SISTEMAS",  9800.00, 'M', 220),
          (1020,"PROGRAMADOR COBOL",     7200.00, 'M', 220),
          (1030,"OPERADOR DE PRODUCAO",  3450.00, 'M', 220),
          (2010,"OPERADOR DE MAQUINAS",    18.50, 'H', 220),
          (2020,"SOLDADOR",                24.75, 'H', 220),
          (2030,"AUXILIAR DE PRODUCAO",  2150.00, 'M', 220),
          (2040,"SUPERVISOR DE TURNO",   6400.00, 'M', 220),
          (3010,"ANALISTA FINANCEIRO",   5900.00, 'M', 220),
          (3020,"ASSISTENTE ADMINIST",   2980.00, 'M', 220),
          (3030,"GERENTE DE DIVISAO",   18500.00, 'M', 200),
          (4010,"MOTORISTA CARRETA",     4100.00, 'M', 220),
          (4020,"CONFERENTE",            2650.00, 'M', 220),
          (5010,"ELETRICISTA INDUSTR",   5300.00, 'M', 220),
          (5020,"MECANICO MANUTENCAO",   4750.00, 'M', 220),
          (6010,"ESTAGIARIO TI",         1650.00, 'M', 120)]

DEPTOS = [(1000, 101000), (2000, 202000), (3000, 303000),
          (4000, 404000), (5000, 505000), (6000, 606000)]
BANCOS = [341, 237, 104, 1, 33, 260]

# ---------------------------------------------------------------- eventos
# codigo, descricao, natureza, tipo-calc, INSS,IRRF,FGTS,DSR,13,FER,
# unidade, percentual, conta contabil
EVENTOS = [
 (   1,"SALARIO BASE MENSAL",         'P',  1,"SSSSSS",'DI',   0,31110001),
 (   2,"SALARIO HORISTA",             'P',  1,"SSSSSS",'HR',   0,31110001),
 (  10,"HORAS EXTRAS 50%",            'P',  2,"SSSSSS",'HR', 150,31110010),
 (  11,"HORAS EXTRAS 100%",           'P',  2,"SSSSSS",'HR', 200,31110011),
 (  12,"D.S.R. SOBRE HORAS EXTRAS",   'P',  1,"SSSSNS",'DI',   0,31110012),
 (  13,"ADICIONAL NOTURNO",           'P',  2,"SSSSSS",'HR',  20,31110013),
 (  14,"D.S.R. ADICIONAL NOTURNO",    'P',  1,"SSSSNS",'DI',   0,31110014),
 (  20,"ADICIONAL INSALUBRIDADE",     'P',  5,"SSSSSS",'PC',  20,31110020),
 (  21,"ADICIONAL PERICULOSIDADE",    'P',  4,"SSSSSS",'PC',  30,31110021),
 (  22,"ADIC.TEMPO SERVICO QUINQ",    'P',  4,"SSSSSS",'PC',   5,31110022),
 (  30,"SALARIO FAMILIA",             'P',  1,"NNNNNN",'VL',   0,31110030),
 (  40,"COMISSAO SOBRE VENDAS",       'P',  6,"SSSSSS",'PC',   0,31110040),
 (  41,"GRATIFICACAO DE FUNCAO",      'P',  4,"SSSSSS",'PC',   0,31110041),
 (  42,"PREMIO PRODUTIVIDADE",        'P',  1,"SSSSNN",'VL',   0,31110042),
 (  43,"AJUDA DE CUSTO",              'P',  1,"NNNNNN",'VL',   0,31110043),
 (  44,"DIARIAS DE VIAGEM",           'P', 10,"NNNNNN",'DI',   0,31110044),
 (  45,"ABONO PECUNIARIO",            'P',  1,"NNSNNN",'VL',   0,31110045),
 (  46,"HORAS SOBREAVISO",            'P',  2,"SSSSSS",'HR',  33,31110046),
 (  50,"13o SALARIO INTEGRAL",        'P',  1,"SSSNNN",'VL',   0,31110050),
 (  60,"FERIAS GOZADAS",              'P',  3,"SSSNNN",'DI',   0,31110060),
 (  61,"1/3 CONSTITUCIONAL FERIAS",   'P',  1,"SSSNNN",'VL',   0,31110061),
 ( 500,"FALTAS INJUSTIFICADAS",       'D',  3,"NNNNNN",'DI',   0,31110500),
 ( 501,"D.S.R. SOBRE FALTAS",         'D',  3,"NNNNNN",'DI',   0,31110501),
 ( 502,"ATRASOS E SAIDAS ANTECIP",    'D',  2,"NNNNNN",'HR', 100,31110502),
 ( 510,"I.N.S.S. SOBRE SALARIOS",     'D',  1,"NNNNNN",'PC',   0,21310001),
 ( 511,"I.R.R.F. SOBRE SALARIOS",     'D',  1,"NNNNNN",'PC',   0,21320001),
 ( 520,"VALE TRANSPORTE",             'D',  4,"NNNNNN",'PC',   6,21330001),
 ( 521,"VALE REFEICAO",               'D',  1,"NNNNNN",'VL',   0,21330002),
 ( 522,"PLANO DE SAUDE",              'D',  1,"NNNNNN",'VL',   0,21330003),
 ( 523,"SEGURO DE VIDA EM GRUPO",     'D',  1,"NNNNNN",'VL',   0,21330004),
 ( 524,"FARMACIA CONVENIADA",         'D',  1,"NNNNNN",'VL',   0,21330005),
 ( 530,"PENSAO ALIMENTICIA",          'D',  1,"NNNNNN",'PC',   0,21340001),
 ( 531,"EMPRESTIMO CONSIGNADO",       'D',  1,"NNNNNN",'VL',   0,21350001),
 ( 532,"ADIANTAMENTO QUINZENAL",      'D',  1,"NNNNNN",'PC',   0,21360001),
 ( 533,"ADIANTAMENTO 13o SALARIO",    'D',  1,"NNNNNN",'VL',   0,21360002),
 ( 540,"CONTRIBUICAO SINDICAL",       'D',  4,"NNNNNN",'PC',   0,21370001),
 ( 541,"MENSALIDADE ASSOCIATIVA",     'D',  1,"NNNNNN",'VL',   0,21370002),
 ( 550,"ARREDONDAMENTO MES ANTER",    'D',  1,"NNNNNN",'VL',   0,21380001),
 ( 551,"SALDO DEVEDOR A COMPENSAR",   'D',  1,"NNNNNN",'VL',   0,21380002),
 ( 900,"BASE DE CALCULO INSS",        'I',  1,"NNNNNN",'VL',   0,       0),
 ( 901,"BASE DE CALCULO IRRF",        'I',  1,"NNNNNN",'VL',   0,       0),
 ( 902,"BASE DE CALCULO FGTS",        'I',  1,"NNNNNN",'VL',   0,       0),
 ( 903,"F.G.T.S. DO MES",             'I',  1,"NNNNNN",'PC',   0,31210001),
 ( 999,"LIQUIDO A RECEBER",           'I',  1,"NNNNNN",'VL',   0,       0)]

def grava_eventos():
    linhas = []
    for cod, desc, nat, tpc, inc, uni, perc, conta in EVENTOS:
        linhas.append(N(cod,4) + A(desc,30) + nat + N(tpc,3) + inc +
                      A(uni,2) + V(perc,3) + N(conta,8) + 'A' + ' '*20)
    linhas.sort()
    return linhas

# ------------------------------------------------- tabelas legais (SFPTAB)
def grava_tabelas():
    L = []
    def reg(tipo, seq, chave, limite, aliq, ded, desc):
        return (tipo + COMPETENCIA + N(seq,2) + A(chave,15) +
                V(limite,9) + V(aliq,3) + V(ded,9) + A(desc,27))
    # --- INSS: faixas progressivas. A deducao da ultima faixa carrega o teto
    L.append(reg('INS',1,'FAIXA-01',  1518.00, 7.50, 0,      'ATE 1.518,00 - 7,5%'))
    L.append(reg('INS',2,'FAIXA-02',  2793.88, 9.00, 0,      'DE 1.518,01 A 2.793,88'))
    L.append(reg('INS',3,'FAIXA-03',  4190.83,12.00, 0,      'DE 2.793,89 A 4.190,83'))
    L.append(reg('INS',4,'FAIXA-04',  8157.41,14.00, 951.63, 'DE 4.190,84 A 8.157,41'))
    # --- IRRF
    L.append(reg('IRF',1,'FAIXA-01',  2428.80, 0.00,   0.00, 'ISENTO'))
    L.append(reg('IRF',2,'FAIXA-02',  2826.65, 7.50, 182.16, 'ALIQUOTA 7,5%'))
    L.append(reg('IRF',3,'FAIXA-03',  3751.05,15.00, 394.16, 'ALIQUOTA 15%'))
    L.append(reg('IRF',4,'FAIXA-04',  4664.68,22.50, 675.49, 'ALIQUOTA 22,5%'))
    L.append(reg('IRF',5,'FAIXA-05',999999.99,27.50, 908.73, 'ALIQUOTA 27,5%'))
    # --- Salario familia
    L.append(reg('SFA',1,'COTA-UNICA', 1906.04, 0.00, 65.00, 'COTA POR FILHO ATE 14A'))
    # --- Parametros gerais
    P = [('SALARIO-MINIMO', 1518.00, 0.00,    0.00, 'SALARIO MINIMO NACIONAL'),
         ('DEDUCAO-DEP-IR',    0.00, 0.00,  189.59, 'DEDUCAO POR DEPENDENTE'),
         ('DESC-SIMPLIFIC',    0.00, 0.00,  607.20, 'DESCONTO SIMPLIFICADO'),
         ('PERC-FGTS',         0.00, 8.00,    0.00, 'ALIQUOTA FGTS MENSAL'),
         ('PERC-VALE-TRAN',    0.00, 6.00,    0.00, 'LIMITE DESCONTO VT'),
         ('PERC-ADIANTAME',    0.00,40.00,    0.00, 'ADIANTAMENTO QUINZENAL'),
         ('MARGEM-CONSIGN',    0.00,35.00,    0.00, 'MARGEM CONSIGNAVEL'),
         ('PERC-HORA-EX50',    0.00,50.00,    0.00, 'ACRESCIMO HORA EXTRA 50'),
         ('PERC-HORA-E100',    0.00,100.00,   0.00, 'ACRESCIMO HORA EXTRA 100'),
         ('PERC-AD-NOTURN',    0.00,20.00,    0.00, 'ADICIONAL NOTURNO'),
         ('PERC-PERICULOS',    0.00,30.00,    0.00, 'ADICIONAL PERICULOSIDADE'),
         ('PERC-QUINQUENI',    0.00, 5.00,    0.00, 'PERC POR QUINQUENIO'),
         ('MAX-QUINQUENIO',    5.00, 0.00,    0.00, 'MAXIMO DE QUINQUENIOS'),
         ('CONTRIB-SINDIC',    0.00, 1.00,    0.00, 'CONTRIBUICAO SINDICAL')]
    for i,(ch,lim,al,de,ds) in enumerate(P, start=1):
        L.append(reg('PAR', i, ch, lim, al, de, ds))
    return L

# ------------------------------------------------------------- empregados
def gera_empregados(qtd=60):
    emps, deps, pons, movs = [], [], [], []
    matricula = 10000
    seq_cpf = 100000000
    for i in range(qtd):
        matricula += random.randint(3, 19)
        cargo, desc_cargo, sal, tipo, carga = random.choice(CARGOS)
        depto, cc = random.choice(DEPTOS)
        nome = f"{random.choice(PRE)} {random.choice(SOB)} {random.choice(SOB)}"
        seq_cpf += random.randint(1, 999)
        cpf = dv_cpf(str(seq_cpf).rjust(9, '0'))
        pis = str(random.randint(10000000000, 99999999999))
        ano_adm = random.randint(1998, 2026)
        mes_adm = random.randint(1, 12)
        dia_adm = random.randint(1, 28)
        if ano_adm == 2026 and mes_adm > MES:
            mes_adm = MES
        adm = f"{ano_adm}{mes_adm:02d}{dia_adm:02d}"
        nasc = f"{random.randint(1962, 2004)}{random.randint(1,12):02d}" \
               f"{random.randint(1,28):02d}"
        # variacao salarial individual
        salario = round(sal * random.uniform(0.92, 1.35), 2)
        situacao = 'A'
        demissao = 0
        r = random.random()
        if r > 0.95:
            situacao = 'D'
            demissao = int(f"{ANO}{MES:02d}{random.randint(5,28):02d}")
        elif r > 0.90:
            situacao = 'F'
        elif r > 0.87:
            situacao = 'L'

        n_dep_ir = random.choice([0,0,0,1,1,2,2,3])
        n_dep_sf = 0
        insalub  = random.choice([0,0,0,0,10,20,40])
        pericul  = 'S' if (insalub == 0 and random.random() > 0.85) else 'N'
        ind_vt   = 'S' if random.random() > 0.35 else 'N'
        vlr_vt   = round(random.uniform(180, 520), 2) if ind_vt=='S' else 0
        ind_vr   = 'S' if random.random() > 0.25 else 'N'
        vlr_vr   = round(random.uniform(45, 190), 2) if ind_vr=='S' else 0
        ind_ps   = 'S' if random.random() > 0.45 else 'N'
        vlr_ps   = round(random.uniform(90, 380), 2) if ind_ps=='S' else 0
        perc_pen = 0; vlr_pen = 0
        if random.random() > 0.90:
            if random.random() > 0.5:
                perc_pen = random.choice([15.00, 20.00, 25.00, 30.00])
            else:
                vlr_pen = round(random.uniform(400, 1800), 2)
        vlr_cons = 0; parc_cons = 0
        if random.random() > 0.75:
            vlr_cons  = round(random.uniform(250, 2600), 2)
            parc_cons = random.randint(6, 60)
        ind_adi = 'S' if random.random() > 0.55 else 'N'
        perc_adi = 40 if ind_adi == 'S' else 0
        sindic  = 'S' if random.random() > 0.70 else 'N'
        banco = random.choice(BANCOS)
        agencia = random.randint(100, 9999)
        conta = random.randint(1000, 99999999)
        media_var = round(random.uniform(0, 2200), 2)
        saldo_fgts = round(salario * random.uniform(0.5, 28), 2)

        # dependentes
        filhos = 0
        for d in range(n_dep_ir):
            ano_n = random.randint(2006, 2025)
            ate14 = (ANO - ano_n) <= 14
            ind_sf = 'S' if ate14 else 'N'
            if ind_sf == 'S':
                filhos += 1
            vps = round(random.uniform(60, 220), 2) if ind_ps == 'S' else 0
            deps.append(N(matricula,8) + N(d+1,2) +
                        A(f"{random.choice(PRE)} {random.choice(SOB)}",35) +
                        f"{ano_n}{random.randint(1,12):02d}"
                        f"{random.randint(1,28):02d}" +
                        N(3,2) + 'S' + ind_sf +
                        ('S' if vps>0 else 'N') + V(vps,7) + ' '*13)
        n_dep_sf = filhos

        # ---- dados pessoais, documentos e endereco
        # Todos os codigos abaixo existem em SFPDOM.DAT / SFPMUN.DAT,
        # de modo que a critica de dominio da tela SFP0100 aprova
        # qualquer registro desta massa.
        sexo      = random.choice('MF')
        instrucao = random.choice([5,6,7,7,7,8,9,9,10,11])
        est_civil = random.choice('SSCCCDVU')
        raca      = random.choice([1,1,2,3,3,3,4,5,6])
        nacional  = random.choice([10,10,10,10,10,20,250,450])
        mun, uf   = random.choice(MUNICIPIOS_MASSA)
        mun_nasc, uf_nasc = random.choice(MUNICIPIOS_MASSA)
        nome_mae  = f"{random.choice(PRE_F)} {random.choice(SOB)} " \
                    f"{random.choice(SOB)}"
        tem_defic = 'S' if random.random() > 0.94 else 'N'
        tipo_def  = random.randint(1,6) if tem_defic == 'S' else 0
        ctps_num  = random.randint(1000000, 9999999)
        ctps_ser  = random.randint(10, 9999)
        rg_num    = f"{random.randint(1000000, 99999999)}"
        rg_orgao  = random.choice(['SSP-PR','SSP-SP','SSP-RJ','SSP-MG',
                                   'SSP-RS','SSP-SC','DETRAN'])
        titulo    = random.randint(100000000000, 999999999999)
        tlg       = random.choice(['RUA','RUA','RUA','AV','TV','PC','AL'])
        logra     = f"{random.choice(LOGRADOUROS)}"
        num_end   = str(random.randint(10, 4999))
        compl     = random.choice(['','APTO 101','CASA 2','BLOCO B',
                                   'FUNDOS','APTO 304'])
        bairro    = random.choice(BAIRROS)
        cep       = random.randint(80000000, 89999999)
        telefone  = f"{random.choice([41,11,21,31,51,47])}9" \
                    f"{random.randint(10000000, 99999999)}"
        estabelec = 1 if uf != 'SP' else random.choice([1,2])
        vinculo   = random.choice([1,1,1,1,1,2,3,4])
        jornada   = 1 if carga == 220 else (2 if carga == 200 else 3)
        horario   = random.choice([1,1,1,2,3,4])

        emps.append(
            N(matricula,8) + A(nome,40) + cpf + pis + adm + N(demissao,8) +
            nasc + situacao + N(cargo,4) + N(depto,4) + N(cc,6) +
            V(salario,9) + tipo + N(carga,3) + N(n_dep_ir,2) +
            N(n_dep_sf,2) + N(insalub,2) + pericul + ind_vt + V(vlr_vt,7) +
            ind_vr + V(vlr_vr,7) + ind_ps + V(vlr_ps,7) + V(perc_pen,3) +
            V(vlr_pen,7) + V(vlr_cons,7) + N(parc_cons,3) + ind_adi +
            N(perc_adi,3) + sindic + N(banco,3) + N(agencia,5) +
            N(conta,12) + str(random.randint(0,9)) + '1' + N(101,3) +
            # --- dados pessoais
            sexo + N(instrucao,2) + est_civil + N(raca,2) +
            N(nacional,3) + A(uf_nasc,2) + N(mun_nasc,7) +
            A(nome_mae,40) + tem_defic + N(tipo_def,2) +
            # --- documentos
            N(ctps_num,8) + N(ctps_ser,5) + A(uf,2) +
            A(rg_num,15) + A(rg_orgao,8) + N(titulo,12) +
            # --- endereco
            A(tlg,3) + A(logra,40) + A(num_end,8) + A(compl,15) +
            A(bairro,25) + N(mun,7) + A(uf,2) + N(cep,8) +
            # --- contato e vinculo
            A(telefone,14) + N(estabelec,4) + N(vinculo,2) +
            N(jornada,2) + N(horario,3) +
            V(media_var,9) + V(saldo_fgts,9) + ' '*17)

        # ---- ponto do mes
        dias_uteis = 21
        faltas = 0; dsr_perd = 0; atrasos = 0
        if random.random() > 0.82:
            faltas = random.randint(1, 3)
            dsr_perd = random.randint(1, faltas)
        if random.random() > 0.75:
            atrasos = random.randint(10, 240)
        he50 = round(random.uniform(0, 32), 2) if random.random() > 0.45 else 0
        he100 = round(random.uniform(0, 14), 2) if random.random() > 0.80 else 0
        not_h = round(random.uniform(0, 60), 2) if random.random() > 0.78 else 0
        dias_afast = random.randint(3, 15) if situacao == 'L' else 0
        dias_fer = random.randint(10, 30) if situacao == 'F' else 0
        hn = round(dias_uteis * 8 - faltas * 8 - atrasos / 60, 2)
        pons.append(N(matricula,8) + COMPETENCIA + N(dias_uteis-faltas,3) +
                    N(dias_uteis,3) + V(hn,5) + V(he50,5) + V(he100,5) +
                    V(not_h,5) + N(faltas,3) + N(atrasos,5) + N(dsr_perd,3) +
                    N(dias_afast,3) + N(dias_fer,3) + ' '*15)

        # ---- movimentos eventuais
        possiveis = []
        if random.random() > 0.72:
            possiveis.append((40, round(random.uniform(3,12),2), 0))     # comissao %
        if random.random() > 0.80:
            possiveis.append((41, round(random.uniform(10,40),2), 0))    # gratif %
        if random.random() > 0.85:
            possiveis.append((42, 0, round(random.uniform(300,2500),2))) # premio
        if random.random() > 0.88:
            possiveis.append((44, random.randint(1,6), round(random.uniform(90,260),2)))
        if random.random() > 0.90:
            possiveis.append((523, 0, round(random.uniform(25,90),2)))
        if random.random() > 0.86:
            possiveis.append((524, 0, round(random.uniform(30,400),2)))
        if random.random() > 0.92:
            possiveis.append((541, 0, round(random.uniform(20,75),2)))
        if random.random() > 0.97:
            possiveis.append((9999, 0, 500.00))   # evento inexistente: critica
        for ev, ref, val in sorted(possiveis):
            movs.append(N(matricula,8) + COMPETENCIA + N(ev,4) + V(ref,5) +
                        V(val,9) + 'E' + 'RH ' + f"{ANO}{MES:02d}05" +
                        A("OPER0417",8) + ' ' + ' '*43)

    # movimento orfao proposital (matricula inexistente) -> critica 0220
    movs.append(N(99999990,8) + COMPETENCIA + N(42,4) + V(0,5) + V(750.00,9) +
                'E' + 'RH ' + f"{ANO}{MES:02d}05" + A("OPER0417",8) +
                ' ' + ' '*43)
    return emps, deps, pons, sorted(movs)


# ---- apoio aos dados pessoais (coerentes com SFPDOM.DAT/SFPMUN.DAT)
MUNICIPIOS_MASSA = [
    (4106902,'PR'), (4113700,'PR'), (4115200,'PR'), (4119905,'PR'),
    (4104808,'PR'), (4125506,'PR'), (3550308,'SP'), (3509502,'SP'),
    (3548708,'SP'), (3304557,'RJ'), (3106200,'MG'), (4314902,'RS'),
    (4205407,'SC'), (4209102,'SC'), (2927408,'BA'), (5300108,'DF'),
]

PRE_F = ["MARIA","ANA","TEREZA","LUCIA","SANDRA","ROSANGELA","CLEUSA",
         "IVONE","MARLENE","SONIA","VERA","NEUSA","APARECIDA","ELZA"]

LOGRADOUROS = ["DAS ACACIAS","SAO JOAO","MARECHAL DEODORO","XV DE NOVEMBRO",
               "DOM PEDRO II","SETE DE SETEMBRO","DAS FLORES","BRASIL",
               "SANTOS DUMONT","TIRADENTES","GETULIO VARGAS","DAS PALMEIRAS",
               "JOAO PESSOA","RIO BRANCO","DOS ANDRADAS","CONSELHEIRO LAURINDO"]

BAIRROS = ["CENTRO","VILA NOVA","JARDIM AMERICA","SANTA FELICIDADE",
           "BOA VISTA","PORTAO","AGUA VERDE","CAJURU","BACACHERI",
           "PINHEIRINHO","SITIO CERCADO","CIDADE INDUSTRIAL","XAXIM",
           "CAMPO COMPRIDO","FAZENDINHA","NOVO MUNDO"]

# ---------------------------------------------------------------- main
def escrever(nome, linhas, tam):
    caminho = os.path.join(DEST, nome)
    with open(caminho, 'w', encoding='ascii') as f:
        for l in linhas:
            if len(l) != tam:
                raise ValueError(f"{nome}: registro com {len(l)} bytes "
                                 f"(esperado {tam}) -> {l[:40]}")
            f.write(l + "\n")
    print(f"  {nome:<14} {len(linhas):>5} registros x {tam:>3} bytes")

if __name__ == '__main__':
    os.makedirs(DEST, exist_ok=True)
    print("Gerando massa de dados ficticios do SFP...")
    emps, deps, pons, movs = gera_empregados(60)
    escrever('SFPEMP.DAT', emps, 500)
    escrever('SFPDEP.DAT', deps, 80)
    escrever('SFPPON.DAT', pons, 80)
    escrever('SFPMOV.DAT', movs, 100)
    escrever('SFPEVE.DAT', grava_eventos(), 80)
    escrever('SFPTAB.DAT', grava_tabelas(), 80)
    escrever('SYSIN.DAT', [ (COMPETENCIA + " 1 " + "000000" + " " +
                             "999999" + " " + "N" + " " +
                             f"{ANO}{MES:02d}05").ljust(80) ], 80)
    print("Massa gerada em:", DEST)
