#!/bin/bash
#
# The CIF operators "overlapping", "nonoverlapping", "interacting", and
# "noninteracting".  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.702
export TESTDIR

cd ${WORK}
run_magic -norcfile ${TESTDIR}/sel.tcl < /dev/null > sel.log
result=$?
if [ ${result} -ne 0 ]; then
    echo "  magic failed (exit status ${result}):  see sel.log"
    finish 1
fi

# Each square is 10 x 10 magic units, which is 50 x 50 CIF units.  Give
# each layer's area as the number of squares.
awk '/^LAYER/ {layer = $2}
     /Layer Total Area/ {print layer, $5 / 2500}' sel.log > found
if ! diff ${TESTDIR}/expected found > found.diff; then
    echo "  squares selected differ from the expected (< expected, > found):"
    sed 's/^/    /' found.diff
    finish 1
fi
echo "  $(wc -l < found) layers:  ok"
finish 0
