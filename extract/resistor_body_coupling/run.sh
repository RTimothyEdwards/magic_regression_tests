#!/bin/bash
#
# Coupling capacitance to the body of a resistor must not be left on a node
# that is not in the netlist.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.695

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# run_case <layout> <tee on|off> <hierarchy on|off>
run_case() {
    local name=$1_tee$2_hier$3 result
    mkdir -p ${name}
    pushd ${name} > /dev/null
    CASE=$1 TEE=$2 HIER=$3 run_magic -rcfile ${RC} ${TESTDIR}/layout.tcl \
	> ${name}.log
    result=$(python3 ${TESTDIR}/check.py ${TESTDIR}/../../common \
	pair.ext out.spice 2>&1 | tail -1)
    popd > /dev/null
    printf '  %-24s %s\n' "${name}:" "${result}"
    [[ ${result} == ok* ]] || status=1
}

for layout in metal poly; do
    for tee in off on; do
	for hier in off on; do
	    run_case ${layout} ${tee} ${hier}
	done
    done
done

finish ${status}
