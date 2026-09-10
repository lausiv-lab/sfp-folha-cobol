--*****************************************************************
--* SISTEMA  : SFP - SISTEMA DE FOLHA DE PAGAMENTO                 *
--* MEMBRO   : SFPDDL01                                           *
--* FUNCAO   : CRIACAO DO BANCO, STORAGE GROUP E TABLESPACES       *
--* SGBD     : IBM DB2 FOR Z/OS V13                               *
--*****************************************************************

--=================================================================
-- STORAGE GROUP
--=================================================================
CREATE STOGROUP SGSFP01
    VOLUMES (SFP001, SFP002, SFP003)
    VCAT     DB2PROD;

--=================================================================
-- DATABASE
--=================================================================
CREATE DATABASE DBSFP001
    STOGROUP SGSFP01
    BUFFERPOOL BP2
    INDEXBP    BP3
    CCSID      EBCDIC;

--=================================================================
-- TABLESPACE DO CADASTRO (SEGMENTADO - BAIXO VOLUME)
--=================================================================
CREATE TABLESPACE TSSFPCAD
    IN DBSFP001
    USING STOGROUP SGSFP01
        PRIQTY 7200
        SECQTY 3600
        ERASE   NO
    SEGSIZE     32
    LOCKSIZE    ROW
    LOCKMAX     SYSTEM
    BUFFERPOOL  BP2
    CLOSE       NO
    COMPRESS    YES
    CCSID       EBCDIC;

--=================================================================
-- TABLESPACE DO MOVIMENTO (PARTICIONADO POR COMPETENCIA)
--=================================================================
CREATE TABLESPACE TSSFPMOV
    IN DBSFP001
    USING STOGROUP SGSFP01
        PRIQTY 144000
        SECQTY  72000
    NUMPARTS    12
    LOCKSIZE    PAGE
    BUFFERPOOL  BP2
    CLOSE       NO
    COMPRESS    YES
    CCSID       EBCDIC;

--=================================================================
-- TABLESPACE DA FOLHA CALCULADA (ALTO VOLUME)
--=================================================================
CREATE TABLESPACE TSSFPFOL
    IN DBSFP001
    USING STOGROUP SGSFP01
        PRIQTY 720000
        SECQTY 360000
    NUMPARTS    24
    LOCKSIZE    PAGE
    MAXROWS     255
    BUFFERPOOL  BP2
    CLOSE       NO
    COMPRESS    YES
    CCSID       EBCDIC;

--=================================================================
-- TABLESPACE DAS TABELAS LEGAIS E PARAMETROS
--=================================================================
CREATE TABLESPACE TSSFPTAB
    IN DBSFP001
    USING STOGROUP SGSFP01
        PRIQTY  720
        SECQTY  360
    SEGSIZE     4
    LOCKSIZE    ROW
    BUFFERPOOL  BP2
    CLOSE       NO
    CCSID       EBCDIC;
