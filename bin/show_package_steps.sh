#!/bin/bash -e

declare CUSTOM_STEP_NAME="default"
while getopts 'Z:h' OPT; do
    case $OPT in
	Z)
	    CUSTOM_STEP_NAME=$OPTARG
	    ;;
	h|?)
            echo "查寻指定包名称所在步骤路径，默认从 default 仓库中进行查寻。"
	    echo "参数："
	    echo "	Z <起始步骤文件名称>: 指定从哪个仓库中查寻包名称，不指定该参数将在 default 仓库中查寻。"
	    exit 0
	    ;;
    esac
done
shift $(($OPTIND - 1))

if [ "x${1}" == "x" ]; then
	echo "请输入一个包名称"
fi

# ZZ="default"
ZZ="${CUSTOM_STEP_NAME}"

for i in $(find storehouse/${ZZ}/step -maxdepth 1 -type d)
do
	if [ -d ${i}/${1} ]; then
		echo "发现步骤文件：${i}/${1}"
	fi

	if [ -d ${i}/arch ]; then
		for j in $(find ${i}/arch -maxdepth 1 -type d)
		do
			if [ -d ${j}/${1} ]; then
				echo "发现架构相关的步骤文件：${j}/${1}"
			fi
		done
	fi
done
