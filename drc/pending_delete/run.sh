#!/bin/bash
#
# Deleting a cell that was queued for DRC more than once must not leave a
# stale entry in the DRC pending list.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.697

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/del.tcl < /dev/null > del.log
if ! grep -q "^DONE" del.log; then
    echo "  magic did not finish (crashed?):  see del.log"
    finish 1
fi
echo "  delete after queueing twice:  ok"
finish 0
