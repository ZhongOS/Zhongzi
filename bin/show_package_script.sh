#!/bin/bash -e

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

for i in $(cat ${PACKAGE_FILE} | grep "^source " | sed "s@^source @@g")
do
	source ${DISTRO_DIR}/$i
done

envsubst <<< "$(cat ${PACKAGE_FILE})"

