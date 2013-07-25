/*------------------------------------------------------------------------*\
** Program : example-dbpedia-01.sas
** Purpose : Basic test of SAS-SPARQLwrapper
** Endpoint: dbpedia    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint /* mlogic */ nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://dbpedia.org/sparql,
query=%str(
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT  ?label
WHERE { <http://dbpedia.org/class/yago/LinkedData> rdfs:label ?label.
    }
),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
