#!/bin/bash -e

source environment/functions

declare CUSTOM_STEP_STR=""
declare CUSTOM_STEP_NAME="default"
declare CUSTOM_VERSIONS_NAME="Default"
declare FORCE_OVERWRITE=0
while getopts 's:S:N:fh' OPT; do
    case $OPT in
        s)
            CUSTOM_STEP_STR=$OPTARG
            ;;
	S)
	    CUSTOM_STEP_NAME=$OPTARG
	    ;;
	N)
	    CUSTOM_VERSIONS_NAME=$OPTARG
	    ;;
        f)
            FORCE_OVERWRITE=1
            ;;
	h|?)
            echo "目标系统构建命令。"
	    echo "参数："
	    echo "	s <步骤组列表>: 设置更新步骤组内容的列表，多个组之间使用“,”进行分隔，若其中有个别指定组不存在则忽略进行存在指定组的更新，不指定该参数则将对全部组进行更新。"
	    echo "	S <起始步骤文件名称>: 设置从哪个步骤文件开始进行制作，不指定该参数将使用 default.step 开始制作。"
	    echo "	N <软件版本组名称>: 设置从哪个软件版本组名称的目录中获取软件版本号，指定的名称为 package_version 目录中的目录名，不指定该参数将使用 package_version/Default 目录中的版本号进行配置。"
	    echo "	f : 强制更新那些指定了AUTO_LOCK（自动锁）的步骤。"
	    exit 0
	    ;;
    esac
done
shift $(($OPTIND - 1))

if [ "x${1}" == "x" ]; then
	echo "必须指定一个名字。"
	exit 1
fi

if [ "x${2}" == "x" ]; then
	echo "必须指定一个架构。"
	exit 2
fi

DISTRO_NAME=${1}
DISTRO_ARCH=${2}
DISTRO_DIR=distro/${DISTRO_NAME}/${DISTRO_ARCH}

if [ ! -d distro/${DISTRO_NAME}/${DISTRO_ARCH} ]; then
	echo "distro/${DISTRO_NAME}/${DISTRO_ARCH} 不存在，请使用 init_distro.sh 脚本进行初始化。"
	exit 99
fi

ZZ_NAME=default
VERSIONS_NAME=Default
if [ "x${CUSTOM_VERSIONS_NAME}" != "x" ]; then
	VERSIONS_NAME="${CUSTOM_VERSIONS_NAME}"
fi

GET_FULL_DISTRO_SET=""
GET_ZZ_NAME=""
GET_CUSTOM_STEP_NAME=""
if [ -f default_store ]; then
	GET_FULL_DISTRO_SET=$(cat default_store | grep "^${DISTRO_NAME}:")
	GET_ZZ_NAME=$(echo "${GET_FULL_DISTRO_SET}" | awk -F':' '{ print $2 }' | sed "s@[^?\|^[:alnum:]\|^\.\|^[:space:]\|^_\|^-]@@g")
	GET_CUSTOM_STEP_NAME=$(echo "${GET_FULL_DISTRO_SET}" | awk -F':' '{ print $3 }' | sed "s@[^?\|^[:alnum:]\|^\.\|^[:space:]\|^_\|^-]@@g")
fi
if [ "x${GET_ZZ_NAME}" == "xtemplate" ]; then
	echo "不能使用 template 作为仓库的名称，请检查 default_store 中对 ${DISTRO_NAME} 的设置。"
	exit 3
fi
if [ "x${GET_ZZ_NAME}" == "x" ]; then
	if [ "x${GET_FULL_DISTRO_SET}" == "x" ]; then
		echo "default_store 文件中没有 ${DISTRO_NAME} 设置的内容，将使用 default 进行目标系统的生成，并保存该设置。"
		echo "${DISTRO_NAME}:default:default" >> default_store
	eles
		echo "default_store 文件中定义了 ${DISTRO_NAME} ，但没有定义使用何种仓库名称进行目标系统的生成，将使用默认的 default 。"
	fi
else
	if [ -d storehouse/${GET_ZZ_NAME} ]; then
		ZZ_NAME=${GET_ZZ_NAME}
	else
		echo "default_store 中 ${DISTRO_NAME} 指定的仓库名称 ${GET_ZZ_NAME} 不存在，不能继续，请检查 default_store 中的设置。"
		exit 3
	fi
