/*------------------------------------------------------------------------*\
** Program : example-dbpedia-05.sas
** Purpose : Basic test of SAS-SPARQLwrapper
** Endpoint: dbpedia    
** Notes: If the programs results in error with encoding SAS tryk starting
          SAS with unicode support
          ========================================
          From explorer window right-click and select
          Batch submit with SAS 9.4 (UTF8)
          ========================================
    
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint mlogic nocenter;

options linesize=200;
options formchar="|----|+|---+=|-/\<>*";

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://dbpedia.org/sparql,
query=%str(
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT  *
    WHERE { ?s ?p ?o .
    ?s  foaf:homepage <http://www.phuse.eu/> .
    }
),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=N
);

proc report data=query missing nofs headline headskip split="¤";
    column s p o;
    define s / display width=30 flow;
    define p / display width=40 flow;
    define o / display width=70 flow;
run;
