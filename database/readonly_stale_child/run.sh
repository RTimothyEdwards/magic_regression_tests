#!/bin/bash
#
# A cell must not be flagged for writing because another parent of its child
# has a stale timestamp, and a real change must still be flagged.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.695

if [ "$(id -u)" = "0" ]; then
    echo "SKIP: $(basename ${TESTDIR}) needs a user that read-only files apply to"
    exit 77
fi

# make_parent <name> <leaf timestamp> <path on the "use" line> <property> [<box>]
#
# Write a cell with a single use of "leaf".

make_parent() {
    cat > $1.mag <<EOT
magic
tech scmos
timestamp 2000
use leaf  leaf_0 $3
timestamp $2
transform 1 0 0 0 1 0
box ${5:-0 0 10 10}
<< properties >>
$4
<< end >>
EOT
}

# Set up a project.  Only the two parents named stale* have out-of-date
# information, and only they should be written.

make_project() {
    mkdir -p $1/lib $1/local
    cat > $1/lib/leaf.mag <<EOT
magic
tech scmos
timestamp 1000
<< metal1 >>
rect 0 0 10 10
<< end >>
EOT
    (cd $1/lib; make_parent readonlyparent 1000 "" "string note library")
    (cd $1/lib; make_parent vendorparent 1000 "" "string GDS_FILE missing.gds")
    (cd $1/local; make_parent cleanparent 1000 ../lib "string note local")
    (cd $1/local; make_parent staleparent 999 ../lib "string note local")
    (cd $1/local; make_parent staleboxparent 999 ../lib "string note local" "0 0 5 5")
    chmod a-w $1/lib/readonlyparent.mag
}

# Write the top cell, with the uses of the stale parents first or last.

make_top() {
    (
	echo "magic"
	echo "tech scmos"
	echo "timestamp 3000"
	x=0
	if [ $1 = stale_first ]; then
	    uses="staleparent: staleboxparent: readonlyparent:../lib vendorparent:../lib cleanparent:"
	else
	    uses="readonlyparent:../lib vendorparent:../lib cleanparent: staleparent: staleboxparent:"
	fi
	for use in ${uses}; do
	    echo "use ${use%:*}  ${use%:*}_0 ${use#*:}"
	    echo "timestamp 2000"
	    echo "transform 1 0 ${x} 0 1 0"
	    echo "box 0 0 10 10"
	    x=$((x + 20))
	done
	echo "<< end >>"
    ) > top.mag
}

cd ${WORK}
status=0

# The order of the uses in the top cell selects which of the two code paths
# finds the mismatch:  with the stale use first, it is found when the child
# is read, and with the correct uses first, when the stale use is read.

for order in stale_first stale_last; do
    make_project ${order}
    cd ${WORK}/${order}/local
    make_top ${order}
    cp ../lib/vendorparent.mag ../vendorparent.orig
    cp cleanparent.mag ../cleanparent.orig

    echo "" > empty.rc
    run_magic -T scmos -rcfile empty.rc ${TESTDIR}/stamps.tcl < /dev/null \
	    > stamps.log
    if ! grep -q "^DONE" stamps.log; then
	echo "  ${order}:  magic did not finish (see ${order}/local/stamps.log)"
	status=1
	cd ${WORK}
	continue
    fi

    # The prompts from "writeall" say which cells were flagged.
    for cell in readonlyparent vendorparent cleanparent; do
	if grep -q "^PROMPT ${cell}$" stamps.log; then
	    echo "  ${order}:  writeall offered to write ${cell}"
	    status=1
	fi
    done
    if grep -q "read_only" stamps.log; then
	echo "  ${order}:  a write to a read-only file was attempted"
	status=1
    fi
    if ! cmp -s ../lib/vendorparent.mag ../vendorparent.orig; then
	echo "  ${order}:  vendorparent.mag was rewritten"
	status=1
    fi
    if ! cmp -s cleanparent.mag ../cleanparent.orig; then
	echo "  ${order}:  cleanparent.mag was rewritten"
	status=1
    fi

    # The parents with stale information must still be updated.
    for cell in staleparent staleboxparent; do
	if ! grep -q "^PROMPT ${cell}$" stamps.log; then
	    echo "  ${order}:  writeall did not offer to write ${cell}"
	    status=1
	fi
	stamp=$(awk '/^use leaf/ { getline; print $2 }' ${cell}.mag)
	if [ "${stamp}" != "1000" ]; then
	    echo "  ${order}:  ${cell} records leaf timestamp ${stamp}, not 1000"
	    status=1
	fi
	box=$(awk '/^box/ { print $2, $3, $4, $5 }' ${cell}.mag)
	if [ "${box}" != "0 0 10 10" ]; then
	    echo "  ${order}:  ${cell} records leaf box ${box}, not 0 0 10 10"
	    status=1
	fi
    done
    cd ${WORK}
