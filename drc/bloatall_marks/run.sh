#!/bin/bash
#
# Tile marks left by the bloat-all and tagged CIF operators.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.700
export TESTDIR

cd ${WORK}
status=0
for style in plain c1 c2 c3; do
    mkdir ${style}
    (cd ${style} && DSTYLE="default(${style})" run_magic -norcfile \
	    ${TESTDIR}/marks.tcl < /dev/null > magic.log)
    result=$?
    if [ ${result} -ne 0 ] || ! grep -q "^EXTRACT DONE" ${style}/magic.log; then
	echo "  ${style}:  extraction failed (exit status ${result})"
	status=1
	continue
    fi
    # The extraction must not depend on whether DRC used the CIF rule.
    grep -v "^timestamp" ${style}/t1.ext > ${style}/t1.cmp
    if [ ${style} != plain ] && ! cmp -s plain/t1.cmp ${style}/t1.cmp; then
	echo "  ${style}:  extraction differs from the plain DRC style"
	diff plain/t1.cmp ${style}/t1.cmp | head -10
	status=1
	continue
    fi
    echo "  ${style}:  ok"
done
finish ${status}
