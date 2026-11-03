#!/bin/bash
#
# Sidewall coupling capacitance between two parallel wires must equal the
# tech file's sidewall coefficient * length / (separation + offset).  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.693

PDK=${PDK_ROOT}/sky130A
TECH=${PDK}/libs.tech/magic/sky130A.tech
RC=${PDK}/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# "defaultsidewall <types> <plane> <coefficient> <offset>" for a plane,
# from the first (nominal) extract style:  prints "coefficient offset"
sidewall() {
    awk -v pl="$1" '/^extract/ { e = 1 } e && $1 == "defaultsidewall" &&
	$3 == pl { print $4, ($5 == "" ? 0 : $5); exit }' ${TECH}
}

for lp in m1:metal1 m3:metal3 m5:metal5; do
    layer=${lp%%:*}
    read coef offset <<< "$(sidewall ${lp#*:})"
    for s in 0.2 0.4 0.8 1.6 3.2; do
	name=pair_${layer}_$(echo ${s} | tr . p)
	SWLAYER=${layer} SWSEP=${s} run_magic -rcfile ${RC} \
		${TESTDIR}/pair.tcl > ${name}.log
	got=$(awk '$1 == "cap" && (($2 == "\"a\"" && $3 == "\"b\"") ||
		($2 == "\"b\"" && $3 == "\"a\"")) { print $4 }' ${name}.ext)
	result=$(python3 -c "
got = '${got}'
exp = ${coef} * 50 / (${s} + ${offset})
if not got:
    print('FAIL:  no coupling capacitance (expected %.4g aF)' % exp)
elif abs(float(got) - exp) > 0.01 * exp:
    print('FAIL:  %s aF, expected %.4g aF (ratio %.3f)' % (got, exp, float(got) / exp))
else:
    print('ok:  %s aF' % got)")
	printf '  %-4s s=%-4s %s\n' ${layer} ${s} "${result}"
	[[ ${result} == FAIL* ]] && status=1
    done
done

finish ${status}