fi
if [ "x${GET_CUSTOM_STEP_NAME}" == "x" ]; then
	if [ "x${GET_FULL_DISTRO_SET}" == "x" ]; then
		echo "default_store 文件中没有 ${DISTRO_NAME} 设置的内容，将使用默认的种子文件 default.step 进行目标系统的生成。"
	eles
		echo "default_store 文件中定义了 ${DISTRO_NAME} ，但没有定义种子文件，将使用默认的 default.step 。"
	fi
else
	if [ -f storehouse/${GET_ZZ_NAME}/step/${GET_CUSTOM_STEP_NAME}.step ]; then
		CUSTOM_STEP_NAME=${GET_CUSTOM_STEP_NAME}
	else
		echo "default_store 中 ${DISTRO_NAME} 指定的种子文件 ${GET_CUSTOM_STEP_NAME}.step 不存在，不能继续，请检查 default_store 中的设置。"
		exit 3
	fi
fi


echo -n "创建目录结构..."
mkdir -pv ${DISTRO_DIR}/{scripts,env}
# mkdir -pv ${DISTRO_DIR}/{status,logs}
mkdir -pv ${DISTRO_DIR}/logs
mkdir -pv ${DISTRO_DIR}/sources/{url,downloads,files}
echo "完成。"
# echo -n "复制脚本文件..."
# if [ ! -d ${DISTRO_DIR}/tools ]; then
# 	echo -n ""
# #	cp -a scripts/tools ${DISTRO_DIR}/
# fi
# if [ ! -f ${DISTRO_DIR}/build.sh ]; then
# 	echo -n ""
# #	cp -a scripts/build.sh ${DISTRO_DIR}/
# fi
# chmod +x ${DISTRO_DIR}/build.sh ${DISTRO_DIR}/tools/*.sh
# echo "完成。"

echo -n "创建索引文件..."
get_steps ${ZZ_NAME} ${CUSTOM_STEP_NAME} | grep "^%" > ${DISTRO_DIR}/step
echo "" > ${DISTRO_DIR}/arch_step
echo "" > ${DISTRO_DIR}/set_step
echo "完成。"

for i in $(cat ${DISTRO_DIR}/step  | gawk -F'/' '{ print $2 }' | sort | uniq)
do
	echo -n "创建${i}的配置..."
	mkdir -p ${DISTRO_DIR}/env/${i}/
	cat storehouse/${ZZ_NAME}/env/common | grep -v "^#[[:blank:]]" > ${DISTRO_DIR}/env/${i}/config
	if [ -f storehouse/${ZZ_NAME}/env/arch/${DISTRO_ARCH}/env ]; then
		cat storehouse/${ZZ_NAME}/env/arch/${DISTRO_ARCH}/env | grep -v "^#[[:blank:]]" >> ${DISTRO_DIR}/env/${i}/config
	else
		load_common_env storehouse/${ZZ_NAME}/env/common_env | grep -v "^#[[:blank:]]" >> ${DISTRO_DIR}/env/${i}/config
	fi
	if [ -f storehouse/${ZZ_NAME}/env/${i}/common ]; then
		cat storehouse/${ZZ_NAME}/env/${i}/common | grep -v "^#[[:blank:]]" >> ${DISTRO_DIR}/env/${i}/config
	fi
	if [ -f storehouse/${ZZ_NAME}/env/${i}/arch/${DISTRO_ARCH}/env ]; then
		cat storehouse/${ZZ_NAME}/env/${i}/arch/${DISTRO_ARCH}/env | grep -v "^#[[:blank:]]" >> ${DISTRO_DIR}/env/${i}/config
	fi
	if [ -f storehouse/${ZZ_NAME}/env/${i}/overlay.set ]; then
		cat storehouse/${ZZ_NAME}/env/${i}/overlay.set | grep -v "^#[[:blank:]]" > ${DISTRO_DIR}/env/${i}/overlay.set
	fi
	if [ -f storehouse/${ZZ_NAME}/env/${i}/custom ]; then
		cat storehouse/${ZZ_NAME}/env/${i}/custom | grep -v "^#[[:blank:]]" > ${DISTRO_DIR}/env/${i}/custom || true
	else
		if [ -f ${DISTRO_DIR}/env/${i}/custom ]; then
			rm -f ${DISTRO_DIR}/env/${i}/custom
		fi
	fi
	echo "完成！"
