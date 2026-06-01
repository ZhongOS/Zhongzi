#!/bin/bash -e

if [ "x${1}" == "x" ]; then
	echo "请输入一个包名称"
fi

if [ -f package_version/${1}.version ]; then
	echo "主版本：$(cat package_version/${1}.version)"
	echo "        URL：$(cat package_version/${1}.url)"
fi

if [ -f package_version/default/${1}.version ]; then
	echo "默认版本：$(cat package_version/default/${1}.version)"
	echo "          URL：$(cat package_version/default/${1}.url)"
fi

for i in $(ls package_version/arch)
do
	if [ -f package_version/arch/${i}/${1}.version ]; then
		echo "$(basename ${i})架构的版本：$(cat package_version/arch/${i}/${1}.version)"
		echo "               URL：$(cat package_version/arch/${i}/${1}.url)"
	fi
done
