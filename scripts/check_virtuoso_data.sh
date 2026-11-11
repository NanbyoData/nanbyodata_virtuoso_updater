#!/bin/bash

source /scripts/virtuoso.sh

isql_exec "SPARQL SELECT ?g (COUNT(?s) AS ?count) WHERE { GRAPH ?g { ?s ?p ?o } } GROUP BY ?g;"
