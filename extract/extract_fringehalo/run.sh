#!/bin/bash
#
# The fringe halo setting selects a capacitance model and is independent of
# "extract do all" and "extract no all".  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk sky130A
require_magic_version 8.3.694

RC=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc
status=0
cd ${WORK}

# caps <tag> <extract option commands, one per argument...>
# Extracts a metal2 wire over a metal1 plate.  Leaves the capacitors in
# <tag>.caps, sorted, with the instance names removed.
caps() {
    local tag=$1; shift
    {
	cat <<TCL
load ${tag} -silent
box 0um 0um 20um 20um
paint metal1
label P c metal1
box 5um 8um 15um 9um
paint metal2
label W c metal2
extract do local
TCL
	for opt in "$@"; do echo "${opt}"; done
	cat <<TCL
extract
ext2spice lvs
ext2spice cthresh 0
ext2spice -o ${tag}.spice ${tag}
quit -noprompt
TCL
    } > ${tag}.tcl
    run_magic -rcfile ${RC} ${tag}.tcl > ${tag}.log
    grep '^C' ${tag}.spice | cut -d' ' -f2- | sort > ${tag}.caps
}

# same <tag> <reference tag> ; differ <tag> <reference tag>
same() {
    if cmp -s $1.caps $2.caps; then
	printf '  %-16s ok\n' "$1"
    else
	printf '  %-16s FAIL (differs from %s)\n' "$1" "$2"
	status=1
    fi
}
differ() {
    if cmp -s $1.caps $2.caps; then
	printf '  %-16s FAIL (same as %s)\n' "$1" "$2"
	status=1
    else
	printf '  %-16s ok\n' "$1"
    fi
}

caps base
if ! grep -qE '^(W P|P W) ' base.caps; then
    echo "  base             FAIL (no W to P coupling)"
    status=1
fi

# No parasitics at all
caps noall "extract no all"
if [ -s noall.caps ]; then
    echo "  noall            FAIL (capacitors found)"
    status=1
else
    echo "  noall            ok"
fi

# Turning capacitance back on individually gives the default result
caps restored "extract no all" "extract do capacitance" "extract do coupling"
same restored base

caps doall "extract no all" "extract do all"
same doall base

# Controlled by name, and left alone by "all"
caps nohalo "extract no fringehalo"
differ nohalo base

caps nohalo_all "extract no fringehalo" "extract no all" "extract do all"
same nohalo_all nohalo

caps halo "extract no fringehalo" "extract do fringehalo"
same halo base

# Value of "cap" record between two nodes, in either order
extcap() {
    awk -v a="\"$2\"" -v b="\"$3\"" '$1 == "cap" && (($2 == a && $3 == b) ||
	($2 == b && $3 == a)) { print $4 }' $1.ext
}

# check <name> <tag> <node1> <node2> <expected>
check() {
    local got=$(extcap $2 $3 $4)
    if python3 -c "import sys; sys.exit(0 if abs(float('${got:-0}') - $5) < 0.01 else 1)"; then
	printf '  %-16s ok:  %s (expected %s)\n' "$1" "${got}" "$5"
    else
	printf '  %-16s FAIL:  %s (expected %s)\n' "$1" "${got:-none}" "$5"
	status=1
    fi
}

# The legacy model is length * coefficient, with no halo.  For the 10 x 1 um
# wire, that is 22 um of edge, plus the 10 um^2 of area overlap.
TECH=${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.tech
FLAT=$(flat_tech ${TECH})
coef() {
    awk -v kw="$1" '/^extract/ { e = 1 } e && $1 == kw && $2 == "allm2" &&
	$3 == "metal2" && $4 == "allm1" && $5 == "metal1" { print $6; exit }' ${FLAT}
}
require_value "metal2 sideoverlap" "$(coef defaultsideoverlap)"
require_value "metal2 overlap" "$(coef defaultoverlap)"
expected=$(python3 -c "print(22 * $(coef defaultsideoverlap) + 10 * $(coef defaultoverlap))")
check legacy_sky130 nohalo W P ${expected}

# scmos, in lambda units.  poly 20 x 4 over nwell:  area 80, perimeter 48.
# scmoscase <tag> <style> <extract option commands, one per argument...>
scmoscase() {
    local tag=$1 style=$2; shift 2
    {
	cat <<TCL
load ${tag} -silent
extract style ${style}
box 0 0 100 100
paint nwell
label W c nwell
box 40 40 60 44
paint poly
label P c poly
extract do local
TCL
	for opt in "$@"; do echo "${opt}"; done
	cat <<TCL
extract
quit -noprompt
TCL
    } > ${tag}.tcl
    run_magic -T scmos -rcfile /dev/null ${tag}.tcl > ${tag}.log
}

# "sidehalo 0" style:  overlap 39, sideoverlap 80, in aF
scmoscase scmos0 "lambda=1.0(scna20_orb)"
check legacy_halo0 scmos0 W P 6960

# "sidehalo 6" style:  overlap 28, sideoverlap 38, in fF after cscale.  Below
# format 34 the legacy model is the default.
scmoscase scmos6 "lambda=0.6(hp)"
check legacy_scmos scmos6 W P 4.064

scmoscase scmos6_set "lambda=0.6(hp)" "extract no fringehalo"
check legacy_scmos2 scmos6_set W P 4.064

# Distributed fringe, on request, is limited by the halo, so it is lower.
scmoscase scmos6_halo "lambda=0.6(hp)" "extract do fringehalo"
got=$(extcap scmos6_halo W P)
if python3 -c "import sys; sys.exit(0 if 2.24 < float('${got:-0}') < 4.0 else 1)"; then
    printf '  %-16s ok:  %s\n' "dist_scmos" "${got}"
else
    printf '  %-16s FAIL:  %s\n' "dist_scmos" "${got:-none}"
    status=1
fi

# The cutoff, on the same wire and tech file with only the format changed
for fmt in 33 34; do
    sed "s/^\( *\)format 35/\1format ${fmt}/" ${FLAT} > fmt${fmt}.tech
    cat > fmt${fmt}.tcl <<TCL
load fmt${fmt} -silent
box 0um 0um 20um 20um
paint metal1
label P c metal1
box 5um 8um 15um 9um
paint metal2
label W c metal2
extract do local
extract
quit -noprompt
TCL
    run_magic -T ./fmt${fmt}.tech -rcfile /dev/null fmt${fmt}.tcl > fmt${fmt}.log
done
check format33 fmt33 W P ${expected}
check format34 fmt34 W P $(extcap base W P)

# A user's choice survives a change of extract style, and a new tech file
# replaces it.  Each line of the expected output is one "extract do" listing.
cat > state.tcl <<TCL
extract no fringehalo
extract do
extract style ngspice(orig)
extract do
extract style ngspice()
extract do
extract do fringehalo
extract do
tech load scmos -noprompt
extract do
extract do fringehalo
extract do
tech load ${TECH%.tech} -noprompt
extract do
quit -noprompt
TCL
run_magic -T ${TECH%.tech} -rcfile /dev/null state.tcl > state.log
got=$(grep -E '^(do|no) fringehalo' state.log | cut -d' ' -f1 | tr '\n' ' ')
want="no no no do no do do "
if [ "${got}" = "${want}" ]; then
    printf '  %-16s ok:  %s\n' "state" "${got}"
else
    printf '  %-16s FAIL:  %s (expected %s)\n' "state" "${got}" "${want}"
    status=1
fi

finish ${status}
