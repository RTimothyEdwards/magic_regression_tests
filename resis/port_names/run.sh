#!/bin/bash
#
# Every port of a net extracted by "extresist" must remain a distinct,
# connected node of the resistor network, even where the resistors around
# it are smaller than "minres".  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.692

PDK=${PDK_ROOT}/sky130A
TECH=${PDK}/libs.tech/magic/sky130A.tech
RC=${PDK}/libs.tech/magic/sky130A.magicrc
SPICENET="python3 ${TESTDIR}/../../common/spicenet.py"
status=0
cd ${WORK}

sheet_res() {
    awk -v cls="$1" '/^extract/ { e = 1 } e && $1 == "resist" && $2 == cls {
	print $3; exit }' ${TECH}
}

# run_case <name> <layer> <length> <sheet class> <extresist options...>
#   A 1um wide wire with ports IN and OUT at the ends and MID in the
#   middle.  Each half of the wire is (length - 1) / 2 squares.

run_case() {
    local name=$1 layer=$2 len=$3 cls=$4; shift 4
    local opts="$*" half r_im r_mo r_io dangling result
    half=$(echo "$(sheet_res ${cls}) * (${len} - 1) / 2 / 1000" | bc -l)
    WIRELAYER=${layer} WIRELEN=${len} WIREWID=1 WIREMID=1 WIRENAME=${name} \
	RESOPTS="${opts}" \
	run_magic -rcfile ${RC} ${TESTDIR}/../../common/resis_wire.tcl \
	> ${name}.log
    r_im=$(${SPICENET} ${name}.spice res IN MID)
    r_mo=$(${SPICENET} ${name}.spice res MID OUT)
    r_io=$(${SPICENET} ${name}.spice res IN OUT)
    dangling=$(${SPICENET} ${name}.spice dangling | cut -d' ' -f2 | tr '\n' ' ')
    result=$(python3 -c "
half = ${half}
err = []
for pair, got, exp in (('IN-MID', '${r_im}', half), ('MID-OUT', '${r_mo}', half),
                       ('IN-OUT', '${r_io}', 2 * half)):
    if got == 'open':
        err.append('%s open' % pair)
    elif abs(float(got) - exp) > 0.02 * exp:
        err.append('%s %s ohms (expected %.4g)' % (pair, got, exp))
if '${dangling}'.strip():
    err.append('unconnected pins: ${dangling}')
print(('FAIL:  ' + ';  '.join(err)) if err else 'ok:  IN-MID ${r_im}, MID-OUT ${r_mo} ohms')")
    printf '  %-12s %-34s %s\n' "${name}:" "(${opts})" "${result}"
    [[ ${result} == FAIL* ]] && status=1
}

# Halves of 12.4 ohms (above the default minres of 1 ohm)
run_case m1_long  m1 200 "(allm1)/metal1" {threshold 0} {mindelay 0}
# Halves of 0.45 ohms, below minres:  the network may not be reduced
# by merging the ports together.
run_case m4_short m4 20  "(allm4)/metal4" {threshold 0} {mindelay 0}
run_case m4_minres m4 20 "(allm4)/metal4" {threshold 0} {mindelay 0} {minres 2000}

finish ${status}
