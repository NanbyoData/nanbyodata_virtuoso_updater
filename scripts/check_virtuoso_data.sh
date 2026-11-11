#!/bin/bash

source /scripts/update_data.sh

isql_exec "SPARQL SELECT ?g (COUNT(?s) AS ?count) WHERE { GRAPH ?g { ?s ?p ?o } } GROUP BY ?g;"