done

# if [ ! -f ${DISTRO_DIR}/env/distro.info ]; then
# 	echo "DISTRO_ARCH=${DISTRO_ARCH}" > ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_ARCH_NAME=${DISTRO_ARCH}" >> ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_NAME=${DISTRO_NAME}" >> ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_VERSION=1.0" >> ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_ARCHIVE_MODE=squashfs" >> ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_DEFAULT_USER=$(echo ${DISTRO_ARCH} | sed -e "s@64@@g" -e "s@32@@g")" >> ${DISTRO_DIR}/env/distro.info
# 	echo "DISTRO_DEFAULT_USER_PASSWD=$(echo ${DISTRO_ARCH} | sed -e "s@64@@g" -e "s@32@@g")" >> ${DISTRO_DIR}/env/distro.info
# 	echo "export DISTRO_ARCH DISTRO_ARCH_NAME DISTRO_NAME DISTRO_VERSION DISTRO_ARCHIVE_MODE DISTRO_DEFAULT_USER" >> ${DISTRO_DIR}/env/distro.info
# fi
# if [ ! -f ${DISTRO_DIR}/env/opt.info ]; then
# 	echo "opt=+g_opt" > ${DISTRO_DIR}/env/opt.info
# 	echo "opt=+f_opt" >> ${DISTRO_DIR}/env/opt.info
# fi
# # cp -a scripts/env/*.sh ${DISTRO_DIR}/env/


echo "创建制作文件..."
if [ "x${CUSTOM_STEP_STR}" == "x" ]; then
# 	DISTRO_DIR_STEP="$(cat ${DISTRO_DIR}/step)"
	DISTRO_DIR_STEP="$(cat ${DISTRO_DIR}/step | sed "s@^%@@g" | awk -F'|' '{ print $1 }' | sort | uniq)"
else
	GREP_STR=""
	for step_i in $(echo ${CUSTOM_STEP_STR} | tr ',' ' ')
	do
		if [ "x${GREP_STR}" == "x" ]; then
			GREP_STR="${step_i}"
		else
			GREP_STR="${GREP_STR}/\|/${step_i}"
		fi
	done
#	DISTRO_DIR_STEP="$(cat ${DISTRO_DIR}/step | grep "/${GREP_STR}/")"
	DISTRO_DIR_STEP="$(cat ${DISTRO_DIR}/step | grep "/${GREP_STR}/" | sed "s@^%@@g" | awk -F'|' '{ print $1 }' | sort | uniq)"
fi

LOCK_GROUP_NAME=""

