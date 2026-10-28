#!/bin/bash
#
# Writing GDS for a read-only cell whose GDS file has since been
# compressed.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc

for step in make ref; do
    run_magic -T scmos -rcfile empty.rc ${TESTDIR}/${step}.tcl \
	    < /dev/null > ${step}.log
    if ! grep -q "^DONE" ${step}.log; then
	echo "  step \"${step}\" did not finish (see ${step}.log)"
	finish 1
    fi
done
grep "^GDS_FILE" ref.log | sed 's/^/  /'

# Compress the GDS file;  the .mag file still names blk.gds
cp blk.gds blk_orig.gds
gzip blk.gds
[ ! -f blk.gds ] && echo "  blk.gds compressed to blk.gds.gz"

run_magic -T scmos -rcfile empty.rc ${TESTDIR}/out.tcl < /dev/null > out.log
status=0
if ! grep -q "^DONE" out.log; then
    echo "  writing out.gds did not finish (see out.log)"
    finish 1
fi
if grep -q "Calma output error" out.log; then
    grep "Calma output error" out.log | sed 's/^/  /'
    status=1
fi

python3 ${TESTDIR}/check.py blk_orig.gds out.gds | sed 's/^/  /'
[ ${PIPESTATUS[0]} = 0 ] || status=1

finish ${status}
