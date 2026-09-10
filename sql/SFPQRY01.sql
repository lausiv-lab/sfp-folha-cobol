--*****************************************************************
--* MEMBRO : SFPQRY01 - CONSULTAS ANALITICAS DA FOLHA             *
--* USO    : SPUFI / DSNTEP2 / QMF                                *
--*****************************************************************

--=================================================================
-- Q01 - CUSTO TOTAL DA FOLHA POR CENTRO DE CUSTO E COMPETENCIA
--       INCLUI O ENCARGO PATRONAL ESTIMADO (INSS 20% + FGTS 8%)
--=================================================================
SELECT R.CENTRO_CUSTO
     , COUNT(*)                                  AS QTD_EMPREG
     , DEC(SUM(R.TOT_PROVENTOS),13,2)            AS PROVENTOS
     , DEC(SUM(R.TOT_DESCONTOS),13,2)            AS DESCONTOS
     , DEC(SUM(R.LIQUIDO),13,2)                  AS LIQUIDO
     , DEC(SUM(R.VLR_FGTS),13,2)                 AS FGTS
     , DEC(SUM(R.BASE_INSS) * 0.20,13,2)         AS INSS_PATRONAL
     , DEC(SUM(R.TOT_PROVENTOS)
         + SUM(R.VLR_FGTS)
         + SUM(R.BASE_INSS) * 0.20 ,13,2)        AS CUSTO_TOTAL
  FROM SFPADM.TB_FOLHA_RESUMO R
 WHERE R.COMPETENCIA = 202608
   AND R.TIPO_FOLHA  = '1'
 GROUP BY R.CENTRO_CUSTO
 ORDER BY CUSTO_TOTAL DESC
 WITH UR;

--=================================================================
-- Q02 - TOP 20 MAIORES LIQUIDOS DA COMPETENCIA
--=================================================================
SELECT R.MATRICULA
     , R.NOME
     , R.CENTRO_CUSTO
     , R.TOT_PROVENTOS
     , R.TOT_DESCONTOS
     , R.LIQUIDO
     , R.ALIQ_IRRF
  FROM SFPADM.TB_FOLHA_RESUMO R
 WHERE R.COMPETENCIA = 202608
   AND R.TIPO_FOLHA  = '1'
 ORDER BY R.LIQUIDO DESC
 FETCH FIRST 20 ROWS ONLY
 WITH UR;

--=================================================================
-- Q03 - COMPOSICAO DA FOLHA POR EVENTO (RANKING DE RUBRICAS)
--=================================================================
SELECT F.COD_EVENTO
     , MAX(F.DESCRICAO)                          AS DESCRICAO
     , MAX(F.NATUREZA)                           AS NATUREZA
     , COUNT(*)                                  AS QTD_LANC
     , DEC(SUM(F.VALOR),13,2)                    AS VALOR_TOTAL
     , DEC(AVG(F.VALOR),11,2)                    AS VALOR_MEDIO
     , DEC(SUM(F.VALOR) * 100
         / (SELECT SUM(X.VALOR)
              FROM SFPADM.TB_FOLHA_CALC X
             WHERE X.COMPETENCIA = F.COMPETENCIA
               AND X.NATUREZA    = F.NATUREZA),7,2) AS PERC_NATUR
  FROM SFPADM.TB_FOLHA_CALC F
 WHERE F.COMPETENCIA = 202608
   AND F.NATUREZA IN ('P','D')
 GROUP BY F.COD_EVENTO, F.COMPETENCIA, F.NATUREZA
 ORDER BY F.NATUREZA, VALOR_TOTAL DESC
 WITH UR;

--=================================================================
-- Q04 - EVOLUCAO MENSAL DO CUSTO DE FOLHA (12 COMPETENCIAS)
--       COM VARIACAO PERCENTUAL SOBRE O MES ANTERIOR
--=================================================================
WITH MENSAL AS (
    SELECT R.COMPETENCIA
         , SUM(R.TOT_PROVENTOS) AS PROVENTOS
         , SUM(R.LIQUIDO)       AS LIQUIDO
         , COUNT(*)             AS QTD
      FROM SFPADM.TB_FOLHA_RESUMO R
     WHERE R.TIPO_FOLHA = '1'
     GROUP BY R.COMPETENCIA
)
SELECT M.COMPETENCIA
     , M.QTD
     , DEC(M.PROVENTOS,13,2)                     AS PROVENTOS
     , DEC(M.LIQUIDO,13,2)                       AS LIQUIDO
     , DEC(M.PROVENTOS / M.QTD,11,2)             AS MEDIA_EMPREG
     , DEC(COALESCE(
         (M.PROVENTOS - LAG(M.PROVENTOS)
              OVER (ORDER BY M.COMPETENCIA)) * 100
        / NULLIF(LAG(M.PROVENTOS)
              OVER (ORDER BY M.COMPETENCIA),0), 0),7,2) AS VAR_PERC
  FROM MENSAL M
 ORDER BY M.COMPETENCIA DESC
 FETCH FIRST 12 ROWS ONLY
 WITH UR;

