#!/bin/bash
#
# GDS arrays (AREF) with rotation, a single row or column, and a fine
# pitch.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A

TECH=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.tech

cd ${WORK}
echo "" > empty.rc
python3 ${TESTDIR}/mkgds.py test.gds

run_magic -T ${TECH} -rcfile empty.rc ${TESTDIR}/aref.tcl < /dev/null > aref.log
if ! grep -q "^DONE" aref.log; then
    echo "  magic did not finish (see aref.log)"
    finish 1
fi

python3 ${TESTDIR}/check.py test.gds flat.gds | sed 's/^/  /'
finish ${PIPESTATUS[0]}
