#!/bin/bash
set -e

script_dir() {
    SOURCE=${BASH_SOURCE[0]}
    while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
        SOURCE=$(readlink "$SOURCE")
        [[ $SOURCE != /* ]] && SOURCE=$DIR/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo $( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
}

SCRIPT_DIR=$(script_dir)

IFS=' ' read -ra TARGETS <<< $(cat "$SCRIPT_DIR/TARGETS.txt")
for TARGET in "${TARGETS[@]}"; do
    echo "building $TARGET cross compiler"
    docker build --platform=linux/amd64 $SCRIPT_DIR/gcc-cross-compiler --build-arg BUILD_TARGET=$TARGET -t gcc-cross-compiler:$TARGET
done