--=================================================================
-- Q05 - EMPREGADOS COM LIQUIDO NEGATIVO OU ABAIXO DE 30% DO BRUTO
--       INDICADOR DE ENDIVIDAMENTO EXCESSIVO
--=================================================================
SELECT R.MATRICULA
     , R.NOME
     , R.TOT_PROVENTOS
     , R.TOT_DESCONTOS
     , R.LIQUIDO
     , DEC(R.TOT_DESCONTOS * 100
         / NULLIF(R.TOT_PROVENTOS,0),7,2)        AS PERC_COMPROM
  FROM SFPADM.TB_FOLHA_RESUMO R
 WHERE R.COMPETENCIA = 202608
   AND (R.LIQUIDO <= 0
    OR  R.TOT_DESCONTOS > R.TOT_PROVENTOS * 0.70)
 ORDER BY PERC_COMPROM DESC
 WITH UR;

--=================================================================
-- Q06 - CONFERENCIA: SOMA DOS EVENTOS X TOTAIS DO RESUMO
--       DEVE RETORNAR ZERO LINHAS EM UMA FOLHA INTEGRA
--=================================================================
SELECT R.MATRICULA
     , R.TOT_PROVENTOS                           AS RESUMO_PROV
     , COALESCE(D.SOMA_PROV,0)                   AS DETALHE_PROV
     , R.TOT_DESCONTOS                           AS RESUMO_DESC
     , COALESCE(D.SOMA_DESC,0)                   AS DETALHE_DESC
  FROM SFPADM.TB_FOLHA_RESUMO R
  LEFT JOIN (
       SELECT F.MATRICULA
            , SUM(CASE WHEN F.NATUREZA='P' THEN F.VALOR ELSE 0 END)
                AS SOMA_PROV
            , SUM(CASE WHEN F.NATUREZA='D' THEN F.VALOR ELSE 0 END)
                AS SOMA_DESC
         FROM SFPADM.TB_FOLHA_CALC F
        WHERE F.COMPETENCIA = 202608
          AND F.TIPO_FOLHA  = '1'
        GROUP BY F.MATRICULA
       ) D
    ON D.MATRICULA = R.MATRICULA
 WHERE R.COMPETENCIA = 202608
   AND R.TIPO_FOLHA  = '1'
   AND (R.TOT_PROVENTOS <> COALESCE(D.SOMA_PROV,0)
    OR  R.TOT_DESCONTOS <> COALESCE(D.SOMA_DESC,0))
 WITH UR;

--=================================================================
-- Q07 - HEADCOUNT E MASSA SALARIAL POR FAIXA DE REMUNERACAO
--=================================================================
SELECT CASE
         WHEN E.SALARIO_BASE <  2000 THEN '1 - ATE 2.000'
         WHEN E.SALARIO_BASE <  5000 THEN '2 - 2.001 A 5.000'
         WHEN E.SALARIO_BASE < 10000 THEN '3 - 5.001 A 10.000'
         WHEN E.SALARIO_BASE < 20000 THEN '4 - 10.001 A 20.000'
         ELSE                             '5 - ACIMA DE 20.000'
       END                                       AS FAIXA
     , COUNT(*)                                  AS QTD
     , DEC(SUM(E.SALARIO_BASE),13,2)             AS MASSA
     , DEC(AVG(E.SALARIO_BASE),11,2)             AS MEDIA
  FROM SFPADM.TB_EMPREGADO E
 WHERE E.SITUACAO IN ('A','F','L')
 GROUP BY CASE
         WHEN E.SALARIO_BASE <  2000 THEN '1 - ATE 2.000'
         WHEN E.SALARIO_BASE <  5000 THEN '2 - 2.001 A 5.000'
         WHEN E.SALARIO_BASE < 10000 THEN '3 - 5.001 A 10.000'
         WHEN E.SALARIO_BASE < 20000 THEN '4 - 10.001 A 20.000'
         ELSE                             '5 - ACIMA DE 20.000'
       END
 ORDER BY FAIXA
 WITH UR;

--=================================================================
-- Q08 - MOVIMENTOS REJEITADOS PELA CRITICA NA COMPETENCIA
--=================================================================
SELECT M.MATRICULA
     , E.NOME
     , M.COD_EVENTO
     , V.DESCRICAO
     , M.REFERENCIA
     , M.VALOR
     , M.ORIGEM
     , M.USUARIO
  FROM SFPADM.TB_MOVIMENTO M
  LEFT JOIN SFPADM.TB_EMPREGADO E ON E.MATRICULA  = M.MATRICULA
  LEFT JOIN SFPADM.TB_EVENTO    V ON V.COD_EVENTO = M.COD_EVENTO
 WHERE M.COMPETENCIA = 202608
   AND M.SIT_CRITICA = 'R'
 ORDER BY M.MATRICULA, M.COD_EVENTO
 WITH UR;
