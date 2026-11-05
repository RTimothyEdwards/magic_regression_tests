#!/bin/bash
#
# The two halves of a "tee" resistor must connect the resistor's terminals, and
# their lengths must add up to the length of the whole resistor.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.695

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# run_case <layout> <expected length, um> <tee on|off> <hierarchy on|off>
run_case() {
    local name=$1_tee$3_hier$4 count=1 result
    [ "$3" == "on" ] && count=2
    mkdir -p ${name}
    pushd ${name} > /dev/null
    CASE=$1 TEE=$3 HIER=$4 run_magic -rcfile ${RC} ${TESTDIR}/layout.tcl \
	> ${name}.log
    result=$(python3 ${TESTDIR}/check.py out.spice $2 ${count} 2>&1 | tail -1)
    popd > /dev/null
    printf '  %-24s %s\n' "${name}:" "${result}"
    [[ ${result} == ok* ]] || status=1
}

for tee in off on; do
    for hier in off on; do
	# Drawn length 56um, plus the offset of 0.16um in the tech file
	run_case poly 56.16 ${tee} ${hier}
	run_case metal 10 ${tee} ${hier}

	# A FET written after a resistor keeps its own length, 0.4um
	name=fet_tee${tee}_hier${hier}
	mkdir -p ${name}
	pushd ${name} > /dev/null
	TEE=${tee} HIER=${hier} run_magic -rcfile ${RC} \
	    ${TESTDIR}/following_device.tcl > ${name}.log
	fets=$(grep -c '^X.*nfet_01v8.* l=0.4$' out.spice)
	popd > /dev/null
	if [ "${fets}" == "2" ]; then
	    result="ok:  ${fets} FETs with l=0.4"
	else
	    result="FAIL:  FET length is wrong, see ${name}/out.spice"
	    status=1
	fi
	printf '  %-24s %s\n' "${name}:" "${result}"
    done
done

finish ${status}
