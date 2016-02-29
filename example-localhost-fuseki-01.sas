/*------------------------------------------------------------------------*\
** Program : example-localhost-07.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:3030/test/query,
query=%str(select * where {?s ?p ?o})
);

proc print data=query width=min;
run;


