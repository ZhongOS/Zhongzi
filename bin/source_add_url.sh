#!/bin/bash -e

declare TEST_SHOW=0
declare IS_PATCH=0
declare IS_GIT_REPO=0
declare TARGET_ARCH=""

while getopts 'tga:' OPT; do
    case $OPT in
        t)
            TEST_SHOW=1
            ;;
        g)
            IS_GIT_REPO=1
            ;;
	a)
	    TARGET_ARCH=$OPTARG
	    ;;
        ?)
            echo "用法: `basename $0` [选项] 软件包名称 软件版本号 [-a 架构名称]  下载URL 存储文件名"
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
	echo "必须指定一个URL地址"
	exit 3
fi

if [ "x${4}" == "x" ]; then
	echo "必须指定文件名"
	exit 4
fi

declare PACKAGE_NAME="${1}"
declare PACKAGE_VERSION="${2}"
declare FILE_URL="${3}"
declare URL_FILENAME="${4}"
declare DEST_DIR=""

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
if [ "x${IS_PATCH}" == "x1" ]; then
	DEST_DIR="${DEST_DIR}/patches/"
fi

if [ ! -d "${DEST_DIR}" ]; then
	mkdir -p ./${DEST_DIR}
fi

case "${FILE_URL%%/*}" in
	https: | http: | ftps: | ftp:)
		echo "URL=${FILE_URL}" > ./${DEST_DIR}/${URL_FILENAME}.url
		echo "FILENAME=${URL_FILENAME}" >> ./${DEST_DIR}/${URL_FILENAME}.url
		if [ "x${IS_GIT_REPO}" == "x0" ]; then
			echo "MODE=FILE" >> ./${DEST_DIR}/${URL_FILENAME}.url
		else
			echo "MODE=GIT" >> ./${DEST_DIR}/${URL_FILENAME}.url
			echo "GIT_BRANCH=" >> ./${DEST_DIR}/${URL_FILENAME}.url
			echo "GIT_COMMIT=" >> ./${DEST_DIR}/${URL_FILENAME}.url
			echo "GIT_SUBMODULE=0" >> ./${DEST_DIR}/${URL_FILENAME}.url
			echo "GIT_UPDATE_MODE=手工" >> ./${DEST_DIR}/${URL_FILENAME}.url
		fi
		;;
 	git:)
		echo "URL=${FILE_URL}" > ./${DEST_DIR}/${URL_FILENAME}.url
		echo "FILENAME=${URL_FILENAME}" >> ./${DEST_DIR}/${URL_FILENAME}.url
		echo "MODE=GIT" >> ./${DEST_DIR}/${URL_FILENAME}.url
		echo "GIT_BRANCH=" >> ./${DEST_DIR}/${URL_FILENAME}.url
		echo "GIT_COMMIT=" >> ./${DEST_DIR}/${URL_FILENAME}.url
		echo "GIT_SUBMODULE=0" >> ./${DEST_DIR}/${URL_FILENAME}.url
		echo "GIT_UPDATE_MODE=手工" >> ./${DEST_DIR}/${URL_FILENAME}.url
		;;
	*)
		echo "${FILE_URL} 不是一个有效协议的URL地址，无法处理，请使用http(s)、ftp(s)、git协议的地址。"
		;;
esac