# for i in $(cat ${DISTRO_DIR}/step)
for i in ${DISTRO_DIR_STEP}
do
#	STEP_NAME=$(echo $i | sed "s@^%@@g" | awk -F'|' '{ print $1 }')
	STEP_NAME="${i}"
	if [ "x${STEP_NAME##*/}" == "xNULL" ]; then
		continue
	fi

	if [ "x${FORCE_OVERWRITE}" == "x0" ]; then
		LOCK_MODE=$(soft_lock_mode "${STEP_NAME}")
		case "x${LOCK_MODE}" in
			xGROUP)
				echo -e "\e[31m根据 ${LOCK_GROUP_NAME} 的锁定设置，因目前 ${DISTRO_DIR} 已启动构建，不再更新 ${LOCK_GROUP_NAME} 内的构建脚本。\e[0m"
				if [ -d ${DISTRO_DIR}/workbase ]; then
					if [ "x${LOCK_GROUP_NAME}" != "x$(echo ${STEP_NAME} | awk -F'/' '{ print $2 }')" ]; then
						LOCK_GROUP_NAME=$(echo ${STEP_NAME} | awk -F'/' '{ print $2 }')
						echo -e "\e[31m根据 ${LOCK_GROUP_NAME} 的锁定设置，因目前 ${DISTRO_DIR} 已启动构建，不再更新 ${LOCK_GROUP_NAME} 内的构建脚本。\e[0m"
					fi
					continue
				fi
				;;
			xAUTO)
				if [ -d ${DISTRO_DIR}/workbase ]; then
					echo -e "\e[31m根据 ${STEP_NAME} 的锁定设置，因目前 ${DISTRO_DIR} 已启动构建，不再更新该软件包的构建脚本。\e[0m"
					continue
				fi
				;;
			*)
				;;
		esac
	fi

	VERSION_URL=$(form_stepname_to_downloadurl ${STEP_NAME} ${DISTRO_ARCH})
	mkdir -p ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME%/*} | sed "s@^step/@@g")
	echo "${VERSION_URL}" > ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g")

	if [ -f ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").gitinfo ]; then
		rm ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").gitinfo
	fi

	if [ "x${VERSION_URL}" != "x" ]; then
		SOURCE_TYPE=$(echo ${VERSION_URL} | awk -F'|' '{ print $1 }')
		SOURCE_URL=$(echo ${VERSION_URL} | awk -F'|' '{ print $2 }')

#                caase "${VERSION_URL%%/*}" in
                case "${SOURCE_TYPE}" in
                FILE)
			if [ -f files/${SOURCE_URL#*//} ]; then
                                echo "复制：$i 所需源码包到${DISTRO_DIR}/sources/files/${SOURCE_URL#*//}..."
                                cp -a files/${SOURCE_URL#*//} ${DISTRO_DIR}/sources/files/
                        else
				echo "错误：$i 所需源码包files/${SOURCE_URL#*//}没有找到。"
				exit 3
                        fi
			;;
		GIT)
			GIT_INFO=$(form_stepname_to_gitinfo ${STEP_NAME} ${DISTRO_ARCH})
			echo "${GIT_INFO}" > ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").gitinfo
			;;
		*)
#			VERSION_DOWNLOAD_URL=$(echo ${VERSION_URL} | awk -F'|' '{ print $1 }')
#			if [ "x${VERSION_DOWNLOAD_URL##*\.}" == "xgit" ]; then
#				GIT_INFO=$(form_stepname_to_gitinfo ${STEP_NAME} ${DISTRO_ARCH})
#				echo "${GIT_INFO}" > ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").gitinfo
#			fi
			;;
		esac
	fi