done

# A timestamp mismatch forces a recheck of a parent with the old timestamp, and
# of the cells above it, but not of other parents of the child, or of the child.

for order in stale_first stale_last; do
    rm -rf ${order}
    make_project ${order}
    cd ${WORK}/${order}/local
    make_top ${order}
    echo "" > empty.rc
    run_magic -T scmos -rcfile empty.rc ${TESTDIR}/checks.tcl < /dev/null \
	    > checks.log
    if ! grep -q "^DONE" checks.log; then
	echo "  ${order}:  magic did not finish (see ${order}/local/checks.log)"
	status=1
    fi
    for cell in ../lib/vendorparent cleanparent ../lib/leaf; do
	if grep -q "^<< checkpaint >>" ${cell}.mag; then
	    echo "  ${order}:  ${cell} was marked for a DRC check"
	    status=1
	fi
    done
    for cell in staleparent staleboxparent top; do
	if ! grep -q "^<< checkpaint >>" ${cell}.mag; then
	    echo "  ${order}:  ${cell} was not marked for a DRC check"
	    status=1
	fi
    done
    cd ${WORK}
done

# Real edits to a child must still reach its parent:  growing the child changes
# the box the parent records, and painting inside it changes the timestamp.

for edit in grow inside; do
    mkdir ${edit}
    cd ${WORK}/${edit}
    cat > leaf.mag <<EOT
magic
tech scmos
timestamp 1000
<< metal1 >>
rect 0 0 10 10
<< end >>
EOT
    make_parent parent 1000 "" "string note local"
    echo "" > empty.rc
    if [ ${edit} = grow ]; then area="0 0 20 10"; want="0 0 20 10"
    else area="2 2 4 4"; want="0 0 10 10"; fi
    EDIT_AREA="${area}" run_magic -T scmos -rcfile empty.rc \
	    ${TESTDIR}/edit.tcl < /dev/null > edit.log
    if ! grep -q "^DONE" edit.log; then
	echo "  ${edit}:  magic did not finish (see ${edit}/edit.log)"
	status=1
    fi
    if ! grep -q "^PROMPT parent$" edit.log; then
	echo "  ${edit}:  writeall did not offer to write parent"
	status=1
    fi
    stamp=$(awk '/^use leaf/ { getline; print $2 }' parent.mag)
    new=$(awk '/^timestamp/ { print $2; exit }' leaf.mag)
    if [ "${stamp}" != "${new}" ] || [ "${new}" = "1000" ]; then
	echo "  ${edit}:  parent records leaf timestamp ${stamp}, leaf has ${new}"
	status=1
    fi
    box=$(awk '/^box/ { print $2, $3, $4, $5 }' parent.mag)
    if [ "${box}" != "${want}" ]; then
	echo "  ${edit}:  parent records leaf box ${box}, not ${want}"
	status=1
    fi
    cd ${WORK}
done

finish ${status}
