#!/bin/bash

source environment/functions

if [ "x${1}" == "x" ]; then
        echo "必须指定一个名字。"
        exit 1
fi

if [ "x${2}" == "x" ]; then
        echo "必须指定一个架构。"
        exit 2
fi

if [ "x${3}" == "x" ]; then
        echo "必须指定一个包路径。"
        exit 3
fi


DISTRO_NAME=${1}
DISTRO_ARCH=${2}
DISTRO_DIR=distro/${DISTRO_NAME}/${DISTRO_ARCH}
PACKAGE_FILE=${DISTRO_DIR}/scripts/step/${3}

pushd ${DISTRO_DIR} > /dev/null
	echo -n "正在执行${3}..."
	bash -e scripts/step/${3} >/tmp/a.log 2>&1
	if [ "x$?" == "x0" ]; then
		echo "完成。"
	else
		echo "发生了错误，请查看/tmp/a.log文件内容。"
	fi
popd > /dev/null

# envsubst <<< "$(cat ${PACKAGE_FILE})"

