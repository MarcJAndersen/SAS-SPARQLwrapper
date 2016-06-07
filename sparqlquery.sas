/*------------------------------------------------------------------------*\
** Program : sparqlquery.sas
** Purpose : Query sparql service and return result as SAS dataset
** Parameters for the macro

endpoint : the endpoint for the SPARQL query                                        
query    : the query as a text, suggested to quote in %str()
queryfile: the filename for the text file with the quert
resultdsn: dataset name for storing the result of the query
queryForm: SELECT or DESCRIBE
querymethod: query method, default queryPOST
frsxlemap: the name for the filename contining the XML map, default SXLEMAP
tempnamestem: stem for temporary file temp-sparqlquery
queryResultRDFgraph: name , default %str(queryResultRDFgraph.ttl)
sparqlquerysxlemap: name of file with XML map, default %str(sparqlquery-sxlemap.map)
problemHandling: problem handling, default ABORTCANCEL
debug: debug flag, Y will provide output, default N,
debug_nohttp: flag for NOT doing the PROC HTTP call,  default N
showresponse: flag for showing the return response, default Y        

\*------------------------------------------------------------------------*/

%MACRO sparqlquery(
    endpoint=,                                        
    query=,
    queryfile=,
    resultdsn=queryresult,
    queryForm=SELECT,
    querymethod=queryPOST,
    frsxlemap=SXLEMAP,
    tempnamestem=temp-sparqlquery,
    queryResultRDFgraph=%str(queryResultRDFgraph.ttl),
    sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
    problemHandling=ABORTCANCEL,
    debug=N,
    debug_nohttp=N,
    showresponse=Y        
    );

%local urlparam;
%local rc;

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


%if %qupcase(&queryForm)=CONSTRUCT %then %do;
    filename sqresult "&queryResultRDFgraph.";
        %end;
    %else %do;
        filename sqresult "&tempnamestem..xml";
%end;

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


%if %qupcase(&queryForm) = CONSTRUCT %then %do;
data _null_;
   infile sqresult length=ltextlen;
   length textline $200;
   if _n_=1 then do;
       textline= pathname("sqresult");
       putlog "Result for RDF graph (first 10 lines)" / textline: ;
       end;
   input textline $varying. ltextlen;
   textlen=ltextlen;
   putlog textline $varying. ltextlen;
   if _n_=10 then do;
       stop;
       end;
run;
            
%end;


%if %qupcase(&queryForm) ne CONSTRUCT %then %do;

%sparqlreadxml(
    sparqlquerysxlemap=&sparqlquerysxlemap.,
    sparqlqueryresultxml=&tempnamestem..xml,
    frsxlemap=&frsxlemap.,
    resultdsn=&resultdsn.,
    debug=&debug.
    );

%end;


%MEND;


