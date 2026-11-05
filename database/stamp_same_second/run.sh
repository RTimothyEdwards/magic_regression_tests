#!/bin/bash
#
# Saving a cell twice within one second must not report an out-of-date timestamp.
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.695

cd ${WORK}
echo "" > empty.rc
status=0

fail() {
    echo "  $1"
    status=1
}

cat > cell.mag <<EOT
magic
tech scmos
timestamp 1000
<< metal1 >>
rect 0 0 10 10
<< end >>
EOT
cat > parent.mag <<EOT
magic
tech scmos
timestamp 2000
use cell  cell_0
timestamp 1000
transform 1 0 0 0 1 0
box 0 0 10 10
<< end >>
EOT

run_magic -T scmos -rcfile empty.rc ${TESTDIR}/stamp.tcl < /dev/null > stamp.log
grep -q "^DONE" stamp.log || fail "magic did not finish (see stamp.log)"
grep -q "out-of-date" stamp.log && fail "reported an out-of-date timestamp"
grep -q "^PENDING" stamp.log && fail "a saved cell still needs a new timestamp"

# The test depends on saves in the same second, so check that it made some.
grep -q "^SAME_SECOND" stamp.log || fail "no two saves were in the same second"

# A save in a later second must still get a new timestamp, in the file and
# in the parent.
grep -q "^NEW_STAMP" stamp.log || fail "a later save did not get a new timestamp"
child=$(awk '/^timestamp/ { print $2; exit }' cell.mag)
recorded=$(awk '/^use cell/ { getline; print $2 }' parent.mag)
[ "${child}" = "${recorded}" ] ||
	fail "parent records cell timestamp ${recorded}, cell has ${child}"
[ "${child}" != "1000" ] || fail "cell.mag kept its old timestamp"

finish ${status}