#	form_stepname_to_script ${STEP_NAME} ${DISTRO_ARCH}
	RET=$(form_stepname_to_script ${STEP_NAME} ${DISTRO_ARCH})
	if [ "x${RET}" == "x2" ]; then
		echo "form_stepname_to_script ${STEP_NAME} ${DISTRO_ARCH} 错误！"
		exit 2
	fi

	if [ "x${RET}" == "x1" ]; then
		echo -n ""
	else
		if [ "x${RET}" == "x0" ]; then
			echo -n ""
		else
			mkdir -p ${DISTRO_DIR}/scripts/${STEP_NAME%/*}
#			echo "${DISTRO_DIR}/scripts/${STEP_NAME}"
			echo "${RET}" > ${DISTRO_DIR}/scripts/${STEP_NAME}

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.os_first_run ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.os_first_run
			fi
			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.os_start_run ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.os_start_run
			fi
			OS_FIRST_RUN_STR=$(form_stepname_to_os_run ${STEP_NAME} ${DISTRO_ARCH} "os_first_run")
			OS_START_RUN_STR=$(form_stepname_to_os_run ${STEP_NAME} ${DISTRO_ARCH} "os_start_run")
			if [ "x${OS_FIRST_RUN_STR}" != "x1" ] && [ "x${OS_FIRST_RUN_STR}" != "x2" ]; then
				echo "${OS_FIRST_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.os_first_run
			fi
			if [ "x${OS_START_RUN_STR}" != "x1" ] && [ "x${OS_START_RUN_STR}" != "x2" ]; then
				echo "${OS_START_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.os_start_run
			fi


			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.tempfix ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.tempfix
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_tempfix ${STEP_NAME} ${DISTRO_ARCH} "tempfix")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.tempfix
			fi

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.env ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.env
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "env")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.env
			fi

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.check ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.check
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "check")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.check
			fi

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.parmfilter ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.parmfilter
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "parmfilter")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.parmfilter
			fi

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.watch_step ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.watch_step
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "watch_step")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.watch_step
			fi

			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.fix_sysroot ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.fix_sysroot
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "fix_sysroot")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.fix_sysroot
			fi


			# 根据步骤文件中定义的软件名称获取默认版本的相关信息。
			STEP_INFO=$(form_stepname_to_version ${STEP_NAME} ${DISTRO_ARCH})
			STEP_INFO_VERSION=$(echo "${STEP_INFO}" | gawk -F'|' '{ print $1 }')
			STEP_INFO_PACKAGE=$(echo "${STEP_INFO}" | gawk -F'|' '{ print $2 }')
			STEP_INFO_ORIG_NAME=$(echo "${STEP_INFO}" | gawk -F'|' '{ print $3 }')
			STEP_INFO_ARCH=$(echo "${STEP_INFO}" | gawk -F'|' '{ print $4 }')
			echo "${STEP_INFO_PACKAGE}|${STEP_INFO_VERSION}|${STEP_INFO_ORIG_NAME}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.info
			case "x${STEP_INFO_ARCH}" in
				"x${DISTRO_ARCH}")
					echo "注意：${STEP_NAME} 使用的是 ${DISTRO_ARCH} 架构相关的版本。"
					if [ "x${CUSTOM_STEP_STR}" == "x" ]; then
						echo "${i}" >> ${DISTRO_DIR}/arch_step
					fi
					;;
				"xLOCK_VERSION")
					echo -e "\e[34m注意：${STEP_NAME}使用的是锁定的版本。\e[0m"
					;;
				*)
					if [ "x${STEP_INFO_PACKAGE}" != "xNULL" ] && ( [ ! -f package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version ] || [ "x${STEP_INFO_VERSION}" != "x$(cat package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version)" ] ); then
						echo -e "\e[33m注意：${STEP_NAME} 使用的是指定版本。\e[0m"
						if [ "x${CUSTOM_STEP_STR}" == "x" ]; then
							echo "${i}" >> ${DISTRO_DIR}/set_step
						fi
					fi
					;;
			esac



#			if [ "x${STEP_INFO_ARCH}" == "x${DISTRO_ARCH}" ]; then
#				echo "注意：${STEP_NAME}使用的是${DISTRO_ARCH}架构相关的版本。"
#				if [ "x${CUSTOM_STEP_STR}" == "x" ]; then
#					echo "${i}" >> ${DISTRO_DIR}/arch_step
#				fi
#			else
#				if [ "x${STEP_INFO_PACKAGE}" != "xNULL" ] && ( [ ! -f package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version ] || [ "x${STEP_INFO_VERSION}" != "x$(cat package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version)" ] ); then
#					echo -e "\e[33m注意：${STEP_NAME}使用的是指定版本。\e[0m"
#					if [ "x${CUSTOM_STEP_STR}" == "x" ]; then
#						echo "${i}" >> ${DISTRO_DIR}/set_step
#					fi
#				fi
#			fi
			mkdir -p ${DISTRO_DIR}/files/${STEP_NAME%/*}
			form_stepname_copy_files "${STEP_NAME}" "${DISTRO_DIR}/files/${STEP_NAME%/*}" "${DISTRO_ARCH}"


			# 根据版本组文件中定义的版本获取所需版本的相关信息。
			if [ -f ${DISTRO_DIR}/scripts/${STEP_NAME}.versions ]; then
				rm ${DISTRO_DIR}/scripts/${STEP_NAME}.versions
			fi
			STEP_TEMPFIX_RUN_STR=$(form_stepname_to_file ${STEP_NAME} ${DISTRO_ARCH} "versions")
			if [ "x${STEP_TEMPFIX_RUN_STR}" != "x1" ] && [ "x${STEP_TEMPFIX_RUN_STR}" != "x2" ]; then
				# 版本组文件的内容定义
				# 版本标记|软件包名|版本号
				for version_line in ${STEP_TEMPFIX_RUN_STR}
				do
					VERSION_LINE_INDEX=$(echo "${version_line}" | gawk -F'|' '{ print $1 }')
#					VERSION_LINE_PACKAGE=$(echo "${version_line}" | gawk -F'|' '{ print $2 }')
					VERSION_LINE_PKG_VERSION=$(echo "${version_line}" | gawk -F'|' '{ print $3 }')
					echo "${STEP_INFO_PACKAGE}|${VERSION_LINE_PKG_VERSION}|${STEP_INFO_ORIG_NAME}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.${VERSION_LINE_INDEX}.info
					if [ "x${STEP_INFO_PACKAGE}" != "xNULL" ] && ( [ ! -f package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version ] || [ "x${VERSION_LINE_PKG_VERSION}" != "x$(cat package_version/${VERSIONS_NAME}/${STEP_INFO_PACKAGE}.version)" ] ); then
						echo -e "\e[33m ${STEP_NAME} 增加附加版本： ${VERSION_LINE_PKG_VERSION} 。\e[0m"
					fi

					RET=$(form_stepname_to_script ${STEP_NAME} ${DISTRO_ARCH} "${VERSION_LINE_PKG_VERSION}")
					if [ "x${RET}" == "x2" ]; then
						echo "form_stepname_to_script ${STEP_NAME} ${DISTRO_ARCH} 错误！"
						exit 2
					fi

					if [ "x${RET}" == "x1" ]; then
						echo -n ""
					else
						if [ "x${RET}" == "x0" ]; then
							echo -n ""
						else
							echo "${RET}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.${VERSION_LINE_INDEX}

							form_stepname_copy_files "${STEP_NAME}" "${DISTRO_DIR}/files/${STEP_NAME%/*}" "${DISTRO_ARCH}" "${VERSION_LINE_PKG_VERSION}"

							VERSION_URL=$(form_stepname_to_downloadurl ${STEP_NAME} ${DISTRO_ARCH} ${VERSION_LINE_PKG_VERSION})
							echo "${VERSION_URL}" > ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").${VERSION_LINE_INDEX}

							if [ -f ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").${VERSION_LINE_INDEX}.gitinfo ]; then
								rm ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").${VERSION_LINE_INDEX}.gitinfo
							fi

							if [ "x${VERSION_URL}" != "x" ]; then
								SOURCE_TYPE=$(echo ${VERSION_URL} | awk -F'|' '{ print $1 }')
								SOURCE_URL=$(echo ${VERSION_URL} | awk -F'|' '{ print $2 }')

						                case "${SOURCE_TYPE}" in
						                FILE)
									if [ -f files/${SOURCE_URL#*//} ]; then
				                		                echo "复制：$i 所需源码包到${DISTRO_DIR}/sources/files/${SOURCE_URL#*//}..."
			        	                        		cp -a files/${SOURCE_URL#*//} ${DISTRO_DIR}/sources/files/
					                	        else
										echo "错误：$i 所需源码包files/${SOURCE_URL#*//}没有找到。"
										exit 3
				                		        fi
									;;
								GIT)
									GIT_INFO=$(form_stepname_to_gitinfo ${STEP_NAME} ${DISTRO_ARCH} ${VERSION_LINE_PKG_VERSION})
									echo "${GIT_INFO}" > ${DISTRO_DIR}/sources/url/$(echo ${STEP_NAME} | sed "s@^step/@@g").${VERSION_LINE_INDEX}.gitinfo
									;;
								*)
									;;
								esac
							fi
						fi
					fi
				done

				echo "${STEP_TEMPFIX_RUN_STR}" > ${DISTRO_DIR}/scripts/${STEP_NAME}.versions

			fi

			echo -n ""
		fi
	fi
done
echo "1.0" > ${DISTRO_DIR}/ZZ.version
echo "主线分支" > ${DISTRO_DIR}/branch_message
mkdir -p ${DISTRO_DIR}/sync/
echo "$(date +%Y%m%d%H%M%S)" > ${DISTRO_DIR}/sync/branch_stamp
echo "完成！"
echo "现在可以切换到 ${DISTRO_DIR} 目录，执行 ./build.sh 构建系统。"
