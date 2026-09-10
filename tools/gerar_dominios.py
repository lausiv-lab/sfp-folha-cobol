#!/usr/bin/env python3
"""Gera as tabelas de dominio, UF, municipios, cargos,
departamentos e estabelecimentos do sistema SFP.

Estes arquivos alimentam as listas de selecao das telas CICS
(tecla F4 abre a janela de consulta) e as criticas de dominio
dos programas de cadastro."""
import os
import random

DEST = os.path.join(os.path.dirname(__file__), '..', 'dados')
random.seed(20260909)


def A(t, n):
    return str(t)[:n].ljust(n)


def N(v, n):
    return str(int(v)).zfill(n)[-n:]


def V(v, n):
    return str(int(round(float(v) * 100))).zfill(n + 2)[-(n + 2):]


# ------------------------------------------------------ dominios
# (tipo, codigo, descricao, reduzida, ordem, valor auxiliar)
DOMINIOS = [
    # --- sexo -------------------------------------------------
    ('SEX', 'M', 'MASCULINO', 'MASC', 1, ''),
    ('SEX', 'F', 'FEMININO', 'FEM', 2, ''),
    # --- estado civil -----------------------------------------
    ('ECI', 'S', 'SOLTEIRO(A)', 'SOLTEIRO', 1, ''),
    ('ECI', 'C', 'CASADO(A)', 'CASADO', 2, ''),
    ('ECI', 'D', 'DIVORCIADO(A)', 'DIVORCIADO', 3, ''),
    ('ECI', 'V', 'VIUVO(A)', 'VIUVO', 4, ''),
    ('ECI', 'U', 'UNIAO ESTAVEL', 'UNIAO EST', 5, ''),
    ('ECI', 'P', 'SEPARADO(A) JUDICIALMENTE', 'SEPARADO', 6, ''),
    # --- grau de instrucao (tabela 18 do eSocial) -------------
    ('INS', '01', 'ANALFABETO', 'ANALFABETO', 1, ''),
    ('INS', '02', 'ATE 5o ANO INCOMPLETO', 'ATE 5o INC', 2, ''),
    ('INS', '03', '5o ANO COMPLETO', '5o COMPL', 3, ''),
    ('INS', '04', 'DO 6o AO 9o ANO INCOMPLETO', '6o A 9o', 4, ''),
    ('INS', '05', 'ENSINO FUNDAMENTAL COMPLETO', 'FUND COMPL', 5, ''),
    ('INS', '06', 'ENSINO MEDIO INCOMPLETO', 'MEDIO INC', 6, ''),
    ('INS', '07', 'ENSINO MEDIO COMPLETO', 'MEDIO COMP', 7, ''),
    ('INS', '08', 'SUPERIOR INCOMPLETO', 'SUP INCOMP', 8, ''),
    ('INS', '09', 'SUPERIOR COMPLETO', 'SUP COMPL', 9, ''),
    ('INS', '10', 'POS-GRADUACAO COMPLETA', 'POS-GRAD', 10, ''),
    ('INS', '11', 'MESTRADO COMPLETO', 'MESTRADO', 11, ''),
    ('INS', '12', 'DOUTORADO COMPLETO', 'DOUTORADO', 12, ''),
    # --- raca / cor (tabela 15 do eSocial) --------------------
    ('RAC', '01', 'BRANCA', 'BRANCA', 1, ''),
    ('RAC', '02', 'PRETA', 'PRETA', 2, ''),
    ('RAC', '03', 'PARDA', 'PARDA', 3, ''),
    ('RAC', '04', 'AMARELA', 'AMARELA', 4, ''),
    ('RAC', '05', 'INDIGENA', 'INDIGENA', 5, ''),
    ('RAC', '06', 'NAO INFORMADO', 'NAO INFORM', 6, ''),
    # --- nacionalidade ----------------------------------------
    ('NAC', '010', 'BRASILEIRA', 'BRASILEIRA', 1, ''),
    ('NAC', '020', 'BRASILEIRA NATURALIZADA', 'NATURALIZ', 2, ''),
    ('NAC', '070', 'ARGENTINA', 'ARGENTINA', 3, ''),
    ('NAC', '080', 'BOLIVIANA', 'BOLIVIANA', 4, ''),
    ('NAC', '250', 'PORTUGUESA', 'PORTUGUESA', 5, ''),
    ('NAC', '450', 'HAITIANA', 'HAITIANA', 6, ''),
    ('NAC', '900', 'OUTRA NACIONALIDADE', 'OUTRA', 9, ''),
    # --- parentesco do dependente -----------------------------
    ('PAR', '01', 'CONJUGE', 'CONJUGE', 1, 'IRRF'),
    ('PAR', '02', 'COMPANHEIRO(A)', 'COMPANHEIR', 2, 'IRRF'),
    ('PAR', '03', 'FILHO(A)', 'FILHO', 3, 'IRRF/SF'),
    ('PAR', '04', 'ENTEADO(A)', 'ENTEADO', 4, 'IRRF/SF'),
    ('PAR', '05', 'TUTELADO(A) OU CURATELADO(A)', 'TUTELADO', 5, 'IRRF'),
    ('PAR', '06', 'PAI OU MAE', 'PAI/MAE', 6, 'IRRF'),
    ('PAR', '07', 'IRMAO(A)', 'IRMAO', 7, 'IRRF'),
    ('PAR', '09', 'AGREGADO / OUTROS', 'OUTROS', 9, ''),
    # --- tipo de conta bancaria -------------------------------
    ('TCO', '1', 'CONTA CORRENTE INDIVIDUAL', 'C/CORRENTE', 1, '01'),
    ('TCO', '2', 'CONTA POUPANCA INDIVIDUAL', 'POUPANCA', 2, '02'),
    ('TCO', '3', 'CONTA SALARIO', 'C/SALARIO', 3, '03'),
    ('TCO', '4', 'CONTA PAGAMENTO / DIGITAL', 'C/PAGTO', 4, '04'),
    # --- tipo de logradouro -----------------------------------
    ('TLG', 'RUA', 'RUA', 'RUA', 1, ''),
    ('TLG', 'AV', 'AVENIDA', 'AVENIDA', 2, ''),
    ('TLG', 'TV', 'TRAVESSA', 'TRAVESSA', 3, ''),
    ('TLG', 'PC', 'PRACA', 'PRACA', 4, ''),
    ('TLG', 'ROD', 'RODOVIA', 'RODOVIA', 5, ''),
    ('TLG', 'EST', 'ESTRADA', 'ESTRADA', 6, ''),
    ('TLG', 'AL', 'ALAMEDA', 'ALAMEDA', 7, ''),
    ('TLG', 'VL', 'VILA', 'VILA', 8, ''),
    # --- categoria eSocial ------------------------------------
    ('CAT', '101', 'EMPREGADO GERAL', 'EMPREG GER', 1, ''),
    ('CAT', '102', 'EMPREGADO TRABALHO INTERMITENTE', 'INTERMITEN', 2, ''),
    ('CAT', '103', 'EMPREGADO APRENDIZ', 'APRENDIZ', 3, ''),
    ('CAT', '104', 'EMPREGADO DOMESTICO', 'DOMESTICO', 4, ''),
    ('CAT', '105', 'EMPREGADO CONTRATO A TERMO', 'A TERMO', 5, ''),
    ('CAT', '701', 'CONTRIBUINTE INDIVIDUAL AUTONOMO', 'AUTONOMO', 7, ''),
    ('CAT', '721', 'DIRETOR NAO EMPREGADO COM FGTS', 'DIRETOR', 8, ''),
    # --- motivo de rescisao -----------------------------------
    ('MRE', '01', 'DISPENSA SEM JUSTA CAUSA', 'S/JUSTA C', 1, 'AV=S MU=S'),
    ('MRE', '02', 'PEDIDO DE DEMISSAO', 'PEDIDO', 2, 'AV=N MU=N'),
    ('MRE', '03', 'DISPENSA POR JUSTA CAUSA', 'JUSTA CAUS', 3, 'AV=N MU=N'),
    ('MRE', '04', 'TERMINO DE CONTRATO A TERMO', 'TERMINO', 4, 'AV=N MU=N'),
    ('MRE', '05', 'ACORDO ENTRE AS PARTES ART 484-A', 'ACORDO', 5, 'AV=M MU=M'),
    ('MRE', '06', 'APOSENTADORIA', 'APOSENTAD', 6, 'AV=N MU=N'),
    ('MRE', '07', 'FALECIMENTO DO EMPREGADO', 'FALECIMENT', 7, 'AV=N MU=N'),
    # --- situacao do empregado --------------------------------
    ('SIT', 'A', 'ATIVO', 'ATIVO', 1, ''),
    ('SIT', 'F', 'EM FERIAS', 'FERIAS', 2, ''),
    ('SIT', 'L', 'AFASTADO / LICENCA', 'AFASTADO', 3, ''),
    ('SIT', 'D', 'DEMITIDO', 'DEMITIDO', 4, ''),
    # --- tipo de salario --------------------------------------
    ('TSA', 'M', 'MENSALISTA', 'MENSALISTA', 1, ''),
    ('TSA', 'H', 'HORISTA', 'HORISTA', 2, ''),
    ('TSA', 'D', 'DIARISTA', 'DIARISTA', 3, ''),
    # --- tipo de lancamento -----------------------------------
    ('TLA', 'F', 'FIXO (REPETE TODO MES)', 'FIXO', 1, ''),
    ('TLA', 'M', 'MENSAL (SO NA COMPETENCIA)', 'MENSAL', 2, ''),
    ('TLA', 'E', 'EVENTUAL', 'EVENTUAL', 3, ''),
    # --- unidade da rubrica -----------------------------------
    ('UNI', 'HR', 'HORAS', 'HORAS', 1, ''),
    ('UNI', 'DI', 'DIAS', 'DIAS', 2, ''),
    ('UNI', 'PC', 'PERCENTUAL', 'PERCENTUAL', 3, ''),
    ('UNI', 'VL', 'VALOR EM REAIS', 'VALOR', 4, ''),
    ('UNI', 'QT', 'QUANTIDADE', 'QUANTIDADE', 5, ''),
    # --- natureza da rubrica ----------------------------------
    ('NAT', 'P', 'PROVENTO', 'PROVENTO', 1, ''),
    ('NAT', 'D', 'DESCONTO', 'DESCONTO', 2, ''),
    ('NAT', 'I', 'INFORMATIVO', 'INFORMAT', 3, ''),
    ('NAT', 'B', 'BASE DE CALCULO', 'BASE', 4, ''),
    # --- tipo de folha ----------------------------------------
    ('TFO', '1', 'FOLHA MENSAL', 'MENSAL', 1, ''),
    ('TFO', '2', 'ADIANTAMENTO SALARIAL', 'ADIANTAMEN', 2, ''),
    ('TFO', '3', '13o SALARIO PRIMEIRA PARCELA', '13o 1a PAR', 3, ''),
    ('TFO', '4', '13o SALARIO SEGUNDA PARCELA', '13o 2a PAR', 4, ''),
    ('TFO', '5', 'FERIAS', 'FERIAS', 5, ''),
    ('TFO', '6', 'RESCISAO CONTRATUAL', 'RESCISAO', 6, ''),
    # --- tipo de vinculo --------------------------------------
    ('VIN', '01', 'CLT PRAZO INDETERMINADO', 'CLT INDET', 1, ''),
    ('VIN', '02', 'CLT PRAZO DETERMINADO', 'CLT DETERM', 2, ''),
    ('VIN', '03', 'CONTRATO DE EXPERIENCIA', 'EXPERIENC', 3, ''),
    ('VIN', '04', 'CONTRATO DE APRENDIZAGEM', 'APRENDIZ', 4, ''),
    ('VIN', '05', 'CONTRATO INTERMITENTE', 'INTERMITEN', 5, ''),
    ('VIN', '06', 'ESTAGIO', 'ESTAGIO', 6, ''),
    # --- tipo de jornada --------------------------------------
    ('JOR', '01', '44 HORAS SEMANAIS', '44H SEM', 1, '220'),
    ('JOR', '02', '40 HORAS SEMANAIS', '40H SEM', 2, '200'),
    ('JOR', '03', '36 HORAS SEMANAIS', '36H SEM', 3, '180'),
    ('JOR', '04', '30 HORAS SEMANAIS', '30H SEM', 4, '150'),
    ('JOR', '05', '20 HORAS SEMANAIS - MEIO PERIODO', '20H SEM', 5, '100'),
    ('JOR', '06', 'ESCALA 12X36', '12X36', 6, '180'),
    # --- tipo de deficiencia ----------------------------------
    ('DEF', '01', 'DEFICIENCIA FISICA', 'FISICA', 1, ''),
    ('DEF', '02', 'DEFICIENCIA AUDITIVA', 'AUDITIVA', 2, ''),
    ('DEF', '03', 'DEFICIENCIA VISUAL', 'VISUAL', 3, ''),
    ('DEF', '04', 'DEFICIENCIA INTELECTUAL', 'INTELECT', 4, ''),
    ('DEF', '05', 'DEFICIENCIA MULTIPLA', 'MULTIPLA', 5, ''),
    ('DEF', '06', 'REABILITADO PELO INSS', 'REABILIT', 6, ''),
    # --- motivo de afastamento --------------------------------
    ('AFA', '01', 'ACIDENTE DE TRABALHO ATE 15 DIAS', 'ACID ATE15', 1, ''),
    ('AFA', '03', 'ACIDENTE DE TRABALHO APOS 15 DIAS', 'ACID +15', 2, ''),
    ('AFA', '15', 'AUXILIO-DOENCA PREVIDENCIARIO', 'AUX DOENCA', 3, ''),
    ('AFA', '17', 'LICENCA MATERNIDADE', 'LIC MATERN', 4, ''),
    ('AFA', '18', 'LICENCA PATERNIDADE', 'LIC PATERN', 5, ''),
    ('AFA', '19', 'SERVICO MILITAR OBRIGATORIO', 'SERV MILIT', 6, ''),
    ('AFA', '20', 'LICENCA SEM VENCIMENTOS', 'LIC S/VENC', 7, ''),
    # --- horario de trabalho ----------------------------------
    ('HOR', '001', 'ADMINISTRATIVO 08:00 AS 18:00', 'ADM 08-18', 1, '220'),
    ('HOR', '002', 'PRIMEIRO TURNO 06:00 AS 14:00', '1o TURNO', 2, '220'),
    ('HOR', '003', 'SEGUNDO TURNO 14:00 AS 22:00', '2o TURNO', 3, '220'),
    ('HOR', '004', 'TERCEIRO TURNO 22:00 AS 06:00', '3o TURNO', 4, '220'),
    ('HOR', '005', 'ESCALA 12X36 DIURNA', '12X36 DIA', 5, '180'),
    ('HOR', '006', 'ESCALA 12X36 NOTURNA', '12X36 NOI', 6, '180'),
    # --- bancos -----------------------------------------------
    ('BAN', '001', 'BANCO DO BRASIL S.A.', 'BB', 1, ''),
    ('BAN', '033', 'BANCO SANTANDER BRASIL S.A.', 'SANTANDER', 2, ''),
    ('BAN', '104', 'CAIXA ECONOMICA FEDERAL', 'CAIXA', 3, ''),
    ('BAN', '237', 'BANCO BRADESCO S.A.', 'BRADESCO', 4, ''),
    ('BAN', '341', 'BANCO ITAU UNIBANCO S.A.', 'ITAU', 5, ''),
    ('BAN', '260', 'NU PAGAMENTOS S.A.', 'NUBANK', 6, ''),
    ('BAN', '077', 'BANCO INTER S.A.', 'INTER', 7, ''),
    ('BAN', '336', 'BANCO C6 S.A.', 'C6', 8, ''),
]

