#!/bin/bash -e

declare TEST_SHOW=0
declare IS_PATCH=0
declare TARGET_ARCH=""

while getopts 'tpa:' OPT; do
    case $OPT in
        t)
            TEST_SHOW=1
            ;;
	a)
	    TARGET_ARCH=$OPTARG
	    ;;
        ?)
            echo "用法: `basename $0` [选项] 软件包名称 软件版本号 [-a 架构名称]  下载列表文件 文件组名称 文件组下载地址"
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
	echo "必须指定一个软件包名"
	exit 1
fi

if [ "x${2}" == "x" ]; then
	echo "必须指定一个软件包的版本号"
	exit 2
fi

if [ "x${3}" == "x" ]; then
	echo "必须指定一个下载列表文件"
	exit 3
fi

if [ "x${4}" == "x" ]; then
	echo "必须指定一个文件组名称"
	exit 4
fi

if [ "x${5}" == "x" ]; then
	echo "必须指定一个文件组下载地址"
	exit 5
fi

declare PACKAGE_NAME="${1}"
declare PACKAGE_VERSION="${2}"
declare LIST_FILENAME="${3}"
declare LIST_NAME="${4}"
declare LIST_URL="${5}"
declare DEST_DIR=""

shift 2

if [ "x${TEST_SHOW}" == "x1" ]; then
        echo "测试模式。"
        echo "${PACKAGE_NAME}"
        echo "${PACKAGE_VERSION}"
fi

if [ "x${TARGET_ARCH}" != "x" ]; then
	DEST_DIR="sources/${PACKAGE_NAME}/arch/${TARGET_ARCH}/${PACKAGE_VERSION}/"
else
	DEST_DIR="sources/${PACKAGE_NAME}/${PACKAGE_VERSION}/"
fi

if [ "x${DEST_DIR}" != "x" ]; then
	if [ ! -d ./${DEST_DIR} ]; then
		echo "./${DEST_DIR} 目录不存在，请检查！"
		exit 5
	else
		DEST_DIR="${DEST_DIR}/files/"
	fi
fi

if [ ! -d "${DEST_DIR}" ]; then
	mkdir -p ./${DEST_DIR}
fi

if [ -f ${LIST_FILENAME} ]; then
	if [ "x${TEST_SHOW}" == "x1" ]; then
		echo " cp -a ${LIST_FILENAME} ./${DEST_DIR}"
	else
		cp -a ${LIST_FILENAME} ./${DEST_DIR}/
		echo "URL=${LIST_URL}" > ./${DEST_DIR}/${LIST_NAME}.listfile
		echo "FILE=$(basename ${LIST_FILENAME})" >> ./${DEST_DIR}/${LIST_NAME}.listfile
	fi
else
	echo "${LIST_FILENAME} 文件不存在，无法处理。"
fi
