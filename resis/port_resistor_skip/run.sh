#!/bin/bash
#
# Network simplification in "extresist" must not crash when the resistor
# being merged away is not the first in its list.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.697
require_pdk sky130A

cd ${WORK}
run_magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc \
	${TESTDIR}/layout.tcl < /dev/null > layout.log
if ! grep -q "^DONE" layout.log; then
    echo "  magic did not finish (crashed?):  see layout.log"
    finish 1
fi
if [ ! -s top_flat.res.ext ]; then
    echo "  no top_flat.res.ext written:  see layout.log"
    finish 1
fi
echo "  two abutted inv_2, mindelay 0:  ok"
finish 0
