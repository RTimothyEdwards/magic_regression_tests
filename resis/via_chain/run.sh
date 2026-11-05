#!/bin/bash
#
# Contact resistance of via chains with 1, 2, 4, and 8 cuts at each sky130
# via level, extracted with "extresist" with all cutoffs at zero.  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.692

PDK=${PDK_ROOT}/sky130A
TECH=$(flat_tech ${PDK}/libs.tech/magic/sky130A.tech)
RC=${PDK}/libs.tech/magic/sky130A.magicrc
SPICENET="python3 ${TESTDIR}/../../common/spicenet.py"
status=0
cd ${WORK}

python3 ${TESTDIR}/gen_vias.py vias.gds
run_magic -rcfile ${RC} ${TESTDIR}/extract.tcl > extract.log

# Resistance per cut (milliohms) of a contact type, from the first
# (nominal) extract style of the tech file.
cut_res() {
    awk -v c="$1" '/^extract/ { e = 1 } e && $1 == "contact" && $2 == c {
	print $3; exit }' ${TECH}
}

for level in li_m1:mcon m1_m2:m2c m2_m3:m3c m3_m4:via3 m4_m5:via4; do
    lv=${level%%:*}
    rcut=$(cut_res ${level#*:})
    require_value "resistance of ${level#*:}" "${rcut}"
    declare -A R=()
    line=""
    for n in 1 2 4 8; do
	if [ -f vc_${lv}_n${n}.spice ]; then
	    R[$n]=$(${SPICENET} vc_${lv}_n${n}.spice res l u)
	else
	    R[$n]=missing
	fi
	line="${line} n${n}=${R[$n]}"
    done
    # The metal is the same in every cell, so R(1) - R(N) is the cut
    # resistance times (1 - 1/N).
    result=$(python3 -c "
r = {1: '${R[1]}', 2: '${R[2]}', 4: '${R[4]}', 8: '${R[8]}'}
rcut = ${rcut} / 1000.0
bad = [n for n in r if r[n] in ('open', 'missing', '0')]
if bad:
    print('FAIL:  no resistance between l and u for N = %s' % ' '.join(map(str, bad)))
else:
    err = []
    if float(r[1]) < rcut:
        err.append('R(1) = %s is less than one cut (%.4g)' % (r[1], rcut))
    for n in (2, 4, 8):
        d = float(r[1]) - float(r[n])
        exp = rcut * (1 - 1.0 / n)
        if abs(d - exp) > 0.01 * rcut:
            err.append('R(1) - R(%d) = %.4g, expected %.4g' % (n, d, exp))
    print(('FAIL:  ' + ';  '.join(err)) if err else 'ok')")
    printf '  %-6s cut %6s mohm:%s  %s\n' ${lv} ${rcut} "${line}" "${result}"
    [[ ${result} == ok* ]] || status=1
    unset R
done

finish ${status}
