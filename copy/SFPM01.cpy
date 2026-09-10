      *================================================================*
      * COPYBOOK : SFPM01 - ESTRUTURA SIMBOLICA GERADA PELO BMS        *
      *            A PARTIR DO MAPSET SFPM01 / MAPA MAPEMP             *
      * NOTA     : NO MAINFRAME ESTE MEMBRO E PRODUZIDO PELO ASSEMBLY  *
      *            DO MAPSET COM TYPE=DSECT E COPIADO PARA A COPYLIB.  *
      *================================================================*
       01  MAPEMPI.
           02  FILLER              PIC X(012).
           02  DATAL               PIC S9(004) COMP.
           02  DATAF               PIC X.
           02  FILLER REDEFINES DATAF.
               03 DATAA            PIC X.
           02  DATAI               PIC X(010).
           02  MATRICL             PIC S9(004) COMP.
           02  MATRICF             PIC X.
           02  FILLER REDEFINES MATRICF.
               03 MATRICA          PIC X.
           02  MATRICI             PIC X(008).
           02  ACAOL               PIC S9(004) COMP.
           02  ACAOF               PIC X.
           02  FILLER REDEFINES ACAOF.
               03 ACAOA            PIC X.
           02  ACAOI               PIC X(001).
           02  NOMEL               PIC S9(004) COMP.
           02  NOMEF               PIC X.
           02  FILLER REDEFINES NOMEF.
               03 NOMEA            PIC X.
           02  NOMEI               PIC X(040).
           02  CPFL                PIC S9(004) COMP.
           02  CPFF                PIC X.
           02  FILLER REDEFINES CPFF.
               03 CPFA             PIC X.
           02  CPFI                PIC X(011).
           02  PISL                PIC S9(004) COMP.
           02  PISF                PIC X.
           02  FILLER REDEFINES PISF.
               03 PISA             PIC X.
           02  PISI                PIC X(011).
           02  DTNASCL             PIC S9(004) COMP.
           02  DTNASCF             PIC X.
           02  FILLER REDEFINES DTNASCF.
               03 DTNASCA          PIC X.
           02  DTNASCI             PIC X(008).
           02  DTADML              PIC S9(004) COMP.
           02  DTADMF              PIC X.
           02  FILLER REDEFINES DTADMF.
               03 DTADMA           PIC X.
           02  DTADMI              PIC X(008).
           02  DTDEML              PIC S9(004) COMP.
           02  DTDEMF              PIC X.
           02  FILLER REDEFINES DTDEMF.
               03 DTDEMA           PIC X.
           02  DTDEMI              PIC X(008).
           02  SITUACL             PIC S9(004) COMP.
           02  SITUACF             PIC X.
           02  FILLER REDEFINES SITUACF.
               03 SITUACA          PIC X.
           02  SITUACI             PIC X(001).
           02  CARGOL              PIC S9(004) COMP.
           02  CARGOF              PIC X.
           02  FILLER REDEFINES CARGOF.
               03 CARGOA           PIC X.
           02  CARGOI              PIC X(004).
           02  DEPTOL              PIC S9(004) COMP.
           02  DEPTOF              PIC X.
           02  FILLER REDEFINES DEPTOF.
               03 DEPTOA           PIC X.
           02  DEPTOI              PIC X(004).
           02  CCUSTOL             PIC S9(004) COMP.
           02  CCUSTOF             PIC X.
           02  FILLER REDEFINES CCUSTOF.
               03 CCUSTOA          PIC X.
           02  CCUSTOI             PIC X(006).
           02  SALARIOL            PIC S9(004) COMP.
           02  SALARIOF            PIC X.
           02  FILLER REDEFINES SALARIOF.
               03 SALARIOA         PIC X.
           02  SALARIOI            PIC 9(009)V99.
           02  TPSALL              PIC S9(004) COMP.
           02  TPSALF              PIC X.
           02  FILLER REDEFINES TPSALF.
               03 TPSALA           PIC X.
           02  TPSALI              PIC X(001).
           02  CARGAHL             PIC S9(004) COMP.
           02  CARGAHF             PIC X.
           02  FILLER REDEFINES CARGAHF.
               03 CARGAHA          PIC X.
           02  CARGAHI             PIC X(003).
           02  DEPIRFL             PIC S9(004) COMP.
           02  DEPIRFF             PIC X.
           02  FILLER REDEFINES DEPIRFF.
               03 DEPIRFA          PIC X.
           02  DEPIRFI             PIC X(002).
           02  DEPSFAL             PIC S9(004) COMP.
           02  DEPSFAF             PIC X.
           02  FILLER REDEFINES DEPSFAF.
               03 DEPSFAA          PIC X.
           02  DEPSFAI             PIC X(002).
           02  INSALUL             PIC S9(004) COMP.
           02  INSALUF             PIC X.
           02  FILLER REDEFINES INSALUF.
               03 INSALUA          PIC X.
           02  INSALUI             PIC X(002).
           02  PERICUL             PIC S9(004) COMP.
           02  PERICUF             PIC X.
           02  FILLER REDEFINES PERICUF.
               03 PERICUA          PIC X.
           02  PERICUI             PIC X(001).
           02  INDVTL              PIC S9(004) COMP.
           02  INDVTF              PIC X.
           02  FILLER REDEFINES INDVTF.
               03 INDVTA           PIC X.
           02  INDVTI              PIC X(001).
           02  VLRVTL              PIC S9(004) COMP.
           02  VLRVTF              PIC X.
           02  FILLER REDEFINES VLRVTF.
               03 VLRVTA           PIC X.
           02  VLRVTI              PIC 9(007)V99.
           02  INDVRL              PIC S9(004) COMP.
           02  INDVRF              PIC X.
           02  FILLER REDEFINES INDVRF.
               03 INDVRA           PIC X.
           02  INDVRI              PIC X(001).
           02  VLRVRL              PIC S9(004) COMP.
           02  VLRVRF              PIC X.
           02  FILLER REDEFINES VLRVRF.
               03 VLRVRA           PIC X.
           02  VLRVRI              PIC 9(007)V99.
           02  INDPSL              PIC S9(004) COMP.
           02  INDPSF              PIC X.
           02  FILLER REDEFINES INDPSF.
               03 INDPSA           PIC X.
           02  INDPSI              PIC X(001).
           02  VLRPSL              PIC S9(004) COMP.
           02  VLRPSF              PIC X.
           02  FILLER REDEFINES VLRPSF.
               03 VLRPSA           PIC X.
           02  VLRPSI              PIC 9(007)V99.
           02  PERPENL             PIC S9(004) COMP.
           02  PERPENF             PIC X.
           02  FILLER REDEFINES PERPENF.
               03 PERPENA          PIC X.
           02  PERPENI             PIC 9(003)V99.
           02  VLRPENL             PIC S9(004) COMP.
           02  VLRPENF             PIC X.
           02  FILLER REDEFINES VLRPENF.
               03 VLRPENA          PIC X.
           02  VLRPENI             PIC 9(007)V99.
           02  VLRCONL             PIC S9(004) COMP.
           02  VLRCONF             PIC X.
           02  FILLER REDEFINES VLRCONF.
               03 VLRCONA          PIC X.
           02  VLRCONI             PIC 9(007)V99.
           02  BANCOL              PIC S9(004) COMP.
           02  BANCOF              PIC X.
           02  FILLER REDEFINES BANCOF.
               03 BANCOA           PIC X.
           02  BANCOI              PIC X(003).
           02  AGENCIAL            PIC S9(004) COMP.
           02  AGENCIAF            PIC X.
           02  FILLER REDEFINES AGENCIAF.
               03 AGENCIAA         PIC X.
           02  AGENCIAI            PIC X(005).
           02  CONTAL              PIC S9(004) COMP.
           02  CONTAF              PIC X.
           02  FILLER REDEFINES CONTAF.
               03 CONTAA           PIC X.
           02  CONTAI              PIC X(012).
           02  DIGCTAL             PIC S9(004) COMP.
           02  DIGCTAF             PIC X.
           02  FILLER REDEFINES DIGCTAF.
               03 DIGCTAA          PIC X.
           02  DIGCTAI             PIC X(001).
           02  MENSAGL             PIC S9(004) COMP.
           02  MENSAGF             PIC X.
           02  FILLER REDEFINES MENSAGF.
               03 MENSAGA          PIC X.
           02  MENSAGI             PIC X(079).
      *
       01  MAPEMPO REDEFINES MAPEMPI.
           02  FILLER              PIC X(012).
           02  FILLER              PIC X(003).
           02  DATAO               PIC X(010).
           02  FILLER              PIC X(003).
           02  MATRICO             PIC X(008).
           02  FILLER              PIC X(003).
           02  ACAOO               PIC X(001).
           02  FILLER              PIC X(003).
           02  NOMEO               PIC X(040).
           02  FILLER              PIC X(003).
           02  CPFO                PIC X(011).
           02  FILLER              PIC X(003).
           02  PISO                PIC X(011).
           02  FILLER              PIC X(003).
           02  DTNASCO             PIC X(008).
           02  FILLER              PIC X(003).
           02  DTADMO              PIC X(008).
           02  FILLER              PIC X(003).
           02  DTDEMO              PIC X(008).
           02  FILLER              PIC X(003).
           02  SITUACO             PIC X(001).
           02  FILLER              PIC X(003).
           02  CARGOO              PIC X(004).
           02  FILLER              PIC X(003).
           02  DEPTOO              PIC X(004).
           02  FILLER              PIC X(003).
           02  CCUSTOO             PIC X(006).
           02  FILLER              PIC X(003).
           02  SALARIOO            PIC ZZZ.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  TPSALO              PIC X(001).
           02  FILLER              PIC X(003).
           02  CARGAHO             PIC X(003).
           02  FILLER              PIC X(003).
           02  DEPIRFO             PIC X(002).
           02  FILLER              PIC X(003).
           02  DEPSFAO             PIC X(002).
           02  FILLER              PIC X(003).
           02  INSALUO             PIC X(002).
           02  FILLER              PIC X(003).
           02  PERICUO             PIC X(001).
           02  FILLER              PIC X(003).
           02  INDVTO              PIC X(001).
           02  FILLER              PIC X(003).
           02  VLRVTO              PIC Z.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  INDVRO              PIC X(001).
           02  FILLER              PIC X(003).
           02  VLRVRO              PIC Z.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  INDPSO              PIC X(001).
           02  FILLER              PIC X(003).
           02  VLRPSO              PIC Z.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  PERPENO             PIC ZZ9,99.
           02  FILLER              PIC X(003).
           02  VLRPENO             PIC Z.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  VLRCONO             PIC Z.ZZZ.ZZ9,99.
           02  FILLER              PIC X(003).
           02  BANCOO              PIC X(003).
           02  FILLER              PIC X(003).
           02  AGENCIAO            PIC X(005).
           02  FILLER              PIC X(003).
           02  CONTAO              PIC X(012).
           02  FILLER              PIC X(003).
           02  DIGCTAO             PIC X(001).
           02  FILLER              PIC X(003).
           02  MENSAGO             PIC X(079).
      *================================================================*
      * MAPA MAPEMP2 - SEGUNDA TELA DO SFP0100                         *
      *================================================================*
       01  MAPEMP2I.
           02  FILLER              PIC X(012).
           02  DATA2L              PIC S9(004) COMP.
           02  DATA2F              PIC X.
           02  FILLER REDEFINES DATA2F.
               03 DATA2A            PIC X.
           02  DATA2I              PIC X(010).
           02  MATRI2L             PIC S9(004) COMP.
           02  MATRI2F             PIC X.
           02  FILLER REDEFINES MATRI2F.
               03 MATRI2A           PIC X.
           02  MATRI2I             PIC X(008).
           02  NOME2L              PIC S9(004) COMP.
           02  NOME2F              PIC X.
           02  FILLER REDEFINES NOME2F.
               03 NOME2A            PIC X.
           02  NOME2I              PIC X(040).
           02  SEXOL               PIC S9(004) COMP.
           02  SEXOF               PIC X.
           02  FILLER REDEFINES SEXOF.
               03 SEXOA             PIC X.
           02  SEXOI               PIC X(001).
           02  DSEXOL              PIC S9(004) COMP.
           02  DSEXOF              PIC X.
           02  FILLER REDEFINES DSEXOF.
               03 DSEXOA            PIC X.
           02  DSEXOI              PIC X(009).
           02  ECIVL               PIC S9(004) COMP.
           02  ECIVF               PIC X.
           02  FILLER REDEFINES ECIVF.
               03 ECIVA             PIC X.
           02  ECIVI               PIC X(001).
           02  DECIVL              PIC S9(004) COMP.
           02  DECIVF              PIC X.
           02  FILLER REDEFINES DECIVF.
               03 DECIVA            PIC X.
           02  DECIVI              PIC X(011).
           02  RACAL               PIC S9(004) COMP.
           02  RACAF               PIC X.
           02  FILLER REDEFINES RACAF.
               03 RACAA             PIC X.
           02  RACAI               PIC X(002).
           02  DRACAL              PIC S9(004) COMP.
           02  DRACAF              PIC X.
           02  FILLER REDEFINES DRACAF.
               03 DRACAA            PIC X.
           02  DRACAI              PIC X(011).
           02  NACIONL             PIC S9(004) COMP.
           02  NACIONF             PIC X.
           02  FILLER REDEFINES NACIONF.
               03 NACIONA           PIC X.
           02  NACIONI             PIC X(003).
           02  DNACIOL             PIC S9(004) COMP.
           02  DNACIOF             PIC X.
           02  FILLER REDEFINES DNACIOF.
               03 DNACIOA           PIC X.
           02  DNACIOI             PIC X(018).
           02  INSTRUL             PIC S9(004) COMP.
           02  INSTRUF             PIC X.
           02  FILLER REDEFINES INSTRUF.
               03 INSTRUA           PIC X.
           02  INSTRUI             PIC X(002).
           02  DINSTRL             PIC S9(004) COMP.
           02  DINSTRF             PIC X.
           02  FILLER REDEFINES DINSTRF.
               03 DINSTRA           PIC X.
           02  DINSTRI             PIC X(018).
           02  UFNASCL             PIC S9(004) COMP.
           02  UFNASCF             PIC X.
           02  FILLER REDEFINES UFNASCF.
               03 UFNASCA           PIC X.
           02  UFNASCI             PIC X(002).
           02  DUFNASL             PIC S9(004) COMP.
           02  DUFNASF             PIC X.
           02  FILLER REDEFINES DUFNASF.
               03 DUFNASA           PIC X.
           02  DUFNASI             PIC X(015).
           02  MUNNASL             PIC S9(004) COMP.
           02  MUNNASF             PIC X.
           02  FILLER REDEFINES MUNNASF.
               03 MUNNASA           PIC X.
           02  MUNNASI             PIC X(007).
           02  DMUNNAL             PIC S9(004) COMP.
           02  DMUNNAF             PIC X.
           02  FILLER REDEFINES DMUNNAF.
               03 DMUNNAA           PIC X.
           02  DMUNNAI             PIC X(020).
           02  NOMEMAL             PIC S9(004) COMP.
           02  NOMEMAF             PIC X.
           02  FILLER REDEFINES NOMEMAF.
               03 NOMEMAA           PIC X.
           02  NOMEMAI             PIC X(040).
           02  DEFICL              PIC S9(004) COMP.
           02  DEFICF              PIC X.
           02  FILLER REDEFINES DEFICF.
               03 DEFICA            PIC X.
           02  DEFICI              PIC X(001).
           02  TPDEFL              PIC S9(004) COMP.
           02  TPDEFF              PIC X.
           02  FILLER REDEFINES TPDEFF.
               03 TPDEFA            PIC X.
           02  TPDEFI              PIC X(002).
           02  DTPDEFL             PIC S9(004) COMP.
           02  DTPDEFF             PIC X.
           02  FILLER REDEFINES DTPDEFF.
               03 DTPDEFA           PIC X.
           02  DTPDEFI             PIC X(020).
           02  CTPSNRL             PIC S9(004) COMP.
           02  CTPSNRF             PIC X.
           02  FILLER REDEFINES CTPSNRF.
               03 CTPSNRA           PIC X.
           02  CTPSNRI             PIC X(008).
           02  CTPSSEL             PIC S9(004) COMP.
           02  CTPSSEF             PIC X.
           02  FILLER REDEFINES CTPSSEF.
               03 CTPSSEA           PIC X.
           02  CTPSSEI             PIC X(005).
           02  CTPSUFL             PIC S9(004) COMP.
           02  CTPSUFF             PIC X.
           02  FILLER REDEFINES CTPSUFF.
               03 CTPSUFA           PIC X.
           02  CTPSUFI             PIC X(002).
           02  RGNUML              PIC S9(004) COMP.
           02  RGNUMF              PIC X.
           02  FILLER REDEFINES RGNUMF.
               03 RGNUMA            PIC X.
           02  RGNUMI              PIC X(015).
           02  RGORGL              PIC S9(004) COMP.
           02  RGORGF              PIC X.
           02  FILLER REDEFINES RGORGF.
               03 RGORGA            PIC X.
           02  RGORGI              PIC X(008).
           02  TITELEL             PIC S9(004) COMP.
           02  TITELEF             PIC X.
           02  FILLER REDEFINES TITELEF.
               03 TITELEA           PIC X.
           02  TITELEI             PIC X(012).
           02  TPLOGRL             PIC S9(004) COMP.
           02  TPLOGRF             PIC X.
           02  FILLER REDEFINES TPLOGRF.
               03 TPLOGRA           PIC X.
           02  TPLOGRI             PIC X(003).
           02  DTPLOGL             PIC S9(004) COMP.
           02  DTPLOGF             PIC X.
           02  FILLER REDEFINES DTPLOGF.
               03 DTPLOGA           PIC X.
           02  DTPLOGI             PIC X(010).
           02  LOGRADL             PIC S9(004) COMP.
           02  LOGRADF             PIC X.
           02  FILLER REDEFINES LOGRADF.
               03 LOGRADA           PIC X.
           02  LOGRADI             PIC X(040).
           02  NUMEROL             PIC S9(004) COMP.
           02  NUMEROF             PIC X.
           02  FILLER REDEFINES NUMEROF.
               03 NUMEROA           PIC X.
           02  NUMEROI             PIC X(008).
           02  COMPLEL             PIC S9(004) COMP.
           02  COMPLEF             PIC X.
           02  FILLER REDEFINES COMPLEF.
               03 COMPLEA           PIC X.
           02  COMPLEI             PIC X(015).
           02  BAIRROL             PIC S9(004) COMP.
           02  BAIRROF             PIC X.
           02  FILLER REDEFINES BAIRROF.
               03 BAIRROA           PIC X.
           02  BAIRROI             PIC X(025).
           02  CEPL                PIC S9(004) COMP.
           02  CEPF                PIC X.
           02  FILLER REDEFINES CEPF.
               03 CEPA              PIC X.
           02  CEPI                PIC X(008).
           02  MUNICL              PIC S9(004) COMP.
           02  MUNICF              PIC X.
           02  FILLER REDEFINES MUNICF.
               03 MUNICA            PIC X.
           02  MUNICI              PIC X(007).
           02  DMUNICL             PIC S9(004) COMP.
           02  DMUNICF             PIC X.
           02  FILLER REDEFINES DMUNICF.
               03 DMUNICA           PIC X.
           02  DMUNICI             PIC X(020).
           02  UFL                 PIC S9(004) COMP.
           02  UFF                 PIC X.
           02  FILLER REDEFINES UFF.
               03 UFA               PIC X.
           02  UFI                 PIC X(002).
           02  DUFL                PIC S9(004) COMP.
           02  DUFF                PIC X.
           02  FILLER REDEFINES DUFF.
               03 DUFA              PIC X.
           02  DUFI                PIC X(012).
           02  TELEFL              PIC S9(004) COMP.
           02  TELEFF              PIC X.
           02  FILLER REDEFINES TELEFF.
               03 TELEFA            PIC X.
           02  TELEFI              PIC X(014).
           02  ESTABL              PIC S9(004) COMP.
           02  ESTABF              PIC X.
           02  FILLER REDEFINES ESTABF.
               03 ESTABA            PIC X.
           02  ESTABI              PIC X(004).
           02  DESTABL             PIC S9(004) COMP.
           02  DESTABF             PIC X.
           02  FILLER REDEFINES DESTABF.
               03 DESTABA           PIC X.
           02  DESTABI             PIC X(020).
           02  VINCULL             PIC S9(004) COMP.
           02  VINCULF             PIC X.
           02  FILLER REDEFINES VINCULF.
               03 VINCULA           PIC X.
           02  VINCULI             PIC X(002).
           02  DVINCL              PIC S9(004) COMP.
           02  DVINCF              PIC X.
           02  FILLER REDEFINES DVINCF.
               03 DVINCA            PIC X.
           02  DVINCI              PIC X(012).
           02  JORNADL             PIC S9(004) COMP.
           02  JORNADF             PIC X.
           02  FILLER REDEFINES JORNADF.
               03 JORNADA           PIC X.
           02  JORNADI             PIC X(002).
           02  DJORNL              PIC S9(004) COMP.
           02  DJORNF              PIC X.
           02  FILLER REDEFINES DJORNF.
               03 DJORNA            PIC X.
           02  DJORNI              PIC X(012).
           02  HORARIL             PIC S9(004) COMP.
           02  HORARIF             PIC X.
           02  FILLER REDEFINES HORARIF.
               03 HORARIA           PIC X.
           02  HORARII             PIC X(003).
           02  DHORARL             PIC S9(004) COMP.
           02  DHORARF             PIC X.
           02  FILLER REDEFINES DHORARF.
               03 DHORARA           PIC X.
           02  DHORARI             PIC X(010).
           02  MENSA2L             PIC S9(004) COMP.
           02  MENSA2F             PIC X.
           02  FILLER REDEFINES MENSA2F.
               03 MENSA2A           PIC X.
           02  MENSA2I             PIC X(079).
       01  MAPEMP2O REDEFINES MAPEMP2I.
           02  FILLER              PIC X(012).
           02  FILLER              PIC X(003).
           02  DATA2O              PIC X(010).
           02  FILLER              PIC X(003).
           02  MATRI2O             PIC X(008).
           02  FILLER              PIC X(003).
           02  NOME2O              PIC X(040).
           02  FILLER              PIC X(003).
           02  SEXOO               PIC X(001).
           02  FILLER              PIC X(003).
           02  DSEXOO              PIC X(009).
           02  FILLER              PIC X(003).
           02  ECIVO               PIC X(001).
           02  FILLER              PIC X(003).
           02  DECIVO              PIC X(011).
           02  FILLER              PIC X(003).
           02  RACAO               PIC X(002).
           02  FILLER              PIC X(003).
           02  DRACAO              PIC X(011).
           02  FILLER              PIC X(003).
           02  NACIONO             PIC X(003).
           02  FILLER              PIC X(003).
           02  DNACIOO             PIC X(018).
           02  FILLER              PIC X(003).
           02  INSTRUO             PIC X(002).
           02  FILLER              PIC X(003).
           02  DINSTRO             PIC X(018).
           02  FILLER              PIC X(003).
           02  UFNASCO             PIC X(002).
           02  FILLER              PIC X(003).
           02  DUFNASO             PIC X(015).
           02  FILLER              PIC X(003).
           02  MUNNASO             PIC X(007).
           02  FILLER              PIC X(003).
           02  DMUNNAO             PIC X(020).
           02  FILLER              PIC X(003).
           02  NOMEMAO             PIC X(040).
           02  FILLER              PIC X(003).
           02  DEFICO              PIC X(001).
           02  FILLER              PIC X(003).
           02  TPDEFO              PIC X(002).
           02  FILLER              PIC X(003).
           02  DTPDEFO             PIC X(020).
           02  FILLER              PIC X(003).
           02  CTPSNRO             PIC X(008).
           02  FILLER              PIC X(003).
           02  CTPSSEO             PIC X(005).
           02  FILLER              PIC X(003).
           02  CTPSUFO             PIC X(002).
           02  FILLER              PIC X(003).
           02  RGNUMO              PIC X(015).
           02  FILLER              PIC X(003).
           02  RGORGO              PIC X(008).
           02  FILLER              PIC X(003).
           02  TITELEO             PIC X(012).
           02  FILLER              PIC X(003).
           02  TPLOGRO             PIC X(003).
           02  FILLER              PIC X(003).
           02  DTPLOGO             PIC X(010).
           02  FILLER              PIC X(003).
           02  LOGRADO             PIC X(040).
           02  FILLER              PIC X(003).
           02  NUMEROO             PIC X(008).
           02  FILLER              PIC X(003).
           02  COMPLEO             PIC X(015).
           02  FILLER              PIC X(003).
           02  BAIRROO             PIC X(025).
           02  FILLER              PIC X(003).
           02  CEPO                PIC X(008).
           02  FILLER              PIC X(003).
           02  MUNICO              PIC X(007).
           02  FILLER              PIC X(003).
           02  DMUNICO             PIC X(020).
           02  FILLER              PIC X(003).
           02  UFO                 PIC X(002).
           02  FILLER              PIC X(003).
           02  DUFO                PIC X(012).
           02  FILLER              PIC X(003).
           02  TELEFO              PIC X(014).
           02  FILLER              PIC X(003).
           02  ESTABO              PIC X(004).
           02  FILLER              PIC X(003).
           02  DESTABO             PIC X(020).
           02  FILLER              PIC X(003).
           02  VINCULO             PIC X(002).
           02  FILLER              PIC X(003).
           02  DVINCO              PIC X(012).
           02  FILLER              PIC X(003).
           02  JORNADO             PIC X(002).
           02  FILLER              PIC X(003).
           02  DJORNO              PIC X(012).
           02  FILLER              PIC X(003).
           02  HORARIO             PIC X(003).
           02  FILLER              PIC X(003).
           02  DHORARO             PIC X(010).
           02  FILLER              PIC X(003).
           02  MENSA2O             PIC X(079).
