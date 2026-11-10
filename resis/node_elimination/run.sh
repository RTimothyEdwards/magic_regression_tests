#!/bin/bash
#
# Node elimination and resistor pruning in extresist network
# simplification.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.698
require_pdk sky130A

cd ${WORK}
status=0

# run_case <array size> <prune value or "">

run_case() {
    local name=n$1_p${2:-default}
    mkdir -p ${name}
    (cd ${name};
	(echo "set ::N $1"; echo "set ::PRUNE \"$2\""; cat ${TESTDIR}/layout.tcl) > layout.tcl;
	run_magic -rcfile ${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc \
		layout.tcl < /dev/null > layout.log)
    if ! grep -q "^DONE" ${name}/layout.log || [ ! -s ${name}/top.res.ext ]; then
	echo "  ${name}:  magic did not finish or wrote no top.res.ext"
	status=1
	return 1
    fi
    return 0
}

for n in 6 12; do
    run_case $n "" || continue
    run_case $n 0 || continue
    def=n${n}_pdefault/top.res.ext
    off=n${n}_p0/top.res.ext
    out=$(python3 ${TESTDIR}/check.py ${def} 2 0.01)
    ndef=$(echo "${out}" | head -1)
    problems=$(echo "${out}" | tail -n +2)
    if [ -n "${problems}" ]; then
	echo "  ${n}x${n} cuts, default prune:"
	echo "${problems}" | sed 's/^/    /'
	status=1
    else
	echo "  ${n}x${n} cuts, default prune:  ${ndef} resistors, ok"
    fi
    out=$(python3 ${TESTDIR}/check.py ${off} 2 0)
    noff=$(echo "${out}" | head -1)
    problems=$(echo "${out}" | tail -n +2)
    if [ -n "${problems}" ]; then
	echo "  ${n}x${n} cuts, prune 0:"
	echo "${problems}" | sed 's/^/    /'
	status=1
    elif [ ${noff} -lt ${ndef} ] || { [ ${n} = 12 ] && [ ${noff} -le ${ndef} ]; }; then
	echo "  ${n}x${n} cuts, prune 0:  ${noff} resistors, expected more than ${ndef}"
	status=1
    else
	echo "  ${n}x${n} cuts, prune 0:  ${noff} resistors, ok"
    fi
done

# The value is kept in single precision, so compare it numerically
log=n6_pdefault/layout.log
pdef=$(sed -n 's/^PRUNE_DEFAULT=//p' ${log})
pbad=$(sed -n 's/^PRUNE_AFTER_BAD=//p' ${log})
if python3 -c "import sys; sys.exit(0 if abs(float('${pdef}') - 0.01) < 1e-6 and abs(float('${pbad}') - 0.01) < 1e-6 else 1)" 2>/dev/null; then
    echo "  extresist prune default 0.01, bad value rejected:  ok"
else
    echo "  extresist prune:  $(grep '^PRUNE_' ${log} | tr '\n' ' ')"
    status=1
fi

finish ${status}
