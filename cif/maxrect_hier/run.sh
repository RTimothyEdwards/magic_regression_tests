#!/bin/bash
#
# Hierarchical output of a "maxrect external" layer.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A

TECH=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.tech

# Add an output layer MAXM1 (GDS 200/0) to the gdsii style:  the bounding
# box of each connected region of metal1.
awk '{ print }
     /^style gdsii/ { ingds = 1 }
     ingds && /^ *scalefactor/ && !done {
	print " layer MAXM1 allm1"
	print "\tmaxrect external"
	print "\tcalma 200 0"
	done = 1
     }' ${TECH} > ${WORK}/maxrect.tech

cd ${WORK}
echo "" > empty.rc
run_magic -T ${WORK}/maxrect.tech -rcfile empty.rc ${TESTDIR}/maxrect.tcl \
	< /dev/null > maxrect.log
if ! grep -q "^DONE" maxrect.log; then
    echo "  magic did not finish (see maxrect.log)"
    finish 1
fi

status=0
for f in ring_flat ring_hier; do
    result=$(python3 ${TESTDIR}/gdsunion.py ${f}.gds 200 0)
    echo "  ${f}: ${result}"
    echo "${result}" | grep -q "solid=1" || status=1
done
# The hierarchical and flattened results must cover the same area
a=$(python3 ${TESTDIR}/gdsunion.py ring_flat.gds 200 0 | cut -d' ' -f2-3)
b=$(python3 ${TESTDIR}/gdsunion.py ring_hier.gds 200 0 | cut -d' ' -f2-3)
[ "${a}" = "${b}" ] || { echo "  hierarchical result differs from flat result"; status=1; }

finish ${status}
