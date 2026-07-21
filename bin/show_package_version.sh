#!/bin/bash -e

source environment/functions

declare CUSTOM_VERSIONS_NAME="Default"
while getopts 's:S:P:p:N:jfh' OPT; do
    case $OPT in
 
	N)
	    CUSTOM_VERSIONS_NAME=$OPTARG
	    ;;
	h|?)
            echo "显示指定软件包当前的版本。"
	    echo "参数："
	    echo "	N <软件版本组名称>: 设置从哪个软件版本组名称的目录中查寻软件版本号，指定的名称为 package_version 目录中的目录名，不指定该参数将查寻 package_version/Default 目录中的版本号。"
	    exit 0
	    ;;
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
	echo "请输入一个软件包名称"
fi

if [ -d package_version/${CUSTOM_VERSIONS_NAME} ]; then
	echo "在 package_version/${CUSTOM_VERSIONS_NAME} 目录中查寻..."
else
	echo "没有找到 package_version/${CUSTOM_VERSIONS_NAME} 目录，清检查 -N 参数指定的名称是否正确。"
	echo "可用的名称有："
	for i in $(find package_version/ -maxdepth 1 -o -type d -o -type l | sed "s@package_version/@@")
	do
		if [ -h package_version/${i} ]; then
			echo "	${i} -> $(readlink package_version/${i})"
		else
			echo "	${i}"
		fi
	done
	exit 9
fi

if [ -f package_version/${CUSTOM_VERSIONS_NAME}/${1}.version ]; then
	echo "主版本：$(cat package_version/${CUSTOM_VERSIONS_NAME}/${1}.version)"
	echo "        URL：$(cat package_version/${CUSTOM_VERSIONS_NAME}/${1}.url)"
fi

if [ -f package_version/${CUSTOM_VERSIONS_NAME}/Settings/${1}.version ]; then
	echo "默认版本：$(cat package_version/${CUSTOM_VERSIONS_NAME}/Settings/${1}.version)"
	echo "          URL：$(cat package_version/${CUSTOM_VERSIONS_NAME}/Settings/${1}.url)"
fi

for i in $(ls package_version/${CUSTOM_VERSIONS_NAME}/arch)
do
	if [ -f package_version/${CUSTOM_VERSIONS_NAME}/arch/${i}/${1}.version ]; then
		echo "$(basename ${i})架构的版本：$(cat package_version/${CUSTOM_VERSIONS_NAME}/arch/${i}/${1}.version)"
		echo "               URL：$(cat package_version/${CUSTOM_VERSIONS_NAME}/arch/${i}/${1}.url)"
	fi
done
