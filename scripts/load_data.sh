#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/data_config.sh"
source "${SCRIPT_DIR}/virtuoso.sh"
CONFIG_FILE=''
DATA_ROOT_DIR=''
all_flag=false

usage() {
    echo "使用法: $0 -o <データルートディレクトリ（ontologiesの親）> -c <configファイル> [-a] [データ名 ...]" >&2
    exit 2
}

declare -A graph_names=(
    [hp]=https://nanbyodata.jp/rdf/ontology/hp
    [medgen]=https://nanbyodata.jp/rdf/medgen
    [mondo]=https://nanbyodata.jp/rdf/ontology/mondo
    [mp]=https://nanbyodata.jp/rdf/ontology/mp
    [nando]=https://nanbyodata.jp/rdf/ontology/nando
    [ordo]=https://nanbyodata.jp/rdf/ontology/ordo
    [pcf]=https://nanbyodata.jp/rdf/pcf
    [rdf]=https://nanbyodata.jp/rdf/nanbyodata
)
declare -A file_patterns=(
    [hp]='*.owl' [medgen]='*.ttl' [mondo]='*.owl' [mp]='*.owl'
    [nando]='*.ttl' [ordo]='*.owl' [pcf]='*.ttl' [rdf]='*.ttl'
)

has_data_file() {
    local file
    for file in "$1"/$2; do
        [[ -f $file ]] && return 0
    done
    return 1
}

while getopts 'o:c:a' opt; do
    case "$opt" in
        o) DATA_ROOT_DIR=$OPTARG ;;
        c) CONFIG_FILE=$OPTARG ;;
        a) all_flag=true ;;
        ?) usage ;;
    esac
done
shift $((OPTIND - 1))
[[ -n $DATA_ROOT_DIR && -n $CONFIG_FILE ]] || usage
DATA_ROOT_DIR=${DATA_ROOT_DIR%/}
load_data_config "$CONFIG_FILE"
targets=("$@")
if "$all_flag"; then
    targets=("${all_data_names[@]}" "$@")
fi
(( ${#targets[@]} > 0 )) || usage

# ファイル不足のままグラフを消去しないよう、全対象を先に確認する。
for data in "${targets[@]}"; do
    if [[ ! $data =~ ^[a-z][a-z0-9_]*$ || -z ${data_methods[$data]+exists} ]]; then
        echo "configにないデータ名です: $data" >&2
        exit 2
    fi
    latest="${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
    if ! has_data_file "$latest" "${file_patterns[$data]}"; then
        echo "ロード対象ファイルが存在しません: ${latest}/${file_patterns[$data]}" >&2
        exit 1
    fi
done

declare -A loaded=()
for data in "${targets[@]}"; do
    [[ -z ${loaded[$data]+exists} ]] || continue
    latest="${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
    # SQL文字列中のシングルクォートをエスケープする。
    latest=${latest//\'/\'\'}
    graph=${graph_names[$data]}
    echo "ロード開始: $data"
    isql_load_virtuoso "$graph" "'${latest}', '${file_patterns[$data]}', '${graph}'"
    loaded[$data]=true
    echo "ロード完了: $data"
done
