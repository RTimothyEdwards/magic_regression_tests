#!/bin/bash
#
# Netlist "ripup" and "verify" on split (non-Manhattan) tiles.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.700

cd ${WORK}
cp ${TESTDIR}/ver.net .
status=0

run_magic -T scmos -norcfile ${TESTDIR}/ripup.tcl < /dev/null > ripup.log
result=$?
if [ ${result} -ne 0 ] || ! grep -q "^RIPUP DONE" ripup.log; then
    echo "  ripup:  failed (exit status ${result})"
    status=1
elif grep -q "^<< metal1 >>" rip.mag; then
    echo "  ripup:  paint left behind:"
    sed -n '/^<< metal1 >>/,/^<< end >>/p' rip.mag | sed 's/^/    /'
    status=1
else
    echo "  ripup:  ok"
fi

run_magic -T scmos -norcfile ${TESTDIR}/verify.tcl < /dev/null > verify.log
result=$?
if [ ${result} -ne 0 ] || ! grep -q "^VERIFY DONE" verify.log; then
    echo "  verify:  failed (exit status ${result})"
    status=1
elif ! grep -q "No wiring errors found" verify.log; then
    echo "  verify:  $(grep -i 'not connected\|error' verify.log | head -3)"
    status=1
else
    echo "  verify:  ok"
fi

finish ${status}