# ---------------------------------------------- meta-dominio TIP
# O catalogo dos proprios tipos vive dentro do SFPDOM sob o tipo
# TIP. Assim a tecla F4 do campo "tipo de dominio" no SFP0160 usa
# o SFP0900 sem caso especial, e o SFP0160 critica o tipo com uma
# leitura de arquivo em vez de uma tabela interna que sairia do ar
# ao se criar um dominio novo.
TIPOS = [
    ('SEX', 'SEXO', 'SEXO'),
    ('ECI', 'ESTADO CIVIL', 'EST CIVIL'),
    ('INS', 'GRAU DE INSTRUCAO', 'INSTRUCAO'),
    ('RAC', 'RACA / COR', 'RACA/COR'),
    ('NAC', 'NACIONALIDADE', 'NACIONALID'),
    ('PAR', 'GRAU DE PARENTESCO', 'PARENTESCO'),
    ('TCO', 'TIPO DE CONTA BANCARIA', 'TP CONTA'),
    ('TLG', 'TIPO DE LOGRADOURO', 'TP LOGRAD'),
    ('CAT', 'CATEGORIA ESOCIAL', 'CATEGORIA'),
    ('MRE', 'MOTIVO DE RESCISAO', 'MOT RESCIS'),
    ('SIT', 'SITUACAO DO EMPREGADO', 'SITUACAO'),
    ('TSA', 'TIPO DE SALARIO', 'TP SALARIO'),
    ('TLA', 'TIPO DE LANCAMENTO', 'TP LANCTO'),
    ('UNI', 'UNIDADE DA RUBRICA', 'UNIDADE'),
    ('NAT', 'NATUREZA DA RUBRICA', 'NATUREZA'),
    ('TFO', 'TIPO DE FOLHA', 'TP FOLHA'),
    ('VIN', 'TIPO DE VINCULO', 'TP VINCULO'),
    ('JOR', 'TIPO DE JORNADA', 'TP JORNADA'),
    ('BAN', 'BANCOS', 'BANCO'),
    ('DEF', 'TIPO DE DEFICIENCIA', 'TP DEFIC'),
    ('AFA', 'MOTIVO DE AFASTAMENTO', 'MOT AFAST'),
    ('HOR', 'HORARIO DE TRABALHO', 'HORARIO'),
]

