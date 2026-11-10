#!/bin/bash
#
# R-C extraction of a standard cell whose pins have large or multiple
# labels, with the labels as ports and as plain labels.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.697
require_pdk sky130A

cd ${WORK}
status=0

# run_case <script> <.res.ext file>

run_case() {
    run_magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc \
	    ${TESTDIR}/$1.tcl < /dev/null > $1.log
    if ! grep -q "^DONE" $1.log || [ ! -s $2 ]; then
	echo "  $1:  magic did not finish or wrote no $2 (see $1.log)"
	status=1
	return 1
    fi
    if grep -q "Couldn't find device\|Error in extracting node" $1.log; then
	echo "  $1:  extraction errors:"
	grep "Couldn't find device\|Error in extracting node" $1.log | sed 's/^/    /'
	status=1
    else
	echo "  $1:  no extraction errors:  ok"
    fi
    dups=$(awk '$1 == "rnode" {print $2}' $2 | sort | uniq -d | tr '\n' ' ')
    if [ -n "${dups}" ]; then
	echo "  $1:  node names written more than once:  ${dups}"
	status=1
    else
	echo "  $1:  each node written once:  ok"
    fi
    selfres=$(awk '$1 == "resist" && $2 == $3' $2)
    if [ -n "${selfres}" ]; then
	echo "  $1:  resistors from a node to itself:"
	echo "${selfres}" | sed 's/^/    /'
	status=1
    else
	echo "  $1:  no resistor from a node to itself:  ok"
    fi
    return 0
}

# Ports:  each pin is one node with the pin's name

if run_case cell sky130_fd_sc_hd__inv_2.res.ext; then
    for pin in VGND VPWR Y; do
	if grep -q "^rnode \"${pin}\" " sky130_fd_sc_hd__inv_2.res.ext; then
	    echo "  cell:  ${pin} has a node named ${pin}:  ok"
	else
	    echo "  cell:  ${pin} has no node named ${pin}"
	    status=1
	fi
    done
fi

# Plain labels:  no node keeps a label's name

if run_case flat top_flat.res.ext; then
    for pin in VGND VPWR Y; do
	name=sky130_fd_sc_hd__inv_2_0.${pin}
	if grep -q "^rnode \"${name}\" " top_flat.res.ext; then
	    echo "  flat:  ${pin} has a node named after the (non-port) label"
	    status=1
	elif ! grep -q "^rnode \"${name}\.[nt][0-9]" top_flat.res.ext; then
	    echo "  flat:  ${pin} has no network"
	    status=1
	else
	    echo "  flat:  ${pin} subnodes only:  ok"
	fi
    done
fi

finish ${status}
