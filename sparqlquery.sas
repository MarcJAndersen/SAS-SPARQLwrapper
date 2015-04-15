/*------------------------------------------------------------------------*\
** Program : sparqlquery.sas
** Purpose : 
\*------------------------------------------------------------------------*/

%MACRO sparqlquery(
endpoint=,
query=,
queryfile=,
resultdsn=,
querymethod=,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=N,
debug_nohttp=N    
    );

%local tempnamestem;
%let tempnamestem=temp-sparqlquery;
%local urlparam;

filename sqresult "&tempnamestem..xml";
filename hdrout "&tempnamestem.-headerOut.txt";

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
/* Clear output file by writing dummy text" */
data _null_;
    length nothing $200;
    nothing=catx(" ", "Nothing here at", put(datetime(),E8601DT19.));
    file sqresult;
    put nothing :;
    file hdrout;
    put nothing :;
run;
%end;    


%if %length(&query)>0 and %qupcase(&querymethod)=%qupcase(queryPOST) %then %do;
filename hdrin "&tempnamestem.-headerIn.txt";
filename sqarqlqu "&tempnamestem..txt";
data filetext;
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

%IF %qupcase(&debug)=%qupcase(Y) %then %do;
data filetext;
   infile hdrout length=ltextlen;
   length textline $200;
   input textline $varying. ltextlen;
   textlen=ltextlen;
   putlog textline $varying. ltextlen;
run;

data filetext;
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
   rearraning the dataset to obtain a rectangular dataset may be made
   in a more straighforward way.
    */
    
filename  SXLEMAP "&sparqlquerysxlemap";

filename  sqresult "&tempnamestem..xml";
libname   sqresult xmlv2 xmlmap=SXLEMAP access=READONLY encoding="utf-8";

/*
* http://support.sas.com/kb/46/233.html;
libname   getsparq xml xmlmap=SXLEMAP access=READONLY;
*/

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

%end;

data variable1;
    set sqresult.variable;
    length var_datatype $64;
    var_datatype=" ";
    max_length=0;
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
       end;
        
    merge
        sqresult.literal
        sqresult.binding
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
    keep valuetextlang;

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

/* This could also be stored in a hash and combined in the step above */
data work.variable2;
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
%let dsid=%sysfunc(open(work.variable2,i)); 
%if (&dsid = 0) %then %do;
     %put sparqlquery: Unexpected problem;
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


%IF %qupcase(&debug)=%qupcase(Y) %then %do;
title2 "&resultdsn.";    
proc print data=&resultdsn. width=min;
run;
%end;


%MEND;

