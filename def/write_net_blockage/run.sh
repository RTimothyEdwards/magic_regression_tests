#!/bin/bash
#
# "def write" with an unlabeled net, written as a blockage.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.700

cd ${WORK}
run_magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc \
	${TESTDIR}/layout.tcl < /dev/null > magic.log
result=$?
if [ ${result} -ne 0 ] || ! grep -q "^DEF DONE" magic.log; then
    echo "  def write failed (exit status ${result})"
    finish 1
fi

# The unlabeled wire, 2um x 0.2um at the origin, is the only blockage.
blockage=$(sed -n '/^BLOCKAGES/,/^END BLOCKAGES/p' top.def | tr -s ' \n' ' ')
echo "  ${blockage}"
expect="BLOCKAGES 1 ; - LAYER met1 RECT ( 0 0 ) ( 2000 200 ) ; END BLOCKAGES "
[ "${blockage}" = "${expect}" ]
finish $?
