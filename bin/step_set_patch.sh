#!/bin/bash

declare TARGET_ARCH=""

while getopts 'a:' OPT; do
    case $OPT in
        a)
            TARGET_ARCH=$OPTARG
            ;;
        ?)
            echo "用法: `basename $0` [-a 架构名] 步骤名 步骤组名"
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
        echo "必须指定一个包名字。"
        exit 1
fi

if [ "x${2}" == "x" ]; then
        echo "必须指定一个所属步骤路径的名字。"
        exit 1
fi

ZZ_NAME=default


DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/${1}/"

if [ "x${TARGET_ARCH}" != "x" ]; then
        DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/arch/${TARGET_ARCH}/${1}"
else
        DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/${1}/"
fi

if [ ! -d ${DEST_DIR} ]; then
	echo "没有发现 ${DEST_DIR} 目录，无法继续！"
	exit 2
fi

vi ${DEST_DIR}/${1}.patches
