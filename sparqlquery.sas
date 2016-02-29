/*------------------------------------------------------------------------*\
** Program : sparqlquery.sas
** Purpose : Query sparql service and return result as SAS dataset 
\*------------------------------------------------------------------------*/

%MACRO sparqlquery(
    endpoint=,
    query=,
    queryfile=,
    resultdsn=queryresult,
    querymethod=queryPOST,
    frsxlemap=SXLEMAP,
    tempnamestem=temp-sparqlquery,
    sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
    problemHandling=ABORTCANCEL,
    debug=N,
    debug_nohttp=N,
    showresponse=Y        
    );

%local urlparam;
%local rc;

%let rc=%sysfunc(fileref(&frsxlemap.));
%if &rc ne 0 %then %do;    
    filename  &frsxlemap. "&sparqlquerysxlemap";
    %end;

/* ===== verify parameters ===== */
%if %length(&query)>0 and %length(&queryfile)>0 %then %do;
    %putlog sparqlquery: parameter query and queryfile are both assigned a value.;
    %putlog sparqlquery: only one parameter can be set.;    
    %if %qupcase(&problemHandling.)=ABORTCANCEL %then %do;
        data _null_;
            abort cancel;
            run;
            %end;
        %else %do;
            %return;
            %end;
%end;

%if not (%qupcase(&querymethod.)=%qupcase(queryPOST) or %qupcase(&querymethod.)=%qupcase(queryGET))  %then %do;
    %putlog sparqlquery: querymethod=&querymethod. can not be handled.;
    %putlog sparqlquery: Only  querymethod=queryPOST or querymethod=queryGET is handled.;    
    %if %qupcase(&problemHandling.)=ABORTCANCEL %then %do;
        data _null_;
            abort cancel;
            run;
            %end;
        %else %do;
            %return;
            %end;
%end;

/* ===== setup for PROC HTTP call  ===== */

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;

data _null_;
    fname="tempfile";
    length fnpath $512;
    do fnpath="&tempnamestem..xml", "&tempnamestem.-headerOut.txt";
    rc=filename(fname, fnpath );
    if rc = 0 and fexist(fname) then do;
        rc=fdelete(fname);
        end;
    rc=filename(fname);
    end;
run;
               
%end;    


filename sqresult "&tempnamestem..xml";
filename hdrout "&tempnamestem.-headerOut.txt";

%if %length(&query)>0 and %qupcase(&querymethod)=%qupcase(queryPOST) %then %do;
filename hdrin "&tempnamestem.-headerIn.txt";
filename sqarqlqu "&tempnamestem..txt";
data _null_;
   file sqarqlqu TERMSTR=CR;
   length textline $32000;
   textline=symget("query");
   textlen=length(textline);
   put textline $varying. textlen ;
run;

data _null_;
   file hdrin;
   length textline $200;
/*   textline="Accept: application/rdf+xml";*/
   textline="Accept: application/sparql-results+xml"; /* Fuseki 2.0 MJA 2015-04-16  */
   ltextlen=length(textline);
   put textline $varying. ltextlen;
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    in=sqarqlqu
    out=sqresult
    url="&endpoint."
    method="post"
    headerin=hdrin  
    headerout=hdrout
    ct="application/sparql-query" 
;
run;
%end;

%end;


%if %length(&query)=0  and %length(&queryfile)>0 and %qupcase(&querymethod)=%qupcase(queryPOST) %then %do;

filename hdrin "&tempnamestem.-headerIn.txt";

filename sqarqlqu "&queryfile.";

data _null_;
   file hdrin;
   length textline $200;
/*   textline="Accept: application/rdf+xml"; */
   textline="Accept: application/sparql-results+xml"; /* Fuseki 2.0 MJA 2015-04-16  */
   ltextlen=length(textline);
   put textline $varying. ltextlen;
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    in=sqarqlqu
    out=sqresult
    url="&endpoint."
    method="post"
    headerin=hdrin  
    headerout=hdrout
    ct="application/sparql-query" 
;
run;
%end;

%end;

%if %length(&query)>0 and %qupcase(&querymethod)=%qupcase(queryGET) %then %do;
%let urlparam=;
data _null_;
   length paramtext $32000;
   paramtext=urlencode(symget("query"));
   call symputx("urlparam", translate(strip(paramtext),'%2B',"+"));
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    out=sqresult
    url="&endpoint.?query=%superq(urlparam)%nrstr(&)%nrstr(output=xml)"
    method="get"
    headerout=hdrout