# guarda contra deriva: todo tipo usado em DOMINIOS tem de estar
# catalogado em TIPOS e vice-versa
_usados = {t for t, *_ in DOMINIOS}
_catalogados = {t for t, *_ in TIPOS}
if _usados != _catalogados:
    raise SystemExit(
        'TIPOS fora de sincronia com DOMINIOS: '
        'so em DOMINIOS %s / so em TIPOS %s'
        % (sorted(_usados - _catalogados),
           sorted(_catalogados - _usados)))

DOMINIOS += [('TIP', cod, desc, red, i, '')
             for i, (cod, desc, red) in enumerate(TIPOS, start=1)]

# dominios que o SFP0160 recusa alterar ou excluir
PROTEGIDOS = ('TIP', 'SEX', 'NAT', 'UNI', 'TSA', 'SIT', 'TFO', 'TLA')


def grava_dominios():
    saida = []
    for tipo, cod, desc, red, ordem, aux in DOMINIOS:
        protegido = 'S' if tipo in PROTEGIDOS else 'N'
        saida.append(A(tipo, 3) + A(cod, 6) + A(desc, 35) +
                     A(red, 12) + N(ordem, 3) + A(aux, 10) +
                     'A' + protegido + ' ' * 9)
    return saida


# ------------------------------------------------------------ UF
UFS = [
    ('AC', 'ACRE', 12, 'NORTE', 'RIO BRANCO', 19.00),
    ('AL', 'ALAGOAS', 27, 'NORDESTE', 'MACEIO', 19.00),
    ('AM', 'AMAZONAS', 13, 'NORTE', 'MANAUS', 20.00),
    ('AP', 'AMAPA', 16, 'NORTE', 'MACAPA', 18.00),
    ('BA', 'BAHIA', 29, 'NORDESTE', 'SALVADOR', 20.50),
    ('CE', 'CEARA', 23, 'NORDESTE', 'FORTALEZA', 20.00),
    ('DF', 'DISTRITO FEDERAL', 53, 'CENTRO-OESTE', 'BRASILIA', 20.00),
    ('ES', 'ESPIRITO SANTO', 32, 'SUDESTE', 'VITORIA', 17.00),
    ('GO', 'GOIAS', 52, 'CENTRO-OESTE', 'GOIANIA', 19.00),
    ('MA', 'MARANHAO', 21, 'NORDESTE', 'SAO LUIS', 22.00),
    ('MG', 'MINAS GERAIS', 31, 'SUDESTE', 'BELO HORIZONTE', 18.00),
    ('MS', 'MATO GROSSO DO SUL', 50, 'CENTRO-OESTE', 'CAMPO GRANDE', 17.00),
    ('MT', 'MATO GROSSO', 51, 'CENTRO-OESTE', 'CUIABA', 17.00),
    ('PA', 'PARA', 15, 'NORTE', 'BELEM', 19.00),
    ('PB', 'PARAIBA', 25, 'NORDESTE', 'JOAO PESSOA', 20.00),
    ('PE', 'PERNAMBUCO', 26, 'NORDESTE', 'RECIFE', 20.50),
    ('PI', 'PIAUI', 22, 'NORDESTE', 'TERESINA', 21.00),
    ('PR', 'PARANA', 41, 'SUL', 'CURITIBA', 19.50),
    ('RJ', 'RIO DE JANEIRO', 33, 'SUDESTE', 'RIO DE JANEIRO', 20.00),
    ('RN', 'RIO GRANDE DO NORTE', 24, 'NORDESTE', 'NATAL', 20.00),
    ('RO', 'RONDONIA', 11, 'NORTE', 'PORTO VELHO', 19.50),
    ('RR', 'RORAIMA', 14, 'NORTE', 'BOA VISTA', 20.00),
    ('RS', 'RIO GRANDE DO SUL', 43, 'SUL', 'PORTO ALEGRE', 17.00),
    ('SC', 'SANTA CATARINA', 42, 'SUL', 'FLORIANOPOLIS', 17.00),
    ('SE', 'SERGIPE', 28, 'NORDESTE', 'ARACAJU', 19.00),
    ('SP', 'SAO PAULO', 35, 'SUDESTE', 'SAO PAULO', 18.00),
    ('TO', 'TOCANTINS', 17, 'NORTE', 'PALMAS', 20.00),
]


