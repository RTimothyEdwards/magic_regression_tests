#!/bin/bash
#
# Which nets "extresist" extracts for given "threshold" and "mindelay"
# settings, and that the extracted network or the unextracted net is
# correct.  See README.md.

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
declare -A RSH
RSH[li]=$(sheet_res "(allli)/locali")
RSH[m1]=$(sheet_res "(allm1)/metal1")
RSH[m4]=$(sheet_res "(allm4)/metal4")

# run_case <name> <layer> <length> <width> <yes|no> <extresist options...>
#   "yes" if the net must be extracted (a resistor network between IN and
#   OUT with the resistance of the wire), "no" if it must not be (IN and
#   OUT remain one node:  as without extresist, the shorted ports are
#   merged into one pin, and must not become two unconnected pins).  Units of the options are as in the "extresist"
#   command:  threshold in milliohms, mindelay in picoseconds.

run_case() {
    local name=$1 layer=$2 len=$3 wid=$4 want=$5; shift 5
    local opts="$*" expect got pins result
    expect=$(echo "${RSH[${layer}]} * (${len} - ${wid}) / ${wid} / 1000" | bc -l)
    WIRELAYER=${layer} WIRELEN=${len} WIREWID=${wid} WIRENAME=${name} \
	RESOPTS="${opts}" \
	run_magic -rcfile ${RC} ${TESTDIR}/../../common/resis_wire.tcl \
	> ${name}.log
    if [ ! -f ${name}.spice ]; then
	echo "  ${name}:  FAIL:  no SPICE output (see ${name}.log)"
	status=1
	return
    fi
    got=$(${SPICENET} ${name}.spice res IN OUT)
    pins=" $(${SPICENET} ${name}.spice pins) "
    result=$(python3 -c "
got, want, exp = '${got}', '${want}', ${expect}
if want == 'yes':
    if got == 'open' or float(got) == 0:
        print('FAIL:  not extracted (wire is %.4g ohms)' % exp)
    elif abs(float(got) - exp) > 0.02 * exp:
        print('FAIL:  extracted as %s ohms, expected %.4g ohms' % (got, exp))
    else:
        print('ok:  extracted, %s ohms' % got)
else:
    if got not in ('open', '0'):
        print('FAIL:  extracted (%s ohms) but should not be' % got)
    elif got == 'open' and ' IN ' in '${pins}' and ' OUT ' in '${pins}':
        print('FAIL:  not extracted, but IN and OUT are separate, unconnected pins')
    else:
        print('ok:  not extracted')")
    printf '  %-16s %-40s %s\n' "${name}:" "(${opts:-defaults})" "${result}"
    [[ ${result} == *FAIL* ]] && status=1
}

# A 100um x 1um metal1 wire is 12.4 ohms with a delay well below 1ps.
run_case m1_zero      m1 100 1 yes {threshold 0} {mindelay 0}
run_case m1_below     m1 100 1 yes {threshold 10000} {mindelay 0}
run_case m1_above     m1 100 1 no  {threshold 20000} {mindelay 0}
run_case m1_defaults  m1 100 1 no

# A 10um x 1um metal4 wire is 0.42 ohms, less than the 1 ohm resolution
# of the lumped resistance in the .ext file.  With no cutoff, it must
# still be extracted.
run_case m4_short     m4 10 1 yes {threshold 0} {mindelay 0}

# A 100um x 1um local interconnect wire is 1267 ohms, with about 12fF of
# capacitance:  a delay of several picoseconds (RC/2 = 7.5ps).
run_case li_delay     li 100 1 yes {threshold 0} {mindelay 1}
run_case li_slow      li 100 1 no  {threshold 0} {mindelay 100}
run_case li_both      li 100 1 yes {threshold 1000000} {mindelay 1}
run_case li_res_fail  li 100 1 no  {threshold 2000000} {mindelay 1}
run_case li_defaults  li 100 1 yes

finish ${status}
