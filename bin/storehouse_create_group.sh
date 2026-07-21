#!/bin/bash

declare TARGET_ARCH=""
declare MOVE_OPT=0
declare INFO_MODE=0
declare CREATE_MODE=0
declare FORCE_CREATE=0
declare SRC_STR=""

while getopts 'cis:h' OPT; do
    case $OPT in
	c)
	    CREATE_MODE=1
	    ;;
	i)
	    INFO_MODE=1
	    ;;
        s)
            SRC_STR=$OPTARG
            ;;
        h|*)
	    echo "功能: 创建种子库及种子组"
            echo "用法: `basename $0` [-c] [-i] [-s SRC_STR] DEST_STR"
	    echo "c: 进行种子库及种子组的创建，必须明确指定该参数才会真实创建。"
	    echo "i: 只显示创建的方式，并不进行真实的创建。"
# 	    echo "s <参考步骤组>: 该参数需要指定一个步骤组的名称，新创建的步骤组将采用指定的步骤组作为参考进行新的步骤组的创建。如果该参数不指定将使用default/template/target_base作为新步骤组的参考。"
	    echo "s <参考种子组>: 该参数需要指定一个种子组的名称, 格式 <zz_name>%<stepname>，新创建的种子组将采用指定的种子组作为参考进行新的种子组的创建。如果该参数不指定将使用 template%target-system 作为新种子组的参考。"
	    exit 0
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
        echo "必须指定一个目标仓库名及种子组名字。格式: <zz_name>%<stepname>，例如: default%target_base"
        exit 1
fi

if [ "x${2}" != "x" ]; then
	echo "请使用 -s 指定参考种子组的名称。<zz_name>%<stepname>，例如: template%target_base"
	exit 2
fi

function get_string_zz
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}%" || echo "NULL"
}

function get_string_stepname
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}" | sed '1d' |tail -n1
}

# loongarch64:default%target_base/package



DEST_ZZ=$(get_string_zz "${1}")
if [ "x${DEST_ZZ}" != "xNULL" ]; then
	DEST_ZZ=${DEST_ZZ:0:-1}
else
	DEST_ZZ="default"
fi
DEST_GROUPNAME=$(get_string_stepname "${1}")
if [ "x${DEST_GROUPNAME}" == "x" ]; then
	echo "由于给定的目的信息中无法判别出种子组名，无法继续！"
	exit 2
fi

if [ "x${SRC_STR}" == "x" ]; then
# 	SRC_STR="template%target-system"
	SRC_STR="template%"
fi

SRC_ZZ=$(get_string_zz "${SRC_STR}")
if [ "x${SRC_ZZ}" != "xNULL" ]; then
	SRC_ZZ=${SRC_ZZ:0:-1}
else
	SRC_ZZ="default"
	if [ ! -d storehouse/${SRC_ZZ}/step/${SRC_GROUPNAME} ]; then
		SRC_ZZ="template"
	fi
fi
SRC_GROUPNAME=$(get_string_stepname "${SRC_STR}")
if [ "x${SRC_GROUPNAME}" == "x" ]; then
	if [ -d storehouse/${SRC_ZZ}/step/${DEST_GROUPNAME} ]; then
		SRC_GROUPNAME=${DEST_GROUPNAME}
	else
		SRC_GROUPNAME=target-system
	fi
	if [ ! -d storehouse/${SRC_ZZ}/step/${SRC_GROUPNAME} ]; then
		echo "由于给定的复制源信息中无法判别出种子组名，无法继续！"
		exit 2
	fi
fi


if [ ${INFO_MODE} == 1 ]; then
	echo "复制源信息:"
	echo "种子库名: " ${SRC_ZZ}
	echo "种子组: " ${SRC_GROUPNAME}
	echo ""
	echo "复制目的信息:"
	echo "种子库名: " ${DEST_ZZ}
	echo "种子组: " ${DEST_GROUPNAME}
	exit 0
fi

SRC_DIR="${SRC_ZZ}/step/${SRC_GROUPNAME}/"
ENV_SRC_DIR=${SRC_ZZ}/env/${SRC_GROUPNAME}/
MODE_SRC_DIR=${SRC_ZZ}/mode/${SRC_GROUPNAME}/


DEST_DIR="${DEST_ZZ}/step/${DEST_GROUPNAME}/"
ENV_DEST_DIR=${DEST_ZZ}/env/${DEST_GROUPNAME}/
MODE_DEST_DIR=${DEST_ZZ}/mode/${DEST_GROUPNAME}/

echo "以下是复制的内容:"
echo "	storehouse/${SRC_DIR} --> storehouse/${DEST_DIR}"
echo "	storehouse/${MODE_SRC_DIR}*.mode --> storehouse/${MODE_DEST_DIR}"
echo "	storehouse/${ENV_SRC_DIR} --> storehouse/${ENV_DEST_DIR}"
if [ -d storehouse/${ENV_SRC_DIR}/arch ]; then
	echo "	storehouse/${ENV_SRC_DIR}arch --> storehouse/${ENV_DEST_DIR}"
fi

if [ ! -d storehouse/${SRC_DIR} ]; then
	echo "storehouse/${SRC_DIR} 目录不存在，无法继续，请检查。"
	exit 3
fi

if [ ! -d storehouse/${ENV_SRC_DIR} ]; then
	echo "storehouse/${ENV_SRC_DIR} 目录不存在，无法继续，请检查。"
	exit 3
fi

if [ ! -d storehouse/${MODE_SRC_DIR} ]; then
	echo "storehouse/${MODE_SRC_DIR} 目录不存在，无法继续，请检查。"
	exit 3
fi

if [ -d storehouse/${ENV_DEST_DIR} ]; then
	echo "${DEST_GROUPNAME} 组已存在，不能重复创建。"
	exit 5
fi

if [ ! -d storehouse/${DEST_ZZ}/env ]; then
	echo "本次是 ${DEST_ZZ} 首次创建，当前的创建过程将复制一些共用文件。"
	echo "	storehouse/${SRC_ZZ}/env/common{,_env} --> storehouse/${DEST_ZZ}/env/common"
fi

if [ ${CREATE_MODE} == 1 ]; then
	echo "开始创建和复制文件..."
	if [ ! -d storehouse/${DEST_ZZ}/env ]; then
		# 首次创建，复制共用文件。
		mkdir -pv storehouse/${DEST_ZZ}/env
		cp -av storehouse/${SRC_ZZ}/env/common{,_env} storehouse/${DEST_ZZ}/env/
		mkdir -pv storehouse/${DEST_ZZ}/step
		touch storehouse/${DEST_ZZ}/step/default.step
	fi
	# 创建主体目录
	mkdir -pv storehouse/${DEST_DIR} storehouse/${ENV_DEST_DIR} storehouse/${MODE_DEST_DIR}
	# 复制模式文件
	cp -av storehouse/${MODE_SRC_DIR}/*.mode storehouse/${MODE_DEST_DIR}/
	# 复制环境文件
	cp -av storehouse/${ENV_SRC_DIR}/common storehouse/${ENV_DEST_DIR}/
	# 复制架构专属环境文件。
	if [ -d storehouse/${ENV_SRC_DIR}/arch ]; then
		cp -av storehouse/${ENV_SRC_DIR}/arch storehouse/${ENV_DEST_DIR}/
	fi
	# 生成默认步骤文件。
	touch storehouse/${DEST_DIR}/default.step
	echo "完成！"
	exit 0
else
	echo "请使用 -c 参数进行创建过程。"
	exit 99
fi

