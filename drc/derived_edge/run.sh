#!/bin/bash
#
# Derived edge (contact cut) Euclidean corner checks for surround and
# spacing rules.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk gf180mcuD

TECH=${PDK_ROOT}/gf180mcuD/libs.tech/magic/gf180mcuD.tech
status=0

# run_case <scale> <drc rule> <sweep case...>
#   scale 1 = 5nm internal grid, scale 5 = 1nm internal grid

run_case() {
    local scale=$1 rule="$2"; shift 2
    local name=$1
    local tech=${WORK}/${name}.tech
    single_rule_tech ${TECH} ${tech} \
	"$(printf ' style drc\n scalefactor 50\n cifstyle drc\n%s' "${rule}")"
    if [ ${scale} -ne 1 ]; then
	sed -i 's/gridlimit 5/gridlimit 1/' ${tech}
    fi
    printf 'drc euclidean on\nscalegrid 1 %d\n' $((10 * scale)) > ${WORK}/${name}.rc
    SWEEPCASE="$*" SWEEPSCALE=${scale} run_magic -T ${tech} \
	-rcfile ${WORK}/${name}.rc ${TESTDIR}/sweep.tcl > ${WORK}/${name}.log
    if ! grep -q "^RESULT" ${WORK}/${name}.log; then
	echo "  ${name}: no result (see ${WORK}/${name}.log)"
	status=1
	return
    fi
    grep "^RESULT" ${WORK}/${name}.log
    if grep -q "false positive\|false negative" ${WORK}/${name}.log; then
	grep "false positive\|false negative" ${WORK}/${name}.log | head -10
	status=1
    fi
}

CO3=' surround pc/a *poly 65 absence_illegal "CO3"'
PCPC=' spacing pc pc 240 touching_ok "PCPC"'
RPPPC=' spacing rpp pc 215 touching_illegal "RPPPC"'
PCDIFF=' spacing pc alldiff 165 touching_illegal "PCDIFF"'
DCPOLY=' spacing allpdiffcont,allndiffcont allpoly 145 touching_illegal "DCPOLY"'
NWPDIFF=' surround *pdiff,*pdiode,pfet,pcap allnwell 430 absence_okay "NWPDIFF"'

# Surround of a contact cut (CO.3):  the contact is a cut.
for q in NE NW SW SE; do
    run_case 1 "${CO3}" pc_poly_${q} place_notch pc poly ${q} 13 1 CO3
done
run_case 5 "${CO3}" pc_poly_1nm place_notch pc poly NE 13 1 CO3

# Surround of a diffusion contact by nwell:  "*pdiff" includes pdc's
# residue, so pdc is a diffusion edge and not a cut (border 0).
run_case 1 "${NWPDIFF}" pdc_nwell place_notch pdc nwell NE 86 0 NWPDIFF

# Contact to contact spacing:  both sides are cuts.
run_case 1 "${PCPC}" pcpc_ne place_spacing pc pc NE 48 2 PCPC
run_case 1 "${PCPC}" pcpc_nw place_spacing pc pc NW 48 2 PCPC
run_case 5 "${PCPC}" pcpc_ne_1nm place_spacing pc pc NE 48 2 PCPC

# Resistor to contact:  one side is a cut, checked from each side.
run_case 1 "${RPPPC}" rpp_pc place_spacing rpp pc NE 43 1 RPPPC
run_case 1 "${RPPPC}" pc_rpp place_spacing pc rpp NE 43 1 RPPPC

# Poly contact to diffusion:  pc is a cut, diffusion is a real edge.
run_case 1 "${PCDIFF}" pc_ndif place_spacing pc ndif NE 33 1 PCDIFF
run_case 1 "${PCDIFF}" ndif_pc place_spacing ndif pc NW 33 1 PCDIFF

# Diffusion contact to poly:  ndc is a cut, but "allpoly" includes pc's
# residue, so pc is a poly edge.
run_case 1 "${DCPOLY}" ndc_pc place_spacing ndc pc NE 29 1 DCPOLY
run_case 1 "${DCPOLY}" pc_ndc place_spacing pc ndc NW 29 1 DCPOLY

finish ${status}
