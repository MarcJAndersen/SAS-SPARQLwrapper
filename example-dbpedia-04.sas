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
endpoint=http://dbpedia.org/sparql,
query=%str(
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT  ?label ?abstract
WHERE { <http://dbpedia.org/resource/SPARQL> rdfs:label ?label;
         <http://dbpedia.org/ontology/abstract> ?abstract.
        FILTER (lang(?abstract) = "" || lang(?abstract) = "en")              
    }
),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
