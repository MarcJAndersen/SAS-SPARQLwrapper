/*------------------------------------------------------------------------*\
** Program : example-localhost-05.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

/*
Windows 7:

Start jena-fusiki as follows, assuming installation in \opt\jena-fuseki-0.2.7
cd \opt\jena-fuseki-0.2.7
fuseki-server --update --mem /ds


*/

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:3030/ds/query,
queryfile=../SAS-RDF-writer/get-sashelp-mean-age.rq,
querymethod=queryPOST,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;

proc summary data=sashelp.class mean;
var age;
output out=table mean(age)=mean n(age)=n;
run;

proc print data=table;
run;

proc compare data=query compare=table ;
run;
