#!/bin/bash
#
# The capacitance of a net extracted by "extresist" is distributed over
# the nodes of the resistor network;  the total must be the same as the
# capacitance of the net without extresist.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A

PDK=${PDK_ROOT}/sky130A
RC=${PDK}/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# Sum of all capacitors in a SPICE file, in fF
total_cap() {
    python3 -c "
import sys
sys.path.insert(0, '${TESTDIR}/../../common')
from spicenet import parse
subckts, elements = parse('$1')
print('%.6g' % (sum(v for n, _, v in elements if n[0].lower() == 'c' and v) * 1e15))"
}

# run_case <name> <layer> <length> <mid port 0|1> <extresist options...>
run_case() {
    local name=$1 layer=$2 len=$3 mid=$4; shift 4
    local opts="$*" lumped split result
    WIRELAYER=${layer} WIRELEN=${len} WIREWID=1 WIREMID=${mid} WIRECAPS=1 \
	WIRENAME=${name} RESOPTS="${opts}" \
	run_magic -rcfile ${RC} ${TESTDIR}/../../common/resis_wire.tcl \
	> ${name}.log
    lumped=$(total_cap ${name}_lumped.spice)
    split=$(total_cap ${name}.spice)
    result=$(python3 -c "
l, s = ${lumped:-0}, ${split:-0}
if l <= 0:
    print('FAIL:  no capacitance in the netlist without extresist')
elif abs(s - l) > 0.005 * l:
    print('FAIL:  %.4g fF with extresist, %.4g fF without' % (s, l))
else:
    print('ok:  %.4g fF' % s)")
    printf '  %-10s %s\n' "${name}:" "${result}"
    [[ ${result} == FAIL* ]] && status=1
}

run_case li_wire  li 100 0 {threshold 0} {mindelay 0}
run_case m1_wire  m1 100 0 {threshold 0} {mindelay 0}
run_case m1_mid   m1 200 1 {threshold 0} {mindelay 0}
run_case li_delay li 100 0 {threshold 0} {mindelay 1}

finish ${status}
