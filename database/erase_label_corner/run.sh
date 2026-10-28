#!/bin/bash
#
# Labels must stay attached when part of the shape under them is erased.
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
status=0
for c in ne sw edge; do
    CASE=${c} run_magic -T scmos -rcfile empty.rc ${TESTDIR}/erase.tcl \
	    < /dev/null > ${c}.log
    if ! grep -q "^DONE" ${c}.log; then
	echo "  ${c}:  magic did not finish (see ${c}.log)"
	status=1
	continue
    fi
    python3 ${TESTDIR}/check.py ${c} | sed 's/^/  /'
    [ ${PIPESTATUS[0]} = 0 ] || status=1
done
finish ${status}
