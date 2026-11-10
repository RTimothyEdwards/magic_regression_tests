#!/bin/bash
#
# R-C extraction of a standard cell whose pins have large or multiple
# labels.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.697
require_pdk sky130A

cd ${WORK}
run_magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc \
	${TESTDIR}/layout.tcl < /dev/null > layout.log
if ! grep -q "^DONE" layout.log || [ ! -s top_flat.res.ext ]; then
    echo "  magic did not finish or wrote no top_flat.res.ext:  see layout.log"
    finish 1
fi

status=0
net=sky130_fd_sc_hd__inv_2_0

if grep -q "Couldn't find device\|Error in extracting node" layout.log; then
    echo "  extraction errors:"
    grep "Couldn't find device\|Error in extracting node" layout.log | sed 's/^/    /'
    status=1
else
    echo "  no extraction errors:  ok"
fi

for pin in VGND VPWR Y; do
    if grep -q "^rnode \"${net}.${pin}\" " top_flat.res.ext; then
	echo "  ${pin} extracted:  ok"
    else
	echo "  ${pin} has no network in top_flat.res.ext"
	status=1
    fi
done

dups=$(awk '$1 == "rnode" {print $2}' top_flat.res.ext | sort | uniq -d | tr '\n' ' ')
if [ -n "${dups}" ]; then
    echo "  node names written more than once:  ${dups}"
    status=1
else
    echo "  each node written once:  ok"
fi

selfres=$(awk '$1 == "resist" && $2 == $3' top_flat.res.ext)
if [ -n "${selfres}" ]; then
    echo "  resistors from a node to itself:"
    echo "${selfres}" | sed 's/^/    /'
    status=1
else
    echo "  no resistor from a node to itself:  ok"
fi

finish ${status}
