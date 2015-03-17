/*------------------------------------------------------------------------*\
** Program : example-localhost-css-2015-v01.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Status: ok.
\*------------------------------------------------------------------------*/

/*
Windows 7:

Get jena-fuseki from http://jena.apache.org/download/index.cgi
See documentation at http://jena.apache.org/documentation/fuseki2/fuseki-run.html#fuseki-as-a-standalone-server

Unzip archive to a suitable directory, I use c:\opt\jena-fuseki-2.0.0
Start the jena jena-fuseki server by opening a terminal

cd/d c:\opt\jena-fuseki-2.0.0
fuseki-server --update --mem /arm

Open a web browser, open http://localhost:3030/

Adding example data

A public available turtle file is the example from the w3c RDF data cube definition
http://publishing-statistical-data.googlecode.com/svn/trunk/specs/src/main/example/example.ttl. Download the file to local store, and then upload the file to fuseki.

Select add data, and upload the file.


*/
    
options mprint mlogic nocenter;

%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:3030/arm/query,
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