;
run;
%end;

%end;

%if %length(&query)=0 and %length(&queryfile)>0 and %qupcase(&querymethod)=%qupcase(queryGET) %then %do;

%let urlparam=;
data _null_;
   length paramtext $32000;
   retain paramtext " ";

   infile "&queryfile." length=ltextlen end=AllDone;

   length textline $200;
   input textline $varying. ltextlen;
   textlen=ltextlen;

   if textlen=0 then do;
       paramtext=cats(paramtext, urlencode("0a0d"x));
       end;
   else do;
       paramtext=catx(urlencode("0a0d"x),paramtext,urlencode(substr(textline,1,textlen)));
   end;
    
   if alldone then do;
      call symputx("urlparam", translate(strip(paramtext),'%2B',"+"));
   end;
run;

proc http
    out=sqresult
    url="&endpoint.?query=%superq(urlparam)%nrstr(&)%nrstr(output=xml)"
    method="get"
    headerout=hdrout
;
run;

%end;

%IF %qupcase(&debug)=%qupcase(Y) or %qupcase(&showresponse)=%qupcase(Y) %then %do;
data _null_;
   infile hdrout length=ltextlen;
   length textline $200;
   input textline $varying. ltextlen;
   textlen=ltextlen;
   putlog textline $varying. ltextlen;
run;
%end;

%IF %qupcase(&debug)=%qupcase(Y) %then %do;
data _null_;
   infile sqresult length=ltextlen;
   length textline $200;
   input textline $varying. ltextlen;
   textlen=ltextlen;
   putlog textline $varying. ltextlen;
run;
%end;

/* MJA 2013-07-25
   Here is used a fixed map for SAS XML input.
   I have a hunch that the map could be generated from the xlm file to
   get the rectangular dataset directly. So, the approach below
   rearranging the dataset to obtain a rectangular dataset may be made
   in a more straighforward way.
    */
    
%if %sysfunc(fileexist(sqresult)) %then %do;
    %put sparqlquery: filename SQRESULT %sysfunc(pathname(sqresult)) does not exist.;
        %if %qupcase(&problemHandling.)=ABORTCANCEL %then %do;
        data _null_;
            abort cancel;
            run;
            %end;
        %else %do;
            %return;
            %end;
        %end;
    
libname   sqresult xmlv2 xmlmap=&frsxlemap. access=READONLY encoding="utf-8";

%IF %qupcase(&debug)=%qupcase(Y) %then %do;
    title2 "sqresult.variable";
    proc contents data=sqresult.variable varnum;
        run;
        
    proc print data=sqresult.variable width=min;
    run;
    
    title2 "sqresult.binding";
    proc contents data=sqresult.binding varnum;
    run;
    
    proc print data=sqresult.binding width=min;
    run;
    
    title2 "sqresult.literal";
    proc contents data=sqresult.literal varnum;
    run;
    
    proc print data=sqresult.literal width=min; 
    run;
    title2;

%end;

data binding1;
    set SQRESULT.binding;
    name= translate(strip(name),"_","-"); /*maybe use other method, like replace - with _ etc */
run;
    
data variable1;
    set sqresult.variable;
    length var_datatype $64;
    var_datatype=" ";
    max_length=1; /* default length for character of 1 character - to handle no records in result */
    name= translate(strip(name),"_","-"); /*maybe use other method, like replace - with _ etc */
run;

/* go through all records and determine datatype and maximal
    length.
    Use that to make attribute statements
    */
data sq;
   if _n_=1 then do;
       if 0  then do;
           set variable1;
           end;
       declare hash variable(dataset: "variable1" );
       variable.defineKey('name');
       variable.defineData(all: "YES");
       variable.defineDone();
       /* make empty dataset - way of handling the case with no records in result */
       variable.output(dataset:"work.variable2");    

       end;
        
    merge
        sqresult.literal
        binding1
        end=AllDone
        ;
    by binding_CNT binding_ORDINAL;
    length valuetext $32000;
    length valuetexttype $65;
/*    length valuetextlang $2; */
    if missing(uri) then do;
        valuetext=literal;
        valuetexttype=datatype;
/* I do not understand why lang is blank. In SAS XMLmapper the lang column is populated 
        valuetextlang=lang;
*/
        end;
    else do;
        valuetext=uri;
        valuetexttype="uri";
/*
        valuetextlang=" ";
*/        
        end;

    keep binding_CNT name valuetext;
