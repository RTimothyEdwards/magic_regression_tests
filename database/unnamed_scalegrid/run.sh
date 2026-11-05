#!/bin/bash
#
# "scalegrid" must not make the empty (UNNAMED) cell look like it needs saving.
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

# Empty (UNNAMED), as in every session started with a PDK that uses "scalegrid"
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/empty.tcl < /dev/null > empty.log
grep -q "^REACHED_QUIT" empty.log || fail "magic did not reach quit (see empty.log)"
grep -q "^FLAGS .*bbox-changed" empty.log && fail "empty (UNNAMED) has bbox-changed"
grep -q "^DIALOG .*UNNAMED" empty.log && fail "writeall offered to write empty (UNNAMED)"
grep -q "^DIALOG .*modified" empty.log && fail "quit warned about empty (UNNAMED)"
grep -q "^QUIT_DID_NOT_EXIT" empty.log && fail "quit did not exit"

run_magic -T scmos -rcfile empty.rc ${TESTDIR}/scale.tcl < /dev/null > scale.log
grep -q "^DONE" scale.log || fail "magic did not finish (see scale.log)"

# (UNNAMED) with contents must not be lost
grep -q "^PAINTED_WRITEALL.*UNNAMED" scale.log || fail "writeall did not offer painted (UNNAMED)"
grep -q "^PAINTED_QUIT.*modified" scale.log || fail "quit did not warn about painted (UNNAMED)"

# A cell with a file is scaled in memory and is still offered for writing
grep -q "^CELL_FLAGS .*bbox-changed" scale.log || fail "cell from a file lost bbox-changed"

finish ${status}
