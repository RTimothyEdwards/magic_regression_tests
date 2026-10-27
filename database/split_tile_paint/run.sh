#!/bin/bash
#
# Painting over split (non-Manhattan) tiles.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc

status=0
for c in corner stripe stripe_low diagonal; do
    CASE=${c} run_magic -T scmos -rcfile empty.rc ${TESTDIR}/paint.tcl \
	    < /dev/null > ${c}.log
    if ! grep -q "^DONE" ${c}.log; then
	echo "  ${c}:  magic did not finish (see ${c}.log)"
	status=1
    fi
    if [ ! -f ${c}_after.mag ]; then
	echo "  ${c}:  no result after paint"
	status=1
	continue
    fi
    python3 ${TESTDIR}/check.py ${c} | sed 's/^/  /'
    [ ${PIPESTATUS[0]} = 0 ] || status=1
done

finish ${status}
