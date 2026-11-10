#!/bin/bash
#
# "instance list <option> <name>" must return its value when the lookup
# reads a cell with a timestamp mismatch, and must find the instance in the
# edit cell when other loaded cells have an instance of the same name.  See
# README.md.

TESTDIR=$(cd $(dirname $0) && pwd)
source ${TESTDIR}/../../common/common.sh
require_magic_version 8.3.695

cd ${WORK}
echo "" > empty.rc

# "pad" has FIXED_BBOX 0 0 20 20.  "top" places it as "p1", rotated by
# 90 degrees (x' = y, y' = -x), so its abutment box in "top" is 0 -20 20 0.
# The timestamp recorded for it in "top" is wrong.

cat > pad.mag <<EOT
magic
tech scmos
timestamp 1000
<< metal1 >>
rect 0 0 10 10
<< properties >>
string FIXED_BBOX 0 0 20 20
<< end >>
EOT
cat > top.mag <<EOT
magic
tech scmos
timestamp 2000
use pad  p1
timestamp 999
transform 0 1 0 -1 0 0
box 0 0 10 10
<< end >>
EOT

# "big" has a different FIXED_BBOX;  "other1" to "other6" each have an
# instance of it that is also named "p1".

cat > big.mag <<EOT
magic
tech scmos
timestamp 1000
<< metal1 >>
rect 0 0 40 40
<< properties >>
string FIXED_BBOX 0 0 50 50
<< end >>
EOT
for i in 1 2 3 4 5 6; do
    cat > other${i}.mag <<EOT
magic
tech scmos
timestamp 2000
use big  p1
timestamp 1000
transform 1 0 0 0 1 0
box 0 0 40 40
<< end >>
EOT
done

status=0

# check <what> <got> <expected>

check() {
    if [ "$2" = "$3" ]; then
	echo "  $1:  ok ($2)"
    else
	echo "  $1:  \"$2\", expected \"$3\""
	status=1
    fi
}

# Stale timestamp:  "pad" is first read by the lookup itself, so the
# mismatch is processed right after the command returns.  Each option gets
# its own session, so that its own call is the one that reads "pad".  The
# second call in the session, with nothing left to process, gives the value
# the first call must return.

for opt in abutment position orientation; do
    cat > stale_${opt}.tcl <<EOT
load top
set first [instance list ${opt} p1]
set second [instance list ${opt} p1]
puts "FIRST=<\$first>"
puts "SECOND=<\$second>"
quit -noprompt
EOT
    run_magic -T scmos -rcfile empty.rc stale_${opt}.tcl < /dev/null > stale_${opt}.log
    if ! grep -q "Timestamp mismatches found" stale_${opt}.log; then
	echo "  stale ${opt}:  no timestamp mismatch was processed (see stale_${opt}.log)"
	status=1
    fi
    first=$(sed -n 's/^FIRST=<\(.*\)>$/\1/p' stale_${opt}.log)
    second=$(sed -n 's/^SECOND=<\(.*\)>$/\1/p' stale_${opt}.log)
    if [ -z "${second}" ]; then
	echo "  stale ${opt}:  no value from the second call (see stale_${opt}.log)"
	status=1
    fi
    check "stale ${opt}" "${first}" "${second}"
    [ ${opt} = abutment ] && check "stale abutment box" "${second}" "0 -20 20 0"
done

# Same instance name in other loaded cells.  These are loaded first, so
# that they are in the cell table when "top" becomes the edit cell.

cat > samename.tcl <<EOT
foreach c {other1 other2 other3 other4 other5 other6} {load \$c}
load top
puts "ABUT=<[instance list abutment p1]>"
quit -noprompt
EOT
run_magic -T scmos -rcfile empty.rc samename.tcl < /dev/null > samename.log
check "same name elsewhere" "$(sed -n 's/^ABUT=<\(.*\)>$/\1/p' samename.log)" "0 -20 20 0"

finish ${status}
