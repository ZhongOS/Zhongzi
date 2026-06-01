#!/bin/bash -e

source environment/functions

declare CUSTOM_STEP_NAME="default"

declare DISTRO_ARCH=""
declare FORCE_OVERWRITE=0
while getopts 'a:S:h' OPT; do
    case $OPT in
	a)
	    DISTRO_ARCH=$OPTARG
	    ;;
	S)
	    CUSTOM_STEP_NAME=$OPTARG
	    ;;
#         f)
#             FORCE_OVERWRITE=1
#             ;;
	h|?)
            echo "创建和初始化指定名称的系统目录。"
	    echo "$0 [-a <架构名称, 如loongarch64>] [-S <仓库中使用的起始步骤文件名，如 default>] <发性版名称> <使用的仓库名称>"
	    echo "参数："
	    echo "	a <架构名>: 设置创建发行版的架构名称，如 loongarch64 、loongarch32 。"
	    echo "	S <起始步骤文件名称>: 设置从哪个步骤文件开始进行制作，不指定该参数将指定为 default(.step) 文件。"
# 	    echo "	f : 强制更新那些指定了AUTO_LOCK（自动锁）的步骤。"
	    exit 0
	    ;;
    esac
done
shift $(($OPTIND - 1))

if [ "x${1}" == "x" ]; then
	echo "必须指定一个发行版名称。"
	exit 1
fi

if [ "x${2}" == "x" ]; then
	echo "必须指定一个仓库名称。"
	echo "当前可用的仓库名称列表："
	for storehouse_list_i in $(find storehouse -maxdepth 1 -type d | awk -F"/" '{ print $2 }' | grep -v -e "^\$" -e "^template\$")
	do
		echo "    ${storehouse_list_i}"
	done
	exit 2
fi

DISTRO_NAME=${1}
DISTRO_STOREHOUSE=${2}
DISTRO_DIR="${DISTRO_NAME}/${DISTRO_ARCH}"

if [ ! -d "storehouse/${2}" ]; then
	echo "没有 ${2} 仓库名称对应的目录，请检查指定名称或 storehouse 目录中的仓库目录是否匹配。"
	echo "当前可用的仓库名称列表："
	for storehouse_list_i in $(find storehouse -maxdepth 1 -type d | awk -F"/" '{ print $2 }' | grep -v -e "^\$" -e "^template\$")
	do
		echo "    ${storehouse_list_i}"
	done
	exit 2
	exit 98
fi

if [ -d "distro/${DISTRO_DIR}" ]; then
	echo "${DISTRO_DIR} 该发行版目录已存在，不能继续初始化。"
	exit 99
fi

if [ "x${DISTRO_ARCH}" == "x" ] || [ ! -d "distro/${DISTRO_DIR}" ]; then

	ZZ_NAME=default
	if [ "x${CUSTOM_STEP_NAME}" != "x" ]; then
		ZZ_NAME=${CUSTOM_STEP_NAME}
	fi

	echo -n "创建 ${DISTRO_NAME} 目录..."
	git init "distro/${DISTRO_NAME}"
# 		git submodule add https://github.com/Zhongzi/gongju.git distro/${DISTRO_NAME}/gongju
	cp -a gongju ./distro/${DISTRO_NAME}/

	echo "${DISTRO_NAME}:${DISTRO_STOREHOUSE}:${ZZ_NAME}" >> default_store
	
	echo "完成。"
	if [ "x${DISTRO_ARCH}" == "x" ]; then
		exit 0
	fi
fi

mkdir -pv ./distro/${DISTRO_DIR}/{scripts,env}
mkdir -pv ./distro/${DISTRO_DIR}/logs
mkdir -pv ./distro/${DISTRO_DIR}/sources/{url,downloads,files}

ln -sv ../gongju/tools ./distro/${DISTRO_DIR}/
ln -sv ../gongju/bin/build.sh ./distro/${DISTRO_DIR}/
ln -sv ../gongju/bin/strip_os.sh ./distro/${DISTRO_DIR}/
ln -sv ../gongju/bin/install_os_run.sh ./distro/${DISTRO_DIR}/
ln -sv ../gongju/bin/pack_os.sh ./distro/${DISTRO_DIR}/

echo "" > ./distro/${DISTRO_DIR}/step

ln -sv ../../gongju/env/function.sh ./distro/${DISTRO_DIR}/env/
ln -sv ../../gongju/env/arch.data ./distro/${DISTRO_DIR}/env/
ln -sv ../../gongju/env/data ./distro/${DISTRO_DIR}/env/

if [ ! -f ./distro/${DISTRO_DIR}/env/distro.info ]; then
	echo "DISTRO_ARCH=${DISTRO_ARCH}" > ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_ARCH_NAME=${DISTRO_ARCH}" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_NAME=${DISTRO_NAME}" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_VERSION=1.0" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_ARCHIVE_MODE=squashfs" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_DEFAULT_USER=$(echo ${DISTRO_NAME} | sed -e "s@64@@g" -e "s@32@@g")" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "DISTRO_DEFAULT_USER_PASSWD=${DISTRO_NAME}" >> ./distro/${DISTRO_DIR}/env/distro.info
	echo "export DISTRO_ARCH DISTRO_ARCH_NAME DISTRO_NAME DISTRO_VERSION DISTRO_ARCHIVE_MODE DISTRO_DEFAULT_USER" >> ./distro/${DISTRO_DIR}/env/distro.info
fi
if [ ! -f ./distro/${DISTRO_DIR}/env/opt.info ]; then
	echo "# opt=+g_opt" > ./distro/${DISTRO_DIR}/env/opt.info
	echo "# opt=+f_opt" >> ./distro/${DISTRO_DIR}/env/opt.info
fi

echo "${DISTRO_NAME} 的 ${DISTRO_ARCH} 架构目录创建完成。"



