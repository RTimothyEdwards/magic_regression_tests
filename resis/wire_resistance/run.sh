#!/bin/bash
#
# Resistance of a straight wire on each routing layer, extracted with
# "extresist" with all cutoffs at zero.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A

PDK=${PDK_ROOT}/sky130A
TECH=$(flat_tech ${PDK}/libs.tech/magic/sky130A.tech)
RC=${PDK}/libs.tech/magic/sky130A.magicrc
SPICENET="python3 ${TESTDIR}/../../common/spicenet.py"
status=0
cd ${WORK}

# Sheet resistance (milliohms per square) of a layer, from the first
# (nominal) extract style of the tech file.
sheet_res() {
    awk -v cls="$1" '/^extract/ { e = 1 } e && $1 == "resist" && $2 == cls {
	print $3; exit }' ${TECH}
}

LEN=100
WID=1

for layer in li:"(allli)/locali" m1:"(allm1)/metal1" m2:"(allm2)/metal2" \
	m3:"(allm3)/metal3" m4:"(allm4)/metal4" m5:"(allm5)/metal5"; do
    name=${layer%%:*}
    rsh=$(sheet_res "${layer#*:}")
    require_value "sheet resistance of ${layer#*:}" "${rsh}"
    # The ports are squares at the two ends;  the path is measured
    # between their centers.
    expect=$(echo "${rsh} * (${LEN} - ${WID}) / ${WID} / 1000" | bc -l)
    WIRELAYER=${name} WIRELEN=${LEN} WIREWID=${WID} \
	RESOPTS="{threshold 0} {mindelay 0} {minres 0}" \
	run_magic -rcfile ${RC} ${TESTDIR}/../../common/resis_wire.tcl \
	> ${name}.log
    got=$(${SPICENET} wire_${name}.spice res IN OUT)
    dangling=$(${SPICENET} wire_${name}.spice dangling)
    result=$(python3 -c "
got = '${got}'
exp = ${expect}
if got == 'open':
    print('FAIL:  IN and OUT not connected by resistors (expected %.4g ohms)' % exp)
elif abs(float(got) - exp) > 0.01 * exp:
    print('FAIL:  %s ohms, expected %.4g ohms' % (got, exp))
else:
    print('ok:  %s ohms (expected %.4g ohms)' % (got, exp))")
    echo "  ${name}:  ${result}"
    [[ ${result} == ok* ]] || status=1
    if [ -n "${dangling}" ]; then
	echo "  ${name}:  FAIL:  unconnected subcircuit pins:  ${dangling}"
	status=1
    fi
done

finish ${status}
