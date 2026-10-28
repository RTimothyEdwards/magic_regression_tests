#!/bin/bash
#
# Cell bounding box with label text extending outside the paint.  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
for step in make bbox; do
    run_magic -T scmos -rcfile empty.rc ${TESTDIR}/${step}.tcl \
	    < /dev/null > ${step}.log
    if ! grep -q "^DONE" ${step}.log; then
	echo "  step \"${step}\" did not finish (see ${step}.log)"
	finish 1
    fi
done

# The cell's paint is (0, 0) to (71, 78), placed at (-50, 144)
want="-50 144 21 222"
got=$(cat bbox.txt)
if [ "${got}" = "${want}" ]; then
    echo "  selected top cell:  ${got}"
    finish 0
else
    echo "  selected top cell:  ${got}, expected ${want}"
    finish 1
fi
