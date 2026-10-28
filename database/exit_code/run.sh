#!/bin/bash
#
# Exit status of magic in batch mode.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh

cd ${WORK}
echo "" > empty.rc

status=0
# Each case and the exit status expected for it
for c in exit3:3 exitneg:255 exit0:0 exitproc:5 quit:0 eof:0; do
    name=${c%:*}
    want=${c#*:}
    CASE=${name} run_magic -T scmos -rcfile empty.rc ${TESTDIR}/exit.tcl \
	    < /dev/null > ${name}.log
    got=$?
    if [ "${got}" = "${want}" ]; then
	echo "  ${name}:  exit status ${got}"
    else
	echo "  ${name}:  exit status ${got}, expected ${want}"
	status=1
    fi
done

finish ${status}
