#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SCRIPT_DIR}/data_config.sh"
CONFIG_FILE=''
DATA_ROOT_DIR=''
all_flag=false

usage() {
    echo "使用法: $0 -o <データルートディレクトリ（ontologiesの親）> -c <configファイル> [-a] [データ名 ...]" >&2
    exit 2
}

fail() {
    echo "$*" >&2
    exit 1
}

downloadAndParase() {
    local output_dir=$1 url=$2
    wget --recursive --level=1 --no-parent --no-directories \
        --accept='*.ttl.gz' --continue --directory-prefix="$output_dir" "$url"
    local files=("$output_dir"/*.ttl.gz)
    (( ${#files[@]} > 0 )) || fail "TTL gzipファイルを取得できませんでした: $url"
    gunzip --force -- "${files[@]}"
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
    targets=("${all_data_names[@]}")
fi
(( ${#targets[@]} > 0 )) || usage

# 全対象を確認してから取得を開始する。
for data in "${targets[@]}"; do
    [[ $data =~ ^[a-z][a-z0-9_]*$ && -n ${data_methods[$data]+exists} ]] \
        || fail "configにないデータ名です: $data"
    latest="${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
    case "${data_methods[$data]}" in
        download|downloadAndParase)
            [[ ${data_sources[$data]} != - ]] \
                || fail "取得元URLを設定してください: ${CONFIG_FILE}: ${data} のsource"
            ;;
    esac
    [[ -L $latest && -d $latest ]] \
        || fail "準備済みのlatestがありません: $latest（先にcreate_data_dirs.shを実行してください）"
done

shopt -s nullglob
declare -A installed=()
for data in "${targets[@]}"; do
    [[ -z ${installed[$data]+exists} ]] || continue
    latest="${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
    source=${data_sources[$data]}
    filename=${data_filenames[$data]}
    case "${data_methods[$data]}" in
        download) wget -O "${latest}/${filename}" "$source" ;;
        downloadAndParase) downloadAndParase "$latest" "$source" ;;
        manual) print_data_notice "$data" "$latest" ;;
    esac
    installed[$data]=true
done
