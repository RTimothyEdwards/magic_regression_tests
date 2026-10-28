#!/bin/bash
#
# DEF special nets with several routed segments.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk gf180mcuD

TECH=${PDK_ROOT}/gf180mcuD/libs.tech/magic/gf180mcuD.tech
export TLEF=${PDK_ROOT}/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef/gf180mcu_fd_sc_mcu7t5v0__nom.tlef

cd ${WORK}
echo "" > empty.rc
cp ${TESTDIR}/test.def .

run_magic -T ${TECH} -rcfile empty.rc ${TESTDIR}/def.tcl < /dev/null > def.log
if ! grep -q "^DONE" def.log; then
    echo "  magic did not finish (see def.log)"
    finish 1
fi

status=0
# Any error from reading the DEF file is a failure
if grep -q "^DEF read.*(\(Error\|Warning\|Message\))" def.log; then
    echo "  errors reading the DEF file:"
    grep "^DEF read" def.log | sed 's/^/    /'
    status=1
fi

python3 ${TESTDIR}/check.py out.gds | sed 's/^/  /'
[ ${PIPESTATUS[0]} = 0 ] || status=1

finish ${status}
