#!/bin/bash
#
# GDS output for a read-only cell whose GDS_FILE is a path relative to the
# directory of its .mag file.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.690

mkdir -p ${WORK}/gds ${WORK}/magic/sub
echo "" > ${WORK}/empty.rc
step() {	# step <directory> <script>
    (cd ${WORK}/$1 && run_magic -T scmos -rcfile ${WORK}/empty.rc \
	    ${TESTDIR}/$2.tcl < /dev/null > ${WORK}/$2.log)
    if ! grep -q "^DONE" ${WORK}/$2.log; then
	echo "  step $2 did not finish (see $2.log)"
	finish 1
    fi
}
step gds mk
step magic/sub rd
grep "^GDS_FILE" ${WORK}/rd.log | sed 's/^/  /'
step magic top
grep "^use" ${WORK}/magic/top.mag | sed 's/^/  /'
step magic wr

status=0
if grep -q "Calma output error" ${WORK}/wr.log; then
    grep "Calma output error" ${WORK}/wr.log | sed 's/^/  /'
    status=1
fi
cd ${WORK}
python3 ${TESTDIR}/../../common/gds_same_layers.py gds/blk.gds magic/out.gds | sed 's/^/  /'
[ ${PIPESTATUS[0]} = 0 ] || status=1
finish ${status}
