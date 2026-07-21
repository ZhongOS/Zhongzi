#!/bin/bash -e

declare CUSTOM_STEP_NAME="default"
declare CUSTOM_SHOW_MODE="S"
while getopts 'm:Z:h' OPT; do
    case $OPT in
	m)
	    CUSTOM_SHOW_MODE=$OPTARG
	    ;;
	Z)
	    CUSTOM_STEP_NAME=$OPTARG
	    ;;
	h|?)
            echo "查寻指定包名称所在步骤路径，默认从 default 仓库中进行查寻。"
	    echo "参数："
	    echo "	m <显示方式>: 指定输出的显示方式，S 表示普通模式显示，R 表示精简方式显示，I 表示按照索引文件的方式显示。"
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

case "x${CUSTOM_SHOW_MODE}" in
	"xS")
		STEP_SHOW_MODE="Standard"
		;;
	"xR")
		STEP_SHOW_MODE="Reduce"
		;;
	"xI")
		STEP_SHOW_MODE="Index"
		;;
	*)
		STEP_SHOW_MODE="Standard"
		;;
esac

for package_i in $(echo ${1} | tr ',' ' ')
do
	for i in $(find storehouse/${ZZ}/step -maxdepth 1 -type d)
	do
		if [ -d ${i}/${package_i} ]; then
			case "${STEP_SHOW_MODE}" in
				Standard)
					echo "发现步骤文件：${i}/${package_i}"
					;;
				Reduce)
					echo "${i}/${package_i}"
					;;
				Index)
					echo "${i}/${package_i}" | sed "s@storehouse/${ZZ}/@%@g"
					;;
			esac
		fi

		if [ -d ${i}/arch ]; then
			for j in $(find ${i}/arch -maxdepth 1 -type d)
			do
				if [ -d ${j}/${package_i} ]; then
					case "${STEP_SHOW_MODE}" in
						Standard)
							echo "发现架构相关的步骤文件：${j}/${package_i}"
							;;
						Reduce)
							echo "${j}/${package_i}"
							;;
						Index)
							echo "${j}/${package_i}" | sed "s@storehouse/${ZZ}/@%@g" | sed "s@arch/\(.*\)/@@g"
							;;
					esac
				fi
			done
		fi
	done
done
