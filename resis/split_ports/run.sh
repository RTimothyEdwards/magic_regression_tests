#!/bin/bash
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_pdk sky130A
python3 "$TESTDIR/check.py" "$MAGIC" "$PDK_ROOT" "$WORK"
finish $?
