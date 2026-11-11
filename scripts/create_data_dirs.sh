#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd) || exit 1
source "${SCRIPT_DIR}/data_config.sh" || exit 1
CONFIG_FILE=''
DATA_ROOT_DIR=''
all_flag=false

usage() {
    echo "使用法: $0 -o <データルートディレクトリ（ontologiesの親）> -c <configファイル> [-a] [データ名 ...]" >&2
}

while getopts 'o:c:a' opt; do
    case "$opt" in
        o) DATA_ROOT_DIR=$OPTARG ;;
        c) CONFIG_FILE=$OPTARG ;;
        a) all_flag=true ;;
        ?) usage; exit 2 ;;
    esac
done
shift $((OPTIND - 1))

if [[ -z $DATA_ROOT_DIR || -z $CONFIG_FILE ]]; then
    usage
    exit 2
fi

# -o にはontologiesを含むデータルートを指定する。
DATA_ROOT_DIR=${DATA_ROOT_DIR%/}
load_data_config "$CONFIG_FILE" || exit 1

if "$all_flag"; then
    targets=("${data_names[@]}")
else
    targets=("$@")
fi
if (( ${#targets[@]} == 0 )); then
    usage
    exit 2
fi

# 対象名と既存latestを、変更を始める前に検証する。
for data in "${targets[@]}"; do
    if [[ ! $data =~ ^[a-z][a-z0-9_]*$ || -z ${data_methods[$data]+exists} ]]; then
        echo "configにないデータ名です: $data" >&2
        exit 2
    fi
    latest="${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
    if [[ -e $latest || -L $latest ]]; then
        if [[ ! -L $latest || ! -d $latest ]]; then
            echo "latestは有効なディレクトリへのシンボリックリンクである必要があります: $latest" >&2
            exit 1
        fi
    fi
done

today=$(date '+%Y%m%d') || exit 1
for data in "${targets[@]}"; do
    base_dir="${DATA_ROOT_DIR}/${data_directories[$data]}"
    version_dir="${base_dir}/${today}"
    latest="${base_dir}/latest"
    previous_dir=''
    if [[ -L $latest ]]; then
        previous_dir=$(readlink -f "$latest") || exit 1
    fi

    mkdir -p "$version_dir" || exit 1
    # 同日の再実行ではコピーしない。更新済みのデータを維持する。
    if [[ -n $previous_dir && $previous_dir -ef $version_dir ]]; then
        continue
    fi
    ln -sfn "$today" "$latest" || exit 1
    # 手動配置のデータだけを、更新日時などの属性を保持してコピーする。
    if [[ ${data_methods[$data]} == manual && -n $previous_dir ]]; then
        if ! cp -a -- "${previous_dir}/." "${latest}/"; then
            echo "過去データのコピーに失敗しました: $previous_dir -> $latest" >&2
            exit 1
        fi
    fi
done

# コピーを含む全対象の準備が完了してから、別途用意するデータを案内する。
echo "ディレクトリの準備が完了しました。"
for data in "${targets[@]}"; do
    print_data_notice "$data" "${DATA_ROOT_DIR}/${data_directories[$data]}/latest"
done