def grava_ufs():
    return [A(s, 2) + A(nome, 25) + N(ibge, 2) + A(reg, 12) +
            A(cap, 25) + V(icms, 2) + 'A' + ' ' * 9
            for s, nome, ibge, reg, cap, icms in UFS]


# ---------------------------------------------------- municipios
MUNICIPIOS = [
    (4106902, 'PR', 'CURITIBA', 7535, 'S', 80000000, 82999999),
    (4113700, 'PR', 'LONDRINA', 7625, 'N', 86000000, 86119999),
    (4115200, 'PR', 'MARINGA', 7649, 'N', 87000000, 87119999),
    (4119905, 'PR', 'PONTA GROSSA', 7717, 'N', 84000000, 84099999),
    (4104808, 'PR', 'CASCAVEL', 7503, 'N', 85800000, 85819999),
    (4125506, 'PR', 'SAO JOSE DOS PINHAIS', 7793, 'N', 83000000, 83099999),
    (4106902 + 1, 'PR', 'COLOMBO', 7529, 'N', 83400000, 83419999),
    (3550308, 'SP', 'SAO PAULO', 7107, 'S', 1000000, 5999999),
    (3509502, 'SP', 'CAMPINAS', 6291, 'N', 13000000, 13139999),
    (3548708, 'SP', 'SANTO ANDRE', 7075, 'N', 9000000, 9299999),
    (3547809, 'SP', 'SANTOS', 7063, 'N', 11000000, 11999999),
    (3543402, 'SP', 'RIBEIRAO PRETO', 6987, 'N', 14000000, 14119999),
    (3304557, 'RJ', 'RIO DE JANEIRO', 6001, 'S', 20000000, 23799999),
    (3301702, 'RJ', 'DUQUE DE CAXIAS', 5811, 'N', 25000000, 25999999),
    (3303302, 'RJ', 'NITEROI', 5865, 'N', 24000000, 24399999),
    (3106200, 'MG', 'BELO HORIZONTE', 4123, 'S', 30000000, 31999999),
    (3170206, 'MG', 'UBERLANDIA', 5403, 'N', 38400000, 38419999),
    (3118601, 'MG', 'CONTAGEM', 4359, 'N', 32000000, 32399999),
    (4314902, 'RS', 'PORTO ALEGRE', 8801, 'S', 90000000, 91999999),
    (4305108, 'RS', 'CAXIAS DO SUL', 8583, 'N', 95000000, 95129999),
    (4309209, 'RS', 'GRAVATAI', 8667, 'N', 94000000, 94199999),
    (4205407, 'SC', 'FLORIANOPOLIS', 8105, 'S', 88000000, 88099999),
    (4209102, 'SC', 'JOINVILLE', 8189, 'N', 89200000, 89239999),
    (4202404, 'SC', 'BLUMENAU', 8059, 'N', 89000000, 89079999),
    (2927408, 'BA', 'SALVADOR', 3849, 'S', 40000000, 42599999),
    (2304400, 'CE', 'FORTALEZA', 1389, 'S', 60000000, 61899999),
    (2611606, 'PE', 'RECIFE', 2531, 'S', 50000000, 54999999),
    (5300108, 'DF', 'BRASILIA', 9701, 'S', 70000000, 72799999),
    (5208707, 'GO', 'GOIANIA', 9373, 'S', 74000000, 74899999),
    (1501402, 'PA', 'BELEM', 401, 'S', 66000000, 66999999),
]