/*
    keep valuetextlang;
    */
    
    rc=variable.find();
    if rc ne 0 then do;
        putlog name= " unexpected name";
        end;
    else do;
        select;
        when (var_datatype=valuetexttype) do; 
       /* nothing */
        end;
        when (missing(var_datatype)) do; 
           var_datatype=valuetexttype;
           variable.replace();
        end;
        otherwise do;
           putlog name= var_datatype= valuetexttype= " unexpected more than one datatype";
        end;
        end;

        if length(valuetext)>max_length then do;
           max_length=length(valuetext);
           variable.replace();
        end;  

   end;

   if alldone then do;
      variable.output(dataset:"work.variable2");    
   end;
run;

proc sort data=work.variable2;
    by variable_ORDINAL;
run;

%IF %qupcase(&debug)=%qupcase(Y) %then %do;
title2 "work.variable2";    
proc print data=work.variable2 width=min;
run;
%end;

/* This could also be stored in a hash or made as a format and combined in the step above */
data work.variable3;
    set work.variable2;
    length var_informat $33 var_type $1;
    select;
    /* Add additonal data types here */
    when (var_datatype="http://www.w3.org/2001/XMLSchema#string"  ) do; var_type="C"; var_informat=" "; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#integer" ) do; var_type="N"; var_informat="best."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#long"    ) do; var_type="N"; var_informat="best."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#double"  ) do; var_type="N"; var_informat="best."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#float"   ) do; var_type="N"; var_informat="best."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#decimal" ) do; var_type="N"; var_informat="best."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#dateTime") do; var_type="N"; var_informat="E8601DT."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#date"    ) do; var_type="N"; var_informat="E8601DA."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#time"    ) do; var_type="N"; var_informat="E8601TM."; end;
    when (var_datatype="http://www.w3.org/2001/XMLSchema#boolean" ) do; var_type="C"; var_informat=" "; end;
    otherwise do; var_type="C"; var_informat=" "; end;
    end;

run;


%local dsid rc;
%let dsid=%sysfunc(open(work.variable3,i)); 
%if (&dsid = 0) %then %do;
     %put sparqlresult: Unexpected problem;
     %put %sysfunc(sysmsg());
     %end;
%else %do;
%syscall set(dsid); 

/* Re-arrange the dataset -
   this is essentially:
        PROC TRANSPOSE;
        by binding_CNT;
        var valuetext;
        id name;
        run;
*/

/* Could also generate the code as text file and subsequently include it */

/* The length statement below is to re-size the character variables. This
   gives a warning - it can be programmed in other ways. */    
data &resultdsn;

%let i=1;        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%do %while(&rc=0);
keep &name.;
/* keep %unquote(%trim(&name.))_lang; */
%if %qupcase(&var_type)=%qupcase(N) %then %do;
format &name. &var_informat.;
%end;
%if %qupcase(&var_type)=%qupcase(C) %then %do;
length &name. %unquote($%trim(&max_length.));
%end;
%let i=%eval(&i+1);        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%end;


    merge

%let i=1;        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%do %while(&rc=0);
sq(where=(name_&variable_ORDINAL.="%trim(&name)")
   rename=(
name=name_&variable_ORDINAL.
%if %qupcase(&var_type)=%qupcase(N) %then %do;
valuetext=%unquote(%trim(&name.)_c)
%end;
%else %do;
valuetext=&name.
%end;
/* valuetextlang=%unquote(%trim(&name.))_lang */
        )
)
%let i=%eval(&i+1);        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%end;            
;
by binding_CNT;

%let i=1;        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%do %while(&rc=0);
%if %qupcase(&var_type)=%qupcase(N) %then %do;
&name.=input(%unquote(%trim(&name.)_c),&var_informat.);
drop %unquote(%trim(&name.)_c);
%end;
%let i=%eval(&i+1);        
%let rc=%sysfunc(fetchobs(&dsid,&i));
%end;

%if &dsid > 0 %then 
   %let rc=%sysfunc(close(&dsid));
%end;
        run;        
* *******************************************************************;        
* Warning ... Multiple lengths were specified for the variable ...;
* can be ignored. ;
* *******************************************************************;         

libname sqresult clear;

%IF %qupcase(&debug)=%qupcase(Y) %then %do;
title2 "&resultdsn.";    
proc print data=&resultdsn. width=min;
        run;
title2;
%end;


%MEND;


