#!/bin/bash
#
# Very long cell use names.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/longname.tcl < /dev/null \
	> ${WORK}/longname.log
status=$?
grep "^  " ${WORK}/longname.log | grep "ok:\|FAILED"
if [ ${status} -ne 0 ]; then
    echo "  magic exited with status ${status}"
    finish 1
fi
grep -q "^RESULT failures=0$" ${WORK}/longname.log
finish $?
