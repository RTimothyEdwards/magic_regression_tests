#!/bin/bash
#
# Sidewall coupling capacitance between two parallel wires must equal the
# tech file's sidewall coefficient * length / (separation + offset).  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.694

PDK=${PDK_ROOT}/sky130A
TECH=$(flat_tech ${PDK}/libs.tech/magic/sky130A.tech)
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
    require_value "sidewall coefficient of ${lp#*:}" "${coef}"
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
	[[ ${result} == ok* ]] || status=1
    done
done

# Offsets not on the layout grid.  The internal grid of this tech file is
# 0.005um, so these would be rounded or truncated if stored on it.  Change the
# offsets in a copy of the tech file, and compare with a tight tolerance.
FLAT=$(flat_tech ${TECH})
for lp in m1:metal1:0.268 m5:metal5:-0.106; do
    IFS=: read layer plane offset <<< "${lp}"
    read coef other <<< "$(sidewall ${plane})"
    awk -v pl="${plane}" -v off="${offset}" '/^extract/ { e = 1 }
	e && $1 == "defaultsidewall" && $3 == pl { $5 = off } { print }' \
	${FLAT} > offset_${layer}.tech
    echo "" > empty.rc
    for s in 0.2 0.4; do
	name=pair_${layer}_$(echo ${s} | tr . p)
	SWLAYER=${layer} SWSEP=${s} run_magic -T ./offset_${layer}.tech \
		-rcfile empty.rc ${TESTDIR}/pair.tcl > off_${name}.log
	got=$(awk '$1 == "cap" && (($2 == "\"a\"" && $3 == "\"b\"") ||
		($2 == "\"b\"" && $3 == "\"a\"")) { print $4 }' ${name}.ext)
	result=$(python3 -c "
got = '${got}'
exp = ${coef} * 50 / (${s} + ${offset})
if not got:
    print('FAIL:  no coupling capacitance (expected %.5g aF)' % exp)
elif abs(float(got) - exp) > 0.001 * exp:
    print('FAIL:  %s aF, expected %.5g aF (ratio %.4f)' % (got, exp, float(got) / exp))
else:
    print('ok:  %s aF' % got)")
	printf '  %-4s s=%-4s offset %-7s %s\n' ${layer} ${s} ${offset} "${result}"
	[[ ${result} == ok* ]] || status=1
    done
done

finish ${status}
