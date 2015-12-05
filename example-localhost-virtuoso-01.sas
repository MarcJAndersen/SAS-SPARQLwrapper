/*------------------------------------------------------------------------*\
** Program : example-localhost-virtuoso-01.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Status: ok.
\*------------------------------------------------------------------------*/

/*
Windows 7:



*/
    
options mprint mlogic nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:8890/sparql/query,
query=%str(
prefix qb: <http://purl.org/linked-data/cube#>
select *
where { ?s a qb:Observation ; ?p ?o .}
    ),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
