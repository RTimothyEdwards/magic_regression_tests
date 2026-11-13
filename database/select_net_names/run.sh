#!/bin/bash
#
# "select net" connections through labels of the same name, following the
# "extract do unique" setting.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.701

cd ${WORK}
run_magic -T scmos -norcfile ${TESTDIR}/nets.tcl < /dev/null > magic.log
grep "^NET " magic.log > nets
status=0
if ! diff ${TESTDIR}/expected nets > nets.diff; then
    echo "  selected nets differ from the expected (< expected, > found):"
    sed 's/^/    /' nets.diff
    status=1
else
    echo "  $(wc -l < nets) selections:  ok"
fi

# Each selection that reaches both wires of a name (taller than one
# wire) used a connection by name, and gives one warning.
nwarn=$(grep -c "connected by the name" magic.log)
nexpect=$(awk '($8 - $6) > 4 {n++} END {print n}' ${TESTDIR}/expected)
if [ "${nwarn}" != "${nexpect}" ]; then
    echo "  ${nwarn} warnings, expected ${nexpect}"
    status=1
else
    echo "  ${nwarn} warnings:  ok"
fi
# "getnode" follows the same connections (but does not warn), and with
# "getnode alias on" gives a list of names for each node.
run_magic -T scmos -norcfile ${TESTDIR}/getnode.tcl < /dev/null > getnode.log
grep "^G[NA] " getnode.log > getnode
if ! diff ${TESTDIR}/getnode_expected getnode > getnode.diff; then
    echo "  getnode results differ from the expected (< expected, > found):"
    sed 's/^/    /' getnode.diff
    status=1
elif grep -q "connected by the name" getnode.log; then
    echo "  getnode:  printed a warning"
    status=1
else
    echo "  getnode:  ok"
fi
finish ${status}
