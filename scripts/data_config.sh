#!/bin/bash

# 保存先とファイル名は固定。configには取得方法と取得元だけを書く。
declare -A data_directories=(
    [medgen]=medgen_rdf [mp]=mp [hp]=ontologies/hp [mondo]=ontologies/mondo
    [nando]=ontologies/nando [ordo]=ontologies/ordo [pcf]=pcf_rdf [rdf]=rdf
)
declare -A data_filenames=(
    [medgen]=- [mp]=mp-international.owl [hp]=hp.owl [mondo]=mondo-international.owl
    [nando]=nando.ttl [ordo]=ordo.owl [pcf]=- [rdf]=-
)

load_data_config() {
    local config=$1 config_dir line name method source valid
    local line_number=0 header_seen=false
    [[ -r $config ]] || { echo "configを読み込めません: $config" >&2; return 1; }
    config_dir=$(cd "$(dirname "$config")" && pwd) || return 1
    data_names=()
    declare -gA data_methods=() data_sources=()
    while IFS= read -r line || [[ -n $line ]]; do
        ((line_number += 1))
        line=${line%$'\r'}
        [[ $line =~ ^[[:space:]]*$ ]] && continue
        if ! "$header_seen"; then
            [[ $line == name,method,source ]] || {
                echo "CSVヘッダーは name,method,source にしてください: $config:$line_number" >&2
                return 1
            }
            header_seen=true
            continue
        fi
        # 引用符を使わない3列のCSV。値中のカンマは扱わない。
        if [[ ! $line =~ ^[^,]+,[^,]+,[^,]+$ || $line == *\"* ]]; then
            echo "configは引用符なしの3列のCSVで指定してください: $config:$line_number" >&2
            return 1
        fi
        IFS=, read -r name method source <<< "$line"
        if [[ ! $name =~ ^[a-z][a-z0-9_]*$ || -z ${data_directories[$name]+exists} ||
              -n ${data_methods[$name]+exists} ]]; then
            echo "未対応または重複するデータ名です: $config:$line_number: $name" >&2
            return 1
        fi
        valid=true
        case "$method" in
            download|downloadAndParase)
                [[ $source == - || $source == http://* || $source == https://* ]] || valid=false
                [[ $method != download || ${data_filenames[$name]} != - ]] || valid=false
                ;;
            manual) ;;
            *) valid=false ;;
        esac
        "$valid" || { echo "取得方法・取得元が不正です: $config:$line_number" >&2; return 1; }
        data_names+=("$name")
        data_methods[$name]=$method
        data_sources[$name]=$source
    done < "$config"
    (( ${#data_names[@]} > 0 )) || { echo "configにデータの設定がありません: $config" >&2; return 1; }
}

print_data_notice() {
    local data=$1 latest=$2 filename=${data_filenames[$1]}
    case "${data_methods[$data]}" in
        download|downloadAndParase)
            if [[ ${data_sources[$data]} == - ]]; then
                echo "[URL指定が必要] ${data}: configのsourceに取得元URLを設定してください。配置先: ${latest}/"
            fi
            ;;
        manual)
            [[ $filename != - ]] || filename=''
            echo "[手動配置] ${data}: 自動取得は行いません。配置先: ${latest}/${filename}";;
    esac
}
