#!/bin/bash
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_magic_version 8.3.704
cd "$WORK"
run_magic -rcfile /dev/null -T scmos "$TESTDIR/skip.tcl" > invalid_skip.log
result=$?
if [ "$result" -ne 0 ] || ! grep -q '^INVALID_SKIP_DONE' invalid_skip.log ||
        grep -q 'ERROR: AddressSanitizer' invalid_skip.log; then
    echo "  invalid layer command did not finish cleanly"
    finish 1
fi
if ! grep -q 'Unrecognized layer' invalid_skip.log; then
    echo "  missing diagnostic for the unknown layer"
    finish 1
fi
finish 0
