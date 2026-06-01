#!/bin/bash -e

# ./set_package_version.sh [-t] [-f] [-a 架构名称] 软件包名称 软件版本号 软件包文件路径

declare TEST_SHOW=0
declare TARGET_ARCH=""
declare WRITE_FORCE=0
declare IS_GIT=0
declare DEFAULT_STR=""
declare CREATE_ONLY=0
declare CUSTOM_VERSIONS_NAME="Default"

while getopts 'htfgdN:a:n' OPT; do
    case $OPT in
        f)
            WRITE_FORCE=1
            ;;
        t)
            TEST_SHOW=1
            ;;
	a)
	    TARGET_ARCH=$OPTARG
	    ;;
	g)
            IS_GIT=1
	    ;;
	d)
	    DEFAULT_STR="-default"
	    ;;
	N)
	    CUSTOM_VERSIONS_NAME=$OPTARG
	    ;;
	n)
	    CREATE_ONLY=1
	    ;;
        h|?)
            echo "用法: `basename $0` [-g] [-t] [-f] [-a 架构名称] [-d] 软件包名称 软件版本号 软件包文件路径 "
            echo "参数： "
            echo "	g: 指定当前创建的版本使用的是一个git仓库地址。"
            echo "	t: 测试模式。"
            echo "	f: 强制写入package_version/软件包名称.version 文件。"
            echo "	a <架构名称>: 创建的.version文件将存放在以"arch/架构名"为名称的目录中。"
            echo "	d: 默认在版本后追加"-default"名称。"
	    echo "      N <软件版本组名称>: 设置存放到哪个软件版本组名称的目录中，指定的名称为 package_version 目录中的目录名，不指定该参数将使用 package_version/Default 目录进行存放。"
            echo "	n: 不写入package_version/软件包名称.version 文件，仅创建该版本的信息。"
	    exit -1
	    ;;
    esac
done
shift $(($OPTIND - 1))


if [ "x${1}" == "x" ]; then
	echo "必须指定一个软件包名称"
	exit 1
fi

if [ "x${2}" == "x" ]; then
	echo "必须指定一个软件包的版本号"
	exit 2
fi

declare PACKAGE_NAME="${1}"
declare PACKAGE_VERSION="${2}"
declare DEST_DIR=""

VERSIONS_NAME=Default
if [ "x${CUSTOM_VERSIONS_NAME}" != "x" ]; then
	VERSIONS_NAME="${CUSTOM_VERSIONS_NAME}"
fi

#if [ "x${TEST_SHOW}" == "x1" ]; then
#        echo "测试模式。"
#        echo "${PACKAGE_NAME}"
#        echo "${PACKAGE_VERSION}"
#fi

if [ "x${TARGET_ARCH}" != "x" ]; then
	DEST_DIR="package_version/${VERSIONS_NAME}/arch/${TARGET_ARCH}/"
else
	DEST_DIR="package_version/${VERSIONS_NAME}/Settings/"
fi

if [ "x${TARGET_ARCH}" != "x" ]; then
	SOURCES_DIR="sources/${PACKAGE_NAME}/arch/${TARGET_ARCH}/${PACKAGE_VERSION}/"
else
#	SOURCES_DIR="sources/${PACKAGE_NAME}/${PACKAGE_VERSION}-default/"
	SOURCES_DIR="sources/${PACKAGE_NAME}/${PACKAGE_VERSION}${DEFAULT_STR}/"
fi

if [ ! -f ${SOURCES_DIR}/info ]; then
	if [ "x${3}" == "x" ]; then
		echo "必须指定一个软件包文件的下载路径。"
		exit 3
	fi
fi
declare PACKAGE_URL="${3}"


if [ "x${WRITE_FORCE}" == "x0" ] && [ "x${CREATE_ONLY}" == "x0" ]; then
	if [ -f ${DEST_DIR}/${PACKAGE_NAME}.version ]; then
                echo "${DEST_DIR}/${PACKAGE_NAME}.version 文件已经存在，如要强制写入，请加入-f参数。"
                exit 5
	fi
fi
if [ "x${WRITE_FORCE}" == "x0" ]; then
	if [ -f ${SOURCES_DIR}/info ] && [ "x${PACKAGE_URL}" != "x" ]; then
		echo "${SOURCES_DIR}/info 文件已经存在，如果要强制写入，请加入-f参数，也可以通过不指定“软件包文件路径”来避免info文件被覆盖。"
		exit 5
	fi
fi

