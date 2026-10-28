#!/bin/bash
#
# FIXED_BBOX and mask hint properties under "scalegrid" and "move origin".
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.689

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/prop.tcl < /dev/null > prop.log
st=$?
if ! grep -q "^DONE" prop.log; then
    echo "  magic did not finish (exit status ${st};  see prop.log)"
    [ -s props.txt ] || finish 1
fi
python3 ${TESTDIR}/check.py props.txt | sed 's/^/  /'
s=${PIPESTATUS[0]}
grep -q "^DONE" prop.log || s=1
finish ${s}
