#!/bin/bash
#
# Coupling capacitance must stay between nets when "extresist" replaces them
# with resistor networks, and must not also be added to the capacitance to
# substrate.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.695

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# run_case <name> <layout> <extresist options...>
run_case() {
    local name=$1 layout=$2 result; shift 2
    mkdir -p ${name}
    pushd ${name} > /dev/null
    CASE=${layout} RESOPTS="$*" run_magic -rcfile ${RC} ${TESTDIR}/layout.tcl \
	> ${name}.log
    result=$(python3 ${TESTDIR}/check.py ${TESTDIR}/../../common \
	${layout}_lumped.spice ${layout}.spice 2>&1 | tail -1)
    popd > /dev/null
    printf '  %-12s %s\n' "${name}:" "${result}"
    [[ ${result} == ok* ]] || status=1
}

run_case kept        ports {threshold 0} {mindelay 0} {minres 0}
run_case killed      fets  {threshold 0} {mindelay 0} {minres 0}
run_case kept_delay  ports {threshold 0} {mindelay 1}
run_case killed_delay fets {threshold 0} {mindelay 1}

finish ${status}
