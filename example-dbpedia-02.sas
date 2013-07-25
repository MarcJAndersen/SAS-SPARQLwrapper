/*------------------------------------------------------------------------*\
** Program : example-dbpedia-02.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query provided in a file
** Endpoint: dbpedia
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint mlogic nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://dbpedia.org/sparql,
queryfile=capitals-europe.rq,
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
