#!/bin/bash
#
# Label names after flattening a selection with "select flat".  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc
run_magic -T scmos -rcfile empty.rc ${TESTDIR}/flat.tcl < /dev/null > flat.log
if ! grep -q "^DONE" flat.log; then
    echo "  magic did not finish (see flat.log)"
    finish 1
fi

# Labels as "<layer> <text>", sorted
labels=$(awk '/^rlabel/{t = $8; for (i = 9; i <= NF; i++) t = t " " $i; print $2, t}' top.mag | sort)
echo "${labels}" | sed 's/^/  label:  /'

status=0
# Exactly two labels:  "A" on metal2, and sub_0 + separator + "B" on metal1
# (the hierarchy separator has been "/" and ".")
if [ "$(echo "${labels}" | wc -l)" != "2" ] ||
	! echo "${labels}" | grep -qx "metal2 A" ||
	! echo "${labels}" | grep -qx "metal1 sub_0[./]B"; then
    echo "  expected labels \"metal2 A\" and \"metal1 sub_0/B\" (or sub_0.B)"
    status=1
fi
finish ${status}
