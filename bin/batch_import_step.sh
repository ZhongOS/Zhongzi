#!/bin/bash -e

declare TARGET_ARCH=""

while getopts 'a:' OPT; do
    case $OPT in
        a)
            TARGET_ARCH=$OPTARG
            ;;
        ?)
            echo "用法: `basename $0` "
	    exit 1
    esac
done
shift $(($OPTIND - 1))


if [ x$1 == x ]; then
    echo "需要输入导入步骤所属步骤组名"
    exit 3
fi

if [ x$2 == x ]; then
    echo "需要输入步骤模式"
    exit 3
fi

if [ "x$2" != "xgnu" ] && [ "x$2" != "xgnu_gi" ] && [ "x$2" != "xmeson" ] && [ "x$2" != "xcmake" ] && [ "x$2" != "xgnu_build" ] && [ "x$2" != "xmeson_cross" ] && [ "x$2" != "xmeson_cross_bool" ] && [ "x$2" != "xpython" ] && [ "x$2" != "xperl" ]; then
    echo "导入方式仅支持gnu、gnu_gi、meson、cmake、gnu_build、meson_cross、meson_cross_bool、python、perl模式！"
    exit 2
fi

if [ x"$3" == x ]; then
    echo "请输入需要导入的步骤"
    exit 3
fi

ZZ_NAME="default"

DEST_DIR="storehouse/${ZZ_NAME}/step/${1}/"

if [ "x${TARGET_ARCH}" != "x" ]; then
        DEST_DIR="storehouse/${ZZ_NAME}/step/${1}/arch/${TARGET_ARCH}/"
else
        DEST_DIR="storehouse/${ZZ_NAME}/step/${1}/"
fi

for package in ${3}
do
	if [ -d ${DEST_DIR}/${package} ]; then
		echo "${package} 已经存在，跳过！"
		continue;
	fi
	echo -n "正在${TARGET_ARCH}导入 ${package} 以 ${2}的制作模式加入到 ${1} 步骤组中..."
	bin/step_edit.sh -k ${package} ${1} ${2}
	bin/step_insert_step.sh ${package} ${1}
	echo "完成。"
done
