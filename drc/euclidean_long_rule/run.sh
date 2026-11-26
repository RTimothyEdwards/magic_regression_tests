#!/bin/bash
#
# Euclidean DRC distance for rules longer than 4095 internal units.
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk ihp-sg13g2
require_magic_version 8.3.709

export TESTDIR
cd ${WORK}
run_magic -T ${PDK_ROOT}/ihp-sg13g2/libs.tech/magic/ihp-sg13g2.tech \
	-rcfile /dev/null ${TESTDIR}/check.tcl > ${WORK}/check.log
grep "^RESULT" ${WORK}/check.log || finish 1
grep -q "^DONE" ${WORK}/check.log || finish 1
grep -q "^RESULT.* WRONG$" ${WORK}/check.log && finish 1
finish 0
