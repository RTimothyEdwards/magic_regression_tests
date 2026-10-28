#!/bin/bash
#
# Coincident cell instances with different transforms.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
export TESTDIR

cd ${WORK}
echo "" > empty.rc

status=0
for c in getcell gds; do
    CASE=${c} run_magic -T scmos -rcfile empty.rc ${TESTDIR}/dup.tcl \
	    < /dev/null > ${c}.log
    if ! grep -q "^DONE" ${c}.log; then
	echo "  ${c}:  magic did not finish (see ${c}.log)"
	status=1
	continue
    fi
    # The transforms of the instances of "ell", sorted
    got=$(awk '/^use ell /{u=1} u && /^transform/{print $2, $3, $4, $5, $6, $7; u=0}' \
	    top_${c}.mag | sort | tr '\n' ';')
    want="-1 0 244 0 1 0;1 0 0 0 1 0;"
    if [ "${got}" = "${want}" ]; then
	echo "  ${c}:  two instances (normal and mirrored)"
    else
	echo "  ${c}:  instances \"${got}\", expected \"${want}\""
	status=1
    fi
done

finish ${status}
