#!/bin/bash

declare TARGET_ARCH=""
declare SKIP_EDIT=0
declare ZZ_NAME=""

while getopts 'ka:z:h' OPT; do
    case $OPT in
        a)
            TARGET_ARCH=$OPTARG
            ;;
        z)
            ZZ_NAME=$OPTARG
            ;;
	k)
	    SKIP_EDIT=1
	    ;;
        h)
            echo "用法: `basename $0` "
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
        echo "必须指定一个包名字。"
        exit 1
fi

if [ "x${2}" == "x" ]; then
        echo "必须指定一个所属步骤路径的名字。"
        exit 1
fi

if [ "x${3}" == "x" ]; then
        echo "必须指定一个制作模式。"
        exit 2
fi

BUILD_MODE=custom
if [ "x${ZZ_NAME}" == "x" ]; then
	ZZ_NAME=default
fi

case "x${3}" in
"xgnu"|"xgnu_build"|"xgnu_gi"|"xperl"|"xpython"|"xpip"|"xmeson"|"xmeson_cross"|"xmeson_cross_bool"|"xcmake")
	BUILD_MODE=${3}
	;;
*)
	echo "模式无法识别，按照custom方式设置。"
	BUILD_MODE=custom
	;;
esac

DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/${1}/"

if [ "x${TARGET_ARCH}" != "x" ]; then
        DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/arch/${TARGET_ARCH}/${1}"
else
        DEST_DIR="storehouse/${ZZ_NAME}/step/${2}/${1}/"
fi

mkdir -p ${DEST_DIR}
# storehouse/${ZZ_NAME}/step/${2}/${1}/
echo "PACKAGE=${1}
BUILD_MODE=${BUILD_MODE}" > ${DEST_DIR}/${1}

if [ "x${BUILD_MODE}" == "xcustom" ]; then
	if [ ! -f ${DEST_DIR}/${1}.build ]; then
		if [ -f storehouse/${ZZ_NAME}/step/${2}/default.template ]; then
	                cp storehouse/${ZZ_NAME}/step/${2}/default.template ${DEST_DIR}/${1}.build
		else
			echo "<<<TAR_UNCOMPRESS>>>

<<<CLEAR_DIR>>>" > ${DEST_DIR}/${1}.build
		fi
	fi
fi
if [ "x${SKIP_EDIT}" == "x0" ]; then
	vi ${DEST_DIR}/${1}.build
	if [ -f ${DEST_DIR}/${1}.build ]; then
		sed -i "s@/opt/mylaos/sysroot@\${SYSROOT_DIR}@g" ${DEST_DIR}/${1}.build
		sed -i "s@\${SYSDIR}/sysroot@\${SYSROOT_DIR}@g" ${DEST_DIR}/${1}.build
		sed -i "s@\${SYSDIR}/cross-tools@\${CROSSTOOLS_DIR}@g" ${DEST_DIR}/${1}.build
	fi
fi
