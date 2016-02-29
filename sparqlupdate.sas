/*------------------------------------------------------------------------*\
** Program : sparqlupdate.sas
** Purpose : Send Update request sparql service 
\*------------------------------------------------------------------------*/



%MACRO sparqlupdate(
endpoint=,
update=,
updatefile=,
updatemethod=updatePOST,
debug=N,
debug_nohttp=N,
showresponse=Y    
    );

    /* See https://www.w3.org/TR/2013/REC-sparql11-protocol-20130321/#update-operation */
%local tempnamestem;
%let tempnamestem=temp-sparqlupdate;
%local urlparam;

filename hdrout "&tempnamestem.-headerOut.txt";

%if %length(&update)>0 and %qupcase(&updatemethod)=%qupcase(updatePOST) %then %do;
filename hdrin "&tempnamestem.-headerIn.txt";
filename sqarqlqu "&tempnamestem..txt";
data _null_;
   file sqarqlqu TERMSTR=CR;
   length textline $32000;
   textline=symget("update");
   textlen=length(textline);
   put textline $varying. textlen ;
run;

data _null_;
   file hdrin;
   length textline $200;
/*   textline="Accept: application/rdf+xml";*/
/*   textline="Accept: application/sparql-results+xml"; /* Fuseki 2.0 MJA 2015-04-16  */
   textline="Accept: */*"; 
   ltextlen=length(textline);
   put textline $varying. ltextlen;
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    in=sqarqlqu
    url="&endpoint."
    method="post"
    headerin=hdrin  
    headerout=hdrout
    ct="application/sparql-update;charset=utf-8" 
;
run;
%end;

%end;



%if %length(&update)=0  and %length(&updatefile)>0 and %qupcase(&updatemethod)=%qupcase(updatePOST) %then %do;

filename hdrin "&tempnamestem.-headerIn.txt";

filename sqarqlqu "&updatefile.";

data _null_;
   file hdrin;
   length textline $200;
   textline="Accept: application/sparql-results+xml"; /* Fuseki 2.0 MJA 2015-04-16  */
   ltextlen=length(textline);
   put textline $varying. ltextlen;
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    in=sqarqlqu
    url="&endpoint."
    method="post"
    headerin=hdrin  
    headerout=hdrout
    ct="application/sparql-update" 
;
run;
%end;

%end;

%if %length(&update)>0 and %qupcase(&updatemethod)=%qupcase(updateGET) %then %do;
%let urlparam=;
data _null_;
   length paramtext $32000;
   paramtext=urlencode(symget("update"));
   call symputx("urlparam", translate(strip(paramtext),'%2B',"+"));
run;

%if %qupcase(&debug_nohttp)=%qupcase(N) %then %do;
proc http
    url="&endpoint.?update=%superq(urlparam)%nrstr(&)%nrstr(output=xml)"
    method="get"
    headerout=hdrout
;
run;
%end;

%end;

%if %length(&update)=0 and %length(&updatefile)>0 and %qupcase(&updatemethod)=%qupcase(updateGET) %then %do;

%let urlparam=;
data _null_;
   length paramtext $32000;
   retain paramtext " ";

   infile "&updatefile." length=ltextlen end=AllDone;

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
    url="&endpoint.?update=%superq(urlparam)%nrstr(&)%nrstr(output=xml)"
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


%MEND;

