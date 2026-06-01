#!/bin/env -iS /bin/bash -e


source environment/env/common
source environment/functions

mkdir -pv ${BUILDDIR}
mkdir -pv ${SYSROOT_DIR}

export

echo -n "创建目标系统目录结构..."
# pre/make_directory.sh
echo "完成."
get_steps clfs 2>&1 | tee /tmp/clfs.list.tmp
cat /tmp/clfs.list.tmp | grep "^%" > /tmp/clfs.list
form_list_to_zz /tmp/clfs.list

if [ "$?" != "0" ]; then
    echo "error"
fi
