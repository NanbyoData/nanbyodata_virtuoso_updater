#!/bin/bash

isql_exec() {
  /opt/virtuoso-opensource/bin/isql 1111 dba dba "exec=$1"
}

isql_prepare_virtuoso_load() {
    local graph=$1
    local file=$2
    isql_exec "DELETE FROM DB.DBA.LOAD_LIST WHERE ll_graph ='${graph}';"
    isql_exec "log_enable(2,1); SPARQL CLEAR GRAPH <${graph}>;"
    isql_exec "log_enable(2,1); ld_dir_all(${file});"
}

isql_run_virtuoso_load() {
    isql_exec "rdf_loader_run();"
    isql_exec "checkpoint;"
}

isql_load_virtuoso() {
    isql_prepare_virtuoso_load "$1" "$2"
    isql_run_virtuoso_load
}
