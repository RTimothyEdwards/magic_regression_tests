#!/bin/bash
#
# GDS instances with magnification (MAG records).  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.688

TECH=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.tech

cd ${WORK}
echo "" > empty.rc
python3 ${TESTDIR}/mkgds.py test.gds

status=0
for mode in normal readonly; do
    MODE=${mode} run_magic -T ${TECH} -rcfile empty.rc ${TESTDIR}/mag.tcl \
	    < /dev/null > ${mode}.log
    if ! grep -q "^DONE" ${mode}.log; then
	echo "  magic did not finish (see ${mode}.log)"
	finish 1
    fi
done

# The geometry written out must be the same as the geometry in the
# original GDS, with all instances flattened.
for f in out out_ro; do
    result=$(python3 ${TESTDIR}/gdsflat.py test.gds ${f}.gds)
    echo "  ${f}.gds: ${result}"
    echo "${result}" | grep -q " xor=0$" || status=1
done

# Each magnified instance must use a magnified copy of the cell, one copy
# per cell and magnification, and the copy must name the original cell.
expect="A_mag0p333333 A_mag0p5 A_mag1p5 A_mag2 A_mag3 B_mag0p5 B_mag1p5 D_mag1p5"
found=$(grep "^CELLS:" normal.log | tr ' ' '\n' | grep "_mag" | tr '\n' ' ')
if [ "${found}" != "${expect} " ]; then
    echo "  magnified copies are \"${found}\", expected \"${expect}\""
    status=1
fi
for c in ${expect}; do
    grep -q "^SOURCE ${c}: ${c%_mag*}$" normal.log || {
	echo "  ${c} does not have GDS_MAG_SOURCE ${c%_mag*}"; status=1; }
done
n=$(grep -c "^use A_mag1p5 " TOP.mag)
[ "${n}" = "2" ] || { echo "  TOP has ${n} uses of A_mag1p5, expected 2"; status=1; }

# A cell use transform cannot contain a scale factor.
bad=$(grep "^transform" *.mag | awk '$2 !~ /^-?[01]$/ || $3 !~ /^-?[01]$/ ||
	$5 !~ /^-?[01]$/ || $6 !~ /^-?[01]$/')
if [ -n "${bad}" ]; then
    echo "  scaled cell use transforms:"
    echo "${bad}" | sed 's/^/    /'
    status=1
fi

# The read-only output copies the original GDS for every cell, which
# refers to the original cells, so it must contain those and no copies.
names=$(python3 -c "
import struct, sys
d = open('out_ro.gds', 'rb').read()
i = 0
while i < len(d):
    ln, rt = struct.unpack('>HB', d[i:i + 3])
    if ln < 4: break
    if rt == 6: print(d[i + 4:i + ln].rstrip(b'\0').decode())
    i += ln
" | sort | tr '\n' ' ')
echo "  out_ro.gds structures: ${names}"
[ "${names}" = "A B D TOP " ] || status=1

finish ${status}