if [ -f ${SOURCES_DIR}/info ] && [ "x${PACKAGE_URL}" == "x" ]; then
	PACKAGE_URL=$(cat ${SOURCES_DIR}/info | grep "URL=" | awk -F'URL=' ' { print $2 }')
fi

declare PACKAGE_FILE=$(echo "${PACKAGE_URL}" | awk -F'/' '{ print $NF }')
if [ "x${PACKAGE_URL}" == "x${PACKAGE_FILE}" ]; then
	if [ "x${PACKAGE_URL}" == "xNULL" ]; then
		PACKAGE_URL="NULL"
	else
		PACKAGE_URL="file://${PACKAGE_FILE}"
	fi
fi

declare HEAD_STR=$(echo "${PACKAGE_URL}"  | awk -F'/' '{ print $1 }')
case "x${HEAD_STR}" in
	xgit:)
		IS_GIT=1
		;;
	*)
		;;
esac


if [ "x${TEST_SHOW}" == "x1" ]; then
        echo "测试模式。"
        echo "${PACKAGE_NAME}"
        echo "${PACKAGE_VERSION}"
        echo "${PACKAGE_URL}"
        echo "${PACKAGE_FILE}"
        echo "${DEST_DIR}"
        echo "${SOURCES_DIR}"
	if [ "x${3}" == "x" ]; then
		echo "不写入 ${SOURCES_DIR}/info 文件。"
	fi
	exit 0
fi

if [ "x${CREATE_ONLY}" == "x0" ]; then
	echo ${PACKAGE_URL} > ${DEST_DIR}/${PACKAGE_NAME}.url
	if [ "x${TARGET_ARCH}" != "x" ]; then
		echo -n "${PACKAGE_VERSION}" > ${DEST_DIR}/${PACKAGE_NAME}.version
	else
#		echo -n "${PACKAGE_VERSION}-default" > ${DEST_DIR}/${PACKAGE_NAME}.version
		echo -n "${PACKAGE_VERSION}${DEFAULT_STR}" > ${DEST_DIR}/${PACKAGE_NAME}.version
	fi
fi

if [ "x${3}" != "x" ]; then
	mkdir -p ${SOURCES_DIR}
	echo "URL=${PACKAGE_URL}" > ${SOURCES_DIR}/info
	if [ "x${IS_GIT}" == "x0" ]; then
		echo "FILE=${PACKAGE_FILE}" >> ${SOURCES_DIR}/info
	else
		if [ "x${TARGET_ARCH}" != "x" ]; then
			echo "FILE=${PACKAGE_NAME}-${PACKAGE_VERSION}_git.tar.gz" >> ${SOURCES_DIR}/info
			echo "DIR=${PACKAGE_NAME}-${PACKAGE_VERSION}_git" >> ${SOURCES_DIR}/info
		else
#			echo "FILE=${PACKAGE_NAME}-${PACKAGE_VERSION}-default_git.tar.gz" >> ${SOURCES_DIR}/info
#			echo "DIR=${PACKAGE_NAME}-${PACKAGE_VERSION}-default_git" >> ${SOURCES_DIR}/info
			echo "FILE=${PACKAGE_NAME}-${PACKAGE_VERSION}${DEFAULT_STR}_git.tar.gz" >> ${SOURCES_DIR}/info
			echo "DIR=${PACKAGE_NAME}-${PACKAGE_VERSION}${DEFAULT_STR}_git" >> ${SOURCES_DIR}/info
		fi
		echo "你设置了一个git协议的获取地址，你可以通过设置 ${SOURCES_DIR}/info 文件来控制下载仓库中的分支及具体Commit，如果不指定将使用默认分支及最新的Commit提交。"
		if [ "x${PACKAGE_VERSION}" == "xgit" ]; then
			echo "PKG_FORMAT=" >> ${SOURCES_DIR}/info
			echo "GIT_BRANCH=" >> ${SOURCES_DIR}/info
		else
			echo "PKG_FORMAT=@${PACKAGE_VERSION}@" >> ${SOURCES_DIR}/info
			echo "GIT_BRANCH=@${PACKAGE_VERSION}@" >> ${SOURCES_DIR}/info
		fi
		echo "GIT_COMMIT=" >> ${SOURCES_DIR}/info
		echo "GIT_SUBMODULE=0" >> ${SOURCES_DIR}/info
		echo "GIT_UPDATE_MODE=手工" >> ${SOURCES_DIR}/info
		vi ${SOURCES_DIR}/info
	fi
fi


exit 0
