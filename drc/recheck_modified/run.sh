#!/bin/bash
#
# When a DRC check does and does not make a cell's file out of date.  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.695

if [ "$(id -u)" = "0" ]; then
    echo "SKIP: $(basename ${TESTDIR}) needs a user that read-only files apply to"
    exit 77
fi

# make_cell <name> <width of metal1 square> [<extra section lines>]
#
# In scmos, metal1 of width 10 is clean and metal1 of width 1 is a DRC error.

make_cell() {
    {
	printf 'magic\ntech scmos\ntimestamp 1000\n<< metal1 >>\nrect 0 0 %s %s\n' $2 $2
	[ -n "$3" ] && printf '%b\n' "$3"
	printf '<< end >>\n'
    } > $1.mag
}

CHECK='<< checkpaint >>\nrect -20 -20 30 30'
VENDOR='<< properties >>\nstring GDS_FILE missing.gds'

cd ${WORK}
echo "" > empty.rc
status=0

fail() {
    echo "  $1"
    status=1
}

# prompted <log> <cell>:  did "writeall" offer to write the cell?
prompted() {
    grep -q "^PROMPT $2$" $1
}

has_checkpaint() {
    grep -q "^<< checkpaint >>" $1.mag
}

run_step() {
    run_magic -T scmos -rcfile empty.rc "$@" < /dev/null > ${STEP}.log
    if ! grep -q "^DONE" ${STEP}.log; then
	fail "step \"${STEP}\" did not finish (see ${STEP}.log)"
    fi
}

# 1.  Cells checked with "drc check"

make_cell clean 10
make_cell checkpaint 10 "${CHECK}"
make_cell newerror 1
make_cell ro_clean 10
make_cell ro_error 1
make_cell ro_checkpaint 10 "${CHECK}"
make_cell vendor_error 1 "${VENDOR}"
chmod a-w ro_clean.mag ro_error.mag ro_checkpaint.mag
for cell in clean ro_clean ro_error ro_checkpaint vendor_error; do
    cp ${cell}.mag ${cell}.orig
done

STEP=check
CELLS="clean checkpaint newerror ro_clean ro_error ro_checkpaint vendor_error" \
	run_step ${TESTDIR}/check.tcl

# Nothing about the file has changed, or it must not be written.
for cell in clean ro_clean ro_error vendor_error; do
    prompted check.log ${cell} && fail "writeall offered to write ${cell}"
    cmp -s ${cell}.mag ${cell}.orig || fail "${cell}.mag was rewritten"
done

# The check cleared the check areas in the file.
prompted check.log checkpaint || fail "writeall did not offer to write checkpaint"
has_checkpaint checkpaint && fail "checkpaint.mag still has checkpaint"

# The check found errors that are not in the file.
prompted check.log newerror || fail "writeall did not offer to write newerror"
grep -q "^<< error_p >>" newerror.mag || fail "newerror.mag has no saved error"

# A read-only file with check areas is checked, and magic keeps reporting that
# it cannot be written.
prompted check.log ro_checkpaint || fail "writeall did not offer to write ro_checkpaint"
grep -q "ro_checkpaint.mag is read_only" check.log ||
	fail "no report that ro_checkpaint cannot be written"
cmp -s ro_checkpaint.mag ro_checkpaint.orig || fail "ro_checkpaint.mag was changed"

# 2.  Checking again finds the same errors as the file has, so nothing changes.

cp newerror.mag newerror.orig
cp checkpaint.mag checkpaint.orig
STEP=again
CELLS="newerror checkpaint" run_step ${TESTDIR}/check.tcl
for cell in newerror checkpaint; do
    prompted again.log ${cell} && fail "second check:  writeall offered to write ${cell}"
    cmp -s ${cell}.mag ${cell}.orig || fail "second check:  ${cell}.mag was rewritten"
done

# 3.  A cell saved with check areas still pending:  clearing them later in the
# same session makes the file out of date.

make_cell pending 10
STEP=pending
run_step ${TESTDIR}/pending.tcl
grep -q "^SAVED_WITH_CHECKPAINT" pending.log ||
	fail "pending.mag was not saved with checkpaint"
prompted pending.log pending || fail "writeall did not offer to write pending"
has_checkpaint pending && fail "pending.mag still has checkpaint"

# 3a.  Edits with the DRC off are recorded.

make_cell painted 10
make_cell erased 10
STEP=paintoff
run_step ${TESTDIR}/paintoff.tcl
has_checkpaint painted || fail "paint with the DRC off did not record checkpaint"
has_checkpaint erased || fail "erase with the DRC off did not record checkpaint"

# 3b.  A GDS read does not depend on the DRC state, only on "gds drccheck".

make_cell gcell 10
STEP=gdsmake
run_step ${TESTDIR}/gdsmake.tcl
for state in off on; do
    for check in no yes; do
	dir=gds_${state}_${check}
	mkdir ${dir}
	cd ${WORK}/${dir}
	echo "" > empty.rc
	STEP=gdsread
	DRC_STATE=${state} GDS_DRCCHECK=${check} run_step ${TESTDIR}/gdsread.tcl
	if [ ! -f gcell.mag ]; then
	    fail "drc ${state}, gds drccheck ${check}:  no cell was written"
	elif [ ${check} = no ] && has_checkpaint gcell; then
	    fail "drc ${state}, gds drccheck no:  checkpaint was recorded"
	elif [ ${check} = yes ] && ! has_checkpaint gcell; then
	    fail "drc ${state}, gds drccheck yes:  checkpaint was not recorded"
	fi
	cd ${WORK}
    done
done

# 4.  A stale timestamp below:  "mid" has an old timestamp for "leaf" and is
# written.  The recheck also reaches "top", which has correct information and
# finds no new errors, so it is not written.

make_cell leaf 10
cat > mid.mag <<EOT
magic
tech scmos
timestamp 2000
use leaf  leaf_0
timestamp 999
transform 1 0 0 0 1 0
box 0 0 10 10
<< end >>
EOT
cat > top.mag <<EOT
magic
tech scmos
timestamp 3000
use mid  mid_0
timestamp 2000
transform 1 0 0 0 1 0
box 0 0 10 10
<< end >>
EOT
cp top.mag top.orig
STEP=stale
run_step ${TESTDIR}/stale.tcl
prompted stale.log mid || fail "writeall did not offer to write mid"
prompted stale.log top && fail "writeall offered to write top"
cmp -s top.mag top.orig || fail "top.mag was rewritten"
stamp=$(awk '/^use leaf/ { getline; print $2 }' mid.mag)
[ "${stamp}" = "1000" ] || fail "mid records leaf timestamp ${stamp}, not 1000"

finish ${status}
