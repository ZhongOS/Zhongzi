#!/bin/bash -e 

declare TARGET_ARCH=""
declare MOVE_OPT=0
declare TEST_MODE=0
declare FORCE_MODE=0

while getopts 'tmfa:' OPT; do
    case $OPT in
	t)
	    TEST_MODE=1
	    ;;
	m)
	    MOVE_OPT=1
	    ;;
	f)
	    FORCE_MODE=1
	    ;;
        a)
            TARGET_ARCH=$OPTARG
            ;;
        ?)
            echo "用法: `basename $0` [<arch>:][<zz_name>%]<stepname>/<pkgname> [<arch>:][<zz_name>%]<stepname>/[<pkgname>] "
	    exit 1
	    ;;
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
        echo "必须指定一个源步骤路径和包名字。<arch>:<zz_name>%<stepname>/<pkgname>"
        exit 1
fi

if [ "x${2}" == "x" ]; then
        echo "必须指定一个目的步骤路径和包名字。"
        exit 1
fi

function get_string_arch
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}:" || echo "NULL"
}


function get_string_zz
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}%" || echo "NULL"
}

function get_string_stepname
{
	echo "${1}" | grep -o "[^:#%/]\{0,\}/" || echo "NULL"
}

function get_string_pkgname
{
	echo "${1}" | grep -o "/[^:#%/]\{0,\}" || echo "NULL"
}

# loongarch64:default%target_base/package


SRC_ARCH=$(get_string_arch "${1}")
if [ "x${SRC_ARCH}" != "xNULL" ]; then
	SRC_ARCH=${SRC_ARCH:0:-1}
fi
if [ "x${SRC_ARCH}" == "x" ] || [ "x${SRC_ARCH}" == "xNULL" ]; then
	SRC_ARCH=""
fi
SRC_ZZ=$(get_string_zz "${1}")
if [ "x${SRC_ZZ}" != "xNULL" ]; then
	SRC_ZZ=${SRC_ZZ:0:-1}
else
	SRC_ZZ="default"
fi
SRC_STEPNAME=$(get_string_stepname "${1}")
if [ "x${SRC_STEPNAME}" != "xNULL" ]; then
	SRC_STEPNAME=${SRC_STEPNAME:0:-1}
fi
if [ "x${SRC_STEPNAME}" == "x" ] || [ "x${SRC_STEPNAME}" == "xNULL" ]; then
	echo "由于给定的复制源信息中无法判别出步骤名，无法继续！"
	exit 2
fi
SRC_PKGNAME=$(get_string_pkgname "${1}")
if [ "x${SRC_PKGNAME}" != "xNULL" ]; then
	SRC_PKGNAME=${SRC_PKGNAME:1}
fi
if [ "x${SRC_PKGNAME}" == "x" ] || [ "x${SRC_PKGNAME}" == "xNULL" ]; then
	echo "由于给定的复制源信息中无法判别出软件包名，无法继续！"
	exit 2
fi

DEST_ARCH=$(get_string_arch "${2}")
if [ "x${DEST_ARCH}" != "xNULL" ]; then
	DEST_ARCH=${DEST_ARCH:0:-1}
fi
if [ "x${DEST_ARCH}" == "x" ] || [ "x${DEST_ARCH}" == "xNULL" ]; then
	DEST_ARCH=""
fi
DEST_ZZ=$(get_string_zz "${2}")
if [ "x${DEST_ZZ}" != "xNULL" ]; then
	DEST_ZZ=${DEST_ZZ:0:-1}
else
	DEST_ZZ="default"
fi
DEST_STEPNAME=$(get_string_stepname "${2}")
if [ "x${DEST_STEPNAME}" != "xNULL" ]; then
	DEST_STEPNAME=${DEST_STEPNAME:0:-1}
fi
if [ "x${DEST_STEPNAME}" == "x" ] || [ "x${DEST_STEPNAME}" == "xNULL" ]; then
	echo "由于给定的目的信息中无法判别出步骤名，无法继续！"
	exit 2
fi
DEST_PKGNAME=$(get_string_pkgname "${2}")
if [ "x${DEST_PKGNAME}" != "xNULL" ]; then
	DEST_PKGNAME=${DEST_PKGNAME:1}