def grava_municipios():
    return [N(ibge, 7) + A(uf, 2) + A(nome, 40) + N(siafi, 4) +
            cap + N(ci, 8) + N(cf, 8) + 'A' + ' ' * 9
            for ibge, uf, nome, siafi, cap, ci, cf in MUNICIPIOS]


# -------------------------------------------------------- cargos
CARGOS = [
    (1010, 'AUXILIAR DE PRODUCAO', 784205, 'O', 1518.00, 2600.00, 220,
     'S', 20, 'N', 'N'),
    (1020, 'OPERADOR DE MAQUINAS', 821405, 'O', 2100.00, 3800.00, 220,
     'S', 20, 'N', 'N'),
    (1030, 'SOLDADOR', 724410, 'O', 2400.00, 4500.00, 220, 'S', 40, 'N', 'N'),
    (1040, 'ELETRICISTA DE MANUTENCAO', 951305, 'T', 2800.00, 5200.00, 220,
     'N', 0, 'S', 'N'),
    (1050, 'MECANICO DE MANUTENCAO', 914205, 'T', 2800.00, 5400.00, 220,
     'S', 20, 'N', 'N'),
    (1060, 'ALMOXARIFE', 414110, 'O', 1900.00, 3200.00, 220, 'N', 0,
     'N', 'N'),
    (2010, 'ASSISTENTE ADMINISTRATIVO', 411010, 'T', 2000.00, 3600.00, 220,
     'N', 0, 'N', 'N'),
    (2020, 'ANALISTA DE RH', 252405, 'T', 3500.00, 7200.00, 220, 'N', 0,
     'N', 'N'),
    (2030, 'ANALISTA CONTABIL', 252210, 'T', 3800.00, 7800.00, 220, 'N', 0,
     'N', 'N'),
    (2040, 'SUPERVISOR DE TURNO', 910105, 'G', 4800.00, 9500.00, 220,
     'N', 0, 'N', 'S'),
    (2050, 'COMPRADOR', 354405, 'T', 3200.00, 6500.00, 220, 'N', 0,
     'N', 'N'),
    (3010, 'ANALISTA DE SISTEMAS', 212405, 'E', 5000.00, 12000.00, 200,
     'N', 0, 'N', 'N'),
    (3020, 'ENGENHEIRO DE PRODUCAO', 214905, 'E', 7000.00, 16000.00, 220,
     'N', 0, 'N', 'N'),
    (4010, 'GERENTE INDUSTRIAL', 122105, 'G', 12000.00, 28000.00, 220,
     'N', 0, 'N', 'S'),
    (4020, 'DIRETOR DE OPERACOES', 121010, 'D', 20000.00, 60000.00, 220,
     'N', 0, 'N', 'S'),
]


