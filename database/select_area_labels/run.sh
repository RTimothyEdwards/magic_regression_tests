#!/bin/bash
#
# What "select area" selects:  paint, labels (including labels on space),
# and cell instances.  See README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.689

cd ${WORK}
echo "" > empty.rc

# What moved, as "m1 onmetal onspace sub" with 1 for moved and 0 for not
moved() {
    awk '/^<< metal1/{m=1} /^<< (labels|end)/{m=0}
	 m && /^rect/ {r["m1"] = ($3 >= 100)}
	 /^rlabel/ {r[$8] = ($4 >= 100)}
	 /^use/ {u=1} u && /^transform/ {r["sub"] = ($7 >= 100); u=0}
	 END {print r["m1"], r["onmetal"], r["onspace"], r["sub"]}' top.mag
}

status=0
n=0
# Each case:  the select command, and what must move (m1 onmetal onspace sub)
while IFS='|' read sel want; do
    [ -z "${sel}" ] && continue
    n=$((n + 1))
    SEL="${sel}" run_magic -T scmos -rcfile empty.rc ${TESTDIR}/sel.tcl \
	    < /dev/null > case${n}.log
    if ! grep -q "^DONE" case${n}.log; then
	echo "  ${sel}:  magic did not finish (see case${n}.log)"
	status=1
	continue
    fi
    cp top.mag case${n}.mag
    got=$(moved)
    if [ "${got}" = "${want}" ]; then
	printf "  %-24s ok (%s)\n" "${sel}" "${got}"
    else
	printf "  %-24s moved %s, expected %s (m1 onmetal onspace sub)\n" \
		"${sel}" "${got}" "${want}"
	status=1
    fi
done <<'CASES'
select area|1 1 1 1
select area *|1 1 1 0
select area label|0 1 1 0
select area m1|1 1 0 0
select area m1,label|1 1 0 0
select area subcell|0 0 0 1
CASES

finish ${status}
