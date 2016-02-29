/*------------------------------------------------------------------------*\
** Program : example-localhost-07.sas
** Purpose : Basic test of SAS-SPARQLwrapper using a update and local server
** Endpoint: localhost    
** Notes: SAS must be invoked with unicode support   
** Status: ok    
\*------------------------------------------------------------------------*/

options mprint nocenter;

%include "sparqlquery.sas";

%sparqlupdate(
endpoint=http://localhost:3030/test/update,
update=%str(
prefix ct:    <http://bio2rdf.org/clinicaltrials> 
prefix css:   <http://www.example.org/CSS> 
prefix owl:   <http://www.w3.org/2002/07/owl#> 
prefix rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
prefix xsd:   <http://www.w3.org/2001/XMLSchema#> 
prefix rdfs:  <http://www.w3.org/2000/01/rdf-schema#> 

INSERT DATA
{ 
ct:NCT00799760  css:enrollment  "541"^^xsd:int ;
        css:phase       "Phase 3"@en ;
        css:title       "Evaluation of Efficacity and Safety of Oseltamivir and Zanamivir"@en .
}            
),    
resultdsn=updateresult,
debug=Y
);

proc print data=updateresult width=min;
run;