def grava_cargos():
    saida = []
    for (cod, desc, cbo, niv, piso, teto, carga,
         iins, pins, iper, iconf) in CARGOS:
        saida.append(N(cod, 4) + A(desc, 35) + N(cbo, 6) + niv +
                     V(piso, 9) + V(teto, 9) + N(carga, 3) +
                     iins + N(pins, 2) + iper + iconf +
                     N(str(cbo)[:4], 4) + '20180101' + 'A' + ' ' * 31)
    return saida


# ------------------------------------------------- departamentos
DEPARTAMENTOS = [
    (1010, 'PRODUCAO - LINHA A', 101000, 1, 4010, 31110001),
    (1020, 'PRODUCAO - LINHA B', 102000, 1, 4010, 31110001),
    (1030, 'MANUTENCAO INDUSTRIAL', 103000, 1, 4010, 31110001),
    (2010, 'ADMINISTRACAO', 201000, 1, 4020, 31110001),
    (2020, 'RECURSOS HUMANOS', 202000, 1, 4020, 31110001),
    (2030, 'CONTROLADORIA', 203000, 1, 4020, 31110001),
    (3010, 'TECNOLOGIA DA INFORMACAO', 301000, 1, 4020, 31110001),
    (3020, 'ENGENHARIA', 302000, 1, 4010, 31110001),
    (3030, 'LOGISTICA E SUPRIMENTOS', 303000, 2, 4010, 31110001),
]


