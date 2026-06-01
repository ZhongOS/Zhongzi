#!/bin/bash

declare TARGET_ARCH=""
declare MOVE_OPT=0
declare TEST_MODE=0
declare CREATE_MODE=0
declare SRC_STR=""

while getopts 'cts:h' OPT; do
    case $OPT in
	c)
	    CREATE_MODE=1
	    ;;
	t)
	    TEST_MODE=1
	    ;;
        s)
            SRC_STR=$OPTARG
            ;;
        h|*)
            echo "用法: `basename $0` [-c] [-t] [-s SRC_STR] DEST_STR"
	    echo "c: 进行步骤组的创建，必须明确指定该参数才会真实创建。"
	    echo "t: 测试模式，只显示创建的方式，并不进行真实的创建。"
# 	    echo "s <参考步骤组>: 该参数需要指定一个步骤组的名称，新创建的步骤组将采用指定的步骤组作为参考进行新的步骤组的创建。如果该参数不指定将使用default/template/target_base作为新步骤组的参考。"
	    echo "s <参考步骤组>: 该参数需要指定一个步骤组的名称, 格式 <zz_name>%<stepname>，新创建的步骤组将采用指定的步骤组作为参考进行新的步骤组的创建。如果该参数不指定将使用 template%target-system 作为新步骤组的参考。"
	    exit 0
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
        echo "必须指定一个目的步骤路径名字。<zz_name>%<stepname>"
        exit 1
fi

if [ "x${2}" != "x" ]; then
	echo "请使用-s指定源目的步骤路径。"
	exit 2
fi

function get_string_zz
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}%" || echo "NULL"
}

function get_string_stepname
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}" | tail -n1
}

# loongarch64:default%target_base/package


if [ "x${SRC_STR}" == "x" ]; then
	SRC_STR="template%target-system"
fi

SRC_STEPNAME=$(get_string_stepname "${SRC_STR}")
if [ "x${SRC_STEPNAME}" == "x" ]; then
	echo "由于给定的复制源信息中无法判别出步骤名，无法继续！"
	exit 2
fi
SRC_ZZ=$(get_string_zz "${SRC_STR}")
if [ "x${SRC_ZZ}" != "xNULL" ]; then
	SRC_ZZ=${SRC_ZZ:0:-1}
else
	SRC_ZZ="default"
	if [ ! -d storehouse/${SRC_ZZ}/step/${SRC_STEPNAME} ]; then
		SRC_ZZ="template"
	fi
fi


DEST_ZZ=$(get_string_zz "${1}")
if [ "x${DEST_ZZ}" != "xNULL" ]; then
	DEST_ZZ=${DEST_ZZ:0:-1}
else
	DEST_ZZ="default"
fi
DEST_STEPNAME=$(get_string_stepname "${1}")
if [ "x${DEST_STEPNAME}" == "x" ]; then
	echo "由于给定的目的信息中无法判别出步骤名，无法继续！"
	exit 2
fi

if [ ${TEST_MODE} == 1 ]; then
	echo "复制源信息:"
	echo "种子库名: " ${SRC_ZZ}
	echo "步骤名: " ${SRC_STEPNAME}
	echo ""
	echo "复制目的信息:"
	echo "种子库名: " ${DEST_ZZ}
	echo "步骤名: " ${DEST_STEPNAME}
	exit 0
fi

SRC_DIR="${SRC_ZZ}/step/${SRC_STEPNAME}/"
ENV_SRC_DIR=${SRC_ZZ}/env/${SRC_STEPNAME}/
MODE_SRC_DIR=${SRC_ZZ}/mode/${SRC_STEPNAME}/


DEST_DIR="${DEST_ZZ}/step/${DEST_STEPNAME}/"
ENV_DEST_DIR=${DEST_ZZ}/env/${DEST_STEPNAME}/
MODE_DEST_DIR=${DEST_ZZ}/mode/${DEST_STEPNAME}/

echo " storehouse/${SRC_DIR} --> storehouse/${DEST_DIR}"
echo " storehouse/${ENV_SRC_DIR} --> storehouse/${ENV_DEST_DIR}"
echo " storehouse/${MODE_SRC_DIR} --> storehouse/${MODE_DEST_DIR}"

if [ ! -d storehouse/${SRC_DIR} ]; then
	echo "storehouse/${SRC_DIR} 目录不存在，无法继续，请检查。"
	exit 3
fi

if [ ! -d storehouse/${ENV_SRC_DIR} ]; then
	echo "storehouse/${ENV_SRC_DIR} 目录不存在，无法继续，请检查。"
	exit 3
fi

if [ -d storehouse/${MODE_DEST_DIR} ]; then
	echo "storehouse/${MODE_DEST_DIR} 目录已存在，无法继续，请使用-f参数强制覆盖数据。"
	exit 5
fi

if [ ! -d ${DEST_ZZ}/env ]; then
	echo "发现指定的 ${DEST_ZZ} 是一个不存在的目录，当前的创建过程将复制一些必要的文件。"
fi

if [ ${CREATE_MODE} == 1 ]; then
	if [ ! -d ${DEST_ZZ}/env ]; then
		mkdir -pv ${DEST_ZZ}/env
		cp -av ${SRC_ZZ}/env/common ${DEST_ZZ}/env/
	fi
	echo "开始创建和复制文件..."
	mkdir -pv storehouse/${DEST_DIR} storehouse/${ENV_DEST_DIR} storehouse/${MODE_DEST_DIR}
	cp -av storehouse/${MODE_SRC_DIR}/*.mode storehouse/${MODE_DEST_DIR}/
	cp -av storehouse/${ENV_SRC_DIR}/common storehouse/${ENV_DEST_DIR}/
	if [ -d storehouse/${ENV_SRC_DIR}/arch ]; then
		cp -av storehouse/${ENV_SRC_DIR}/arch storehouse/${ENV_DEST_DIR}/
	fi
	touch storehouse/${DEST_DIR}/default.step
	echo "完成！"
else
	echo "请使用-c参数进行创建过程。"
fi

exit 0
