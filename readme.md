# SAS-SPARQLwrapper - SPARQL query wrapper for the Base SAS programming language #

Introduction
===========

This is a SAS macro to perform a SPARQL query to a SPARQL service. 

The macro returns the results as a SAS dataset.

The macro is inspired by the python "SPARQLWrapper 1.5.2" (https://pypi.python.org/pypi/SPARQLWrapper), and the R "SPARQL: SPARQL client" (http://cran.r-project.org/web/packages/SPARQL/index.html).

Synopsis
========

    %SPARQLquery(
       endpoint=http://dbpedia.org/sparql,
       query=%str(
         PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         SELECT ?label
         WHERE { <http://dbpedia.org/class/yago/LinkedData> rdfs:label ?label }
       ),
       resultdsn=query
      );
    proc print data=query width=min;
    run;

Syntax
======

    %SPARQLquery(
       endpoint=<uri>,
       query=<sparql-query>,
       resultdsn=<sas data set name>,
       queryfile=<sparql query file>,
       querymethod=queryGET|queryURLencPOST|queryPOST,
       sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
       debug=< Y | N >,
       debug_nohttp=< Y | N >
       )

Required Arguments
==================

`endpoint=<uri>` is the URI for the SPARQL Protocol service.
  Example: http://dbpedia.org/sparql

`query=<sparql-query>` is SPARQL query as %str macro quoted text. Use of query implies `querymethod=queryGET`
  
Example:
  
   `query=%str(
     PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
     SELECT ?label
     WHERE { <http://dbpedia.org/class/yago/LinkedData> rdfs:label ?label }
   )`

`queryfile=<sparql query file>` is path and filename for a file containing a SPARQL query.

Example:
    `queryfile=cdisc2rdf-fields.rq`

`resultdsn=<sas data set name>` is the name of the SAS dataset containing the result of the SPARQL query

Optional Arguments
==================

`sparqlquerysxlemap=%str(sparqlquery-sxlemap.map)` is the XML MAP file
for the SAS XMLV2 engine. The file `sparqlquery-sxlemap.map` must be
present, and is provided here.

`debug=Y|N` is either `Y` for printing (much) debug information or `N`
for no debug information. The default is no debug information `N`

`debug_nohttp=Y|N` is either `N` for invoking PROC HTTP or `N` for
re-using the existing temporary file name, which is usefull for
debiuggin input of the XML file without calling the SPARQL Protocol
Service. The default is `N`, ie calling the endpoint.

Examples 
========

The files `examples*.sas` demostrates the use of the macro.

Limitation
==========

The LANG attribute is not handled correctly.

Only the SPARQL Query Results XML Format is handled (see references below). Handling of JSON, CSV and TSV formats is pending.

Failure in the query is not handled in an informative way.

Files needed
============
`sparqlquery.sas` contains the macro definition.
`sparqlquery-sxlemap.map` contains the SAS XML map for input of SPARQL Qurey Result in XML


References
==========

SPARQL 1.1 Protocol, W3C Recommendation 21 March 2013: http://www.w3.org/TR/2013/REC-sparql11-protocol-20130321/

Query operation, SPARQL 1.1 Protocol, W3C Recommendation 21 March 2013: http://www.w3.org/TR/2013/REC-sparql11-protocol-20130321/#query-operation

SPARQL Query Results XML Format (Second Edition), W3C Recommendation 21 March 2013: http://www.w3.org/TR/2013/REC-rdf-sparql-XMLres-20130321/


Base SAS programming language: https://www.sas.com/technologies/bi/appdev/base/


