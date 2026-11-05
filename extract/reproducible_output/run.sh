#!/bin/bash
#
# Repeated runs of "extract" and "ext2spice" on the same layout must write
# the same files.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.695

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

for run in 1 2 3; do
    mkdir -p run${run}
    (cd run${run} && run_magic -rcfile ${RC} ${TESTDIR}/layout.tcl > layout.log)
done

files=$(cd run1 && ls *.ext *.spice 2>/dev/null)
if [ -z "${files}" ]; then
    echo "  FAIL:  no output, see run1/layout.log"
    status=1
fi
for f in ${files}; do
    if cmp -s run1/${f} run2/${f} && cmp -s run1/${f} run3/${f}; then
	result="ok:  same in all runs"
    else
	result="FAIL:  differs between runs"
	status=1
    fi
    printf '  %-34s %s\n' "${f}:" "${result}"
done

finish ${status}