fi
if [ "x${DEST_PKGNAME}" == "x" ] || [ "x${DEST_PKGNAME}" == "xNULL" ]; then
	echo "警告：由于给定的目的信息中无法判别出软件包名，将使用源信息中的软件名！"
	DEST_PKGNAME=${SRC_PKGNAME}
fi

if [ ${TEST_MODE} == 1 ]; then
	echo "复制源信息:"
	echo "架构名: " ${SRC_ARCH}
	echo "种子库名: " ${SRC_ZZ}
	echo "步骤名: " ${SRC_STEPNAME}
	echo "软件包名:" ${SRC_PKGNAME}
	echo ""
	echo "复制目的信息:"
	echo "架构名: " ${DEST_ARCH}
	echo "种子库名: " ${DEST_ZZ}
	echo "步骤名: " ${DEST_STEPNAME}
	echo "软件包名:" ${DEST_PKGNAME}
fi

if [ "x${SRC_ARCH}" == "x" ]; then
	SRC_DIR="${SRC_ZZ}/step/${SRC_STEPNAME}/${SRC_PKGNAME}"
else
	SRC_DIR="${SRC_ZZ}/step/${SRC_STEPNAME}/arch/${SRC_ARCH}/${SRC_PKGNAME}"
fi


if [ "x${DEST_ARCH}" == "x" ]; then
	DEST_DIR="${DEST_ZZ}/step/${DEST_STEPNAME}/${DEST_PKGNAME}"
else
	DEST_DIR="${DEST_ZZ}/step/${DEST_STEPNAME}/arch/${DEST_ARCH}/${DEST_PKGNAME}"
fi

echo " storehouse/${SRC_DIR} --> storehouse/${DEST_DIR}"

if [ ! -d storehouse/${SRC_DIR} ]; then
	echo "复制源目录 storehouse/${SRC_DIR} 不存在，无法继续！"
	exit 3
fi

if [ ! -d storehouse/${DEST_ZZ}/step/${DEST_STEPNAME} ]; then
	echo "复制目的步骤组 storehouse/${DEST_ZZ}/step/${DEST_STEPNAME} 不存在，无法继续！"
	exit 3
fi

if [ -d storehouse/${DEST_DIR} ]; then
	if [ "x${FORCE_MODE}" == "x0" ]; then
		echo "目标软件名 storehouse/${DEST_DIR} 已经存在，请检查是否需要覆盖，如需要覆盖，请使用参数-f"
		exit 4
	else
		rm -f storehouse/${DEST_DIR}/${DEST_PKGNAME}{,.build,.patch}
		rmdir storehouse/${DEST_DIR}
	fi
fi

mkdir -p $(dirname storehouse/${DEST_DIR})

if [ "x${SRC_PKGNAME}" == "x${DEST_PKGNAME}" ]; then
	if [ ${TEST_MODE} == 1 ]; then
		echo "cp -a storehouse/${SRC_DIR} storehouse/${DEST_DIR}"
	else
		cp -a storehouse/${SRC_DIR} storehouse/${DEST_DIR}
	fi
else
	if [ ${TEST_MODE} == 1 ]; then
		echo "cp -a storehouse/${SRC_DIR} storehouse/${DEST_DIR}"
		for i in $(ls storehouse/${SRC_DIR}/${SRC_PKGNAME}*)
		do
			echo "cp -a  ${i} storehouse/${DEST_DIR}/"$(basename ${i} | sed -e "s@^${SRC_PKGNAME}\$@${DEST_PKGNAME}@g" -e "s@^${SRC_PKGNAME}\.@${DEST_PKGNAME}\.@g") | sed "s@storehouse/${SRC_DIR}@storehouse/${DEST_DIR}@g"
		done
	else
		cp -a storehouse/${SRC_DIR} storehouse/${DEST_DIR}
		for i in $(ls storehouse/${DEST_DIR}/${SRC_PKGNAME}*)
		do
			mv ${i} storehouse/${DEST_DIR}/$(basename ${i} | sed -e "s@^${SRC_PKGNAME}\$@${DEST_PKGNAME}@g" -e "s@^${SRC_PKGNAME}\.@${DEST_PKGNAME}\.@g")
		done
		sed -i "/^PACKAGE=/s@=${SRC_PKGNAME}\$@=${DEST_PKGNAME}@g" storehouse/${DEST_DIR}/${DEST_PKGNAME}
	fi
fi
exit 0
