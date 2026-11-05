#!/bin/bash
#
# Reading new geometry from LEF or DEF marks a cell as needing a DRC check, and
# annotating an existing cell does not.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_pdk gf180mcuD
require_magic_version 8.3.695

RC=${PDK_ROOT}/gf180mcuD/libs.tech/magic/gf180mcuD.magicrc
status=0

fail() {
    echo "  $1"
    status=1
}

# step <directory> <script>:  run a script in its own directory
step() {
    mkdir -p ${WORK}/$1
    cd ${WORK}/$1
    run_magic -rcfile ${RC} ${TESTDIR}/$2.tcl < /dev/null > $2.log
    grep -q "^DONE" $2.log || fail "$1:  magic did not finish (see $1/$2.log)"
    cd ${WORK}
}

# expect <file> yes|no <what>
expect() {
    local have=no
    if [ ! -f "$1" ]; then
	fail "$3:  $1 was not written"
	return
    fi
    grep -q "^<< checkpaint >>" $1 && have=yes
    [ "${have}" = "$2" ] || fail "$3:  checkpaint ${have}, expected $2"
}

export LEFFILE=${TESTDIR}/test.lef
export DEFFILE=${TESTDIR}/test.def

# Geometry from LEF:  with a SIZE, and without one
step lef lefread
expect lef/sized.mag yes "LEF macro with a size"
expect lef/nosize.mag yes "LEF macro without a size"

# LEF annotating cells read from GDS, as when installing a PDK.  These stay
# clean.  The macro "sized" is not in the GDS, so it is new and gets checked.
step make makegds
export GDSFILE=${WORK}/make/annotated.gds
step anno lefanno
expect anno/annotated.mag no "LEF annotating a GDS cell"
grep -q "^rlabel .* PIN1" anno/annotated.mag || fail "the LEF did not annotate the cell"
expect anno/sized.mag yes "new macro from LEF that also annotates"

# Geometry from DEF, with the DRC off and on
for state in off on; do
    export DRC_STATE=${state}
    step def_${state} defread
    expect def_${state}/testdesign.mag yes "DEF read, drc ${state}"
done

# DEF annotating a clean cell
step annodef defanno
expect annodef/testdesign.mag no "DEF annotating a cell"
grep -q "^rlabel .* NET1\|^flabel .* NET1\|^port\|NET1" annodef/testdesign.mag ||
	fail "the DEF did not annotate the cell"

finish ${status}
