      *================================================================*
      * COPYBOOK : SFPM03 - ESTRUTURA SIMBOLICA GERADA PELO BMS        *
      *            MAPSET SFPM03 / MAPA MAPEVEN                        *
      *================================================================*
       01  MAPEVENI.
           02  FILLER              PIC X(012).
           02  MACAOL              PIC S9(004) COMP.
           02  MACAOF              PIC X.
           02  FILLER REDEFINES MACAOF.
               03 MACAOA           PIC X.
           02  MACAOI              PIC X(001).
           02  MCODIGOL            PIC S9(004) COMP.
           02  MCODIGOF            PIC X.
           02  FILLER REDEFINES MCODIGOF.
               03 MCODIGOA         PIC X.
           02  MCODIGOI            PIC X(004).
           02  MDESCRL             PIC S9(004) COMP.
           02  MDESCRF             PIC X.
           02  FILLER REDEFINES MDESCRF.
               03 MDESCRA          PIC X.
           02  MDESCRI             PIC X(030).
           02  MNATURL             PIC S9(004) COMP.
           02  MNATURF             PIC X.
           02  FILLER REDEFINES MNATURF.
               03 MNATURA          PIC X.
           02  MNATURI             PIC X(001).
           02  MDESNATL            PIC S9(004) COMP.
           02  MDESNATF            PIC X.
           02  FILLER REDEFINES MDESNATF.
               03 MDESNATA         PIC X.
           02  MDESNATI            PIC X(020).
           02  MTIPCALL            PIC S9(004) COMP.
           02  MTIPCALF            PIC X.
           02  FILLER REDEFINES MTIPCALF.
               03 MTIPCALA         PIC X.
           02  MTIPCALI            PIC X(003).
           02  MDESTIPL            PIC S9(004) COMP.
           02  MDESTIPF            PIC X.
           02  FILLER REDEFINES MDESTIPF.
               03 MDESTIPA         PIC X.
           02  MDESTIPI            PIC X(034).
           02  MUNIDADL            PIC S9(004) COMP.
           02  MUNIDADF            PIC X.
           02  FILLER REDEFINES MUNIDADF.
               03 MUNIDADA         PIC X.
           02  MUNIDADI            PIC X(002).
           02  MDESUNIL            PIC S9(004) COMP.
           02  MDESUNIF            PIC X.
           02  FILLER REDEFINES MDESUNIF.
               03 MDESUNIA         PIC X.
           02  MDESUNII            PIC X(020).
           02  MPERCENL            PIC S9(004) COMP.
           02  MPERCENF            PIC X.
           02  FILLER REDEFINES MPERCENF.
               03 MPERCENA         PIC X.
           02  MPERCENI            PIC ZZ9,99.
           02  MCONTAL             PIC S9(004) COMP.
           02  MCONTAF             PIC X.
           02  FILLER REDEFINES MCONTAF.
               03 MCONTAA          PIC X.
           02  MCONTAI             PIC X(008).
           02  MSITUACL            PIC S9(004) COMP.
           02  MSITUACF            PIC X.
           02  FILLER REDEFINES MSITUACF.
               03 MSITUACA         PIC X.
           02  MSITUACI            PIC X(001).
           02  MINCINSL            PIC S9(004) COMP.
           02  MINCINSF            PIC X.
           02  FILLER REDEFINES MINCINSF.
               03 MINCINSA         PIC X.
           02  MINCINSI            PIC X(001).
           02  MINCDSRL            PIC S9(004) COMP.
           02  MINCDSRF            PIC X.
           02  FILLER REDEFINES MINCDSRF.
               03 MINCDSRA         PIC X.
           02  MINCDSRI            PIC X(001).
           02  MINCIRRL            PIC S9(004) COMP.
           02  MINCIRRF            PIC X.
           02  FILLER REDEFINES MINCIRRF.
               03 MINCIRRA         PIC X.
           02  MINCIRRI            PIC X(001).
           02  MINC13OL            PIC S9(004) COMP.
           02  MINC13OF            PIC X.
           02  FILLER REDEFINES MINC13OF.
               03 MINC13OA         PIC X.
           02  MINC13OI            PIC X(001).
           02  MINCFGTL            PIC S9(004) COMP.
           02  MINCFGTF            PIC X.
           02  FILLER REDEFINES MINCFGTF.
               03 MINCFGTA         PIC X.
           02  MINCFGTI            PIC X(001).
           02  MINCFERL            PIC S9(004) COMP.
           02  MINCFERF            PIC X.
           02  FILLER REDEFINES MINCFERF.
               03 MINCFERA         PIC X.
           02  MINCFERI            PIC X(001).
           02  MMENSAGL            PIC S9(004) COMP.
           02  MMENSAGF            PIC X.
           02  FILLER REDEFINES MMENSAGF.
               03 MMENSAGA         PIC X.
           02  MMENSAGI            PIC X(079).
      *
       01  MAPEVENO REDEFINES MAPEVENI.
           02  FILLER              PIC X(012).
           02  FILLER              PIC X(003).
           02  MACAOO              PIC X(001).
           02  FILLER              PIC X(003).
           02  MCODIGOO            PIC X(004).
           02  FILLER              PIC X(003).
           02  MDESCRO             PIC X(030).
           02  FILLER              PIC X(003).
           02  MNATURO             PIC X(001).
           02  FILLER              PIC X(003).
           02  MDESNATO            PIC X(020).
           02  FILLER              PIC X(003).
           02  MTIPCALO            PIC X(003).
           02  FILLER              PIC X(003).
           02  MDESTIPO            PIC X(034).
           02  FILLER              PIC X(003).
           02  MUNIDADO            PIC X(002).
           02  FILLER              PIC X(003).
           02  MDESUNIO            PIC X(020).
           02  FILLER              PIC X(003).
           02  MPERCENO            PIC ZZ9,99.
           02  FILLER              PIC X(003).
           02  MCONTAO             PIC X(008).
           02  FILLER              PIC X(003).
           02  MSITUACO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINCINSO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINCDSRO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINCIRRO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINC13OO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINCFGTO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MINCFERO            PIC X(001).
           02  FILLER              PIC X(003).
           02  MMENSAGO            PIC X(079).
