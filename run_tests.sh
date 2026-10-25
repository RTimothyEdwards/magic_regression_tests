#!/bin/bash
#
# run_tests.sh --- Run all magic regression tests, or the tests in the
# directories given as arguments (e.g., "./run_tests.sh drc").
#
# Each test is a directory containing an executable "run.sh", which prints
# a final line "PASS: <name>", "FAIL: <name>", or "SKIP: <reason>", and
# exits with status 0 (pass), 1 (fail), or 77 (skip).
#
# See common/common.sh for environment variables (MAGIC, PDK_ROOT).

cd $(dirname $0)
dirs=${@:-.}
pass=0; fail=0; skip=0; failed=""

for t in $(find ${dirs} -name run.sh -not -path "*/work/*" | sort); do
    tdir=$(dirname ${t})
    echo "=== ${tdir}"
    ${t}
    case $? in
	0)  pass=$((pass + 1)) ;;
	77) skip=$((skip + 1)) ;;
	*)  fail=$((fail + 1)); failed="${failed} ${tdir}" ;;
    esac
done

echo
echo "Passed: ${pass}  Failed: ${fail}  Skipped: ${skip}"
[ -n "${failed}" ] && echo "Failed tests:${failed}"
[ ${fail} -eq 0 ]
