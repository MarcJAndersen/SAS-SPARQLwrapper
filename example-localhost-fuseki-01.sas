/*------------------------------------------------------------------------*\
** Program : example-localhost-07.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

/*
Windows 7:



=====
Start jena-fusiki as follows, assuming installation in \opt\apache-jena-fuseki-2.0.0 and TDB data F:\s108-mja\mja-projects\LinkedCT\linkedCT-tdb

cd/d C:\opt\apache-jena-fuseki-2.0.0
fuseki-server --loc=F:\s108-mja\mja-projects\LinkedCT\linkedCT-tdb /linkedCT



*/

%include "sparqlquery.sas";


%sparqlquery(
endpoint=http://localhost:3030/test/query,
query=%str(select * where {?s ?p ?o}),
querymethod=queryPOST,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=N
);

proc print data=query width=min;
run;


