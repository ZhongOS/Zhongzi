#!/bin/bash -e

if [ "x${1}" == "x" ]; then
        echo "必须指定一个包名字。"
        exit 1
fi

ZZ_NAME=default

DEST_DIR="storehouse/${ZZ_NAME}/step/"


