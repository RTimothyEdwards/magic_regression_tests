#!/bin/bash
# Coupling area must not overflow at the 32-bit internal-coordinate boundary.
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_pdk sky130A
TECH=$(flat_tech "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech")
python3 "$TESTDIR/check.py" "$MAGIC" "$PDK_ROOT" "$WORK" "$TECH"
finish $?
