/*------------------------------------------------------------------------*\
** Program : example-localhost-07.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a update and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

%include "sparqlquery.sas";
%include "sparqlupdate.sas";

%sparqlupdate(
endpoint=http://localhost:3030/test/update,
update=%str(
PREFIX ex: <http://example.org/>

INSERT { ex:aa ex:bb ?p1 ;
ex:cc ?p2. }
WHERE
{ values(?p1 ?p2) { ("a" 1) ("b" 2) } }
),    
debug=Y
);



%sparqlquery(
endpoint=http://localhost:3030/test/query,
query=%str(select * where {?s ?p ?o})
);

proc print data=queryresult width=min;
run;


