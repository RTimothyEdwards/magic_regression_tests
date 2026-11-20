#!/bin/bash
# Resistors sharing a model name must retain their actual layout types.
TESTDIR=$(cd "$(dirname "$0")" && pwd)
source "$TESTDIR/../../common/common.sh"
require_pdk ihp-sg13g2
require_magic_version 8.3.706
python3 "$TESTDIR/check.py" "$MAGIC" "$PDK_ROOT" "$WORK"
finish $?