def grava_departamentos():
    return [N(cod, 4) + A(desc, 35) + N(cc, 6) + N(est, 4) +
            N(0, 8) + N(sup, 4) + N(conta, 8) + 'N' + '20180101' +
            'A' + ' ' * 41
            for cod, desc, cc, est, sup, conta in DEPARTAMENTOS]


# ----------------------------------------------- estabelecimentos
def grava_estabelecimentos():
    saida = []
    matriz = (
        1, 'M', 74829163000178,
        'INDUSTRIA MERIDIONAL DE COMPONENTES S/A',
        'MERIDIONAL COMPONENTES', '9012345678', '11223344',
        'AV', 'DAS INDUSTRIAS', '2450', 'GALPAO 1',
        'CIDADE INDUSTRIAL', 4106902, 'PR', 81170000,
        '4133215500', 'RH@MERIDIONAL.IND.BR',
        2910701, 507, 4163, 3.00, 1.0000, 5.80, 'N', 'N',
        11222333000144, 'SIND TRAB IND METALURGICAS CURITIBA', 11, 1.00,
        5, 20, 341, 1234, 567890123, '7', 'CONV0034521',
        20180101, 'A')
    filial = (
        2, 'F', 74829163000259,
        'INDUSTRIA MERIDIONAL DE COMPONENTES S/A - FILIAL SP',
        'MERIDIONAL SP', '110234567890', '55667788',
        'ROD', 'ANHANGUERA KM 32', 'S/N', 'MODULO B',
        'DISTRITO INDUSTRIAL', 3550308, 'SP', 5110000,
        '1145889900', 'RHSP@MERIDIONAL.IND.BR',
        2910701, 507, 4163, 2.00, 1.0000, 5.80, 'N', 'N',
        11222333000144, 'SIND TRAB IND METALURGICAS SAO PAULO', 9, 1.00,
        5, 20, 341, 1234, 567890123, '7', 'CONV0034521',
        20200601, 'A')

    for e in (matriz, filial):
        (cod, tipo, cnpj, razao, fant, ie, im,
         tlg, log, num, comp, bai, mun, uf, cep,
         tel, mail, cnae, fpas, terc, rat, fap, alter, simp, deso,
         cnpjs, nomes, mesdb, percs,
         diapg, diaad, banco, ag, cta, dig, conv,
         dtini, sit) = e
        saida.append(
            N(cod, 4) + tipo + N(cnpj, 14) + A(razao, 60) + A(fant, 40) +
            A(ie, 15) + A(im, 15) +
            A(tlg, 3) + A(log, 40) + A(num, 8) + A(comp, 15) +
            A(bai, 25) + N(mun, 7) + A(uf, 2) + N(cep, 8) +
            A(tel, 14) + A(mail, 40) +
            N(cnae, 7) + N(fpas, 3) + N(terc, 4) + V(rat, 2) +
            str(int(round(fap * 10000))).zfill(5) + V(alter, 2) +
            simp + deso +
            N(cnpjs, 14) + A(nomes, 40) + N(mesdb, 2) + V(percs, 3) +
            N(diapg, 2) + N(diaad, 2) + N(banco, 3) + N(ag, 5) +
            N(cta, 12) + dig + A(conv, 20) +
            N(dtini, 8) + sit + ' ' * 25)
    return saida


def escrever(nome, linhas, tam):
    caminho = os.path.join(DEST, nome)
    with open(caminho, 'w', encoding='ascii') as f:
        for l in linhas:
            if len(l) != tam:
                raise ValueError(f"{nome}: registro com {len(l)} bytes "
                                 f"(esperado {tam}) -> {l[:50]}")
            f.write(l + "\n")
    print(f"  {nome:<14} {len(linhas):>5} registros x {tam:>3} bytes")


if __name__ == '__main__':
    os.makedirs(DEST, exist_ok=True)
    print("Gerando tabelas de dominio e cadastros de apoio do SFP...")
    escrever('SFPDOM.DAT', grava_dominios(), 80)
    escrever('SFPUFE.DAT', grava_ufs(), 80)
    escrever('SFPMUN.DAT', grava_municipios(), 80)
    escrever('SFPCAR.DAT', grava_cargos(), 120)
    escrever('SFPDPT.DAT', grava_departamentos(), 120)
    escrever('SFPEST.DAT', grava_estabelecimentos(), 480)
    print("Concluido.")
