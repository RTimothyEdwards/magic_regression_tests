#!/bin/bash
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_pdk sky130A
# Draft until the source fix has a released version number; add
# require_magic_version with that actual version before merging.
TECH=$(flat_tech "$PDK_ROOT/sky130A/libs.tech/magic/sky130A.tech")
python3 "$TESTDIR/check.py" "$MAGIC" "$PDK_ROOT" "$WORK" "$TECH"
finish $?
