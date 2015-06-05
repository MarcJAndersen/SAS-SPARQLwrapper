/*------------------------------------------------------------------------*\
** Program : example-dbpedia-04.sas
** Purpose : Basic test of SAS-SPARQLwrapper
** Endpoint: dbpedia    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint mlogic nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://pubmed.bio2rdf.org/sparql,
query=%str(
select distinct ?Concept where {[] a ?Concept} LIMIT 100
),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
