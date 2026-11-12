#!/bin/bash
#
# run_tests.sh --- Run all magic regression tests, or the tests in the
# directories given as arguments (e.g., "./run_tests.sh drc").
#
# Options:
#   -j <n>   Run up to <n> tests at the same time (default 20, or the
#            value of the environment variable JOBS).  With "-j 1", the
#            tests run one after another and their output is shown as
#            they run.  Otherwise the output of each test is shown when
#            it finishes, so tests are listed in the order they finish.
#
# Each test is a directory containing an executable "run.sh", which prints
# a final line "PASS: <name>", "FAIL: <name>", or "SKIP: <reason>", and
# exits with status 0 (pass), 1 (fail), or 77 (skip).  Tests must not
# write outside their own directory, since several run at the same time.
#
# See common/common.sh for environment variables (MAGIC, PDK_ROOT).

jobs=${JOBS:-20}
while getopts "j:" opt; do
    case ${opt} in
	j)  jobs=${OPTARG} ;;
	*)  echo "Usage: $0 [-j <n>] [directory ...]"; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
if ! [ "${jobs}" -ge 1 ] 2>/dev/null; then
    echo "$0:  -j needs a positive number"
    exit 2
fi

cd $(dirname $0)
dirs=${@:-.}
tests=$(find ${dirs} -name run.sh -not -path "*/work/*" | sort)
pass=0; fail=0; skip=0; failed=""
start=${SECONDS}

# Count the result of one test from its exit status.

count() {
    case $1 in
	0)  pass=$((pass + 1)) ;;
	77) skip=$((skip + 1)) ;;
	*)  fail=$((fail + 1)); failed="${failed} $2" ;;
    esac
}

if [ ${jobs} -eq 1 ]; then
    for t in ${tests}; do
	tdir=$(dirname ${t})
	echo "=== ${tdir}"
	${t}
	count $? ${tdir}
    done
else
    # Each test's output goes to a log file, which is shown when the test
    # finishes, so that the output of different tests is not mixed.
    # ("wait -p" needs bash 5.1 or newer.)

    logs=$(mktemp -d)
    trap 'rm -rf ${logs}' EXIT
    declare -A tdirs times
    running=0

    # Wait for any one test to finish, then show its output and count it.

    reap() {
	local pid status
	wait -n -p pid
	status=$?
	running=$((running - 1))
	echo "=== ${tdirs[${pid}]}  ($((SECONDS - times[${pid}])) s)"
	cat ${logs}/${pid}.log
	count ${status} ${tdirs[${pid}]}
    }

    for t in ${tests}; do
	[ ${running} -ge ${jobs} ] && reap
	# The log is named by the test's process ID ($$ in the shell that
	# execs the test, the same as $! here), which "wait -p" returns.
	bash -c 'exec "$1" > "$2/$$.log" 2>&1' run_one ${t} ${logs} &
	tdirs[$!]=$(dirname ${t})
	times[$!]=${SECONDS}
	running=$((running + 1))
    done
    while [ ${running} -gt 0 ]; do
	reap
    done
fi

echo
echo "Passed: ${pass}  Failed: ${fail}  Skipped: ${skip}  ($((SECONDS - start)) s)"
if [ -n "${failed}" ]; then
    echo "Failed tests:"
    for f in $(echo ${failed} | tr ' ' '\n' | sort); do
	echo "    ${f}"
    done
fi
[ ${fail} -eq 0 ]
