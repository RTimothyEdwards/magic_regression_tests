#!/bin/bash
#
# "splitpaint" and "spliterase" with a zero-size box or a locked layer.
# See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/split.tcl < /dev/null > split.log
if ! grep -q "^DONE" split.log; then
    echo "  magic did not finish (see split.log)"
    finish 1
fi

# The paint (rect and tri lines) on each layer of a saved cell
paint() {
    awk -v layer=$2 '/^<< /{l = $2} l == layer && /^(rect|tri) /' $1.mag | sort | tr '\n' ';'
}

status=0
check() {	# check <cell> <layer> <expected paint> <description>
    local got=$(paint $1 $2)
    if [ "${got}" = "$3" ]; then
	echo "  $4:  ok"
    else
	echo "  $4:  $2 is \"${got}\", expected \"$3\""
	status=1
    fi
}

check zero_paint metal1 "" "splitpaint, zero-size box"
check zero_erase metal2 "rect 0 0 20 20;" "spliterase, zero-size box"
check locked_paint metal2 "rect 0 0 20 20;" "splitpaint, locked layer"
check locked_erase metal2 "rect 0 0 20 20;" "spliterase, locked layer"

finish ${status}
