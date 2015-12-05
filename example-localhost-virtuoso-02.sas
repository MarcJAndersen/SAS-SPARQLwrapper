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



%sparqlupdate(
endpoint=http://localhost:8890/sparql/update,
update=%str(
PREFIX dc: <http://purl.org/dc/elements/1.1/>
INSERT DATA
{ 
GRAPH <http://example/bookStore> {  
<http://example/book1> dc:title "A new book 1" .
<http://example/book2> dc:title "A new book 2" .
<http://example/book3> dc:title "A new book 3" .
<http://example/book4> dc:title "A new book 4" .   
<http://example/book5> dc:title "A new book 5" .   
<http://example/book6> dc:title "A new book 6" .   
<http://example/book7> dc:title "A new book 7" .   
}    
}
),
resultdsn=updateresult,
debug=Y
);



%sparqlquery(
endpoint=http://localhost:8890/sparql/query,
query=%str(
PREFIX dc: <http://purl.org/dc/elements/1.1/>
SELECT *
{ 
  ?s dc:title ?o .
}    
    ),
querymethod=queryGET,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
