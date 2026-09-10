      *================================================================*
      * COPYBOOK : SFPM00 - ESTRUTURA SIMBOLICA GERADA PELO BMS       *
      *            A PARTIR DO MAPSET SFPM00 / MAPA MAPMENU      *
      *================================================================*
       01  MAPMENUI.
           02  FILLER              PIC X(012).
           02  MDATAL              PIC S9(004) COMP.
           02  MDATAF              PIC X.
           02  FILLER REDEFINES MDATAF.
               03 MDATAA           PIC X.
           02  MDATAI              PIC X(010).
           02  MHORAL              PIC S9(004) COMP.
           02  MHORAF              PIC X.
           02  FILLER REDEFINES MHORAF.
               03 MHORAA           PIC X.
           02  MHORAI              PIC X(008).
           02  MUSERL              PIC S9(004) COMP.
           02  MUSERF              PIC X.
           02  FILLER REDEFINES MUSERF.
               03 MUSERA           PIC X.
           02  MUSERI              PIC X(008).
           02  MOPCAOL             PIC S9(004) COMP.
           02  MOPCAOF             PIC X.
           02  FILLER REDEFINES MOPCAOF.
               03 MOPCAOA          PIC X.
           02  MOPCAOI             PIC X(002).
           02  MTRANSL             PIC S9(004) COMP.
           02  MTRANSF             PIC X.
           02  FILLER REDEFINES MTRANSF.
               03 MTRANSA          PIC X.
           02  MTRANSI             PIC X(004).
           02  MMENSAGL            PIC S9(004) COMP.
           02  MMENSAGF            PIC X.
           02  FILLER REDEFINES MMENSAGF.
               03 MMENSAGA         PIC X.
           02  MMENSAGI            PIC X(079).
      *
       01  MAPMENUO REDEFINES MAPMENUI.
           02  FILLER              PIC X(012).
           02  FILLER              PIC X(003).
           02  MDATAO              PIC X(010).
           02  FILLER              PIC X(003).
           02  MHORAO              PIC X(008).
           02  FILLER              PIC X(003).
           02  MUSERO              PIC X(008).
           02  FILLER              PIC X(003).
           02  MOPCAOO             PIC X(002).
           02  FILLER              PIC X(003).
           02  MTRANSO             PIC X(004).
           02  FILLER              PIC X(003).
           02  MMENSAGO            PIC X(079).
