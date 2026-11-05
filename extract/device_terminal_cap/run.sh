#!/bin/bash
#
# Capacitance on the terminals of a device must stay on those terminals in
# ext2spice output, in both the hierarchical and flat writers, except for the
# body of a resistor, which is split between its two ends.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.694

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cp ${TESTDIR}/*.ext ${WORK}
cd ${WORK}

# check <cell> <hierarchy on|off> <expected...>
check() {
    local cell=$1 hier=$2; shift 2
    local out=${cell}_${hier}.spice
    cat > ${cell}_${hier}.tcl <<EOF
ext2spice lvs
ext2spice subcircuit on
ext2spice cthresh 0
ext2spice hierarchy ${hier}
ext2spice -o ${out} ${cell}
quit -noprompt
EOF
    run_magic -rcfile ${RC} ${cell}_${hier}.tcl > ${cell}_${hier}.log
    if python3 ${TESTDIR}/check_caps.py ${out} ${cell} "$@"; then
	printf '  %-18s hierarchy %-3s ok\n' "${cell}" "${hier}"
    else
	printf '  %-18s hierarchy %-3s FAIL\n' "${cell}" "${hier}"
	status=1
    fi
}

for hier in on off; do
    # MOSFET and diode subcircuits, modeled by "msubckt".  The expected
    # values are the node and cap records in the .ext files.
    check sky130a_diode ${hier} :D1:D2=0.17429
    check sky130a_inverter ${hier} \
	:vout:vin=0.04809 :vout:vdd=0.07011 :vdd:vin=0.05265 \
	:vout:vss=0.24097 :vdd:vss=0.25998 :vin:vss=0.3082

    # Generic and capacitor subcircuits:  The first terminal is a terminal.
    check subckt2 ${hier} :a:VSUB=0.1 :b:VSUB=0.01
    check subckt3 ${hier} :a:VSUB=0.1 :b:VSUB=0.01 :c:VSUB=0.02
    check csubckt3 ${hier} :a:VSUB=0.1 :b:VSUB=0.01 :c:VSUB=0.02

    # Resistors:  0.1 fF on the body is split between the ends
    check rsubckt3 ${hier} :a:VSUB=0.06 :b:VSUB=0.07
    check res3 ${hier} :a:VSUB=0.06 :b:VSUB=0.07
done

# The same, in subcells
check top on rchild:a:VSUB=0.06 rchild:b:VSUB=0.07 \
	dchild:a:VSUB=0.1 dchild:b:VSUB=0.01 dchild:c:VSUB=0.02
check top off :r0/a:VSUB=0.16 :r0/b:VSUB=0.07 :d0/b:VSUB=0.01 :d0/c:VSUB=0.02

finish ${status}
