/*------------------------------------------------------------------------*\
** Program : example-localhost-02.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a query and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

/*
Windows 7:

Start jena-fusiki as follows, assuming installation in \opt\jena-fuseki-0.2.7
cd \opt\jena-fuseki-0.2.7
fuseki-server --update --mem /cdiscrdf

In another window - assuming cdisc2rdf related files stored in \opt\cdisc2rdf:
cd \opt\jena-fuseki-0.2.7
ruby s-put http://localhost:3030/cdiscrdf/data default \opt\cdisc2rdf\ontologies\sdtmig-3-1-2.owl

*/
    
%include "sparqlquery.sas";

%sparqlquery(
endpoint=http://localhost:3030/cdiscrdf/query,
queryfile=cdisc2rdf-fields.rq,
querymethod=queryPOST,
resultdsn=query,
sparqlquerysxlemap=%str(sparqlquery-sxlemap.map),
debug=Y
);

proc print data=query width=min;
run;
