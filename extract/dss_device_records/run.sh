#!/bin/bash
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_pdk gf180mcuD
require_magic_version 8.3.708
TECH=$(flat_tech "$PDK_ROOT/gf180mcuD/libs.tech/magic/gf180mcuD.tech")
python3 "$TESTDIR/check.py" "$MAGIC" "$WORK" "$TECH"
finish $?
