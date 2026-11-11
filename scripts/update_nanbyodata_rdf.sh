#!/bin/bash

source /scripts/update_data.sh

GRAPH_NAME='https://nanbyodata.jp/rdf/nanbyodata'

isql_exec "DELETE FROM DB.DBA.LOAD_LIST WHERE ll_graph ='${GRAPH_NAME}';"
isql_exec "log_enable(2,1); SPARQL CLEAR GRAPH <${GRAPH_NAME}>;"
isql_exec "log_enable(2,1); ld_dir_all('/rdf_data/nanbyodata/rdf/latest', '*.ttl', '${GRAPH_NAME}');"
isql_exec "rdf_loader_run();"
isql_exec "checkpoint;"