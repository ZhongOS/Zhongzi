#!/bin/bash -e

if [ "x${1}" == "x" ]; then
	echo "必须指定一个软件包名"
	exit 1
fi

if [ "x${2}" == "x" ]; then
	echo "必须指定软件包的版本"
	exit 2
fi

if [ "x${3}" == "x" ]; then
	echo "必须指定一个目标架构"
	exit 3
fi

if [ ! -f sources/${1}/${2}/info ]; then
	echo "没有找到 sources/${1}/${2}/info 文件。"
	exit 4
fi

if [ ! -d sources/${1}/arch/${3}/${2} ]; then
	mkdir -p sources/${1}/arch/${3}/${2}
fi

echo "从 sources/${1}/${2}/ 复制info文件到 sources/${1}/arch/${3}/${2}/ ..."
cp -a sources/${1}/${2}/info sources/${1}/arch/${3}/${2}/
