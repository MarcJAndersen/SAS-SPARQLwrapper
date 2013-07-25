/*------------------------------------------------------------------------*\
** Program : example-localhost-01.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Status: ok.
\*------------------------------------------------------------------------*/

/*
Windows 7:

Start jena-fusiki as follows, assuming installation in \opt\jena-fuseki-0.2.7
cd \opt\jena-fuseki-0.2.7
fuseki-server --update --mem /books

In another window:
cd \opt\jena-fuseki-0.2.7
ruby s-put http://localhost:3030/books/data default Data/books.ttl

Check:
ruby s-query --service http://localhost:3030/books/query 'SELECT * {?s ?p ?o}'

*/
    
options mprint mlogic nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:3030/books/query,
query=%str(
select * where {?s ?p ?o}
    ),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
