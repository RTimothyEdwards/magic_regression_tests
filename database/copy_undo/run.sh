#!/bin/bash
#
# Repeated "copy" of a cell instance followed by "undo".  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/copy.tcl < /dev/null > copy.log
if ! grep -q "^DONE" copy.log; then
    echo "  magic did not finish (see copy.log)"
    finish 1
fi

status=0
got=$(tr '\n' ';' < instances.txt)
if [ "${got}" = "copied 5;undone 2;" ]; then
    echo "  5 instances after copying, 2 after undo"
else
    echo "  instance counts \"${got}\", expected \"copied 5;undone 2;\""
    status=1
fi
# The two instances left must be the original and the first copy
got=$(awk '/^use sub /{u=1} u && /^transform/{print $4; u=0}' top.mag | sort -n | tr '\n' ' ')
if [ "${got}" = "0 20 " ]; then
    echo "  instances left at x = 0 and 20"
else
    echo "  instances left at x = ${got}, expected 0 and 20"
    status=1
fi

finish ${status}
